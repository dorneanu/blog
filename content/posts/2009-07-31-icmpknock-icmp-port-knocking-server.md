+++
title = "icmpKNOCK - ICMP port knocking server"
author = "Victor"
date = "2009-07-31"
tags = ["networking", "icmp", "tools", "icmpknock"]
category = "blog"
+++

## Whats this about? 

If you're familiar with port knocking, you should know the basics and how this technique basically works. If don't have a clue what I'm talking about, feel free to have a look at the *Links* section. Most port knocking tools are listening for TCP or UDP packets to arrive on specific ports in a specific order. icmpKNOCK is waiting for ICMP echo requests and checks their payloads. Packets that match given criteria trigger some action, e.g. open/close port(s) etc. The main advantage of this tool is the fact that this approach works with all standard ping tools, regardless of your operating system.

## How to use it

a) Define some unique keys (MD5, SHA1 etc.):
b) Define actions (check out icmpKNOCK_actions.py) 
c) run icmpKNOCK.py as root!!! otherwise you won't be able to listen for incoming ICMP requests 
d) Using your `ping` utility you can pass hex patterns to the requests: 

~~~.shell
$ ping -p [hex pattern] [host]
~~~

Be aware of the order in which you send the packets. Example: 

~~~.shell
@set_action(hex1, hex2, hex3, ...)
~~~ 

When you run ping keep in mind to first send key1, then key2, then... You got it, right? Example: 

~~~.shell
$ ping -p hex1 [host] 
$ ping -p hex2 [host] 
... 
~~~

## Links 

* http://www.portknocking.org/ 
* http://www.faqs.org/rfcs/rfc791.html * http://www.faqs.org/rfcs/rfc792.html 

**Download [here!][1]**

![icmpknock](/posts/img/2010/200/icmpknock1.png)

![icmpknock actions](/posts/img/2010/200/icmpknock2.png)

[1]: https://github.com/dorneanu/icmpKNOCK
