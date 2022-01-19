+++
title = "HowTo: Convert pocket reader links to Epub and upload to Dropbox"
author = ["Victor Dorneanu"]
date = 2021-08-15T00:00:00+02:00
lastmod = 2022-01-05T13:28:02+01:00
tags = ["org", "pocket", "asciinema", "howto", "emacs", "productivity", "ARCHIVE"]
draft = false
asciinema = true
+++

## Read, organize, archive {#read-organize-archive}

I heavily use [getpocket](https://getpocket.com) to collect articles and save them for later reading. While on my mobile devices I use the official
app, on my desktop systems (mostly tmux +[ Emacs](https://brainfck.org/#Emacs)) I use [pocket-reader.el](https://github.com/alphapapa/pocket-reader.el) quite heavily to collect/organize/archive my list of
articles. After my transition from [Spacemacs](https://www.spacemacs.org/) to [Doom Emacs](https://github.com/hlissner/doom-emacs) I still love [evil](https://github.com/emacs-evil/evil) mode and like to do most of the stuff in `normal`
mode. That's why I've added some [keybindings to pocket-reader](https://github.com/dorneanu/dotfiles/blob/master/emacs/doom/.doom.d/%2Bbindings.el#L25):

```elisp
(map! :map pocket-reader-mode-map
      :after pocket-reader
      :nm "d" #'pocket-reader-delete
      :nm "a" #'pocket-reader-toggle-archived
      :nm "TAB" #'pocket-reader-open-url
      :nm "tr" #'pocket-reader-remove-tags
      :nm "ta" #'pocket-reader-add-tags
      :nm "gr" #'pocket-reader-refresh
      :nm "p" #'pocket-reader-search
      :nm "y" #'pocket-reader-copy-url
      :nm "Y" #'dorneanu/pocket-reader-copy-to-scratch)
```

This way I can add/remove tags, archive articles, open links without leaving normal mode in `evil`.


## Read later on E-Reader {#read-later-on-e-reader}

Since I tend to read on my [e-reader](https://pocketbook.de/de%5Fde/inkpad-3-dark-brown) most of the time, I also wanted to have an almost automated way of saving articles to **Epub**
and send these to my device. Fortunately PocketBook devices can sync with Dropbox which made my life quite easy in the past. I just had to copy e-books, PDFs, Epubs to a specific folder in Dropbox and these will eventually sync with my device once WiFi
is activated. That's first step of automation.

As for the Epub conversion I've used [pandoc](https://pandoc.org/) in the past which still does its job great. Initially I've used [monolith](https://github.com/Y2Z/monolith) to save complete web pages as HTML but I've realized the HTML also contained useless ads, images, text. That's why I've searched for
ways how to make the content more **readable** and discovered [rdrview](https://github.com/eafer/rdrview). It's written in C and applies [Firefox's reader view](https://support.mozilla.org/en-US/kb/firefox-reader-view-clutter-free-web-pages) to web pages. Here are some examples:

```shell
$ rdrview -M http://blog.dornea.nu/2021/06/13/note-taking-in-2021/
Title: Note taking in 2021 - blog.dornea.nu
Excerpt: [Update 2021-06-22] If you’re more interested in the Tiddlywiki aspect of this post you can also check this Tiddlywiki Google Groups thread. [Update 2021-06-18] This post caught some attention on this Hackernews thread. You might want to check the comments. Based on the recommendations in the thread I’ve put together a list of (digital) solutions (besides the preferred ones) Almost 6 years ago I was blogging about organizing and visualizing knowledge.
Readerable: Yes
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1</span>:
  Get meta information
</div>

And now I'm using some `xpath` to extract the title:

```shell
$ rdrview -T title,body -H http://blog.dornea.nu/2021/06/13/note-taking-in-2021/ | xmllint --html --xpath "//div/h1/text()" -
Note taking in 2021 - blog.dornea.nu
```

Below I've glued everything together in order to:

-   convert an URL to epub
-   extract the title and use it as the filename for the Epub
-   do the converion using [pandoc](https://pandoc.org/)
-   use [rclone](https://rclone.org/) to copy the file to Dropbox

<!--listend-->

```shell
#!/bin/bash

RDRVIEW_OUTPUT=~/work/dropbox/rdrview
DROPBOX_DIR="dropbox:Apps/Dropbox PocketBook/articles/2021/"

add_link_to_dropbox() {
    # Create tmp file
    TEMP_FILE=$(mktemp)

    # Make link readable
    rdrview -T title,body -H $1 > $TEMP_FILE

    # Extract title
    TITLE=$(xmllint --html --xpath "//div/h1/text()" 2>/dev/null ${TEMP_FILE})
    echo "[-] Converting $TITLE"

    # Convert to PDF
    OUTPUT_FILE="${RDRVIEW_OUTPUT}/${TITLE// /_}".epub
    pandoc --pdf-engine=xelatex --metadata title="${TITLE}" -f html -t epub -o ${OUTPUT_FILE} ${TEMP_FILE}

    # Copy to dropbox
    rclone copy ${OUTPUT_FILE} "${DROPBOX_DIR}"

    # Log
    echo "[-] Successfully added ${OUTPUT_FILE} to dropbox."

    # Clean up
    rm $TEMP_FILE
    rm $OUTPUT_FILE
}

add_link_to_dropbox $1
```

Let's give it a try using <https://pandoc.org/> as an URL:

```:exports
$ ~/work/dropbox/add_links_to_dropbox https://pandoc.org/
[-] Converting Pandoc - About pandoc
[-] Successfully added /home/victor/work/dropbox/rdrview/Pandoc_-_About_pandoc.epub to dropbox.
```


## Emacs for Everything {#emacs-for-everything}

Now I'd like to be able to call that script from Emacs without copy/paste URLs and hand them over to my script.
The most difficult part here was to come up with some valid Elisp code. What I wanted was:

-   in `pocket-reader` copy entry's URL to `scratch` buffer
-   once I have collected the list of URLs for which I want the Epub conversion
    -   take the list and use it as input for my script
    -   use `xargs` since my script takes only one argument

And this is what I've got (my first elisp [function](https://github.com/dorneanu/dotfiles/blob/master/emacs/doom/.doom.d/%2Bfunctions.el#L159) ever):

```elisp
;; Copy current url to scratch buffer
(defun dorneanu/pocket-reader-copy-to-scratch ()
  "Copy URL of current item to kill-ring/clipboard."
  (interactive)
  (when-let ((id (tabulated-list-get-id))
             (item (ht-get pocket-reader-items id))
             (url (pocket-reader--get-url item)))
    (with-current-buffer "*scratch*"
      (insert url)
      (newline))
     (message "Added: %s to scratch buffer" url)))
```

This will `insert` the URL into the `scratch` buffer and add a new line. Once you have your URLs in the buffer you can
use `shell-command-on-region` with `xargs -n1 <script>` as shown in the asciinema below.


## Demo {#demo}

{{< asciinema key="first" rows="40" font-size="10px" cols="800" preload="1" >}}
