+++
title = "HowTo: RsynCrypto - The backup jewel"
author = "Victor"
date = "2009-06-25"
tags = ["howto", "networking", "crypto", "admin", "backup", "tools"]
category = "blog"
+++

Nowadays it is essential to backup your data and keep it safe in case of a data loss event. The most common way to backup (private) data is to use a remote server where you can upload your data. Certainly you want to keep it safe and **private** So how do you want to guarantee the privacy of the files stored? Upload it to the server and encrypt it afterwards?! Somehow you want to automate this backup process so you don't have to do nothing than running the backup script. Suppose you have a huge amount of data (GB / TB) you'll have to backup every day. Then you'll have to upload the data completely to the server and do the encryption stuff. So your next question in mind should be: How to save bandwidth usage and keep it to a minimum?

Apparently you'll have to encrypt your data first and then commit the in-file changes to the server. This works similar to the CVS/SVN versioning systems. So here are the steps:

1.  Encrypt data using rsyncrypto
2.  Transfer data (changes) to server using rsync

Quite simple, isn't it? Let's start by configuring and installing the required tools. (For the next steps I'll be using NetBSD 5.0. But most Unix systems include rsync and rsyncrypto in their packaging systems.)  

## Installing required tools

~~~.shell
cd /usr/pkgsrc/net/rsync
make install clean CLEANDEPENDS=1
~~~

If you don't find `rsync` in your packages list, then you'll have to download it and from [here][1]. I couldn't find `rsyncrypto` in NetBSDs package tree so I've downloaded it from [here][2]. Be carefull when configuring the package on NetBSD:

~~~.shell
$ LDFLAGS=-L/usr/pkg/lib CPPFLAGS=-I/usr/pkg/include ./configure
~~~

Now both tools shoud work and execute properly.

## Generate backup keys

Therefore we'll be using OpenSSL. We'll generate a backup key and a certificate used for encryption. Remeber: Keep these files safe and don't lose them!

~~~.shell
openssl req -nodes -newkey rsa:2046 -x509 
    -keyout /backup/openssl/backup.key -out /backup/openssl/backup.crt
~~~

Check out the man page for parameters explication.

## Encrypt data

Let us now encrypt our data.

~~~.shell
rsyncrypto -r --name-encrypt=/encrypted/backup/map /encrypted/ /tmp/enc /encrypted/backup/enc.keys /encrypted/keys/openssl/backup.crt
~~~

Quite simple, isn't it? Here is a quick explanation:

~~~.shell
Main syntax of rsyncrypto: 
rsyncrypto [options] src dst key master key
In our case:
"-r"          -- directory names are processed recursively
"--name-encrypt=translation_file"   --  Encrypt file names
"/encrypted"    -- Directory to be encrypted
"/tmp/enc"       -- Where to store encrypted data temporarily
"enc.keys"      --  Keys file or directory
"backup.crt"    -- Master key (public key certificate or private key)
~~~

Now all we have to do is to rsync the encrypted data to some remote server.

~~~.shell
rsync --progress --delete -ave /tmp/enc user@host:/dir/where/to/store/data
~~~


[1]: http://www.samba.org/rsync/
[2]: http://rsyncrypto.lingnu.com/index.php/Home_Page
