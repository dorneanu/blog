+++
title = "My own cheap NAS - the OpenWRT way"
author = "Victor"
date = "2011-03-19"
tags = ["howto", "networking", "openwrt", "linux", "iptables", "admin"]
category = "blog"
+++

Introducing my **TP-Link TL-WR1043ND**:


![TP Link](/posts/img/2011/236/tp-link-TL-WR1043ND_2.jpg)

## Summary

*   **OS**: Linux **OpenWrt** 2.6.32.25 #1 Fri Nov 19 20:27:50 PST 2010 mips GNU/Linux
*   **CPU**:  <pre class="brush:java;">system type             : Atheros AR9132 rev 2
machine                 : TP-LINK TL-WR1043ND
processor               : 0
cpu model               : MIPS 24Kc V7.4</pre>

## Filesystems

~~~.shell
root@OpenWrt:~# df -Ph
Filesystem                Size      Used Available Capacity Mounted on
/dev/root                 2.1M      2.1M         0 100% /rom
tmpfs                    14.4M    232.0K     14.2M   2% /tmp
tmpfs                   512.0K         0    512.0K   0% /dev
/dev/sda1                 1.8G     64.6M      1.8G   3% /overlay
mini_fo:/overlay          2.1M      2.1M         0 100% /
~~~

As you can see a USB-Hub is attached along with a 2GB USB-Stick. I used it to store my rootfs on external storage [1]. Additionally my 2TB external hard drived is attached to the device so I can access the data per NFS [2].

![TP Link](/posts/img/2011/236/tp-link-TL-WR1043ND_1.jpg)


## Firewall

These are my firewall [3] rules:

~~~.shell
root@OpenWrt:~# cat /etc/firewall.user 
# This file is interpreted as shell script.
# Put your custom iptables rules here, they will
# be executed with each firewall (re-)start.
IPT=iptables
NET_LAN=192.168.0.0/16

# ssh from outside
$IPT -I input -j ACCEPT -i eth0.2 -s xxx -p tcp --dport 22
$IPT -I input -j ACCEPT -i eth0.2 -s xxx -p udp --dport 22

# portmap
$IPT -I INPUT -j ACCEPT -i eth0.2 -s $NET_LAN -p tcp --dport 111
$IPT -I INPUT -j ACCEPT -i eth0.2 -s $NET_LAN -p udp --dport 111

# nfsd
$IPT -I INPUT -j ACCEPT -i eth0.1 -s $NET_LAN -p tcp --dport 32777:32780
$IPT -I INPUT -j ACCEPT -i eth0.1 -s $NET_LAN -p udp --dport 32777:32780

# minidlna
$IPT -I INPUT -j ACCEPT -i eth0.2 -s $NET_LAN -p tcp --dport 8200
$IPT -I INPUT -j ACCEPT -i eth0.2 -s $NET_LAN -p udp --dport 8200
~~~


## What about speed?

![TP Link speed](/posts/img/2011/236/tp-link_speed-test.png)

In general you won't get more than **5.60MB/s**. It depends on your drives read/write speed and the connection. In my case I was using WLAN which was slower than normal LAN connectivity.  But that's fine with me.

## Conclusion

**Awesome device with great features!** Check out [openwrt.org][4]  for more information. The devices price is about **50€** which is a fair one.

&nbsp;

## Links

[1] <http://wiki.openwrt.org/doc/howto/extroot>

[2] <http://wiki.openwrt.org/doc/howto/nfs.server>

[3] <http://wiki.openwrt.org/doc/uci/firewall?s>

 [4]: http://openwrt.org
