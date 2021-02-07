+++
title = "HowTo: Put nginx and PHP to jail in Debian 8"
author = "Victor Dorneanu"
date = "2016-01-15"
tags = ["nginx", "php", "admin", "debian", "chroot", "security"]
category = "blog"
+++

Although I thought this would be an easy task, it turned out that **chrooting** daemons takes more than copying config files and libraries. There are donzens of tutorials out there how to do it, but the devil lies in detail - as always. Setting up a chroot environment is easy. But securing it properly is prone to faults which in worst case could let an attacker escape the chroot. And this is your worst nightmare, right? So let's have a look at some more technical details.

For those unfamiliar with `chroot` make sure you have a look at least the [Wikipedia entry](https://en.wikipedia.org/wiki/Chroot).  There are also soms [chroot best practices](http://www.unixwiz.net/techtips/chroot-practices.html) you could have a look at. Although there are better alternatives solving this job (e.g. docker) and being unable to load **LSM** ([Linux Security Modules](https://en.wikipedia.org/wiki/Linux_Security_Modules)) on a vServer, putting a daemon to *jails* seems to be a pretty good approach. But there are several things one should keep in mind since `chroot` isn't a security feature per se (make sure you read ["Is chroot a security feature?"](https://securityblog.redhat.com/2013/03/27/is-chroot-a-security-feature/) and ["What chroot() is really for"](https://lwn.net/Articles/252794/)).


## Before starting 

All the shell commands below are part of a `bash` script I use to setup a secure chroot. Use this [gist](https://gist.github.com/dorneanu/9f940b2ded9c05b5be9f) to download the script files:

* [chroot.sh](https://gist.github.com/dorneanu/9f940b2ded9c05b5be9f#file-chroot-sh)
* [n2chroot](https://gist.github.com/dorneanu/9f940b2ded9c05b5be9f#file-n2chroot)
* [nginx-chroot](https://gist.github.com/dorneanu/9f940b2ded9c05b5be9f#file-nginx-chroot) (to copy to `/etc/init.d/*`)
* [php5-fpm-chroot](https://gist.github.com/dorneanu/9f940b2ded9c05b5be9f#file-php5-fpm-chroot) (to copy to `/etc/init.d/*`)

Make sure you **edit** the files and adapt `BASE` to your **chroot path** (in my scripts: `/var/www/chroot`).


## Unleash the daemons

Nowadays hosting a typical PHP application is  pretty straight-forward. Several components are necesarry:

* web server (`nginx`) hosting the application
* application (`PHP`)
* data base (`mysqld`) for storing information

The `mysqld` will usually listen on *localhost:3306* and can be thus accessed by the processes inside the chroot as well. The `nginx` and the `PHP` daemons have some dependencies to be installed inside the chroot otherwise you won't be able to run them. For the sake of example let's have a look at `nginx`:

~~~.bash
$ ldd /usr/sbin/nginx
    linux-vdso.so.1 (0x00007fffe734d000)
    libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f47b5548000)
    libcrypt.so.1 => /lib/x86_64-linux-gnu/libcrypt.so.1 (0x00007f47b5311000)
    libpam.so.0 => /lib/x86_64-linux-gnu/libpam.so.0 (0x00007f47b5101000)
    libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007f47b4ed8000)
    libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f47b4c6a000)
    libssl.so.1.0.0 => /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 (0x00007f47b4a09000)
    libcrypto.so.1.0.0 => /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0 (0x00007f47b460e000)
[...]
~~~

So there are a lot of libraries which have to be copied into the chroot in order for the `nginx` binary to execute properly. But first, let's setup the basic directory structure.


## chroot() environment

First we'll create the basic directory structure and copy some basic stuff to it:

~~~.bash
# Create devices
$ mkdir $JAIL/dev
$ mknod -m 0666 $JAIL/dev/null c 1 3
$ mknod -m 0666 $JAIL/dev/random c 1 8
$ mknod -m 0444 $JAIL/dev/urandom c 1 9

# Create directories
$ mkdir -p $JAIL/{etc,bin,usr,var}
$ mkdir -p $JAIL/usr/{lib,sbin,bin}
$ mkdir -p $JAIL/{run,tmp}
$ mkdir -p $JAIL/var/run

# Check if 64-bit system
$ if [ $(uname -m) = "x86_64" ]; then
    cd $JAIL; ln -s usr/lib lib64
    cd $JAIL/usr; ln -s lib lib64
else
    cd $JAIL; ln -s usr/lib lib
fi

# Copy important stuff
$ cp -rfvL /etc/{services,localtime,nsswitch.conf,nscd.conf,protocols,hosts,ld.so.cache,ld.so.conf,resolv.conf,host.conf} $JAIL/etc

~~~


## nginx

Next we'll setup `nginx` and copy necessary config files and libraries:


~~~.bash
# Create directories
$ mkdir -p $JAIL/usr/share/nginx
$ mkdir -p $JAIL/var/{log,lib}/nginx
$ mkdir -p $JAIL/www/cgi-bin

# Copy files
$ cp -r /usr/share/nginx/* $JAIL/usr/share/nginx
$ cp /usr/sbin/nginx $JAIL/usr/sbin/
$ cp -r /var/lib/nginx $JAIL/var/lib/nginx

# Copy libraries
$ ${N2CHROOT} /usr/sbin/nginx

# Copy config files and other important stuff
$ cp -rfvL /etc/nginx $JAIL/etc

# Create PID file
$ touch $JAIL/run/nginx.pid

# Copy the nginx binary
$ cp /usr/sbin/nginx $JAIL/usr/sbin/
~~~

### Troubleshooting

First let's see if we can run the daemon at all:

~~~.bash
$ /usr/sbin/chroot $JAIL /usr/sbin/nginx -t                
nginx: [emerg] getpwnam("www-data") failed in /etc/nginx/nginx.conf:1
nginx: configuration file /etc/nginx/nginx.conf test failed
~~~

OK. Let's have a look at `strace`:

~~~.bash
mmap(NULL, 39842, PROT_READ, MAP_PRIVATE, 5, 0) = 0x7f1d0c620000
close(5)                                = 0
access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
open("/lib/x86_64-linux-gnu/libnss_compat.so.2", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
...
exit_group(1)                           = ?
+++ exited with 1 +++
~~~


Apparently `libnss` can't be found. Let's fix that:

~~~.bash
$ find / -name "libnss*"
/lib/x86_64-linux-gnu/libnss_nis-2.19.so
/lib/x86_64-linux-gnu/libnss_compat-2.19.so
/lib/x86_64-linux-gnu/libnss_compat.so.2
/lib/x86_64-linux-gnu/libnss_nisplus.so.2
/lib/x86_64-linux-gnu/libnss_nis.so.2
/lib/x86_64-linux-gnu/libnss_files.so.2
/lib/x86_64-linux-gnu/libnss_dns.so.2
/lib/x86_64-linux-gnu/libnss_files-2.19.so
/lib/x86_64-linux-gnu/libnss_hesiod.so.2
/lib/x86_64-linux-gnu/libnss_nisplus-2.19.so
/lib/x86_64-linux-gnu/libnss_hesiod-2.19.so
/lib/x86_64-linux-gnu/libnss_dns-2.19.so
/usr/lib/x86_64-linux-gnu/libnss_nisplus.so
/usr/lib/x86_64-linux-gnu/libnss_hesiod.so
/usr/lib/x86_64-linux-gnu/libnss_compat.so
/usr/lib/x86_64-linux-gnu/libnss_files.so
/usr/lib/x86_64-linux-gnu/libnss_dns.so
/usr/lib/x86_64-linux-gnu/libnss_nis.so

# cp /lib/x86_64-linux-gnu/libnss_* $JAIL/lib/x86_64-linux-gnu/
~~~

Let's give it a 2nd try:

~~~.bash
$ /usr/sbin/chroot $JAIL /usr/sbin/nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
~~~

## php5-fpm

The PHP FastCGI Process Manager (`php5-fpm`) also requires some libraries and config files that have to be available in the new `chroot`:

~~~.bash
# Copy config files
$ cp -rfvl /etc/php5 $JAIL/etc/
$ cp -rfvl /usr/share/zoneinfo $JAIL/usr/share/

# Copy libraries
$ ${N2CHROOT} /usr/sbin/php5-fpm

# Copy the php5-fpm binary
$ cp /usr/sbin/php5-fpm $JAIL/usr/sbin/
~~~

Let's check if everything is ok:

~~~.bash
$ /usr/sbin/chroot $JAIL /usr/sbin/php5-fpm --help
Failed loading /usr/lib/php5/20131226/opcache.so:  /usr/lib/php5/20131226/opcache.so: cannot open shared object file: No such file or directory
[11-Jan-2016 19:46:19] NOTICE: PHP message: PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/lib/php5/20131226/mysqlnd.so' - /usr/lib/php5/20131226/mysqlnd.so: cannot open shared object file: No such file or directory in Unknown on line 0
[11-Jan-2016 19:46:19] NOTICE: PHP message: PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/lib/php5/20131226/pdo.so' - /usr/lib/php5/20131226/pdo.so: cannot open shared object file: No such file or directory in Unknown on line 0
[11-Jan-2016 19:46:19] NOTICE: PHP message: PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/lib/php5/20131226/curl.so' - /usr/lib/php5/20131226/curl.so: cannot open shared object file: No such file or directory in ...
~~~

Obviously some libraries are still missing. Let's fix that:

~~~.bash
$ cp -rvfl /usr/lib/php5 $JAIL/usr/lib
$ for f in /usr/lib/php5/20131226/*.so; do
>    n2chroot $f
> done
~~~

The `for`-loop will look at every php-module and copy its dependant libraries to the chroot. 


### Can't execute exec(), shell_exec() or system()

If you experience some sort of problems like [this](http://stackoverflow.com/questions/17006136/exec-with-php-fpm-on-nginx-under-chroot-returns-nothing) you probably have no `/bin/sh` inside your chroot (which is great after all, since we want to strip down the environment to a minimal setup). However **PHP**'s functions like `exec()`, `shell_exec()` or `system()`will internally call `/bin/sh -c` to run the commands. So if your PHP application is using something like `sendmail` and you don't want to install any shell into your chroot, I've found this [solution](https://knzl.de/setting-up-a-chroot-for-php/) from *Sebastian Kienzl* which basically consists in providing a "shell" which will in turn use `execvp()` to run commands. 


~~~.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
 
#define MAXARG 64
 
int main( int argc, char* const argv[] ) {
    char* args[ MAXARG ] = {};
 
    if( argc < 3 || strcmp( argv[1], "-c" ) != 0 ) {
        fprintf( stderr, "Usage: %s -c <cmd>\n", argv[0] );  
        return 1;
    }
 
    {
        char* token;
        int i = 0;  
        char* argStr = strdup( argv[2] );
        while( ( token = strsep( &argStr, " " ) ) != NULL ) {
            if( token && strlen( token ) )
                args[ i++ ] = token;
            if( i >= MAXARG )
                return 2;
        }
    }  
 
    return execvp( args[0], args );
}
~~~


Compile this using (I use `clang`):

~~~.bash
$ clang -O2 -fpie -pie -Wformat -Wformat-security -Werror=format-security -D_FORTIFY_SOURCE=2 \
  sh.c -o sh
~~~

Now remove the sources and strip the binary:

~~~.bash
$ rm sh.c
$ strip sh
~~~


However this approach seemed to introduce more problems than it was a decent solution. Depending on the applications and the scope you can decide whether to use a wrapper or provide `/bin/sh` inside your chroot. Nevertheless there should be no `setuid` binaries. More on that later.


### Timezone is corrupt

If you have issues like:

~~~.bash
PHP message: PHP Fatal error:  date(): Timezone database is corrupt - this should *never* happen!
~~~


or 

~~~.bash
PHP message: PHP Notice:  date_default_timezone_set(): Timezone ID 'UTC' is invalid
~~~

make sure you copy `/usr/share/zoneinfo` into the chroot:

~~~.bash
$ cp -Rv /usr/share/zoneinfo $JAIL/usr/share/
~~~



## Adjust chroot() security

In fact the actual hardening of the environment has not taken place already. Many people have pointed out that **chroot != security** and additional steps are vital for not being able to **unchroot** inside it. A few years ago [Filippo](https://filippo.io/escaping-a-chroot-jail-slash-1/) also showed how easy an attacker could achieve that if specific conditions were satisfied. Since `chroot()` in my opinion it not **THE** security feature I'd say it's sort of **security in depth**. Although there are enough cases where  leaving the chroot is possible - if securing it hasn't been done correctly, some recommendations from [here](http://talby.rcs.manchester.ac.uk/~isd/_unix_security/unix_security_intro_securing_network_services.Breaking_Out_of_and_Securing_Chroot_Jails.html) should be taken into consideration:

* **not** run daemons as **root**
* avoid **setuid** executables
* ensure root (**UID 0**) does not even exist within the jail
* avoid unnecessary bullshit and only install the minimum inside the jail

Let's translate those into commands:

~~~.bash
# Add users
$ echo "www-data:x:1337:1337:www-data:/:/bin/false" >> $JAIL/etc/passwd
$ echo "nobody:x:99:99:nobody:/:/bin/false" >> $JAIL/etc/passwd

# Add groups
$ echo "www-data:x:1337:" >> $JAIL/etc/group
$ echo "nobody:x:99:" >> $JAIL/etc/group

# Add shadow
$ echo "www-data:x:14871::::::" >> $JAIL/etc/shadow
$ echo "nobody:x:14871::::::" >> $JAIL/etc/shadow

# Add gshadow
$ echo "www-data:::" >> $JAIL/etc/gshadow
$ echo "nobody:::" >> $JAIL/etc/gshadow

# Set ownerships
$ chown -R root:root $JAIL/
$ chown -R www-data:www-data $JAIL/www
$ chown -R www-data:www-data $JAIL/etc/{nginx,php5}
$ chown -R www-data:www-data $JAIL/var/{log,lib}/nginx
$ chown www-data:www-data $JAIL/run/nginx.pid

# Restrict permissions
$ find $JAIL/ -gid 0 -uid 0 -type d -print | xargs chmod -rw
$ find $JAIL/ -gid 0 -uid 0 -type d -print | xargs chmod +x
$ find $JAIL/etc -gid 0 -uid 0 -type f -print | xargs chmod -x
$ find $JAIL/usr/sbin -type f -print | xargs chmod ug+rx
$ find $JAIL/ -group www-data -user www-data -print | xargs chmod o-rwx
$ chmod +rw $JAIL/tmp
$ chmod +rw $JAIL/run
~~~



## systemd

Since `systemd`is now everywhere you can define your own **service** to start the daemons.


### nginx

~~~.bash
$ sudo cat /etc/systemd/system/multi-user.target.wants/nginx.service 
# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=nginx (Chroot)
After=network.target

[Service]
Type=forking
PIDFile=/var/www/chroot/run/nginx.pid
RootDirectory=/var/www/chroot
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx.conf -s reload
ExecStop=/usr/sbin/nginx -c /etc/nginx/nginx.conf -s stop
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
~~~

Now run it:

~~~.bash
$ sudo service nginx start
$ ps -ax | grep nginx
28530 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
28531 ?        S      0:00 nginx: worker process
28613 pts/0    S+     0:00 grep nginx
$ ls -l /proc/28530/root
sudo ls -l /proc/28530/root
lrwxrwxrwx 1 root root 0 Jan 12 21:31 /proc/28530/root -> /var/www/chroot
~~~


If you don't want to use `systemd` you can use following to start/stop `nginx`:

~~~.bash
$ chroot $JAIL /usr/sbin/nginx
$ pgrep nginx | xargs kill -9
~~~


### php5-fpm

The same applies to `php5-fpm` too:

~~~.bash
$ cat /etc/systemd/system/multi-user.target.wants/php5-fpm.service
[Unit]
Description=The PHP FastCGI Process Manager
After=network.target

[Service] 
Type=notify
PIDFile=/var/run/php5-fpm.pid
ExecStartPre=/usr/xbin/php5 -t
ExecStart=/usr/sbin/php5-fpm --daemonize --fpm-config /etc/php5/fpm/php-fpm.conf
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target
~~~

or start it manually:

~~~.bash
$ chroot $JAIL /usr/sbin/php5-fpm --daemonize --fpm-config /etc/php5/fpm/php-fpm.conf
$ pgrep php | xargs kill -9
~~~

Check if it's indeed running in the chroot:

~~~.bash
$ ps -ax |grep fpm
 9468 ?        Ss     0:00 php-fpm: master process (/etc/php5/fpm/php-fpm.conf)
 9469 ?        S      0:00 php-fpm: pool www
 9470 ?        S      0:00 php-fpm: pool www
 
$ ls -l /proc/9468/root
lrwxrwxrwx 1 root root 0 Jan 13 18:04 /proc/9468/root -> /var/www/chroot
~~~


## System V

If you don't like `systemd` you can still do it the old way and have your scripts at `/etc/init.d/*`. 

### nginx

~~~.bash
$ cat /etc/init.d/nginx-chroot 
#!/bin/sh
 
### BEGIN INIT INFO
# Provides:          nginx-chroot
# Required-Start:    
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start nginx in a chroot
### END INIT INFO
 
CHROOT=/var/www/chroot
 
case "$1" in
  start)
        /usr/sbin/chroot $CHROOT /usr/sbin/nginx -q -g 'daemon on; master_process on;'
        ;;  
  reload)
        /usr/sbin/chroot $CHROOT /usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
        ;;
  stop) 
        pgrep nginx | xargs kill -9  
        ;; 
  *)
        echo "Usage: $N {start|reload|stop}" >&2
        exit 1
        ;;
esac
 
exit 0
~~~

### php5-fpm

~~~.bash
$ cat /etc/init.d/php5-fpm-chroot 
#!/bin/sh
 
### BEGIN INIT INFO
# Provides:          php5-fpm-chroot
# Required-Start:    
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start php5-fpm in a chroot
### END INIT INFO
 
CHROOT=/var/www/chroot
 
case "$1" in
  start)
        /usr/sbin/chroot $CHROOT /usr/sbin/php5-fpm --daemonize --fpm-config /etc/php5/fpm/php-fpm.conf
        ;;  
  stop) 
        pgrep php | xargs kill -9  
        ;; 
  *)
        echo "Usage: $N {start|stop}" >&2
        exit 1
        ;;
esac
 
exit 0
~~~

### Install new services

First of all make sure you **remove** the old ones:

~~~.bash
$ update-rc.d nginx remove
$ update-rc.d php5-fpm remove
~~~

Now **add** the **new** ones:

~~~.bash
$ update-rc.d nginx-chroot defaults
$ update-rc.d php5-fpm-chroot defaults
~~~

## Conclusion

Now you have a basic structure to work with. You might want to add more **binaries** to the chroot but keep in mind the implied security concerns. And also try **not** to use symlinks/hardlinks to directories outside the chroot. You can always always override config files in the chroot with backuped one. And to make sure that everything works well, think about using [auditd](http://linux.die.net/man/8/auditd) for monitoring file changes inside the chroot. 


## References

* [Howt multiple websites with nginx and php-fpm](https://www.digitalocean.com/community/tutorials/how-to-host-multiple-websites-securely-with-nginx-and-php-fpm-on-ubuntu-14-04)
* [Escaping a chroot](https://filippo.io/escaping-a-chroot-jail-slash-1/)
* [exec with php-fpm on nginx under chroot](http://stackoverflow.com/questions/17006136/exec-with-php-fpm-on-nginx-under-chroot-returns-nothing)
* [Setting up a chroot for php](https://knzl.de/setting-up-a-chroot-for-php/)
