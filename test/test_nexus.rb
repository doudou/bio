require 'minitest/autorun'
require 'minitest/spec'
require 'nexus'
require 'tmpdir'

describe NexusProcessing do
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

    def assert_generate_expected(filename, prefix: '')
        full = File.expand_path(filename, output_dir)
        expected = File.join(base_dir, 'expected', "#{prefix}#{filename}")
        assert_equal File.read(expected), File.read(full)
    end

    subject { NexusProcessing.from_config_file(File.join(base_dir, 'test.config')) }

    describe ".default_rename_output_path" do
        it "inserts .renamed. between the basename and the extension" do
            assert_equal "a/nexus/file.renamed.nex",
                NexusProcessing.default_rename_output_path("a/nexus/file.nex")
        end
    end

    describe "#perform_sequence_renames" do
        it "generates a new file with the renamed sequences" do
            subject.perform_sequence_renames(File.join(base_dir, 'test.nexus'),
                                             File.join(base_dir, 'test.nds'),
                                             output: File.join(output_dir, 'test.renamed'))
            assert_generate_expected 'test.renamed'
        end
    end

    describe "#process" do
        it "generates one nexus file per trait" do
            subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
            assert_generate_expected 'habitat.nex'
        end

        it "generates one csv file per trait" do
            subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
            assert_generate_expected 'habitat.csv'
        end

        it "generates one nexus file for the geotags" do
            subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
            assert_generate_expected 'geotags.nex'
        end

        it "generates one csv file for the geotags" do
            subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
            assert_generate_expected 'geotags.csv'
        end

        describe "without geotags" do
            subject { NexusProcessing.from_config_file(File.join(base_dir, 'test-nogeotags.config')) }

            it "does not require the geotags" do
                subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
                assert_generate_expected 'habitat.nex'
                assert_generate_expected 'habitat.csv'
                assert !File.exists?(File.join(output_dir, 'geotags.nex'))
                assert !File.exists?(File.join(output_dir, 'geotags.csv'))
            end
        end

        describe "without renaming" do
            subject { NexusProcessing.from_config_file(File.join(base_dir, 'test-norename.config')) }

            it "does not require to rename" do
                subject.process(File.join(base_dir, 'test.nexus'), output_dir: output_dir)
                assert_generate_expected 'habitat.nex', prefix: 'norename-'
                assert_generate_expected 'habitat.csv', prefix: 'norename-'
                assert_generate_expected 'geotags.nex', prefix: 'norename-'
                assert_generate_expected 'geotags.csv', prefix: 'norename-'
            end
        end
    end
end

