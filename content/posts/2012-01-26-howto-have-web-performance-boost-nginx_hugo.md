+++
title = "HowTo: Have a web performance boost with Nginx"
author = "Victor"
date = "2012-01-26"
tags = ["howto", "nginx", "admin"]
category = "blog"
+++

## Why Nginx?

Since I wanted to improve my sites load speed I thought I should look around for some lighttpd-alternatives which I have used for so many years. The really annoying thing about `lighttpd` is its configuration syntax. I don't think it's comprehensive nor easy to learn. Besides that I wanted to have a configuration where `memcahed` plays a major role: Serve static content (html) from memcache. Lighttpd does have some modules/tutorials how to interact with `memcached` but I couldn't find any working configuration. Frustration but also curiosity brought me to `Nginx`. 

  
According to the author Nginx `is an HTTP and reverse proxy server, as well as a mail proxy server`. I thought I should give it a try and test its performance against Lighttpd. Meanwhile I'm using Lighttpd `'AND`' Nginx on my server due to some regexp issue that have to be solved very soon. In that case Nginx acts a a proxy server (see below for configuration stuff).

## Get it!

Before going further you should have the latest (stable) available Nginx version. If you use Debian make sure, you add following to your `/etc/apt/sources.list`:

~~~
deb-src http://nginx.org/packages/debian/ squeeze nginx
~~~

On my system I have currently version `1.0.9-1` installed.

## Basic configuration

The main file for this part is `/etc/nginx/nginx.conf`. This is my `nginx.conf`:

~~~.shell
user www-data;
worker_processes  5;
worker_rlimit_nofile 8192;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  4096;
    use epoll;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    keepalive_requests    50;
    keepalive_timeout     300 300;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #cp_nopush     on;

    # Compression
    gzip on;
    gzip_buffers 16 8k;
    gzip_comp_level 2;
    gzip_http_version 1.1;
    gzip_min_length 10;
    gzip_types text/plain text/css application/x-javascript text/xml;
    gzip_vary on;
    gzip_proxied any;
    gzip_disable "MSIE [1-6].";

    include /etc/nginx/conf.d/*.conf;
}
~~~

I won't explain every line since this is not what I'm supposed to do. Please have a look at the links at the end of this article for additional links.

## vHost configuration

Well this is probably the most interesting part. You should have a configuration file per each vhost located at `/etc/nginx/conf.d/`. In my case the configuration was adapted to Drupals system and needs. Let's have a look:

~~~.shell
server {
        listen 80;
        server_name dornea.nu;

        root /var/www/sites/dornea.nu/htdocs/current; ## <-- Your only path reference.

        ## Drupal Boost with nginx 
        set $boost "";
        set $boost_query "_";

        if ( $request_method = GET ) { 
                set $boost G;
        }

        if ($http_cookie !~ "DRUPAL_UID") {
            set $boost "${boost}D";
        }

        if ($query_string = "") {
            set $boost "${boost}Q";
        }

        if ( -f $document_root/cache/normal/$host$request_uri$boost_query.html ) {
            set $boost "${boost}F";
        }

        if ($boost = GDQF){
            rewrite ^.*$ /cache/normal/$host/$request_uri$boost_query.html break;
        }

        location = /favicon.ico {
                log_not_found off;
                access_log off;
        }

        location = /robots.txt {
                allow all;
                log_not_found off;
                access_log off;
        }

        # This matters if you use drush
        location = /backup {
                auth_basic            "Restricted";
                auth_basic_user_file  /etc/lighttpd/lighttpd_passwords.inc;
                #deny all;
        }

        # Very rarely should these ever be accessed outside of your lan
        location ~* .(txt|log)$ {
                allow 192.168.0.0/16;
                deny all;
        }

        location ~ ..*/.*.php$ {
                return 403;
        }

        location / {

                set $memcached_key "nginx:$request_uri";
                memcached_pass 127.0.0.1:11211;
                default_type       text/html;

                error_page 404 405 502 = @fallback;
                autoindex  on;
        }

        location @fallback {
                try_files $uri @rewrite;
        } 

        location @rewrite {
                # Some modules enforce no slash (/) at the end of the URL
                # Else this rewrite block wouldn't be needed (GlobalRedirect)
                #rewrite ^/system/test/(.*)$     /index.php?q=system/test/$1;
                #rewrite ^/system/files/(.*)$    /index.php?q=system/files/$1;
                rewrite ^/sitemap.xml$          /index.php?q=sitemap.xml;

                rewrite ^/(.*)$                 /index.php?q=$1;
        }

        location ~ .php$ {
                fastcgi_split_path_info ^(.+.php)(/.+)$;
                #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param  VERIFIED $ssl_client_verify;
                fastcgi_param  DN $ssl_client_s_dn;
                fastcgi_intercept_errors on;
        }

        # Fighting with ImageCache? This little gem is amazing.
        location ~ ^/sites/.*/files/imagecache/ {
                try_files $uri @rewrite;
        }
        # Catch image styles for D7 too.
        location ~ ^/sites/.*/files/styles/ {
                try_files $uri @rewrite;
        }

        location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
                expires 24h;
                log_not_found off;
        }
}
~~~

Having Drupals boost module enabled you should have static pages on your server which will be served by the memcache daemon. At the beginning of the configuration nginx checks if any static content should be served at all (ist the user logged in? etc.) If there is a html file which correlates with the URI then nginx will load the files content from memcache. If not: the PHP script will be executed. Speaking of PHP.. Lets have a look at `/etc/nginx/`:

~~~.shell
# cat /etc/nginx/fastcgi_params 
fastcgi_pass   unix:/tmp/fcgi.sock;
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;
fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

fastcgi_index  index.php;

fastcgi_param  REDIRECT_STATUS    200;
~~~

I use a socket instead of child processes. The socket can be created using `/etc/init.d/fastcgi`:

~~~.shell
# cat /etc/init.d/fastcgi 
#!/bin/sh

### BEGIN INIT INFO
# Provides:          fastcgi
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the FastCGI server
# Description:       starts spawn-fcgi using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/php-fastcgi

test -x $DAEMON || exit 0

set -e

RETVAL=0
case "$1" in
  start)
    $DAEMON
    RETVAL=$?
  ;;
  stop)
    killall -9 php5-cgi
    RETVAL=$?
  ;;
  restart)
    killall -9 php5-cgi
    $DAEMON
    RETVAL=$?
  ;;
  *)
    echo "Usage: php-fastcgi {start|stop|restart}"
    exit 1
  ;;
esac
exit $RETVAL
~~~

`php-fastcgi` is located at /usr/local/bin/:

~~~.shell
# cat /usr/local/bin/php-fastcgi 
#!/bin/sh
/usr/bin/spawn-fcgi -F 1 -C 10 -a 127.0.0.1 -s /tmp/fcgi.sock -u www-data -g www-data -f "/usr/bin/php5-cgi -c /etc/php5/cgi/php.ini" -P /var/run/fastcgi-php.pid
~~~

## Nginx as proxy server

As already mentioned nginx can be used as a proxy server. In my case I need nginx to redirect requests on a certain subdomain to `lighttpd` listening to a local interface. The configuration:

~~~.shell
### dl.dornea.nu
server {
    listen 80;
    server_name dl.dornea.nu;
    root /var/www/sites/dl.dornea.nu/htdocs/current;
    rewrite_log on;
    index index.php index.html;

    location / {
        #index index.php index.html;
        proxy_pass         http://127.0.0.1:8080/;
        proxy_redirect     off;
        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_connect_timeout      90;
        proxy_send_timeout         90;
        proxy_read_timeout         90;

        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
    } 

    location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
        expires 24h;
        log_not_found off;
    }
}
~~~

All requests to `'dl.dornea.nu/*`' will be redirected to `'http://127.0.0.1:8080`'. Isn't that simple? Simple configuration, no need for magic!

