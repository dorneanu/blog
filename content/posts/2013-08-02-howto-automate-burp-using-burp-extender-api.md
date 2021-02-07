+++
title = "HowTo: Automate Burp using Burp Extender API"
author = "Victor"
date = "2013-08-02"
tags = ["coding", "howto", "security", "web", "appsec", "burp", "python", "java"]
category = "blog"
+++

I really love [Burp][1]. Since I use it on a daily basis I thought there might be some way to automate it. Usually I mainly do these steps to scan some URL:

1.  Define scope
2.  Start manual exploring OR spider the URL in order to get some target map
3.  Activate passive scanning
4.  Activate live scanning
5.  Wait to the scan to finish
6.  Have a look at the results
7.  Save/export the results

Well these are a lot of steps which have to be done manually. We all know that necessity is the mother of invention so I've started looking for some concepts how to automate those steps. This is what I've found...  

## Requirements

Before I've started googling for some code I've collected some requirements which *should* be fulfilled:

*   Functional 
    *   Ability to communicate with Burp using some API
    *   Control Burp by command line
    *   Interact with Burp through some console
    *   Tamper requests before being sent in the wild
    *   Create events in order to trigger specific actions
*   Technical 
    *   OS independent (should at least work on Linux and Windows)
    *   Extendibility: Use your favourite programming language (Python, Java whatever) to interact with the API
*   Reportings 
    *   Ability to create/generate/export results as XML, CSV, whatever.

Having this written I've started googling.

# Google found...

*   [Burp Extender API][2]

> <p style="padding-left: 60px;">
>   Burp Extender lets you load Burp extensions, to extend Burp's functionality using your own or third-party code.
> </p>
> 
> <p style="padding-left: 60px;">
>   Burp extensions can customize Burp's behavior in numerous ways, such as modifying HTTP requests and responses, customizing the UI, adding custom Scanner checks, and accessing key runtime information, including the <a href="http://portswigger.net/burp/help/proxy_history.html">Proxy history</a>, <a href="http://portswigger.net/burp/help/target_sitemap.html">Target site map</a> and <a href="http://portswigger.net/burp/help/scanner_results.html">Scanner results</a>. (Source: <a href="http://portswigger.net/burp/help/extender.html">http://portswigger.net/burp/help/extender.html</a>)
> </p>

*   [GDS Burp API][3]

