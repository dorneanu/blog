+++
title = "Debugging Android native shared libraries"
date = "2015-07-01"
tags = ["ipython", "hacking", "security", "android", "python", "mobile", "appsec", "c", "gdb"] 
author = "Victor Dorneanu"
category = "blog"
+++

Since I haven't done this before, I thought I could share some experiences with you. All this began during some APK analysis which was heavily using [JNI](https://en.wikipedia.org/wiki/Java_Native_Interface)s. In my particular case *Java Native Interfaces* were used to call functions inside libraries written in C/C++. At that time I was quite unfamiliar with JNIs and how they actually work. Besides that I haven't debugged any native applications/libraries on Android before. So this was the perfect opportunity to have a closer look at [Android NDK](https://developer.android.com/tools/sdk/ndk/index.html) and its debugging features.

## Create Eclipse project

In this post I'll first create and build a *simple* Android project that includes native code using the **JNI**. As a main source I have used this extraordinary [Android JNI tutorial](http://blog.edwards-research.com/2012/04/tutorial-android-jni/) which I highly appreciate. Following the instructions described in the post, I have managed to successfully create an empty Android project (File -> New -> Project -> Android Application Project) for my purposes.


```bash
%%bash
tree -L 1
```

    .
    ├── AndroidManifest.xml
    ├── assets
    ├── build.xml
    ├── ic_launcher-web.png
    ├── jni
    ├── res
    └── src
    
    4 directories, 3 files


And in `src` we have following **classes**:


```python
%ls -lR src/com/example/jni_debug_demo
```

    src/com/example/jni_debug_demo:
    total 8
    -rw-r--r-- 1 victor users 1183 Jun 30 16:44 MainActivity.java
    -rw-r--r-- 1 victor users  471 Jun 30 16:44 SquaredWrapper.java


## Create Android project

In order to be able to build the APK, you'll have to create a new Android project:


```bash
%%bash
/home/victor/work/android-sdk/tools/android update project --target android-19 -p .
```

    Updated and renamed default.properties to project.properties
    Updated local.properties
    Added file ./proguard-project.txt


Now you should be able to **build** the project and also generate the **APK**:


```bash
%%bash
ant clean release | grep BUILD
```

    BUILD SUCCESSFUL


## Add JNI functionalities

Now that we have the base Android project, let's add some **JNI** functionalities to the project. To compile the shared library (using gcc/g++) we'll need a valid C **header** which can be computed from *SquaredWrapper* (class used in previously mentioned tutorial).

### C header

The compiled classes are now in "`./bin/classes`". Let's generate the **header** files for `SquaredWrapper`:


```bash
%%bash
javah -jni -classpath ~/work/android-sdk/platforms/android-19/android.jar:./bin/classes -o square.h com.example.jni_debug_demo.SquaredWrapper
cat square.h
```

    /* DO NOT EDIT THIS FILE - it is machine generated */
    #include <jni.h>
    /* Header for class com_example_jni_debug_demo_SquaredWrapper */
    
    #ifndef _Included_com_example_jni_debug_demo_SquaredWrapper
    #define _Included_com_example_jni_debug_demo_SquaredWrapper
    #ifdef __cplusplus
    extern "C" {
    #endif
    /*
     * Class:     com_example_jni_debug_demo_SquaredWrapper
     * Method:    squared
     * Signature: (I)I
     */
    JNIEXPORT jint JNICALL Java_com_example_jni_1debug_1demo_SquaredWrapper_squared
      (JNIEnv *, jclass, jint);
    
    #ifdef __cplusplus
    }
    #endif
    #endif


So there is a function **Java_com_example_jni_1debug_1demo_SquaredWrapper_squared** (pay attention to the naming convention) which has 3 arguments. I won't discuss this further and I'll simple copy the file into a new folder `jni` inside the project:


```bash
%%bash
mkdir jni
mv square.h jni/
```

### C source

Now that we have the **function definition** and the prototype generated by `javah` we can easily implement the **C source** as follows:


```python
%cat jni/square.c
```

    #include "square.h"
     
    JNIEXPORT jint JNICALL Java_com_example_jni_1debug_1demo_SquaredWrapper_squared (JNIEnv * je, jclass jc, jint base)
    {
        return (base*base);
    }


So nothing special about it. Due to the introductory aspect of this post I'll try to keep things simple. You can of course go further and implement more complex functions. 

### Build the library

Create a **Makefile** for all the Android build tools. 


```python
%cat jni/Android.mk
```

    LOCAL_PATH := $(call my-dir)
     
    include $(CLEAR_VARS)
    
    LOCAL_LDLIBS := -llog
    
    LOCAL_MODULE    := squared
    LOCAL_SRC_FILES := square.c
     
    include $(BUILD_SHARED_LIBRARY)


And now **build** the library (remember to set the *NDK_DEBUG* flag otherwise you won't be able to debug your native code):


```bash
%%bash
NDK_DEBUG=1 /home/victor/work/android-ndk-r10e/ndk-build 
readelf -h libs/armeabi/libsquared.so
```

    Android NDK: WARNING: APP_PLATFORM android-19 is larger than android:minSdkVersion 16 in ./AndroidManifest.xml    
    [armeabi] Gdbserver      : [arm-linux-androideabi-4.8] libs/armeabi/gdbserver
    [armeabi] Gdbsetup       : libs/armeabi/gdb.setup
    [armeabi] Compile thumb  : squared <= square.c
    [armeabi] SharedLibrary  : libsquared.so
    [armeabi] Install        : libsquared.so => libs/armeabi/libsquared.so
    ELF Header:
      Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 
      Class:                             ELF32
      Data:                              2's complement, little endian
      Version:                           1 (current)
      OS/ABI:                            UNIX - System V
      ABI Version:                       0
      Type:                              DYN (Shared object file)
      Machine:                           ARM
      Version:                           0x1
      Entry point address:               0x0
      Start of program headers:          52 (bytes into file)
      Start of section headers:          12564 (bytes into file)
      Flags:                             0x5000000, Version5 EABI
      Size of this header:               52 (bytes)
      Size of program headers:           32 (bytes)
      Number of program headers:         8
      Size of section headers:           40 (bytes)
      Number of section headers:         21
      Section header string table index: 20


## Call the library

In `MainActivity` some static routines of the class `SquaredWrapper` are being called:

```.java
public class MainActivity extends Activity {
    private EditText etInput;
    private TextView txtTo2;
    private TextView txtTo4;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		
		// Define Input EditText, TextViews
        etInput = (EditText) findViewById(R.id.etInput);
        txtTo2 =  (TextView) findViewById(R.id.resTo2);
        txtTo4 =  (TextView) findViewById(R.id.resTo4);
		
		int b = 3;
        int a = SquaredWrapper.to4(b);
        Log.i("JNIDemo", String.format("%d->%d", b,a));
	}
	
	public void cbCalculate(View view) {
        int in = 0;
        try{
            in = Integer.valueOf( etInput.getText().toString() );
        } catch(NumberFormatException e) { 
        	return ; 
        }
         
        txtTo2.setText(String.format("%d", SquaredWrapper.squared(in)));
        txtTo4.setText(String.format("%d", SquaredWrapper.to4(in)));
    }
}
```

Build the project again:


```bash
%%bash
ant clean release | grep -e "^BUILD"
```

    BUILD SUCCESSFUL


## Run the demo application

First let's build the APK with **debug** enabled and sign it using a debug key:


```bash
%%bash
ant clean debug | grep -e "^BUILD"
```

    BUILD SUCCESSFUL


Now you can **install** `./bin/MainActivity-debug.apk` on your Android device (whether virtual or real)


```bash
%%bash
/home/victor/work/android-sdk/platform-tools/adb devices
```

    List of devices attached 
    0123456789ABCDEF	device
    



```bash
%%bash
adb install ./bin/MainActivity-debug.apk 2> /dev/null
```

    WARNING: linker: libvc1dec_sa.ca7.so has text relocations. This is wasting memory and is a security risk. Please fix.
    WARNING: linker: libvc1dec_sa.ca7.so has text relocations. This is wasting memory and is a security risk. Please fix.
    	pkg: /data/local/tmp/MainActivity-debug.apk
    Success



```bash
%%bash 
adb shell am start -n com.example.jni_debug_demo/com.example.jni_debug_demo.MainActivity
```

    WARNING: linker: libvc1dec_sa.ca7.so has text relocations. This is wasting memory and is a security risk. Please fix.
    WARNING: linker: libvc1dec_sa.ca7.so has text relocations. This is wasting memory and is a security risk. Please fix.
    Starting: Intent { cmp=com.example.jni_debug_demo/.MainActivity }


![JNI Debug Demo Application](/posts/img/2015/android-solib/a74f0e9adca736086c2834fb63c793ad.png)

Greping for the **logcat messages** shows:

```.shell
$ adb logcat -s JNIDemo
--------- beginning of /dev/log/system
--------- beginning of /dev/log/main
I/JNIDemo ( 5524): 3->81
I/JNIDemo ( 5524): 3->81
I/JNIDemo ( 5524): 3->81
^C
```

## Debug the application

For the next steps a **rooted** device is *required*. Besides that you should install the *Android NDK* if you haven't done this yet. 

### Remount /system as rw

First you'll have to *mount* `/system` with read-write rights:


```bash
%%bash
adb shell mount | grep -e "system"
```

    /emmc@android /system ext4 ro,seclabel,noatime,noauto_da_alloc,commit=1,data=ordered 0 0



```bash
%%bash
adb shell "su -c 'mount -o rw,remount /system'"
```


```bash
%%bash
adb shell mount | grep -e "system"
```

    /emmc@android /system ext4 rw,seclabel,relatime,noauto_da_alloc,commit=1,data=ordered 0 0


### Copy gdbserver to device

Now you'll have to copy the **gdbserver** from the Android NDK into `/system/bin`:


```bash
%%bash
find /home/victor/work/android-ndk-r10e/ -type f -name "gdbserver"
```

    /home/victor/work/android-ndk-r10e/prebuilt/android-mips/gdbserver/gdbserver
    /home/victor/work/android-ndk-r10e/prebuilt/android-x86_64/gdbserver/gdbserver
    /home/victor/work/android-ndk-r10e/prebuilt/android-arm64/gdbserver/gdbserver
    /home/victor/work/android-ndk-r10e/prebuilt/android-x86/gdbserver/gdbserver
    /home/victor/work/android-ndk-r10e/prebuilt/android-mips64/gdbserver/gdbserver
    /home/victor/work/android-ndk-r10e/prebuilt/android-arm/gdbserver/gdbserver



```bash
%%bash
adb shell cat /proc/cpuinfo | grep -e "Processor"
```

    Processor	: ARMv7 Processor rev 3 (v7l)



```bash
%%bash
adb push /home/victor/work/android-ndk-r10e/prebuilt/android-arm/gdbserver/gdbserver /mnt/sdcard/tmp 2> /dev/null
adb shell "su -c 'cp /mnt/sdcard/tmp/gdbserver /system/bin/'"
```

### Copy ARM libraries to your client

In order to be able to find debug information/symbols you'll need  all ARM libraries all your device/emulator to be copied to your PC. `gdb` will need them later on.


```bash
%%bash
mkdir system_lib
cd system_lib
adb pull /system/lib 2> /dev/null
```

### Run the application


```bash
%%bash
adb shell am start -n com.example.jni_debug_demo/com.example.jni_debug_demo.MainActivity
```

    WARNING: linker: libvc1dec_sa.ca7.so has text relocations. This is wasting memory and is a security risk. Please fix.
    WARNING: linker: libvc1dec_sa.ca7.so has text relocations. This is wasting memory and is a security risk. Please fix.
    Starting: Intent { cmp=com.example.jni_debug_demo/.MainActivity }



```bash
%%bash
adb shell ps | grep jni_debug_demo
```

    u0_a159   28054 135   554400 14484 ffffffff 00000000 S com.example.jni_debug_demo


Now that the app is running we're ready to start the debugger and attach it to the process ID *28054*. 

### Attach gdb to process

In project's root directory you'll run `ndk-gdb` which is part of the *Android NDK* package. 


```bash
%%bash
ndk-gdb --verbose > /dev/null
```

    warning: Could not load shared library symbols for 108 libraries, e.g. libstdc++.so.
    Use the "info sharedlibrary" command to see the complete listing.
    Do you need "set solib-search-path" or "set sysroot"?


Without paying attention to the *warning* message, here are the steps `ndk-gdb` will do for you

* check if application is running
* setup network redirection (port forwarding)

```
adb_cmd forward tcp:5039 localfilesystem:/data/data/com.example.jni_debug_demo/debug-socket
```

* pull several utilities (app_process, linker) from the device/emulator
* start `gdb`
* attach to the process

One could of course do all these steps **manually**. 

1) Do port *forwarding*:

```
\\( adb forward tcp:1337 tcp:1337
```

1) Attach `gdbserver` to the process (on the device)

