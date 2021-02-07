+++
title = "Gentoo, systemd, consolekit, udev and some failed system update"
author = "Victor"
date = "2013-08-10"
tags = ["misc", "wtf", "gentoo", "systemd", "linux", "update"]
category = "blog"
+++

OK, first some explanations:

*   **systemd** is a modern sysvinit & RC replacement for Linux systems. It is supported in Gentoo as an alternate init system. (Source: [http://wiki.gentoo.org/wiki/Systemd)][1]
*   **ConsoleKit** is a framework for defining and tracking users, login sessions, and seats. (Source:[ http://wiki.gentoo.org/wiki/ConsoleKit)][2]
*   **udev** is the device manager for the Linux kernel. Primarily, it manages device nodes in <tt>/dev</tt> and handles all user space actions when adding/removing devices. Also have a look at <a href="http://www.gentoo.org/proj/en/eudev" rel="nofollow">eudev</a> a gentoo fork of udev. (Source: [http://wiki.gentoo.org/wiki/Udev)][3]

  
At first look they don't seem to have sth in common. These are some other facts:

*   *systemd* and *udev* don't like each other
*   *systemd* conflicts with *consolekit*
*   *consolekit* is not longer maintained
*   *systemd* \*is\* *udev* (as systemd somehow includes udev)
*   *polkit* depends on *consolekit* and they will both pull eath other
*   *consolekit* has been replaced by logind which is being provided by *systemd*
*   ...and top of that *OpenRC* is somehow also involved in this whole thing.

As you may have noticed: THIS IS A WHOLE BUNCH OF BULLSHIT GOING ON! I just wanted to update my Gentoo system and got stucked in some stupid conflicts between the mentioned packets. It took about one day to solve it (after reading lots of forum threads of people complaining about the same thing). Check:

*   [Force Disable Consolekit][4]
*   [Want to get rid of *kits. What should I be careful about?][5]
*   [SOLVED gnome3 systemd udev and many other things][6]

Be sure you read them. They've helped me a lot to understand this whole topic. So after all this is how I was able to solve it:

*   Remove all USE flags related to consolekit: 
   
~~~.shell
# euse -D consolekit policykit upower udisks
~~~

*   Make sure you have a `clean` /etc/make.conf. Here is mine:


~~~.shell
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
CFLAGS="-O2 -pipe"
CXXFLAGS="${CFLAGS}"
# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
AUTOCLEAN="yes"
VIDEO_CARDS="intel"
USE="acpi smapi mmx sse sse2 cairo svg -kde qt4 qt3support dbus \
     declarative jpeg png vorbis ogg pulse alsa usb sdl spice gtk gtk3 \
     -gnome-shell -consolekit -policykit -upower -udisks"
MAKEOPTS="-j2"
FEATURES="-userfetch"
#CCACHE_DIR="/var/tmp/ccache"
#CCACHE_SIZE="2G"
#source /var/lib/layman/make.conf

# Set PORTDIR for backward compatibility with various tools:
#   gentoo-bashcomp - bug #478444
#   euse - bug #474574
#   euses and ufed - bug #478318
PORTDIR="/usr/portage"
~~~

*   Make sure you have selected the right profile 

~~~.shell
# eselect profile list
Available profile symlink targets:
  [1]   default/linux/amd64/13.0
  [2]   default/linux/amd64/13.0/selinux
  [3]   default/linux/amd64/13.0/desktop *
  [4]   default/linux/amd64/13.0/desktop/gnome
  [5]   default/linux/amd64/13.0/desktop/kde
  [6]   default/linux/amd64/13.0/developer
  [7]   default/linux/amd64/13.0/no-multilib
  [8]   default/linux/amd64/13.0/x32
  [9]   hardened/linux/amd64
  [10]  hardened/linux/amd64/selinux
  [11]  hardened/linux/amd64/no-multilib
  [12]  hardened/linux/amd64/no-multilib/selinux
  [13]  hardened/linux/amd64/x32
  [14]  hardened/linux/uclibc/amd64
~~~

*   Adjust profile settings
   
~~~.shell
# cd /etc/portage/profile
# cat use.force
-consolekit
# cat use.mask
consolekit
-systemd
~~~

*   Remove udev, consolekit and polkit

~~~.shell
# emerge -aC udev consolekit polkit
~~~

*   Now you should be able to install systemd

~~~.shell
# emerge -pv systemd
~~~

*   Now update your system

~~~.shell
# emerge --keep-going --jobs 4 --update --newuse --ask --deep --with-bdeps=y @world
~~~
    
Additional steps to clean up your system:

~~~.shell    
# emerge -a --depclean
# revdep-rebuild -- -q --keep-going
~~~ 

 [1]: http://wiki.gentoo.org/wiki/Systemd
 [2]: http://wiki.gentoo.org/wiki/ConsoleKit
 [3]: http://wiki.gentoo.org/wiki/Udev
 [4]: http://forums.gentoo.org/viewtopic-t-920340-start-0.html "Force Disable ConsoleKit?"
 [5]: http://forums.gentoo.org/viewtopic-t-917584.html
 [6]: http://forums.gentoo.org/viewtopic-p-7367906.html
