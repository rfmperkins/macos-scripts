#!/bin/sh

# Build Date 09/12/2023 
# Built by Robert Perkins 
# Purpose: For macOS hardware information gathering



clear
sExternalMACALService="http://dns.kittell.net/macaltext.php?address="

# List all Network ports
NetworkPorts=$(ifconfig -uv | grep '^[a-z0-9]' | awk -F : '{print $1}')
#echo $NetworkPorts

# Function to convert IP Subnet Mask to CIDR
mask2cdr ()
{
# Assumes there's no "255." after a non-255 byte in the mask
local x=${1##*255.}
set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
x=${1%%$3*}
echo $(( $2 + (${#x}/4) ))
}

# Get remote/public IP address
remoteip=$(dig +short myip.opendns.com @resolver1.opendns.com)

# Get OS/HW Info
computername=$(scutil --get ComputerName)
os_name=$(sw_vers -productName)
os_version=$(sw_vers -productVersion)
os_build=$(sw_vers -buildVersion)
hw=$(system_profiler SPHardwareDataType | grep "Model Identifier")
uuid=$(system_profiler SPHardwareDataType | awk '/UUID/ { print $3 }')
disk0mount=$(diskutil info disk0 | grep "Device Node")
disk0model=$(diskutil info disk0 | grep "Device / Media Name")
disk0size=$(diskutil info disk0 | grep "Disk Size")
disk0smart=$(diskutil info disk0 | grep "SMART Status")
disk0loc=$(diskutil info disk0 | grep "Device Location")
ethdevicespeed=$(system_profiler SPEthernetDataType | grep "Maximum Link Speed")
appleethdeviceinfo=$(system_profiler SPEthernetDataType | grep "Apple ")
bcmethdeviceinfo=$(system_profiler SPEthernetDataType | grep "Broadcom")


# Get CPU Info
cpu_model=$(sysctl -n machdep.cpu.brand_string)
physical_cpus=$(sysctl -n hw.physicalcpu)
cpucores=$(sysctl -n machdep.cpu.core_count)
virt_cores=$(sysctl -n hw.ncpu)

# Get GPU Info
gpu_model=$(system_profiler SPDisplaysDataType | grep "Chipset Model")
gpu_cores=$(system_profiler SPDisplaysDataType | grep "Total Number of Cores")

# get memory info
ttl_mem=$(hostinfo | awk '/available:/ {print $4" "$5}')

# logs for last 5 seconds
logshow=$(log show --last 5s)

# Get serial number
sSerialNumber=$(system_profiler SPHardwareDataType |grep "Serial Number (system)" |awk '{print $4}'  | cut -d/ -f1)
#echo $sSerialNumber


# Get operating system name and version - Stop



echo " "
echo "System Information for $sSerialNumber"
echo "The current date and time is: $(date +"%m-%d-%Y %H:%M:%S")"
echo " "
echo "*********************************************"
echo " "
echo "	Computer Name:  $computername"
echo "	OS Name:  $os_name"
echo "	OS Version:  $os_version"
echo "	Version Build:  $os_build"
echo "  $hw"
echo "	Serial Number:  $sSerialNumber"
echo "	UUID:  $uuid"
echo " "
echo "*********************************************"
echo "CPU Information"
echo "      Processor:  $cpu_model"
echo "      Core Count:  $cpucores"
echo " "
echo "*********************************************"
echo "GPU Information"
echo "$gpu_model"
echo "$gpu_cores"
echo " "
echo "*********************************************"
echo "Memory Information"
echo "      $ttl_mem"
echo " "
echo "*********************************************"
echo "Storage Information"
echo "  disk0"
echo "$disk0mount"
echo "$disk0model"
echo "$disk0size"
echo "$disk0smart"
echo "$disk0loc"
echo "*********************************************"
#echo "Last 30 seconds of system logs"
#echo "$logshow"
#echo "*********************************************"
echo "Network Device Information"
echo " "
echo "--------------"
echo "Installed NIC 1G or 10G"
echo "$appleethdeviceinfo" "$bcmethdeviceinfo"
echo "$ethdevicespeed"




for val in $NetworkPorts; do   # Get for all available hardware ports their status
activated=$(ifconfig -uv "$val" | grep 'status: ' | awk '{print $2}')
#echo $activated
label=$(ifconfig -uv "$val" | grep 'type' | awk '{print $2}')
#echo $label
#ActiveNetwork=$(route get default | grep interface | awk '{print $2}')
ActiveNetworkName=$(networksetup -listallhardwareports | grep -B 1 "$label" | awk '/Hardware Port/{ print }'|cut -d " " -f3- | uniq)
#echo $ActiveNetwork
#echo $ActiveNetworkName
state=$(ifconfig -uv "$val" | grep 'status: ' | awk '{print $2}')
#echo $state
ipaddress=$(ifconfig -uv "$val" | grep 'inet ' | awk '{print $2}')
# echo $ipaddress

if [[ -z $(ifconfig -uv "$val" | grep 'link rate: ' | awk '{print $3, $4}' | sed 'N;s/\n/ up /' ) ]]; then
networkspeed="$(ifconfig -uv "$val" | grep 'link rate: ' | awk '{print $3}' ) up/down"
else
networkspeed="$(ifconfig -uv "$val" | grep 'link rate: ' | awk '{print $3, $4}' | sed 'N;s/\n/ up /' ) down"
fi

#echo $networkspeed
macaddress=$(ifconfig -uv "$val" | grep 'ether ' | awk '{print $2}')
#echo $macaddress
macal=$(curl -s "$sExternalMACALService$macaddress")
#echo $macal
quality=$(ifconfig -uv "$val" | grep 'link quality:' | awk '{print $3, $4}')
#echo $quality
netmask=$(ipconfig getpacket "$val" | grep 'subnet_mask (ip):' | awk '{print $3}')
#echo $netmask
router=$(ipconfig getpacket "$val" | grep 'router (ip_mult):' | sed 's/.*router (ip_mult): {\([^}]*\)}.*/\1/')
#echo $router
DHCPActive=$(networksetup -getinfo "Wi-Fi" | grep DHCP)
#echo $DHCPActive
dnsserver=$(networksetup -getdnsservers "$ActiveNetworkName" | awk '{print $1, $2}' | sed 'N;s/\n//' )
#echo $dnsserver

if [ "$activated" = 'active' ]; then
#echo "Network Port is Active"
if [[ $ipaddress ]]; then
echo "--------------"
echo "$ActiveNetworkName ($val)"
echo "--------------"
# Is this a WiFi associated port? If so, then we want the network name
if [ "$label" = "Wi-Fi" ]; then
WiFiName=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I | grep '\sSSID:' | sed 's/.*: //')
#echo $WiFiName
echo "     Network Name:  $WiFiName"
fi

echo "       IP Address:  $ipaddress"
echo "      Subnet Mask:  $netmask"
echo "           Router:  $router"
echo "          IP CIDR:  $ipaddress/$(mask2cdr $netmask)"

if [[ -z $dnsserver ]]; then
if [[ $DHCPActive ]]; then
echo "       DNS Server:  Set With DHCP"
else
echo "       DNS Server:  Unknown"
fi
else
echo "       DNS Server:  $dnsserver"
fi

echo "      MAC-address:  $macaddress ($macal)"
echo "    Network Speed:  $networkspeed"
echo "     Link quality:  $quality"
echo " "
fi

# Don't display the inactive ports.
fi



done