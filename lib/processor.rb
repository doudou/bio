class Processor
    def load_name_mappings(path)
        mapping = Hash.new
        File.readlines(path).each do |line|
            key, *name = line.strip.split(/\s+/)
            mapping[key] = name.join(" ").strip.gsub(/[^\w]+/, '_')
        end
        @sequence_key_mapping = mapping
    end

    def self.default_rename_output_path(file_path)
        input_ext = File.extname(file_path)
        output_basename = File.basename(file_path, input_ext)
        File.join(File.dirname(file_path), "#{output_basename}.renamed#{input_ext}")
    end

    def perform_sequence_renames(file_path, rename_path,
                                 output: self.class.default_rename_output_path(file_path))
        load_name_mappings(rename_path)
        File.open(output, 'w') do |io|
            process_sequence_renames(io, file_path)
        end
    end

end
