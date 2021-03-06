require 'set'
require 'matrix'
require 'yaml'
require 'csv'
require 'fileutils'
require_relative 'processor'

class NexusProcessing < Processor
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

    def self.from_config_file(config_path)
        config = YAML.load(File.read(config_path))
        base_dir = File.dirname(config_path)
        key_col_name  = config.delete('key')
        lat_col_name  = config.delete('lat')
        lon_col_name  = config.delete('lon')
        nclusters     = config.delete('nclusters') || 5
        name_mappings = config.delete('name_mappings_file')
        if name_mappings
            name_mappings = File.expand_path(name_mappings, base_dir)
        end
        traits_file   = File.expand_path(config.delete('traits_file'), base_dir)
        traits_col_names = (config.delete('traits') || Array.new)
        if !config.empty?
            raise "unknown config parameters #{config}"
        end

        latlon =
            if lat_col_name && lon_col_name
                [lat_col_name, lon_col_name]
            end
        processor = NexusProcessing.new(nclusters: nclusters)
        processor.load_traits_from_csv(traits_file, key_col_name, traits_col_names, latlon: latlon)
        if name_mappings
            processor.load_name_mappings(name_mappings)
        end
        processor
    end

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
	lat_field, long_field = *latlon
        traits = Hash[all_traits_names.map { |n| [n, Array.new] }]
        CSV.enum_for(:foreach, path, headers: :first_row).each_with_index do |row, row_idx|
            next if !(k = row[key])
            keys << k
            if lat_field && long_field
		row_lat, row_long = row.values_at(lat_field, long_field)
		if !row_lat
		    raise "no latitude field '#{lat_field}' in row #{row_idx} of #{path}"
		elsif !row_long
		    raise "no latitude field '#{long_field}' in row #{row_idx} of #{path}"
		end
                lat << row_lat.gsub(',', '.')
                lon << row_long.gsub(',', '.')
            end
            all_traits_names.each do |col_name|
		if val = row[col_name]
		    traits[col_name] << val.strip.gsub(/[^\w]+/, '_')
		else
		    raise "missing expected trait field '#{col_name}'"
		end
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

    def process_sequence_renames(io, path)
        if sequence_key_mapping
            max_key_size = sequence_key_mapping.values.map(&:size).max
            name_format = "%-#{max_key_size}s"
        end

        in_data_block, in_data_matrix = false
        sequence_names = Array.new
        File.readlines(path).each do |line|
            if line =~ /\[Name: (\w+)(.*)/
                name, remainder = $1, $2
                sequence_names << name
                if !sequence_key_mapping
                    io.print line
                elsif mapped_name = sequence_key_mapping[name]
                    mapped_name = name_format % [mapped_name]
                    io.puts "[Name: #{mapped_name}#{remainder}"
                else
                    raise "no mapping for name #{name}"
                end
            elsif in_data_matrix && line =~ /^ (\w+)(\s+.*)/
                name, remainder = $1, $2
                if !sequence_key_mapping
                    io.print line
                elsif mapped_name = sequence_key_mapping[name]
                    mapped_name = name_format % [mapped_name]
                    io.puts " #{mapped_name}#{remainder}"
                else
                    raise "no mapping for name '#{name}'"
                end
            elsif in_data_block && line.downcase.strip == "matrix"
                in_data_matrix = true
                io.print line
            elsif line.downcase.strip == "begin data;"
                in_data_block = true
                io.print line
            elsif in_data_block && line.downcase.strip == "end;"
                in_data_block, in_data_matrix = false
                io.print line
            else
                io.print line
            end
        end
        sequence_names
    end

    def process(path, output_dir: nil)
        base_file = StringIO.new
        sequence_names = process_sequence_renames(base_file, path)

        output_dir ||= path.gsub(/\.nex(?:us)?$/, '')
        FileUtils.mkdir_p output_dir
        # Add annotation blocks for the traits
        traits.each_value do |trait|
            File.open(File.join(output_dir, "#{trait.name}.nex"), 'w') do |io|
                io.puts base_file.string
                make_trait_block(io, trait, sequence_names)
            end
            File.open(File.join(output_dir, "#{trait.name}.csv"), 'w') do |io|
                make_trait_csv(io, trait, sequence_names)
            end
        end

        # And if we have lat/lon, make a geotag block
        if latlon
            File.open(File.join(output_dir, "geotags.nex"), 'w') do |io|
                io.puts base_file.string
                make_geotags_block(io, sequence_names)
            end
            File.open(File.join(output_dir, "geotags.csv"), 'w') do |io|
                make_geotags_csv(io, sequence_names)
            end
        end
    end

    def make_trait_block(io, trait, sequence_names)
        sequence_key_mapping = (self.sequence_key_mapping || ->(k) { k })

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

    def make_trait_csv(io, trait, sequence_names)
        sequence_key_mapping = (self.sequence_key_mapping || ->(k) { k })
        io.puts "name,#{trait.categories.join(",")}"
        sequence_names.each do |seq_name|
            if row = trait.sequence_to_row[seq_name]
                io.puts "#{sequence_key_mapping[seq_name]},#{trait.matrix[row].map(&:to_s).join(",")}"
            end
        end
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
                raise "no data for sequence #{seq_name}"
            end
        end
        io.puts ";"
        io.puts "END;"
    end

    def make_geotags_csv(io, sequence_names)
        sequence_key_mapping = (self.sequence_key_mapping || ->(k) { k })

        io.puts "name,latitude,longitude,count"
        sequence_names.each do |seq_name|
            if seq_latlon = latlon[seq_name]
                seq_latlon.each do |(lat,lon),count|
                    io.puts "#{sequence_key_mapping[seq_name]},#{lat},#{lon},#{count}"
                end
            else
                raise "no data for sequence #{seq_name}"
            end
        end
    end
end

