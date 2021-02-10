+++
title = "Thank God there is iodine! IPv4 over DNS"
author = "Victor"
date = "2011-11-09"
tags = ["hacking", "networking", "security", "dns", "icmp", "ipv4", "tools"]
category = "blog"
+++

I always knew DNS/ICMP traffic is mostly allowed and un-monitored. It was about time to setup some DNS server on my vServer which would allow me to break free! Thanks God there is [iodine][1] which allows you to route IP traffic over DNS.

I was recently at some cafe and thought it would be a great ideea to test my configuration. I've setup the iodine server a few weeks before.This is what I did:

~~~.shell
# iodine -fP (insert password here) *.*136.116 *.mooo.com
Opened dns0
Opened UDP socket
Sending DNS queries for tunnel.syngres.mooo.com to *.*.136.116
Autodetecting DNS query type (use -T to override).
Using DNS type NULL queries
Version ok, both using protocol v 0x00000502. You are user #0
Setting IP of dns0 to 10.0.0.2
Setting MTU of dns0 to 1130
Server tunnel IP is 10.0.0.1
Testing raw UDP data to the server (skip with -r)
Server is at 178.77.98.100, trying raw login: ....failed
Using EDNS0 extension
Switching upstream to codec Base128
Server switched upstream to codec Base128
No alternative downstream codec available, using default (Raw)
Switching to lazy mode for low-latency
Server switched to lazy mode
Autoprobing max downstream fragment size... (skip with -m fragsize)
768 ok.. ...1152 not ok.. 960 ok.. ...1056 not ok.. 1008 ok.. 1032 ok.. 1044 ok.. will use 1044-2=1042
Setting downstream fragment size to max 1042...
Connection setup complete, transmitting data.
~~~

Then setup the SSH connection:

~~~.shell
# ssh -CD 9999 user@10.0.0.1 -p 1337
~~~

This will create a **local socket** which can be used for further connections.

## Traffic redirection

I use **proxychains** (but there is also socat, socksify, tsocks etc.) for traffic redirection. Simply add 127.0.0.1:9999 to your /etc/proxychains.conf and you'll have your desired traffic control.

## Screenshots

![](/posts/img/2011/261/iodine1.png)

![](/posts/img/2011/261/iodine2.png)

![](/posts/img/2011/261/iodine3.png)

[1]: http://code.kryo.se/iodine/
