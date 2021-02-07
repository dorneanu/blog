+++
title = "Re-Root Nexus 10 4.x"
author = "Victor Dorneanu"
date = "2014-12-02"
tags = ["note", "android"]
category = "notes"
+++

I wrote this since I always forget the 2 essential steps in order to regain **root** on a Nexus 10 device which has been updated over-the-air. Basically you'll have to flash a new **recovery** image:

~~~
# ~/android-sdk/platform-tools/fastboot flash recovery recovery-clockwork-touch-6.0.4.3-manta.img
...
~~~

Before booting into *recovery* make sure you'll push the latest `SuperSU` zip package to your device:

~~~
# adb push UPDATE-SuperSU-v1.51.zip /mnt/sdcard
...
~~~

Boot into *recovery*:

~~~
# adb reboot recovery
...
~~~

In CWRM install the previously pushed zip file and you're done.

