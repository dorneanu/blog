+++
title = "HowTo: Create new Debian domU using Xen on *BSD"
author = "Victor"
date = "2010-03-22"
tags = ["howto", "networking", "virtualization", "xen", "netbsd", "admin", "linux"]
category = "blog"
+++

In this tutorial you'll get detailed information how to setup a fully functionable Debian Lenny system using virtualization software [Xen][1]. This entry was written due to high frustration caused by unreliable/outdated articles on the Internet and uncompleted tutorials. This here should be an attempt to describe the installation process completely and provide additional information which might help you solve common problems. The domU system we'd like to setup (in our case Debian) provides a neat [netboot][2] installer which supports Xen. I don't know - I don't really have the time to look it up - if any other Linux distributions have such installer (nor if they support Xen at all) , so this howto might also apply - or not - to any other distribution. The same applies to the dom0 system: On your system shown shell commands might differ (different syntax)  as well as described methods (e.g. mount pseudo devices etc.). I used NetBSD 5.0_STABLE (amd64) on my system, so there should be no major differences to other BSD systems. If you use Linux as your host system, then you should seek forward since this paper is aimed to focus on *BSD papers. There are enough (good) tutorials out there you can rely on.

## Prerequisites

At this point you should have a running Xen instance and have booted your dom0 (NetBSD with kernel XEN3_DOM0). You should have sth like this:

~~~.shell
$ uname -a
NetBSD BlackTiny 5.0_STABLE NetBSD 5.0_STABLE (XEN3_DOM0)
~~~

Some technical details:

*   System: *Lenovo Thinkpad x61 / NetBSD 5.0_STABLE (amd64)*
*   pkgsrc branch: *2009Q4*
*   Xen kernel: *xenkernel33-3.3.2*
*   Xen tools: *xentools33-3.3.2nb1*
*   Xen dom0 kernel: *NetBSD 5.0_STABLE*

## Step 1: Network configuration

Now you'll have to create a network bridge:

~~~.shell
$ ifconfig bridge0 create
$ ifconfig bridge0
bridge0: flags=0 mtu 1500
~~~

Make sure you use an Intenet connection based on Ethernet (IEEE 802.3) since the Debian installer provides no WiFi modules (?). There have been several problems when using WiFi due to some data encapsulation issues. So be sure you have an active Internet connection based on Ethernet. Now you should add your Ethernet interface (wm0 on my system) to the network bridge we've created:

~~~.shell
$ brconfig -a
bridge0: flags=0
        Configuration:
                priority 32768 hellotime 2 fwddelay 15 maxage 20
                ipfilter disabled flags 0x0
        Interfaces:
        Address cache (max cache: 100, timeout: 1200):

$ brconfig bridge0 add wm0 stp wm0 up
$ brconfig bridge0
bridge0: flags=41 UP,RUNNING
        Configuration:
                priority 32768 hellotime 2 fwddelay 15 maxage 20
                ipfilter disabled flags 0x0
        Interfaces:
                wm0 flags=7 LEARNING,DISCOVER,STP
                        port 1 priority 128 path cost 55 listening
        Address cache (max cache: 100, timeout: 1200):
~~~

This whole configuration stuff will be gone after reboot in case you don't save it to some file. If you want your system to automaticallly create the bridge, then you'll have to create `/etc/ifconfig.bridge0` and add these lines to it:

~~~.shell
create!brconfig $int add [your LAN interface]up
~~~

Be sure to replace `[your LAN interface]` with the interface identifier on your system (in my case it would be wm0).

## Create disk container

After setting up the network stuff, you should now create a container (about 2GB) where Debian will be later on installed.

~~~.shell
$ dd if=/dev/zero of=Debian-Lenny.img bs=1m count=2048
~~~

## Step 3: Get Debian kernel and ramdisk file

In order to have a fully functionable Debian installation **DON'T** use [these][3] files. You'll run into several problems which will keep you busy searching the Internet for the solutions. Instead you should use the i386-current Xen netboot installer from this[ link][4]. You should at least download:

