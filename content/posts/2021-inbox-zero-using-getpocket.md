+++
title = "Inbox Zero using Getpocket"
author = ["Victor Dorneanu"]
date = 2021-09-01T00:00:00+02:00
lastmod = 2021-09-01T13:44:56+02:00
tags = ["pocket", "asciinema", "emacs", "productivity"]
draft = false
asciinema = true
+++

After finishing my last post on [how to convert getpocket links to epub](/2021/08/15/howto-convert-pocket-reader-links-to-epub-and-upload-to-dropbox/) I was thinking a lot about my current workflow, how
I manage to capture everything that
 might be interesting for me and save it for later use. Saving web articles for later reading is not a big deal but dealing with the amount of saved articles requires some management skills. In this post I'll share some best practices on how to organize and categorize your (web) articles in a [GTD](https://brainfck.org/#GTD) manner: [Capture what has your attention](https://brainfck.org/#GTD/Input), [organize your content in buckets](https://brainfck.org/#GTD/Buckets) and [keep an eye on your focus](https://brainfck.org/#GTD%20Managing%20attention).


## Requirements {#requirements}

When I had to decide for a "read it later"/"save for later" service some years ago, I've instantly registered an account with [getpocket.com](https://getpocket.com) and I still don't regret my decision. But what should a read it later app be capable of? Here is my incomplete list:

-   let's you **save articles** with **one click**
    -   ideally there are solutions for different devices (desktop, mobile, e-readers etc.)
    -   you can easily save/\*share\* the content/articles
        -   "share to" on mobile phones
        -   browser extensions
        -   e-mail service that automatically adds your article to the read it later list when you send an e-mail to that specific address
-   let's you **organize** your articles
    -   you can **tag** items
    -   you can **search** for items
        -   either by specific tag or
        -   by keyword
    -   you can **archive** items
    -   you can create lists/\*collections\* of items

Now, for my not so unspecific requirements `getpocket` has done a very great job and I still feel bad for no purchasing premium.


## What is Inbox Zero? {#what-is-inbox-zero}

> "Unproductive preoccupation with all the things we have to do is the single largest consumer of time and energy" - Kerry Glees

