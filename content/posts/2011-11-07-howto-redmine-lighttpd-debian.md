+++
title = "HowTo: Redmine, Lighttpd with Debian"
author = "Victor"
date = "2011-11-07"
tags = ["howto", "web", "lighttpd", "admin", "debian"]
category = "blog"
+++

I'll just post my `lighttpd.conf`. The rest can be easily found on the Internet.

~~~.shell
$HTTP["host"] =~ "^dev.dornea.nu$" {
        evhost.path-pattern = "/home/redmine/current/public"
        server.follow-symlink = "enable"
        
        server.indexfiles = ( "dispatch.fcgi" )
        server.error-handler-404 = "/dispatch.fcgi"

        #dir-listing.activate = "enable"
        
        url.rewrite-once = (
            "^/(.*..+(?!html))$" =&gt; "$0",
            "^/(.*).(.*)"        =&gt; "$0",
        )
 
        fastcgi.server      = ( ".fcgi" =&gt; ( "redmine" =&gt; (
                "min-procs"       =&gt; 1,
                "max-procs"       =&gt; 5,
                "socket" =&gt; "/tmp/redmine.socket",
                "bin-path" =&gt; "/usr/bin/ruby /home/redmine/current/public/dispatch.fcgi",
                "bin-environment" =&gt; ( "RAILS_ENV" =&gt; "production" )
        ) ) )

    }
~~~

My redmine installation can be found under **/home/redmine/current**
