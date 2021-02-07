+++
title = "HowTo: Full-Encrypt data using Gentoo,Luks and initramfs"
author = "Victor"
date = "2011-03-07"
tags = ["howto", "security", "crypto", "gentoo", "luks", "admin"]
category = "blog"
+++

Since last post many things have changed. No more NetBSD on my laptop (this has to do with several things, I'll write about in a future post): I had to fall in love with Gentoo! I'll try to give you some quick overview related to this posts title: Encryption under Gentoo using Luks.

There are serveral (good!) tutorials out there. Among these I've used:

<table style="width: 100%;" border="1" cellspacing="1" cellpadding="1">
  <tr>
    <td>
      <a href="http://en.gentoo-wiki.com/wiki/DM-Crypt_with_LUKS">http://en.gentoo-wiki.com/wiki/DM-Crypt_with_LUKS</a>
    </td>
    
    <td>
      There you'll get a lot of information related to the topic. I've basically followed the same steps as described in the HowTo. However I didn't get any functionable system at all. Especially the initramfs part seems to be buggy. Therefore: Follow the steps ín the article <strong>except</strong> the initramfs part!
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="http://de.gentoo-wiki.com/wiki/DM-Crypt">http://de.gentoo-wiki.com/wiki/DM-Crypt</a> <strong>(german)</strong>
    </td>
    
    <td>
      Really good explanations. If you want some technical background to this whole thing, this is the place to be.
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="http://djamc.ath.cx/2008/01/20/howto-gentoo-vollverschlusselung-mit-cryptsetup-und-initramfs-bei-der-installation/">http://djamc.ath.cx/2008/01/20/howto-gentoo-vollverschlusselung-mit-cryptsetup-und-initramfs-bei-der-installation/</a> <strong>(german)</strong>
    </td>
    
    <td>
      Another nice howto I've found.
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="http://en.gentoo-wiki.com/wiki/Initramfs">http://en.gentoo-wiki.com/wiki/Initramfs</a>
    </td>
    
    <td>
      As already mentioned above, you'll get into troubles if you don't have a working initramfs. Follow this link to get detailed information how to create your own - as I did! - initramfs and how to adapt it to your needs.
    </td>
  </tr>
</table>

There is no need for additional explanations! Just follow the instructions in the tutorial and you're done.


## My initramfs

Here is my initramfs structure I'm using:

~~~.shell
$ tree
.
â”œâ”€â”€ bin
â”‚   â”œâ”€â”€ busybox
â”‚   â”œâ”€â”€ gpg
â”‚   â””â”€â”€ gpg-error
â”œâ”€â”€ dev
â”œâ”€â”€ etc
â”œâ”€â”€ init
â”œâ”€â”€ lib
â”‚   â””â”€â”€ modules
â”œâ”€â”€ mnt
â”‚   â””â”€â”€ root
â”œâ”€â”€ new-root
â”œâ”€â”€ proc
â”œâ”€â”€ README
â”œâ”€â”€ root
â”‚   â””â”€â”€ keys
â”œâ”€â”€ sbin
â”‚   â”œâ”€â”€ cryptsetup
â”‚   â””â”€â”€ mdev
â”œâ”€â”€ sys
â””â”€â”€ usr
    â””â”€â”€ bin

15 directories, 7 files
~~~

Make sure all **binaries** are **statically** linked. And this is my **init script**:

~~~.shell
$ cat init 
#!/bin/busybox sh

# Some useful functions
rescue_shell() {
    echo "Something went wrong. Dropping you to a shell."
    busybox --install -s
    exec /bin/busybox sh
}

# GPG workaround
cp -a /dev/console /dev/tty

# Mount the /proc and /sys filesystems.
mount -t proc none /proc
mount -t sysfs none /sys

busybox --install -s
mdev -s 
echo /bin/mdev > /proc/sys/kernel/hotplug

# Decrypt root
while [ ! -e /root/keys/sda1_key ] ; do
   sleep 2
   echo "> Decrypt root ..."
   gpg -o /root/keys/sda1_key -d /root/keys/sda1_key.gpg 2> /dev/null
done

# Unlock partition
cryptsetup -d /root/keys/sda1_key luksOpen /dev/sda1 root

# Mount new root 
mount /dev/mapper/root /new-root

# Create swap device
cryptsetup -c twofish -h sha256 -d /dev/urandom create swap /dev/sda6
mkswap /dev/mapper/swap

# Unmount old root
umount -l /proc
umount -l /sys

# Start new system
exec switch_root /new-root /sbin/init || rescue_shell
~~~

Don't forget to copy your **keys** to */root/keys/ *and rename them properly. Afterwards all you have to do is to create the initramfs file:

~~~.shell
$ cd /usr/src/initramfs
$ find . -print0 | cpio --null -ov --format=newc | gzip -9 > /boot/initramfs.cpio.gz
~~~

That's all!
