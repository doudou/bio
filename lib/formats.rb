def is_fasta?(file)
    File.open(file) do |io|
	return false if io.readline !~ /^>/
	
	while !io.eof?
	    line = io.readline
	    return false if line !~ /^[A-Za-z\-]+\n$/

	    if line.size != 51
		return (io.eof? || io.read =~ /^\n+$/)
	    end
	end
	return true
    end
end

