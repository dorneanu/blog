+++
title = "Android remote sniffing using Tcpdump, nc and Wireshark"
author = "Victor Dorneanu"
date = "2015-02-20"
tags = ["note", "network", "android", "mobile"]
category = "notes"
+++

If you want to sniff your devices traffic and visualize it on Wireshark, you'll need:

* tcpdump
* netcat
* wireshark/tshark

Make sure you have `tcpdump` installed on your machine. I *highly* recommend you installing 
the [Debian Kit](https://play.google.com/store/apps/details?id=org.dyndns.sven_ola.debian_kit&hl=en) 
which I've been using for years now. It makes things less complicated. Once you have done that, log in 
to your Android device and switch to the Debian environment:

~~~
victor@delia:/$ adb shell
# deb
root@debian:/#
~~~

Now you can start `tcpdump` and pipe its output to `netcat`:

~~~
root@debian:/# tcpdump -i wlan0 -s0 -w - | nc -l -p 11111
~~~

Afterwards you want to access port `11111` on the Android device using port forwarding:

~~~
victor@delia:/$ adb forward tcp:11111 tcp:11111
~~~

On your laptop/pentest machine you can run `tshark`:

~~~
victor@delia:/$ nc localhost 11111 | tshark -i -
~~~

Using `wireshark` that'd be:

~~~
victor@delia:/$ nc localhost 11111 | wireshark -k -S -i -
~~~

Happy hacking!

