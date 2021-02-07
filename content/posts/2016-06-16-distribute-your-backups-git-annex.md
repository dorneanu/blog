+++
title = "Distribute your backups using git-annex"
author = "Victor Dorneanu"
date = "2016-06-16"
tags = ["networking", "backup", "git"]
category = "blog"
+++

Backuping a whole bunch of photos and videos might be a difficult task. Taking care of the **consistency** of your backups is even more complicated task. Besides that you don't want to have your backups at a **single place**, thus mitigating the impact of a **single point of data loss**. 

I've been using `git-annex` for some years but not like a *pro* user, rather than "it just works". Meanwhile I've heard of `ownCloud` and I've liked it because one can access its data via *web*, *mobile client* or whatever. In connection with a **VPN** (I prefer [openvpn](http://blog.dornea.nu/2015/11/17/openvpn-for-paranoids)) solution you can have a **secure** way of remotely accessing your data from everywhere. 

Well this post is where the link between `git-annex` and `ownCloud` should be emphasized: Use ownCloud as your "frontend" tool for accessing the data while letting git-annex do the "backend" (aka backup) job. While this might sound like a pretty easy task, it does have some peculiarities to be taken into consideration.

# Backup setup

{% blockdiag
    blockdiag {
      R [label="Raspberry Pi (central repo)", color="lightblue", width=192];
      S [label="External Server (git + data)", width=192];
      C [label="Cloud"];
      L [label="Laptop"];
      M [label="Mobile Clients"];
      G [label="GitHub (only git)", width=192];

      L -> R [label="plain"];
      M -> R ; 
      R -> S [label="enc"];
      R -> G ; 
      S -> C [label="enc"];
    }   
%}                                                                                                                                                   

There is one **centralized** repo on my raspberry pi where my HDD is attached to. Usually I *push* stuff to the HDD using `rsync` from my laptop or `ownCloud` using my mobile clients. Afterwards the **encrypted** repo **and** the data itself is being pushed to some **external server**. Data is being encrypted using my private GPG key. From the server I could then replicate the repo+data stuff to some **cloud** provider like *AWS*, *DropBox* or whatever. 

Additionally one could push the git repo to GitHub in an encrypted form - without the data itself. It will then only contain the git information (symlinks) but no data (annexed data). 

## Using ownCloud with git-annex

{% blockdiag
    blockdiag {
     C [label="ownCloud client", width=192];
     S [label="Server"];
     Cloud [label="Cloud"];
     group {
       label = "frontend";
       O [label="ownCloud"];
     }
     group {
       label = "backend";
       G [label="git-annex"];
     }
     C -> O [folded];
     G -> S;
     S -> Cloud;
    } 
%}

`ownCloud` will act as a **front-end** and can be used by any ownCloud client. The data itself is then managed by `git-annex` which basically acts as a `back-end`.  One can access the data using ownCloud but you there are some restrictions:

* already annexed data can't be deleted
* you can add files/folders and delete them only if these weren't added to the git-annex repo yet

That means: Newly added data (but not committed to the repo) can be deleted by the client which added the data. In this case old data can't be deleted. You'll have to work with git-annex to do that.  

## Encryption

One the important constraints before pushing my backups into the cloud was **security**. In order to be able to encrypt my stuff **before** pushing into the cloud, I had to

* generate a GPG key
* create a special remote (see below) which offers encryption

### GPG

Generating a GPG key was the easiest step. Afterwards I had to make sure that my **keychain** was available `git-annex` for a specific period of time. Here are my configuration files:

```
$ cat ~/.gnupg/gpg.conf | tail -n 3

use-agent
pinentry-mode loopback

```

and then the GPG agent configuration:

```
$ cat ~/.gnupg/gpg-agent.conf

pinentry-program /usr/bin/pinentry 
default-cache-ttl 180000
max-cache-ttl 864000
allow-loopback-pinentry
```

### Keychain

Then I've found [keychain](http://www.funtoo.org/Keychain) which helps you manage your SSH and GPG keys in a secure manner. Adding this to your bashrc/zshrc/whatever

```
$ eval `keychain --inherit any --eval --agents ssh,gpg id_rsa_backup xxx`

* keychain 2.8.2 ~ http://www.funtoo.org
 * Inheriting ssh-agent (7268)
 * Inheriting gpg-agent (3528)
 * Known ssh key: /home/cyneox/.ssh/id_rsa_backup

 * Known gpg key: xxxx

```

