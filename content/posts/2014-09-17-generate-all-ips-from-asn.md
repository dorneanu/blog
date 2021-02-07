+++
title = "Generate all IP addresses from ASN"
date = "2014-09-17"
tags = ["networking", "hacking", "ipv4", "python"]
author = "Victor Dorneanu"
category = "blog"
+++

Sometimes you need to know if a certain IP (or several ones) are within an IP range or belong to a certain [ASN](http://en.wikipedia.org/wiki/Autonomous_System_%28Internet%29). Let's give it a try and generate all possible IP addresses for [telekom.de](http://telekom.de). 

~~~ shell
$ dig telekom.de 
...
telekom.de.     86346   IN  A   46.29.100.76
...
~~~

Now let's find out the ASN:

~~~ shell
$ whois 46.29.100.76 | grep origin            
origin:         AS34086
~~~

Now ask [RIPE](http://ripe.net) for the IP ranges:

~~~ shell
$ whois -h whois.ripe.net -T route AS34086 -i origin | egrep "route: " | awk '{print $NF}'   
145.225.1.0/24
151.136.0.0/16
185.9.216.0/22
193.143.55.0/24
193.143.56.0/24
193.143.57.0/24
217.150.144.0/20
217.150.144.0/21
46.29.96.0/21
93.188.240.0/21
94.100.240.0/20
~~~

Now for every IP range let's generate all *possible* IP addresses. Therefore I've wrote a simple python script. 

> I know there is [cidr2range](www.cpan.org/authors/id/R/RA/RAYNERLUC/cidr2range-0.9.pl) but that didn't work for certain blocks like **145.225.1.0/24**.

~~~ shell
$ cat cidr2list.py 
#!/usr/bin/env python2

import sys
from netaddr import IPNetwork

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "Usage: %s <CIDR Block>\n" % sys.argv[0]
    else:
        for ip in IPNetwork(sys.argv[1]):
            print '%s' % ip
~~~

Now let's generate the lists:

~~~ shell
$ whois -h whois.ripe.net -T route AS34086 -i origin | egrep "route: " | awk '{print $NF}'  >> /tmp/ip-ranges.txt
$ cat /tmp/ip-ranges.txt | xargs -n1 ./cidr2list.py > /tmp/ip-lists.txt
$  head -n 10 /tmp/ip-lists.txt 
145.225.1.0
145.225.1.1
145.225.1.2
145.225.1.3
145.225.1.4
145.225.1.5
145.225.1.6
145.225.1.7
145.225.1.8
145.225.1.9
$ wc -l /tmp/ip-lists.txt 
81920 /tmp/ip-lists.txt
~~~

Voila! :) 