```
root@Android:/ # ps | grep jni
u0\_a159   28054 135   561056 14100 ffffffff 400a499c S com.example.jni\_debug\_demo
root@Android:/ # gdbserver :1337 --attach 28054                                
Attached; pid = 28054
Listening on port 1337

```
2) Connect gdb `client` to the server:

```
\\) /home/victor/work/android-ndk-r10e/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-gdb
...
> target remote :1337
...
```

But I still recommend using `ndk-gdb`. 


### Read debugging information

And now let's go back to the previously mentioned `warning` message:

```
warning: Could not load shared library symbols for 108 libraries, e.g. libstdc++.so.
```

`gdb` is telling us that it can't find any **debugging symbols** for the loaded (ARM) libraries. In that case we'll have to specify the **path** where it can find that information:

* `system_lib`: contains all ARM libraries from the device (/system/lib)
* `obj/local/armeabi`: contains debugging information about `libsquared.so` (our target)

```
$ ndk-gdb --verbose
...
gef> set solib-search-path system_lib/:obj/local/armeabi/
Reading symbols from system_lib/libc.so...(no debugging symbols found)...done.
Loaded symbols for system_lib/libc.so
Reading symbols from system_lib/libstdc++.so...(no debugging symbols found)...done.
Loaded symbols for system_lib/libstdc++.so
Reading symbols from system_lib/libm.so...(no debugging symbols found)...done.
Loaded symbols for system_lib/libm.so
Reading symbols from system_lib/liblog.so...(no debugging symbols found)...done.
Loaded symbols for system_lib/liblog.so
Reading symbols from system_lib/libcutils.so...(no debugging symbols found)...done.
...

```

