+++
title = "VNC: Connect to current desktop session using x11vnc and ssh"
author = "Victor"
date = "2011-04-04"
tags = ["howto", "networking", "ssh", "x11", "vnc"]
category = "notes"
+++

**x11vnc** allows you to connect to real X displays without creating any new X session (fluxbox, twm, gnome etc.). It allows you to control the mouse, keyboard and X events remotely. I usually use it when friends of mine need help and I want to see what exactly they're doing.

Make sure any **ssh server **is running on *remote-host*and you have a vnc client installed on your *localhost*. Also make sure *remote-host* has x11vnc otherwise this won't make sense at all.Then run:

~~~.shell
[remote-host] > x11vnc -display :0
[localhost] > ssh -t -L 5900:localhost:5900 [remote-user]@[remote-host]
~~~

Now the whole connection is encrypted via ssh. Now open new terminal and run:

~~~.shell
[localhost] > vncviewer localhost:5900
~~~

That's all!
