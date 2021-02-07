+++
title = "Torrents over TOR?! Don't!"
author = "Victor"
date = "2010-05-03"
tags = ["misc", "tor", "security", "networking"]
category = "blog"
+++

>"An increasing number of people are asking us about the recent paper coming out of Inria in France around Bittorrent and privacy attacks. This post tries to explain the attacks and what they imply. There are three pieces to the attack (or three separate attacks that build on each other, if you prefer)."

*The first attack is on people who configure their Bittorrent application to proxy their tracker traffic through Tor. These people are hoping to keep their IP address secret from somebody looking over the list of peers at the tracker. The problem is that several popular Bittorrent clients (the authors call out uTorrent in particular, and I think Vuze does it too) just ignore their socks proxy setting in this case. Choosing to ignore the proxy setting is understandable, since modern tracker designs use the UDP protocol for communication, and  
socks proxies such as Tor only support the TCP protocol &#8212; so the developers of these applications had a choice between `make it work even when the user sets a proxy that can't be used` and `make it mysteriously fail and frustrate the user`. The result is that the Bittorrent applications made a different security decision than some of their users expected, and now it's biting the users.`*

[Source: http://blog.torproject.org/blog/bittorrent-over-tor-isnt-good-idea]

Read full article: [blog.torproject.org][1]

 [1]: http://blog.torproject.org/blog/bittorrent-over-tor-isnt-good-idea
