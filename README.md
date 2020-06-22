# Wifi-Shepherd-IPS

![alt text](https://github.com/eaglefn/wifi-shepherd-ips/blob/master/images/wifi-shepherd-ips.png?raw=true)


## Description

The Wifi-Shepherd is a small tool based on Raspberry Pi Zero W which scans your local wifi network on a regular basis. Whenever a new device is connected to your network, Wifi-Shepherd alerts you by email. The scan result is published on its own website.  The integrated IPS (Intrusion Prevention System) is able to work in auto but also manual mode. The IPS sends deauthentication frames to the intruder.

Wifi-Shepherd-IPS uses Raspberry Pi OS (32-bit) Light and is working with an external Wifi-USB adapter. We have tested AWUS036AC from ALFA-Networks (2.4 und 5GHz) and TL-WN722N von TP-Link (2.4 Ghz).



The installation is very simple. You can create this easy solution for free in three steps:

## STEP 1:  Download the Wifi-Shepherd-IPS image 

Download the Image. You will find it under “Release”. 

Create the following files on the boot partition:

* ssh – with no content
* wpa_supplicant.conf  – with information about your wifi network

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
        ssid="your-SSID"
        scan_ssid=1
        psk="your-Password"
}
```

Check if you are able to ping your  Wifi-Shepherd and connect via ssh using the default password raspberry:

```
ssh pi@IP-Address
```

## Step 2: Configure Raspberry Pi OS 

Use the Raspberry Pi Software Configuration Tool (raspi-config) to change settings:

```
sudo raspi-config
```

1.	Change User Password 
2.	Check localization options and change time zone if necessary 
3.	See advanced option and expand filesystem to ensure that all of the SD card storage is available	



## Step 3:  Configure Wifi-Shepherd and email settings

Open wifi-shepherd.conf with your preferred editor and make your settings:

```
# Make your settings here!
Wifi_Shepherd_Hostname="raspberrypi.lan"
Wifi_Network="192.168.1.0/24"
EmailReceiver="your@email.com"
```

Get a free email account or use your own SMTP server. Change settings in the following files. This is for GMX Freemail only!

/etc/ssmtp/ssmtp.conf

```
root=email@gmx.de
mailhub=mail.gmx.net:465
AuthUser=email@gmx.de
AuthPass=Passwort
UseTLS=YES
rewriteDomain=gmx.net
hostname=gmx.net
FromLineOverride=NO
```

/etc/ssmtp/revaliases

```
root:email@gmx.de:mail.gmx.net:465
pi:email@gmx.de:mail.gmx.net:465
```

To scan your wifi network on a regular basis, create a cronjob for the pi user:

```
crontab -e
```
e.g. this will scan your network every 10 minutes:

```
# Bluetooth available after reboot 180 seconds
@reboot sudo bt-adapter --set Discoverable 1

#Wifi-Shepherd is running all 10 minutes
*/10 * * * * /home/pi/wifi-shepherd-ips/wifi-shepherd.sh

#checks channel configuration in your Wifi-Network at 8:30 am and 8:30 pm
30 8,20 * * * /home/pi/wifi-shepherd-ips/find-channels.sh

# Auto-IPS starts every hour
#0 */1 * * * /home/pi/wifi-shepherd-ips/auto-ips.sh
```

## Copyright and license
Wifi-Shepherd is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Wifi-Shepherd  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with nmaptocsv. If not, see http://www.gnu.org/licenses/.

## Credits

I'm using Thomas D. brilliant  script nmaptocsv https://github.com/maaaaz/nmaptocsv to convert nmap output to a csv file. Thanks! @maaaaz

DataTables https://www.datatables.net are used to enhance the accessibility of data in HTML tables.


## Links

You will find more information (German language only) on pentestit.de 

https://pentestit.de/wifi-shepherd-als-intrusion-protection-system-einrichten/

https://www.youtube.com/watch?v=YKMrF_nhzrE


## Releases

Download the Wifi-Shepherd image (540 MB), unzip it and copy it to your SD card. Enjoy the easy setup.
https://github.com/eaglefn/wifi-shepherd-ips/releases
