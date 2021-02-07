+++
title = "HowTo: iOS Apps - Static analysis"
author = "Victor Dorneanu"
date = "2014-10-29"
tags = ["coding", "security", "ios", "appsec", "howto", "mobile"]
category = "blog"
+++

In this short article I'll try to explain what are the main steps to analyze an iOS app. Since I've writen similar posts related to [Android](/tag/android/) I thought I could devote some of spare time writing about the steps required to analyze iOS apps/binaries. But first of all let's start with:

## What's an iOS app?

In a nutshell here are the main characteristics:

* Objective-C / C / C++ compiled (ARM) executable
* mostly encrypted using Apple's [Fairplay](http://en.wikipedia.org/wiki/FairPlay) DRM
* it runs in a sandbox
* it's installed by the user `mobile`
* apps come as an **IPA** file which is the counterpart to Android's **APK**

Now that you roughly know what an iOS app is let's have a look at the most common *blackbox* pentesting tools out there. In this post I'll focus only on *static analysis*. *Dynamic analysis* (also known as *runtime analysis*) will be covered in a future post. 


## Binary Analysis Tools

Assuming you've already jailbreaked your device, you'll definitely need these tools:

* **SSH** - For connecting to the device
* **ipainstaller** - Install [IPA](http://en.wikipedia.org/wiki/.ipa_%28file_extension%29) files
* **otool** - object file displaying [tool](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/otool.1.html)  
* [**class-dump-z**](https://github.com/nygard/class-dump) -  Examine Mach-O files and dump segments as Objective-C declarations
* Dump encrypted app
    - [**dumpdecrypted**](https://github.com/stefanesser/dumpdecrypted) - Dumps decrypted mach-o files from encrypted iPhone applications from memory to disk
    - [**Clutch**](https://github.com/KJCracks/Clutch) 

## IPA

**ipa** files are archive files which are usually encrypted using Apple's FairPlay DRM. In a nutshell an ipa file consists of:

{% img http://oi60.tinypic.com/15q2ici.jpg 600 200 "IPA-File" "IPA-File" %}


The **App binary** is the target to be analyzed. It's compiled for ARM and used the **Mach-O**(mach object) file format. Check out next section for more detailed information.


#### Installing the App 

Usually you can manually install apps by using **ipainstaller**:

~~~
# ipainstaller <ipa file>
...
~~~

This will install your app under `/var/mobile/Applications`. Just do a `grep` to find out to which folder your app was copied to.


## Mach-O

The Mach-O binary consists of 3 components:

{% img https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/MachORuntime/art/mach_o_segments.gif 600 200 Mach-O Mach-O %}

#### Header

The **header** contains basic file type information like architecture and several flags. Using **otool** you can have a look a the headers:

~~~
# otool -h BINARY
BINARY:
Mach header
      magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
 0xfeedfacf 16777228          0  0x00          2    29       3832 0x00200085
~~~

Sometimes you'll get an application that is built for multiple architectures. These applications then consist of multiple Mach-O files and are called **fat** or **universal** binaries. Mach-O fat binaries not only group completely different CPU architectures (PowerPC, Intel) but also 32- or 64-bit versions of an architecture. Besides that you'll also get different CPU subtypes bundled in one binary. The device running the binary will choose the "part" of the binary it can best support. Also have a look at this great [article](http://wanderingcoder.net/2010/07/19/ought-arm/).

Here is an example of a fat binary:

~~~
# otool -arch all -h PewPew 
PewPew (architecture cputype (12) cpusubtype (9)):
Mach header
      magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
 0xfeedface      12          9  0x00          2    29       3544 0x00210085
PewPew (architecture cputype (12) cpusubtype (11)):
Mach header
      magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
 0xfeedface      12         11  0x00          2    29       3544 0x00210085
~~~


#### Load commands

The [load commands](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/MachORuntime/index.html#//apple_ref/doc/uid/20001298-89026) are located directly after the header and specify the logical structure of the binary (as a file) and it's representation in the virtual memory (using offsets). Besides that you'll be able to get:

* the symbol table
* shared library details

For my understanding it's pretty much the same as ELFs segments and sections:

{% img http://oi59.tinypic.com/3478ltk.jpg 600 200 ELF ELF %}

Load commands also define whether an application is encrypted or not. To have a look at the those run:

~~~
# otool -Vl BINARY
...
~~~


#### Raw segment data

In the Mach-O file you'll also have [raw data](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/MachOTopics/0-Introduction/introduction.html) for the segments specified in the load commands. One segment can consist of multiple sections.



## Runtime protection features

iOS has several mechanisms which prevent application from being compromised at runtime. In order to understand the security issues that affect iOS applications, it is important to understand and to known the security features of the platform. The main security features of iOS [are](http://www.apple.com/ipad/business/docs/iOS_Security_Feb14.pdf):

* **Code signing**
    - Ensures that all applications come from a approved source (using Apple-issued certificates)



* **Generic exploit mitigations**
    * Address Space Layout Randomization ([ASLR](http://en.wikipedia.org/wiki/Address_space_layout_randomization)) 
        * Usually compiled using `-fPIE –pie`
    * Non Executable Memory ([ARM's Execute Never](http://en.wikipedia.org/wiki/Address_space_layout_randomization) feature)
    * Stack Smashing Protections ([SSP](http://wiki.osdev.org/Stack_Smashing_Protector))
        * Usually compiled with `–fstack-protector-all` flag



* **Sandboxing**
    * run applications as non-privileged user
    * 3rd-party apps are restricted in accessing files stored by other apps



* **Memory Management**
    * Automatic Reference Counting ([ARC](https://developer.apple.com/library/ios/releasenotes/objectivec/rn-transitioningtoarc/Introduction/Introduction.html)) protects applications from memory coruption issues by letting the compiler do the memory management stuff


Keeping all this stuff in mind, let's pickup some binary and go for it.


## Analyzing the binary

Comparing Android to iOS I must admit you'll have to overcome more (technical) challenges for a successful analysis. iOS uses **binary** files (instead of *bytecode*). Having that said I'll be using **otool** (which seems to be the equivalent to **readelf**) to inspect the binary.

#### Architecture

Let's first determine the *architecture* the binary was compiled for:

~~~
# otool -f BINARY                                                                                              
Fat headers
fat_magic 0xcafebabe
nfat_arch 2
architecture 0
    cputype 12
    cpusubtype 9
    capabilities 0x0
    offset 16384
    size 2712496
    align 2^14 (16384)
architecture 1
    cputype 16777228
    cpusubtype 0
    capabilities 0x0
    offset 2736128
    size 3213664
    align 2^14 (16384)
~~~

Or using old-school `file`:

~~~
# file BINARY
PM: Mach-O fat file with 2 architectures
~~~

Also have a look at this cool [list](http://blakespot.com/ios_device_specifications_grid.html).


#### Encryption

Usually the `ipa` file will be decrypted at runtime by the kernel's mach loader. If the binary is encrypted or not is easily found out using:

~~~
# otool -l BINARY | grep -A 4 LC_ENCRYPTION_INFO
~~~

In this case the binary file is **not** encrypted. Let me show an example where the binary **is** encrypted:

~~~
# otool -l OTHER_BINARY | grep -A 4 LC_ENCRYPTION_INFO                            
          cmd LC_ENCRYPTION_INFO
      cmdsize 20
 cryptoff  16384
 cryptsize 10502144
 cryptid   1
~~~

### Runtime protections mechanisms

This time I'll show you how to extract some valuable information from the binary itself regarding some runtime protection mechanisms:

* **ASLR**
    - Usually the binary is compiled using the `PIE` flag

~~~
# otool -Vh BINARY 
WH Quest:
Mach header
      magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
   MH_MAGIC     ARM          9  0x00     EXECUTE    45       4684   NOUNDEFS DYLDLINK TWOLEVEL BINDS_TO_WEAK PIE
~~~

Have you noticed the `PIE` flag at the end of the list?

* **Stack Smashing Protection**
    - iOS applications usually use [**stack canaries**](http://en.wikipedia.org/wiki/Stack_buffer_overflow#Stack_canaries)
    - therefore you should find certain symbols inside the binary (like `_stack_chk_guard` and `_stack_chk_fail`)

~~~
# otool -v -l BINARY | grep stack
...
~~~


* **Automatic Reference Couting**
    - this option can be enabled by activating the compiler option "Objective-C Automatic Reference Counting"
    - binaries built with this option should include symbols called `_objc_release`, `_obj_autorelease`, `_obj_storeStrong`, `_obj_retain`

~~~
# otool -v -I BINARY  | grep release
0x008b8ce4 241789 _objc_autorelease
0x008b8cf4 241790 _objc_autoreleasePoolPop
0x008b8d04 241791 _objc_autoreleasePoolPush
0x008b8d14 241792 _objc_autoreleaseReturnValue
0x008b8ea4 241817 _objc_release
0x008b8ed4 241820 _objc_retainAutorelease
0x008b8ee4 241821 _objc_retainAutoreleaseReturnValue
0x008b8ef4 241822 _objc_retainAutoreleasedReturnValue
0x008b9504 241439 ___cxa_guard_release
0x008b9674 241341 __Block_release
0x008b9ab4 241551 _dispatch_release
0x00a0c3f4 229369 __ZN11GPASWrapperI6GPHashE7releaseEv
0x00a12e8c 241789 _objc_autorelease
0x00a12e90 241790 _objc_autoreleasePoolPop
0x00a12e94 241791 _objc_autoreleasePoolPush
0x00a12e98 241792 _objc_autoreleaseReturnValue
0x00a12efc 241817 _objc_release
0x00a12f08 241820 _objc_retainAutorelease
0x00a12f0c 241821 _objc_retainAutoreleaseReturnValue
0x00a12f10 241822 _objc_retainAutoreleasedReturnValue
0x00a13094 241439 ___cxa_guard_release
0x00a130f0 241341 __Block_release
0x00a13200 241551 _dispatch_release
~~~


#### Dangerous functions

Beside the previosly mentioned symbols we can also seek for symbols aimed at (classical) memory management mechanisms like `malloc` and `free`. Their presence indicate that the application has its own memory management which is the opposite to **ARC**. While this is not always a bad thing it could easily lead to some memory related vulnerabilities if not handled properly.

~~~
# otool -v -I BINARY  | grep malloc
0x008b9f64 241776 _malloc
0x00a1332c 241776 _malloc

# otool -v -I BINARY  | grep free  
0x008b9cb4 241583 _free
0x008b9cc4 241584 _freeifaddrs
0x00a13280 241583 _free
0x00a13284 241584 _freeifaddrs
~~~

> Sometimes you'll find goodies like `strcpy` :)

## Understand the App

Now that we have examined the binary we should proceed and try to "understand" the application. This means we have to look at it from a *logical perspective* and identify its main components. Afterwards one can go into detail and analyze only certain parts of the application which might be of interest. 

Using `class-dump-z` we'll dump the class information:

~~~
# class-dump-z BINARY | head -20
Warning: Part of this binary is encrypted. Usually, the result will be not meaningful. Try to provide an unencrypted version instead.
/**
 * This header is generated by class-dump-z 0.2-0.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: (null)
 */

@protocol XXEncryptedProtocol_aff088
@property(assign) ? XXEncryptedProperty_8bd3a0;
@property(assign) ? XXEncryptedProperty_8bd383;
@property(assign) ? XXEncryptedProperty_8bd373;
@property(assign) ? XXEncryptedProperty_8bd369;
-(?)XXEncryptedMethod_93d1ce;
-(?)XXEncryptedMethod_93d1c3;
-(?)XXEncryptedMethod_93d1be;
-(?)XXEncryptedMethod_93d1b9;
-(?)XXEncryptedMethod_93d1ad;
-(?)XXEncryptedMethod_93c8e5;
-(?)XXEncryptedMethod_93c784;
-(?)XXEncryptedMethod_93c697;

~~~

Every class name seems to be encrypted. That's a good hint you should decrypt the binary in case you haven't done so yet. 


### Decrypt binary

Since every application downloaded from the AppStore is encrypted using Apple's FairPlay DRM you'll have to decrypt them before starting your analysis. For this step I'll be using `clutch` to dump the relevant data from memory to disk.

~~~
# Clutch MyAPP
Cracking MyAPP...
Creating working directory...
Performing initial analysis...
Performing cracking preflight...
yolofat magic 4277009102
Application is a thin binary, cracking single architecture...
dumping binary: analyzing load commands
found vmaddr
found LC_ENCRYPTION
found LC_CODE_SIGNATURE
dumping binary: obtaining ptrace handle
dumping binary: forking to begin tracing
dumping binary: obtaining mach port
dumping binary: preparing code resign
dumping binary: preparing to dump
dumping binary: ASLR enabled, identifying dump location dynamically
dumping binary: performing dump
dumping binary: patched cryptid
dumping binary: writing new checksum
Censoring iTunesMetadata.plist...
warning: iTunesMetadata.plist item named 'asset-info' is unrecognized
warning: iTunesMetadata.plist item named 'product-type' is unrecognized
warning: iTunesMetadata.plist item named 'bundleDisplayName' is unrecognized
Packaging IPA file...
Compressing second stage payload (2/2)...
    /var/root/Documents/Cracked/MyAPP.ipa
~~~

Now that you have decrypted to binary and got a fresh new IPA file, you're ready to unpack it:

~~~
# unzip -d MyAPP MyAPP.ipa
...
~~~

Afterwards you can have a look at the new binary using `class-dump-z`:

~~~
# class-dump-z BINARY  | head -n 20
/**
 * This header is generated by class-dump-z 0.2-0.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: (null)
 */

typedef struct _NSZone NSZone;

typedef struct CGPoint {
    float x;
    float y;
} CGPoint;

typedef struct CGSize {
    float width;
    float height;
} CGSize;

typedef struct CGRect {

~~~

Much better, isn't it? :)


### Disassemble binary

I don't want to be too specific and go into too much detail. A good *disassembler* could save you a **lot** of time. I really like [Hopper](http://www.hopperapp.com/) because it's *free* and *easy* to use. For the geeks out there feel free to throw your binary into [IDA](https://www.hex-rays.com/products/ida/) and let the bin rock. Particularly noteworthy is also [radare2](http://www.radare.org/y/) which is unix-like reverse engineering framework. 


## Conclusion

Binary analysis can be a hell of a lot of fun if you have the right tools. Especially when you're not used to Apple's universe and don't have a Mac OS machine it could be useful to jailbreak your smartphone/tablet and install your tools there. *Gather* as much information as you can get to get a pretty precise image of what you're dealing with. *Disassemble* your binary to get more in "contact". Afterwards *run* it and do some runtime analysis.


## References

* [iNalyzer – No More iOS Blackbox Assessments](http://conference.hitb.org/hitbsecconf2013ams/materials/D2T2%20-%20Chilik%20Tamir%20-%20iAnalyzer%20-%20No%20More%20Blackbox%20iOS%20Analysis.pdf)
* [iPwn Apps: Pentesting iOS Applications](https://www.sans.org/reading-room/whitepapers/testing/ipwn-apps-pentesting-ios-applications-34577)
* [Pentesting iOS Apps Runtime Analysis and Manipulation](http://reverse.put.as/wp-content/uploads/2011/06/pentestingiosapps-deepsec2012-andreaskurtz.pdf)
* [IOS Application Security Part 15 – Static Analysis of IOS Applications using iNalyzer](http://resources.infosecinstitute.com/part-15-static-analysis-of-ios-apps-using-inalyzer/)
* [Hacking and Securing iOS Applications](http://books.google.de/books?id=huy8AwAAQBAJ&printsec=frontcover#v=onepage&q&f=false)
