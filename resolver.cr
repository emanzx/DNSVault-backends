## This script will configure node resolver settings based on
## json file as database backend.

### Configuration Parameters
# json_path = "/home/system/settings/routes.json"
# resolver_file = "/etc/resolv.conf"
json_path = "/home/system/DNSVault-backends/settings/resolv.json"
resolv_file = "/home/system/DNSVault-backends/etc/settings/resolv.conf"

### Dependencies ###
require "json"

### Functions ###


### Code Begin Here ###

# load json db.
json_file =  File.read(json_path)
resolv_settings = JSON.parse(json_file)


# process each route hash then write to file.
# write parameter to configs file.
resolv_template = ""
resolver_list = resolv_settings["resolver"]?

#process resolver
if resolver_list
    resolver_list.each do |resolv|

        resolv_key = resolv[0].to_s
        resolv_value = resolv[1].to_s
        resolv_template = resolv_template + "#{resolv_key} #{resolv_value}\n"
    end
end

puts routes_template

#writing setting to file.
File.write(resolv_file, resolv_template)