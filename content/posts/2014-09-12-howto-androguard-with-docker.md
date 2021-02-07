+++
title = "HowTo: Androguard with Docker"
date = "2014-09-12"
tags = ["ipython", "python", "androguard", "android", "docker", "howto", "networking", "mobile", "appsec", "iptables"] 
author = "Victor Dorneanu"
category = "blog"
+++

Meanwhile I think I've felt in love with *Androguard*. I love its Pythonic way handling things and its visualizations features. As many of you have noticed, you can run Androguard inside a *Docker* container. I've never used Docker before so it was about time. You can find some general information about the installation process on Arch Linux at [this](https://docs.docker.com/installation/archlinux/) address.

### Extensions


```
# Install extensions
# <!-- collapse=True -->
%install_ext https://raw.githubusercontent.com/dorneanu/ipython/master/extensions/diagmagic.py
    
# Then load extensions
%load_ext diagmagic
```

    Installed diagmagic.py. To use it, type:
      %load_ext diagmagic
    The diagmagic extension is already loaded. To reload it, use:
      %reload_ext diagmagic


On my main pentest machine (kudoz to @blackarch) I've installed docker and followed these instructions. Here is my service file:


```
!cat /etc/systemd/system/docker.service
```

    .include /usr/lib/systemd/system/docker.service
    [Service]
    # assume 192.168.1.1 is your proxy server, don't use 127.0.0.1
    #Environment="http_proxy=192.168.1.1:3128"
    ExecStart=
    ExecStart=/usr/bin/docker -d -g /home/cyneox/work/docker


I've added myself to the *docker* group in order to be able to start docker as a regular user:

~~~ shell
# sudo gpasswd -a cyneox docker
~~~

Afterwards make sure you enable the service:

~~~ shell
# sudo systemctl enable docker
~~~

Now make sure you do a reboot (Windows style :D).


```bash
%%bash
# Check if docker is running
sudo systemctl start docker
ps -ax | grep docker
```

      836 ?        Ssl    0:00 /usr/bin/docker -d -g /home/cyneox/work/docker



```
!docker info
```

    Containers: 0
    Images: 0
    Storage Driver: devicemapper
     Pool Name: docker-8:1-385640-pool
     Pool Blocksize: 64 Kb
     Data file: /home/cyneox/work/docker/devicemapper/devicemapper/data
     Metadata file: /home/cyneox/work/docker/devicemapper/devicemapper/metadata
     Data Space Used: 291.5 Mb
     Data Space Total: 102400.0 Mb
     Metadata Space Used: 0.7 Mb
     Metadata Space Total: 2048.0 Mb
    Execution Driver: native-0.2
    Kernel Version: 3.16.1-1-ARCH
    Operating System: Arch Linux
    WARNING: No swap limit support


## Install Androguard

I could find 3 maintained dockerized Android images:
    
1. https://github.com/adepasquale/docker-androguard
1. https://github.com/dweinstein/dockerfile-androguard
1. https://github.com/aikinci/androguard

The [2nd](https://github.com/dweinstein/dockerfile-androguard) one started automatically *androguard* so you couldn't tweak the underlying system. So I've decided to look at [@aikinci](https://github.com/aikinci)'s androguard docker container. 


```
!docker run -it -v ~/samples/:/root/samples/ honeynet/androguard 
```

    Unable to find image 'honeynet/androguard' locally
    Pulling repository honeynet/androguard
    
    [1B
    [0B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [1B
    [36B]0;root@de3fbe90bdde: ~root@de3fbe90bdde:~# ^C
    ]0;root@de3fbe90bdde: ~root@de3fbe90bdde:~# 
    ]0;root@de3fbe90bdde: ~root@de3fbe90bdde:~# 

It must say that was pretty **fast**. And **easy** to do! In the end you'll get a root bash prompt. Since the image does not provide all the tools I need, you'll have to install them manually. After you have `exit`ed from the container you can attach it again. But first lets see which container are currently active:


```
!docker ps -a
```

    CONTAINER ID        IMAGE                        COMMAND             CREATED             STATUS              PORTS               NAMES
    de3fbe90bdde        honeynet/androguard:latest   "/bin/bash"         5 minutes ago       Up 5 minutes                            sleepy_lalande      


Now you can re-attach to a specific container by using `docker attach`:
    
~~~ shell
# docker attach de3fbe90bdde
root@de3fbe90bdde:~# 
~~~

Now I've installed some additional packages:

~~~ shell
root@de3fbe90bdde:~# apt-get install openssh-server ipython ipython-notebook vim
...
~~~

Now change the `root` password:

~~~ shell
root@de3fbe90bdde:~# passwd
...
~~~

Start SSH server:

~~~ shell
root@de3fbe90bdde:~# /etc/init.d/sshd start
...
~~~

Now **most important**: You'll have to **commit** your change to the image otherwise all changes will be lost on next start. On the maching running docker run:

~~~ shell
# docker commit de3fbe90bdde
~~~

## Network with docker

When started docker creates a new virtual interface on the **host** machine called `docker0` ([more](https://docs.docker.com/articles/networking/)):


```
!ifconfig docker0
```

    docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
            inet 172.17.42.1  netmask 255.255.0.0  broadcast 0.0.0.0
            inet6 fe80::bd01:3011:3b12:b866  prefixlen 64  scopeid 0x20<link>
            ether 56:84:7a:fe:97:99  txqueuelen 0  (Ethernet)
            RX packets 0  bytes 0 (0.0 B)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 0  bytes 0 (0.0 B)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
    


As you can see docker choosed a subnet and assigned an IP address to that interface. What about the **guest** machine?

~~~ shell
root@de3fbe90bdde:~# ifconfig -a
eth0      Link encap:Ethernet  HWaddr 02:5b:c7:1e:a8:26  
          inet addr:172.17.0.2  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::5b:c7ff:fe1e:a826/64 Scope:Link
          UP BROADCAST RUNNING  MTU:1500  Metric:1
          RX packets:2225 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1949 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:17216525 (17.2 MB)  TX bytes:134553 (134.5 KB)
~~~
                                                                                                                                

Can I reach the container within the host machine?


```
!ping -c 4 172.17.0.2
```

    PING 172.17.0.2 (172.17.0.2) 56(84) bytes of data.
    64 bytes from 172.17.0.2: icmp_seq=1 ttl=64 time=0.086 ms
    64 bytes from 172.17.0.2: icmp_seq=2 ttl=64 time=0.118 ms
    64 bytes from 172.17.0.2: icmp_seq=3 ttl=64 time=0.131 ms
    64 bytes from 172.17.0.2: icmp_seq=4 ttl=64 time=0.099 ms
    
    --- 172.17.0.2 ping statistics ---
    4 packets transmitted, 4 received, 0% packet loss, time 2997ms
    rtt min/avg/max/mdev = 0.086/0.108/0.131/0.020 ms


Looks good! Well before I go to the next steps let me show my current pentest setup.

## Pentest setup


```
%%blockdiag
// <!-- collapse=True -->
blockdiag admin {
    // A and B belong to first group.
    group first_group {
        label = "";
        color = "#FFF";
        Arch[label = "Arch Linux Host"];
        group kvm_group {
            label = "KVM/QEMU";
            textcolor = "#FF0000";
            color = "#EFEFEF";
    

            KaliLinux[label = "Kali Linux"];
            Windows[label = "Windows Pentest"];
            shape = line;
            style = dashed;
            
            group blackarch {
                label = "";
                textcolor = "#FF0000";
                color = "#EFEFEF";
                BlackArch[label = "BlackArch Host"];
    
               group docker {
                  // Set group-label
                  label = "";

                  // Set background-color to this group.
                  color = "#77FF77";

                  // Set textcolor to this group
                  textcolor = "#FF0000";
                  shape = line;

                  Docker;
                  Docker -> Androguard;
                  Docker -> Container1;
                  Docker -> ContainerX;
               }
            }
        }
    }

   // E, F and G belong to second group.


   Arch -> BlackArch;
   Arch -> KaliLinux;
   Arch -> Windows;
   BlackArch -> Docker;
    
}
```


    
![png](output_23_0.png)
    


On my physical machine (`Arch Linux Host`) I run several `QEMU` instances:

* Kali Linux (Pentest)
* Windows (Pentest)
* BlackArch (Pentest)

## A little bit of networking

**Inside** `BlackArch` I run docker which manages several containers. Regarding the networking part this is what I want to achieve:

1. Be able to access `Androguard` from `Arch Linux Host`
1. Be able to access `Androguard` from `BlackArch Host`
1. Be able to access the *Internet* from `Androguard`

The first one is the most important to me, since I want to access the Androguard container **directly** - preferably through SSH. Since the Àndroguard machine gets a private IP address, it's obvious I can't access it - yet. The packets must be routed though `BlackArch Host`. Let's check IPv4 forwarding:


```
!sysctl net.ipv4.conf.all.forwarding
```

    net.ipv4.conf.all.forwarding = 1


Ok for now. The Docker [documentation](https://docs.docker.com/articles/networking/) states:

> By default Docker containers can make connections to the outside world, but the outside world cannot connect to containers. Each outgoing connection will appear to originate from one of the host machine's own IP addresses thanks to an iptables masquerading rule on the host machine that the Docker server creates when it starts

After starting the Androguard container, let's check the firewall rules:


```
!sudo iptables -t nat -L
```

    Chain PREROUTING (policy ACCEPT)
    target     prot opt source               destination         
    DOCKER     all  --  anywhere             anywhere             ADDRTYPE match dst-type LOCAL
    
    Chain INPUT (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain OUTPUT (policy ACCEPT)
    target     prot opt source               destination         
    DOCKER     all  --  anywhere            !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
    
    Chain POSTROUTING (policy ACCEPT)
    target     prot opt source               destination         
    MASQUERADE  all  --  localhost/16         anywhere            
    
    Chain DOCKER (2 references)
    target     prot opt source               destination         


Having a futher look at the documentaton, I've found this:

>More convenient is the -p SPEC or --publish=SPEC option which lets you be explicit about exactly which external port on the Docker server — which can be any port at all, not just those in the 49000–49900 block — you want mapped to which port in the container.

Now, let's stop the container and restart it again with the `-p` paramater:


```
!docker ps -a
```

    CONTAINER ID        IMAGE                        COMMAND             CREATED             STATUS                     PORTS               NAMES
    534dc09cc451        honeynet/androguard:latest   "/bin/bash"         14 seconds ago      Exited (0) 8 seconds ago                       sleepy_mcclintock   



```bash
%%bash
docker stop 534dc09cc451
docker rm 534dc09cc451
```

    534dc09cc451
    534dc09cc451



```
!docker ps -a
```

    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES



```
!docker run -t -i -p 22 honeynet/androguard 
```

    ]0;root@469eced649c1: ~root@469eced649c1:~# ^C
    ]0;root@469eced649c1: ~root@469eced649c1:~# 
    ]0;root@469eced649c1: ~root@469eced649c1:~# 

Now let's check iptables again:


```
!sudo iptables -t nat -L
```

    Chain PREROUTING (policy ACCEPT)
    target     prot opt source               destination         
    DOCKER     all  --  anywhere             anywhere             ADDRTYPE match dst-type LOCAL
    
    Chain INPUT (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain OUTPUT (policy ACCEPT)
    target     prot opt source               destination         
    DOCKER     all  --  anywhere            !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
    
    Chain POSTROUTING (policy ACCEPT)
    target     prot opt source               destination         
    MASQUERADE  all  --  localhost/16         anywhere            
    
    Chain DOCKER (2 references)
    target     prot opt source               destination         
    DNAT       tcp  --  anywhere             anywhere             tcp dpt:49154 to:172.17.0.4:22


As you can see in the last line all packets sent to **localhost:49154** (which is `BlackArch Host`) will be forwarded to **172.17.0.4:22**. Bingo! On `Arch Linux Host` I try to reach `Androguard`:

~~~ shell
# telnet blackarch.local 49154
Trying 10.0.1.92...
Connected to blackarch.local.
Escape character is '^]'.
SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2
^C^C
Connection closed by foreign host.
~~~

Perfect!

## Accessing IPython on Androguard

Now you could use port forwarding to access services on `Androguard` through the SSH tunnel. On the `Androguard` machine I usually start `ipython-notebook` to take notes etc. I usually run it as:

~~~ shell
root@469eced649c1:~/ipython# ipython notebook --no-browser --port 7000
2014-09-11 16:48:11.330 [NotebookApp] Created profile dir: u'/root/.ipython/profile_default'
2014-09-11 16:48:11.336 [NotebookApp] Using system MathJax
2014-09-11 16:48:11.350 [NotebookApp] Serving notebooks from local directory: /root/ipython
2014-09-11 16:48:11.350 [NotebookApp] The IPython Notebook is running at: http://127.0.0.1:7000/
2014-09-11 16:48:11.350 [NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
...
~~~

On `ArchLinux Host` I run:

~~~ shell
# ssh -L localhost:7777:localhost:7000 root@blackarch.local -p 49154
root@blackarch.local's password: 
Welcome to Ubuntu 14.04 LTS (GNU/Linux 3.2.0-37-generic x86_64)

 * Documentation:  https://help.ubuntu.com/

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

root@469eced649c1:~# 
~~~

As you can see I've successfully logged in into the `Androguard` machine through `BlackArch Host` using [DNAT](http://en.wikipedia.org/wiki/Network_address_translation#DNAT). On `ArchLinux Host` I can open the browser and point to `http://localhost:7777` which connects to `IPython` on the `Androguard` machine. 
