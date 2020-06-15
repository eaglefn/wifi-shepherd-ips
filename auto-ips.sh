#!/bin/bash
# Title:   Wifi-Shepherd Intrusion Protection
#          This script runs Auto-IPS
# Author:  Pentestit.de, Frank Neugebauer
# Version: 0.1 - 2020/05/26
#
#------------------------------------------------------------------------------------------------------
# Read configuration
. /home/pi/wifi-shepherd-ips/wifi-shepherd.conf

# Funktion attack
attack () {
   [[ $# -ne 2 ]] && echo Usage: $0 [blacklist channels] && exit -1
   blacklist=$1
   channels=$2

   # set the Wifi adapter in monitor mode
   sudo ip link set "$Wifi_Iface" down;
   sleep 10;
   sudo ip link set "$Wifi_Iface" up;
   sudo iw dev "$Wifi_Iface" set type monitor
   if [ $Use5GHz == true ];
     then
       sudo iw "$Wifi_Iface" set channel 36;
       sudo iw "$Wifi_Iface" set txpower fixed 3000
   fi;

   #store channels in a variable
   channel=$(cat $channels);

   #start attack
   screen -d -m sudo mdk4 "$Wifi_MonIface" d -b "$blacklist" -c "$channel";

   #set wifi adapter off
   sudo ip link set "$Wifi_Iface" down
}

# Main program
testfile="$DevFound_FILE";
if  [ -f "$testfile" ];
   then
      if read -r && read -r
         then
         # Create a blacklist with devices found and available
         cat "$DevFound_FILE"  | cut -d ";" -f 3 | sed '1,1d' | sed 's/"//g' > blacklist.txt;
         #Call function attack, make sure to collect used channels with option 3 before
         status=`cat /sys/class/net/wlan1/operstate`
         if ! [ "$status" == "up" ]; then
           attack blacklist.txt channels.txt
         fi
     fi < "$DevFound_FILE";
fi


