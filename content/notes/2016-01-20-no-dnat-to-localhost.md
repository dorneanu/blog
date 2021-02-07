+++
title = "No DNAT to localhost"
author = "Victor Dorneanu"
date = "2016-01-20"
tags = ["note", "iptables", "linux", "networking"]
+++

Doing a simple **port forwarding** is actually a simple task:


~~~.bash
$ iptables -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080
~~~

This would redirect all traffic from `80` to `8080`. But if you have some **firewall** activated, you'll have to **allow** both ports:

~~~.bash
$ iptables -A INPUT -p tcp --dport 80 -j ALLOW
$ iptables -A INPUT -p tcp --dport 8080 -j ALLOW
~~~

Otherwise the port forwarding won't work. But this is not the use case you want to achieve. In most cases you want to **redirect** 
traffic from one port (let's say `80`) from an external interface to another IP address (let's say `10.0.0.1:8080`). Using **DNAT** this 
actually pretty easy to implement:

~~~.bash
$ iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:8080
~~~

For a full example have a look at [this stackoverflow](http://stackoverflow.com/questions/14212807/iptables-forward-request-on-different-interfaces-and-port?answertab=votes#tab-top).
However in my case I wanted to do DNAT to the **loopback** interface which didn't work ([this answer](http://lists.netfilter.org/pipermail/netfilter/2004-August/055074.html) confirms this). Using **REDIRECT** is also a pretty bad idea since I had to allow access to both ports (which is kind of stupid). 

So... How to solve the problem? Using [inetd](https://en.wikipedia.org/wiki/Inetdhttps://en.wikipedia.org/wiki/Inetd). I've installed [rinetd](http://www.boutell.com/rinetd/) and configured the port forwarding:

~~~.bash
$ apt-get install rinetd
$ cat /etc/rinetd.conf
[...]
# bindadress    bindport  connectaddress  connectport
<external ip>   80          127.0.0.1       8080
[...]
$ service rinetd restart
~~~

I hope this would prevent others from spending their whole day on doing DNAT to localhost. 

