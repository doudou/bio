require 'set'
require 'matrix'

class NexusProcessing
    # List of traits to be added to the nexus file
    #
    # @return [Hash<String,Trait>]
    attr_reader :traits

    # Mapping of sequence keys in the nexus file to names that should be used in
    # the processed file
    #
    # @return [Hash<String,String>]
    attr_reader :sequence_key_mapping

    # Latitute/longitude information
    attr_reader :latlon

    # The number of clusters to be declared in the geotags block
    attr_accessor :nclusters

    Trait = Struct.new :name, :categories, :sequence_to_row, :matrix
    
    def initialize(nclusters: 5)
        @nclusters = nclusters
        @traits = Hash.new
    end

    def add_trait(name, sequence_keys, sequence_traits)
        categories = sequence_traits.sort_by { |v| v || "" }.uniq
        categories.delete('?')
        category_to_col = Hash[categories.each_with_index.map { |v, i| [v, i] }]

        sequence_keys_uniq = Set[*sequence_keys].to_a.sort
        sequence_keys_to_row = Hash[sequence_keys_uniq.each_with_index.map { |k, i| [k, i] }]

        matrix = (1..sequence_keys_uniq.size).map { [0] * categories.size }
        sequence_keys.each_with_index do |key, i|
            if trait = sequence_traits[i]
                row = sequence_keys_to_row[key]
                col = category_to_col[trait]
                matrix[row][col] += 1
            end
        end

        self.traits[name] = Trait.new(name, categories, sequence_keys_to_row, matrix)
    end

    def load_traits_from_csv(path, key, traits_names, latlon: nil)
        all_traits_names = traits_names

        keys = Array.new
        lat  = Array.new
        lon  = Array.new
        traits = Hash[all_traits_names.map { |n| [n, Array.new] }]
        CSV.foreach(path, headers: :first_row) do |row|
            next if !(k = row[key])
            keys << k
            if latlon
                lat << row[latlon.first].gsub(',', '.')
                lon << row[latlon.last].gsub(',', '.')
            end
            all_traits_names.each do |col_name|
                traits[col_name] << row[col_name].strip.gsub(/[^\w]+/, '_')
            end
        end

        traits.each do |name, data|
            add_trait(name, keys, data)
        end

        if latlon
            @latlon = Hash.new
            keys.each_with_index do |k,i|
                k_latlon = (@latlon[k] ||= Hash.new(0))
                k_latlon[[lat[i],lon[i]]] += 1
            end
        end
    end

    def load_name_mappings(path)
        mapping = Hash.new
        File.readlines(path).each do |line|
            key, *name = line.strip.split(/\s+/)
            mapping[key] = name.join(" ").strip.gsub(/[^\w]+/, '_')
        end
        @sequence_key_mapping = mapping
    end

    def process(path)
        max_key_size = sequence_key_mapping.values.map(&:size).max
        name_format = "%-#{max_key_size}s"

        in_data_block, in_data_matrix = false
        base_file = StringIO.new
        sequence_names = Array.new
        File.readlines(path).each do |line|
            if line =~ /\[Name: (\w+)(.*)/
                name, remainder = $1, $2
                sequence_names << name
                if !sequence_key_mapping
                    base_file.print line
                elsif mapped_name = sequence_key_mapping[name]
                    mapped_name = name_format % [mapped_name]
                    base_file.puts "[Name: #{mapped_name}#{remainder}"
                else
                    raise "no mapping for name #{name}"
                end
            elsif in_data_matrix && line =~ /^ (\w+)(\s+.*)/
                name, remainder = $1, $2
                if !sequence_key_mapping
                    base_file.print line
                elsif mapped_name = sequence_key_mapping[name]
                    mapped_name = name_format % [mapped_name]
                    base_file.puts " #{mapped_name}#{remainder}"
                else
                    raise "no mapping for name '#{name}'"
                end
            elsif in_data_block && line.downcase.strip == "matrix"
                in_data_matrix = true
                base_file.print line
            elsif line.downcase.strip == "begin data;"
                in_data_block = true
                base_file.print line
            elsif in_data_block && line.downcase.strip == "end;"
                in_data_block, in_data_matrix = false
                base_file.print line
            else
                base_file.print line
            end
        end

        dirname = path.gsub(/\.nex(?:us)?$/, '')
        FileUtils.mkdir_p dirname
        # Add annotation blocks for the traits
        traits.each_value do |trait|
            File.open(File.join(dirname, "#{trait.name}.nex"), 'w') do |io|
                io.puts base_file.string
                make_trait_block(io, trait, sequence_names)
            end
        end

        # And if we have lat/lon, make a geotag block
        File.open(File.join(dirname, "geotags.nex"), 'w') do |io|
            io.puts base_file.string
            make_geotags_block(io, sequence_names)
        end
    end

    def make_trait_block(io, trait, sequence_names)
        sequence_key_mapping = (self.sequence_key_mapping || ->(k) { k })

        trait_array = ["0"] * trait.categories.size
        io.puts "BEGIN TRAITS;"
        io.puts "  Dimensions NTRAITS=#{trait.categories.size};"
        io.puts "  Format labels=yes missing=? separator=Comma;"
        io.puts "  TraitLabels #{trait.categories.join(" ")};"
        io.puts "  Matrix"
        sequence_names.each do |seq_name|
            if row = trait.sequence_to_row[seq_name]
                io.puts "#{sequence_key_mapping[seq_name]} #{trait.matrix[row].map(&:to_s).join(",")}"
            end
        end
        io.puts ";"
        io.puts "END;"
    end

    def make_geotags_block(io, sequence_names)
        sequence_key_mapping = (self.sequence_key_mapping || ->(k) { k })

        io.puts "BEGIN GEOTAGS;"
        io.puts "  Dimensions NClusts=#{nclusters};"
        io.puts "  Format labels=yes separator=Comma;"
        io.puts "  Matrix"
        sequence_names.each do |seq_name|
            if seq_latlon = latlon[seq_name]
                seq_latlon.each do |(lat,lon),count|
                    io.puts "#{sequence_key_mapping[seq_name]} #{lat},#{lon},#{count}"
                end
            else
                binding.pry
                raise "no data for sequence #{seq_name}"
            end
        end
        io.puts ";"
        io.puts "END;"
    end
end