You can now **verify** the debugging information via `info sharedlibrary`:

```
gef> info sharedlibrary
From        To          Syms Read   Shared Object Library
0x40053a80  0x400619e8  Yes (*)     /home/victor/workspace/jni_debug_demo/obj/local/armeabi/linker
0x4008c500  0x400d2e54  Yes (*)     /home/victor/workspace/jni_debug_demo/system_lib/libc.so
0x400f4828  0x400f49ec  Yes (*)     /home/victor/workspace/jni_debug_demo/system_lib/libstdc++.so
0x400f9940  0x4010d5b8  Yes (*)     /home/victor/workspace/jni_debug_demo/system_lib/libm.so
0x4007a190  0x4007bdf8  Yes (*)     /home/victor/workspace/jni_debug_demo/system_lib/liblog.so
0x4006f6c8  0x40074ac4  Yes (*)     /home/victor/workspace/jni_debug_demo/system_lib/libcutils.so
0x4012eb1c  0x40131210  Yes (*)     /home/victor/workspace/jni_debug_demo/system_lib/libgccdemangle.so
0x40142bf0  0x40152a84  Yes (*)     /home/victor/workspace/jni_debug_demo/system_lib/libz.so
...
0x60b5bbe4  0x60b5d174  Yes         /home/victor/workspace/jni_debug_demo/obj/local/armeabi/libsquared.so
                        No          gralloc.mt6582.so
(*): Shared library is missing debugging information.
```

