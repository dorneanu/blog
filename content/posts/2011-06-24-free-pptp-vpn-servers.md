+++
title = "Free PPTP VPN servers"
author = "Victor"
date = "2011-06-24"
tags = ["networking", "security", "vpn", "pptp"]
category = "blog"
+++

I'd recommend you all using some VPN to keep your identity safe and private. Here's some setup:

~~~.shell
$ pptpsetup --create vpnde --server pptp.freedevpn.com --username free --password --encrypt 
$ pptpsetup --create vpnca --server freecavpn.com --username free --password --encrypt 
$ pptpsetup --create vpnl --server freenlvpn.com --username free --password --encrypt 
$ pptpsetup --create vpnuk --server freeukvpn.com --username free --password --encrypt
~~~

For the passwords have a look at freenlvpn.com, freedevpn.com, freeukvpn.com, freecavpn.com. The VPN passwords changes every 12 hours, so keep in mind to change whenever the authentication failes. Therefore have a look at /etc/ppp/chap-secrets. Just edit the password there and you're ready to go. In order to activate the VPN connection you'll have to:

~~~.shell
$ pon vpn{de, uk, nl, ca}
~~~

Please choose only one them. Have a look at your syslog to check if the connection succeded. If so, then have a look at your [b]ppp device[/b] for the IP. Now you should delete your default route and add a new one. For example we have following in our log:

~~~.shell
Jun 23 23:17:32 BlackTiny pppd[16313]: local IP address 10.32.0.50 
Jun 23 23:17:32 BlackTiny pppd[16313]: remote IP address 10.32.0.1
~~~

Then you should:

~~~.shell
$ route delete default
$ route add default gw 10.32.0.1
~~~

That's it! Now test the connection using traceroute, ipchicken.com or whatever. To disable the VPN connection just fire up:

~~~.shell
$ poff vpn{de, uk, nl, ca}
~~~

and you're done. Keep in mind to **restore the old default route**.
