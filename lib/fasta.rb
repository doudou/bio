require_relative 'processor'

class FastaProcessing < Processor
    def process_sequence_renames(io, path)
        File.readlines(path).each do |line|
            line = line.chomp
            if line.start_with?('>')
                name = line[1..-1].strip
                mapped_name = @sequence_key_mapping[name] || name
                io.puts ">#{mapped_name}"
            else
                io.puts line
            end
        end
        io.puts
    end
end
