+++
title = "TLS Client authentication using Bitnami Nginx stack"
date = "2016-02-18"
tags = ["nginx", "openssl", "tls", "ssl", "bitnami", "security", "appsec"]
category = "notes"
+++

I've felt that I **have** to write it down since it took almost 2 days to find the root cause of:

~~~ 
[info] 30979#0: *2 client SSL certificate verify error: (18:self signed certificate) while reading client request headers, client: xxx, server: yyy, request: "GET / HTTP/1.1", host: "yyy"
~~~

## Use nginx stack environment

**Not** generating the certificates inside the Bitnami environment was the root cause - at least I think it is. In your Bitnami installation folder (remember the instructions [here](http://blog.dornea.nu/2016/02/12/chrooting-nginx-php-fpm-and-mysql-using-bitnami/)) you'll find a small script called `use_nginxstack`:

~~~ shell
$ cd /home/bitnami/nginxstack
$ ./use_nginxstack
bash-4.3# which openssl
/home/bitnami/nginxstack/common/bin/openssl
~~~

I still don't know **why** but you'll have to use the `openssl` binary inside the nginx stack.

## Generate root CA

First generate a **key** for the root CA and then the correponding **certificate**:

~~~ shell
bash-4.3# openssl genrsa -des3 -out ca.key 4096
bash-4.3# openssl req -new -x509 -days 365 -key ca.key -out ca.crt
~~~

## Generate client certificate

First generate some *client* key (without any password):

~~~ shell
bash-4.3# openssl genrsa -out client.key 2048
~~~

Then generate the client **CSR**:

~~~ shell
bash-4.3# openssl req -new -key client.key -out client.csr
~~~

Then sign the CSR using the previously generated CA:

~~~ shell
bash-4.3# openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt
~~~


## Configure nginx

To make this work you'll have to configure your `nginx`. In your `nginx-vhosts.conf` make sure you have this:

~~~ shell
[...]

server {

    listen    443 ssl;
    [...]

    ssl_client_certificate "/home/bitnami/nginxstack/apps/wiki.dornea.nu/certs/ca.crt";
    ssl_verify_client on;
    [...]
}

[...]
~~~

Now restart your `nginx` and test it:


~~~ shell
$ cd /home/bitnami/nginxstack
$ ./ctlscript.sh restart nginx
$ curl --insecure https://yourdomain/
curl --insecure https://wiki.dornea.nu
<html>
<head><title>400 No required SSL certificate was sent</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>No required SSL certificate was sent</center>
<hr><center>nginx</center>
</body>
</html>
~~~

So your client has to specify the **client** certificate. Let's move on to next section.


## Export/Import client key 

Let's now **export** the client stuff in order to import it into your browser:

~~~ shell
bash-4.3# openssl pkcs12 -export -clcerts -in client.crt -inkey client.key -out client.p12
Enter Export Password:
Verifying - Enter Export Password:
~~~

Now you should be able to import it into your browser. ALternatively you can use `curl` to test it:

~~~ shell
$ curl -v -s -k --key client.key --cert client.crt https://yourdomain
~~~