### Find target function

From last output you can see that `libsquared.so` starts at address **0x60b5bbe4**. Let's see what we can find there:

![jni_debug_demo libsquared](/posts/img/2015/android-solib/b85df1e566b46ed748e315c3d4f043ed.png)

Bingo! So `Java_com_example_jni_1debug_1demo_SquaredWrapper_squared` starts at **0x60b5bc28**. We'll definitely set a **breakpoint** at that address:

```.shell
gef> b Java_com_example_jni_1debug_1demo_SquaredWrapper_squared
Breakpoint 1 at 0x60b5bc40: file jni/square.c, line 5.
gef>
```

### Trigger and debug function

For the targeted function to be executed we'll have to trigger its execution by clicking on the "Calculate" button in the UI. **Before** doing that you should tell `gdb` to *continue* execution:

```
gef> continue
Continuing.
```

After having pressed the button in the UI, you should see sth similar to this:

```
gef> continue
Continuing.
--------------------------------------------------------------------------------[regs]
\\(r0    0x4187fe30 \\)r1    0x7a100019 \\(r2    0x00000008 \\)r3    0x578bbd18 
\\(r4    0x57c49258 \\)r5    0x41882860 \\(r6    0x00000004 \\)r7    0x578bbccc 
\\(r8    0xbed1e2a8 \\)r9    0x578bbcc4 \\(r10   0x41882870 \\)r11   0xbed1e2a4 
\\(r12   0x60b5bc28 \\)sp    0xbed1e290 \\(lr    0x418a1750 \\)pc    0x60b5bc40 

--------------------------------------------------------------------------------[stack]
0xbed1e290: 
0xbed1e294: 
0xbed1e298: 
0xbed1e29c: 
0xbed1e2a0: 
0xbed1e2a4: 
0xbed1e2a8: 
0xbed1e2ac: 
0xbed1e2b0: 
0xbed1e2b4: 
--------------------------------------------------------------------------------[code]
0x60b5bc2c       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+4>:  add     r11, sp, #0
0x60b5bc30       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+8>:  sub     sp, sp, #20
0x60b5bc34       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+12>: str     r0, [r11, #-8]
0x60b5bc38       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+16>: str     r1, [r11, #-12]
0x60b5bc3c       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+20>: str     r2, [r11, #-16]
0x60b5bc40       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+24>: ldr     r3, [r11, #-16] <<= 
0x60b5bc44       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+28>: ldr     r2, [r11, #-16]
0x60b5bc48       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+32>: mul     r3, r2, r3
0x60b5bc4c       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+36>: mov     r0, r3
0x60b5bc50       <Java_com_example_jni_1debug_1demo_SquaredWrapper_squared+40>: sub     sp, r11, #0
--------------------------------------------------------------------------------[trace]
#0  Java_com_example_jni_1debug_1demo_SquaredWrapper_squared (je=0x4187fe30, jc=0x7a100019, base=8) at jni/square.c:5
#1  0x418a1750 in ?? ()
Backtrace stopped: previous frame identical to this frame (corrupt stack?)

Breakpoint 1, Java_com_example_jni_1debug_1demo_SquaredWrapper_squared (je=0x4187fe30, jc=0x7a100019, base=8) at jni/square.c:5
5           return (base*base);
```

