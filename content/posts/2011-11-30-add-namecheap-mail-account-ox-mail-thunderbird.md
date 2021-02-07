+++
title = "Add Namecheap Mail account (OX Mail) to Thunderbird"
author = "Victor"
date = "2011-11-30"
tags = ["mail", "tls", "ssl"]
category = "notes"
+++

I thought this could be useful for other Namecheap customers. `'Namecheap`'s Open-Xchange servers use only `'secure`' connnections (STARTTLS, SSL/TLS). Supposing `domain.com` is the domain you have purchased, you'll have to configure Thunderbird using these settings:  

~~~.shell  
; Username  
: your email address (@domain.com)  
; Password  
: password you have set in the Namecheap configuration menu  
; Incoming/outgoing servers  
: oxmail.registrar-servers.com  
; Incoming server type  
: IMAP or POP3  
; Outgoing server (SMTP)  
: 465 port for SSL, 25 or 26 for TLS  
; Incoming server (IMAP)  
: 993 port for SSL, 143 for TLS  
; Incoming server (POP3)  
: 995 port for SSL 110 for TLS
~~~

That should do the work. I use POP3 with SSL/TLS (Port: 995). Be sure you use `'Normal password`' as `authentication method`. Voila !
