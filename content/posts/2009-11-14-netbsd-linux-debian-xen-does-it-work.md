+++
title = "NetBSD, Linux &#038; Xen - Does it work?"
author = "Victor"
date = "2009-11-14"
tags = ["networking", "virtualization", "linux", "netbsd", "admin", "howto", "xen"]
category = "blog"
+++

In this article I'd like to share my impressions I made with Xen during the last weeks. I met Xen a few months ago but due to general lack of interest I didn't have the chance to give it a try.Para-virtualization - why bother at all? There were actually no significant reasons why I should use virtualization. But then it started with this [thread,][1] followed by this [one][2]. The really fascinating - and tough quite useful - aspect of virtualization consists of the hardware access policy which is implemented by the virtualization host. Guests (virtualized operating systems) may access specific devices like hard disks, PCI cards etc. The host system - in our case Xen's domain-0 - can grant `guests` access to physical hardware. Xen comes up with a great feature which allows you to pass a PCI device trough to an unprivileged domain. Once you pass the PCI device (as boot parameter) to Xen's hypervisor you won't be able to use it within your domain-0 (dom0). A dummy driver stops the dom0 from accessing the device. If everything went well, you should be able to see the device on your domU (unprivileged). That's the idea so far...

I have tried many scenarios: NetBSD-CURRENT / {Xen3 ,Xen3.3}, NetBSD 5.0.1 / {Xen3, Xen3.3} and finally NetBSD 5.0_STABLE / {Xen3, Xen3.3}. The last combination worked devianatfine for me. NetBSD 5.0.1 had some problems during boot process so I decided to use a stable version which finally worked. If you tend to use Xen 3 (not Xen 3.3) be aware to use the vmlinux and NOT the compressed vmlinuz image. Otherwise you'll get something like this:

~~~.shell
$ xm create -c linux
Using config file "/usr/pkg/etc/xen/linux".
Error: (2, 'Invalid kernel', 'xc_dom_find_loader: no loader found
')
~~~

Whatever kernel you may specify be sure its an ELF binary (ELF 64-bit LSB executable, x86-64, version 1 (SYSV) in my case). You should find a `vmlinux` file in the kernel source directory (usually /usr/src). Be sure you use this file as your domU kernel and don't forget to create a ramdisk image as this is required by Xen. I won't waste my time helping you how to configure your domU and how to setup Xen + Xen tools. There are a lot of tutorials and (good) papers related to this issue. Feel free to invest some time in understanding Xen and the virtualization system. Perhaps I should mention that Xen 3.3 has a better kernel image support than Xen 3. You should be able to specify a compressed kernel image (bzImage) in your domU configuration without any problems. You should however - therefor I'd like to thank #xen on Freenode for their great support - use a kernel image >= 2.6.26 (correct me if I'm wrong ?!). Debian Lenny provides vmlinuz-2.6.30 so you should be fine with that. At the moment there is no pciback support for Xen 3.3. As told [here][3] someone with python knowledge has to port pkgsrc/sysutils/xentools3/patches/{patch-dm,patch-dn} to xentools33. Although I had some good intensions and took a look at the files that have to be modified, I quickly gave it up due to its complexity. Maybe someone else - with more spare time - could commit some changes. Xen 3.3 needs pciback and I need pciback support on NetBSD. Back to Xen 3 ... So I was able to pass some PCI device to my domU. Well not really, at least not using my own kernel. I had this configuration:

~~~.shell
kernel = "/vmlinuz-2.6.18-xen"
ramdisk = "/initrd.img-2.6.30"
memory = 156
name = "debian"
disk = [ 'phy:/dev/wd0g,xvda,w' ]
~~~

And got this:

~~~
$ dmesg | grep -e pci -e PCI
PCI: setting up Xen PCI frontend stub
PCI: System does not support PCI
PCI: System does not support PCI
pcifront pci-0: Installing PCI frontend
pcifront pci-0: Creating PCI Frontend Bus 0000:03
$ lspci
03:00.0 Network controller: Intel Corporation PRO/Wireless 4965 AG or AGN [Kedron] Network Connection (rev 61)
~~~

Since wmlinuz-2.6.18-xen doesn't have built-in driver support for my WLAN card, I had to use some different kernel (2.6.30). Then I sould theoretically be able to use my PCI device. Well things turned up to be a little be different as expected:

~~~.shell
kernel = "/vmlinux-2.6.30"
ramdisk = "/initrd.img-2.6.30"
memory = 156
name = "debian"
disk = [ 'phy:/dev/wd0g,xvda,w' ]
vif = [ 'bridge=bridge0'  ]
root = "/dev/xvda"
pci = [ '0000:03:00.0']
#extra = "xencons=tty1"
extra = "1"
~~~

`dmesg` told me:

~~~.shell
$ dmesg | grep -e "PCI" -e "pci"
[    0.000000] Allocating PCI resources starting at 10000000 (gap:9c00000:f6400000)
[    0.005111] PCI: Fatal: No config space access function found
[    0.012608] PCI: System does not support PCI
[    0.012615] PCI: System does not support PCI
[    0.051897] pci_hotplug: PCI Hot Plug PCI Core version: 0.5
[    0.052676] pciehp: PCI Express Hot Plug Controller Driver version: 0.4
[    0.052683] acpiphp: ACPI Hot Plug PCI Controller Driver version: 0.5
[    0.052696] cpcihp_zt5550: ZT5550 CompactPCI Hot Plug Driver version: 0.2
[    0.052702] cpcihp_generic: Generic port I/O CompactPCI Hot Plug Driver version: 0.1
[    0.052709] cpcihp_generic: not configured, disabling.
[    0.052761] shpchp: Standard Hot Plug PCI Controller Driver version: 0.4
[    0.164017] XENBUS: Device with no driver: device/pci/0
~~~

... and `lspci` told me nothing:

~~~
$ lspci
$
~~~

What went wrong? Did I miss something in the kernel configuration file? As you see there is a lot of work to do. I suppose there are no such problems under Linux (as dom0). Again: Correct me if I'm wrong! I really appreciate NetBSDs Xen support on this [mailing list][4] as it provides precious information you might find helpful - like I did. Nevertheless we sholuld push up the whole porting process so we can have a 100% functionable Xen integration in NetBSD. If you got some ideas that might solve my problem (in particular) don't esitate to contact me. Or even better: Write a mail to the mailing list. The whole discussion can be followed on NetBSD's mailing list [port-xen][5].

 [1]: http://mail-index.netbsd.org/tech-net/2009/07/21/msg001509.html
 [2]: http://mail-index.netbsd.org/netbsd-users/2009/10/13/msg004692.html
 [3]: http://mail-index.netbsd.org/port-xen/2009/10/26/msg005500.html
 [4]: http://www.netbsd.org/mailinglists/#port-xen
 [5]: http://mail-index.netbsd.org/port-xen/2009/10/23/msg005478.html
