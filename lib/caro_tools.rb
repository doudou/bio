def ask(question, default = nil)
    print question
    if default == true || default == false
	if default
	    print " [Y/n]"
	else
	    print " [y/N]"
	end
    elsif !default.nil?
	print " [#{default}]"
    else
	print " "
    end

    loop do
	answer = STDIN.readline.chomp
	if answer.empty? && !default.nil?
	    return default
	elsif answer =~ /^[YyOo]$/
	    return true
	elsif answer =~ /^[Nn]$/
	    return false
	elsif default.nil?
	    return answer
	else
	    print "please answer 'y' or 'n'"
	end
    end
end

