+++
title = "Organizing and visualizing knowledge"
author = "Victor Dorneanu"
date = "2015-09-17"
tags = ["viz", "pocket", "xmind", "tiddly", "wiki", "pkms"]
category = "blog"
+++

I've been recently looking for some new ways organizing my notes/thoughts/tasks/bookmarks/whatever in order to keep things clean and *backup* valuable information. After spending some time reading others efforts to do that, I've realized that mine were not that bad. Let me give you some overview how I keep track of bits of information and which tools are best suited for every day tasks.

## Mind maps

I've repeated this one several times: I like [visualizing](http://blog.dornea.nu/tag/viz/) information. When taking **notes** I do that in a non-linear way. I don't really like tables or lists which in my oppinion is the *static* way of organizing stuff. I rather try to structure my thoughts in **mind maps**. 
I've been using [XMind](https://www.xmind.net) as my first note taking app for more than 3 years. I usually use it for:

* creating new concepts
* roadmaps
* designing workflow processes
* structuring interrelated *knowledge* domains

You can easily structure your information in your desired layout:
![XMind](/posts/img/2015/organize/73b67a8fe370adae481d579462ed3bae.png "XMind")

Attaching screenshots or notes is also allowed:
![XMind](/posts/img/2015/organize/1d6e071a80a321d3b9c37a59e7bfc17d.png "XMind")

## Bookmarks and web stuff

I have a lot of information ressources which I try to have a look at on a daily basis:

* [Twitter](https://twitter.com/victordorneanu)
* feeds
* several blogs
* etc.

When dealing with large articles I like to **read them later** and save them to a *to-read* list. [getpocket](https://getpocket.com) has helped me organizing my links for ca. 2 years. You can structure your information using *tags* and *archive* your read articles. For a while I was using [crofflr](http://www.crofflr.com) for sending tagged articles in my *getpocket* list to my Kindle device. I also use *getpocket* for sharing links between my devices: Android, Laptop, PC. And besides that: (Almost) every modern browser has an **add-on** for this service.

This is my archived list of items:
![Pocket Archive](/posts/img/2015/organize/6da00f35bac361f6fd89c4c4c0ec2752.png "Pocket Archive")

*Pocket* can also distinguish between *articles*, *images* or *videos*. Here is my archived images list:
![Pocket Images](/posts/img/2015/organize/a06a9acf53d24268e86b39d9be193aa3.png "Pocket Images")


## Task management

Since everybody has some tasks to be completed, I also had the agony of choice between Todoist, Wunderlist, Any.Do ... And then I've found [Google Keep](httphttps://play.google.com/store/apps/details?id=de.mgsimon.android.andtidwiki://www.google.com/keep/). I really love the layout and the widgets (although I'm not a hardcore *widge*list user). With Keep I can create note *lists* that can have several TODO points and just some text. Plus: I can apply different colors to the notes and share them with my contacts. I usually check out my todo list for that particular day, complete them and then just mark it as done on my smartphone.

Creating a new task is very easy:
![Google Keep - New Task](/posts/img/2015/organize/e9dda9fb2b5fcbbcac6b16b89859505d.png "Google Keep - New Task")

You can access your tasks via web or smartphone:
![Google Keep](/posts/img/2015/organize/31aff37cabaa520c2b54518b17e84beb.png "Google Keep")

I have even used Google Keep for managing the release of [smalisca](https://github.com/dorneanu/smalisca) v0.1:

![Google Keep - smalisca.01](/posts/img/2015/organize/9274a2db057ad874a0a462f65994f63d.png "Google Keep - smalisca 0.1")

## Personal wiki

Sometimes you may want to combine all that into a single tool in order to:

* have your todo list
* write down some thoughts you had during the day
* organize some events
* record ideeas that crosses your brain
* take notes during some (online) course
* organize your notes in a visual way (mindmaps anybody? :)

This is where [TiddlyWiki](http://tiddlywiki.com) caught my attention. I have not used Tiddly for a long time, but I think its main features are:

* Available for many platforms
    * single **HTML** page and some **JavaScript**
    * [Android](https://play.google.com/store/apps/details?id=de.mgsimon.android.andtidwiki)
    * Chrome/Firefox/Internet Explorer/Safari
    * [iPad/iPhone](https://itunes.apple.com/gb/app/twedit/id409607956?mt=8)
    * [node.js](http://tiddlywiki.com/#Node.js) (preferred installation method)
* file based
    * no need for a DB 
    * easily editable 
* tiddlers
    * bit of [information](http://tiddlywiki.com/static/ContentType.html) 
    * it can be a book chapter, a section, a wiki page, a JSON file, a PNG/JPG file
    *  this way you can structure your information depending on its type
* portable
    * you can copy your tiddlywiki to your USB stick
    * you can sync your data to be available online
* journals
    * journals are [*tiddlers*](http://tiddlywiki.com/static/Creating%2520journal%2520tiddlers.html) that use a timestamp (date or time) as their title
    * usually used to record time-stamped information 
* extendable 
    * there are a lot of available plugins
    * among these: [D3 Plugin](http://tiddlywiki.com/#D3%20Plugin), [Markdown Plugin](http://tiddlywiki.com/#Markdown%20Plugin), [KaTeX Plugin](http://tiddlywiki.com/#KaTeX%20Plugin), 
    * you can easily write your own plugins

So this whole list is very promising. When I've started looking for a suitable wiki, I wanted to keep things simple and don't over-engineer stuff. Having previously used *XMind* as my primary notes taking tool, I want to keep track of my notes in a more "convenient" way. I wanted to make "relationships" between my pieces of information and be able to extend it in a uncomplicated way. Then I've found *TiddlyWiki*. And digging deeper I've also found [TiddlyMap](http://tiddlymap.org) a **really** cool way of *visualizing* the links between your tiddlers and not only. 

With *TiddlyWiki* and *TiddlyMap* you'll get a nice overview not only of the content but also on inter-related topics:
![TiddlyMap](/posts/img/2015/organize/5696b3eb316fac6e2b7460183a6dd97a.png "TiddlyMap")

TiddlyMap will automatically create links between your tiddlers if it founds *links* in a tiddler:

![TiddlyMap](/posts/img/2015/organize/d9d7dd9bfad825475373bc6ebc3281b7.png "Tiddly Map - Connections between interrelated tiddlers")

But you can also manually create links between your tiddlers: 

![TiddlyMap - Connections](/posts/img/2015/organize/50359ca7124ff81f7fa5b8b1553dd517.png "TiddlyMap - Connections")

## Final thoughts

Using all those tools on a regular basis I think each tool has its own specific features depending on your needs. There is *no* super tool and you should not try to rely on a single tool. I like Tiddly for organizing content but I think I won't save my bookmarks as a tiddler. There are better tools for this job (like *getpocket*). Try them out and judge for yourself. 

And regarding *Tiddly* I've found some interesting links (archived using *getpocket* ^^) you might have look at:

* [TW5 Magick](http://tw5magick.tiddlyspot.com)
* [TiddlyWiki Squared](http://iani.github.io/tw5square/)
* [dGSD - A GTD-based Task and Project Management Wiki](http://thinkcreatesolve.biz/dGSD.html)
* [Visualisations with d3.js and others](http://d3tw.tiddlyspot.com) 

PS: This blog post was writen using Tiddly :) 


