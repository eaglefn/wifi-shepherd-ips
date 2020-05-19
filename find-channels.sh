#!/bin/sh
# Title: Find-Channels in your Wifi-Network
# Author: Pentestit.de, Frank Neugebauer
# Version: 0.1 - 2020/05/18
#
# If you are running a wireless mesh radio system in your local Wifi, you should find more than one Access Points
# and you should have more than on channel in use. The channels could also change from time to time. In this
# case the 2.4 GHz and the 5 GHz frequency band are used.
#
# This script will determine all channels your Wifi-Network is running on and will store them in a comma separated list.
#
# You have to make sure to use the correct hardware (for 2.4 GHz and 5 GHz) and your WLAN-USB-Adapter is accepting
# monitor mode. The script needs Aircrack-ng and screen to run.
#
# To run this scpript permanently create a conjob "crontab -e""
# e.g. this runs Find-Channels every day at 8:00  and at 17:00 -  0 8,17 * * * /home/pi/wifi-shepherd/find-channels.sh
#------------------------------------------------------------------------------------------------------
# Make your settings here!
Wifi_Iface="wlan1"
Wifi_MonIface="wlan1" 	 # check with ifconfig that you are using the correct monitor interface
Wifi_Essid="FreeWiFi"      # this is the SSID, not the Mac-Address of your Access Point
Time_to_wait="30"        # time to run airodump-ng to collect channels (in seconds)
#-------------------------------------------------------------------------------------------------------
#set your WLAN-Adapter in monitor mode

sudo ip link set "$Wifi_Iface" down
sudo iw dev "$Wifi_Iface" set type monitor
sudo ip link set "$Wifi_Iface" up

#It is  not so easy to run airodump-ng in a background session while collecting data.
#For that reason I'm usig "screen" to run it and kill all sessions after a time period.

#runs airodump-ng and saves output to scan-01.csv
screen -d -m sudo airodump-ng -a -h --essid "$Wifi_Essid" -w scan --output-format csv "$Wifi_MonIface"
sleep  "$Time_to_wait"

#find all detached screen sessions and kill them
screen -ls | grep '(Detached)' | awk '{print $1}' | xargs -I % -t screen -X -S % quit >/dev/null 2>&1

#collect all channels from csv-file and store them in the file channels.txt
grep "$Wifi_Essid"  scan-01.csv | cut -d "," -f 4 | tr -d ' '| sort | uniq | sed '/-/d'  > channels.tmp

#create comma separated list with channels
echo $(paste -sd, channels.tmp) > channels.txt
cat channels.tmp
cat channels.txt

# cleanup
sudo rm scan-01.csv channels.tmp
sudo ip link set "$Wifi_Iface" down
