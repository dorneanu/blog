+++
title = "RSS/Atom, Emacs and elfeed"
author = ["Victor Dorneanu"]
date = 2022-06-29T21:04:00+02:00
lastmod = 2022-07-11T11:29:35+02:00
tags = ["rss", "emacs"]
draft = false
+++

In [my last post](/2022/06/13/rss-and-atom-for-digital-minimalists/) I wrote about RSS/Atom and how these technologies can be used
to declutter your digital life and reduce your exposure to the attention
economy. [Emacs](/tags/emacs) (and all the amazing packages) taught me [ORG mode](https://orgmode.org), some basic [Elisp](https://www.gnu.org/software/emacs/manual/html_node/elisp/)
and how to be a minimalist and use just one tool for almost everything.

Staying up-to-date with current technological trends, Security advisories, blog
posts from smart people (and many other things) while not having to subscribe to every
single newsletter, led me to [elfeed](https://github.com/skeeto/elfeed):

> Elfeed is an extensible web feed reader for Emacs, supporting both Atom and RSS. - [Source](https://github.com/skeeto/elfeed)


## Configuration {#configuration}

{{< notice info >}}

My elfeed related configuration is available in [config.org](https://github.com/dorneanu/dotfiles/blob/master/dot_doom.d/config.org#elfeed).

{{< /notice >}}

Usually you would organize your feed entries as a list:

```emacs-lisp
;; Somewhere in your .emacs file
(setq elfeed-feeds
      '("http://nullprogram.com/feed/"
        "https://planet.emacslife.com/atom.xml"))
```

I didn't like this approach since the initial list was way to big to be managed.
Then I came across [elfeed-org](https://github.com/remyhonig/elfeed-org) which lets you organize your feeds in an ORG file.

{{< gbox src="/posts/img/2022/rss/elfeed-org.png" title="elfeed entries" caption="I have my bookmarks/feeds structured in ORG mode and each category/item is tagged accordingly." pos="left" >}}


## Workflow {#workflow}


### Daily view {#daily-view}

This is what I get whenever I hit **M-x elfeed**:

{{< gbox src="/posts/img/2022/rss/elfeed-search.png" title="Daily view in elfeed" caption="This is my daily view of RSS entries. Each lines has a timestamp, the feed entry name, a tag list and the corresponding feed entry title." pos="left" >}}

And this is how I actually consume my feeds:

{{< gbox src="/posts/img/2022/rss/elfeed-search-workflow.gif" title="Workflow in elfeed" caption="I usually start with a predefined query and then while I go through the list I mark each entry as read. In the right corner (I've activated keycast-tab-bar-mode) you'll also see my keystrokes. " pos="left" >}}

I usually start with a predefined filter: `@1-week-ago +unread +daily -youtube`. This gives me all entries:

-   not older than 1 week AND
-   not yet read AND
-   are tagged by `daily` AND
-   are NOT tagged by `youtube`

Simple, isn't it? :) In the gif you can see that I change the filter to also show the entries marked by `read`.
Whenever I want to actually visit an entry link, I press **RET** to get the excerpt or **b** to open that specific link
in an external browser (or **B** to open it in an `eww` buffer).


## getpocket integration {#getpocket-integration}

If you've read my getpocket article last year, you know I use [getpocket.com](https://getpocket.com) to save links/articles to read later. In `elfeed` I
can easily add a link to getpocket (thanks to [pocket-reader.el](https://github.com/alphapapa/pocket-reader.el)). I use these [key bindings](https://github.com/dorneanu/dotfiles/blob/master/dot_doom.d/config.org#elfeed):

```emacs-lisp
;; Define maps
(map! :map elfeed-search-mode-map
    :after elfeed-search
    [remap kill-this-buffer] "q"
    [remap kill-buffer] "q"
    :n doom-leader-key nil
    :n "q" #'+rss/quit
    :n "e" #'elfeed-update
    :n "r" #'elfeed-search-untag-all-unread
    :n "u" #'elfeed-search-tag-all-unread
    :n "s" #'elfeed-search-live-filter
    :n "RET" #'elfeed-search-show-entry
    :n "p" #'elfeed-show-pdf
    :n "+" #'elfeed-search-tag-all
    :n "-" #'elfeed-search-untag-all
    :n "S" #'elfeed-search-set-filter
    :n "b" #'elfeed-search-browse-url
    :n "B" #'elfeed-search-eww-open
    :n "a" #'pocket-reader-elfeed-search-add-link
    :n "y" #'elfeed-search-yank)
(map! :map elfeed-show-mode-map
    :after elfeed-show
    [remap kill-this-buffer] "q"
    [remap kill-buffer] "q"
    :n doom-leader-key nil
    :nm "q" #'+rss/delete-pane
    :nm "a" #'pocket-reader-elfeed-entry-add-link
    :n "B" #'elfeed-show-eww-open
    :nm "o" #'ace-link-elfeed
    :nm "RET" #'org-ref-elfeed-add
    :nm "n" #'elfeed-show-next
    :nm "N" #'elfeed-show-prev
    :nm "p" #'elfeed-show-pdf
    :nm "+" #'elfeed-show-tag
    :nm "-" #'elfeed-show-untag
    :nm "s" #'elfeed-show-new-live-search
    :nm "y" #'elfeed-show-yank)
```

Whenever I press **a** in an `elfeed` related buffer the entries link will be added to getpocket.


## Bookmarks {#bookmarks}

I use [bookmarks](https://www.gnu.org/software/emacs/manual/html_node/emacs/Bookmarks.html) to specify elfeed filters. This allows me to quickly jump to a certain view without
having to change the filter in-between:

{{< gbox src="/posts/img/2022/rss/bookmarks.png" title="Bookmarks for managing predefined filters" caption="I use bookmarks to have a list of predefined elfeed filters." pos="left" >}}


## Podcasts {#podcasts}

As already described [here](/2022/06/13/rss-and-atom-for-digital-minimalists/#podcasts) I use RSS/Atom feed to regularly check for new podcast episodes. Here's my workflow:

{{< gbox src="/posts/img/2022/rss/elfeed-podcasts.gif" title="Managing podcasts in elfeed" caption="I use tags (e.g. 2listen) to mark episodes I'd like to put into my todo/to-listen queue" pos="left" >}}
