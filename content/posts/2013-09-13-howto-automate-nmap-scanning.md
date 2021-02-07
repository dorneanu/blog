+++
title = "HowTo: Automate nmap scanning"
author = "Victor"
date = "2013-09-13"
tags = ["hacking", "howto", "networking", "tools", "nmap"]
category = "blog"
+++

Recently a [colleague][1] of mine at [nullsecurity.net][2] released a new scanning tool called [wnmap][3]. Basically it's a wrapper around nmap which helps automating the scanning process by using simple configuration files. Let's have a look at it..

## Configuration

Make sure you you have downloaded the archive and open **src/core/wnmap.conf** in order to edit:

*   the wnmap path
*   editor preferences
*   global parameters (to use in every scan)

## Running the tool

Now the obligatory -help message:

~~~.shell
-==[ wnmap by nrz@nullsecurity.net ]==--
Usage: wnmap [options] <target specification> | <misc>
TARGET SPECIFICATION:
    Can pass hostname or IP address.
OPTIONS:
    SCANNING - USER MODE:
    -F: 'fast' scan - nmap args: -F
    -K: 'ack' scan - nmap args: -PA
    -V: 'version' scan - nmap args: -sV -version-trace
    -O: 'os' scan - nmap args: -O --osscan-guess
    -M: 'script_malware' scan - nmap args: -script malware
    -H: 'http-methods' scan - nmap args: -P0 --script=http-methods.nse -p 80,443
    SCANNING - STANDARD MODE:
    -C: chain all modes
    LOAD NEW SCAN:
    -a {wnmap_arg;mode_name;nmap_args;need_sudo?[true,false]}: add new scan to user mode
MISC:
    -r: rescan host by default
    -e: edit wmodes.conf
    -v: print version of wnmap and exit
    -h: print this help and exit
EXAMPLES:
    wnmap -F 8.8.8.8 -r # scan again
    wnmap -C scanme.nmap.org # give it all you got
    wnmap -a "-I;iddle-scan;-P0 -p- -sI sweet.host.com;true"
    wnmap -e # edit modes
~~~    

As you can see the tool comes along with several **predefined **running modes. You can easily edit them at **src/core/wmodes.conf:**

~~~.shell
% cat src/core/wmodes.conf
# SAMPLE FILE !!! DEFINE YOUR OWN MAGIC !!!
# wnmap_arg; mode_name; nmap_args; sudo?
-F;fast;-F;false
-K;ack;-PA;false
-V;version;-sV -version-trace;false
-O;os;-O --osscan-guess;true
-M;script_malware;-script malware;false
~~~

Quite handy, isn't it? You can **chain** the modes using **-C. **

## Add new mode

Let's say I want to add a new mode, which will scan all hosts at port 80 and 443 for web services. In particular I want to the the supported HTTP methods at those ports.  
You can easily use the command line to insert the new mode:

~~~.shell
% ./wnmap -a "-H;http-methods;-P0 --script=http-methods.nse -p 80,443;false"
--==[ wnmap by nrz@nullsecurity.net ]==--
[+] New mode added!
~~~

or edit **src/core/wmodes.conf **directly.Now let's scan a host using the newly inserted mode:

~~~.shell
% ./wnmap -H scanme.nmap.org
--==[ wnmap by nrz@nullsecurity.net ]==--
[+] Creating scanme.nmap.org/http-methods
[+] Scanning scanme.nmap.org
[*] cmd: /usr/bin/nmap -P0 --script=http-methods.nse -p 80,443 --reason -oX scanme.nmap.org/http-methods/scanme.nmap.org.xml -oN scanme.nmap.org/http-methods/scanme.nmap.org.nmap scanme.nmap.org
Starting Nmap 6.25 ( http://nmap.org ) at 2013-09-11 15:32 CEST
Nmap scan report for scanme.nmap.org (74.207.244.221)
Host is up, received user-set (0.18s latency).
PORT    STATE  SERVICE REASON
80/tcp  open   http    syn-ack
|_http-methods: GET HEAD POST OPTIONS
443/tcp closed https   conn-refused
Nmap done: 1 IP address (1 host up) scanned in 0.69 seconds
~~~

Now you should see a directory called **scanme.nmap.org** inside your working directory. The output of the scan was saved as a regular nmap file and as XML.

~~~.shell
# tree scanme.nmap.org
scanme.nmap.org
`-- http-methods
    |-- scanme.nmap.org.nmap
    `-- scanme.nmap.org.xml
~~~

## Combine modes

You could now combine the modes:

~~~.shell
% ./wnmap -H -F scanme.nmap.org
~~~

And you'll get:

~~~.shell
# tree scanme.nmap.org 
scanme.nmap.org
|-- fast
|   |-- scanme.nmap.org.nmap
|   `-- scanme.nmap.org.xml
`-- http-methods
    |-- scanme.nmap.org.nmap
    `-- scanme.nmap.org.xml
~~~

 [1]: http://nullsecurity.net/about.html
 [2]: http://nullsecurity.net/
 [3]: http://nullsecurity.net/tools/automation/wnmap-0.1.tar.gz
