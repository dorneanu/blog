+++
title = "HowTo: Debug Android APKs with Eclipse and DDMS"
date = "2014-08-21"
tags = ["android", "eclipse", "java", "debug", "howto", "mobile", "fakebanker", "appsec"]
author = "Victor Dorneanu"
category = "blog"
+++

Simply out of necessity I've written this mini-tutorial how debug android APKs using Eclipse and [DDMS](http://developer.android.com/tools/debugging/ddms.html). 
After hours of wild googling these are the steps to make your APK debuggable under Eclipse. I'll be using the `FakeBanker` APK reverse-engineered in previous [articles](http://blog.dornea.nu/tag/android/).


## Revisions

* ***UPDATE 2014-12-09***: 

Before looking at the next steps, make sure you'll have a look at [ADUS](http://adus.dev.dornea.nu/). It will help you with the automation of several steps described in this post. Added some additional infos regarding the breakpoints.


## Dump the APK


First of all make sure you'll have the latest version of `apktool`. I've compiled it by myself:

~~~ shell

# git clone git://github.com/iBotPeaches/Apktool.git
oCloning into 'Apktool'...    
remote: Counting objects: 9605, done.
remote: Compressing objects: 100% (3622/3622), done.
remote: Total 9605 (delta 4556), reused 9494 (delta 4502)
Receiving objects: 100% (9605/9605), 34.27 MiB | 3.89 MiB/s, done.
Resolving deltas: 100% (4556/4556), done.
Checking connectivity... done.

# cd Apktool
# ./gradlew build fatJar
[o...]
~~~

Afterwards you'll get a new fresh `apktool` to use within the next steps:

~~~ shell
# find . -name "apktool-cli.jar"
./obrut.apktool/apktool-cli/build/libs/apktool-cli.jar

# cp ./brut.apktool/apktool-cli/build/libs/apktool-cli.jar /tmp
~~~

After having installed the right tool it's time to dump the APK contents:

