def read_fasta(file)
    if !is_fasta?(file)
        raise ArgumentError, "#{file} is not a valid FASTA file"
    end

    result = Array.new
    File.open(file) do |io|
        line = io.readline.chomp
        while !io.eof?
            seqname = line.chomp[1..-1].strip

            data = ""
            line = io.readline.chomp
            while !io.eof? && line !~ /^>/
                data << line
                line = io.readline.chomp
            end
            data << line if io.eof?

            result << [seqname, data]
        end
    end
    puts "found #{result.size} sequences"
    result
end

def is_fasta?(file)
    line_size = nil
    File.open(file) do |io|
	return false if io.readline !~ /^>/
        last_line_size_mismatch = false
	
	while !io.eof?
	    line = io.readline.chomp
            if line =~ /^>/
                # New sequence, skip
                last_line_size_mismatch = false
                next
            elsif line =~ /^\n*$/
                last_line_size_mismatch = false
                next
            elsif last_line_size_mismatch
		return false
            end

	    return false if line !~ /^[A-Za-z\-:]*$/

	    if line_size
                if line.size != line_size
                    return true if io.eof?
                    last_line_size_mismatch = true
                end
            else
                line_size = line.size
	    end
	end
	return true
    end
end

def write_tcs(title, sequences, io)
    if sequences.empty?
        raise ArgumentError, "no sequences given"
    end

    seqlength = sequences.first.last.size
    namewidth = sequences.map { |name, _| name.size }.max

    sequences.each do |name, data|
        name.gsub! /[^\w]/, '_'
        if data.size != seqlength
            raise ArgumentError, "sequence data mismatch: #{name} has #{data.size} bases instead of #{seqlength}"
        end
        if data =~ /[U]/
            bad = (data =~ /[U]/)
            raise ArgumentError, "#{name} contains U (character #{bad})"
        end
    end

    io.puts <<-EOH
#NEXUS\r
[Title #{title}]\r
begin taxa;\r
dimensions ntax=#{sequences.size};\r
taxlabels\r
\r
#{sequences.map { |name, _| "%- #{namewidth}s" % name }.join("\r\n")}\r
\r
;\r
end;\r
begin characters;\r
dimensions nchar=#{seqlength};\r
FORMAT DATATYPE=DNA MISSING=? GAP=-;\r
matrix\r
\r
[!Domain=Data;]\r
\r
    EOH

    sequences.each do |name, data|
        io.puts "%- #{namewidth}s %s\r" % [name, data.upcase]
    end

    io.print ";\r\nend;"
end

