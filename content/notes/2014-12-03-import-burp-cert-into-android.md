+++
title = "Import Burp cert into Android"
author = "Victor Dorneanu"
date = "2014-12-03"
tags = ["note", "burp", "android"]
category = "notes"
+++

As already mentioned in previous posts, in order to install Burps CA certificate, just go to the IP address Burp is listening on, followed by */cert*, e.g. `http://127.0.0.1:8080/cert`. There you can download the cert and push it to your Android device. Usually you'll get a *binary* certificate in *DER* format: *cacert.crt*. 

Android won't recognize this file as a cert. You'll have to **rename** it to: *cacert.der* and push it to your device:

~~~
# mv cacert.crt cacert.der
# adb push cacert.der /mnt/sdcard
~~~

Afterwards you should be able to import your cert into your Android device.
