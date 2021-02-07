+++
title = "Chrooting nginx, php-fpm and mysql using Bitnami "
date = "2016-02-12"
tags = ["nginx", "php", "admin", "debian", "chroot", "security", "bitnami"]
category = "blog"
+++

Having talked about hardening your server using `chroot` in a [previous post](http://blog.dornea.nu/2016/01/15/howto-put-nginx-and-php-to-jail-in-debian-8) I've felt that the whole process was way to complicated. I wanted to have a more **generic** solution regardless of the operating system (and especially the Linux distro). Besides that I wasn't quite happy changing the systems `systemd` settings and do several modifications to the already **running** system. What I wanted to achieve was a **closed**, **portable** system of running applications inside a `chroot` environment. 

And then I've remembered using some [bitnami](https://bitnami.com) applications in the past. You can either run them in the *cloud*, in a *virtual machine* or install them **locally**. The *local* installation will install a whole software [stack](https://bitnami.com/stacks) inside a directory (*closed* system). You can then start the whole stack using *shell scripts*:

~~~ shell
$ ./ctlscript.sh help
usage: ./ctlscript.sh help
       ./ctlscript.sh (start|stop|restart|status)
       ./ctlscript.sh (start|stop|restart|status) mysql
       ./ctlscript.sh (start|stop|restart|status) php-fpm
       ./ctlscript.sh (start|stop|restart|status) nginx

help       - this screen
start      - start the service(s)
stop       - stop  the service(s)
restart    - restart or start the service(s)
status     - show the status of the service(s)
~~~ 

The binaries inside the stack are using **libraries** inside the *closed* system (by changing `LD_LIBRARY_PATH`). So the Bitnami installation will run out of the stack without interacting with the underlying operating system (read more about the technology [here](https://bitnami.com/learn_more)). This is a great advantage since you can simply **copy** the directory, change the **settings** and you'll have another instance running in its own directory (remember the **portable** aspect of my wish list before?)

However the Bitnami stacks won't use `chroot` by default. This is where I had to commit my own modifications to the local installation. But, one thing after another. 

## The Nginx stack

If you're recalling the [previous post](http://blog.dornea.nu/2016/01/15/howto-put-nginx-and-php-to-jail-in-debian-8), my `chroot` environment consisted of: `nginx`, `php-fpm` and `mysql`. Fortunately Bitnami provides a [Nginx Stack](https://bitnami.com/stack/nginx) which is a:

>"... complete,  fully-integrated and ready to run PHP, MySQL and Nginx development environment. In addition, it bundles phpMyAdmin, SQLite, ImageMagick, FastCGI, Memcache, GD, CURL, PEAR, PECL and other components. Also known as LEMP for Linux, WEMP for Windows and MEMP for OS X." (Source: <https://bitnami.com/stack/nginx>)

So let's give it a try.


## Installing Bitnami Nginx stack

Download the [installer](https://bitnami.com/stack/nginx/installer) to your machine and run it: 

~~~ .shell
# ./bitnami-nginxstack-1.9.10-0-linux-x64-installer.run 
----------------------------------------------------------------------------
Welcome to the Bitnami Nginx Stack Setup Wizard.

----------------------------------------------------------------------------
Select the components you want to install; clear the components you do not want 
to install. Click Next when you are ready to continue.

Varnish [Y/n] :n

PhpMyAdmin : Y (Cannot be edited)

Is the selection above correct? [Y/n]: Y

----------------------------------------------------------------------------
Installation folder

Please, choose a folder to install Bitnami Nginx Stack

Select a folder [/opt/nginxstack-1.9.10-0]: /home/bitnami/nginxstack

----------------------------------------------------------------------------
Create MySQL 'root' Account

Bitnami Nginx Stack database root user creation

Password :
Re-enter :
----------------------------------------------------------------------------
MySQL Information

Please enter your MySQL database information:

MySQL Server port [3306]: 3307 

----------------------------------------------------------------------------
Please enter the port that the bundled Nginx Server will listen to by default.

Nginx Port [80]: 8080

----------------------------------------------------------------------------
Setup is now ready to begin installing Bitnami Nginx Stack on your computer.

Do you want to continue? [Y/n]: Y

----------------------------------------------------------------------------
Please wait while Setup installs Bitnami Nginx Stack on your computer.

 Installing
 0% ______________ 50% ______________ 100%
 #########################################

----------------------------------------------------------------------------
Setup has finished installing Bitnami Nginx Stack on your computer.

Launch Bitnami Nginx Stack [Y/n]: n
~~~

A few observations:

* I've installed the stack to `/home/bitnami/nginxstack`
* `MySQL` will listen on `localhost:3307`
* `nginx` will listen on `localhost:8080`

## Setup chroot environment

Now that we have installed the *nginx stack*, we'll setup a `chroot` environment and copy the *nginx stack directory* to it. Supposing that the chroot will be located at `/home/bitnami/nginxstack-chroot`, inside the chroot we'll have following directory structure:

~~~ shell
$ tree -L 3
.
|-- bin
|-- dev
|   |-- null
|   |-- random
|    -- urandom
|-- etc
|   ...
|-- home
|   -- bitnami
|       -- nginxstack
|-- lib
|   ...
|-- lib64 -> usr/lib
|-- run
|-- tmp
|-- usr
|   ...
|-- var
    ...
~~~

So the nginx stack directory will be available at `/home/bitnami/nginxstack-chroot/home/bitnami/nginxstack`. This is **very important** and you should take care having the same structure. Let's setup the chroot using following script:

~~~ shell
#!/bin/bash

export N2CHROOT=/home/bitnami/scripts/n2chroot
export JAIL=/home/bitnami/nginxstack-chroot
export BITNAMI=/home/bitnami/nginxstack
export BITNAMI_INSTALLDIR=$JAIL/$BITNAMI

function create_chroot {
    # Create devices
    mkdir $JAIL/dev
    mknod -m 0666 $JAIL/dev/null c 1 3
    mknod -m 0666 $JAIL/dev/random c 1 8
    mknod -m 0444 $JAIL/dev/urandom c 1 9

    # Create directories
    mkdir -p $JAIL/{etc,bin,usr,var}
    mkdir -p $JAIL/usr/{lib,sbin,bin}
    mkdir -p $JAIL/{run,tmp}
    mkdir -p $JAIL/var/run
    mkdir -p $JAIL/$BITNAMI/{php,nginx,mysql}
    mkdir -p $JAIL/$BITNAMI/php/lib
    mkdir -p $JAIL/$BITNAMI/nginx/lib
    mkdir -p $JAIL/$BITNAMI/common/lib
    mkdir -p $JAIL/$BITNAMI/mysql/lib
    
    # Check if 64-bit system
    if [ $(uname -m) = "x86_64" ]; then
        mkdir -p $JAIL/lib/x86_64-linux-gnu
        cd $JAIL; ln -s usr/lib lib64
        cd $JAIL/usr; ln -s lib lib64
    else
        cd $JAIL; ln -s usr/lib lib
    fi

    # Copy important stuff
    cp -rfvL /etc/{services,localtime,nsswitch.conf,nscd.conf,protocols,hosts,ld.so.cache,ld.so.conf,resolv.conf,host.conf} $JAIL/etc

    # Cp bitnami to the chroot
    # cp -Rv $BITNAMI $JAIL/home/bitnami/ 
}

function add_users {
    # Most instructions from https://wiki.archlinux.org/index.php/nginx#Installation_in_a_chroot
    # Add users
    echo "daemon:x:1:1:daemon:/:/bin/false" >> $JAIL/etc/passwd
    echo "mysql:x:100:101:MySQL Server,,,:/nonexistent:/bin/false" >> $JAIL/etc/passwd
    echo "nobody:x:99:99:nobody:/:/bin/false" >> $JAIL/etc/passwd


    # Add groups
    echo "daemon:x:1:" >> $JAIL/etc/group
    echo "mysql:x:101:" >> $JAIL/etc/group
    echo "nobody:x:99:" >> $JAIL/etc/group

    # Add shadow
    echo "daemon:x:14871::::::" >> $JAIL/etc/shadow
    echo "mysql:!:16755:0:99999:7:::" >> $JAIL/etc/shadow
    echo "nobody:x:14871::::::" >> $JAIL/etc/shadow

    # Add gshadow
    echo "daemon:::" >> $JAIL/etc/gshadow
    echo "mysql:!::" >> $JAIL/etc/gshadow
    echo "nobody:::" >> $JAIL/etc/gshadow
}

function add_libraries {
    # Add system stuff
    cp /lib/x86_64-linux-gnu/libnsl* $JAIL/lib/x86_64-linux-gnu/
    cp /lib/x86_64-linux-gnu/libnss* $JAIL/lib/x86_64-linux-gnu/
    
    # Add nginx stuff
    # $N2CHROOT $BITNAMI_INSTALLDIR/nginx/sbin/.nginx.bin
    cp /lib/x86_64-linux-gnu/libnsl* $BITNAMI_INSTALLDIR/common/lib/
    cp /lib/x86_64-linux-gnu/libnss* $BITNAMI_INSTALLDIR/common/lib/
    cp /lib/x86_64-linux-gnu/libpthread* $BITNAMI_INSTALLDIR/common/lib/
    cp /lib/x86_64-linux-gnu/libpcre* $BITNAMI_INSTALLDIR/common/lib/
    cp /lib/x86_64-linux-gnu/libdl* $BITNAMI_INSTALLDIR/common/lib/
    cp /lib/x86_64-linux-gnu/libgcc* $BITNAMI_INSTALLDIR/common/lib/
    cp /lib/x86_64-linux-gnu/libresolv* $BITNAMI_INSTALLDIR/common/lib/

    # Add php-fpm stuff
    cd $BITNAMI_INSTALLDIR/php/lib
    ln -s ../../common/lib/libresolv.so.2 

    # Add mysql stuff
    cd $BITNAMI_INSTALLDIR/mysql/lib
    ln -s ../../common/lib/libdl.so.2
    ln -s ../../common/lib/libgcc_s.so.1 
    ln -s ../../common/lib/libpthread.so.0 
}

function add_binaries {
    # Add shell
    cp /bin/sh $JAIL/bin/
    $N2CHROOT /bin/sh

    # Add nohup (mysqld needs it)
    cp /usr/bin/nohup $JAIL/usr/bin
}

function fix_permissions {
    cd $BITNAMI_INSTALLDIR/mysql
    chown -R mysql:mysql .

    cd $BITNAMI_INSTALLDIR/php
    chown -R daemon:daemon .

    cd $BITNAMI_INSTALLDIR/nginx
    chown -R daemon:daemon .
}

# Run functions
create_chroot
add_users
add_libraries
add_binaries
fix_permissions

~~~

The `N2CHROOT` script can be found [here](https://gist.github.com/dorneanu/9f940b2ded9c05b5be9f#file-n2chroot). Make sure it's located inside `/home/bitnami/scripts` and also change the `BASE` variable inside the script to `/home/bitnami/nginxstack-chroot`.  Now [download](https://gist.github.com/dorneanu/9f940b2ded9c05b5be9f#file-nginx-chroot-bitnami) the script and run it:

~~~ shell
$ export JAIL=/home/bitnami/nginxstack-chroot
$ cd $JAIL
$ ../scripts/nginx-chroot-bitnami.sh
...
~~~

Now you should have following structure:

~~~ shell
$ tree -L 3
.
|-- bin
|    -- sh
|-- dev
|   |-- null
|   |-- random
|    -- urandom
|-- etc
|   |-- group
|   |-- gshadow
|   |-- host.conf
|   |-- hosts
|   |-- ld.so.cache
|   |-- ld.so.conf
|   |-- localtime
|   |-- nsswitch.conf
|   |-- passwd
|   |-- protocols
|   |-- resolv.conf
|   |-- services
|    -- shadow
|-- home
|    -- bitnami
|        -- nginxstack
|-- lib
|    -- x86_64-linux-gnu
|       |-- libc.so.6
|       |-- libcrypt.so.1
|       |-- libm.so.6
|       |-- libpthread.so.0
|        -- librt.so.1
|-- lib64 -> usr/lib
|-- run
|-- tmp
|-- usr
|   |-- bin
|   |-- lib
|   |   |-- ld-linux-x86-64.so.2
|   |    -- x86_64-linux-gnu
|   |-- lib64 -> lib
|    -- sbin
 -- var
     -- run
~~~


Since all config files created by the bitnami installer point to `/home/bitnami/nginxstack` I will create a new **link** to point to the right directory inside the `chroot`:

~~~ shell
$ cd /home/bitnami
$ ln -s nginxstack-chroot/home/bitnami/nginxstack nginxstack
~~~

**This is very important**, since all daemons (nginx, php-fpm, mysqld) will look at `/home/bitnami/nginxstack` for their config files etc. before entering the `chroot`. 

## Patch scripts

Now the **controll scripts** have to be modified to run the binaries in a `chroot`. 


### Patch setenv.sh

At `/home/bitnami/nginxstack/scripts/setenv.sh` (inside the `chroot`) there is a script which sets all the environment variables (e.g. `LD_LIBRARY_PATH`) for the binaries. We'll use this script to set a variable which we'll use a few times in some other scripts. At the beginning of the script set the `JAIL` variable accordingly:

~~~ shell
#!/bin/sh
export JAIL=/home/bitnami/nginxstack-chroot

[...]
~~~
 
 
### Patch nginx control script

When calling `./ctlscript.sh start nginx` the script will then call `./nginx/scripts/ctl.sh` and finally this will call `./nginx/sbin/nginx`. The last contains the commands for calling the `nginx` binary directly. You'll have sth like this:

~~~ shell
#!/bin/sh

. /home/bitnami/nginxstack/scripts/setenv.sh

exec /home/bitnami/nginxstack/nginx/sbin/.nginx.bin -p /home/bitnami/nginxstack/nginx/ "$@"
~~~


Now we want the `nginx` binary to run inside the `chroot`:

~~~ shell
#!/bin/sh

. /home/bitnami/nginxstack/scripts/setenv.sh

exec /usr/sbin/chroot $JAIL /home/bitnami/nginxstack/nginx/sbin/.nginx.bin -p /home/bitnami/nginxstack/nginx/ "$@"
~~~

Using almost the same command you can if `nginx` will run properly:

~~~ shell
$ /usr/sbin/chroot $JAIL sh -c 'LD_LIBRARY_PATH="/home/bitnami/nginxstack/sqlite/lib:/home/bitnami/nginxstack/nginx/lib:/home/bitnami/nginxstack/mysql/lib:/home/bitnami/nginxstack/common/lib" /home/bitnami/nginxstack/nginx/sbin/.nginx.bin -t -p /home/bitnami/nginxstack/nginx'
nginx: the configuration file /home/bitnami/nginxstack/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /home/bitnami/nginxstack/nginx/conf/nginx.conf test is successful

~~~

I've set the `LD_LIBRARY_PATH` manually since not all libs are located at `/lib/*`. 


### Patch php-fpm control script

Despite some previous approaches this turned out to be a very simple step. All you'll have to do is to add following lines to your `php-fpm.conf` insde `/home/bitnami/nginxstack/php/etc/php-fpm.conf`:

~~~ shell
chroot = /home/bitnami/nginxstack-chroot
chdir = /
~~~

This will put the `php-fpm` workers into `/home/bitnami/nginxstack-chroot`. However, you may want to restrict that a little bit more and "jail" `php-fpm` to `/home/bitnami/nginxstack/apps/yourapp`. I'll come back to this point in a sec. 

### Patch mysql control script

Patching the `mysql` control scripts seemed to be a never-ending story. Till I've found `--chroot`:


>"Put the mysqld server in a closed environment during startup by using the chroot() system call." (Source: <http://dev.mysql.com/doc/refman/5.7/en/server-options.html>)

Bingo! At `/home/bitnami/nginxstack/mysql/scripts/ctl.sh` you'll have sth like this:

~~~ shell
#!/bin/sh

MYSQL_PIDFILE=/home/bitnami/nginxstack/mysql/data/mysqld.pid

MYSQL_START="/home/bitnami/nginxstack/mysql/bin/mysqld_safe --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock  --datadir=/home/bitnami/nginxstack/mysql/data --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log  --pid-file=$MYSQL_PIDFILE --lower-case-table-names=1 "

[...]
~~~

And now just add the `--chroot` option and you're done:

~~~ shell
#!/bin/sh

MYSQL_PIDFILE=/home/bitnami/nginxstack/mysql/data/mysqld.pid

MYSQL_START="/home/bitnami/nginxstack/mysql/bin/mysqld_safe --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock  --datadir=/home/bitnami/nginxstack/mysql/data --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log  --pid-file=$MYSQL_PIDFILE --lower-case-table-names=1 --chroot=$JAIL"

[...]
~~~



## Check setup

Now that we have modified the scripts let's have a dry run.

### nginx

~~~ shell
root:/home/bitnami/nginxstack-chroot# ./home/bitnami/nginxstack/nginx/scripts/ctl.sh status
Nginx not running
root:/home/bitnami/nginxstack-chroot# ./home/bitnami/nginxstack/nginx/scripts/ctl.sh start 
./home/bitnami/nginxstack/nginx/scripts/ctl.sh : Nginx started
root:/home/bitnami/nginxstack-chroot# ./home/bitnami/nginxstack/nginx/scripts/ctl.sh status
Nginx already running
root@nusec:/home/bitnami/nginxstack-chroot# netstat -ptan | grep 8080
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      22706/          
root:/home/bitnami/nginxstack-chroot# ls -l /proc/22706/root
lrwxrwxrwx 1 root root 0 Feb  8 21:07 /proc/22706/root -> /home/bitnami/nginxstack-chroot
~~~

So there is a nginx instance (PID = `22706`) and this is running in a `chroot` (/home/bitnami/nginxstack-chroot). Alright!

### php-fpm

~~~ shell
root:/home/bitnami/nginxstack-chroot# ./home/bitnami/nginxstack/php/scripts/ctl.sh start
./home/bitnami/nginxstack/php/scripts/ctl.sh : php-fpm started
root:/home/bitnami/nginxstack-chroot# ps -ax | grep php-fpm
                                         1
15134 ?        Ss     0:06 php-fpm: master process (/home/bitnami/nginxstack/php/etc/php-fpm.conf)                        
26557 ?        Ss     0:00 php-fpm: master process (/home/bitnami/nginxstack/php/etc/php-fpm.conf)                                                         
26560 pts/0    S+     0:00 grep php-fpm
root:/home/bitnami/nginxstack-chroot# ls -l /proc/15134/root
lrwxrwxrwx 1 root root 0 Feb  8 21:07 /proc/15134/root -> /home/bitnami/nginxstack-chroot
~~~

### mysql

~~~ .shell
root:/home/bitnami/nginxstack-chroot/home/bitnami/nginxstack# ./mysql/scripts/ctl.sh start
160209 16:36:46 mysqld_safe Logging to '/home/bitnami/nginxstack/mysql/data/mysqld.log'.
160209 16:36:47 mysqld_safe Starting mysqld.bin daemon with databases from /home/bitnami/nginxstack/mysql/data
./mysql/scripts/ctl.sh : mysql  started at port 3307


root:/home/bitnami/nginxstack-chroot/home/bitnami/nginxstack# ps -ax | grep mysql
13975 pts/3    S      0:00 /bin/sh /home/bitnami/nginxstack-chroot//home/bitnami/nginxstack/mysql/bin/mysqld_safe --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock --datadir=/home/bitnami/nginxstack/mysql/data --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log --pid-file=/home/bitnami/nginxstack/mysql/data/mysqld.pid --lower-case-table-names=1
14236 pts/3    S      0:00 sh -c LD_LIBRARY_PATH=/home/bitnami/nginxstack/mysql/lib nohup /home/bitnami/nginxstack/mysql/bin/mysqld.bin --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --basedir=/home/bitnami/nginxstack/mysql --datadir=/home/bitnami/nginxstack/mysql/data --plugin-dir=/home/bitnami/nginxstack/mysql/lib/plugin --user=mysql  --lower-case-table-names=1 --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log --pid-file=/home/bitnami/nginxstack/mysql/data/mysqld.pid --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock --port=3307
14237 pts/3    Sl     0:00 /home/bitnami/nginxstack/mysql/bin/mysqld.bin --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --basedir=/home/bitnami/nginxstack/mysql --datadir=/home/bitnami/nginxstack/mysql/data --plugin-dir=/home/bitnami/nginxstack/mysql/lib/plugin --user=mysql --lower-case-table-names=1 --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log --pid-file=/home/bitnami/nginxstack/mysql/data/mysqld.pid --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock --port=3307
14258 pts/3    S+     0:00 grep mysql

root:/home/bitnami/nginxstack-chroot/home/bitnami/nginxstack# ls -l /proc/14237/root
lrwxrwxrwx 1 root root 0 Feb  9 16:37 /proc/14237/root -> /home/bitnami/nginxstack-chroot
~~~

## Run the nginx stack

Now that everything seems to work fine, let's start all services using Bitnamis `ctlscript.sh`:

~~~ shell
root:/home/bitnami/nginxstack-chroot/home/bitnami/nginxstack# ./ctlscript.sh start
160209 12:59:50 mysqld_safe Logging to '/home/bitnami/nginxstack/mysql/data/mysqld.log'.
160209 12:59:50 mysqld_safe Starting mysqld.bin daemon with databases from /home/bitnami/nginxstack/mysql/data
/home/bitnami/nginxstack/mysql/scripts/ctl.sh : mysql  started at port 3307
/home/bitnami/nginxstack/php/scripts/ctl.sh : php-fpm started
/home/bitnami/nginxstack/nginx/scripts/ctl.sh : Nginx started
~~~

Great! Now let's stop the services:

~~~ shell
/home/bitnami/nginxstack/nginx/scripts/ctl.sh : Nginx stopped
/home/bitnami/nginxstack/php/scripts/ctl.sh : php-fpm stopped
160209 13:01:21 mysqld_safe mysqld from pid file /home/bitnami/nginxstack/mysql/data/mysqld.pid ended
/home/bitnami/nginxstack/mysql/scripts/ctl.sh : mysql stopped
~~~


### Check UID and GID

To make sure that the previously launched services are dropping privileges (as they are supposed to!) let's have a look at the running processes:

~~~ shell
$ ps -eo uid,gid,args | grep nginx
1337  1337 nginx: worker process                              
1337  1337 nginx: worker process                              
1337  1337 nginx: worker process                              
1337  1337 nginx: worker process                              
   0     0 nginx: master process /home/bitnami/nginxstack/nginx/sbin/.nginx.bin -p /home/bitnami/nginxstack/nginx/
1337  1337 nginx: worker process
~~~

You can see that there is a **master** process running with `0:0` (UID:GID) but the **worker processes** are running as `1337:1337` (daemon:daemon). Let's verify that for `php` and `mysql`:

~~~ .shell
$ ps -eo uid,gid,args | grep php
1337  1337 php-fpm: pool www                                                     
1337  1337 php-fpm: pool www                                                     
1337  1337 php-fpm: pool www                                                     
1337  1337 php-fpm: pool www 
   0     0 php-fpm: master process (/home/bitnami/nginxstack/php/etc/php-fpm.conf)                        
   
$ ps -eo uid,gid,args | grep mysql
 0     0 /bin/sh /home/bitnami/nginxstack-chroot//home/bitnami/nginxstack/mysql/bin/mysqld_safe --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock --datadir=/home/bitnami/nginxstack/mysql/data --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log --pid-file=/home/bitnami/nginxstack/mysql/data/mysqld.pid --lower-case-table-names=1
 0     0 sh -c LD_LIBRARY_PATH=/home/bitnami/nginxstack/mysql/lib\:/home/bitnami/nginxstack/sqlite/lib\:/home/bitnami/nginxstack/nginx/lib\:/home/bitnami/nginxstack/mysql/lib\:/home/bitnami/nginxstack/common/lib\: nohup /home/bitnami/nginxstack/mysql/bin/mysqld.bin --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --basedir=/home/bitnami/nginxstack/mysql --datadir=/home/bitnami/nginxstack/mysql/data --plugin-dir=/home/bitnami/nginxstack/mysql/lib/plugin --user=mysql  --lower-case-table-names=1 --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log --pid-file=/home/bitnami/nginxstack/mysql/data/mysqld.pid --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock --port=3307
100   101 /home/bitnami/nginxstack/mysql/bin/mysqld.bin --defaults-file=/home/bitnami/nginxstack/mysql/my.cnf --basedir=/home/bitnami/nginxstack/mysql --datadir=/home/bitnami/nginxstack/mysql/data --plugin-dir=/home/bitnami/nginxstack/mysql/lib/plugin --user=mysql --lower-case-table-names=1 --log-error=/home/bitnami/nginxstack/mysql/data/mysqld.log --pid-file=/home/bitnami/nginxstack/mysql/data/mysqld.pid --socket=/home/bitnami/nginxstack/mysql/tmp/mysql.sock --port=3307
~~~


## Extras

In this section I'll try to sum up some "best practices" I've experienced while setting up the (web) application inside the bitnami nginxstack chrooted environment.

### Check UID/GID

Inside the chroot `/etc/passwd` should have:

~~~ shell
aemon:x:1:1:daemon:/:/bin/false
mysql:x:100:101:MySQL Server,,,:/nonexistent:/bin/false
nobody:x:99:99:nobody:/:/bin/false
~~~

When setting the user/group ownerships for your directories, make sure that you're using the same UID/GID for that specific user/group also outside the chroot. What I mean is: If you set the ownerships like this:

~~~ shell
$ chown -R daemon.daemon php nginx apps
$ chown -R mysql.mysql mysql
~~~

Make sure that the UID/GID for user/group `daemon` or `mysql` are the same as in `/etc/passwd` (outside the chroot). In my case:

~~~ shell
$ cat /etc/passwd  | grep -e mysql -e daemon
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
mysql:x:100:101:MySQL Server,,,:/nonexistent:/bin/false
~~~

If you don't pay attention to this, you might be setting ownserships and permissions to the right user/group, but the UID/GID might differ between the chroot and the operating system. 

###  Applying LD_LIBRARY_PATH globally

If some of your web applications are using some extra binaries (`/usr/bin/git` for example), you may have to install the dependent libraries for this binary like we did before using `n2chroot`. If `git` has some dependencies, that are already installed inside the chroot (let's say inside `/home/bitnami/nginxstack/common/lib`) you can set the `LD_LIBRARY_PATH` variable globally. Inside the chroot, you'll have `/etc/ld.so.conf`:

~~~ shell
$ cat /etc/ld.so.conf
include /etc/ld.so.conf.d/*.conf
~~~

Now create an extra directory and a new conf file:

~~~ shell
$ mkdir /etc/ld.so.conf.d
$ cat /etc/ld.so.conf.d/local.conf
/home/bitnami/nginxstack/common/lib/
~~~

Now you'll have to re-create the LD cache by running `ldconfig` inside the chroot:

~~~ shell
$ cp /sbin/ldconfig $JAIL/sbin/
$ cp /sbin/ldconfig.real $JAIL/sbin/
$ chroot $JAIL /bin/sh
# /sbin/ldconfig
...
~~~ 

Now you should be running `git` without any missing dependencies inside your chroot.

### Run own php-fpm pool for each vhost

In some previous thoughts I've mentioned that you may want to put `php-fpm` in "jail" into some more specific than `/home/bitnami/nginxstack`. For example if you have a vhost at `bla.example.com` and the according conf/htdocs file structure is located at `/home/bitnami/nginxstack/apps/bla.example.com` you can `chroot` php-fpm into the same location. 

> Btw: The [bitnami documentation](https://wiki.bitnami.com/Infrastructure_Stacks/Bitnami_Nginx_Stack#How_can_I_create_a_custom_PHP_application.3f) regarding custom PHP applications  is awesome! 

Let's say `bla.example.com` consists of following directory structure:

~~~ shell
$ tree /home/bitnami/nginxstack/apps/bla.example.com
bla.example.com
|-- conf
|   |-- nginx-app.conf
|   |-- nginx-prefix.conf
|   `-- nginx-vhosts.conf
`-- htdocs
    |-- index.php
~~~

The *app* configuration will look like this:

~~~ shell
$ cat /home/bitnami/nginxstack/apps/bla.example.com/conf/nginx-app.conf
    index index.php index.html index.htm;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_read_timeout 300;
        fastcgi_pass unix:/home/bitnami/nginxstack/php/var/run/www-bla.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        add_header Vary "Accept-Encoding";
        expires max;
        tcp_nodelay off;
        tcp_nopush on;
    }

~~~

The `fastcgi_param SCRIPT_FILENAME $fastcgi_script_name;` is the most important one. Read [here](http://serverfault.com/questions/463674/a-complicated-nginx-php-fpm-chroot-setup) and [here](http://serverfault.com/questions/356081/chrooting-php-fpm-with-nginx).
 
Now let's create the `php-fpm` pool for this specific vhost. Usually each pool conf has be created under `./php/etc/fpm.d/*.conf`. Make sure you have created this directory before and you have following in your `./php/etc/php-fpm.conf`:

~~~ shell
[...]
include=etc/fpm.d/*.conf
[...]
~~~

Now create a new file (`./php/etc/fpm.d/www-bla.conf`) and add:

~~~ shell
;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ; 
;;;;;;;;;;;;;;;;;;;;
[www-bla]
include=/home/bitnami/nginxstack/php/etc/environment.conf
include=/home/bitnami/nginxstack/php/etc/common.conf
user=daemon
group=daemon
listen=/home/bitnami/nginxstack/php/var/run/www-bla.sock
pm=dynamic
pm.max_children=5
pm.start_servers=2
pm.min_spare_servers=1
pm.max_spare_servers=3
chroot = /home/bitnami/nginxstack-chroot/apps/bla.example.com/htdocs
chdir = /
~~~

You can of course add some more options. But this is the minimum one should have. Now you'll have to **restart** the `php-fpm` daemon and you should see some **workers** designated for your specific vhost:

~~~ shell
$ ./ctlscript.sh restart php-fpm
$ ps -ax | grep php-fpm
2735 ?        Ss     0:01 php-fpm: master process (/home/bitnami/nginxstack/php/etc/php-fpm.conf)                                  
 2736 ?        S      0:00 php-fpm: pool www-bla                                                               
 2737 ?        S      0:00 php-fpm: pool www-bla
~~~

Let's check the `root` directory of the workers:

~~~ shell
$ ls -l /proc/2736/root
lrwxrwxrwx 1 daemon daemon 0 Feb 12 11:23 /proc/2736/root -> /home/bitnami/nginxstack-chroot/home/bitnami/nginxstack/apps/bla.example.com/htdocs
~~~

Voila!

## Conclusion

The Bitnami nginx stack is a really easy-to-configure bundle one can either use in a dev or productive environment. Applying additional security measurements to it like `chroot` will help you to mitigate the impact of a potential attack. Again: **chroot != security**. Don't blindly rely on `chroot` and make sure you deeply understand how this technology works and what its potential risks could damage your business. 
