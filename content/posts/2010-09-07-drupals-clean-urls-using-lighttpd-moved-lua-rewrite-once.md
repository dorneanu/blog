+++
title = "Drupals clean urls using Lighttpd: Moved from Lua to rewrite-once"
author = "Victor"
date = "2010-09-07"
tags = ["coding", "web", "lighttpd", "drupal", "admin"]
category = "notes"
+++

I've been using Lighttpd + Drupal for a long time. In order to have those sexy clean urls, you'll have to do some rewrite stuff. A few months ago I found this Lua script, which served its purpose without any complications.

~~~.lua
-- little helper function
function file_exists(path)
local attr = lighty.stat(path)
if (attr) then
return true
else
return false
end
end
function removePrefix(str, prefix)
return str:sub(1,#prefix+1) == prefix.."/" and str:sub(#prefix+2)
end

-- prefix without the trailing slash
local prefix = ''

-- the magic
if (not file_exists(lighty.env["physical.path"])) then
-- file still missing. pass it to the fastcgi backend
request_uri = removePrefix(lighty.env["uri.path"], prefix)
if request_uri then
lighty.env["uri.path"] = prefix .. "/index.php"
local uriquery = lighty.env["uri.query"] or ""
lighty.env["uri.query"] = uriquery .. (uriquery ~= "" and "&" or "") .. "q=" .. request_uri
lighty.env["physical.rel-path"] = lighty.env["uri.path"]
lighty.env["request.orig-uri"] = lighty.env["request.uri"]
lighty.env["physical.path"] = lighty.env["physical.doc-root"] .. lighty.env["physical.rel-path"]
end
end
-- fallthrough will put it back into the lighty request loop
-- that means we get the 304 handling for free.
~~~

Your `lighttpd.conf` should include - somewhere! - this lines:

~~~.shell
# Make Drupal's url SEXY
magnet.attract-physical-path-to = ( "/etc/lighttpd/drupal.lua" )
~~~

Well.. That's now history! I found a better way to do that rewritting:

~~~.shell
url.rewrite-once = (
"^/system/test/(.*)$" => "/index.php?q=system/test/$1",
"^/search/node/(.*)$" => "/index.php?q=search/node/$1",
"^/([^.?]*)?(.*)$" => "/index.php?q=$1&$2",
"^/([^.?]*)$" => "/index.php?q=$1"
)
~~~

That should do the work. If any troubles, just let me know!
