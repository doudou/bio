def is_fasta?(file)
    line_size = nil
    File.open(file) do |io|
	return false if io.readline !~ /^>/
	
	while !io.eof?
	    line = io.readline.chomp
	    return false if line !~ /^[A-Za-z\-:]*$/
	    
	    if line_size && line.size != line_size
		return (io.eof? || io.read =~ /^\n*$/)
	    end
	    line_size = line.size
	end
	return true
    end
end

