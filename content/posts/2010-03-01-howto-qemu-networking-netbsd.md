+++
title = "HowTo: Qemu networking on NetBSD"
author = "Victor"
date = "2010-03-01"
tags = ["networking", "virtualization", "qemu", "netbsd", "admin", "howto"]
category = "blog"
+++

In this tutorial I'd like to give you some useful examples how to configure network when using Qemu as virtualization machine. The videos in this HowTo were taken on a NetBSD-5_STABLE/amd64 machine using  Qemu 0.11.1. **Attention: **On my system I've used a patched version of Qemu as reported [here][1]. However you can use the `fd=` option to specify an open socket to be used. Example:

~~~.shell
$ qemu -cdrom [iso file] -net nic -net tap,fd=3 3<>/dev/tap0
~~~

Using this example `tap0&#8243; should be created before the qemu command. The shown examples might work on other platforms too. Be sure to have TUN/TAP device support built-in and the Qemu suite installed. Check out **References** for further information.

## Usermode network stack

Probably the simplest method of connecting your host and the guest system. In this mode Qemu will create a :

*   virtual network (10.0.2.0)
*   fiirewall which doesn't allow any external connections
*   DHCP-Server (10.0.2.2)
*   gateway (10.0.2.2)

The DHCP-Server will automatically assign 10.0.2.15 to your interface when a DHCP-request was sent. When the host system is connected to the Internet, the guest will be automatically be able to access the Internet too. No additional steps are required.

1. [ host system ] Launch Qemu process:

~~~.shell
$ qemu -net nic -net user -cdrom [iso file]
~~~

2. [ guest system] Get an IP address:

~~~.shell
$ dhclient [interface]
~~~

3. [ guest system] Check settings and Internet connectivity:

~~~.shell
$ ifconfig [interface]
$ ftp [ftp site]
~~~

On my system the firewall was blocking any ICMP packets so ping might not work. But don't get disoriented (like I did). Try to ssh or ftp any known host to check the connection.

## Connecting VLANs

This is a quite simple step. You'll have to set up a Qemu process listening for incoming connection(s) on  a certain socket. The second Qemu process will connect to the listening socket. Whenever a frame/packet appears on the VLAN of the first Qemu process, it will be forwarded to the second one and <span style="font-style: italic;">vice versa</span>.

Here's our configuration:

*   Guest **A**: listen for connections on `localhost:8010`
*   Guest **B**: connect to Guest **A** through `localhost:8010`

Host **A** will listen for incomming connections on port 8010 and host **B** will be configured to connect to host **A**.

### Create host A

~~~.shell
$ qemu  -net nic,macaddr=52:54:00:12:34:57 -net socket,listen=:8010  
      -cdrom [iso file]
~~~

### Create host B

~~~.shell
$ qemu  -net nic,vlan=2,macaddr=52:54:00:12:34:56 
      -net socket,vlan=2,connect=127.0.0.1:8010 
      -cdrom [iso file]
~~~

### Configure host A

~~~.shell
$ ifconfig [interface] 10.0.2.100 netmask 255.255.255.0 up
~~~

### Configure host B

~~~.shell
$ ifconfig [interface] 10.0.2.101 netmask 255.255.255.0 up
~~~

Using this configuration you should be able to access host **B** from host **A** and vice versa.

## Connecting VLANs to TAP device (1 host)

There is another option to create VLANs: Using a virtual Ethernet device (tap device). Any frames transmitted through this device will also appear on the VLAN of your guest OS. Of course any frames sent to guest's VLAN will be also received by the TAP device.

Using the kernel TAP/TUN device driver applications are allowed to interact with a network device using a simple file descriptor. Any data sent over the file descriptor will be received on both sides. That means that applications running on the guest system(s) will be able to access and connect to applications running on the host system. If port forwarding is allowed, guest applications can also access the Internet.

First we create a TAP device:

~~~.shell
$ ifconfig tap0 create
$ ifconfig tap0
tap0: flags=8802  mtu 1500
        address: f2:0b:a4:86:42:08
        media: Ethernet autoselect
$ ifconfig tap0 10.0.2.100 netmask 255.255.255.0 up
~~~

### Launch Qemu process:

~~~.shell
$ qemu -net nic,vlan=0 -net tap,vlan=0,ifname=tap0 -cdrom  [iso file]
~~~

### Configure virtual host:

~~~.shell
$ ifconfig [interface] 10.0.2.101 netmask 255.255.255.0 up
~~~

You should now be able to access your Qemu host from your guest host (ping 10.0.2.101). 10.0.100 (guest system) should be also accessible from your Qemu process.

## Connecting VLANs to TAP devices (2 hosts)

In this example we'll have 2 guests (= 2 TAP devices). Each guest is connected to the host system by a TAP device. In order to allow inter-connectivity the gust system should have a bridge between both TAP devices. The bridge will act as a central network node between the guest and both virtual hosts. For Internet access IP forwarding should be enabled (disabled by default). First we'll have to create the TAP devices:

~~~.shell
$ ifconfig tap0 create
$ ifconfig tap1 create
$ ifconfig tap0
tap0: flags=8802 mtu 1500
        address: f2:0b:a4:86:42:08
        media: Ethernet autoselect
$ ifconfig tap1
tap1: flags=8802 mtu 1500
        address: f2:0b:a4:86:61:01
        media: Ethernet autoselect
~~~

### Launch guest A

~~~.shell
$ qemu  -net nic,macaddr=52:54:00:12:34:56 -net tap,ifname=tap0 -cdrom [iso file]
~~~

### Launch guest B

~~~.shell
 $ qemu  -net nic,macaddr=52:54:00:12:34:57 -net tap,ifname=tap1 -cdrom [iso file]
~~~

### Setup TAP devices networking settings:

~~~.shell
$ ifconfig tap0 10.0.2.100 netmask 255.255.255.0 up
$ ifconfig tap1 10.0.3.100 netmask 255.255.255.0 up
~~~

### Create bridge interface:

~~~.shell
$ ifconfig bridge0 create
$ brconfig bridge0 add tap0 add tap1 up
~~~

### Setup network settings for guest A

~~~.shell
$ ifconfig [interface] 10.0.2.101 netmask 255.255.0.0 up
~~~

### Setup network settings for guest B

~~~.shell
$ ifconfig [interface] 10.0.3.101 netmask 255.255.0.0 up
~~~

Now try following:

1.  From your host system: ping 10.0.2.101; ping 10.0.3.101
2.  From guest A: ping 10.0.2.100; ping 10.0.3.101; ping 10.0.3.100
3.  From guest B: ping 10.0.3.101; ping 10.0.2.101; ping 10.0.2.100

For Internet access the guest system should be connected to the Internet and allow IP forwarding:

~~~.shell
$ sysctl -w net.inet.ip.forwarding=1
~~~

In all cases you should be able to ping/access any system no matter what system you operate on. 

## References

a) <http://wiki.qemu.org/Main_Page>

b)[ http://qemu-buch.de/de/index.php/QEMU-KVM-Buch/\_Netzwerkoptionen/\_Virtuelle\_Netzwerke\_konfigurieren][2]

c) [http://compsoc.dur.ac.uk/~djw/qemu.html][3]

d) [http://people.gnome.org/~markmc/qemu-networking.html][4]

 [1]: http://mail-index.netbsd.org/pkgsrc-bugs/2009/12/18/msg035190.html
 [2]: http://qemu-buch.de/de/index.php/QEMU-KVM-Buch/_Netzwerkoptionen/_Virtuelle_Netzwerke_konfigurieren
 [3]: http://compsoc.dur.ac.uk/%7Edjw/qemu.html
 [4]: http://people.gnome.org/%7Emarkmc/qemu-networking.html
