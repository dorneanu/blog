+++
title = "Find out your geolocation via MAC address"
date = "2010-10-07"
tags = ["networking", "security", "android", "mac"]
category = "blog"
+++

Today I found a very interesting article about geoposition localisation based on MAC addresses. MAC addresses ? Yeah, right! As securiteam described [here][1] it is possible to find out your location using Google's Location Services REST API. Further information can be found on Dinis Cruz [blog][2]. But where is all the data coming from? You may also have noticed Google's Street View cars scanning your neighborhood for WLAN access points. Oh, I have forgotten about that: It wasn't Google's intention as stated [here][3]. So MAC source no. 1 is identified. What about the rest? Somehow this equation has to make sense:

~~~.shell
HotSpot/Wlan + GPS + Google =  Your LOCATION!
~~~
Got it? No? It's your mobile phone which reveals your location. Next question should be: Why does Google known about my GPS position and the WLAN router I'm using? Well because you're using house made products like *Android*. So dear Android users: It's about time to ponder about your own privacy.

 [1]: http://blogs.securiteam.com/index.php/archives/1450
 [2]: http://diniscruz.blogspot.com/2010/10/using-mac-address-to-find-your-physical.html
 [3]: http://googleblog.blogspot.com/2010/05/wifi-data-collection-update.html
