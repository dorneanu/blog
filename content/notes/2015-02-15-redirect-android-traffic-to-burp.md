+++
title = "Redirect Androids traffic to Burp"
author = "Victor Dorneanu"
date = "2015-02-19"
tags = ["note", "android", "mobile", "iptables", "network"]
category = "notes"
+++

If you want to redirect you Android devices traffic to your Burp instance, you'll just have to use **DNAT**
and **MASQUERADING**. I was more detailed about this topic in [this](http://blog.dornea.nu/2014/12/02/howto-proxy-non-proxy-aware-android-applications-through-burp/)
post. And since the Internet is full of misleading information these are the steps to get it working. 
A small side remark: Most articles show you how to route the devices traffic *through* another machine (hosting the Burp instance). In that case
one could:

* force the traffic redirection using **arp spoofing**
* connect the Android device to a software (WiFi) access point forwarding everything to the hosting machine

In both cases you'll be using the `PREROUTING` chain and `DNAT` on your Burp machine in order to make sure 
that arriving packets will be forwarded/redirected to Burp's socket. In **my case** I **won't** be using `PREROUTING`
since I'll try to redirect all **locally** generated packets to another host. To be more specific: All **outbound**
traffic (`OUTPUT` chain) (destinated at a certain port) will be redirected to the Burp machine. 

{% blockdiag
	blockdiag {
	  Client [label="Android\n192.x.x.3", shape=cisco.pda]; 
	  NAT [label="NAT\n192.x.x.3", shape=cisco.router];
	  Server [label="Burp\n192.x.x.2", shape=cisco.www_server];
      Internet [shape=cloud];
	  CN [label="Packet\n\nTo: x.x.x.x:80", height=80, width=170, color="orange"];
	  NS [label="Packet\n\nFrom: 192.x.x.3\nTo: 192.x.x.2:8080", height=80, width=170, color="orange"];

	  Client -> CN -> NAT [color="orange"];
	  NAT -> NS -> Server [color="orange"];
      Server -> Internet;
	}
%}

Supposing your Android device (192.168.0.3) and the machine Burp is listening on (192.168.0.2:8080) are in the same WiFi-Network, you may have sth
like this:

{% blockdiag 
	nwdiag {
	 internet [shape = cloud];
	 internet -- router;

	 network internal {
	      address = "192.x.x.x/24";

	      router [address = "192.x.x.1", shape=cisco.router];
	      burp [address = "192.x.x.2", shape=cisco.pc];
	      android-client [address = "192.x.x.3", shape=cisco.pda];
	  }
	}
%}


Let's begin:

### Flush iptables NAT table

~~~
$ adb shell "iptables -t nat -F"
~~~


### Redirect HTTP traffic to Burp

~~~
$ adb shell "iptables -t nat -A OUTPUT -p tcp --dport 80 -j DNAT --to-destination 192.168.0.2:8080
~~~

### Redirect HTTPS traffic to Burp

~~~
$ adb shell "iptables -t nat -A OUTPUT -p tcp --dport 443 -j DNAT --to-destination 192.168.0.2:8080
~~~

### Activate Masquerading

~~~
$ adb shell "iptables -t nat -A POSTROUTING -p tcp --dport 80 -j MASQUERADE"
$ adb shell "iptables -t nat -A POSTROUTING -p tcp --dport 443 -j MASQUERADE"
~~~

That's it. You can test it by making a HTTPS connection to `paypal.com`:

~~~
$ curl -I https://www.paypal.com
curl: (60) SSL certificate problem, verify that the CA cert is OK. Details:
error:14090086:SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed
More details here: http://curl.haxx.se/docs/sslcerts.html

curl performs SSL certificate verification by default, using a "bundle"
 of Certificate Authority (CA) public keys (CA certs). If the default
 bundle file isn't adequate, you can specify an alternate file
 using the --cacert option.
If this HTTPS server uses a certificate signed by a CA represented in
 the bundle, the certificate verification probably failed due to a
 problem with the certificate (it might be expired, or the name might
 not match the domain name in the URL).
If you'd like to turn off curl's verification of the certificate, use
 the -k (or --insecure) option.
~~~

This happens because Burp is presenting the client (curl) it's own certificate. If you see that, then you're 
successfully redirecting your HTTP(s) traffic to Burp.

> This should also work for other ports/protocols.
