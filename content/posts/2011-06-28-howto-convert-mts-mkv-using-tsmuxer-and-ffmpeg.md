+++
title = "HowTo: Convert MTS to MKV using tsMuxeR and ffmpeg"
author = "Victor"
date = "2011-06-28"
tags = ["video", "media", "howto", "tools"]
category = "notes"
+++

Since I wasn't able to find any acceptable Howto, I thought I'd write my own one.

## Initial situation

I have some videos taken with my **Panasonic Lumix DMC-TZ10** in AVCHD Lite format (MTS). All I want to do is to convert these files into some more handy format like MKV (Matroska).

## Demuxing

I've used **tsMuxeR** from SmartLabs to demux the files. Here's what I did:

![tsmuxer](http://dl.dornea.nu/img/2011/253/tsmuxer.png)

Now you should have following files on your disk:

~~~.shell
# ls -ltr 00001.*
-rwxr-xr-x 1 root root 1259520 Jun 27 21:31 00001.MTS
-rw-r----- 1 root root    8906 Jun 28 10:09 00001.track_4608.sup
-rw-r----- 1 root root   25344 Jun 28 10:09 00001.track_4352.ac3
-rw-r----- 1 root root 1150138 Jun 28 10:09 00001.track_4113.264
~~~

## Put things together

Now using **ffmpeg** let's create some MKV from previously demuxed files. Make sure you have ffmpeg with libx264 built-in support ("-enable-libx264" when configuring). For Gentoo users this are my USE flags:

~~~.shell
# eix -e ffmpeg
[I] media-video/ffmpeg
...
     Installed versions:  0.7_rc1(09:28:59 PM 06/27/2011)(3dnow 3dnowext X alsa avx bzip2 encode hardcoded-tables mmx mmxext ssse3 truetype v4l v4l2 x264 xvid zlib -aac -altivec -amr -bindist -celt -cpudetection -custom-cflags -debug -dirac -doc -faac -frei0r -gsm -ieee1394 -jack -jpeg2k -mp3 -network -oss -pic -qt-faststart -rtmp -schroedinger -sdl -speex -static-libs -test -theora -threads -vaapi -vdpau -video_cards_nvidia -vorbis -vpx)
~~~

Now all you have to do is to type:

~~~.shell
$ ffmpeg -i 00001.*.264 -i 00001.*.ac3 -vcodec libx264 -acodec ac3 -b 2000k output.mkv
~~~

You should get some crazy output like:

~~~.shell
ffmpeg version 0.7-rc1, Copyright (c) 2000-2011 the FFmpeg developers
  built on Jun 27 2011 21:28:51 with gcc 4.4.4
  configuration: --prefix=/usr --libdir=/usr/lib64 --shlibdir=/usr/lib64 --mandir=/usr/share/man --enable-shared --cc=x86_64-pc-linux-gnu-gcc --disable-static --enable-gpl --enable-postproc --enable-avfilter --disable-stripping --disable-debug --disable-doc --disable-network --disable-vaapi --disable-ffplay --disable-vdpau --enable-libx264 --enable-libxvid --disable-indev=oss --disable-indev=jack --enable-x11grab --disable-outdev=oss --enable-libfreetype --disable-altivec --enable-hardcoded-tables
  libavutil    50. 40. 1 / 50. 40. 1
  libavcodec   52.120. 0 / 52.120. 0
  libavformat  52.108. 0 / 52.108. 0
  libavdevice  52.  4. 0 / 52.  4. 0
  libavfilter   1. 77. 0 /  1. 77. 0
  libswscale    0. 13. 0 /  0. 13. 0
  libpostproc  51.  2. 0 / 51.  2. 0
[h264 @ 0x24266a0] Estimating duration from bitrate, this may be inaccurate

Seems stream 0 codec frame rate differs from container frame rate: 100.00 (100/1) -> 50.00 (100/2)
Input #0, h264, from &#39;00001.track_4113.264&#39;:
  Duration: N/A, bitrate: N/A
    Stream #0.0: Video: h264 (High), yuv420p, 1280x720 [PAR 1:1 DAR 16:9], 25 fps, 50 tbr, 1200k tbn, 100 tbc
[ac3 @ 0x2427960] Estimating duration from bitrate, this may be inaccurate
Input #1, ac3, from &#39;00001.track_4352.ac3&#39;:
  Duration: 00:00:01.05, start: 0.000000, bitrate: 192 kb/s
    Stream #1.0: Audio: ac3, 48000 Hz, stereo, s16, 192 kb/s
File &#39;output.mkv&#39; already exists. Overwrite ? [y/N] y
[buffer @ 0x242d7d0] w:1280 h:720 pixfmt:yuv420p
[libx264 @ 0x245aa20] Default settings detected, using medium profile
[libx264 @ 0x245aa20] using SAR=1/1
[libx264 @ 0x245aa20] using cpu capabilities: MMX2 SSE2Fast SSSE3 FastShuffle SSE4.1 Cache64
[libx264 @ 0x245aa20] profile High, level 3.2
[libx264 @ 0x245aa20] 264 - core 107 - H.264/MPEG-4 AVC codec - Copyleft 2003-2010 - http://www.videolan.org/x264.html - options: cabac=1 ref=3 deblock=1:0:0 analyse=0x3:0x113 me=hex subme=7 psy=1 psy_rd=1.00:0.00 mixed_ref=1 me_range=16 chroma_me=1 trellis=1 8x8dct=1 cqm=0 deadzone=21,11 fast_pskip=1 chroma_qp_offset=-2 threads=1 sliced_threads=0 nr=0 decimate=1 interlaced=0 constrained_intra=0 bframes=3 b_pyramid=2 b_adapt=1 b_bias=0 direct=1 weightb=1 open_gop=0 weightp=2 keyint=250 keyint_min=25 scenecut=40 intra_refresh=0 rc_lookahead=40 rc=abr mbtree=1 bitrate=2000 ratetol=1.0 qcomp=0.60 qpmin=10 qpmax=51 qpstep=4 ip_ratio=1.40 aq=1:1.00
Output #0, matroska, to &#39;output.mkv&#39;:
  Metadata:
    encoder         : Lavf52.108.0
    Stream #0.0: Video: libx264, yuv420p, 1280x720 [PAR 1:1 DAR 16:9], q=2-31, 2000 kb/s, 1k tbn, 50 tbc
    Stream #0.1: Audio: ac3, 48000 Hz, stereo, s16, 64 kb/s
Stream mapping:
  Stream #0.0 -> #0.0
  Stream #1.0 -> #0.1
Press [q] to stop encoding
^Came=   22 fps=  0 q=0.0 size=       1kB time=10000000000.00 bitrate=   0.0kbits/s    
~~~