will **cache** your GPG and SSH keys to a specific time of period. 

# git-annex reference
## Create git repo

```
$ git init
```

## Create git annex repo

```
$ git-annex init <name>
```

# Add remotes

## Create bare git repo on the server

```
$ git init --bare oc-encrypted 
```

## Add special remote  (ssh+rsync)

```
$ git-annex initremote oc-encrypted type=gcrypt gitrepo=ssh://backup.ext/home/backup/oc-encrypted keyid=xxxx
```

# Synchronize data

## Sync only git repository to ssh remote

```
$ git-annex sync oc-encrypted
```

## Sync git repo + content to ssh remote

```
$ git-annex sync --content oc-encrypted
```

If you have a look at the repo `oc-encrypted` on the external server, you'll see only encrypted stuff:

```.shell
% tree | head -n 20 
.
|-- HEAD
|-- annex
|   |-- keys.lck
|   |-- objects
|   |   |-- 000
|   |   |   |-- 32a
|   |   |   |   `-- GPGHMACSHA1--0222fb5a96702da2e0e0d763f3893d0a97897d32
|   |   |   |       `-- GPGHMACSHA1--0222fb5a96702da2e0e0d763f3893d0a97897d32
|   |   |   |-- d88
|   |   |   |   `-- GPGHMACSHA1--55d8e2ea7626a3958b0182192e7cf34c8be09fd5
|   |   |   |       `-- GPGHMACSHA1--55d8e2ea7626a3958b0182192e7cf34c8be09fd5
|   |   |   `-- db9
|   |   |       `-- GPGHMACSHA1--2b2a121170d00fdb06a04d8df80b6135c4c51d7e
|   |   |           `-- GPGHMACSHA1--2b2a121170d00fdb06a04d8df80b6135c4c51d7e
|   |   |-- 001
|   |   |   |-- 380
|   |   |   |   `-- GPGHMACSHA1--6dbdddddde415496c429c9788428fffb358e55fa
|   |   |   |       `-- GPGHMACSHA1--6dbdddddde415496c429c9788428fffb358e55fa
|   |   |   |-- 590

% file annex/objects/000/32a/GPGHMACSHA1--0222fb5a96702da2e0e0d763f3893d0a97897d32/GPGHMACSHA1--0222fb5a96702da2e0e0d763f3893d0a97897d32 
annex/objects/000/32a/GPGHMACSHA1--0222fb5a96702da2e0e0d763f3893d0a97897d32/GPGHMACSHA1--0222fb5a96702da2e0e0d763f3893d0a97897d32: GPG symmetrically encrypted data (AES cipher)

```

# Troubleshooting

## Find broken symlinks

```
$ find . -xtype l
```

or

```
$ find . -type l -! -exec test -e {} \; -print
```

# Garbage collection 

## Delete unused (annexed) data

```
$ git-annex unused 
unused . (checking for unused data...) (checking master...) 
  Some annexed data is no longer used by any files:
    NUMBER  KEY
    1       SHA256E-s1048577--dd8a6196a5a42dc394ed277191024ba51149167f2afd577557e29d4495ce107b.this-is-a-test-key
    2       SHA256E-s11--1fd9176b4dc46b02de28fc850c160d9d0bf71ebd3cddac52b83b288d73645d89
    3       SHA256E-s1048575--b877cbd76972eabf53837edf24af92f3567ff9dc6cc42c420f5ebbcb911d0ad5.this-is-a-test-key
    4       SHA256E-s2097152--be41ea1dc3c13e45848717d213bf64d11171f221b86be4b91c56baa17193ee6e.this-is-a-test-key
  (To see where data was previously used, try: git log --stat -S'KEY')
  
  To remove unwanted data: git-annex dropunused NUMBER
  

  Some partially transferred data exists in temporary files:
    NUMBER  KEY
    5       GPGHMACSHA1--5b029d5db5dde1c7e12e347580e732c00de22f6e
  
  To remove unwanted data: git-annex dropunused NUMBER
  
ok
```

Now you can **drop** the unused data:

```
$ git-annex dropunused 1-4
```

## Delete unused remote

First you'll have to mark the repo as **dead**:

```
$ git-annex dead <remote name>
```

Then you'll have to **forget** the **dead** repo:

```
$ git-annex forget --force --drop-dead
```

And finally you can **remove** the remote using `git`:

```
$ git remote remove <repo name>
```

