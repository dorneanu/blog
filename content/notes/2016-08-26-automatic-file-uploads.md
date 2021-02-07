+++
title = "Automatic file uploads"
author = "Victor Dorneanu"
date = "2016-08-26"
tags = ["burp", "appsec "]
category = "notes"
+++

Uploading files in web applications iw nowadays a common feature. Being able to **automate** this steps using `Burp`, `Curl`, `Python`
& Co. doesn't seem to be an easy task. Basically the automation involves following steps:

* for a given directory of files, repeat the request for each file
* have a look for the status responses to detect anomalies

In Burp you're allowed to copy a certain request as `curl` command which simplifies things. Given a `POST` request Burp will convert 
it to a valid curl command like:

```.shell
curl -i -X 'POST' \
	-H <Header 1> \
	-H <Header 2> \
    --data-binary $'-----------------------------12271989442246301301198248013\x0d\x0aContent-Disposition: form-data; name=\"name\"\x0d\x0a\x0d\x0a<name of file>\x0d\x0a-----------------------------12271989442246301301198248013\x0d\x0aContent-Disposition: form-data; name=\"attachment\"; filename=\"<NAME OF FILE>\"\x0d\x0aContent-Type: image/jpeg\x0d\x0a\x0d\x0a\<CONTENT OF FILE>\x0d\x0a-----------------------------12271989442246301301198248013--\x0d\x0a
	<target url> 
```

Having tried this neat Burp feature, I can tell you that the curl commands won't trigger the **same** requests as in Burp. I don't
know why nor I have not investigated this further. Modifying the curl script will definitely cause you some headaches. Using `Python` and 
`requests` will help you automate your file uploads in a easy way. Here is my gist:

<script src="https://gist.github.com/dorneanu/d87da02b3e883bdc82d79bd0c937926c.js"></script> 
