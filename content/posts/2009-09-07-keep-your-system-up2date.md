+++
title = "Keep your system up2date!"
date = "2009-09-07"
tags = ["misc", "netbsd", "admin", "update"]
category = "blog"
+++

Due to NetBSD’s great packaging system, software gets updated very frequently. It is very important to have a clean and safe system running and no outdated packages on your system. They might be vulnerable to recently discovered bugs and affect your systems’s security and performance. After updating the package tree (see [documentation](http://www.netbsd.org/docs/pkgsrc/using.html)), I usually update my whole system by running:

~~~.shell
$ pkg_chk -su
~~~

Actually there is nothing wrong about that. Yet there is one big problem, which caused me to seek for another updating mechanism.

~~~.shell
$ pkg_chk -sun > pkg_chk.log
~~~

The log file might look like this:

~~~.shell
archivers/gtar-base - gtar-base-1.20 < gtar-base-1.22
WARNING: No archivers/lzma-utils/Makefile - package moved or obsolete?
archivers/unrar - unrar-3.8.3 < unrar-3.9.5
archivers/zip - zip-2.32 < zip-3.0nb1
archivers/zziplib - zziplib-0.10.82nb3 < zziplib-0.13.56
audio/amarok - amarok-1.4.10nb4 < amarok-1.4.10nb5
audio/cdparanoia - cdparanoia-3.0.9.8nb8 < cdparanoia-3.0.10.2nb1
audio/libcddb - libcddb-1.3.0 < libcddb-1.3.2
audio/libvorbis - libvorbis-1.2.0nb1 < libvorbis-1.2.3
audio/nas - nas-1.9.1nb1 < nas-1.9.1nb2
audio/pulseaudio - pulseaudio-0.9.14nb2 < pulseaudio-0.9.14nb4
audio/speex - speex-1.2rc1 < speex-1.2rc1nb1
audio/wavpack - wavpack-4.41.0 < wavpack-4.50.1
chat/libpurple - libpurple-2.5.7 < libpurple-2.6.1
chat/pidgin - pidgin-2.5.7 < pidgin-2.6.1
databases/sqlite - sqlite-2.8.16nb2 < sqlite-2.8.17
databases/sqlite3 - sqlite3-3.6.16 < sqlite3-3.6.17
devel/SDL - SDL-1.2.13nb4 < SDL-1.2.13nb5
devel/apr - apr-1.3.5 < apr-1.3.8
devel/apr-util - apr-util-1.3.7 < apr-util-1.3.9
devel/autoconf - autoconf-2.63 < autoconf-2.64
...

15:52 /usr/pkg/sbin/pkg_delete -K /var/db/pkg -r gtar-base-1.20
15:52 /usr/pkg/sbin/pkg_delete -K /var/db/pkg -r unrar-3.8.3
15:52 /usr/pkg/sbin/pkg_delete -K /var/db/pkg -r zip-2.32
15:52 /usr/pkg/sbin/pkg_delete -K /var/db/pkg -r zziplib-0.10.82nb3
15:52 /usr/pkg/sbin/pkg_delete -K /var/db/pkg -r amarok-1.4.10nb4
15:52 /usr/pkg/sbin/pkg_delete -K /var/db/pkg -r cdparanoia-3.0.9.8nb8
15:52 /usr/pkg/sbin/pkg_delete -K /var/db/pkg -r libcddb-1.3.0
...

[ Rechecking packages after deletions ]
~~~

o before updating any package “pkg_chk” will first delete the package AND its dependencies. This will take a lot of time when you’ll have to update big packages, e.g. Firefox. All its dependencies will be first updated and then the main package (in this case Firefox).

If you want to save time and effort, you should better use another utility called “pkg_rolling-replace”. This will rebuild or update packages using “make replace” in tsorted order. For more information click [here](http://pkgsrc.se/pkgtools/pkg_rolling-replace).

In order to update all packages on my system and ensure correct shared library dependencies, I run following commando:

~~~.shell
$ pkg_rolling-replace -rsuv
~~~
