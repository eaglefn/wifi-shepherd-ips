#!/bin/sh
# Title: Wifi-Shepherd based on Raspberry Pi Zero W
# Author: Pentestit.de, Frank Neugebauer
# Version: 0.1 - 2020/04/20
#
# Wifi Shepherd scans your Wifi network and sneds an email with new devices found
# For more information see https://pentestit.de
#
# To run this scpript permanently create a conjob using "crontab -e"
# Runs Wifi Shepherd every 10 minutes -  */10 * * * * /home/pi/wifi-shepherd-ips/wifi-shepherd.sh
# Runs Wifi Shepherd every day at 8:00  and at 17:00 -  0 8,17 * * * /home/pi/wifi-shepherd-ips/wifi-shepherd.sh
#------------------------------------------------------------------------------------------------------
# Read configuration
. /home/pi/wifi-shepherd-ips/wifi-shepherd.conf

#Start nmap scan and save the output to nmap.raw
#Exclude Wifi-Shepherd Hostname from scan
cd  "$Wifi_Shepherd_DIR"
sudo nmap -sP  --exclude "$Wifi_Shepherd_Hostname" -oN  "$Wifi_Shepherd_DIR$Nmapoutput_FILE"  "$Wifi_Network" >/dev/null 2>&1

# Change ownership
sudo chown pi:pi "$Wifi_Shepherd_DIR$Nmapoutput_FILE"

#Convert  nmap.raw output to csv file
#See https://github.com/maaaaz/nmaptocsv for more information
sudo python "$Nmaptocsv_DIR"/nmaptocsv.py -i "$Nmapoutput_FILE"  -d ";" -n -f ip-fqdn-mac_address-mac_vendor > "$Nmapcsv_FILE"

# remove "" from  csv file
cat  nmap.csv | sed 's/"//g' > nmap.tmp

# copy html header to Webserverindex
cat html_head.txt > "$Webserverindex_FILE"

#convert csv file to html and copy to  Webserverindex
./csvtohtml.sh nmap.tmp >>  "$Webserverindex_FILE"

#Move Webserverindex to Webserver /var/www/html
sudo mv  "$Webserverindex_FILE" "$Webserver_DIR"

#Check if DataTables already exists on the webserver, if not copy all files
DIRECTORY="/var/www/html/js/"
if [ ! -d "$DIRECTORY" ]; then
  sudo cp -R js/ images/ css/ "$Webserver_DIR"
fi

#Take csv file and cut Mac-Addresses, store it to MacDetected
cat "$Nmapcsv_FILE"  | sed '1,1d' | cut -d ";" -f 3 > "$MacDetected_FILE"

#Check if we alrady have MacAddresses collected
testfile="$Wifi_Shepherd_DIR$MacKnown_FILE"
if ! [ -f "$testfile" ];then
      touch "$Wifi_Shepherd_DIR$MacKnown_FILE"
fi

#Compare detected MAC with known MAC and store differences in separate file (mac_diff.txt)
grep -Fxvf "$MacKnown_FILE" "$MacDetected_FILE" > "$Wifi_Shepherd_DIR$MacDiff_FILE"

case $IPS_Mode in
     false)
        #Compare detected MAC with known MAC and store differences in separate file (mac_diff.txt)
        #grep -Fxvf "$MacKnown_FILE" "$MacDetected_FILE" > "$Wifi_Shepherd_DIR$MacDiff_FILE";

        #Find new devices in csv file and prepare E-Mail attachment message.txt
        while read line; do grep $line "$Nmapcsv_FILE" ;done < "$MacDiff_FILE" > message.txt;
        if [ -s message.txt ];
           #Send email with alert if message.txt not empty
           then mail -s "$MessageText" "$EmailReceiver" < message.txt;
           #Add MAC-Addresses found to known MAC-Addresses
           cat  "$MacDiff_FILE" >> "$MacKnown_FILE"
        fi
        ;;
     true)
       #Check if we alrady have devices found that are not attacked
       testfile="$Wifi_Shepherd_DIR$MacIdent_FILE"
       if ! [ -f "$testfile" ];then
          touch "$Wifi_Shepherd_DIR$MacIdent_FILE"
       fi

       #Check if a mac found is alrady in our list
       grep -Fxvf "$MacIdent_FILE" "$MacDiff_FILE" > list.txt

       #Find new devices in csv file and prepare E-Mail attachment message.txt
       while read line; do grep $line "$Nmapcsv_FILE" ;done < list.txt  > message.txt;
       cat list.txt  >> "$MacIdent_FILE";
       if [ -s message.txt ];
          #Send email with alert if message.txt not empty
          then mail -s "$MessageText" "$EmailReceiver" < message.txt
        fi

       #Identify new Devices to attack
       cat nmap.tmp | sed '1,1!d' > "$DevFound_FILE"
       while read line; do grep $line "$Nmapcsv_FILE" ;done < "$MacIdent_FILE"  >> "$DevFound_FILE";
     ;;
     *)
esac


