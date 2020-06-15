#!/bin/bash
# Title: Find-Access Points in your environment
# Author: Pentestit.de, Frank Neugebauer
# Version: 0.1 - 2020/06/13
#
# You have to make sure to use the correct hardware (for 2.4 GHz and 5 GHz) and your WLAN-USB-Adapter is accepting
# monitor mode. The script needs Aircrack-ng and screen to run.
# Configure frequency in wif-shepherd.conf
#------------------------------------------------------------------------------------------------------
# Read configuration
. /home/pi/wifi-shepherd-ips/wifi-shepherd.conf

#set your WLAN-Adapter in monitor mode

echo -e  ""$C_on"Wait! Wifi-Shepherd will start scanning in view seconds! Stop with CTRL-C "$C_off"";
sleep 3; clear;
sudo ip link set "$Wifi_Iface" down
sudo iw dev "$Wifi_Iface" set type monitor
sudo ip link set "$Wifi_Iface" up

# this function is called when Ctrl-C is sent
clean_up () {
    # perform cleanup
    sudo ps -ax | grep "airodump-ng" |  awk '{print $1}' | xargs -I % -t kill -9 % >/dev/null 2>&1;
    echo ""; echo -e  ""$C_on"Clean up ... Wait! ..."$C_off"";
    sleep 5; clear;
    cat logo.txt;
    sudo ip link set "$Wifi_Iface" down;

    # exit shell script with error code 2
    # if omitted, shell script will continue execution
    exit 2
}

# when signal 2 (SIGINT) is received
trap "clean_up" 2
sudo airodump-ng  --band ag "$Wifi_MonIface"

