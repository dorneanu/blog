+++
title = "Pidgin stores account data in plaintext!"
author = "Victor"
date = "2009-11-23"
tags = ["wtf", "security"]
category = "blog"
+++

I was just looking for some configuration files in Pidgins working directory `~/.purple/` and found this:

~~~.shell
...
-rw------- 1 victor users  22939 Nov 23 19:34 accounts.xml
...
~~~

Well I wouldn't have payed to much attention at that file, if it had not contained this:

~~~.shell
$ head accounts.xml 
<?xml version='1.0' encoding='UTF-8' ?>

<account version='1.0'>
        <account>
                <protocol>prpl-msn</protocol>
                <name>******@hotmail.de</name>
                <password>**</password>
                <alias>v****</alias>
                <statuses>
                         
...
~~~

Plaintext passwords? I couldn't believe it. So I searched on Pidgins Wiki site for some entries justifing this (in)secure measurement. And indeed I found one: <http://developer.pidgin.im/wiki/PlainTextPasswords>. However... Could somebody tell me what they mean by this one: 

>"We're 100% fine with people having false perceptions of how insecurely Pidgin handles your passwords. We are not, however, fine with sacrificing actual security for false security. We're 100% fine with people having false perceptions of how insecurely. Pidgin handles your passwords. We are not, however, fine with sacrificing actual security for false security."
