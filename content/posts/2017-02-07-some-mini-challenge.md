+++
title = "Some forensics mini-challenge"
author = "Victor Dorneanu"
date = "2017-02-01"
tags = ["networking", "linux", "dfir", "python"]
category = "blog"
+++

After reading [this excellent article](https://www.elttam.com.au/blog/playing-with-canaries/) I've found this [page](https://www.elttam.com.au/roles/). If you scroll down you'll find the **Apply** section. Not that I wanted to apply for some job but I thought, it'd be challenging to find out the mail address:

> well, the email address is hidden below. Find the email and send your resume, solution walk-through and desired role.

Let's have a look at the message:

```
2c 54 2d f0 0d 2a 08 00 27 c3 59 62 08 00 45 00
01 a1 f3 33 40 00 40 06 bd 8d c0 a8 01 20 68 d2
5d fb 88 90 00 50 c9 c9 77 90 1f e5 d2 bd 50 18
00 e5 8a 29 00 00 50 4f 53 54 20 2f 63 61 72 65
65 72 20 48 54 54 50 2f 31 2e 31 0d 0a 48 6f 73
74 3a 20 77 77 77 2e 65 6c 74 74 61 6d 2e 63 6f
6d 2e 61 75 0d 0a 55 73 65 72 2d 41 67 65 6e 74
3a 20 65 6c 74 74 61 6d 20 72 6f 63 6b 73 21 0d
0a 41 63 63 65 70 74 2d 4c 61 6e 67 75 61 67 65
3a 20 65 6e 2d 55 53 2c 65 6e 3b 71 3d 30 2e 35
0d 0a 41 63 63 65 70 74 2d 45 6e 63 6f 64 69 6e
67 3a 20 67 7a 69 70 2c 20 64 65 66 6c 61 74 65
0d 0a 43 6f 6f 6b 69 65 3a 20 5a 57 31 68 61 57
77 39 4d 47 59 77 59 54 42 6a 4d 47 49 79 4e 54
41 77 4d 44 6b 78 4d 54 45 78 4d 44 51 77 4f 44
52 69 4d 44 59 77 59 54 41 34 4e 47 49 77 4e 44
45 77 0d 0a 43 6f 6e 74 65 6e 74 2d 54 79 70 65
3a 20 61 70 70 6c 69 63 61 74 69 6f 6e 2f 78 2d
77 77 77 2d 66 6f 72 6d 2d 75 72 6c 65 6e 63 6f
64 65 64 0d 0a 43 6f 6e 74 65 6e 74 2d 4c 65 6e
67 74 68 3a 20 38 31 0d 0a 43 6f 6e 6e 65 63 74
69 6f 6e 3a 20 63 6c 6f 73 65 0d 0a 0d 0a 71 3d
54 68 65 2b 65 6d 61 69 6c 2b 61 64 64 72 65 73
73 2b 69 73 2b 68 69 64 64 65 6e 2b 69 6e 2b 74
68 69 73 2b 72 65 71 75 65 73 74 26 62 6f 6e 75
73 3d 57 68 61 74 2b 69 73 2b 73 6f 75 72 63 65
2b 49 50 2b 61 64 64 72 65 73 73 0d 0a 0d 0a 00
```

Removing all the white spaces leads to:

```
2c542df00d2a080027c359620800450001a1f33340004006bd8dc0a8012068d25dfb88900050c9c977901fe5d2bd501800e58a290000504f5354202f63617265657220485454502f312e310d0a486f73743a207777772e656c7474616d2e636f6d2e61750d0a557365722d4167656e743a20656c7474616d20726f636b73210d0a4163636570742d4c616e67756167653a20656e2d55532c656e3b713d302e350d0a4163636570742d456e636f64696e673a20677a69702c206465666c6174650d0a436f6f6b69653a205a573168615777394d4759775954426a4d4749794e5441774d446b784d5445784d4451774f4452694d445977595441344e4749774e4445770d0a436f6e74656e742d547970653a206170706c69636174696f6e2f782d7777772d666f726d2d75726c656e636f6465640d0a436f6e74656e742d4c656e6774683a2038310d0a436f6e6e656374696f6e3a20636c6f73650d0a0d0a713d5468652b656d61696c2b616464726573732b69732b68696464656e2b696e2b746869732b7265717565737426626f6e75733d576861742b69732b736f757263652b49502b616464726573730d0a0d0a00
```

## Find out mail address

Now let's start `ipyton`:

```.python
In [1]: data="2c542df00d2a080027c359620800450001a1f33340004006bd8dc0a8012068d25dfb88900050c9c977901fe5d2bd501800e58a290000504f5354202f63617265657220485454502f312e310d0a486f73743a207777772e656c7474616d2e636f6d2e61750d0a557365722d4167656e743a20656c7474616d20726f636b73210d0a4163636570742d4c616e67756167653a20656e2d55532c656e3b713d302e350d0a4163636570742d456e636f64696e673a20677a69702c206465666c6174650d0a436f6f6b69653a205a573168615777394d4759775954426a4d4749794e5441774d446b784d5445784d4451774f4452694d445977595441344e4749774e4445770d0a436f6e74656e742d547970653a206170706c69636174696f6e2f782d7777772d666f726d2d75726c656e636f6465640d0a436f6e74656e742d4c656e6774683a2038310d0a436f6e6e656374696f6e3a20636c6f73650d0a0d0a713d5468652b656d61696c2b616464726573732b69732b68696464656e2b696e2b746869732b7265717565737426626f6e75733d576861742b69732b736f757263652b49502b616464726573730d0a0d0a00"

In [2]: import binascii

In [3]: binascii.unhexlify(data)
Out[3]: ",T-\xf0\r*\x08\x00'\xc3Yb\x08\x00E\x00\x01\xa1\xf33@\x00@\x06\xbd\x8d\xc0\xa8\x01 h\xd2]\xfb\x88\x90\x00P\xc9\xc9w\x90\x1f\xe5\xd2\xbdP\x18\x00\xe5\x8a)\x00\x00POST /career HTTP/1.1\r\nHost: www.elttam.com.au\r\nUser-Agent: elttam rocks!\r\nAccept-Language: en-US,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nCookie: ZW1haWw9MGYwYTBjMGIyNTAwMDkxMTExMDQwODRiMDYwYTA4NGIwNDEw\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 81\r\nConnection: close\r\n\r\nq=The+email+address+is+hidden+in+this+request&bonus=What+is+source+IP+address\r\n\r\n\x00"

In [4]: request=binascii.unhexlify(data)

In [5]: print(request)
'�YE
��3@@����
 h�]���P��w��ҽP��)POST /career HTTP/1.1
Host: www.elttam.com.au
User-Agent: elttam rocks!
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate
Cookie: ZW1haWw9MGYwYTBjMGIyNTAwMDkxMTExMDQwODRiMDYwYTA4NGIwNDEw
Content-Type: application/x-www-form-urlencoded
Content-Length: 81
Connection: close

q=The+email+address+is+hidden+in+this+request&bonus=What+is+source+IP+address
```

Let's have a look at the **cookie**:

```.python
In [6]: cookie="ZW1haWw9MGYwYTBjMGIyNTAwMDkxMTExMDQwODRiMDYwYTA4NGIwNDEw"

In [7]: import base64

In [8]: base64.dec
base64.decode        base64.decodestring  

In [8]: base64.decodestring(cookie)
Out[8]: 'email=0f0a0c0b250009111104084b060a084b0410'
```

## Extract IP address

First I saved the binary data as a file:

```.python
In [24]: f=open("/tmp/1.pcap", "wb")
In [25]: f.write(request)
In [26]: f.close()
```

`file` will tell you nothing:

```.python
In [28]: !file /tmp/1.pcap
/tmp/1.pcap: data
```

After asking the team for some hint, it then suddenly made sense: The whole request was some **raw bytes**  extract from some network packet. After capturing some `GET` request with `tshark` and exporting the raw bytes, I could see some similarities:

```.shell
blackarch :: /tmp » hexdump -C 2.pcap
00000000  52 54 00 e6 70 bf 52 54  00 65 0a b3 08 00 45 00  |RT..p.RT.e....E.|
00000010  00 7d 26 89 40 00 40 06  5a 9e c0 a8 7a f2 3e d6  |.}&.@.@.Z...z.>.|
00000020  3e e3 a6 6c 00 50 24 4d  56 73 cc bc 8e e1 80 18  |>..l.P$MVs......|
00000030  00 e5 b9 c3 00 00 01 01  08 0a 00 05 70 f6 06 48  |............p..H|
00000040  74 42 47 45 54 20 2f 20  48 54 54 50 2f 31 2e 31  |tBGET / HTTP/1.1|
00000050  0d 0a 48 6f 73 74 3a 20  67 6f 6f 67 6c 65 2e 64  |..Host: google.d|
00000060  65 0d 0a 55 73 65 72 2d  41 67 65 6e 74 3a 20 63  |e..User-Agent: c|
00000070  75 72 6c 2f 37 2e 35 32  2e 31 0d 0a 41 63 63 65  |url/7.52.1..Acce|
00000080  70 74 3a 20 2a 2f 2a 0d  0a 0d 0a                 |pt: */*....|
0000008b
blackarch :: /tmp » hexdump -C 1.pcap
00000000  2c 54 2d f0 0d 2a 08 00  27 c3 59 62 08 00 45 00  |,T-..*..'.Yb..E.|
00000010  01 a1 f3 33 40 00 40 06  bd 8d c0 a8 01 20 68 d2  |...3@.@...... h.|
00000020  5d fb 88 90 00 50 c9 c9  77 90 1f e5 d2 bd 50 18  |]....P..w.....P.|
00000030  00 e5 8a 29 00 00 50 4f  53 54 20 2f 63 61 72 65  |...)..POST /care|
00000040  65 72 20 48 54 54 50 2f  31 2e 31 0d 0a 48 6f 73  |er HTTP/1.1..Hos|
00000050  74 3a 20 77 77 77 2e 65  6c 74 74 61 6d 2e 63 6f  |t: www.elttam.co|
00000060  6d 2e 61 75 0d 0a 55 73  65 72 2d 41 67 65 6e 74  |m.au..User-Agent|
00000070  3a 20 65 6c 74 74 61 6d  20 72 6f 63 6b 73 21 0d  |: elttam rocks!.|
00000080  0a 41 63 63 65 70 74 2d  4c 61 6e 67 75 61 67 65  |.Accept-Language|
00000090  3a 20 65 6e 2d 55 53 2c  65 6e 3b 71 3d 30 2e 35  |: en-US,en;q=0.5|
000000a0  0d 0a 41 63 63 65 70 74  2d 45 6e 63 6f 64 69 6e  |..Accept-Encodin|
000000b0  67 3a 20 67 7a 69 70 2c  20 64 65 66 6c 61 74 65  |g: gzip, deflate|
000000c0  0d 0a 43 6f 6f 6b 69 65  3a 20 5a 57 31 68 61 57  |..Cookie: ZW1haW|
000000d0  77 39 4d 47 59 77 59 54  42 6a 4d 47 49 79 4e 54  |w9MGYwYTBjMGIyNT|
000000e0  41 77 4d 44 6b 78 4d 54  45 78 4d 44 51 77 4f 44  |AwMDkxMTExMDQwOD|
000000f0  52 69 4d 44 59 77 59 54  41 34 4e 47 49 77 4e 44  |RiMDYwYTA4NGIwND|
00000100  45 77 0d 0a 43 6f 6e 74  65 6e 74 2d 54 79 70 65  |Ew..Content-Type|
00000110  3a 20 61 70 70 6c 69 63  61 74 69 6f 6e 2f 78 2d  |: application/x-|
00000120  77 77 77 2d 66 6f 72 6d  2d 75 72 6c 65 6e 63 6f  |www-form-urlenco|
00000130  64 65 64 0d 0a 43 6f 6e  74 65 6e 74 2d 4c 65 6e  |ded..Content-Len|
00000140  67 74 68 3a 20 38 31 0d  0a 43 6f 6e 6e 65 63 74  |gth: 81..Connect|
00000150  69 6f 6e 3a 20 63 6c 6f  73 65 0d 0a 0d 0a 71 3d  |ion: close....q=|
00000160  54 68 65 2b 65 6d 61 69  6c 2b 61 64 64 72 65 73  |The+email+addres|
00000170  73 2b 69 73 2b 68 69 64  64 65 6e 2b 69 6e 2b 74  |s+is+hidden+in+t|
```

And then I tried to think of ways how to **build** packets out of raw bytes. And then old-good [scapy](http://www.secdev.org/projects/scapy/) came to my mind:

```.shell
(env) blackarch :: /tmp » scapy
INFO: Can't import python gnuplot wrapper . Won't be able to plot.
INFO: Can't import PyX. Won't be able to use psdump() or pdfdump().
WARNING: No route found for IPv6 destination :: (no default route?)
INFO: Can't import python Crypto lib. Won't be able to decrypt WEP.
INFO: Can't import python Crypto lib. Disabled certificate manipulation tools
Welcome to Scapy (2.3.2)
>>> data="2c542df00d2a080027c359620800450001a1f33340004006bd8dc0a8012068d25dfb88900050c9c977901fe5d2bd501800e58a290000504f5354202f63617265657220485454502f312e310d0a486f73743a207777772e656c7474616d2e636f6d2e61750d0a557365722d4167656e743a20656c7474616d20726f636b73210d0a4163636570742d4c616e67756167653a20656e2d55532c656e3b713d302e350d0a4163636570742d456e636f64696e673a20677a69702c206465666c6174650d0a436f6f6b69653a205a573168615777394d4759775954426a4d4749794e5441774d446b784d5445784d4451774f4452694d445977595441344e4749774e4445770d0a436f6e74656e742d547970653a206170706c69636174696f6e2f782d7777772d666f726d2d75726c656e636f6465640d0a436f6e74656e742d4c656e6774683a2038310d0a436f6e6e656374696f6e3a20636c6f73650d0a0d0a713d5468652b656d61696c2b616464726573732b69732b68696464656e2b696e2b746869732b7265717565737426626f6e75733d576861742b69732b736f757263652b49502b616464726573730d0a0d0a00"
>>> import binascii
>>> r=binascii.unhexlify(data)
>>> Ether(r)
<Ether  dst=2c:54:2d:f0:0d:2a src=08:00:27:c3:59:62 type=IPv4 |<IP  version=4L ihl=5L tos=0x0 len=417 id=62259 flags=DF frag=0L ttl=64 proto=tcp chksum=0xbd8d src=192.168.1.32 dst=104.210.93.251 options=[] |<TCP  sport=34960 dport=www seq=3385423760 ack=535155389 dataofs=5L reserved=0L flags=PA window=229 chksum=0x8a29 urgptr=0 options=[] |<Raw  load='POST /career HTTP/1.1\r\nHost: www.elttam.com.au\r\nUser-Agent: elttam rocks!\r\nAccept-Language: en-US,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nCookie: ZW1haWw9MGYwYTBjMGIyNTAwMDkxMTExMDQwODRiMDYwYTA4NGIwNDEw\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 81\r\nConnection: close\r\n\r\nq=The+email+address+is+hidden+in+this+request&bonus=What+is+source+IP+address\r\n\r\n' |<Padding  load='\x00' |>>>>>
```


