#!/bin/bash
# Title: Wifi-Shepherd Intrusion Protection
# Author: Pentestit.de, Frank Neugebauer
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
   sudo ip link set "$Wifi_Iface" down
   sudo iw dev "$Wifi_Iface" set type monitor
   sudo ip link set "$Wifi_Iface" up
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
   #sudo ip link set "$Wifi_Iface" down
}

# Main program
clear
cat logo.txt
echo ""
touch blacklist.txt

# Check if auto-ips is set in crontab
crontab -l  | grep "auto" > auto.txt
if [[ `cut -c1 auto.txt` != "#" ]];
  then echo -e  ""$B_on"IPS is set to AUTO Mode! Use "crontab -e" to reconfigure!  "$C_off""
fi;

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
   echo "8 - Find all Access Points in your Environment"
   echo ""
   echo "r - Reboot Wifi-Shepherd"
   echo "q - quit"
   echo ""
   echo -n "Input: "
   read answer
   case "$answer" in
       0) echo "";echo -n "Do you really want to reset Wifi-Shepherd? This will remove all stored mac adresses! y/n: ";
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
      8) clear;
         ./find-ap.sh
         #continue
        ;;
      q) exit
      ;;
      r) echo "";echo -n "Do you really want to reboot Wifi-Sehpherd? You will loose your ssh session! y/n: ";
          read reboot;
          clear;
          if [ "$reboot" == "y" ];
            then
              sudo reboot;
              clear;
              echo -e  ""$C_on"Wait to Reboot! ... "$C_off""
          fi
       ;;
      *) echo -e ""$C_on"Try again!"$C_off""
      ;;
   esac
done
