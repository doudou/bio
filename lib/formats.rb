def is_fasta?(file)
    File.open(file) do |io|
	return false if io.readline !~ /^>/
	
	while !io.eof?
	    line = io.readline.chomp
	    return false if line !~ /^[A-Za-z\-]+$/

	    if line.size != 50
		return (io.eof? || io.read =~ /^\n*$/)
	    end
	end
	return true
    end
end

