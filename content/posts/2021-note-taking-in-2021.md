+++
title = "Note taking in 2021"
author = ["Victor Dorneanu"]
date = 2021-06-13T14:56:00+02:00
lastmod = 2021-06-13T15:10:14+02:00
tags = ["golang", "tiddly"]
draft = false
+++

Almost 6 years ago I was blogging about [organizing and visualizing knowledge](/2015/09/17/organizing-and-visualizing-knowledge/). At that time I was just playing around with [ Tiddlywiki](https://brainfck.org/#Tiddlywiki) and using it to collect notes during my [CCNA](/tags/ccna/) course. I couldn't anticipate to which extent [personal knowledge management systems](https://en.wikipedia.org/wiki/Personal%5Fknowledge%5Fmanagement) would become famous and trendy. And people nowadays don't blog anymore: They take care of their [digital gardens](https://joelhooks.com/digital-garden). While most of them seem to be just a collection of random notes, there are actually good ones where you can actually read through the thoughts/notes and learn something new. Here are my favourite ones:

-   [Andy Matuschanks Digital Garden](https://notes.andymatuschak.org/About%5Fthese%5Fnotes)
-   [Jethro's Braindump](https://braindump.jethro.dev/) (build with [ ORG Mode)](https://brainfck.org/#ORG%20Mode) and [ox-hugo](https://ox-hugo.scripter.co/))
    -   more in his [github repository](https://github.com/jethrokuan/braindump)
-   [Personal Zettelkasten of Soeren](https://zettelkasten.sorenbjornstad.com/)
    -   Did I already mention what a [ Zettelkasten](https://brainfck.org/#Zettelkasten) is about?

And what about me? Yes, I still blog but I also have a digital garden available at [brainfck.org](https://brainfck.org). For me blogging and maintaining a public source of inspirations and ideas is not the same. A blog post should be readable and contain full sentences. A collection of ideas/thoughts can be just some bullet points with some random links (for me they're not random, since I actively set those links in order to inter-connect notes). The idea is that I use my `PKMS` to lookup things and generate new content (like this post). That's for the introduction. Now let's talk about the importance of having and maintaining a source of notes/thoughts.


## Motivation {#motivation}

After all: What's all the fuzz about "note taking"? You have them __somewhere__, you use them __somehow__. Well, there it's more than that. In my job as a Security Engineer I need to keep up with new technologies and arising attack vectors. Additionally I tend to [read](https://brainfck.org/#Books) about non-IT topics I'm currently
interested in. Each time I want to make sure I don't have to re-read/review that source again when I think I might use an interesting idea/concept out of it.
Making future-proof notes (a terminology used in a [ Zettelkasten](https://brainfck.org/#Zettelkasten) system) is essential for me also because I use that content to generate new one.

Not only in a professional context, but also for private purposes it does make sense to __actively__ read your books/articles. Try to apply some __analytical reading__, a concept I've read about for the first time in [ How to read a book (book)](https://brainfck.org/#How%20to%20read%20a%20book). The idea is to interact with the content you're reading about: Ask questions, try to link ideas in your mind, make notes, lookup complex definitions. The worst thing you can do is to just __passively__ read something, finish it and then you move on to your next reading. After finishing a book, I always take some time (1-3 hours) to go through my notes, adjust already existing ones or link them to other ones.


## The perfect setup {#the-perfect-setup}

I've spent the last years, trying to find not only the perfect note **taking** system but also the most proficient note **storage** system. I don't want to dissapoint you, but there is no perfect solution. You just need one system that fulfills __your needs__, is easy to use and will most probably still work in a couple of years.
Let's have a look at my current setup which has envolved over the last 2-3 years and definitely will change whenever I think I can optimize each step individually.


## Note taking {#note-taking}

For me this is the most important step when dealing with sources of information in general. The process of note taking is supposed to help you to internalize the main concepts and the authors ideas. In this step taking __temporary notes__ as described by Söhnke Ahrens in his book "How to take smart notes" (german: [ Das Zettelkasten-Prinzip](https://brainfck.org/#Das%20Zettelkasten-Prinzip)) will give you a good starting point for storing them in a __permanent__ manner. But more on this below.


### Pen and paper {#pen-and-paper}

This is still my favourite way of writing things down and collecting so called __temporary notes__ as described by Söhnke Ahrens in his book "How to take smart notes" (german: [ Das Zettelkasten-Prinzip](https://brainfck.org/#Das%20Zettelkasten-Prinzip)). All you need is just a piece of paper and something to write. You're free to use whatever structure you want as long as it doesn't disturb your reading flow. Add diagrams, bullet points, symbols or everything you think is necessary.

The downside of this analogue method is the fact your notes could get lost at some point. You have no automated backups in-place and if you lose your "paper" notes,
also your work is gone.


#### Some examples {#some-examples}

{{< figure src="/posts/img/2021/note-taking/note-taking-paper.jpg" caption="Figure 1: Taking notes on A5 paper (notes for the book [1984](https://brainfck.org/#1984))" >}}

{{< figure src="/posts/img/2021/note-taking/note-taking-technical.jpg" caption="Figure 2: The same also for tech books (notes for the book [Black Hat Go](https://brainfck.org/#Black%20Hat%20Go))" >}}

{{< figure src="/posts/img/2021/note-taking/note-taking-a4.jpg" caption="Figure 3: Taking notes in a A4 notebook (notes for [ How not to die](https://brainfck.org/#How%20not%20to%20die))" >}}

{{< figure src="/posts/img/2021/note-taking/note-taking-a5.jpg" caption="Figure 4: Works with A5 as well (its easier to carry it around, notes for [The Big Five for Life](https://brainfck.org/#The%20Big%20Five%20for%20Life))" >}}

{{< figure src="/posts/img/2021/note-taking/note-taking-project.jpg" caption="Figure 5: A5 is also good for keeping track of (non-IT) projects such as camping boxes for the car :)" >}}

{{< figure src="/posts/img/2021/note-taking/note-taking-djembe.jpg" caption="Figure 6: I also use paper to store patterns, notes for drumming (in my example Djembe/Darbuka). I can always carry them around and I have everything at one place." >}}


### Smartphone {#smartphone}

Yes, this might surprise you, but I do use my smartphone to take notes, especially when I don't have a "piece of paper" with me. The best thoughts will come to your mind when you don't expect them to do so. And in that case you should be better prepared to write them down.


#### orgzly {#orgzly}

At some point I've started using [orgzly](http://www.orgzly.com/) which worked fine for [ ORG mode](https://brainfck.org/#ORG%20Mode) in combination with [syncthing](https://syncthing.net/) for the cross-device synchronization. However, once I've came back to [ Tiddlywiki](https://brainfck.org/#Tiddlywiki) I've somehow abandoned orgzly in flavour of [miMind](https://mimind.cryptobees.com/).

{{< youtube GYhIMHjGzjQ >}}


#### miMind pro {#mimind-pro}

This little (mobile) application has great usability and it does help you to quickly add new notes, structured as a mind map. You can then easily export your map as XML which can then be converted to [ORG](/tags/org) format.

{{< youtube IR-8q6TQZ7c >}}

In the application itself (as shown in the video) you can export your mind map to a XML file which can be converted to [ORG](/tags/org) using this small [Golang](/tags/golang) utility:

{{< gist dorneanu 906facb9aa2eb88c51dd348cdeaddf97 "main.go" >}}

Once you have download all files included in the gist you can run it against your miMind XML file. In my case I had this XML:

```shell
❯ head Ernährungskompass.xml
<Root>
<Header info="Created with miMind software."></Header>
<Content>
<Node Title="Ernährungskompass">
<Node Title="Kapitel 1">
<Node Title="Der Eiweisseffekt">
<Node Title="Tiere sind auf Proteinsuche bis sie ihren Proteinbedarf gedeckt haben"></Node>
<Node Title="Zu viele Proteine sind auch nicht gut, da sie den Alterungsprozess begünstigen"></Node>
</Node>
<Node Title="Insektenforscher">
```

```shell
$ go run main.go -hl 1 -f Ernährungskompass.xml | head
...
```


### Desktop {#desktop}

[ GTD](https://brainfck.org/#GTD) suggests to always [ capture](https://brainfck.org/#GTD/Input) what has our attention. Also minizing the number of possible capture locations makes your life even easier. But I also tend to capture my thoughts where it feels most comfortable. If I'm doing some work at my laptop and suddenly some idea comes to my mind, then I'll capture it on my laptop. In that case I won't grab a piece of paper, put a label on it (to remember what the thought was about) and then put it aside. I'd rather use tools on my desktop system.

During the last months 2 __input capture systems__ established and have become part of my note capture routine:

-   [ORG Capture](https://orgmode.org/manual/Capture.html)
    -   Intergrated within Emacs and ORG mode
    -   I use it mainly for events, appointments or TODOs
    -   I'm not using it anymore for storing thoughts, bookmarks, ideas since I've moved back to Tiddlywiki
-   [ Tiddlywiki](https://brainfck.org/#Tiddlywiki)
    -   I always have a running (nodeJS) instance in my browser ([here you can view the exported version](https://brainfck.org))
    -   Whenever I think something should be added to an existing note, I open that tab, search for that specific __tiddler__ (a page/note in the Tiddlywiki ecosystem) and make the changes
    -   I also used for storing notes to podcasts, articles I listen/read to/about during the day

{{< figure src="/posts/img/2021/note-taking/note-taking-journal.jpg" caption="Figure 9: Whenever I work at my laptop and think I need to write sth down, bookmark a site, I use Tiddlywiki's journals to do so (link to that specific journal: [2021-12-03](https://brainfck.org/#2021-12-03))" >}}

{{< figure src="/posts/img/2021/note-taking/note-taking-list-of-journals.jpg" caption="Figure 10: Here is a list of some [ Journal](https://brainfck.org/#Journal) entries" >}}


## Note storage {#note-storage}

Contrary to what [Lukas Luhmann](https://en.wikipedia.org/wiki/Niklas%5FLuhmann) was doing with his "slip box" (german: Zettelkasten) I like to have my notes stored digitally. Not only I can easily make multiple
backups and store them at different locations, but I can also apply batch operations (text modification, add/remove tags etc.) using command line tools like `sed`, `awk` & co. And as with the [ Unix](https://brainfck.org/#Unix) philosophy [everything is a file](https://en.wikipedia.org/wiki/Everything%5Fis%5Fa%5Ffile) I like to cluster notes (on the same topic) in one single file. This solution is completely software agnostic and files can be modified accordingly to be imported into different note-taking systems.


### Requirements {#requirements}

I wrote this post in order to give you some ideas what worked best for _me_ but it's up to you to define which requirements you need for a simple, working solution. For me these
requirements were _essential_:

-   **digital solution**
    -   like I've mentioned before I do think digital solutions are the better long-term storage systems
    -   you can easily backup them
    -   you can share between multiple devices
    -   you can have version control in-place
-   **edit from (almost) everywhere**
    -   well in theory you should be able to view, modify your notes regardless of the device:
        -   desktop system
        -   smartphone
        -   terminal
        -   web client
    -   I also like to add/modify notes on the fly
-   **good looking UI**
    -   Being a "terminal guy" for many, many years now I didn't thought I would put this as a requirement
    -   However, once you can actually "visualize" your content or more important see the connections between your notes, you'll definitely start to appreciate **UI**
    -   Adding new content or modifying existing one shouldn't be a rocket science
-   **export content**
    -   solution has to be _software agnostic_
    -   Imagine in 20 years you'll have to import your notes into some fancy, AI-driven, blockchain-based note system :)
    -   You should be able to do this without massive data manipulation
    -   You should be able to export **all** content to a common format (who knows if JSON will still be around in 20 years)
        -   no proprietary format!
    -   If you use tags and extra fields for your content, then it should be easy to use them in the new system
    -   You should export all content to a readable form and share it online (like a _digital garden_)


## Final thoughts {#final-thoughts}

I really recommend taking this whole topic more seriously since it will pay off on many layers. Not only you'll be able to deep-dive into multiple topics at once, but you'll have a solid
collection of notes/thoughts for later. Having a solid note eco-system will definitely increase your productivity and overall focus since we already spend to much time _googling_ stuff.
**Use your brain for what it was built for**: Thinking, cognitive processes and creativity. Definitely not for storing information.
