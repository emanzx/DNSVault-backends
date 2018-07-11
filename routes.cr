## This script will configure node routes settings based on
## json file as database backend.

### Configuration Parameters
#### Move the static configuration file to yaml config file. 
config_file = "/home/system/dnsvault/configs/settings.yml"

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
route_file = config_yaml["routes"]["route_file"].as_s

# load json db.
if File.file?(json_path)
    json_file =  File.read(json_path)
    routes_settings = JSON.parse(json_file)
else
    puts "Error #{json_path} not found!"
    exit 1
end


# process each route hash then write to file.
# write parameter to configs file.
routes_template = ""
routes_v4_template = ""
routes_v6_template = ""
route_v4_names = ""
route_v6_names = ""
route_v4_default = routes_settings["default_router_ipv4"]?.to_s
route_v6_default = routes_settings["default_router_ipv6"]?.to_s
route_static_v4 = routes_settings["static"]["ipv4"]?
route_static_v6 = routes_settings["static"]["ipv6"]?

#process default routes
routes_template = "#IPv4 Default Route\ndefaultrouter=\"#{route_v4_default}\"\n" unless route_v4_default.empty?
routes_template = "#{routes_template}" + "#IPv6 Default Route\nipv6_defaultrouter=\"#{route_v6_default}\"\n" unless route_v6_default.empty?
routes_template = routes_template + "\n"

#process v4 routes
if route_static_v4
    route_static_v4.each do |route|

        route_name = route["route_name"]?.to_s
        address = route["address"]?.to_s
        prefix = route["netmask"]?.to_s.split("/")[1] if route["netmask"]?.to_s
        gateway = route["gateway"]?.to_s
        interface = route["interface"]?.to_s

        if prefix == "32"
            unless interface.empty?
                routes_v4_template = routes_v4_template + "route_#{route_name}=\"-host #{address} -iface #{interface}\"\n"
            else
                routes_v4_template = routes_v4_template + "route_#{route_name}=\"-host #{address} #{gateway}\"\n"
            end
        else
            unless interface.empty?
                routes_v4_template = routes_v4_template + "route_#{route_name}=\"-net #{address}/#{prefix} -iface #{interface}\"\n"
            else
                routes_v4_template = routes_v4_template + "route_#{route_name}=\"-net #{address}/#{prefix} #{gateway}\"\n"
            end
        end
        route_v4_names = route_v4_names + "#{route_name} "
    end
end

#process v6 routes
if route_static_v6
    route_static_v6.each do |route|

        route_name = route["route_name"]?.to_s
        address = route["address"]?.to_s
        prefix = route["prefix"]?.to_s
        gateway = route["gateway"]?.to_s

        routes_v6_template = routes_v6_template + "ipv6_route_#{route_name}=\"#{address} -prefixlen #{prefix} #{gateway}\"\n"
        route_v6_names = route_v6_names + "#{route_name} "
    end
end

# generating routing parameter for IPv4
unless route_v4_names.empty?
    ipv4_routes_names = "#IPv4 Static Routes\nstatic_routes=\"#{route_v4_names.strip}\"\n"
    routes_v4_template = ipv4_routes_names + routes_v4_template + "\n"
else
    routes_v4_template = ""
end

# generating routing parameter for IPv6
unless route_v6_names.empty?
    ipv6_routes_names = "#IPv6 Static Routes\nipv6_static_routes=\"#{route_v6_names.strip}\"\n"
    routes_v6_template = ipv6_routes_names + routes_v6_template
else
    routes_v6_template  = ""
end


#aggregating settings.
routes_template = routes_template + routes_v4_template  + routes_v6_template
if test_mode
    puts routes_template
else
    #writing setting to file.
    File.write(route_file, routes_template)
end