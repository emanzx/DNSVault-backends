## This script will configure node resolver settings based on
## json file as database backend.

### Configuration Parameters
#### Move the static configuration file to yaml config file. 
config_file = "/home/system/dnsvault/configs/settings.yml"
test_mode = false

### Dependencies ###
require "json"
require "yaml"
require "option_parser"


# Excutable argument settings.
# -t to run in verbose test mode.
# https://crystal-lang.org/api/0.18.7/OptionParser.html
OptionParser.parse! do |parser|
    parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"
    parser.on("-t", "--test", "Run in test mode. Only output to stdout and will not write to file.") { test_mode = true }
    parser.on("-h", "--help", "Show this help") { puts parser }
  end

### Load external variable
unless File.file?(config_file)
    puts "Error!! Config file not found at #{config_file}"
    exit 1
else
    config_yaml = YAML.parse(File.read("#{config_file}"))
end

### Functions ###


### Code Begin Here ###
json_path = config_yaml["routes"]["json_file"].as_s
resolv_file = config_yaml["routes"]["route_file"].as_s

# load json db.
if File.file?(json_path)
    json_file =  File.read(json_path)
    resolv_settings = JSON.parse(json_file)
else
    puts "Error #{json_path} not found!"
    exit 1
end


# process each resolver hash then write to file.
# write parameter to configs file.
resolv_template = ""
resolver_list = resolv_settings["resolver"]?

#process resolver
if resolver_list
    resolver_list.each do |resolv|
        resolv_key = resolv.as_h.keys.first
        resolv_value = resolv["#{resolv_key}"]
        resolv_template = resolv_template + "#{resolv_key} #{resolv_value}\n"
    end
end
if test_mode
    puts resolv_template
else
    #writing setting to file.
    File.write(resolv_file, resolv_template)
end