require 'minitest/autorun'
require 'minitest/spec'
require 'fasta'
require 'tmpdir'

describe FastaProcessing do
    attr_reader :base_dir
    attr_reader :output_dir

    before do
        base_dir = File.expand_path(File.dirname(__FILE__))
        @base_dir = File.join(base_dir, 'fasta')
        @output_dir = Dir.mktmpdir
    end

    after do
        FileUtils.rm_rf output_dir if output_dir
    end

    def assert_generate_expected(filename, prefix: '')
        full = File.expand_path(filename, output_dir)
        expected = File.join(base_dir, 'expected', "#{prefix}#{filename}")
        assert_equal File.read(expected), File.read(full)
    end

    describe "#perform_sequence_renames" do
        it "generates a new file with the renamed sequences" do
            FastaProcessing.new.perform_sequence_renames(File.join(base_dir, 'test.fas'),
                                             File.join(base_dir, 'test.nds'),
                                             output: File.join(output_dir, 'test.renamed'))
            assert_generate_expected 'test.renamed'
        end
    end
end
