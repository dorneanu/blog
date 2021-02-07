+++
title = "CoWPAtty 4.2 for NetBSD"
date = "2009-07-22"
tags = ["security", "netbsd", "tools"]
category = "notes"
+++

From [http://wirelessdefence.org/Contents/coWPAttyMain.htm](http://wirelessdefence.org/Contents/coWPAttyMain.htm):

>*coWPAtty is designed to audit the pre-shared key (PSK) selection for WPA networks based on the TKIP protocol.* - Joshua Wright.

Since I had problems installing/compiling cowpatty, I had to modify the Makefile and several include-lines in some files. Currently I'm using NetBSD/Amd64. Feel free to modify the files at your needs. [][1]Download [here][2]!

Edit: As stated [here][3], there is a newer version, [4.3][4]. I edited the Makefile and created a new [tarball][5]. `make -D __NETBSD__` should do the work.

 [1]: http://dornea.nu/system/files/cowpatty-4.2-NetBSD.tar_.gz
 [2]: http://ul.to/vexnr9
 [3]: http://www.renderlab.net/projects/WPA-tables/
 [4]: http://www.willhackforsushi.com/code/cowpatty/4.3/cowpatty-4.3.tgz
 [5]: http://ul.to/2jvm0j
