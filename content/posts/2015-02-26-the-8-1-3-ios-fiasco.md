+++
title = "The iOS 8.1.3 fiasco"
author = "Victor Dorneanu"
date = "2015-02-26"
tags = ["mobile", "ios", "apple", "misc", "update"]
category = "blog"
+++

From time to time we all seem to ignore the "voice of reason" and tend to 
unconsidered actions. This will be a short summary of what could go wrong 
when one is forced to quick reactions which will result in chaos.

All started with an [iPad Air](http://en.wikipedia.org/wiki/IPad_Air). I have
jailbroken the device from the very first touch. That time **iOS 7.x** was installed
and a [jailbreak](http://www.redmondpie.com/download-evasi0n-ios-7-7.0.4-jailbreak-for-iphone-5s-5c-5-ipad-ipod-touch-windows-mac/)
was available for that specific version (**iOS 7.0.4**). After months of testing and
without taking notice of the current iOS development, I've found out that the installed
version was indeed out of date. At this time **iOS 8.1.3** is the latest stable iOS version.
My first thought was to update to **iOS 7.1.2** without loosing my [jailbreak](http://www.evad3rs.net/2014/05/jailbreak-712-one-click-1-min.html).
So I've searched on [ipswdownloader.com/](http://www.ipswdownloader.com/) for restore files for my device and downloaded them. 
I've soonly failed at restoring the image and downloaded another restore file (iOS 8.1.2). 

At that moment I wasn't aware of this [list](https://ipsw.me/all#iPad41) which contains a list 
of all signable firmware versions. So I tried again and again. Doing that I was very "amused" 
(not at all actually) to get intouch with [iTunes](https://www.apple.com/itunes/) 
which is very "verbose" when something fails. So I got very "precise" error codes like 
*3004*, *3194*, *2005*, *17* and so on. C'mon Apple, is that the way how error logging should work?
At least an error message could have helped. But one is always wiser afterwards. There is indeed
a [list](http://support.apple.com/en-us/TS3694) containing details about update and restore errors. So I had:

* **network** problems
    * Adapting the *hosts* file really helped in this case (have a look at this [tutorial](http://www.howtoisolve.com/how-to-fix-error-3194-in-itunes-step-by-step-solved/))
* **USB** connections problems

After solving those problems, I've tried again to restore the firmware and failed hard. I repeat: I'm not 
an Apple expert nor an user. I use Apple products because I **have** to (due to my pentest activities at work). 
So I didn't have a clue about this whole Apple firmware signing. I admit that somewhere I've read that one should
not update to **iOS 8.1.3** yet since there are no jailbreaks yet. Ok, but what about **downgrading** the firmware?
"That should work", I thought. **WRONG**!  I should have read the sources more precisely and pay more attention 
to the previously mentioned [list](https://ipsw.me/all#iPad41). And I should point out with some more emphasis:

** Once you have upgraded to 8.1.3 you can NOT downgrade to a lower version! **

Well that's the part where I have been thrown into cold water (or should I say: in the **Apple** universe?) and got stuck with
**8.1.3**. The jailbreak was gone and there was no way to go back to **7.1.2** or **8.1.2**. **But then I've found this 
[page](http://phonerebel.com/ios-8-2-jailbreak-download-page/)**. And this indeed renewed my hope of getting my jailbreak back.

And this where the 2nd part of this crazy journey beginns. **iOS 8.2 Beta 1/2** is no longer available from the [Apples developer center](https://developer.apple.com/programs/ios/). So I have searched for some mirrors and found this [site](miroir1.trackr.fr/miroirs.php?file=http://miroir.trackr.fr/iOS%208.2b2/iPad4,2_8.2_12D445d_Restore.ipsw). The firmware is about **2Gb** and the download seemed
to last for days. So I've decided to find another approach and found [ibetacloud.com](http://ibetacloud.com/#downloads) which 
had a much better DL rate. I have finally downloaded the beta image and was ready to try it again using iTunes. After another 
cryptical error codes, I was finally able to **update** from 8.1.2 to **8.2 beta**! Hurray! But unfortunately this is not the end.

I have downloaded the [TaiG Jailbreak for iOS 8.2](http://www.evasi0njailbreak.com/download-evasi0n/taigios82.html) and was
happy to see the finishing line ahead. **It didn't work!** Don't ask my why since the tool was full of Chinese signs. The only think 
I could decrypt was a link which didn't help me at all. Somewhere I've read again that the problem could maybe iTunes itself. They
said, the **12.0.1** version has to be installed which I've found [here](https://ipsw.me/iTunes). Again another try with *TaiG 1.3* and voila: **The iPad got jailbroken!**

So about the leasons learned?

* Read, read and read more precisely! (note to myself)
* Apple's policy on updating/downgrading to another versions su... aehmm..is very strange
* iTunes should get a more comprehensive list of error codes
* Thanks to all brilliant jailbreakers out there!

