+++
title = "rm -rf / and some kernel panic"
author = "Victor"
date = "2010-03-26"
tags = ["wtf", "netbsd", "kernel"]
category = "blog"
+++

If you ever had in mind to `rm -rf /`: DON'T! Even for its funny aspect, it isn't worth doing such a stupid thing. Well I did it..At least not intentionally. I remember I was going to remove some ordinary directory and then I must have misspelled the last argument (directory name). Luckily I was able to notice the tragedy  and cancel the command by ^C. `F\***! What should I now?!`, was my first thought. I remembered there was a dir called backups somewhere. Indeed, there was `/var/backups` but I wasn't able to restore my data completely. And what about `/dev` ?! I knew I had to reinstall the NetBSD distribution; just to be sure everything is there. So I ran

~~~.shell
$ ./build.sh -u distribution install=/
~~~

and hoped for the best. Finally the installation was done and I did a fresh reboot. And then it happened: BOOM!

~~~.shell
...panic: init died (signal 0, exit 12)Stopped in pid 1.1 (init) at netbsd:cpu_Debugger+0x4: bx r14
~~~

(for more details read [this][1]). At that moment I knew I've screwed it up. Apparently the init process couldn't create the devices, since there was no MAKEDEV in /dev. I don't have a clue how that happened. So I booted Linux, mounted the UFS partition and looked up for the MAKEDEV file. I found it in `/mnt//usr/obj/destdir.amd64/dev`. I tried to copy it to `/mnt/dev/` but then BAM! The partition was mounted read-only. Ok, I ran

~~~.shell
$ mount -o rw /mnt
~~~

and the kernel said there was no write support for UFS. My second `F\*** YOU!` was just about to enter /dev/stdout but then I tried to stay calm and search for the solution. The solution: Recompile Linux kernel with UFS write suppport enabled. I found this [short tutorial][2] (BTW: Really great howto!) and was able to enable write support for UFS. I rebooted, mounted the NetBSD partition with write support, copied MAKEDEV into `/dev` and rebooted again. No kernel panic anymore! I was on cloud nine!

So what did I learned during this adventure?! **Think before you type!** That should apply to all of us.

 [1]: http://mail-index.netbsd.org/tech-kern/2009/03/18/msg004607.html
 [2]: http://ghantoos.org/2009/04/04/mounting-ufs-in-readwrite-under-linux/
