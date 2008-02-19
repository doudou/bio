$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'test/unit'
require 'formats'

class TC_Formats < Test::Unit::TestCase
    BASEDIR      = File.expand_path(File.dirname(__FILE__))

    def test_is_fasta
    	Dir.chdir(File.join(BASEDIR, "fasta_set")) do
	    Dir.glob('*') do |file|
	    	assert(is_fasta?(file))
	    end
	end
    end
end
