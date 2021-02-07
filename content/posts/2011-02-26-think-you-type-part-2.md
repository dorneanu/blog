+++
title = "Think before you type part 2"
author = "Victor"
date = "2011-02-26"
tags = ["wtf", "misc"]
category = "blog"
+++

This is the type of post where I blame myself for my stupidity (I'd call it rather carelessness)What happened? Well all I wanted to do was:

~~~.shell
$ dd if=/dev/urandom of=/dev/sda3
~~~

Beware of the "3" at the end. I don't know what really happened but at the end dd was running with:

~~~.shell
$ dd if=/dev/urandom of=/dev/sda
~~~

Damn! I was like: "F\***! All my data!" Fortunately only 4 MBs were "randomized". That means: No partition table more! &nbsp;I tried gpart & co. No success! Backup all data and start from the beginning. So what's todays lesson? There will be hopefully no more "think before you type" post!!
