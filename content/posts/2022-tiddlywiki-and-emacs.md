+++
title = "TiddlyWiki and Emacs"
author = ["Victor Dorneanu"]
date = 2022-07-12T07:00:00+02:00
lastmod = 2022-07-13T15:49:41+02:00
tags = ["emacs", "tiddlywiki", "elisp"]
draft = false
+++

Since my [last post on reddit](https://www.reddit.com/r/emacs/comments/pkuhqd/emacs_and_tiddlywiki_anyone/) asking for some help regarding Emacs and TiddlyWikis REST API
I gained some `elisp` knowledge I'd like to share.
{{% sidenote %}}
Maybe you want to go directly to the [Emacs configuration](https://github.com/dorneanu/dotfiles/blob/master/dot_doom.d/config.org#tiddlywiki).
{{% /sidenote %}}


## TiddlyWiki 5 {#tiddlywiki-5}

For those of you who haven't heard of TiddlyWiki yet:

> TiddlyWiki is a personal wiki and a non-linear notebook for organising and
> sharing complex information. It is an open-source single page application wiki
> in the form of a single HTML file that includes CSS, JavaScript, and the
> content. It is designed to be easy to customize and re-shape depending on
> application. It facilitates re-use of content by dividing it into small pieces
> called Tiddlers. -- [Wikipedia](https://en.wikipedia.org/wiki/TiddlyWiki)

You use the wiki as a **single HTML page** or via `nodejs`. With `nodejs` we can talk to
Tiddlywiki via its REST API.
{{% sidenote %}}
I've been using TiddlyWikis REST API to serve a instance via AWS Lambda and DynamoDB
for the data storage. The project itself is called [widdly](https://github.com/dorneanu/widdly) and there is also a demo at
[tiddly.info/serverless](https://tiddly.info/serverless).
{{% /sidenote %}} Every single page inside the wiki is called `tiddler`.

> On the philosophy of [tiddlers](https://tiddlywiki.com/static/Philosophy%2520of%2520Tiddlers.html): "The purpose of recording and organising information is so that it can be used again. The value of recorded information is directly proportional to the ease with which it can be re-used."

A `tiddler` has following [format](https://tiddlywiki.com/prerelease/static/TiddlyWeb%2520JSON%2520tiddler%2520format.html):

```json
{
	"title": "HelloThere",
	"tags": "FirstTag [[Second Tag]]",
	"my-custom-field": "Field value"
}
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Tiddler JSON format
</div>

Next I'll show you how to setup your TiddlyWiki instance.
{{% sidenote %}}
I have a public "digital garden" aka wiki available at <https://brainfck.org>
{{% /sidenote %}}


### Basic setup {#basic-setup}

I use `node.js` to run my TiddlyWiki instance.
{{% sidenote %}}
The REST API is only available within the nodeJS environment.
{{% /sidenote %}} For isolation reasons I use `Docker` to run it. Here is my `Dockerfile`:

<a id="code-snippet--tw5-dockerfile"></a>
```docker
FROM mhart/alpine-node

# Create a group and user
RUN addgroup -g 984 -S appgroup
RUN adduser -h /DATA/wiki -u 1000 -S appuser -G appgroup

# Tell docker that all future commands should run as the appuser user

ENV TW_BASE=/DATA TW_NAME=wiki TW_USER="xxx" TW_PASSWORD="xxx" TW_LAZY=""
ENV TW_PATH ${TW_BASE}/${TW_NAME}

WORKDIR ${TW_BASE}

RUN npm install -g npm@8.10.0
RUN npm install -g tiddlywiki http-server

# COPY plugins/felixhayashi /usr/lib/node_modules/tiddlywiki/plugins/felixhayashi
# RUN ls -la /usr/lib/node_modules/tiddlywiki/plugins
COPY start.sh ${TW_BASE}

# Change ownership
RUN chown appuser:appgroup /DATA/start.sh

EXPOSE 8181

USER appuser

ENTRYPOINT ["/DATA/start.sh"]
CMD ["/DATA/start.sh"]
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--tw5-dockerfile">Code Snippet 2</a>:</span>
  Dockerfile for running TiddlyWiki 5 using alpine
</div>

And as for `start.sh`:

<a id="code-snippet--tw5-docker-start-sh"></a>
```sh
#!/usr/bin/env sh

# Start image server
http-server -p 82 /DATA/wiki/images &

# Start tiddlywiki server
tiddlywiki /DATA/wiki --listen port=8181 host=0.0.0.0 csrf-disable=yes
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--tw5-docker-start-sh">Code Snippet 3</a>:</span>
  Bash script to start a simple http-server (for uploading images) and the tiddlywiki server instance (node.js)
</div>

Now you should be able to call the API (via `curl` for example):

<a id="code-snippet--tw5-get-tiddler-emacs"></a>
```sh
curl http://127.0.0.1:8181/recipes/default/tiddlers/Emacs | jq
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--tw5-get-tiddler-emacs">Code Snippet 4</a>:</span>
  Now you should be able to call the API (via <code>curl</code> for example).
</div>

<a id="code-snippet--tw5-get-tiddler-emacs-response"></a>
```sh
{
  "title": "Emacs",
  "created": "20210623082136326",
  "modified": "20210623082138258",
  "tags": "Topics",
  "type": "text/vnd.tiddlywiki",
  "revision": 0,
  "bag": "default"
}
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--tw5-get-tiddler-emacs-response">Code Snippet 5</a>:</span>
  The REST API will send back a JSON response.
</div>


## request.el {#request-dot-el}

I use [request.el](https://tkf.github.io/emacs-request/)
{{% sidenote %}}
I know there might be better alternatives. But in my case it's been totally
sufficient and Elisp beginner friendly.
{{% /sidenote %}} for crafting and sending HTTP requests. So what is `request.el` all about?

> Request.el is a HTTP request library with multiple backends. It supports url.el
> which is shipped with Emacs and curl command line program. User can use curl
> when s/he has it, as curl is more reliable than url.el. Library author can use
> request.el to avoid imposing external dependencies such as curl to users while
> giving richer experience for users who have curl. -- [Source](https://tkf.github.io/emacs-request/)


### GET {#get}

Let's have a look how a simple (GET) API call looks like:

<a id="code-snippet--request-get-chuck-norris"></a>
```emacs-lisp
(let*
    ((httpRequest
      (request "https://api.chucknorris.io/jokes/random"
        :parser 'json-read
        :sync t
        :success (cl-function
                  (lambda (&key data &allow-other-keys)
                    (message "I sent: %S" data)))))

     (data (request-response-data httpRequest)))

  ;; Print information
 (cl-loop for (key . value) in data
      collect (cons key value)))
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--request-get-chuck-norris">Code Snippet 6</a>:</span>
  Get a random Chuck Norris joke
</div>

```emacs-lisp
((categories .
             [])
 (created_at . "2020-01-05 13:42:19.576875")
 (icon_url . "https://assets.chucknorris.host/img/avatar/chuck-norris.png")
 (id . "YNmylryESKCeA5-TJKm_9g")
 (updated_at . "2020-01-05 13:42:19.576875")
 (url . "https://api.chucknorris.io/jokes/YNmylryESKCeA5-TJKm_9g")
 (value . "The descendents of Chuck Norris have divided into two widely known cultures: New Jersey and New York."))
```


### POST {#post}

Sending a `POST` request is also an easy task:

<a id="code-snippet--request-post-request-httpbin"></a>
```emacs-lisp
(let*
    ((httpRequest
      (request "http://httpbin.org/post"
        :type "POST"
        :data '(("key" . "value") ("key2" . "value2"))
        :parser 'json-read
        :sync t
        :success (cl-function
                  (lambda (&key data &allow-other-keys)
                    (message "I sent: %S" data)))))

     (data (request-response-data httpRequest))
     (err (request-response-error-thrown httpRequest))
     (status (request-response-status-code httpRequest)))

  ;; Print information
 (cl-loop for (key . value) in data
      collect (cons key value)))
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--request-post-request-httpbin">Code Snippet 7</a>:</span>
  POST request with data
</div>

And here is the result:

<a id="code-snippet--request-post-request-httpbin-response"></a>
```emacs-lisp
((args)
 (data . "")
 (files)
 (form
  (key . "value")
  (key2 . "value2"))
 (headers
  (Accept . "*/*")
  (Accept-Encoding . "deflate, gzip, br, zstd")
  (Content-Length . "21")
  (Content-Type . "application/x-www-form-urlencoded")
  (Host . "httpbin.org")
  (User-Agent . "curl/7.83.1")
  (X-Amzn-Trace-Id . "Root=1-62cdbc5c-52d3ad32436c1cb8778808e5"))
 (json)
 (origin . "127.0.0.1")
 (url . "http://httpbin.org/post"))
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--request-post-request-httpbin-response">Code Snippet 8</a>:</span>
  POST response as list of Elisp cons cells
</div>


## Emacs {#emacs}

```lisp
;; default tiddlywiki base path
(setq tiddlywiki-base-path "http://127.0.0.1:8181/recipes/default/tiddlers/")
```


### GET tiddler {#get-tiddler}

Let's [GET](https://tiddlywiki.com/prerelease/static/WebServer%2520API%253A%2520Get%2520Tiddler.html) a tiddler:

<a id="code-snippet--request-get-tiddler-emacs"></a>
```emacs-lisp
(let*
    ((httpRequest
      (request (concat tiddlywiki-base-path "Emacs")
        :parser 'json-read
        :sync t
        :success (cl-function
                  (lambda (&key data &allow-other-keys)
                    (message "I sent: %S" data)))))

     (data (request-response-data httpRequest))
     (err (request-response-error-thrown httpRequest))
     (status (request-response-status-code httpRequest)))

  ;; Print information
 (cl-loop for (key . value) in data
      collect (cons key value)))
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--request-get-tiddler-emacs">Code Snippet 9</a>:</span>
  Get a tiddler by name ("Emacs")
</div>

<a id="code-snippet--request-get-tiddler-emacs-response"></a>
```emacs-lisp
((title . "Emacs")
 (created . "20210623082136326")
 (modified . "20210623082138258")
 (tags . "Topics")
 (type . "text/vnd.tiddlywiki")
 (revision . 0)
 (bag . "default"))
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--request-get-tiddler-emacs-response">Code Snippet 10</a>:</span>
  Response as list of Elisp cons cells
</div>


### PUT a new tiddler {#put-a-new-tiddler}

[Creating a new tiddler](https://tiddlywiki.com/prerelease/static/WebServer%2520API%253A%2520Put%2520Tiddler.html) is also simple. Using [ob-verb](https://github.com/federicotdn/verb)
{{% sidenote %}}
This package is really helpful especially when you do literate programming with [org-babel](https://orgmode.org/worg/org-contrib/babel/).
{{% /sidenote %}} let's add a `PUT` request to the API:

<a id="code-snippet--put-new-tiddler-pseudo"></a>
```verb
PUT http://127.0.0.1:8181/recipes/default/tiddlers/I%20love%20Elisp
x-requested-with: TiddlyWiki
Content-Type: application/json; charset=utf-8

{
    "title": "I love Elisp",
    "tags": "Emacs [[I Love]]",
    "send-with": "verb",
    "text": "This rocks!"
}
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--put-new-tiddler-pseudo">Code Snippet 11</a>:</span>
  Sample request for creating a new tiddler
</div>

Check if tiddler was indeed created:

<a id="code-snippet--get-tiddler-verb"></a>
```verb
GET http://127.0.0.1:8181/recipes/default/tiddlers/I%20love%20Elisp
x-requested-with: TiddlyWiki
Accept: application/json; charset=utf-8
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--get-tiddler-verb">Code Snippet 12</a>:</span>
  GET request using <code>verb</code>
</div>

<a id="code-snippet--put-new-tiddler-pseudo-response"></a>
```http
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 13 Jul 2022 10:03:27 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{
  "title": "I love Elisp",
  "tags": "Emacs [[I Love]]",
  "fields": {
    "send-with": "verb"
  },
  "text": "This rocks!",
  "revision": 1,
  "bag": "default",
  "type": "text/vnd.tiddlywiki"
}
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--put-new-tiddler-pseudo-response">Code Snippet 13</a>:</span>
  A new tiddler was created
</div>

Now let's translate that to `request.el` code. This I'll some extra complexity: I'll add
a function (`defun`) to `PUT` a new tiddler for us, where **name**, **tags** and **body** of the tiddler are variable.

<a id="code-snippet--request-insert-function"></a>
```emacs-lisp { hl_lines=["6","21","13"] }
;; Define function for inserting new tiddlers
(defun insert-tiddler(name tags body)
  (let*
  (
   (tiddler-title name)
   (url-path (url-hexify-string tiddler-title))
   (tiddler-tags tags)
   (tiddler-body body)

   (httpRequest
    (request (concat tiddlywiki-base-path url-path)
      :type "PUT"
      :data (json-encode
             `(
               ("title" . ,tiddler-title)
               ("created" . ,(format-time-string "%Y%m%d%H%M%S%3N"))
               ("modified" . ,(format-time-string "%Y%m%d%H%M%S%3N"))
               ("tags" . ,tiddler-tags)
               ("text" . ,tiddler-body)
               ("type" . "text/vnd.tiddlywiki")))
      :headers '(
                 ("Content-Type" . "application/json")
                 ("X-Requested-With" . "Tiddlywiki")
                 ("Accept" . "application/json"))
      :encoding 'utf-8
      :sync t
      :complete
      (function*
       (lambda (&key data &allow-other-keys)
         (message "Inside function: %s" data)
         (when data
           (with-current-buffer (get-buffer-create "*request demo*")
             (erase-buffer)
             (insert (request-response-data data))
             (pop-to-buffer (current-buffer))))))
      :error
      (function* (lambda (&key error-thrown &allow-other-keys&rest _)
                   (message "Got error: %S" error-thrown)))
      )))

  (format "%s:%s"
          (request-response-headers httpRequest)
          (request-response-status-code httpRequest)
          )))

;; Insert 2 tiddlers
(insert-tiddler "I love Elisp" "Elisp [[I Love]]" "This rocks!")
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--request-insert-function">Code Snippet 14</a>:</span>
  Create new function for inserting new tiddlers
</div>

<a id="code-snippet--request-insert-function-created"></a>
```emacs-lisp
"((etag . \"default/I%20love%20Elisp/61:\") (content-type . text/plain) (date . Wed, 13 Jul 2022 12:30:33 GMT) (connection . keep-alive) (keep-alive . timeout=5)):204"
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--request-insert-function-created">Code Snippet 15</a>:</span>
  New tiddler was created
</div>

Some explanations:

-   in line 6 I URL encode the `tiddler-title`
    -   `I love Elisp` should become `I%20love%20Elisp`
-   in line 21 some headers are set
    -   `X-Requested-With` is required to be set to `TiddlyWiki`
    -   `Content-Type` should be `json`
    -   we also accept `json` as a response
-   in line 13 we specify the `data` to be sent to the API
    -   each field (key, value sets) is set accordingly (see [10](#code-snippet--request-get-tiddler-emacs-response))
    -   I set the `created` and `modified` fields using `format-time-string`

Now let's check again if tiddler really exists:

<a id="code-snippet--get-tiddler-verb-new-tiddler"></a>
```:exports
GET http://127.0.0.1:8181/recipes/default/tiddlers/I%20love%20Elisp
x-requested-with: TiddlyWiki
Accept: application/json; charset=utf-8
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--get-tiddler-verb-new-tiddler">Code Snippet 16</a>:</span>
  Check if new tiddler exists
</div>

<a id="code-snippet--get-tiddler-verb-new-tiddler-response"></a>
```http
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 13 Jul 2022 12:40:22 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{
  "title": "I love Elisp",
  "created": "20220713143033566",
  "modified": "20220713143033566",
  "tags": "Elisp [[I Love]]",
  "text": "This rocks!",
  "type": "text/vnd.tiddlywiki",
  "revision": 61,
  "bag": "default"
}
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--get-tiddler-verb-new-tiddler-response">Code Snippet 17</a>:</span>
  It does exist!
</div>


## Use cases {#use-cases}

Now what can you do with this little custom functions? Let me share my use cases.


### Add bookmark {#add-bookmark}

A bookmark in my TiddlyWiki represents a tiddler of following format:

```verb
GET http://127.0.0.1:8181/recipes/default/tiddlers/chashell
Accept: application/json; charset=utf-8
```

```http { hl_lines=["17","13","14","15"] }
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 13 Jul 2022 12:49:58 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{
  "title": "chashell",
  "created": "20210519103441485",
  "modified": "20210519103528982",
  "fields": {
    "name": "chashell",
    "note": "Chashell is a Go reverse shell that communicates over DNS. It can be used to bypass firewalls or tightly restricted networks.",
    "url": "https://github.com/sysdream/chashell"
  },
  "tags": "Golang Security Tool Bookmark",
  "type": "text/vnd.tiddlywiki",
  "revision": 0,
  "bag": "default"
}
```

Every bookmarks consists of a **name**, a **note** and an **url**. Every tiddler supposed to be a bookmark is tagged by `Bookmark`. In this `chashell` is
a tiddler and at the same time a bookmark in my wiki.
{{% sidenote %}}
This is the entry in my public Tiddlywiki instance: <https://brainfck.org/#chashell>.
{{% /sidenote %}} As part of my daily routine, I go through my [pocket entries](/2021/09/01/inbox-zero-using-getpocket/) and decide which ones I should bookmark in Tiddlywiki. These are my keybindings
for the getpocket major mode:

```emacs-lisp { hl_lines=["12"] }
(map! :map pocket-reader-mode-map
      :after pocket-reader
      :nm "d" #'pocket-reader-delete
      :nm "SD" #'dorneanu/pocket-reader-send-to-dropbox
      :nm "a" #'pocket-reader-toggle-archived
      :nm "B" #'pocket-reader-open-in-external-browser
      :nm "e" #'pocket-reader-excerpt
      :nm "G" #'pocket-reader-more
      :nm "TAB" #'pocket-reader-open-url
      :nm "tr" #'pocket-reader-remove-tags
      :nm "tN" #'dorneanu/pocket-reader-remove-next
      :nm "C-b" #'dorneanu/tiddlywiki-add-bookmark
      :nm "ta" #'pocket-reader-add-tags
      :nm "gr" #'pocket-reader-refresh
      :nm "p" #'pocket-reader-search
      :nm "U" #'pocket-reader-unmark-all
      :nm "y" #'pocket-reader-copy-url
      :nm "Y" #'dorneanu/pocket-reader-copy-to-scratch)
```

Let's have a look at `dorneanu/tiddlywiki-add-bookmark`:
{{% sidenote %}}
Again: You can find all my customized functions in my [dotfiles](https://github.com/dorneanu/dotfiles/blob/master/dot_doom.d/config.org#tiddlywiki).
{{% /sidenote %}} <a id="code-snippet--function-tiddlywiki-add-bookmark-getpocket"></a>
```emacs-lisp
(defun dorneanu/tiddlywiki-add-bookmark ()
  "Adds a new bookmark to tiddlywiki. The URL is fetched from clipboard or killring"
    (require 'url-util)
    (interactive)
    (pocket-reader-copy-url)

    (setq my-url (org-web-tools--get-first-url))
    (setq url-html (org-web-tools--get-url my-url))
    (setq url-title (org-web-tools--html-title url-html))
    (setq url-title-mod (read-string "Title: " url-title))
    (setq url-path (url-hexify-string url-title-mod))
    (setq url-note (read-string (concat "Note for " my-url ":")))
    (setq url-tags (concat "Bookmark "(read-string "Additional tags: ")))

    (request (concat tiddlywiki-base-path url-path)
    :type "PUT"
    :data (json-encode `(("name" . ,url-title-mod) ("note" . ,url-note) ("url" . ,my-url) ("tags" . ,url-tags)))
    :headers '(("Content-Type" . "application/json") ("X-Requested-With" . "TiddlyWiki") ("Accept" . "application/json"))
    :parser 'json-read
    :success
    (cl-function
            (lambda (&key data &allow-other-keys)
                (message "I sent: %S" (assoc-default 'args data))))
    :complete (lambda (&rest _) (message "Added %s" (symbol-value 'url-title-mod)))
    :error (lambda (&rest _) (message "Some error"))
    :status-code '((400 . (lambda (&rest _) (message "Got 400.")))
                    (418 . (lambda (&rest _) (message "Got 418.")))
                    (204 . (lambda (&rest _) (message "Got 202."))))
    )
)
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--function-tiddlywiki-add-bookmark-getpocket">Code Snippet 18</a>:</span>
  Bookmark entries from getpocket directly into Tiddlywiki
</div>


### Add quote {#add-quote}

After reading each book I usually do some post-reading/post-processing. While I could use the
Tiddlywiki web interface to add new tiddlers, I'd rather do it from Emacs directly.

Often I need to insert new quotes from book (or web articles). How to I do this:

<a id="code-snippet--function-tiddlywiki-add-quote"></a>
```emacs-lisp
(defun dorneanu/tiddlywiki-add-quote ()
  "Adds a new quote"
    (interactive)

    (setq quote-title (read-string "Quote title: " quote-title))
    (setq url-path (url-hexify-string quote-title))
    (setq quote-source (read-string (concat "Source for " quote-title ": ") quote-source))
    (setq quote-body (read-string (concat "Text for " quote-title ": ")))
    (setq quote-tags (concat "quote "(read-string "Additional tags: ")))

    (request (concat tiddlywiki-base-path url-path)
    :type "PUT"
    :data (json-encode `(
        ("title" . ,quote-title)
        ("created" . ,(format-time-string "%Y%m%d%H%M%S%3N"))
        ("modified" . ,(format-time-string "%Y%m%d%H%M%S%3N"))
        ("source" . ,quote-source)
        ("tags" . ,quote-tags)
        ("text" . ,quote-body)
        ("type" . "text/vnd.tiddlywiki")))
    :headers '(("Content-Type" . "application/json") ("X-Requested-With" . "TiddlyWiki") ("Accept" . "application/json"))
    :parser 'json-read
    :success
    (cl-function
            (lambda (&key data &allow-other-keys)
                (message "I sent: %S" (assoc-default 'args data))))
    :complete (lambda (&rest _) (message "Added quote <%s>" (symbol-value 'quote-title)))
    :error (lambda (&rest _) (message "Some error"))
    :status-code '((400 . (lambda (&rest _) (message "Got 400.")))
                    (418 . (lambda (&rest _) (message "Got 418.")))
                    (204 . (lambda (&rest _) (message "Got 202."))))
    )
)
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--function-tiddlywiki-add-quote">Code Snippet 19</a>:</span>
  Directly add new quotes from Emacs
</div>

I simply invoke `M-x dorneanu/tiddlywiki-add-quote` and `read-string` will ask for a quote title, some source of the quote (e.g. a book)
and of course the actual text.


## Hydra {#hydra}

I've recently discovered [hydra](https://github.com/abo-abo/hydra) and I came up with some hydra also for TiddlyWiki:

<a id="code-snippet--tiddlywiki-customized-hydra"></a>
```emacs-lisp
(defhydra hydra-tiddlywiki (:color blue :hint nil)
"
Tiddlywiki commands^
---------------------------------------------------------
_b_ Add new bookmark
_j_ Add new journal entry
_t_ Add new tiddler
_q_ Add new quote
"
  ("b" dorneanu/tiddlywiki-add-bookmark)
  ("j" vd/tw5-journal-file-by-date)
  ("q" dorneanu/tiddlywiki-add-quote)
  ("t" dorneanu/tiddlywiki-add-tiddler))

;; Keybindings
(my-leader-def
  :infix "m w"
  "h" '(hydra-tiddlywiki/body :which-key "Open Tiddlywiki hydra")
  "j" '(vd/tw5-journal-file-by-date :which-key "Create/Open TW5 Journal file")
  "s" '(my/rg-tiddlywiki-directory :which-key "Search in TW5 directory"))
```

<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--tiddlywiki-customized-hydra">Code Snippet 20</a>:</span>
  Hydra for Tiddlywiki
</div>

This way I press `M m w h` and the TiddlyWiki hydra will pop up.


## Conclusion {#conclusion}

I hope some day there will be a full (elisp) package for TiddlyWiki combining some of the
functionalities/ideas mentioned here. If you have anything to add/share, please let me know.
