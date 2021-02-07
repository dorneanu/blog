+++
title = "Block facebook with iptables on OpenWrt"
author = "Victor"
date = "2011-04-02"
tags = ["networking", "security", "facebook", "admin", "iptables"]
category = "notes"
+++

Say **NO** to facebook and add these lines to `/etc/firewall.user`

~~~.shell
# This file is interpreted as shell script.
# Put your custom $IPT rules here, they will
# be executed with each firewall (re-)start.
IPT=iptables
NET_LAN=192.168.0.0/16

...

# facebook
$IPT -I FORWARD -p tcp -m iprange --dst-range 66.220.144.0-66.220.159.255 --dport 443 -j DROP
$IPT -I FORWARD -p tcp -m iprange --dst-range 69.63.176.0-69.63.191.255 --dport 443 -j DROP
$IPT -I FORWARD -p tcp -m iprange --dst-range 204.15.20.0-204.15.23.255 --dport 443 -j DROP
$IPT -I FORWARD -p tcp -m iprange --dst-range 66.220.144.0-66.220.159.255 --dport 80 -j DROP
$IPT -I FORWARD -p tcp -m iprange --dst-range 69.63.176.0-69.63.191.255 --dport 80 -j DROP
$IPT -I FORWARD -p tcp -m iprange --dst-range 204.15.20.0-204.15.23.255 --dport 80 -j DROP
~~~

Run `/etc/init.d/firewall restart` and you're done!
