## This script will configure node resolver settings based on
## json file as database backend.

### Configuration Parameters
#### Move the static configuration file to yaml config file. 
config_file = "/home/system/dnsvault/configs/settings.yml"

### Dependencies ###
require "json"
require "yaml"

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

puts resolv_template

#writing setting to file.
File.write(resolv_file, resolv_template)