[GTD](https://brainfck.org/#GTD) proposes to capture everything that has our attention. You can either capture stuff on paper or digitally. And most important of all:
Collection tools should be part of your life style in order to **get everything out of your head**. And for better management you should also minimize the
number of capture locations (at work, at home, on your smartphone, at your desktop, while sitting down, while driving home etc.). [Managing attention](https://brainfck.org/#GTD%20Managing%20attention) will eventually not only get things off your mind but also enable you to collect **things** and access them later.

> Your brain is for having ideas, not storing them – David Allen

Now that you know what GTD is about (I really recommend reading the book since you won't find any explanations around the GTD process on the web. I was using GTD methodologies for years but without knowing how to apply them properly and for which areas to use) what is **inbox zero** about? [Merlin Mann](https://en.wikipedia.org/wiki/Merlin%5FMann) popularized the concept of "inbox zero" which somehow become associated with GTD. Even though [Mann stated](https://www.wired.co.uk/article/inbox-zero-mentality) he doesn't keep his inbox empty and everything I **guess** I know about it might be wrong,
let's (re-)define it for our own purposes.

So Inbox Zero is the attempt to keep your inbox empty, or close to empty, at all times. And if you realize everything in your life is an inbox, then you'll see the true benefit of keeping your inbox(es) empty. It not only helps you to make space for new input/ideas, but also use your brain for
what it was built for: Cognitive processes and not for information storage.

While you could apply this methodology to almost everything in life, let's have a look how it could be used for cleaning up your `getpocket` inbox for better URL management
and how to get most out of your readings.


## Why Getpocket {#why-getpocket}

Before we get into details, why did I chose `getpocket` at all?

-   works on nearly every device
    -   mobile clients (smartphones, tablets)
    -   desktop clients (browser, native applications)
    -   but also on E-readers (like my PocketBook Inkpad 3)
-   has great UI
-   I love their "readable" content view
    -   Now that Mozilla acquired them, most likely they use [readability](https://github.com/mozilla/readability)
    -   in my [last post](/2021/08/15/howto-convert-pocket-reader-links-to-epub-and-upload-to-dropbox/) I was also playing with [rdrview](https://github.com/eafer/rdrview) which allows you to have that reader view as a CLI tool
-   you can access your articles using the API
    -   I'm still missing some features, though
        -   e.g. you cannot extract your highlights


### Alternatives {#alternatives}

Here's a list of alternatives in case you don't want to use getpocket:

-   [Instapaper](https://www.instapaper.com/)
    -   never tried
-   [raindrop.io](https://raindrop.io/)
    -   implements pretty much the same feature set as Getpocket does
-   [wallabag](https://github.com/wallabag/wallabag)
    -   this is self-hosted
    -   along with [koreader](http://koreader.rocks/) you can also use wallabag on your E-Reader device

Apart from these service, there are tons of "bookmark managers" which they all have their pros and
cons. Feel free to give them a try and chose the one matching your needs best.


## Buckets {#buckets}

Usually when you send an URL to getpocket it will land in your default list (which is [my-list](https://getpocket.com/my-list)). Additionally you might have different other lists (such as [favorites](https://getpocket.com/my-list/favorites) or [archive](https://getpocket.com/my-list/archive)) available. But again: Those are only the default ones and just categorize your content depending on the content type ([videos](https://getpocket.com/my-list/videos), [articles](https://getpocket.com/my-list/articles) etc.
). What we want to have is a personalized categorization depending on your needs. Also dealing with a huge list like [my-list](https://getpocket.com/my-list) can be also very time consuming. You need
to chunk the list in small portions in order to actually **consume** it.

I like the idea of buckets where you can put **things in**. In a perfect world you'd want to have all your buckets
**empty** but I know that is hard to achieve.

{{< figure src="/posts/img/2021/input-zero/buckets-all.png" caption="Figure 1: Different buckets/lists used at getpocket" >}}


### Reading state tags {#reading-state-tags}

I use the initial list (my-list) as the first input gate from where I decide what to actually **do** with the content: Read it, share it, print it, delete it etc.

{{< figure src="/posts/img/2021/input-zero/tags.png" caption="Figure 2: I use tags to manage my reading workflow" >}}


### Topics tags {#topics-tags}

Additionally I of course tag URLs based on topics (like programming language, politics, business etc.) among with
the tags describing each URLs reading state.

{{< figure src="/posts/img/2021/input-zero/tags-with-topics.png" caption="Figure 3: Some URLs tagged with reading state tags and topics tags" >}}

In the above figure I have 4 URLs which are tagged multiple times. When tagging stuff I differentiate between

-   reading state tags
-   topics tags

In my example I have 2 URLs which I'd like to read (`2read`) and 2 which I'd like to watch (`2watch`). Additionally
I also use **topics tags** in order to categorize my content also by content:

-   URL #2 is about [Python](https://brainfck.org/#Python) and [Blockchain](https://brainfck.org/#Blockchain)
-   URL #3 is about politics


## Use tags wisely {#use-tags-wisely}

Whether tagging is good or not has been a controverse topic around [Zettelkasten](https://brainfck.org/#Zettelkasten) which doesn't recommend tagging (at least in an information system). Here you can read more:

-   [Indexed references vs. tags](https://notes.andymatuschak.org/z6ztEgzqZichYTJgabhYQLn4UY4FbC1JMH394)
-   [Tagging is broken (fortelabs.co)](https://fortelabs.co/blog/tagging-is-broken/)
-   [Tags vs Zettels](https://forum.zettelkasten.de/discussion/915/tags-vs-zettel-links)
-   [The Difference Between Good and Bad Tags](https://zettelkasten.de/posts/object-tags-vs-topic-tags/)
-   [Tags vs. page/link (obsidian.md)](https://forum.obsidian.md/t/tags-vs-page-link/193/21)

However, I merely use the tags to define a state which helps my overall reading workflow. Initially I've read about this
idea in [Daryl's awesome article on his own GTD workflow](https://daryl.wakatara.com/the-information-overload-gtd-flow/). It helped me a lot to

Here are these together with some explanations.


### 2read {#2read}

-   this is pretty much self-explanatory: mark items/articles I want to **read**
-   this might no seem obvious (why tagging articles as to-read when using a save-for-later-read service?) but I sometimes getpocket for temporary storage
    -   I temporarly add articles/links to it
    -   This way the global **input** bucket will eventually get cloaked


### 2watch {#2watch}

-   used to mark items/links that contain some videos
-   Whenever I have time to watch some videos I use this list to check what I've marked for watching
-   I mostly used this for Youtube videos
    -   But also for articles that contain videos (self-hosted)


### 2listen {#2listen}

-   this is mostly about podcasts
    -   I tag the whole podcast or specific episodes


### 2share {#2share}

-   The content I'm reading/watching is sometimes worth to be **shared**
    -   I either share it with friends/colleagues/family
    -   Add the link to some (bookmark) list (like [these ones](/bookmarks/))
    -   Or I put into my [Tiddlywiki](https://brainfck.org/#Tiddlywiki) instance as a bookmark


### 2print {#2print}

-   I don't own a printer at home so whenever I'm at the copy shop I'd like to have a list of documents/articles to be printed
-   I also put Google Docs links into Getpocket and tag them by `2print`


### 2go {#2go}

-   I sometimes search for local coffee shops or interesting places I'd like to go to
-   this tag helps mark those places so I can find them again


## My setup {#my-setup}

In this last section I'll share some details regarding my workflow, which (getpocket) clients I use and how I manage to stay focussed while going through my articles.


### Browser add-on {#browser-add-on}

Getpocket has for almost every browser [add-ons](https://help.getpocket.com/category/846-category) you can easily use to add content on-the-fly. Try to remember the keyboard shortcuts (I use [Surfingkeys](https://github.com/brookhong/Surfingkeys) but that's a different story) for frictionless interaction. In Chrome for example you can use `CMD+Shift+P` (OS X) or `Ctrl+Shift+P` (Windows/Linux) to add current site to getpocket.

I rarely use this functionality since I try to avoid the browser as much as I can. Not because I'm a freak but
because of distractions every page has to offer. When I want to read sth (and I know there is readmode for Chrome)
I don't want to get distrupted by ads. Whenever I can, I try to read on my E-Reader after having converted the articles to epub and uploaded them to Dropbox.


### (Doom) Emacs {#doom--emacs}

{{% notice tip %}}
You can also check my [dotfiles](https://github.com/dorneanu/dotfiles/tree/master/emacs/doom/.doom.d) if you want to get straight to the point.
{{% /notice %}}

During the last 2 years I've become a huge [Emacs](https://brainfck.org/#Emacs) fan and currently I'm also learning some [Lisp](https://brainfck.org/#Lisp) to even add more customizations.

When it comes to getpocket there is [pocket-reader.el](https://github.com/alphapapa/pocket-reader.el) which is **the** getpocket client for Emacs.

{{< asciinema key="inbox-zero-getpocket" poster="npt:2:34" rows="25" font-size="10px" cols="800" preload="1" >}}


### Workflow {#workflow}

Depending on the content (if it's a Youtube link, an article, a podcast episode) I'll add accordingly `2read`, `2listen` etc. Sometimes I only want to add that link to a collection of links/bookmarks, so it will only get `2share`. In `pocket-reader` I'll then search for items tagged by `2share`, copy the links and **archive** (I'll get to this one immediately) them.

After having tagged the items by `2read`, `2watch`, `2listen`, etc. I then decide which items should get my attention
first. How do I do this? Given GTD's statement that [open loops will attract attention](https://brainfck.org/#GTD%20Managing%20attention) I try to give my brain some "break" from the long `2read` list. Instead I only tag a few by `next`
which I'll actually read and focus on. After I have finished reading **all** of them, I remove the tags `2read` and `next`, **archive** the items and add **new** ones (by adding `next` to some items in the `2read` bucket). Sounds complicated? Let me try to explain using a sequence diagram.

{{< figure src="/posts/img/2021/input-zero/workflow-2share.png" caption="Figure 5: My 2share workflow" >}}

The `2share` workflow consists of several steps:

-   add item to initial list (my-list)
    -   may I already tag the item by `2share`
-   then I share that item with family, friends etc.
    -   or add it to some collection (e.g. bookmarks)
-   I remove tag `2share`
-   I archive the item

{{< figure src="/posts/img/2021/input-zero/workflow-2read.png" caption="Figure 6: My 2read workflow" >}}

The steps here are quite similar:

-   I add the article to the initial list
    -   I might have already tagged the item by `2read`
-   I'll fetch the `next` list, convert it to epub and sent it to Dropbox
    -   or eventually I read the item straight away on my phone/desktop
-   I might also tag that specific item by `2share`
    -   in case I want to share it
-   I remove tags `2read` and `next`
-   I archive the item


## Conclusion {#conclusion}

When used wisely `getpocket` can be an awesome tool (same applies for any other bookmarking/read-later service). Not only you'll save more time by having the right workflow (and discipline!) for your content management, but
you'll also get to read lot more. I'd like to know more about your workflows, how you deal with content to-be-read and what kind of tools/services you use.