## Benchmarks

### ab (apache suite) benchmark

#### lighttpd

~~~ shell
$ ab -n 1000 -c 2 http://dornea.nu/
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking dornea.nu (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests

Server Software:        lighttpd/1.4.28
Server Hostname:        dornea.nu
Server Port:            80

Document Path:          /
Document Length:        48134 bytes

Concurrency Level:      2
Time taken for tests:   1438.721 seconds
Complete requests:      1000
Failed requests:        2
   (Connect: 0, Receive: 0, Length: 2, Exceptions: 0)
Write errors:           0
Total transferred:      48619020 bytes
HTML transferred:       48133998 bytes
Requests per second:    0.70 [#/sec] (mean)
Time per request:       2877.441 [ms] (mean)
Time per request:       1438.721 [ms] (mean, across all concurrent requests)
Transfer rate:          33.00 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       36   41  18.8     39     271
Processing:  1369 2836 1314.7   2641   15499
Waiting:     1215 2649 1306.8   2467   15346
Total:       1406 2877 1314.6   2680   15536

Percentage of the requests served within a certain time (ms)
  50%   2680
  66%   2903
  75%   3062
  80%   3208
  90%   3841
  95%   5057
  98%   6924
  99%   9111
 100%  15536 (longest request)
~~~

#### nginx

~~~ shell
$ ab -n 1000 -c 2 http://dornea.nu/
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking dornea.nu (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests

Server Software:        nginx/1.0.9
Server Hostname:        dornea.nu
Server Port:            80

Document Path:          /
Document Length:        48216 bytes

Concurrency Level:      2
Time taken for tests:   133.533 seconds
Complete requests:      1000
Failed requests:        0
Write errors:           0
Total transferred:      48451000 bytes
HTML transferred:       48216000 bytes
Requests per second:    7.49 [#/sec] (mean)
Time per request:       267.065 [ms] (mean)
Time per request:       133.533 [ms] (mean, across all concurrent requests)
Transfer rate:          354.34 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       36   42  18.5     39     268
Processing:   190  225  43.3    212     483
Waiting:       36   43  17.9     40     270
Total:        227  267  52.1    252     713

Percentage of the requests served within a certain time (ms)
  50%    252
  66%    259
  75%    262
  80%    269
  90%    299
  95%    371
  98%    471
  99%    481
 100%    713 (longest request)
~~~

### tools.pingdom.com benchmark

#### lighttpd

![lighttpd](/posts/img/2012/pingdom_nl_dornea.nu_lighttpd.png)

### nginx

![lighttpd](/posts/img/2012/pingdom_nl_dornea.nu_nginx.png)

## Literature

*   Nginx 
    *   http://nginx.org/
    *   http://wiki.nginx.org/Main
*   Basic Configuration 
    *   http://wiki.nginx.org/Configuration
    *   https://calomel.org/nginx.html
