#! /usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'fileutils'
require 'caro_tools'

def build_renames(source_basename, species, start_number, target_number)
    renames = Hash.new
    ignored = []
    Dir.glob("#{source_basename}_*") do |file|
	if File.basename(file) =~ /^#{source_basename}_(\d+)/
	    id = Integer($1)
	    if id >= start_number
		ext = File.extname(file)
		renames["#{id}#{ext}"] = [file, "#{species}_#{id - start_number + target_number}#{ext}"]
	    else
		ignored << file
	    end
	end
    end

    return renames, ignored
end

def perform_rename(logfile, renames)
    logfile.puts
    logfile.puts "starting to rename at #{Time.now}"

    renames = renames.values_at(*renames.keys.sort)
    renames.each do |source, target|
	logfile.puts "  #{source} => #{target}"
	FileUtils.mv source, target
    end

    logfile.puts "done"

rescue Exception
    logfile.puts "failed"
    raise
end

def seq_rename
    source_basename = ask('source name ?')
    species       = ask('target name ?')
    start_number  = Integer(ask('source start number ?'))
    target_number = Integer(ask('target start number ?'))

    renames, ignored = build_renames(source_basename, species, start_number, target_number)

    if !ignored.empty?
	puts "Ignored #{ignored.size} files:"
	puts "  " + ignored.join("\n  ")
    end
    puts "Found #{renames.size} renames:"
    renames.
	values_at(*renames.keys.sort).
	each do |source, target|
	    puts "  #{source} => #{target}"
	end

    if ask('Is that OK ?', false)
	File.open("renames.log", 'a') do |logfile|
	    perform_rename(logfile, renames)
	end
    end

rescue Interrupt
    puts "Interrupted"
end

