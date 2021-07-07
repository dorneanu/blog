+++
title = "hacklu 2018"
author = "Victor Dorneanu"
date = "2018-10-19"
tags = ["events", "hacking"]
category = "notes"
+++

# who

- conference in Luxemburg
- about 300 (at least I think) attendees
- lots of talks but also **workshops**

# Workshops

* [Introduction to Bro Security Monitoring](https://2018.hack.lu/talks/#Introduction+to+Bro+Network+Security+Monitor)
   * perhaps interesting building our SIEM
   * [Bro](https://www.bro.org) is not Snort
   * it is the **backend** for building the SIEM
   * on top you can have ELK stack
   * cool stuff: Bro has an event-drive [scripting language](https://www.bro.org/sphinx/scripting/index.html)
   * syslog/syslog-ng/etc. integration
   * VM is already available to play with

* [Finding vulnerabilities with modern fuzzing techniques](https://2018.hack.lu/talks/#Finding+security+vulnerabilities+with+modern+fuzzing+techniques)
    * we don't really need this
    * but that guy had really cool tipps regarding [AFL](http://lcamtuf.coredump.cx/afl/)
    * slides and VM also available if desired

* [How to analyze the behaviour of malware traffic](https://2018.hack.lu/talks/#Getting+Your+Hands+Dirty%3A+How+to+Analyze+the+Behavior+of+Malware+Traffic+and+Web+Connections)
     * real-life examples of connection PCAP of known malware
     * intersting tipps regarding Wireshark
     * was fun to analyze the PCAPs and kind of deduce what was going at a specific time point

* [Practical Docker security workshop](https://2018.hack.lu/talks/#%2APractical%2A+Docker+Security+Workshop)
     * this was definitely **not** one of those 101 introductions
     * a lot of interesting tipps how to
          * secure docker containers
          * isolate container (network segmentation)
     * I'll put together some **best practices sheet** ASAP
     * I'll also talk to Cloud team to see what can be put in practice

# Talks

These is the talks list I can recommend:

* [The Science Behind Social Engineering And An Effective Security Culture - E. Nicaise](https://www.youtube.com/watch?v=Ndz0S8zhzEU)
* [The Snake Keeps Reinventing Itself - Jean-Ian Boutin and Matthieu Faou](https://www.youtube.com/watch?v=yIibzqEEHV8)

     * it's about [Turla](https://en.wikipedia.org/wiki/Turla_(malware))
      
* [What The Fax?! - Eyal Itkin and Yaniv Balmas](https://www.youtube.com/watch?v=aahHbliwfm0)
     * really **funny** talk
     * you may think that fax is not exploitable
     * the amount of research these guys put in is incredible
     

All talks (and also a bunch of other ones at several conferences) can be found here: 
https://www.youtube.com/channel/UCI6B0zYvK-7FdM0Vgh3v3Tg/videos
