$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'test/unit'
require 'formats'
require 'stringio'

class TC_Formats < Test::Unit::TestCase
    BASEDIR      = File.expand_path(File.dirname(__FILE__))

    def test_is_fasta
    	Dir.chdir(File.join(BASEDIR, "fasta_set")) do
	    Dir.glob('*') do |file|
	    	assert(is_fasta?(file), file)
	    end
	end
    end

    OSMU6173_SEQ = "TTAATGCTTTCGCTAAGTCACGCACGGTGTATTGTGCACAACGAGTAATCATCGTTTACGGCGTGGACTACCAGGGTATCTAATCCTGTTCGCTCCCCACGCTTTCGTCCATCAGCGTCAATAATGGTTTAGTAAGCTGCCTTCGCAATTGGTGTTCTACGTTATATCTATGCATTTCACCGCTACATAACGTATTCCGCCTACCTCAACCATATTCAAGTCTTTCAGTTTCAATGGCAGTTCCAGAGTTGAGCTCTGGGATTTCACCACTGACTTAAAAGACCGCCTACGGACCCTTTAAACCCAATAAATCCGGATA:A:CGCTCGAATCCTCCGTATTACCGCGGCTGCTGGCACGGAGTTAGCCGATCCTTATTCATACAGTACATTCAAACTTCTACACGTAGAAGCAATTATTCCTGT"

    TEST4TCS_SEQNAMES = ["Osmu3-93A",
                "Osmu3-71A",
                "Osmu3-69A",
                "Osmu3-61A",
                "Osmu3-51A",
                "Osmu3-50A",
                "Osmu3-37A",
                "OSmu3-30A",
                "Osmu3-70A",
                "Osmu1-274A",
                "Osmu1-324A",
                "Osmu1-251A",
                "OT19-3398A",
                "OT19-3401A",
                "OT1-1002D",
                "OT1-1046A",
                "OT1-1050D",
                "OT1-1075",
                "OT2-1427A",
                "OT3-3114A",
                "OT3-3124A",
                "OT3-3152A",
                "OT3-3156A",
                "OT4-1781A",
                "OT4-1782A",
                "OT73-3868F",
                "OT75-40832",
                "OT76-2687E"]

    def test_read_fasta
        data = read_fasta File.join(BASEDIR, "fasta_set", "Osmu6_173.TXT")
        assert_equal 1, data.size
        assert_equal "Osmu6173", data.first.first
        assert_equal OSMU6173_SEQ, data.first.last

        data = read_fasta File.join(BASEDIR, "fasta2tcs", "test4tcs.fas")
        assert_equal 28, data.size
        assert_equal TEST4TCS_SEQNAMES, data.map { |name, _| name }
        assert data.all? { |_, data| data.size == 1419 }
    end

    def test_write_tcs
        data = read_fasta File.join(BASEDIR, "fasta2tcs", "test4tcs.fas")

        output = StringIO.new
        write_tcs "osedaxmucofloris_oceanosymbiontgroupA", data, output
        File.open 'test.out', 'w' do |io|
            io.write output.string
        end

        assert_equal File.read(File.join(BASEDIR, "fasta2tcs", "test4tcs.txt")), output.string
    end
end

