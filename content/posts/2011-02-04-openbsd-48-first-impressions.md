+++
title = "OpenBSD 4.8 - First impressions"
author = "Victor"
date = "2011-02-04"
tags = ["openbsd", "admin", "networking"]
category = "blog"
+++

Today I had the big opportunity to setup an OpenBSD based gateway. I've never used OpenBSD before and I was really excited about. All in one: Really clean (almost spartanic), secure 4.4BSD. Although I had some problems during the partitioning process - I didn't thought they have such a l33t partitioning tool - the installation went smooth. Afterwards I've fetched the [ports][1] and installed some common utilities: No compilation errors etc.

Here some pics:

![](/posts/img/2011/230/04022011268.jpg)

![](/posts/img/2011/230/04022011269.jpg)

Then my first ipf configuration:

~~~.shell
# Set network interfaces
ext_if=sk0 #internet
int_if=sk1  #LAN
# Allowed  icmp type
icmp_types=echoreq

# Skip all loopback traffic
set skip on lo

# Scrub all traffic
scrub in

# Perform NAT on external interface
nat on $ext_if from $int_if:network -> ($ext_if:0)

# Define default behavior: block IN, pass OUT
block in
pass out keep state

# Allow inbound traffic on internal interface
pass quick on $int_if

# No spoofing
antispoof quick for { lo $int_if }
~~~

Quite easy, isn't it?


**[Update: 2011-02-17]**

As stated [here][4] there have been some changes made to the pf syntax in 4.8.

~~~.shell
# Perform NAT on external interface
nat on $ext_if from $int_if:network -> ($ext_if:0)
~~~

should be changed to

~~~.shell
..
match out on $ext_if from $int_if nat-to ($ext_if)
...
~~~

 [1]: http://www.openbsd.org/faq/faq15.html
 [4]: http://www.openbsd.org/faq/upgrade47.html