You can see that the execution currently stopped at **0x60b5bc40**. Now you can inspect the *registers*, set *additional* breakpoints, *step* into routines etc. 

![GDB GEF](/posts/img/2015/android-solib/1c34d2da522b2a450b603cf8cd6a965a.png)
![GDB GEF](/posts/img/2015/android-solib/18d6146e96dbb21ceed498ae1cdd92f4.png)

At this point you should now be equipped with enough knowledge to dissect shared libraries and get some reverse engineering job done. Although this was a quite easy one due to the fact that we had debug symbols and were able to compile the library, the same techniques should also work on *stripped* binaries. In the post I'll some *binary analysis* on some random Android shared library using [radare](http://www.radare.org/r/).

## References

* [jni_debug_demo GitHub Project](https://github.com/dorneanu/test/tree/master/jni_debug_demo)
* [Tutorial: Android JNI](http://blog.edwards-research.com/2012/04/tutorial-android-jni/)
* [Advanced Android: Getting started with the NDK](http://code.tutsplus.com/tutorials/advanced-android-getting-started-with-the-ndk--mobile-2152)
* [How to do remote debugging via gdbserver running inside the Android phone?](https://tthtlc.wordpress.com/2012/09/19/how-to-do-remote-debugging-via-gdbserver-running-inside-the-android-phone/)
