+++
title = "Video editing with ffmpeg and kdenlive"
author = "Victor Dorneanu"
date = "2016-01-08"
tags = ["note", "ffmpeg", "kdenlive", "video"]
+++

Having recently bought a brand new [Sony Action Cam HDR-AS200v](http://www.sony.net/Products/actioncam/en-us/support/cameras/HDR-AS200V/) I wanted to do some video editing. I've used [Blender](https://www.blender.org) before but at some point of time it was to over-bloated and to complicated for some video editing tasks. So I've had a look at [kdenlive](https://kdenlive.org).

Due to the nature of the action cam I had recordings in 

* standard MP4 (28 Mb/s)
* XAVC S Codec (50 Mb/s)

I've first set the right profile in *kdenlive* (1080p, 30fps) and imported the recordings. Afterwards you can *render* your mixture losslessly by using the **MPEG4** profile which is basically:

* video: mpeg4
* audio: pcm_s16le

Since the rendered movie is going to be very large, you can render and compress it to sth like [h264](https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC). This is also the codec recommended by [YouTube](https://support.google.com/youtube/answer/1722171?hl=en) for the uploads. So I've used `ffmpeg` to encode my lossless movie to *h264*:

    ffmpeg -threads 0 \
           -i <loessless movie> \
           -crf 18 \
           -bf 2 \ 
           -flags +cgop \
           -pix_fmt yuv420p \
           -acodec aac  -strict -2 \
           -vcodec h264 \
           -preset slow \
           -b:v 500k 
           movie_h264.avi

To play the movie I recommend `mplayer` or [mpv](https://mpv.io):

    mplayer -cache-min 70 -lavdopts threads=0 -framedrop <file.avi>

or

    mpv --autosync=30  --vd-lavc-threads=0 <file.avi>





