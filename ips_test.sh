#!/bin/bash
# Title: Wifi-Shepherd Intrusion Protection
# Author: Pentestit.de, Frank Neugebauer
# Version: 0.1 - 2020/05/26
#
#------------------------------------------------------------------------------------------------------
# Make your settings here!
Wifi_Iface="wlan1"
Wifi_MonIface="wlan1"    # check with ifconfig that you are using the correct monitor interface
Wifi_Essid="YourSSID"      # this is the SSID, not the Mac-Address of your Access Point
Use5GHz=false		 # use an anettene for 2.4 Ghz und 5 GHz networks, set "false" for 2.4 Ghz only
MacKnown_FILE="mac_known.txt"
MacDiff_FILE="mac_diff.txt"
MacIdent_FILE="mac_ident.txt"
DevFound_FILE="found.txt"
C_on="\e[1;31m"          # Text color on/off use 31=red, 32=green, 36=Cyan, 35=purble
C_off="\e[0m"
#
#-------------------------------------------------------------------------------------------------------

# Funktion attack
attack () {
   [[ $# -ne 2 ]] && echo Usage: $0 [blacklist channels] && exit -1
   blacklist=$1
   channels=$2

   # set the Wifi adapter in monitor mode
   sudo ip link set "$Wifi_Iface" down
   sudo iw dev "$Wifi_Iface" set type monitor
   if [ $Use5GHz == true ];
     then
       sudo iw "$Wifi_Iface" set channel 36;
       sudo iw "$Wifi_Iface" set txpower fixed 3000
   fi;
   sudo ip link set "$Wifi_Iface" up;

   #store channels in a variable
   channel=$(cat $channels);

   #start attack
   screen -d -m sudo mdk4 "$Wifi_MonIface" d -b "$blacklist" -c "$channel";

   #set wifi adapter off
   sudo ip link set "$Wifi_Iface" down
}

# Main program
clear
cat logo.txt
echo ""
touch blacklist.txt
while true
do
   echo ""
   echo "0 - Reset Wifi-Shepherd"
   echo ""
   echo "1 - List connected devices"
   echo "2 - List new devices found"
   echo "3 - Discover channels"
   echo "4 - Start to attack intruders"
   echo "5 - Watch attacks"
   echo "6 - Cancel all attacks and delete devices found"
   echo "7 - Cancel all attacks and add found devices"
   echo ""
   echo "q - quit"
   echo ""
   echo -n "Input: "
   read answer
   case "$answer" in
       0) echo "";echo -n "Do you really want to reset Wifi-Sehpherd? This will remove all stored mac adresses! y/n: ";
          read remove;
          clear;
          if [ "$remove" == "y" ];
            then
              rm mac_known.txt;
              clear;
              echo -e  ""$C_on"Reset successful! "$C_off""
          fi
       ;;
       1) clear;
       	 echo -n "Last Scan:"; cat LastScan.txt;
         echo "";
         csvlook -d ";" nmap.tmp;
         echo ""; echo -n "Devices currently available: ";
         tail -n +2 nmap.tmp  | wc -l 
      ;;
      2) #Check if file exists
         testfile="$DevFound_FILE";
         if ! [ -f "$testfile" ];
            then 
               clear;
               echo -e  ""$C_on"No new devices found yet! "$C_off"";
               continue
         fi

         #If DevFound_FILE has more the on line then list devices
         if read -r && read -r
         then clear;
            echo -n "Last Scan:"; cat LastScan.txt;
            echo "";
            csvlook -d ";" "$DevFound_FILE"
            echo ""; echo -n "New devices found ready to attack: ";
            tail -n +2 "$DevFound_FILE"  | wc -l

         else clear;
            echo  ""; echo -e  ""$C_on"No new devices found yet! "$C_off""
         fi < "$DevFound_FILE"
      ;;
      3) clear;
         echo "This can take view seconds ..."; echo"";
         bash find-channels.sh
      ;;
      4) #Check if file exists
         testfile="$DevFound_FILE";
         if ! [ -f "$testfile" ];
            then
               clear;
               echo -e  ""$C_on"No new devices found yet! "$C_off"";
               continue
         fi
         clear;
         #If DevFound_FILE has more the on line then start attack
         if read -r && read -r
            then
               # Create a blacklist with devices found and available
               echo -e ""$C_on"Use Option 5 to watch the attack on a differnt screen."$C_off"";
               cat "$DevFound_FILE"  | cut -d ";" -f 3 | sed '1,1d' | sed 's/"//g' > blacklist.txt;

               #Call function attack, make sure to collect used channels with option 3 before
               attack blacklist.txt channels.txt
            else
               clear;
               echo -e ""$C_on"Nothing to attack!"$C_off""
         fi < "$DevFound_FILE"
      ;;
      5) clear;
         echo -e ""$C_on"Use Ctrl+AD to close attack screen!"$C_off"";
         screen -r
      ;;
      6) clear;
         screen -ls | grep '(Detached)' | awk '{print $1}' | xargs -I % -t screen -X -S % quit >/dev/null 2>&1;
         echo -n -e  ""$C_on"All attacks are canceled! "$C_odd"";
         sudo ip link set "$Wifi_Iface" down;
         if [ -s "$DevFound_FILE" ];
         then
           rm  "$DevFound_FILE" "$MacIdent_FILE" "$MacDiff_FILE";
           echo -e  ""$C_on"Found devices deleted!"$C_off""
         else
           echo -e ""$C_on"Nothing to delete!"$C_off""
         fi
         if [ -s blacklist.txt ];
         then
            rm  blacklist.txt
         fi
      ;;
      7) clear;
         screen -ls | grep '(Detached)' | awk '{print $1}' | xargs -I % -t screen -X -S % quit >/dev/null 2>&1;
         echo -n -e ""$C_on"All attacks are canceled! "$C_off"";
         sudo ip link set "$Wifi_Iface" down;
         if [ -s "$DevFound_FILE" ];
         then
           #Add files found to known devices
           grep -Fxvf "$MacKnown_FILE" "$MacIdent_FILE" >> "$MacKnown_FILE";
           #Remove files
           rm  "$DevFound_FILE"  "$MacDiff_FILE"  ;
           echo -e  ""$C_on"Found devices added!"$C_off""
         else
           echo -e ""$C_on"Nothing to add!"$C_off""
         fi
         if [ -s blacklist.txt ];
         then
            rm  blacklist.txt
         fi
         if [ -s "$MacIdent_FILE" ];
         then
            rm  "$MacIdent_FILE"
         fi
        ;;
      q) exit
      ;;
      *) echo -e ""$C_on"Try again!"$C_off""
      ;;
   esac
done
