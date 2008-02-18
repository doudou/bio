$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'seq_rename'
require 'enumerator'
require 'set'

class TC_SeqRename < Test::Unit::TestCase
    BASEDIR      = File.expand_path(File.dirname(__FILE__))
    TEST_SET_DIR = File.join(BASEDIR, "seq_rename_set")

    attr_reader :workdir
    def setup
	@workdir = File.join(BASEDIR, "workdir")
	FileUtils.cp_r TEST_SET_DIR, workdir
    end

    def teardown
	FileUtils.rm_rf workdir
    end

    TEST_SEQUENCE_IDS = [1, 2, 3, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16, 19, 50]

    def test_build_renames
	Dir.chdir(workdir) do
	    result, ignored = build_renames 'caro', 'OsmuTD3', 1, 10
	    assert_equal(16, result.size)
	    assert(ignored.empty?)

	    expected_result = Hash.new
	    expected_result["10.1"] = ["caro_10_blablo.1", "OsmuTD3_19.1"]
	    expected_result["10.2"] = ["caro_10_blablo.2", "OsmuTD3_19.2"]
	    TEST_SEQUENCE_IDS.each do |id|
		next if id == 10
		expected_result[id.to_s] = ["caro_#{id}_blablo", "OsmuTD3_#{id + 9}"]
	    end
	    assert_equal(expected_result, result)

	    result, ignored = build_renames 'caro', 'OsmuTD4', 8, 2

	    expected_result = Hash.new
	    expected_result["10.1"] = ["caro_10_blablo.1", "OsmuTD4_4.1"]
	    expected_result["10.2"] = ["caro_10_blablo.2", "OsmuTD4_4.2"]
	    TEST_SEQUENCE_IDS.each do |id|
		if id >= 8 && id != 10
		    expected_result[id.to_s] = ["caro_#{id}_blablo", "OsmuTD4_#{id - 6}"]
		end
	    end
	    assert_equal(expected_result, result)
	    assert_equal(5, ignored.size)

	    result, ignored = build_renames 'wrong', '', 10, 50
	    assert(result.empty?)
	    assert(ignored.empty?)
	end
    end

    def test_perform_renames
	Dir.chdir(workdir) do
	    renames, ignored = build_renames 'caro', 'OsmuTD4', 8, 2
	    File.open('/dev/null', 'w') do |logfile|
		perform_rename logfile, renames
	    end

	    expected_filelist = Set.new
	    expected_result = Hash.new
	    expected_result["10.1"] = ["caro_10_blablo.1", "OsmuTD4_4.1"]
	    expected_result["10.2"] = ["caro_10_blablo.2", "OsmuTD4_4.2"]
	    TEST_SEQUENCE_IDS.each do |id|
		next if id == 10
		if id >= 8 
		    expected_result[id.to_s] = ["caro_#{id}_blablo", "OsmuTD4_#{id - 6}"]
		else
		    expected_filelist << "caro_#{id}_blablo"
		end
		expected_result
	    end
	    assert_equal expected_result, renames

	    expected_filelist.merge expected_result.values.map { |_, target| target }.to_set
	    assert_equal expected_filelist, Dir.enum_for(:glob, '*').to_set
	end
    end
end

