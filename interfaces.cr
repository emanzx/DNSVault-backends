## This script will configure node network settings based on
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

json_path = config_yaml["interfaces"]["json_file"].as_s
iface_file = config_yaml["interfaces"]["iface_file"].as_s

# load json db.
if File.file?(json_path)
    json_file =  File.read(json_path)
    network_settings = JSON.parse(json_file)
else
    puts "Error #{json_path} not found!"
    exit 1
end


# process each interface hash then write to file.
# write parameter to configs file.
iface_template = ""
clone_interfaces = [] of String
vlan_interface = {} of String => Array(Int32)
lagg_index = 0
network_settings["interfaces"].each do |iface|


    iface_state = iface["state"]?
    iface_name = iface["name"]?
    iface_ipv4 = iface["ipv4_address"]?
    iface_ipv4_netmask = iface["ipv4_netmask"]?
    iface_ipv6_state = iface["ipv6_state"]?
    iface_ipv6_type = iface["ipv6_type"]?
    iface_ipv6 = iface["ipv6_address"]?
    iface_ipv6_prefix = iface["ipv6_prefix"]?
    iface_aliases = iface["aliases"]?
    iface_high_availability = iface["high_availability"]?
    iface_ha_roles = iface["ha_roles"]?
    iface_type = iface["type"]?
    iface_bond_mode = iface["mode"]?
    iface_parents = iface["parent"]?.to_s
    iface_vlan_id = iface["vlan_id"]?.to_s.to_i rescue 0

    next unless iface_state.try( &.as_bool? )
    alias_index = 0
    iface_template = iface_template + "#Interface settings for #{iface_name}\n"
    if  iface_name && iface_ipv4 && iface_ipv4_netmask
        if iface_type == "lagg"
            #rename iface name to laggN
            iface_name = "lagg#{lagg_index}"
            #increase lagg_index
            lagg_index+=1
            #add interface to cloned interface
            clone_interfaces << iface_name.to_s
            #activate parrent interface
            iface_template = iface_template + "#Parent interfaces \n"
            laggports = ""
            iface_parents.split(" ").each do |i|
                iface_template = iface_template + "ifconfig_#{i}=\"up\"\n"
                #agregating network interface
                laggports = laggports + " laggport #{i}"
            end
            #process v4 address
            #split netmask
            iface_ipv4_split_netmask = iface_ipv4_netmask.to_s.split("/")[0]
            iface_template = iface_template + "#IPv4\n"
            iface_template = iface_template + "ifconfig_#{iface_name}=\"inet #{iface_ipv4} netmask #{iface_ipv4_split_netmask} laggproto #{iface_bond_mode} #{laggports.strip}\"\n"
        elsif iface_type == "vlan"
            #add curent vlan to vlan tag
            if vlan_interface.empty?
                vlan_interface["#{iface_parents}"] = [iface_vlan_id]
            elsif vlan_interface.has_key?("#{iface_parents}")
                vlan_interface["#{iface_parents}"] << iface_vlan_id
            elsif !vlan_interface.has_key?("#{iface_parents}")
                vlan_interface["#{iface_parents}"] = [iface_vlan_id]
            else
                puts "Error configuring Vlan :#{iface_name}"
                next
            end
            #process v4 address
            #split netmask
            iface_ipv4_split_netmask = iface_ipv4_netmask.to_s.split("/")[0]
            iface_template = iface_template + "#IPv4\n"
            iface_template = iface_template + "ifconfig_#{iface_name}=\"inet #{iface_ipv4} netmask #{iface_ipv4_split_netmask}\"\n"
        else
            #process v4 address
            #split netmask
            iface_ipv4_split_netmask = iface_ipv4_netmask.to_s.split("/")[0]
            iface_template = iface_template + "#IPv4\n"
            iface_template = iface_template + "ifconfig_#{iface_name}=\"inet #{iface_ipv4} netmask #{iface_ipv4_split_netmask} -lro -rxcsum -rxcsum6 -txcsum -txcsum6 -tso -tso6\"\n"
        end
        #process v4 alias and HA
        if iface_aliases && iface_aliases["ipv4"]?
            iface_template = iface_template + "#IPv4 alias\n"
            iface_aliases["ipv4"].each do |a|
                alias_v4_address = a["address"]
                alias_v4_netmask = a["netmask"].to_s.split("/")[0]

                if alias_v4_address && alias_v4_netmask
                    iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet #{alias_v4_address} netmask #{alias_v4_netmask}\"\n"
                    alias_index+=1
                end
            end
        end

        #process v4 HA
        if iface_high_availability.try( &.as_bool? )
            if iface_ha_roles && iface_ha_roles["ipv4"]?
                iface_template = iface_template + "#IPv4 High Availability\n"
                iface_ha_roles["ipv4"].each do |ha|
                    ha_v4_address = ha["address"]
                    ha_v4_netmask = ha["netmask"]
                    ha_v4_password = ha["password"]
                    ha_v4_vhid = ha["vhid"]
                    ha_v4_adskew = ha["adskew"]
                    ha_v4_type = ha["type"]
                    
                    if ha_v4_type == "master"
                        if ha_v4_address && ha_v4_netmask && ha_v4_password && ha_v4_vhid
                            iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet #{ha_v4_address} netmask #{ha_v4_netmask} vhid #{ha_v4_vhid} pass #{ha_v4_password}\"\n"
                            alias_index+=1
                        end
                    elsif ha_v4_type == "slave"
                        if ha_v4_address && ha_v4_netmask && ha_v4_password && ha_v4_vhid && ha_v4_adskew
                            iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet #{ha_v4_address} netmask #{ha_v4_netmask} vhid #{ha_v4_vhid} advskew #{ha_v4_adskew} pass #{ha_v4_password}\"\n"
                            alias_index+=1
                        end
                    end
                end
            end
        end
    end

    if iface_ipv6_state.try( &.as_bool? )
        if iface_ipv6_type == "auto"
            iface_template = iface_template + "#IPv6\n"
            iface_template = iface_template + "ifconfig_#{iface_name}_ipv6=\"inet6 accept_rtadv\"\n"

        elsif iface_ipv6_type == "link_local"
            iface_template = iface_template + "#IPv6\n"
            iface_template = iface_template + "ifconfig_#{iface_name}_ipv6=\"inet6 auto_linklocal\"\n"

        elsif iface_ipv6_type == "dhcpv6"
            iface_template = iface_template + "#IPv6\n"
            iface_template = iface_template + "ifconfig_#{iface_name}_ipv6=\"DHCP\"\n"

        elsif iface_ipv6_type == "static"
            if iface_name && iface_ipv6 && iface_ipv6_prefix
                #process v6 address
                iface_template = iface_template + "#IPv6\n"
                iface_template = iface_template + "ifconfig_#{iface_name}_ipv6=\"inet6 #{iface_ipv6} prefixlen #{iface_ipv6_prefix}\"\n"

                #process v6 alias
                if iface_aliases && iface_aliases["ipv6"]?
                    iface_template = iface_template + "#IPv6 alias\n"
                    iface_aliases["ipv6"].each do |a|
                        alias_v6_address = a["address"]
                        alias_v6_prefix = a["prefix"]
                        if alias_v6_address && alias_v6_prefix
                            iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet6 #{alias_v6_address} prefixlen #{alias_v6_prefix}\"\n"
                            alias_index+=1
                        end
                    end
                end

                #process v6 HA
                if iface_high_availability.try( &.as_bool? )
                    if iface_ha_roles && iface_ha_roles["ipv6"]?
                        iface_template = iface_template + "#IPv6 High Availability\n"
                        iface_ha_roles["ipv6"].each do |ha|
                            ha_v6_address = ha["address"]
                            ha_v6_prefix = ha["prefix"]
                            ha_v6_password = ha["password"]
                            ha_v6_vhid = ha["vhid"]
                            ha_v6_adskew = ha["adskew"]
                            ha_v6_type = ha["type"]
                            
                            if ha_v6_type == "master"
                                if ha_v6_address && ha_v6_prefix && ha_v6_password && ha_v6_vhid
                                    iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet6 #{ha_v6_address} prefixlen #{ha_v6_prefix} vhid #{ha_v6_vhid} pass #{ha_v6_password}\"\n"
                                    alias_index+=1
                                end
                            elsif ha_v6_type == "slave"
                                if ha_v6_address && ha_v6_prefix && ha_v6_password && ha_v6_vhid && ha_v6_adskew
                                    iface_template = iface_template + "ifconfig_#{iface_name}_alias#{alias_index}=\"inet6 #{ha_v6_address} prefixlen #{ha_v6_prefix} vhid #{ha_v6_vhid} advskew #{ha_v6_adskew} pass #{ha_v6_password}\"\n"
                                    alias_index+=1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
     iface_template = iface_template + "\n"
end
# generating clone interface parameter
if ! clone_interfaces.empty?
    clone_iface = "#Cloned Interfaces\ncloned_interfaces=\"#{clone_interfaces.join(" ")}\"\n\n"
else
    clone_iface = ""
end
#generating vlan interface tag for each parent interface
if ! vlan_interface.empty?
    vlan_tags = "#Vlans interfaces\n"
    vlan_interface.each do |vlan_if|
        parent_if = vlan_if[0]
        vlan_ids = vlan_if[1].join(" ")
        vlan_tags = vlan_tags + "vlans_#{parent_if}=\"#{vlan_ids}\"\n"
    end
    vlan_tags = vlan_tags + "\n"
else
    vlan_tags = ""
end

#aggregating settings.
iface_template = "#Network Settings \n\n" + clone_iface + vlan_tags + iface_template
if test_mode
    puts iface_template
else
    #writing setting to file.
    File.write(iface_file, iface_template)
end