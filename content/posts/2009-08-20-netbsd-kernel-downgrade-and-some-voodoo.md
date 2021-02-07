+++
title = "NetBSD, kernel downgrade and some voodoo!"
date = "2009-08-20"
tags = ["misc", "netbsd", "update"]
category = "blog"
+++

I don't know if you still remember my ACPI suspend/resume problems a few months ago. I once suspended my Linux system to RAM and forgotten to make a proper shutdown. After a while the battery discharged and my laptop was out of power. After some reboots (there were about 15 tries) I finally managed it to boot my system again. Some BIOS error occured every time. That error still keeps my busy. I couldn't find out the cause for the strange BIOS error. The fact of matter is that my laptop behaved strange for about 3-4 months: I couldn't shutdown properly (I always had to force shutdown by pressing the power-off button) and the suspend functionality didn't work well.

Then came the voodoo effect! One night (about 3 weeks ago) I was about to shutdown my system (meanwhile NetBSD 5.0) and surprisingly IT DID SHUTDOWN! No power-off button! Just a smooth shutdown as expected!  

What the hell happened? It came so suddenly... However I was very pleased about that. But wait.. The story still goes on! Today I did some kernel downgrade from NetBSD-current to NetBSD 5.0.1  and enabled the APM (ACPI Power Managment) support for my kernel. I build the new userland, rebooted the system and I was looking for the `apm`command in /usr/sbin... Not found! I quickly joined the #netbsd channel on Freenode and asked for some help.

~~~.shell
sysctl -w macdeep.sleep_state=3
~~~

That was the command I was looking for! When ACPI is enabled on your system you can easily suspend/resume your system using the `sysctl` utility. Thanks #netbsd and NetBSD for such a great OS!