> <p class="crayon-selected" style="padding-left: 60px;">
>   The GDS Burp API exposes a Python object interface to requests/responses recorded by Burp (whether Proxy/Spider/Repeater, etc). The API is used to parse Burp logs, creating a list of Burp objects that contain the request and response data and related meta-data. (Source: <a href="https://github.com/GDSSecurity/burpee">https://github.com/GDSSecurity/burpee</a>)
> </p>

*   [Jython Burp API][4]

> <p style="padding-left: 60px;">
>   Jython-Burp-API exposes a Jython interface to the popular Burp Suite web security testing tool, as an alternative to <a href="http://tduehr.github.com/buby/">Buby</a> for those testers who prefer Python over Ruby. (Souce: <a href="https://github.com/mwielgoszewski/jython-burp-api">https://github.com/mwielgoszewski/jython-burp-api)</a>
> </p>

The Burp Extender API is the main component and plays a crucial role in automating burp. There are a lot of extension (Java, Python, Ruby) and you could easily write your [own][5] one. As you might have noticed there are 3 main supported languages: Java, Ruby and Python. And because I love the pythonic way of life I had closer look at the Jython Burp API. As stated on the github page you can get a jython console to interact with Burp. That's crazy! And this was one of my main requirements.

# Jython Burp API

First I've cloned the github repo and copied Burp into the* jython-burp-api *folder as described in the README.

~~~.shell
$ ls -l
total 13173
drwxr-xr-x 3 vd vd     1024 2013-07-31 14:50 custom-modules
drwxr-xr-x 4 vd vd     1024 2013-08-02 11:27 jython-burp-api-master
lrwxrwxrwx 1 vd vd       28 2013-07-31 14:19 jython.jar -> jython-standalone-2.7-b1.jar
-rw-r--r-- 1 vd vd 13432713 2013-07-31 13:49 jython-standalone-2.7-b1.jar
~~~

I *cd *into* jython-burp-api-master, *copied Burp into it and compiled the Burp Extender files:

~~~.shell
$ ls -l
total 9068
-rw-r--r-- 1 vd vd    2087 2013-05-13 20:27 burp.ini
-rwxr-x--- 1 vd vd 9225061 2013-07-31 14:07 burpsuite_pro_v1.5.11.jar
drwxr-xr-x 3 vd vd    1024 2013-05-13 20:27 java
drwxr-xr-x 3 vd vd    1024 2013-07-31 15:39 Lib
-rw-r--r-- 1 vd vd     739 2013-05-13 20:27 LICENSE
-rw-r--r-- 1 vd vd    6662 2013-05-13 20:27 README.md
-rw-r--r-- 1 vd vd    3592 2013-07-31 15:30 run.py

$ javac -cp ../jython.jar java/src/*.java java/src/burp/*.java
~~~

Afterwards I tried to start Burp (as described in the README) using:

~~~.shell
$ java -Xmx1g -jar ../jython.jar run.py -i -d -B burpsuite_pro_v1.5.11.jar
Traceback (most recent call last):
  File "run.py", line 117, in <module>
    start_burp(opt, *args)
  File "run.py", line 15, in start_burp
    from burp_extender import BurpExtender as MyBurpExtender, ConsoleThread
ImportError: No module named burp_extender
~~~

Hmmm.. Strange. I've created this [issue][6] and informed the developer about the bug. Finally I was able to solve it by myself. The problem was that jython didn't know where to find the module *burp_extender. *So the class path had to be changed:

~~~.shell
$ java -jar ../jython.jar -Dpython.path=Lib/ run.py -B burpsuite_pro_v1.5.11.jar -i -d -v

Jython 2.7b1 (default:ac42d59644e9, Feb 9 2013, 15:24:52) 
[OpenJDK 64-Bit Server VM (Sun Microsystems Inc.)] on java1.6.0_20
>>> 
2013-08-02 11:39:08,582 - BurpExtender - DEBUG - Monitoring jython-burp-api-master/Lib/gds/burp/menu/console.py for changes
2013-08-02 11:39:08,594 - BurpExtender - DEBUG - Monitoring jython-burp-api-master/burp.ini for changes
help
>>> Burp
>>>
~~~

Ahh there we go! Now you should have Burp fired up and a jython console to interact with. Check out [examples][7] for some commands.

# Automation

Having this done the next step was to automate the scanning process. The jython console is very helpful but I somehow have to automate Burp with one command. Sth like:

~~~.shell
$ java -jar ../jython.jar -Dpython.path=Lib/  run.py -B burpsuite_pro_v1.5.11.jar --send-to-spider http://dornea.nu --add-to-scope http://dornea.nu -i
~~~

Well I had some closer look at the *run.py *and modified it a little bit. This is what came out (own modifications have been highlighted):

~~~.python
# -*- coding: utf-8 -*-
from java.lang import System

from org.python.util import JLineConsole, PythonInterpreter

import logging
import os.path
import sys
import time
from threading import Thread

class MyThread(Thread):
    # Run own thread to get things done
    def __init__(self, burp, options):
        Thread.__init__(self, name='jython-console')
        self.opts   = options
        self.burp   = burp

    def run(self):
        from java.net import URL

        # Add new scope
        if self.opts.add_to_scope:
            self.burp.includeInScope(URL(self.opts.add_to_scope))
            print("[--] Added new scope ...")

        # Send URL to spider
        if self.opts.send_to_spider:
            self.burp.sendToSpider(URL(self.opts.send_to_spider))
            print("[--] Starting spider ...")

        # Start interactive jython console
        if self.opts.interactive:
            from java.util import Properties
            pre_properties = System.getProperties()
            pre_properties['python.console'] = 'org.python.util.ReadlineConsole'
            post_properties = Properties()

            PythonInterpreter.initialize(pre_properties, post_properties, [])

            # Attach threaded console to BurpExtender
            self.burp.console = console = JLineConsole()
            console.set('Burp', self.burp)

            try:
                self.burp.stdout.write('Launching interactive session...\n')
            except Exception:
                sys.stdout.write('Launching interactive session...\n')

            ConsoleThread(console).start()

def start_burp(options, *args):
    sys.path.extend([os.path.join('java', 'src'), options.burp])

    from burp_extender import BurpExtender as MyBurpExtender, ConsoleThread
    from burp import StartBurp
    from pprint import pprint
    import BurpExtender

    from gds.burp.config import Configuration

    if options.debug:
        logging.basicConfig(
            filename='jython-burp.log',
            format='%(asctime)-15s - %(levelname)s - %(message)s',
            level=logging.DEBUG)

    elif options.verbose:
        logging.basicConfig(
            filename='jython-burp.log',
            format='%(asctime)-15s - %(levelname)s - %(message)s',
            level=logging.INFO)

    else:
        logging.basicConfig(
            filename='jython-burp.log',
            format='%(asctime)-15s - %(levelname)s - %(message)s',
            level=logging.WARN)

    # Set the BurpExtender handler to the Pythonic BurpExtender
    Burp = MyBurpExtender()
    Burp.config = Configuration(os.path.abspath(opt.config))
    Burp.opt = options
    Burp.args = args

    BurpExtender.setHandler(Burp)
    StartBurp.main(args)

    # In latest Burp, callbacks might not get registered immediately
    while not Burp.cb:
        time.sleep(0.1)

    # Disable Burp Proxy Interception on startup
    Burp.setProxyInterceptionEnabled(False)

    # Check for options and start new thread(s)
    MyThread(Burp, options).start()

if __name__ == '__main__':
    from optparse import OptionParser
    parser = OptionParser()

    parser.add_option('-B', '--load-burp', dest='burp',
                      help='Load Burp Jar from PATH', metavar='PATH')

    parser.add_option('-i', '--interactive',
                      action='store_true',
                      help='Run Burp in interactive mode (Jython Console)')

    parser.add_option('-f', '--file', metavar='FILE',
                      help='Restore Burp state from FILE on startup')

    parser.add_option('-d', '--debug',
                      action='store_true',
                      help='Set log level to DEBUG')

    parser.add_option('-v', '--verbose',
                      action='store_true',
                      help='Set log level to INFO')

    parser.add_option('-P', '--python-path',
                      default='',
                      help='Set PYTHONPATH used by Jython')

    parser.add_option('-C', '--config',
                      default='burp.ini',
                      help='Specify alternate jython-burp config file')

    parser.add_option('--disable-reloading',
                      action='store_true',
                      help='Disable hot-reloading when a file is changed')

    parser.add_option('--send-to-spider', type=str, help='Send URL to spider')
    parser.add_option('--add-to-scope', type=str, help='Add URL to scope')

    opt, args = parser.parse_args()

    if not opt.burp:
        print('Load Burp Error: Specify a path to your burp.jar with -B')
        parser.print_help()
        sys.exit(1)

    start_burp(opt, *args)
~~~

Now I can easily automate following steps:

*   send some URL to the spider
*   add URL to the scope

~~~.shell
$ java -jar ../jython.jar -Dpython.path=Lib/  testing.py -B burpsuite_pro_v1.5.11.jar --send-to-spider http://heise.de --add-to-scope http://heise.de -i 
[--] Added new scope ...
[--] Starting spider ...
...
~~~

The above code is just a PoC. Maybe I'll extend it to some features like

*   logging (specify format)
*   tamper requests before being sent
*   export results (XML)
*   write results to some DB


 [1]: http://portswigger.net/burp/
 [2]: http://portswigger.net/burp/help/extender.html
 [3]: https://github.com/GDSSecurity/burpee
 [4]: https://github.com/mwielgoszewski/jython-burp-api
 [5]: http://blog.portswigger.net/2012/12/writing-your-first-burp-extension.html
 [6]: https://github.com/mwielgoszewski/jython-burp-api/issues/7
 [7]: https://github.com/mwielgoszewski/jython-burp-api#examples
