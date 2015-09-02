require 'minitest/autorun'
require 'minitest/spec'
require 'nexus'
require 'tmpdir'

describe NexusProcessing do
    subject { NexusProcessing.from_config_file(File.join(base_dir, 'test.config')) }

    attr_reader :base_dir
    attr_reader :output_dir

    before do
        base_dir = File.expand_path(File.dirname(__FILE__))
        @base_dir = File.join(base_dir, 'nexus')
        @output_dir = Dir.mktmpdir
    end

    after do
        FileUtils.rm_rf output_dir if output_dir
    end

    def assert_generate_expected(filename)
        full = File.expand_path(filename, output_dir)
        expected = File.join(base_dir, 'expected', filename)
        assert_equal File.read(expected), File.read(full)
    end

    describe "#process" do
        it "generates one file per trait" do
            subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
            assert_generate_expected 'habitat.nex'
        end

        it "generates one file for the geotags" do
            subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
            assert_generate_expected 'geotags.nex'
        end
    end
end