~~~ shell
# java -jar /tmp/apktool-cli.jar d -d FakeBanker.apk -o source
I: Using Apktool 2.0.0-3d2e93-SNAPSHOT on FakeBanker.apk
I: Loading resource table...
I: Loading resource table...
I: Decoding AndroidManifest.xml with resources...
I: Loading resource table from file: /home/victor/apktool/framework/1.apk
I: Regular manifest package...
I: Decoding file-resources...
I: Decoding values */* XMLs...
I: Baksmaling classes.dex...
I: Copying assets and libs...
I: Copying unknown files...
I: Copying original files...
~~~

Afterwards I got following file structure:

~~~ shell
tree -L 2 source 
source
├── AndroidManifest.xml
├── apktool.yml
├── original
│   ├── AndroidManifest.xml
│   └── META-INF
├── res
│   ├── drawable-hdpi
│   ├── drawable-ldpi
│   ├── drawable-mdpi
│   ├── drawable-xhdpi
│   ├── layout
│   ├── menu
│   ├── raw
│   └── values
└── smali
    ├── android
    └── com

14 directories, 3 files
~~~

## Make APK debuggable

After dumping the APK now you'll have to mark your APK as debuggable. There are several ways in order to achieve that:

* manually 
* using apktool

If you want to do it manually open the `AndroidManifest.xml` file and search for the `application` tag. Then insert new attribute `android:debuggable='true'` like I did:

~~~ xml
...
<application android:theme="@style/AppTheme" android:label="@string/app_name" android:icon="@drawable/ic_launcher1" android:debuggable="true" android:allowBackup="false">
...
~~~

 
## Build new APP

Now you're ready to build you new debuggable APK using `apktool`:

~~~ shell
java -jar /tmp/apktool-cli.jar b -d source FakeBanker.Debug.apk
I: Using Apktool 2.0.0-3d2e93-SNAPSHOT on source
I: Checking whether sources has changed...
I: Smaling smali folder into classes.dex...
I: Checking whether resources has changed...
I: Building resources...
Warning: AndroidManifest.xml already defines debuggable (in http://schemas.android.com/apk/res/android); using existing value in manifest.
I: Building apk file...
~~~

A few explanations regarding the parameters:

* `b`
  + run apktool in **build** mode
* `-d`
  + make APK debuggable (this is the 2nd way I was previously talking about)

## Extract sources

I'll be using `jd-gui` to **undex** the dex files inside the newly created package. First let's unpack `FakeBanker.Debug.apk`:

~~~ shell
# unzip FakeBanker.Debug.apk -d unpacked
Archive:  FakeBanker.Debug.apk
 extracting: unpacked/res/drawable-hdpi/ic_launcher1.png  
 extracting: unpacked/res/drawable-hdpi/logo.png  
 extracting: unpacked/res/drawable-ldpi/ic_launcher1.png  
 extracting: unpacked/res/drawable-mdpi/ic_launcher1.png  
 extracting: unpacked/res/drawable-xhdpi/ic_launcher1.png  
  inflating: unpacked/res/layout/actup.xml  
  inflating: unpacked/res/layout/main.xml  
  inflating: unpacked/res/layout/main2.xml  
  inflating: unpacked/res/menu/main.xml  
 extracting: unpacked/res/raw/blfs.key  
  inflating: unpacked/res/raw/config.cfg  
  inflating: unpacked/AndroidManifest.xml  
  inflating: unpacked/classes.dex    
  inflating: unpacked/resources.arsc  
~~~

Let `dex2jar` do its job:

~~~ shell
# cd unpacked
# dex2jar classes.dex
dex2jar classes.dex -> classes-dex2jar.jar
~~~

Now open the jar file using `jd-gui` and save the sources as zip like I did:

{% img  http://dl.dornea.nu/img/2014/eclipse-ddms/jd-gui.png %}


## Sign the APK

In order to push your APK to the device you'll have to **sign** it. I'll therefor using a test [certificate](http://developer.android.com/tools/publishing/app-signing.html):

~~~ shell
# git clone https://github.com/appium/sign
Cloning into 'sign'...
remote: Counting objects: 49, done.
remote: Total 49 (delta 0), reused 0 (delta 0)
Unpacking objects: 100% (49/49), done.
Checking connectivity... done.
~~~

Now let's sign it:

~~~ shell
# java -jar sign/dist/signapk.jar sign/testkey.x509.pem sign/testkey.pk8 FakeBanker.Debug.apk FakeBanker.Debug.Signed.apk          
~~~

## Install the APK

Having signed the APK now you're ready to push it to your device and have some fun.

~~~ shell
# adb devices -l  
List of devices attached 
emulator-5554          device product:sdk model:sdk device:generic

# adb install FakeBanker.Debug.Signed.apk
1628 KB/s (219033 bytes in 0.131s)
    pkg: /data/local/tmp/FakeBanker.Debug.Signed.apk
Success
~~~

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/app_installed.png %}

## Add sources

We'll add the Java sources to the `source` directory structure:

~~~ shell
# mkdir source/src
# unzip classes-dex2jar.src.zip -d source/src 
Archive:  classes-dex2jar.src.zip
   creating: source/src/android/
   creating: source/src/android/support/
...
~~~ 

The new directory structure will be:

~~~ shell
# tree -L 2 source 
source
├── AndroidManifest.xml
├── apktool.yml
├── bin
│   ├── android
│   └── com
├── build
│   └── apk
├── dist
│   └── FakeBanker.apk
├── original
│   ├── AndroidManifest.xml
│   └── META-INF
├── res
│   ├── drawable-hdpi
│   ├── drawable-ldpi
│   ├── drawable-mdpi
│   ├── drawable-xhdpi
│   ├── layout
│   ├── menu
│   ├── raw
│   └── values
├── smali
│   ├── android
│   └── com
└── src
    ├── android
    └── com

23 directories, 4 files
~~~  

## Debug settings

I had to active the debug settings for my targeted app. Go to `Device Settings` -> `Select debug app`. Also make sure you have `Wait for debugger` activated. 
This will prevent your app starting before any debugger gets connected to it.

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/app_select_debug_app.png %}

## Setup Eclipse

First of all make sure you have the [ADT](http://developer.android.com/tools/sdk/eclipse-adt.html) along with the [Android SDK](http://developer.android.com/sdk/index.html) installed. Now let's move on:

#### Create new Java project

First create a new *Java* project and use `source` as the location of the project.

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_create_java_project.png %}


#### Add src folder to build path

Make sure the `src` folder is added as a source location to the build path.

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_project_src.png %}


#### Check project properties

You could also check the project properties by clicking on it and then `ALT+Enter`. You should have sth similar to:
 
{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_project_properties_build_path.png %}


## Set breakpoints

Having set up the Eclipse environment let's add some breakpoints. 

### UPDATE 2014-12-09

**Important note**: As stated [here](https://code.google.com/p/android-apktool/wiki/SmaliDebugging) you should pay attention **where** you set your breakpoint:

> You must select line with some instruction, you can't set breakpoint on lines starting with ".", ":" or "#". 

So be careful whet choosing your breakpoints otherwise you might ask yourself why your code doesn't get debugged.

### Debug onCreate

First search for **onCreate** in all files:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_search_on_create.png %}

Eclipse found several matches:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_found_oncreate.png %}

We'll now concentrate on `MainActivity.java` and set a breakpoint:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_set_breakpoint.png %}

Switching the perspective to `Debug` you should be able to see your breakpoints (marked in red):

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_view_breakpoints.png %}


## Run application

Before running our application we'll have a look at the already running processes on the device:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_running_processes.png %}

After starting the application in the `AVD` you'll notice a new process:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_running_processes_after_app_start.png %}

The red "bug" indicates that the process isn't being debugged yet. Meanwhile the app waits for some debugger
to get connected:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/app_waiting_for_debugger.png %}


#### Debug configuration

In order to be able to debug process you'll have to add a new debug configuration:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_debug_configuration.png %}

When setting up the configuration pay attention to the **port** your debugger should connect to. Make sure it matches with the port pair previously 
seen in the running process list (marked in red):

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_debug_set_port.png %}

Now click on **Debug** and you're ready to go. Take a look at the running processes. You'll notice sth changed:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_debug_running.png %}

The bug is now "green" meaning you're ready to debug your application.



## Trigger breakpoint

We've previously set a breakpoint at the `onCreate` method. Now that the application is running I had to "trigger" that breakpoint. Switching to my AVD I took 
a look at the application and filled in the fields:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/app_enter_click.png %}

Afterwards I've clicked *Enter*. Switching back to Eclipse I got following picture:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_hold_on_breakpoint.png %}

The execution stopped at the breakpoint. Success! Now I've typed F6 (Step over) and the execution moved on:

{% img http://dl.dornea.nu/img/2014/eclipse-ddms/eclipse_debug_stepin.png %}

 
## Conclusion

Using great tools like `apktool` and `dex2jar` you can prepare your APK to inspect it dynamically in Eclipse. I think Eclipse (along with ADT) is a very powerful tool 
when it comes to dynamic analysis. I can easily switch between code parts and analyze the execution flow. Keep in mind that when the original is *obfuscated* you may 
want to debug **smali** code. In that case make sure you add the **smali** order instead of the **src** one (described earlier). For any questions feel free to write comments
below.     

## References

* [http://www.programering.com/a/MjM5UTMwATg.html](http://www.programering.com/a/MjM5UTMwATg.html)
* [http://resources.infosecinstitute.com/android-hacking-security-part-6-exploiting-debuggable-android-applications/](http://resources.infosecinstitute.com/android-hacking-security-part-6-exploiting-debuggable-android-applications/)
