+++
title = "HowTo: SSH-Tunnel over CorkScrew using Tor"
date = "2009-08-05"
tags = ["hacking", "howto", "networking", "security", "ssh", "tor", "tools"]
category = "blog"
+++

Nowadays it seems like we're loosing our privacy and are being taped by video cameras all over. The same applies to Internet surveillance: By daily traffic analysis you can find out who is talking to whom over a public network. This traffic allows others to track your click behaviour and interests. So if any mailicious guy has access to your network traffic (@work, @home &#8230;) he will try to find more information about you, like e.g. the sites you visit, the server(s) you own&#8230; The other way around: You don't want anybody else (host provider etc.) to know from which IP's you've connected to your server! Proxies are very useful and cover up your traces. This **paranoid** way of thinking might have several reasons... You just might want to keep your identity secret, right? Privacy at its best!? Well here is an approach how to do that.

## a) SSH ...

Supposing you have installed SSH, you might have a look at `~/.ssh/config`:

~~~.shell
Host *
HashKnownHosts yes
StrictHostKeyChecking no
Host [your host]
User [your user]
Port [hosts port]
...
~~~

Since the SSH client itself is not able to make connections over proxies, a 3rd party tool is required. Of course you could use the `-D` flag to create a SOCKS proxy. If so, all localhost connections using that proxy will be made first through the host you just connected by SSH. Indeed, you might use SOCKS 4/5 proxies but this is far behind the scope of this paper. I'll focus now only on HTTP/HTTPS proxies.

## b) SSH over CorkScrew ...

Corkscrew enables you to run SSH connections over HTTP/HTTPS proxies. You can find it [here][1]

~~~.shell
corkscrew 2.0 (agroman@agroman.net)
usage: corkscrew &lt; proxyhost &gt; &lt; proxyport &gt; &lt; desthost &gt; &lt; destport &gt; [authfile]
~~~

At this point you can add following line to your SSH config file:

~~~.shell
ProxyCommand [path/to/corkscrew] [proxy host] [proxy port] %h %p
~~~

The "%h" (host) and "%p" (port) options will automatically be replaced by SSH with the actual destination host and port. There is no magic behind that line. It just tells the SSH client to make the connection using an external application, in our case CorkScrew. Afterwards you should be able to connect to your host by running:

~~~.shell
$ ssh [your host]
~~~

If no error messages arise, then you successfully connected to your host using an external HTTP/HTTPS proxy!

## c) SSH over CorkScrew using Tor!

This paper wouldn't have been complete, if I didn't mention the [Tor][2] + [Privoxy][3] suite. If you need help compilling/installing them, just grab some help on Google. If you succeeded in configuring Tor and Privoxy, then you can run them on your local system. Tor should be running on port **9050**, Privoxy on **8118** (check out the configuration files). If everything went well, you should now have a web proxy running on port **8118**. You can use it within Firefox, wget, curl, links, lynx etc. Let's go back to our SSH tunnel. After making sure Tor and Privoxy are running you should add this line to your SSH config file:

~~~.shell
ProxyCommand [path/to/corkscrew] localhost 8118 %h %p
~~~

That's all! I hope you enjoyed this one. Cya next time and enjoy your privacy!

[1]: http://www.agroman.net/corkscrew/
[2]: http://www.torproject.org/
[3]: http://www.privoxy.org/
