+++
title = "emacs"
author = ["Victor Dorneanu"]
lastmod = 2021-02-26T20:17:44+01:00
tags = ["note", "emacs"]
draft = false
weight = 2004
toc = true
noauthor = true
nocomment = true
nodate = true
nopaging = true
noread = true
+++

## Topics {#topics}


### How to remove empty lines in region {#how-to-remove-empty-lines-in-region}

-   Select what you want to change, or C-x h to select the whole buffer.
-   Then: `M-x flush-lines RET` followed by `^$ RET` or `^[[ : space : ]]*$ RET`
-   `^[[ : space : ]]*$` contain the meta-characters:
    -   ^ for beginning of string,
    -   $ for end of string,


### Tag multiple headers in a region {#tag-multiple-headers-in-a-region}

-   Select region
-   run `M-x org-change-tag-in-region`


### Remove read-only lock in a buffer {#remove-read-only-lock-in-a-buffer}

`C-x C-q`


## org-mode {#org-mode}

-   [Bookmark with Org-capture | The DevOps Blog](https://blog.lazkani.io/posts/text-editors/bookmark-with-org-capture/)
    How to capture links with own functions (for lisp beginners)
