+++
title = "Simple MAC address generator"
author = "Victor"
date = "2009-10-14"
tags = ["networking", "tools"]
category = "notes"
+++

Any time you do some **security researches** you should better spoof/hide your identity. The best way to do that is to spoof/manipulate the MAC address of your interface. I normally do that when doing WiFi stuff: WEP cracking and such stuff. I usually assign some random MAC address to my interfaces to fully hide my identity.

A MAC address consists of six groups of hexadecimal digits. Each group is separated by hyphens or colons. Each group consists of 256 possible permutations, e.g. A1, 1F, C3 etc. Since we have 6 groups, you&#8217;ll get 256^6 = 2^48 = 281,474,976,710,656 possible MAC addresses.

I wrote a simple sh (not bash) script which generates MAC addresses using shuffle (you may want to use another randomizing command available on your system). If no arguments are given the script will print out the generated MAC. You can call the script with an additional parameter which should be an existant network interface. In that case the script (you'll need r00t rights) will assign that MAC to the interface. 

~~~.shell
#!/bin/sh
#    MACgen - simple MAC address generator
#    Copyright (C) 2009 by Victor Dorneanu
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see .
#
#    Mail: victor[__at__]dornea.nu
#    Site: http://dornea.nu
#    ----------------------
# 
#    USAGE: MACgen.sh [interface]
#           If "interface" exists, then the newly generated MAC address will
#           be assigned to the given interface. Otherwise the script will just
#           print out the MAC address.
#

# Define here randomizing shell command
SHUFFLE=`which shuffle`
SHUFFLE_OPTS='-p 1'

# List of available characters
list="0 1 2 3 4 5 6 7 8 9 A B C D E F"

# How many characters does a MAC address consist of?
mac_size=12

# Our random MAC address
generated_mac=""

generate_mac()
{
   # Some internal variable (used for the dots ":")
   c=2

   # Permutate list of available characters
   while true 
   do
      # Loop break condition
      if [ $mac_size = 0 ]; then break 
      fi

      if [ $c = 0 ]; then
         generated_mac=$generated_mac:`$SHUFFLE $SHUFFLE_OPTS $list`
         c=2
      else
         generated_mac=$generated_mac`$SHUFFLE $SHUFFLE_OPTS $list`
      fi

      mac_size=$((mac_size-1))
      c=$((c-1))
   done
}

# Check if interface argument was supplied
if [ -z $1 ]; then
   generate_mac
   echo $generated_mac

# Assign MAC to interface
else
    generate_mac
   `which ifconfig` $1 link $generated_mac active
    echo "New MAC address for $1: $generated_mac"
fi
~~~

Feel free to change the script and adapt it to your needs. Some examples:

~~~.shell
root@BlackTiny:~]$ MACgen.sh 
60:17:E8:1C:FF:7C
[root@BlackTiny:~]$ MACgen.sh
AE:7C:B6:CE:8B:7A
[root@BlackTiny:~]$ MACgen.sh
FB:D9:AB:D8:01:61
[root@BlackTiny:~]$ MACgen.sh
D8:F8:67:EF:BF:06
[root@BlackTiny:~]$ MACgen.sh ath0
New MAC address for ath0: BD:50:D4:CB:FA:F2
[root@BlackTiny:~]$ ifconfig ath0
ath0: flags=8802 mtu 1500
        ssid ""
        powersave off
        address: bd:50:d4:cb:fa:f2
        media: IEEE802.11 autoselect
        status: no network</pre>

~~~
