+++
title = "From Doom to Vanilla Emacs"
author = ["Victor Dorneanu"]
lastmod = 2024-02-22T19:58:33+01:00
tags = ["emacs"]
draft = false
+++

## Why vanilla? {#why-vanilla}

Let's start with the most obvious question: _What's wrong with Doom Emacs_? Short answer:
There is _nothing_ wrong with Doom Emacs. I still use it and I still recommend it for
_beginners_. Some years ago I started with `Spacemacs` and moved to `Doom` which, in my humble
opinion, is far faster and more stable. So if you're a novice and just entered the "_church
of Emacs_"
{{% sidenote %}}
The "Church of Emacs" is a humorous reference to the strong advocacy and devotion some
Emacs users have towards the Emacs text editor. It plays on the idea of Emacs being more
than just a tool, but almost a way of life for some users.
{{% /sidenote %}} I **strongly** recommend you do **NOT** start with `vanilla`. I recommend `Doom` because:

-   it comes with batteries included
-   I like how you can exclude packages from your configuration
-   you don't have to get into heavy `Elisp`
-   there is a whole group of being taking care of _bugs_ and making sure
    each release works properly

That said, I still wanted to go "vanilla," at least give it a try. My first attempt
failed, mainly because I was trying to use someone's config without really understanding
how it works. I also had some "hard requirements" for my configuration:

