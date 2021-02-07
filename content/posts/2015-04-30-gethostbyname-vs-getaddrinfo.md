+++
title = "gethostbyname vs. getaddrinfo"
author = "Victor Dorneanu"
date = "2015-04-30"
tags = ["c", "coding", "networking"]
category = "blog"
+++

After started coding in C [again](http://blog.dornea.nu/2015/04/21/coming-back-to-cc-after-2-years) I've had a look
at some basic network stuff like: **socket()**, **connect()** etc. In order to resolve domain names, one was used to 
use **gethostbyname()**. I've used this function in all my previous C projects but this one seems to be out-dated as 
the main page states:

    The gethostbyname*(), gethostbyaddr*(), herror(), and hstrerror() functions are obsolete.  
    Applications should use getaddrinfo(3), getnameinfo(3), and gai_strerror(3) instead.

The really bad thing about **gethostbyname** is the fact that it doesn't support IPv6. Besides that you would then load
the results into a *struct sockaddr_in*  and use it for your futher calls. A better option is **getaddrinfo()** which 
supports IPv4 and IPv6 as well, does the DNS lookup and fills your structures. Perfect! 

So what do you need? First you'll need some variables:

```c
int status;
char ip_addr[INET6_ADDRSTRLEN];
struct sockaddr_in *remote;
struct addrinfo hints, *res, *p;
```

And then the call:

```c
if ((status=getaddrinfo(server_hostname, port, &hints, &res)) != 0) {
    log_err("getaddrinfo failed: %s", gai_strerror(status));
    return -1;
}

```

`res` is a linked list which has to be looped to fetch the results:

```c
while (p = res; p != NULL; p = p->ai_next) {
    void *addr;
    remote = (struct sockaddr_in *)p->ai_addr;
    addr = &(remote->sin_addr);

    // Convert IP to string
    inet_ntop(p->ai_family, addr, ip_addr, sizeof(ip_addr));

    printf("%s\n", ip_addr);
}
```

Now you could create your socket, connect to the host, read data and so on:

```c
if ((socketfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol)) < 0) {
    log_err("Failed creating socket!");
    return -1;
