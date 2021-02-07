+++
title = "Fuzzing the hell out of conntrack tools"
date = "2016-10-28"
tags = ["hacking", "fuzz", "networking", "python", "afl", "linux", "appsec"]
category = "blog"
+++

Fuzzing is nowadays **the** attack technique used by a lot of pentesters and security researchers. Whether you're 
looking for vulnerabilities in media files (pictures, videos, audio stuff) or just binary files,
fuzzing is the right approach if you don't want to do some static code analysis or debug the 
hell out of your targets. 

When it comes to fuzzing there are a few tools to mention that have established during the last 
years. One of them is definitely [AFL](http://lcamtuf.coredump.cx/afl/). AFL has a very powerful
[fuzzing engine](https://lcamtuf.blogspot.de/2014/08/binary-fuzzing-strategies-what-works.html)
and a lot of [vulnerabilities](http://lcamtuf.coredump.cx/afl/#bugs) have been identified by AFL.
However, AFL's simpleness of using files as parameters to your target binary, is also one big 
disadvantage. While in most cases you should be fine by reading your input from files, when dealing
with **sockets**, the **code** has to be **modified** in order to read input from files instead of sockets.
This step can be very **complex** and involves good C/C++ skills.

After reading ["How I nearly almost saved the Internet"](https://blog.skullsecurity.org/2015/how-i-nearly-almost-saved-the-internet-starring-afl-fuzz-and-dnsmasq) 
I thought it should be an easy task to adapt the code of my target in order
to run it by AFL. This step was indeed very **time-consuming** and was done after endless debug sessions.
Below I'll try to give some overview which steps might be essential in fuzzing your target in an
effective way. Modifying the source code for your needs definitely requires a deep understanding 
of the programms workflow. I hope this post will provide some useful tips how to speed up 
the fuzzing process - whatever your target will be. 

## Motivation

Why would one want to **fuzz** [conntrack-tools](http://conntrack-tools.netfilter.org) anyway? Before we continue: **No 0day here!** 
As sad as it sounds, I wasn't able to find any crashes using `AFL`. But that is no guarantee
for safe, secure code so there might be some vulnerabilities ready to be found. 

As you probably know **software security** doest not only apply to web stuff but also to 
software that runs critical network infrastructure. Since the IT sec community seems to
have a **huge** focus on web applications (it's still the main entry point, right?), a few
people (in relation to the first group mentioned) do have a look at network/system level 
stuff. In my case I wanted to audit and fuzz software that deals with [connection tracking](http://www.iptables.info/en/connection-state.html#COMPLEXPROTOCOLS) management. In my particular case I've used [conntrackd](http://conntrack-tools.netfilter.org/conntrackd.html)
to manage and synchronize the connection tracking information between 2 hosts. 

## Setup

On 2 virtual machines I've downloaded the `conntrack-tools` (also includes `conntrackd`), 
compiled the code and ran the daemons:

{% blockdiag
	nwdiag
	{
	  network nat-network {
		  address = "192.168.122.0/24"

		  nat01 [address = "192.168.122.242"];
		  nat02 [address = "192.168.122.252"];
	  }
	}
%}

So `nat01` and `nat02` were supposed to exchange information about their connection tracking table. 
In a nutshell `conntrackd`:

* **synchronizes** connection tracking states among several replica firewalls
* has **channels** (UDP, TCP)
* has **sync** modes (notrack, ftfw)

Let's have a look at some **configuration** file:

```
Sync {
        Mode FTFW{
        }
    UDP Default {
        IPv4_address 192.168.122.242
        IPv4_Destination_Address 192.168.122.252 
        Port 3780
        Interface ens3 
        SndSocketBuffer 1249280
        RcvSocketBuffer 1249280
        Checksum on
    }
}
``` 

This configuration says:

* **FTFW** sync mode is used
* **own** IP address is `192.168.122.242`
* **destination** IP address for sync is `192.168.122.252`
* use **port** `3780` for sync

Basically this how synchronization works. Of course some details have been ommitted for the sake of 
simplicity. For the detailed configuration please refer to the [documentation](http://conntrack-tools.netfilter.org/manual.html). 
In the end the daemons are started by specifying the config file:

```.shell
$ ./src/conntrackd -C <config file>
...
```

> If you experience some crazy error messages, make sure you have following kernel modules loaded: `af_netlink`

## Network traffic 

If you then **sniff** for packets you'll see some magic packets:

```.shell
$ tshark -nr nat-traffic.pcap -E separator="," -T fields -e udp.srcport -e udp.dstport -e udp.length -e data  | head -n 5
53085,3780,76,110000445815c162000c00000a17680236ef368f000800050000019e00050002060000000008000391f201bb000500040400000000080006000000780008000c7e64b2c3
53085,3780,76,110000445815c163000c00000a17680236ef368f000800050000019e00050002060000000008000391f201bb0005000406000000000800060000001e0008000c7e64b2c3
53085,3780,76,100000445815c164000c00000a216801d83ad4a30008000500000198000500020600000000080003c29a0050000500040100000000080006000000780008000ceb64b2c3
53085,3780,76,110000445815c1aa000c00000a171f0cca0c1b21000800050000019a00050002060000000008000386e600350005000402000000000800060000003c0008000c7e64b2c3
53085,3780,76,110000445815c1ab000c00000a171f0cca0c1b21000800050000019e00050002060000000008000386e60035000500040300000000080006000038400008000c7e64b2c3
```

As you have noticed the `UDP` payloads above are very similar to each other. However, **bigger** payloads were also transmitted:

```.shell
57252,3780,1444,1100004457e14ced000c00000a21680236ef249d000800050000019e000500020600000000080003d9ac01bb000500040300000000080006000038400008000ceb64b
2c31100004457e14cee000c00000a17680236ef22ae000800050000019e000500020600000000080003c0a201bb000500040300000000080006000038400008000c7e64b2c31100004457
e14cef000c00000a176801c3b265ac000800050000019e000500020600000000080003bc700050000500040300000000080006000038400008000c7e64b2c31100004457e14cf0000c000
00a176802b0206cff000800050000019e000500020600000000080003c16401bb000500040300000000080006000038400008000c7e64b2c31100004457e14cf1000c00000a21680136ef208d000800050000019e0005000206000000000800039dc201bb000500040300000000080006000038400008000ceb64b2c31100004457e14cf2000c00000a17680236ef249d000800050000019e000500020600000000080003d12c01bb000500040300000000080006000038400008000c7e64b2c31100004457e14cf3000c00000a21680236ef208d000800050000019e000500020600000000080003be7c01bb000500040300000000080006000038400008000ceb64b2c31100004457e14cf4000c00000a21680236ef37cb000800050000019e000500020600000000080003d4d201bb000500040300000000080006000038400008000ceb64b2c31100004457e14cf5000c00000a21680236ef208d000800050000019e000500020600000000080003de9001bb000500040300000000080006000038400008000ceb64b2c31100004457e14cf6000c00000a21680136ef208d000800050000019e000500020600000000080003bdae01bb000500040300000000080006000038400008000ceb64b2c31100004457e14cf7000c00000a17680336ef22af000800050000019e000500020600000000080003a37a01bb000500040300000000080006000038400008000c7e64b2c31100004457e14cf8000c00000a21680136ef208d000800050000019e0005000206000000000800039c8601bb000500040300000000080006000038400008000ceb64b2c31100004457e14cf9000c00000a21680134314113000800050000019e00050002060000000008000382f401bb000500040300000000080006000038400008000ceb64b2c31100004c57e14cfa000c00000a21680236ef3698000800050000019e000500020600000000080003d27c01bb000500040300000000080006000038400008000ceb64b2c30006000eeb0600001100004457e14cfb000c00000a17680336ef249d000800050000019e000500020600000000080003de7601bb000500040300000000080006000038400008000c7e64b2c31100004457e14cfc000c00000a21680136ef208d000800050000019e0005000206000000000800039ce001bb000500040300000000080006000038400008000ceb64b2c31100004457e14cfd000c00000a176803c01efd70000800050000019e000500020600000000080003b51001bb0005000403000000000800
``` 

## Analysis 

Now what valuable information can we extract from the payloads? Using [scapy](http://www.secdev.org/projects/scapy/) I've did
some basic traffic analysis:

```.python
In [11]: p.payload.payload.show()

###[ UDP ]###
  sport     = 53085
  dport     = nnp
  len       = 76
  chksum    = 0x1aa6
###[ Raw ]###
     load      = '\x11\x00\x00DX\x15\xc1c\x00\x0c\x00\x00\n\x17h\x026\xef6\x8f\x00\x08\x00\x05\x00\x00\x01\x9e\x00\x05\x00\x02\x06\x00\x00\x00\x00\x08\x00\x03\x91\xf2\x01\xbb\x00\x05\x00\x04\x06\x00\x00\x00\x00\x08\x00\x06\x00\x00\x00\x1e\x00\x08\x00\x0c~d\xb2\xc3'
```

Apparently this is no ASCII data (who would have expected that anyway? :) Using `gdb` I wanted to know what's inside the data 
and did some **dynamic analysis**. This way I was able to learn more about the data being passed over the wire and how 
the source code is structured.   

But first I had to make the code debuggable:

```.shell
$ CCFLAGS="-g3 -gdwarf2" ./configure
[...]
```

Afterwards you should be able to **run** it:

```.shell
$ sudo ./src/conntrackd -C conntrackd.conf
```

Sniffing the traffic you should see sth like this:

```.shell
$ sudo tshark -i ens3 -Y udp -E separator="," -T fields -e ip.src -e udp.srcport -e udp.dstport -e udp.length -e data
192.168.122.242,192.168.122.242,48786,3780,16,1a10000858109293
192.168.122.242,192.168.122.242,48786,3780,16,1a10000858109294
192.168.122.242,192.168.122.242,48786,3780,16,1a10000858109295
192.168.122.242,192.168.122.242,48786,3780,16,1a10000858109296
192.168.122.242,192.168.122.242,48786,3780,16,1a10000858109297
192.168.122.242,192.168.122.242,48786,3780,16,1a10000858109298
192.168.122.242,192.168.122.242,48786,3780,16,1a10000858109299
192.168.122.242,192.168.122.242,48786,3780,16,1a1000085810929a
^C8 packets captured
```

The daemon will try to send out some "keep-alive" messages to its counterpart. Now we send those packets
**manually** and debug the interesting part in the code. For packet generation I'll use `scapy` again (running as
**root** since you'll need to create **RAW sockets**):

```.python
In [1]: from scapy.all import *
WARNING: No route found for IPv6 destination :: (no default route?)

In [2]: import binascii

In [3]: p=Ether()/IP(dst="192.168.122.242")/UDP(dport=3780)

In [4]: payload = binascii.unhexlify("1a10000858109293")

In [5]: p/Raw(load=payload)
Out[5]: <Ether  type=IPv4 |<IP  frag=0 proto=udp dst=192.168.122.242 |<UDP  dport=nnp |<Raw  load='\x1a\x10\x00\x08X\x10\x92\x93' |>>>>

In [7]: sendp(p/Raw(load=payload))
.
Sent 1 packets.
```  


### Data flow

After heavy debugging sessions I was able to understand the data flow inside the code. Below I'll try to explain how `conntrackd` basically
works:

1. The **configuration** file gets parsed and several options are set
1. In `src/sync-mode.c` you have [init_sync](http://git.netfilter.org/conntrack-tools/tree/src/sync-mode.c#n362) where a lot of vodoo happens but the most important part is:

```.c
	for (i=0; i<STATE_SYNC(channel)->channel_num; i++) {
		int fd = channel_get_fd(STATE_SYNC(channel)->channel[i]);
		fcntl(fd, F_SETFL, O_NONBLOCK);

		switch(channel_type(STATE_SYNC(channel)->channel[i])) {
		case CHANNEL_T_STREAM:
			register_fd(fd, channel_accept_cb,
					STATE_SYNC(channel)->channel[i],
					STATE(fds));
			break;
		case CHANNEL_T_DATAGRAM:
			register_fd(fd, channel_handler,
					STATE_SYNC(channel)->channel[i],
					STATE(fds));
			break;
		}
	}
```

Depending on the **sync** mode, then for every **channel** a channel **handler** is being registered. This 
will be called every time an "event" occurs, that means a packet arrives:

* for TCP packets (`CHANNEL_T_STREAM`) `channel_accept_cb` will be called
* for UDP datagrams (`CHANNEL_T_DATAGRAM`) `channel_handler` will be called

Since I chose to test for **UDP** packets, let's have a look at [channel_handler](http://git.netfilter.org/conntrack-tools/tree/src/sync-mode.c#n253):

```.c
static void channel_handler(void *data)
{
	struct channel *c = data;
	int k;

	for (k=0; k<CONFIG(event_iterations_limit); k++) {
		if (channel_handler_routine(c) == -1) {
			break;
		}
	}
}
```

This will then call [channel_handler_routine](http://git.netfilter.org/conntrack-tools/tree/src/sync-mode.c#n178):

```.c
static int channel_handler_routine(struct channel *m)
{
	ssize_t numbytes;
	ssize_t remain, pending = cur - __net;
	char *ptr = __net;

	numbytes = channel_recv(m, cur, sizeof(__net) - pending);
	if (numbytes <= 0)
		return -1;

	remain = numbytes;
	if (pending) {
		remain += pending;
		cur = __net;
	}

	while (remain > 0) {
		struct nethdr *net = (struct nethdr *) ptr;
		int len;

		// HERE THE PACKET ITSELF IS ANALYZED
		[...]
	}

	return 0;
}
```

Obvisouly [channel_recv](http://git.netfilter.org/conntrack-tools/tree/src/channel.c#n279) is called:

```.c
int channel_recv(struct channel *c, char *buf, int size)
{
	return c->ops->recv(c->data, buf, size);
}
```

Depending on which channel (variable `c`) is currently active `channel_recv` will then call the channel's
`recv` function. The channel for UDP is stored in a structure called [channel_udp](http://git.netfilter.org/conntrack-tools/tree/src/channel_udp.c#n128):

```.c
struct channel_ops channel_udp = {
	.headersiz	= 28, /* IP header (20 bytes) + UDP header 8 (bytes) */
	.open		= channel_udp_open,
	.close		= channel_udp_close,
	.send		= channel_udp_send,
	.recv		= channel_udp_recv,
	.get_fd		= channel_udp_get_fd,
	.isset		= channel_udp_isset,
	.accept_isset	= channel_udp_accept_isset,
	.stats		= channel_udp_stats,
	.stats_extended = channel_udp_stats_extended,
};
``` 

As you can notice `channel_udp.recv` is a function pointer to [channel_udp_recv](http://git.netfilter.org/conntrack-tools/tree/src/channel_udp.c#n49):

```.c
static int
channel_udp_recv(void *channel, char *buf, int size)
{
	struct udp_channel *m = channel;
	return udp_recv(m->server, buf, size);
}
```

So now we're getting closer to the function that is actually responsible for reading data from the wire. In [udp_recv](http://git.netfilter.org/conntrack-tools/tree/src/udp.c#n193) all the magic happens:

```.c
ssize_t udp_recv(struct udp_sock *m, void *data, int size)
{
	ssize_t ret;
	socklen_t sin_size = sizeof(struct sockaddr_in);

        ret = recvfrom(m->fd,
		       data, 
		       size,
		       0,
		       (struct sockaddr *)&m->addr,
		       &sin_size);
	if (ret == -1) {
		if (errno != EAGAIN)
			m->stats.error++;
		return ret;
	}

	m->stats.bytes += ret;
	m->stats.messages++;

	return ret;
}
```

Nothing special about: Just call `recvfrom`, read the data into `data` and update some statistics. 

### The plan

If we want to do some fuzzing we'll have to modify `udp_recv` to read from some file instead of sockets. Re-writing 
the function was actually a quite easy task:


```.c
#ifdef FUZZ
ssize_t my_udp_recv(struct udp_sock *m, void *data, int size, char *filename) {
    ssize_t ret;
    long f_size;
    FILE *f;
	socklen_t sin_size = sizeof(struct sockaddr_in);

    // Read file
    if (!(f = fopen(CONFIG(fuzz_file), "rb"))) {
        fprintf(stderr, "[FUZZ] Couldn't open file\n");
        exit(1);
    }
  
    // Get file length
    fseek(f, 0L, SEEK_END);
    f_size = ftell(f);
    rewind(f);

    ret = fread(data, f_size, 1, f);
    fclose(f);
	
    if (ret == -1) {
		if (errno != EAGAIN)
			m->stats.error++;
		return ret;
    }
	
    m->stats.bytes += f_size;
	m->stats.messages++;

	return f_size;
}
#endif
``` 

Easy, right? Now `my_udp_recv` will read the file specified by `filename` and store the contents inside `data`. However,
this simple modification implied several changes across the whole base. 

> You can see the whole changes [here](https://github.com/dorneanu/conntrack-fuzzing/search?utf8=✓&q=udp_recv). 

Afterwards I was able to compile the code with this new feature:

```.shell
$ git clone https://github.com/dorneanu/conntrack-fuzzing
$ cd conntrack-fuzzing
$ CFLAGS=-DFUZZ LDFLAGS=-ldl ./configure
[...]
$ ./src/conntrackd --help 
Connection tracking userspace daemon v1.4.4
Usage: ./src/conntrackd [commands] [options]

Daemon mode commands:
  -X [fuzz-file], specify fuzz file
  -d [options]          Run in daemon mode

[...]
```  

Now you can specify a file (`-X`) which will be used as parameter for `my_udp_recv`. The "daemon" will now just read 
the contents of the file, analyze the input and then simply exit.

## Generating input values

Now that I was able to specify files as data input, I had to generate some input examples for the screening process of `AFL`.
By sniffing enought traffic between 2 productive hosts running `conntrackd` I got a **lots** of payloads I could then use
for `AFL`. All I had to do was to store those values as binary files:


```.python
In [1]: payload = "1000003c5815c1c9000c00000a171f0cc3b265fa000800050000019800050002110000000008000305be0035000800060000001e0008000c7e64b2c3"

In [2]: import binascii

In [3]: with open("/tmp/input1", "wb") as f:
   ...:     f.write(binascii.unhexlify(payload))
   ...:     f.close()
   ...: 

In [4]: !hexdump -C /tmp/input1
00000000  10 00 00 3c 58 15 c1 c9  00 0c 00 00 0a 17 1f 0c  |...<X...........|
00000010  c3 b2 65 fa 00 08 00 05  00 00 01 98 00 05 00 02  |..e.............|
00000020  11 00 00 00 00 08 00 03  05 be 00 35 00 08 00 06  |...........5....|
00000030  00 00 00 1e 00 08 00 0c  7e 64 b2 c3              |........~d..|
0000003c
``` 

For my test cases I've chosen ca. 4-5 different payloads and stored them as binary files. Now I was ready to run `AFL`.  

## Prepare for AFL

Inside the project I've then created the directory structure for `AFL`:

```.shell
$ mkdir -p fuzzing/{ftfw,notrack}/input
```

For every sync mode (ftwfw and notrack) I've then copied the input values into `input`. As a next step I had to compile the source using
`afl-gcc`:


```.shell
$ CC=afl-gcc AFL_USE_ASAN=1 CFLAGS=-DFUZZ LDFLAGS=-ldl ./configure
[...]
$ make -j 4
[...]
``` 

## Running AFL

`AFL` itself had to be ran as `root` since `conntrackd` requires privileged permissions:

```.shell
$ echo core >/proc/sys/kernel/core_pattern
$ afl-fuzz -i fuzzing/ftfw/input/ -o fuzzing/ftfw/output ./src/conntrackd -C conntrackd.conf -X @@
[+] You have 2 CPU cores and 1 runnable tasks (utilization: 50%).
[+] Try parallel jobs - see /usr/local/share/doc/afl/parallel_fuzzing.txt.
[*] Checking core_pattern...
[*] Setting up output directories...
[*] Scanning 'fuzzing/ftfw/input/'...
[+] No auto-generated dictionary tokens to reuse.
[*] Creating hard links for all input files...
[*] Validating target binary...
[*] Attempting dry run with 'id:000000,orig:r1'...
[*] Spinning up the fork server...
[+] All right - fork server is up.
    len = 136, map size = 597, exec speed = 3185 us
[*] Attempting dry run with 'id:000001,orig:r2'...
    len = 204, map size = 622, exec speed = 2569 us
[*] Attempting dry run with 'id:000002,orig:r3'...
    len = 68, map size = 619, exec speed = 2545 us
[*] Attempting dry run with 'id:000003,orig:r4'...
    len = 476, map size = 597, exec speed = 2867 us
[!] WARNING: No new instrumentation output, test case may be useless.
[+] All test cases processed.

[!] WARNING: Some test cases look useless. Consider using a smaller set.
[+] Here are some useful stats:

    Test case count : 2 favored, 0 variable, 4 total
       Bitmap range : 597 to 622 bits (average: 608.75 bits)
        Exec timing : 2545 to 3185 us (average: 2792 us)

[*] No -t option specified, so I'll use exec timeout of 20 ms.
[+] All set and ready to roll!

[...]
```

You can also monitor the current input using:

```.shell
$ watch -n1 'cat fuzzing/ftfw/output/.cur_input | hexdump -C'
```

## Results

While the **preparation** steps were indeed time-consuming I think I have definitely improved my `gdb` 
skills looking at the code and trying to understand how things work. Additionally I was able to trace 
the data flow within the code - from the sockets till to the functions where data got analyzed. The 
**fuzzing process** itself was quite straight-forward and mainly managed by `AFL` itself. Unfortunately 
(depends on the perspective you're looking from) I wasn't able to find any crashes inside `conntrack-tools` 
which is actually good. By crashing the daemon some network connectivity would have been heavily 
affected. But again: The fact that I wasn't able to find any issues, is no guarantee for secure software.
Maybe other will have a look at the code and do some **static code analysis**. 

For me personally this was a hell of fun and I'm already looking forward to my next fuzzing project. Stay tuned
and feel free to drop your comments for additional questions/suggestions regarding the steps explained here. 