* the kernel file ([vmlinuz][5])
* the ramdisk file ([initrd.gz][6])

to your local directory.

## Step 4: Xen domU configuration

Now let us configure then Xen domU at least with these options (see xm-debian.cfg):

~~~.shell
# Initial memory allocation (in megabytes) for the new domain.
memory = 128

# A name for your domain. All domains must have different names.
name = "debianinstall"

# Define network interfaces
vif = ['bridge=bridge0']
...
~~~

## Step 5: Start Xen services

First be sure you have following entries in your `/etc/rc.conf`:

~~~.shell
xend=YES
xendomains=YES
xenbackendd=YES
~~~

Additionally you can add:

~~~.shell
xendomains="domain.foo domain.bar"
~~~

where `domain.foo` and `domain.bar` are your Xen configs for these domains,  
i.e $LOCALBASE/etc/xen/domain.foo.In my case $LOCALBASE is defined as /usr/pkg.This will bring Xen to automatically start your DomUs. (thanks Marcin M. Jessa for this hint)

Then you should be able to start Xen services:

~~~.shell
$ /usr/pkg/share/examples/rc.d/xend start
$ /usr/pkg/share/examples/rc.d/xenbackendd start
$ /usr/pkg/share/examples/rc.d/xendomains start
~~~

## Step 6: Install Debian

Now you should be able to start the Debian installation process.

~~~.shell
$ ls -l
-rw-r--r--  1 root  wheel  13796958 Mar  3 18:13 initrd.gz
-rw-r--r--  1 root  wheel   1548496 Mar  3 18:13 vmlinuz
-rw-r--r--  1 root  wheel      7733 Mar 21 18:46 xm-debian.cfg

$ $ sha1 vmlinuz 
SHA1 (vmlinuz) = becfb0b127c083b1444f896011564b1822423152
$ sha1 initrd.gz 
SHA1 (initrd.gz) = 11bc2711f08ed8a0863169c506ab88d69cf9f3cf
~~~

You should now launch your Xen domU:

~~~.shell
$ xm create xm-debian.cfg install=true install-kernel=./vmlinuz install-ramdisk=./initrd.gz
~~~

Since we use no framebuffer you should now switch to your console (by pressing CTRL+ALT + Fx, where X = 1 .. 8), login as root, cd to the previously listed directory and type:

~~~.shell
$ xm console debianinstall
~~~

You should now have an attached console to Debian's installer.

![debian installer](/posts/img/2010/147/11ae9eb.jpg)

The Debian installer should also configure network automatically by DHCP.

![DHCP](/posts/img/2010/147/2rdyl2g.jpg)

If this fails, then you should go back to the main installer menu and **Execute a shell**. Afterwards run `dhclient eth0` as shown below:

![DHCP](/posts/img/2010/147/5oz5zn.jpg)


![Configure network manually](/posts/img/2010/147/2d9r3it.jpg)

Then proceed with the installation process...

![Successful network setup](/posts/img/2010/147/29mklm1.jpg)

Attention: When configuring the virtual disk, have in mind that you should format your disk as ext2 and **not as ext3**. Ext3 is currently not supported by NetBSD. When you have reached the partitioning step, select the partition marked as ext3, press enter and change afterwards the file system type to ext2. Then you should select `Done setting up the partition` and press enter.

![Ext3fs](/posts/img/2010/147/m79cgk.jpg)

You should now go through the installation process without experiencing any troubles. At the end of the installation you won't have to install grub nor any boot loader, so simply ignore the error messages and select `Continue`. Even if you should go back to the main installation menu, select `Continue without any boot loader` and everything will be alright.

## Step 7: Start your fresh new Debian system

First you'll have to extract `vmlinuz` and `initrd.gz` from your local disk container. NetBSD provides vnconfig(8) to configure pseudo disk devices.

