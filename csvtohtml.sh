#!/bin/bash
[[ $# -ne 1 ]] && echo Usage: $0 [CSV_FN] && exit -1

CSV_FN=$1

#ip=`cat  ip.txt |  sed 's/ //'`
LastScan=`date +%Y-%m-%d" "%H:%M`
echo "$LastScan" > LastScan.txt
echo "<body>"

echo "<table align=\"center\" style=\"width:98%\">"
echo "<tr> <td><p align=\"left\"><font family=\"Verdana,Arial,Helvetica\" color=\"#0000FF\" size=\"+1\">"

echo "Last Scan: $LastScan" 
echo "</font></p> </td>"
#echo '<td><a class="button" href="../cgi-bin/ips.sh">Intrusion Protection</a> </td>'
#echo "<td>  <a href=\"http://"$ip"/cgi-bin/ips.sh\"><img src=\"images/link_button.png\"/></a> </td>"


echo "<td><img src=\"..\images\wifi_shepherd.gif\" alt=\"Wifi Shepherd\" width=\"225\" height=\"108\" align=\"right\"></td></tr></table>"

echo "<table id=\"shepherd\" class=\"table table-striped table-bordered\" style=\"width:98%\" align=\"center\">"
echo "<thead>"
head -n 1 $CSV_FN | \
    sed -e 's/^/<tr><th>/' -e 's/;/<\/th><th>/g' -e 's/$/<\/th><\/tr>/'
echo "</thead>"
echo "<tbody>"
tail -n +2 $CSV_FN | \
    sed -e 's/^/<tr><td>/' -e 's/;/<\/td><td>/g' -e 's/$/<\/td><\/tr>/'
echo "</tbody>"
echo "</table>"
echo "</body>"

