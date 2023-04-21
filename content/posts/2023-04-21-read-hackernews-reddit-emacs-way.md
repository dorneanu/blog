+++
title = "Read Hackernews and Reddit the Emacs way"
author = ["Victor Dorneanu"]
lastmod = 2023-04-21T07:14:42+02:00
tags = ["rss", "emacs"]
draft = false
+++

## Motivation {#motivation}

Usually when I consume my daily [news feeds](/2022/06/13/rss-and-atom-for-digital-minimalists/), I prefer to keep context switching
to a minimum. Whether you're a busy professional or just someone who values
their time, you might want to streamline your online reading experience as much
as possible. For me, this means sticking to [Emacs](https://brainfck.org/t/emacs) and
using tools like [elfeed and pocket-reader](/2022/06/29/rss/atom-emacs-and-elfeed/) to stay on top of my reading list.

Unfortunately, this approach doesn't work with content served within comments at
Hackernews or Reddit, where you usually have lots of comments and discussion
threads. This is where I began to struggle, as I found myself bouncing back and
forth between Emacs and my browser in order to stay on top of the conversation.

Luckily, I've found [hnreader](https://github.com/thanhvg/emacs-hnreader) and [reddigg](https://github.com/thanhvg/emacs-reddigg) which have changed the way I consume
content on these platforms. These packages are specifically designed to help you
navigate and read through Hackernews and Reddit threads directly from within
Emacs, saving you from the hassle of constantly switching between different apps
and tabs.

In my opinion these are the most underrated packages and in this post I'd like
to show you how they can help you improve your reading experience. By the end of
this post, you'll have a better understanding of how to use [hnreader](https://github.com/thanhvg/emacs-hnreader) and [reddigg](https://github.com/thanhvg/emacs-reddigg)
to read and navigate through even the most complex Hackernews and Reddit
threads, all without ever having to leave the comfort of [Emacs](https://brainfck.org/t/emacs).


## hnreader {#hnreader}

Without any customizations you can use `hnreader` straightaway. Currently you have following options:

{{< gbox src="/posts/img/2023/hnreader-reddigg/hnreader-functions.png" title="" caption="" pos="left" >}}

Invoking each function will return a buffer with the latest 30 posts in that category:

{{< gbox src="/posts/img/2023/hnreader-reddigg/hnreader-top-posts.png" title="" caption="" pos="left" >}}

Let's have a look how we can add customized behaviour.


### Basic functions {#basic-functions}

The easiest way to show comments for a thread ID is to use

```emacs-lisp
(hnreader-readpage-promise "https://news.ycombinator.com/item?id=34482433")
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Open a new buffer with the HN page
</div>

This will create a new buffer and load the _readpage_ for that specific HN URL

{{< gbox src="/posts/img/2023/hnreader-reddigg/hnreader-readpage-buffer.png" title="" caption="" pos="left" >}}

```emacs-lisp
(hnreader-promise-comment "https://news.ycombinator.com/item?id=34482433")
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  Open a new buffer with the HN threads
</div>

This will create a new buffer and load all comments from this specific Hackernews thread:

{{< gbox src="/posts/img/2023/hnreader-reddigg/hnreader-comments-buffer.png" title="" caption="" pos="left" >}}


### elfeed integrations {#elfeed-integrations}

Whenever you have a Hackernews specific link inside your buffer you may want to open it using:

```emacs-lisp
(defun my/elfeed-hn-show-comments-at-point ()
  "Show HN comments for an URL at point"
  (interactive)
  (setq-local hnreader-view-comments-in-same-window t)
  (hnreader-comment (format "%s" (url-get-url-at-point))))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Show HN comments for an URL at point
</div>

You can of course call a function from the `elfeed-search` buffer to show the HN threads:

```emacs-lisp
(defun my/elfeed-hn-show-commments (&optional link)
  (interactive)
  (let* ((entry (if (eq major-mode 'elfeed-show-mode)
                    elfeed-show-entry
                  (elfeed-search-selected :ignore-region)))
         (link (if link link (elfeed-entry-link entry))))
    (setq-local hnreader-view-comments-in-same-window nil)
    (hnreader-promise-comment (format "%s" link))))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Opens new buffer when called from the elfeed-search buffer
</div>

And these are my `elfeed` related keybindings:

```emacs-lisp
(map! :map elfeed-search-mode-map
      :after elfeed-search
      [remap kill-this-buffer] "q"
      [remap kill-buffer] "q"
      :n doom-leader-key nil
      ;; ...
      :n "H" #'my/elfeed-hn-show-commments
      ;; ...)
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Key bindings for elfeed-search-mode
</div>

```emacs-lisp
(map! :map elfeed-search-mode-map
      :after elfeed-show
      [remap kill-this-buffer] "q"
      [remap kill-buffer] "q"
      :n doom-leader-key nil
      ;; ...
      :n "H" #'my/elfeed-hn-show-comments-at-point
      ;; ...)
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Key bindings for elfeed-show-mode
</div>


## reddigg {#reddigg}

[reddigg](https://github.com/thanhvg/emacs-reddigg) is the similar solution for reddit. When invoked directly you have these options:

{{< gbox src="/posts/img/2023/hnreader-reddigg/reddigg-functions.png" title="reddigg functions" caption="reddigg functions" pos="left" >}}

After invoking `reddigg-view-frontpage` you'll get a new buffer with the last posts:

{{< gbox src="/posts/img/2023/hnreader-reddigg/reddigg-frontpage.png" title="reddigg front page" caption="reddigg front page" pos="left" >}}

```emacs-lisp
(defun my/elfeed-reddit-show-commments (&optional link)
  (interactive)
  (let* ((entry (if (eq major-mode 'elfeed-show-mode)
                    elfeed-show-entry
                  (elfeed-search-selected :ignore-region)))
         (link (if link link (elfeed-entry-link entry))))
    (reddigg-view-comments link)))
```


### elfeed integration {#elfeed-integration}

We can also use `reddigg` to show reddit threads from within an `elfeed` buffer

```emacs-lisp
(defun my/elfeed-reddit-show-commments (&optional link)
  (interactive)
  (let* ((entry (if (eq major-mode 'elfeed-show-mode)
                    elfeed-show-entry
                  (elfeed-search-selected :ignore-region)))
         (link (if link link (elfeed-entry-link entry))))
    (reddigg-view-comments link)))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Show reddit comments from within elfeed
</div>

And my related keybindings:

```emacs-lisp
(map! :map elfeed-search-mode-map
      :after elfeed-search
      [remap kill-this-buffer] "q"
      [remap kill-buffer] "q"
      :n doom-leader-key nil
      ;; ...
      :n "R" #'my/elfeed-reddit-show-commments
      ;; ...
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Key bindings for reddigg
</div>

When invoked you'll get an ORG mode styled buffer with all the comments for a specific reddit thread:

{{< gbox src="/posts/img/2023/hnreader-reddigg/reddigg-comments.png" title="reddigg comments" caption="reddigg comments" pos="left" >}}


## Conclusion {#conclusion}

I hope you're as enthusiastic as I am. And if you have any better alternatives,
please don't hesitate to let me know in the comments.