~~~.shell
$ vnconfig vnd0 Debian-Lenny.img
$ disklabel /dev/vnd0
# /dev/vnd0d:
type: vnd
disk: vnd
label: fictitious
flags:
bytes/sector: 512
sectors/track: 32
tracks/cylinder: 64
sectors/cylinder: 2048
cylinders: 1024
total sectors: 2097152
rpm: 3600
interleave: 1
trackskew: 0
cylinderskew: 0
headswitch: 0 # microseconds
track-to-track seek: 0 # microseconds
drivedata: 0

9 partitions:
# size offset fstype [fsize bsize cpg/sgs]
d: 2097152 0 unused 0 0 # (Cyl. 0 - 1023)
e: 1863477 63 Linux Ext2 0 0 # (Cyl. 0*- 909*)
i: 224847 1863603 swap # (Cyl. 909*- 1019*)
disklabel: boot block size 0
disklabel: super block size 0
~~~

As expected we have a swap partition and a ext2 (!!!) file system. We'll try now to mount it in order to extract the previously mentioned files:

~~~.shell
$ mount -t ext2fs /dev/vnd0e /mnt
$ file /mnt/vmlinuz /mnt/vmlinuz: symbolic link to `boot/vmlinuz-2.6.26-2-686-bigmem'
$ file /mnt/initrd.img /mnt/initrd.img: symbolic link to `boot/initrd.img-2.6.26-2-686-bigmem'
~~~

Now all you'll have to do is to copy these files to your local partition and use them in your domU configuration. On my laptop I've created /home/xen:

~~~.shell
$ ls -lR total 16
drwxr-xr-x 2 root wheel 512 Mar 22 17:04 conf
drwxr-xr-x 2 root wheel 512 Mar 6 22:07 container
drwxr-xr-x 2 root wheel 512 Mar 6 22:08 kernel
drwxr-xr-x 2 root wheel 512 Mar 6 22:06 ramdisk

./conf:
total 32
-rw-r--r-- 1 root wheel 2676 Mar 6 22:08 Debian-Lenny.conf

./container:
total 4195360
-rw-r--r-- 1 root users 2147483648 Mar 6 21:38 Debian-Lenny.img

./kernel:
total 3072
-rw-r--r-- 1 root wheel 1548304 Mar 5 18:03 Debian-Lenny-vmlinuz-2.6.26-2-686-bigmem

./ramdisk:
total 12192
-rw-r--r-- 1 root wheel 6214259 Mar 5 18:03 Debian-Lenny-initrd.img-2.6.26-2-686-bigmem
~~~

Debian-Lenny.conf in *conf *contains:

~~~.shell
# Kernel image file. This kernel will be loaded in the new domain.
kernel = "/home/xen/kernel/Debian-Lenny-vmlinuz-2.6.26-2-686-bigmem"
ramdisk = "/home/xen/ramdisk/Debian-Lenny-initrd.img-2.6.26-2-686-bigmem"

# Memory allocation (in megabytes) for the new domain.
memory = 156

# A handy name for your new domain. This will appear in 'xm list',
# and you can use this as parameters for xm in place of the domain
# number. All domains must have different names.

name = "Debian-Lenny"
vif = [ 'mac=00:16:3e:2e:32:5f, bridge=bridge0' ]

disk = [ 'file:/home/xen/container/Debian-Lenny.img,xvda,w']

# Set root device.
root = "/dev/xvda"
~~~

Now for the final step, launch your Debian domU using:

~~~.shell
$ cd conf
$ pwd/home/xen/conf
$ xen create -c Debian-Lenny.conf
~~~

Thats it! I hope you enjoyed this HowTo and if you have any questions/unsolved issues, just drop me a mail and I'll try to help.

 [1]: http://xen.org/
 [2]: http://en.wikipedia.org/wiki/NetBoot
 [3]: http://people.debian.org/%7Ejoeyh/d-i/images/daily/
 [4]: ftp://ftp.debian.org/debian/dists/lenny/main/installer-i386/current/images/netboot/xen/
 [5]: ftp://ftp.debian.org/debian/dists/lenny/main/installer-i386/current/images/netboot/xen/vmlinuz
 [6]: ftp://ftp.debian.org/debian/dists/lenny/main/installer-i386/current/images/netboot/xen/initrd.gz
