## This script will configure node routes settings based on
## json file as database backend.

### Configuration Parameters
# json_path = "/home/system/settings/routes.json"
# iface_file = "/etc/settings/routes.conf"
json_path = "/home/system/DNSVault-backends/settings/interfaces.json"
iface_file = "/home/system/DNSVault-backends/etc/settings/networks.conf"

### Dependencies ###
require "json"

### Functions ###


### Code Begin Here ###

# load json db.
json_file =  File.read(json_path)
routes_settings = JSON.parse(json_file)


# process each route hash then write to file.
# write parameter to configs file.
routes_template = ""
routes_v4_template = ""
routes_v6_template = ""
route_v4_names = ""
route_v6_names = ""
route_v4_default = routes_settings["default_router_ipv4"]?
route_v6_default = routes_settings["default_router_ipv6"]?
route_static_v4 = routes_settings["static"]["ipv4"]?
route_static_v6 = routes_settings["static"]["ipv6"]?

#process default routes
routes_template = "IPv4 Default Route\ndefaultrouter=\"#{route_v4_default}\"\n" if route_v4_default
routes_template = "#{routes_template}" + "IPv6 Default Route\nipv6_defaultrouter=\"#{route_v6_default}\"\n" if route_v6_default
routes_template = routes_template + "\n"

#process v4 routes
route_static_v4.each do |route|

    route_name = route["route_name"]?.to_s
    address = route["address"]?.to_s
    prefix = route["netmask"]?.to_s.split("/")[1] if route["netmask"]?.to_s
    gateway = route["gateway"]?.to_s
    interface = route["interface"]?.to_s

    if prefix == "32"
        if interface
            routes_v4_template = routes_v4_template + "route_#{route_name}=\"-host #{address} -iface #{interface}\"\n"
        else
            routes_v4_template = routes_v4_template + "route_#{route_name}=\"-host #{address} #{gateway}\"\n"
        end
    else
        if interface
            routes_v4_template = routes_v4_template + "route_#{route_name}=\"-net #{address}/#{prefix} -iface #{interface}\"\n"
        else
            routes_v4_template = routes_v4_template + "route_#{route_name}=\"-net #{address}/#{prefix} #{gateway}\"\n"
        end
    end
    route_v4_names = route_v4_names + "#{route_name} "
end
#process v6 routes
route_static_v6.each do |route|

    route_name = route["route_name"]?.to_s
    address = route["address"]?.to_s
    prefix = route["netmask"]?.to_s.split("/")[1] if route["netmask"]?.to_s
    gateway = route["gateway"]?.to_s

    routes_v6_template = routes_v6_template + "ipv6_route_#{route_name}=\"#{address} -prefixlen #{prefix} #{gateway}\"\n"
    route_v6_names = route_v6_names + "#{route_name} "
end
    
# generating routing name parameter for IPv4
if route_v4_names
    ipv4_routes_names = "#IPv4 Static Routes\nstatic_routes=\"#{route_v4_names}.strip\"\n\n"
else
    ipv4_routes_names = ""
end

# generating routing name parameter for IPv6
if route_v6_names
    ipv6_routes_names = "#IPv6 Static Routes\nipv6_static_routes=\"#{route_v6_names}.strip\"\n\n"
else
    ipv6_routes_names = ""
end


#aggregating settings.
routes_template = ipv4_routes_names + ipv6_routes_names
puts routes_template

#writing setting to file.
File.write(route_file, routes_template)