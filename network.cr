## This script will configure node network settings based on
## json file as database backend.

### Configuration Parameters
# json_path = "/home/system/settings/interfaces.json"
# iface_file = "/etc/settings/networks.conf"
json_path = "/home/system/DNSVault-backends/settings/interfaces.json"
iface_file = "/home/system/DNSVault-backends/etc/settings/networks.conf"

### Dependencies ###
require "json"
require "ipaddr"

### Functions ###


### Code Begin Here ###

# load json db.
json_file =  File.read(json_path)
network_settings = JSON.parse(json_file)
puts network_settings

# # process each interface hash then write to file.
# # write parameter to configs file.
# iface_template = "#Network Settings \n"
# network_settings["interfaces"].each do |iface|

#     iface_name = iface["name"]
#     iface_ipv4 = iface["ipv4_address"]
#     iface_ipv4_subnetmask = iface["ipv4_subnetmask"]
#     iface_ipv6_state = iface["ipv6_state"]
#     iface_ipv6_auto_configure = iface["ipv6_auto_configure"]
#     iface_ipv6 = iface["ipv6_address"]
#     iface_ipv6_prefix = iface["ipv6_prefix"]
#     iface_aliases = iface["aliases"]

#     iface_template = iface_template + "#Interface settings for #{iface_name}\n"
#     unless iface_name.nil? or iface_ipv4.nil? or iface_ipv4_subnetmask.nil?
#         #process v4 address
#         iface_template = iface_template + "#IPv4\n"
#         iface_template = iface_template + "ifconfig_#{iface_name}=\"inet #{iface_ipv4} netmask #{iface_ipv4_subnetmask}\"\n"

#         #process v4 alias
#         unless iface_aliases["ipv4"].nil?
#             alias_index = 0
#             iface_template = iface_template + "#IPv4 alias\n"
#             iface_aliases["ipv4"].each do |a|
#                 alias_v4_address = a["address"]
#                 alias_v4_subnet = a["subnetmask"]

#                 iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet #{alias_v4_address} netmask #{alias_v4_subnet}\"\n"
#                 alias_index+=1
#             end
#         end
#     end

#     if iface_ipv6_state
#         if iface_ipv6_auto_configure
#             iface_template = iface_template + "#IPv6\n"
#             iface_template = iface_template + "ifconfig_#{iface_name}=\"inet6 accept_rtadv\"\n"
#         else
#             unless iface_name.nil? or iface_ipv6.nil? or iface_ipv6_prefix.nil?
#                 #process v6 address
#                 iface_template = iface_template + "#IPv6\n"
#                 iface_template = iface_template + "ifconfig_#{iface_name}=\"inet6 #{iface_ipv6} prefixlen #{iface_ipv6_prefix}\"\n"

#                 #process v6 alias
#                 unless iface_aliases["ipv6"].nil?
#                     alias_index = 0
#                     iface_template = iface_template + "#IPv6 alias\n"
#                     iface_aliases["ipv6"].each do |a|
#                         alias_v6_address = a["address"]
#                         alias_v6_prefix = a["prefix"]

#                         iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet6 #{alias_v6_address} prefixlen #{alias_v6_prefix}\"\n"
#                         alias_index+=1
#                     end
#                 end
#             end
#         end
#     end
#     iface_template = iface_template +"\n"
# end
