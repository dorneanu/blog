+++
title = "HowTo: Root your Kindle 3"
author = "Victor"
date = "2013-07-03"
tags = ["hacking", "howto", "kindle"]
category = "blog"
+++

As I'm using my Kindle 3 on daily basis I wanted to go behind the limits and check for some new features. As an entry point to the whole topic I highly recommend you [K3_Index][1]. This is what I did:

## Step 1: Jailbreak

Download the files from <http://www.mobileread.com/forums/showthread.php?t=88004>. In my case I've used **update\_jailbreak\_0.11.N\_k3w\_install.bin**. Copy this file to your Kindle, unplug it from the PC and run: `[HOME] -> [MENU] > Settings -> [MENU] > Update YourÂ  Kindle.`

## Step 2: Install launchpad

>"launchpad for Kindle is a small program supporting extended input capabilities. * * The main purpose of it is providing the ability to run any 3rd-party programs* * from within the original unmodified Kindle Framework software.* * It can be also used to organize custom keyboard shortcut operations and* * to simplify input of special symbols... (Source: <http://www.mobileread.com/forums/showthread.php?t=97636>)"

I've downloaded the package and copied **update\_launchpad\_0.0.1c\_k3w\_install.bin **to the device. Afterwards the same procedure: Unplug your Kindle and run `[HOME] -> [MENU] > Settings -> [MENU] > Update Your Kindle`

## Step 3: Install PDF reader

You could use this wonderful [unofficial guide][2]. You can choose between:

*   [kindlepdfreader][3] (download [here][4] the latest version)
*   [librerator][5] (a quite neat fork of kindlepdfreader)

As already described [here][6] follow these steps:

*   You need to jailbreak and install launchpad first
*   Create a folder `customupdates` on the exported Kindle drive, if not yet present
*   Copy a release ZIP file into the folder `customupdates`
*   Press Shift-Shift-I sequence on the Kindle for installing (if this is the first time you use launchpad: you only have 0.7 secs for the sequence!)
*   Press Shift-Shift-Space sequence on the Kindle to reload launchpad
*   done! now you can run the viewer via a **Shift-P-D** sequence.

The same applies to **librerator** too. Instead of Shift-P-D use **Shift-L-L**.


[<img alt="Calculator" src="http://static.dornea.nu/img/2013/0a569c30e50de6eb56f1527a4135eb17.gif" width="50%" height="800" />][7][<img alt="KUAL not working" src="http://static.dornea.nu/img/2013/5b32f0bf9df20c3454d6f49ef58649d8.gif" width="50%" height="800" />][8]

 [1]: http://wiki.mobileread.com/wiki/K3_Index
 [2]: http://www.mobileread.mobi/forums/showthread.php?t=190641
 [3]: https://github.com/koreader/kindlepdfviewer
 [4]: https://github.com/koreader/kindlepdfviewer/wiki/Download
 [5]: https://github.com/kai771/kindlepdfviewer/tree/librerator
 [6]: http://www.mobileread.com/forums/showthread.php?t=157047
