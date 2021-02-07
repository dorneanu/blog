+++
title = "HowTo: Secure your server using icmpKNOCK"
author = "Victor"
date = "2010-10-03"
tags = ["howto", "networking", "security", "icmp", "admin", "icmpknock"]
category = "blog"
+++

This time I'd like to give you a short usage description of [icmpKNOCK][1] that was recently released. The main reason I wrote it was lack of security measurements on my boxes. I didn't want any sophisticated IDS tools nor complicated monitoring services. I wanted to implement something which will run on (almost) any platform without any external toolsb. Since the ping utility is available on most modern systems using ICMP packets to communicate with the server was the most reasonable approach. There are plenty of other **port knocking** tools but these are mostly binaries. These have to be first compiled on the running system which is bad. So the second thought was to use a programming language powerful enough to fulfill my needs and be portable. It had to be Python. 


## Getting started

First you'll have to get the latest version of icmpKNOCK. Please check the SVN download [link][2] for the newest packages. Then make sure to upload the package to your server and copy it to a secret place where nobody - besides you - has read permissions on the actions file. Why is that important? Because the actions file contains your `secret` hex sequences used to trigger certain actions. So you don't want anybody to know these ones. In that case potential attackers might manipulate the behaviour of your system without noticing it.

~~~.shell
~/icmpknock/v0.2.r9# ls -l
total 32
-rw-r--r-- 1 root root   35 Sep  9 13:45 AUTHORS
-rw-r--r-- 1 root root  340 Sep  9 14:19 CHANGELOG
-rw-r--r-- 1 root root 1074 Sep 13 13:54 README
drwxr-xr-x 2 root root 4096 Sep 30 16:33 conf
-rwxr-xr-x 1 root root 4575 Sep  9 13:45 icmpKNOCK.py
drwxr-xr-x 2 root root 4096 Sep 30 16:11 modules
drwxr-xr-x 2 root root 4096 Sep 30 16:11 scripts
~~~

## Generate hex sequences

Now you'll have to generate your keys. You could use MD4, MD5, SHA-1 etc hashes. This is what I did:

~~~.shell
$ for i in `seq 1 10`; 
do pwgen 20 1 | md5; 
done        
bf6e1e0c0ce8fedb43146e50d1b281f9                                                
d3ed14fb017c3b0afb8b2329fb010756
2ab616e0b85ff5e80a8bd274745d530f
c2a565c9132b4931f1c5cd20c1498604
57abd2bb3cc26413050b90cd7509c677
26ef6c1dede976ba48c1c4adbdf4ceae
cfdff084e3442c5b8613ac75aa5147ad
d047732f4c0b083f8f322437f0071bb9
56bb53f69f701975db0977f316cd6402
b124d903a6c510fbba2b1ccb23a11f2d
~~~

That should do the work. Now you'll have to edit your actions file (conf/actions.conf) and copy these values to it. Please have a look at the descriptive text inside the file for further information.

## Define actions

This is the most interesting part. In this HowTo I'll give you an example how to block/open SSH port 22 using icmpKNOCK. Therefor I'll be using iptables which should be available within every Linux distribution. So let's start...

For this tutorial the SSH port should be always closed. Let's define the action describing that:

~~~.shell
[stop_ssh]
keys = <your secret keys here>
payload = iptables -A INPUT -p tcp --dport 22 -j REJECT --reject-with tcp-reset
~~~

Everytime the server receives the secret hex sequences it will close port 22 to block any external connections. What about opening it?

~~~.shell
[start_ssh]
keys = <your secret keys here>
payload = iptables -D INPUT -p tcp --dport 22 -j REJECT --reject-with tcp-reset
~~~

In that case you simply delete the previously created rule. Afterwards port 22 should be open again.

Of course: There are lot of other possible configurations. Perhaps it is a better idea to define only 1 action which allows you to connect to port 22 within 20 seconds, close the port again after 20 seconds and keep the established connections. Feel free to use your brain.

## Prepare your scripts

Your server - along with the Python application - will listen for incoming ICMP packets. Your client will be the ping utility as described above. In order to send your sequences to the server you'll need a small bash script which will do the rest for you:

~~~.shell
#!/bin/sh

HOST=<your host here>
keys=<your keys here>'

for k in $keys
do
   ping -c 1 -p $k $HOST
done
~~~

That's all. Just name your script something like `start_ssh.sh` and run it every time you you'll connect to the server. The same applies to `cllosing the port`.

For any comments, new features or simply feedback, please use the comment functionality or drop me a mail.

 [1]: http://github.com/dorneanu/icmpKNOCK
 [2]: http://github.com/dorneanu/icmpKNOCK
