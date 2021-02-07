+++
title = "Stay clean and anonymous with Google Apps"
author = "Victor"
date = "2011-02-10"
tags = ["web", "security", "google"]
category = "blog"
+++

I was recently reading some documentary article about the Mexican drug war near USA's national border. Actually it was rather an interview with some guy who fights against the (corrupt) authorities and the drugs leaders by running some informative blog. Feel free to activate your investigative mind and find out which blog I'm talking about...

So this guy was clever enough to hide its identity - what would you do in his case ? - by hiding the domains whois information. These days all you have to do is to find some serious registrar, use some CC and there you go: All your sensible information will be kept private against spammers, hax0rs, feds, ...drug leaders.


~~~.shell
Domain Name:     xxx
$ whois xxx
...
Registrar:       Name.com LLC

Protected Domain Services Customer ID: NCR-xxx

Expiration Date: xxx
Creation Date:   xxx

Name Servers:
        NS1.NAME.COM
        NS2.NAME.COM
        NS3.NAME.COM
        NS4.NAME.COM

REGISTRANT CONTACT INFO
Protected Domain Services - Customer ID: NCR-xxx
P.O. Box 6197
Denver
CO
80206
US
Phone:         +1.7202492374 
Email Address: xxx_at_protecteddomainservices.com
~~~

Ok that's DNS. What about (web) hosting? And here comes the interesting part. I was thinking of some .ru / .pk / .ro (...) hosters to serve the blog content. Far fetched!

~~~.shell
$ dig xxx

; <<>> DiG 9.7.2-P3 <<>> xxx
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35710
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;xxx.              IN      A

;; ANSWER SECTION:
xxx.       1782    IN      CNAME   ghs.google.com.
ghs.google.com.         21506   IN      CNAME   ghs.l.google.com.
ghs.l.google.com.       95      IN      A       74.125.43.121

;; Query time: 4 msec
;; SERVER: xxx
;; WHEN: Thu Feb 10 19:40:05 2011
;; MSG SIZE  rcvd: 95
~~~

Google? Aeehhh? Ok. Let's be sure about that and do some reverse lookup. Therefor I've used my favourite online dns tool DomainTools.com and voila:

~~~
Reverse IP: 1,176,001 other sites hosted on this server.
~~~

0_o Now I'm really confused. Let's hang on for a minute, take a deep breath and seek for the facts: Google seems to host this site and other 1.176.001 other sites too. How can this be? (please forgive me for my naive curiosity, but before this I had no clue about the concept behind this whole thing)

A quick Google search gave me the answer I was looking for: [Google Aps][1]. (I use Google to find out more about Google. Quite ironically, isn't it?) The whole Internet is full of entries related to these Apps. Everybody seems to use these free services - besides me. I've never heard of Google Apps before. Did you? Never mind. Infact I knew [Google Sites][2] which is - in my own oppinion - the easiest way (forget WordPress!) to create a site adapted to your needs in less than 10 minutes. So this is where the whole story ends at.

Supposing you have already achived your whois protected domain, Google will help you map your Google site to your OWN url as stated [here][3]. You'll need to have full access to the DNS administration of your domain and change some [CNAME][4] entries. Afterwards you'll have your domain pointing to the Google site. BTW: If you like [Blogger.com][5] you may want to check [this][6] out. This whole hocus pocus works with MX entries too. So if you want to map your mail address me@example.com to your Google accounts mail address,  follow [these][7] instructions.

So if you ever had some criminal plans in mind or planed doing some `private` stuff, Google might be your friend.

 [1]: http://www.google.com/apps/
 [2]: http://www.google.com/sites/overview.html
 [3]: http://www.google.com/support/sites/bin/answer.py?hl=en&answer=99448
 [4]: http://en.wikipedia.org/wiki/CNAME_record
 [5]: http://blogger.com
 [6]: http://www.google.com/support/blogger/bin/answer.py?hl=en&answer=55373
 [7]: http://www.google.com/support/a/bin/answer.py?hl=en&answer=33352
