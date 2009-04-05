$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'test/unit'
require 'formats'

class TC_FastaToTcs < Test::Unit::TestCase
    BASEDIR      = File.expand_path(File.dirname(__FILE__))

    def test_fasta_to_tcs
        assert(is_fasta?(File.join(BASEDIR, "fasta2tcs", "test4tcs.fas")))
    end
end

