+++
title = "Coming back to C/C++ after 2 years"
author = "Victor Dorneanu"
date = "2015-04-21"
tags = ["c", "coding"]
category = "blog"
+++

After years of [python](http://blog.dornea.nu/tag/python/) hacking and all kind of projects (like
[netgrafio](https://github.com/dorneanu/netgrafio) or [smalisca](https://github.com/dorneanu/smalisca)) I wanted to do more low-level stuff and refresh my C/C++ skills. I'll try to describe how it feels like coming back to C/C++ after 2 years of coding abstinence.

### It's low.. Very low

Having started a new project I didn't feel like I've forgotten everything. It just felt strange to
**declare** functions and use **header** files. After initial difficulties I was able to run my code and compile it using `-Wall` without any warnings. Perfect. 

The project itself is about implementing SSL/TLS in C since I've never done that before. The executable
will take an *UR*L and optionally a *proxy* as arguments:

~~~
$ ./main -u http://blog.dornea.nu/ -p http://username:password@localhost:8080
~~~

The very first problem I've encountered was **parsing**. While in Python you usually have pretty good
string operations you can apply on your string, in C you have to take of everything. In my case
I had to parse the proxy argument for its specific parts:

* schema
* username
* password
* domain name
* port

And if that wasn't enought, I also have to take care about **error handling** in case the proxy URL is malformed.  Speaking of *error handling*: It was indeed tempted to think of some `try .. catch` construct. Naaah! I remember ... The typical construct you should use:

```c
if (not sth) {
    // this is very bad
    return <whatever>
} else {
    // This is was ok
}
```

Ok. What about **logging**? I remember having implemented some **macros** in the past and finally found this:

```c
#define log_err(M, ...) fprintf(stderr, "ERROR: \t(%s:%d: errno: %s) " M "\n",\     
                       __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__) 

#define log_warn(M, ...) fprintf(stderr, "WARN: \t(%s:%d: errno: %s) " M "\n",\
                        __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__) 
```

Great! At that point if was able to pass arguments to my executable and do some string parsing. 


### Pointers .. and more pointers

I do know some pointers arithmetics. But coming back from **objects** to **pointers** was a big 
mindset change. Almost everything is a pointer to some data structure, to some memory region etc. 
Using pointers the right way has always been a challenge. Let's first have a look at some struct
I'm using to collect information and store global accessible data:

```c
typedef struct globalargs {
    char *prog;
    char *url;
    char *proxy_uri;
    int port;
    int verbose;
    int debug;

    /* Proxy settings */
    char *proxy_username;
    char *proxy_password;
    char *proxy_host;
    int  proxy_port;

} globalargs;
```

So we've got pointers everywhere. I use this struct to collect the CLI arguments using `getopt`. Besides that
I'm using `globalargs` to store information which should be available in all "modules" (I don't have any yet but
just for the explanation ...). But let me explain this using some example:

```c
#include <stdio.h>
#include <stdlib.h>

typedef struct myStruct {
    char *username;
    char *password;
} myStruct;

void change_username1 (char *username) {
    char *tmp_username = "username1";
    username = tmp_username;
}

void change_username2 (char **username) {
    char *tmp_username = "username2";
    *username = tmp_username;
}

int main (int argc, char **argv) {
    myStruct *ms;
    char *a = "username0";

    if (!(ms = malloc(sizeof(myStruct)))) {
        printf("Failed allocating memory!");
        return -1;
    }

    ms->username = a;
    printf("Username: %s\n", ms->username);

    // First change
    change_username1(ms->username);
    printf("Username: %s\n", ms->username);

    // 2nd change
    change_username2(&ms->username);
    printf("Username: %s\n", ms->username);

    return 0;
}
```

When compiled and executed this produces following output:

~~~
$ gcc -Wall -o n n.c && ./n
Username: username0
Username: username0
Username: username2
~~~

As you might have noticed `change_usernam1` doesn't really change the `username` in the `myStruct` structure.
Using **pointers to pointers** I was able to make my desired change. What did I learn from this particular case?
I should definitely improve my pointer arithmetics :)

### Memory management

For almost every data structure memory has to be allocated. While this in OOP (object oriented programming) is usually done 
by just creating a new instance of a new object, in C everything has to be done "manually". In our example allocating memory 
for `myStruct` should be easy and straight forward:

```c
...
    if (!(ms = malloc(sizeof(myStruct)))) {
        printf("Failed allocating memory!");
        return -1;
    }
...
```

And don't forget to `free` your memory! That's it for now. Now happy (C) coding!
