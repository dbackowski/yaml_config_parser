#!/usr/bin/env ruby

require 'yaml'
require 'optparse'                                                                                                                                                                                                                                                                                                                                                                                               

options = {}

optparse = OptionParser.new do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: #{script_name} [options]"

  opts.separator ""
  
  opts.on('-c', '--config FILE', 'YAML config file') do |c|
    options[:config] = c
  end

  opts.on('-f', '--file FILE', 'File to parse') do |f|
    options[:file] = f
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end

begin
  optparse.parse!
  required = [:file, :config]
  missing = required.select{ |param| options[param].nil? }
  
  if not missing.empty?               
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end


begin
  CONFIG = YAML::load(File.open(options[:config]))
rescue Exception => e
  $stderr.puts "Error occurred"
  $stderr.puts e
  exit 1
end

error = 0
puts "Generating file: #{options[:file]}"

begin
  lines = File.readlines(options[:file])
  i = 0

  lines.each { |line|
    i += 1
    line.scan(/(#\{([a-z0-9_]+):([a-z0-9_]+)\})/).each { |t|
      begin
        config_value = eval "CONFIG['#{t[1]}']['#{t[2]}']"
        config_value = config_value.to_s
      rescue
      end

      if config_value.nil?
        raise "Key \"#{t[2]}\" not found in section \"#{t[1]}\", file \"#{options[:file]}\" line number #{i}, yaml file: \"#{options[:config]}\"."
      else
        line.sub!(t[0], config_value)
      end
    }
  }

  output_file = File.open(options[:file], 'w')
  output_file.puts lines
rescue Exception => e
  $stderr.puts "Error occurred"
  $stderr.puts e
      
  error = 1
ensure
  unless output_file.nil?
    output_file.close()
  end
end

exit error