-   [evil mode](https://github.com/emacs-evil/evil)

    I've used `vim` for more than 10 years and memorized vim like keybindings like my own
    pocket. Sometimes I find Emacs like keybindings to be more practical, though. That's why
    I wanted to have both.
-   literate config (using [ORG mode](https://orgmode.org/))

    I still don't consider myself efficient in writing `Elisp` code. For this reason, I wanted
    my configuration to be written in ORG mode (like most of my stuff available online)
    whose _parts_ can be written (or _tangled_) to files (e.g. `.el` files) using [org-babel](https://orgmode.org/worg/org-contrib/babel/).
-   modular

    I wanted to _group_ similar functionalities in the same ORG file. That's why I have a
    `programming.org` file which includes configuration for the programming languages I'm
    using. At the same time I wanted to easily _disable_ parts of configuration by deleting
    the corresponding section or commenting it out (`org-toggle-comment`).

    Of course, `Org mode` would then have its own file `org.org` 😎


## Go vanilla {#go-vanilla}

If you really decide to continue this journey, I'd like to share some tipps/workflow to
make your process more smoothly.

Ever since I've started my `Emacs` journey it seemed like the wholy grail to have your own
(vanilla!) configuration without any hard dependencies on frameworks like [Doom](https://github.com/doomemacs/doomemacs) or
[Spacemacs](https://www.spacemacs.org/). There are plenty of `dotemacs` configurations ouf there which can serve as a
great source of inspiration.

In my case, it was specifically this one which caught my attention:
<https://config.phundrak.com/emacs/>. It had almost everything I needed, it was using `evil
mode` and the whole configuration is written in ORG mode. Bingo!
{{% sidenote %}}
I also droped [Lucien](https://github.com/Phundrak) a mail expressing my gratitude for having such a great source of an awesome configuration.
{{% /sidenote %}}


### Literate config {#literate-config}

As a matter of preference I don't like Elisp based Emacs configurations. I find ORG mode
and literate config to be more easy to read and understand what's going on.

You can have a **basic structure** in your ORG mode file, define sections, and use the outline
functionality to jump to each section. You can then `tangle` the ORG file to generate the
`.el` files to be loaded by Emacs.
{{% sidenote %}}
Check [Introduction to Literate Programming](https://howardism.org/Technical/Emacs/literate-programming-tutorial.html) for more insights.
{{% /sidenote %}} Having spent countless hours (and days) tweaking my configuration, reading others and
trying to understand custom `Elisp` functions, I think I've reached a level where I **exactly**
know which part of my config is responsible for some misbehavior. Other than that, I've
found a _structure_ that fits my needs and the way I want my configuration to be structured.


### Basic structure {#basic-structure}

Your configuration should have a basic structure. You can either use a **single** file for the
whole configuration or **multiple** ones. I prefer multiple ones because you can `tangle` each
one individually and thus make the whole process faster. This is what I have inside my
`Emacs` folder in my [dotfiles](https://github.com/dorneanu/dotfiles):

```shell
emacs
├── basic-config.org
├── custom-elisp.org
├── index.org
├── keybinding-managers.org
├── keybindings.org
├── Makefile
├── package-manager.org
├── packages
│   ├── applications.org
│   ├── autocompletion.org
│   ├── editing.org
│   ├── helpful.org
│   ├── org.org
│   ├── programming.org
│   └── visual-config.org
└── tangle_script.sh
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Basic structure of my Emacs configuration files
</div>

This structure is more or less **copied** from [Phundrak's one](https://config.phundrak.com/emacs/) which served as a really good
starting point. Of course I stripped down each file to my needs.

The point is that each file would host a different set of customizations relevant to
specific functionalities. If I want to change some keybindings I'd then go to
`keybindings.org` and modify stuff. If I want to tweak the autocompletion for lsp-mode I'd
then go to `autocompletion.org`.


### Tangling {#tangling}

In Emacs and Org mode, `tangling` refers to the process of extracting code snippets from an
ORG file and writing them to separate source code files. It usually allows you to maintain
code and documentation in the same file while keeping them in sync. In my case I use it to
generate Elisp code out of my ORG files.

{{< gbox src="/posts/img/2024/vanilla-emacs/emacs-org-config.png" title="My ORG mode config" caption="My ORG mode config" pos="left" >}}


#### Automation {#automation}

I like to automate most of the workflows and therefore I use a `Makefile` and some bash
script for tangling **all** files:

```makefile
# Phony target to tangle all org files
.PHONY: tangle
tangle:
    find . -name "*.org" -exec sh -c 'echo "[!] Tangling {}"; ./tangle_script.sh "{}"' \;
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  Makefile for my Emacs configuration
</div>

And this is the script I use to tangle one individual file:

```sh
#!/bin/bash

emacs -q --batch --eval "(require 'ob-tangle)" \
  --eval "(setq org-confirm-babel-evaluate nil)" \
  --eval "(org-babel-tangle-file \"$1\")"
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3:</span>
  The tangle script which takes an ORG file as an argument
</div>


#### Manually {#manually}

I would like my overall configuration (at `~/.config/emacs`) to be updated immediately
whenever I change something in the Org mode files.
Therefore I use `.dir-locals.el` to define this behaviour for all ORG mode files

```emacs-lisp
;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((org-mode . ((org-confirm-babel-evaluate . nil)
              (eval .
                    (progn
                      ;; Tangle whole file after being saved
                      (add-hook 'after-save-hook 'org-babel-tangle)
                      )))))

```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4:</span>
  .dir-locals.el
</div>

First I don't want to be asked every time if I want to **evaluate** the source code blocks
(that's why `org-confirm-babel-evaluate` is set to `nil` ). Secondly I want to automatically
`tangle` the file whenever the file gets saved (`org-babel-tangle` in the `after-save-hook`).

This way every time I _save_ one file, the `Elisp` code will be automatically be tangled to
the corresponding file.


## Inspirations {#inspirations}

Sometimes I don't know exactly how to configure a package or which options I should be
using. Instead of searching the web for the examples last year I came up with an idea: I started collecting interesting/useful `dotfiles~/~dotemacs` collections in a **single** place. You can find the repository at [github.com/dorneanu/dotemacs](https://github.com/dorneanu/dotemacs). So what I usually do is to search inside the folder where I've cloned all repositories for specific keywords. For this purpose I use [rg.el](https://github.com/dajva/rg.el) and some custom function:

```elisp
(setq dotemacs-directory "/cs/priv/repos/dotemacs")
(rg-define-search my/rg-dotemacs
  :query ask
  :format regexp
  :files "everything"
  :dir dotemacs-directory
  :confirm prefix)
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5:</span>
  From the <code>rg</code> section in my dotemacs config
</div>

{{< gbox src="/posts/img/2024/vanilla-emacs/emacs-rg-search.png" title="Searching with rg" caption="Searching with rg is way faster" pos="left" >}}


## Conclusion {#conclusion}

Checkout my [dotfiles](https://github.com/dorneanu/dotfiles/tree/master/emacs) (which I manage using [chezmoi](https://www.chezmoi.io/)) if you need some inspiration. If you
have other tips on how to further improve my workflow or the overall structure, please
drop me an email.
