+++
title = "Migrate Tiddlywiki to org-roam - Part 1: Export Tiddlers"
author = ["Victor Dorneanu"]
date = 2022-09-03T22:04:00+02:00
lastmod = 2022-09-05T08:12:01+02:00
tags = ["tiddlywiki", "org"]
draft = false
series = ["Migrate Tiddlywiki to org-roam"]
+++

{{< notice warning >}}

In the **first part** of this series I'll outline the main factors why I've decided
to move my digital garden / braindump / Zettelkasten to [org-roam](https://github.com/org-roam/org-roam) and which factors
have facilitated this decision. In the **2nd part** (still work in progress) I will expand more
how I've built the new [brainfck.org](https://brainfck.org) using [hugo](https://gohugo.io/), [ox-hugo](https://github.com/kaushalmodi/ox-hugo) and [org-roam](https://github.com/org-roam/org-roam).

{{< /notice >}}


## Motivation {#motivation}

I've been using Tiddlywiki for almost 10 years now and setup different instances for
work, personal stuff and lately as my own [personal knowledge management system](https://tw5.brainfck.org). I've
used it to save highlights, notes, quotes from different sources and organized them
in an useful way. I used [daily journaling](https://tw5.brainfck.org/#Journals) to handle the daily input of ideas and (web)
articles I'm constantly exposed to. I talked at work about the importance of PKMS
and how Tiddlywiki can increase productivity and contribute to better (mental) health
by using it as a second brain.
{{% sidenote %}}
Other popular terms: Zettelkasten (slip box in German), memex, braindump or digital garden.
{{% /sidenote %}} Basically it's all about giving your a brain a rest and offload information to a medium so
your brain doesn't have to remember everything:

> Your brain is for having ideas, not for holding them -- [Getting Things Done](https://brainfck.org/book/getting-things-done-the-art-of-stress-free-productivity/)

While I initially started using just one _single_ HTML file for my
tiddlers, I soon switched over to the [nodeJS installation](https://tiddlywiki.com/static/Node.js.html). This still
has better benefits like:

-   you can run the instance in [Docker]({{< relref "2022-tiddlywiki-and-emacs#basic-setup" >}})
    -   install `tiddlywiki` and its dependencies **without** messing around with your system
-   you'll get multiple "flat" files (`.tid` files are in _plain text_)
    -   you can apply `sed`, `awk`, `bash` _foo_ to extract/modify data
    -   even if Tiddlywiki will be discontinued some day, you'll still be able to import your notes in whatever note-taking syntax

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/brainfck-20220903-tw5.png" title="old brainfck - Now available at https://tw5.brainfck.org" caption="" pos="left" >}}

Among the many packages I've used, [stroll](https://giffmex.org/stroll/stroll.html) has definitely changed the way I interacted with
Tiddlywiki. It allowed me to _focus_ more on the note-taking process by dividing the screen
into 2 columns. This allowed me to work on different tiddlers simultaneously. Still it
took me hours to process my notes and digitize them into Tiddlywiki. I guess the UI kind
of slowed me down, mostly because I'm a _keyboard-centric_ user and don't use the mouse that
often. Switching between tiddlers, closing them, creating new ones always involved _mouse
interaction_.

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/tiddlywiki-stroll.png" title="Tiddlywiki using stroll" caption="stroll allowed you to split the screen into multiple columns, backlinks are automatically shown." pos="left" >}}

For the same reason I've been using VIM for more than a decade and since more than 2 years
I'm happy to consider myself an [evil](https://www.emacswiki.org/emacs/Evil) Emacs user. It became not only my primary editor, but
also my [RSS feeds reader]({{< relref "2022-rss-atom-emacs-and-elfeed" >}}), mail client, YouTube video player, IDE, API client... I
basically live in Emacs
{{% sidenote %}}
Here is my [config.org](https://github.com/dorneanu/dotfiles/blob/master/dot_doom.d/config.org)
{{% /sidenote %}} and try to avoid as many context switches as possible.


## Personal preferences {#personal-preferences}


### ORG mode as lingua franca {#org-mode-as-lingua-franca}

After going down the Emacs rabbit hole, I've adopted [ORG mode](https://orgmode.org/) as my main file format for writing documents, exporting these to other formats (PDF, markdown, Confluence, Jira and many others), creating diagrams (mainly plantuml), [presentations](https://slides.dornea.nu/), writing technical documentation and hopefully some day for publishing a whole book. For the note-taking phase I write my notes in ORG mode and create a rudimentary outline sorted by chapters/sections. Usually I use the same structure to create my blog posts from (like I did in the [book summaries](/tags/books)). Extracting pieces of information for individual tiddlers, however, tends to be a _time-intensive process_. I've managed to use [the Tiddlywiki API within Emacs]({{< relref "2022-tiddlywiki-and-emacs#get-tiddler" >}}) but my Elisp skills are still not good for doing more advanced stuff like:

-   fetch existing tiddlers, modify body in a new buffer, save new tiddler
-   when linking text to new/existing tiddler, show list (in the minibuffer) of Tiddlers and if not create new one(s)
-   show cross-references (e. g. Backlinks) for a specific tiddler
-   refile specific (ORG) headline to a new tiddler

All these features are some however doable **within** Tiddlywiki using stroll and [streams](https://saqimtiaz.github.io/streams/). But I don't want to use the web UI anymore since I'm already _inside_ Emacs for the majority of the day 😅


### Editing on steroids {#editing-on-steroids}

At some point I began adopting ORG style syntax for the new tiddlers too:

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/tiddlywiki-syntax.png" title="Tiddlywiki Syntax" caption="Syntax is pretty similar to the ORG mode one" pos="left" >}}

If you pay attention, there are lots of similarities. That's why I could easily _copy and paste_ most of the  ORG content into the tiddlers. As for the rest (source blocks, quotes, examples, sidenotes etc.) manual conversion (or using [ox-tiddly](https://github.com/dfeich/org8-wikiexporters) ) was necessary.

It was especially this part that slowed me down in my post-reading process mainly because:

-   I'm writing my notes in Emacs (using ORG)
    -   converting to full tiddlywiki syntax takes time
-   in some of blog posts (written in [ORG](https://github.com/dorneanu/blog/tree/master/org)) I wanted to include some content from different tiddlers
    -   I had to convert Tiddlywiki content back to ORG syntax again

This back and forth between ORG/Emacs and Tiddlywiki combined with the fact I was maintaining _multiples sources_ of information (my raw notes _in ORG_, my own thoughts / processed notes _in Tiddlywiki_) brought me to [org-roam](https://github.com/org-roam/org-roam). Not only this, but it also forced me to rethink my note-taking workflow and make adjustments to the whole system.

{{< notice info >}}

I'll explicitly cover org-roam, hugo and ox-hugo in the next part.

{{< /notice >}}


## Exporting from Tiddlywiki {#exporting-from-tiddlywiki}

As I've started exporting my notes from Tiddlywiki I soon realized there are 2 options to do so:

-   you could use external standard Unix utilities
    -   and parse files using `sed`, `aws` &amp; co.
-   but you could also use [Tiddlywikis internal templating system](https://tiddlywiki.com/static/TemplateTiddlers) to _generate_ data


### Export tiddlers {#export-tiddlers}

[David Alfonso](https://github.com/davidag) has done a great job and put together a [repository](https://github.com/davidag/tiddlywiki-migrator) that helps you with the
export of tiddlers. All you need is to export all your tiddlers bundled as one single HTML and
then follow the instructions in the `README`.

In my Tiddlywiki root directory I had a `tiddlywiki.info` with a build step to export all tiddlers:

```sh
ls -l
cat tiddlywiki.info
```

```text
total 168
drwxr-xr-x 3 victor users   4096 Aug 30 06:09 output
drwxr-xr-x 2 victor users 163840 Aug 29 21:14 tiddlers
-rw-r--r-- 1 victor users   1316 Aug 16 06:00 tiddlywiki.info
{
    "description": "Basic client-server edition",
    "plugins": [
        "tiddlywiki/tiddlyweb",
        "tiddlywiki/filesystem",
        "tiddlywiki/highlight"
    ],
    "themes": [
        "tiddlywiki/vanilla",
        "tiddlywiki/snowwhite"
    ],
    "build": {
        "index": [
            "--rendertiddler",
            "$:/plugins/tiddlywiki/tiddlyweb/save/offline",
            "index.html",
            "text/plain"
        ],
        "static": [
            "--rendertiddler",
            "$:/core/templates/static.template.html",
            "static.html",
            "text/plain",
            "--rendertiddler",
            "$:/core/templates/alltiddlers.template.html",
            "alltiddlers.html",
            "text/plain",
            "--rendertiddlers",
            "[!is[system]]",
            "$:/core/templates/static.tiddler.html",
            "static",
            "text/plain",
            "--rendertiddler",
            "$:/core/templates/static.template.css",
            "static/static.css",
            "text/plain"
        ],
        "books": [
            "--render",
            "[!is[system]prefix[Cashkurs]tag[Book]]",
            "[encodeuricomponent[]addprefix[books/]addsuffix[.org]]",
            "text/plain",
            "$:/vd/templates/render-book"
        ]
    }
}
```

Now let's generate the single HTML file:

```sh
tiddlywiki . --build index
ls -lh ./output/index.html
```

```text
-rw-r--r-- 1 victor users 6.0M Aug 30 06:09 ./output/index.html
```


### Generate HTML and meta files {#generate-html-and-meta-files}

Once you have generated your single HTML Tiddlywiki file, clone the [repository](https://github.com/davidag/tiddlywiki-migrator) and copy your
file to `wiki.html` inside the repository's root folder. Then you can run `make` to export your tiddlers.

Afterwards, for each tiddler, you will get:

-   a `HTML` file (with the tiddler's content)
-   a `meta` file (containing header information)

{{< figure src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/html-meta-files.png" caption="<span class=\"figure-number\">Figure 1: </span>The original tiddler gets exported into one HTML and one meta file." >}}

As an example (for the "zucker" tiddler):

```sh
cat ./tmp_wiki/output/zucker.html
```

```html
: <ul><li>Auch Saccharose</li><li>Gehört zur Familie der Saccharide</li><li>Formen<ul><li>Einfachzucker<ul><li><a class="tc-tiddlylink tc-tiddlylink-resolves" href="#Glukose">Glukose</a></li><li><a class="tc-tiddlylink tc-tiddlylink-resolves" href="#Fruktose">Fruktose</a></li></ul></li><li>Mehrfachzucker<ul><li>Stärke</li></ul></li></ul></li><li>Haushaltszucker<ul><li>Dissacharid</li><li>Besteht aus 2 Monosacchariden<ul><li>Glukose (Traubenzucker)</li><li>Fruktose (Fruchtzucker)</li></ul></li></ul></li><li><a class="tc-tiddlylink tc-tiddlylink-resolves" href="#S%C3%BC%C3%9Fstoffe">Süßstoffe</a></li></ul>
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  HTML file
</div>

And now the `meta` data:

```sh
cat ./tmp_wiki/output/zucker.meta
```

```text
created: 20200727100215598
lang: de
modified: 20210518184433986
origin: [[<<. bibliography "Der Ernährungskompass" "Der Ernährungskompass">>]]
revision: 0
tags:
title: Zucker
tmap.id: c268554d-9122-4728-88e0-0549ec026010
type: text/vnd.tiddlywiki
```


### Convert to ORG mode {#convert-to-org-mode}

The original repository will export by default all tiddlers to `markdown`. Since `pandoc` is used
we can also export to ORG mode directly by changing the Makefile.
{{% sidenote %}}
I've created a [fork](https://github.com/dorneanu/tiddlywiki-migrator) with my own customizations.
{{% /sidenote %}} Instead of exporting to `commonmark` we export to `markdown` first:

```makefile
...
$(MARKDOWN_DIR)/%.md : $(TW_OUTPUT_DIR)/%.html
    @echo "Generating markdown file '$(@F)'..."
    @$(PANDOC) -f html-native_divs-native_spans -t markdown \
        --wrap=none -o - "$^" >> "$@"
...
```

Then for every generated `markdown` file we

-   add `#+` to every header line (in the corresponding `.meta` file)
-   insert a newline after header lines
-   convert the `markdown` file to `ORG` format

<!--listend-->

```makefile
...

$(ORG_DIR)/%.org : $(MARKDOWN_DIR)/%.md
    @echo "Generating ORG file '$(@F)'..."

    # Add #+ to every header line
    @cat "$(TW_OUTPUT_DIR)/`basename $^ .md`.meta" | sed -s 's/^/#+/' >> "$@"

    # Insert newline after header lines
    @echo "" >> "$@"

    # Convert from markdown to org
    @$(PANDOC) -f markdown -t org --wrap=none -o - "$^" >> "$@"

...
```

{{< figure src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/combined-files.png" caption="<span class=\"figure-number\">Figure 2: </span>The ORG file consists of the meta file (where every line is prepended by #+) and the corresponding markdown file." >}}

This is how the final ORG file looks like:

```sh
cat org_tiddlers/zucker.org
```

```org
#+created: 20200727100215598
#+lang: de
#+modified: 20210518184433986
#+origin: [[<<. bibliography "Der Ernährungskompass" "Der Ernährungskompass">>]]
#+revision: 0
#+tags:
#+title: Zucker
#+tmap.id: c268554d-9122-4728-88e0-0549ec026010
#+type: text/vnd.tiddlywiki

-   Auch Saccharose
-   Gehört zur Familie der Saccharide
-   Formen
    -   Einfachzucker
        -   [Glukose](#Glukose){.tc-tiddlylink .tc-tiddlylink-resolves}
        -   [Fruktose](#Fruktose){.tc-tiddlylink
            .tc-tiddlylink-resolves}
    -   Mehrfachzucker
        -   Stärke
-   Haushaltszucker
    -   Dissacharid
    -   Besteht aus 2 Monosacchariden
        -   Glukose (Traubenzucker)
        -   Fruktose (Fruchtzucker)
-   [Süßstoffe](#S%C3%BC%C3%9Fstoffe){.tc-tiddlylink
    .tc-tiddlylink-resolves}
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  Generated ORG file
</div>


## Extract bookmarks {#extract-bookmarks}

I have lots of bookmarks (each one is mapped to one `tiddler`) tagged in this way:

```sh
cat org_tiddlers/bookmarks/writing_a_technical_book_in_emacs_and_org_mode_.org
```

```org
#+created: 20220201125456750
#+modified: 20220203071728094
#+name: Writing a Technical Book in Emacs and Org Mode
#+note: Author writes about the workflow itself, importance of pomodoro
#+revision: 0
#+tags: Bookmark [[ORG Mode]] Writing
#+title: Writing a Technical Book in Emacs and Org Mode
#+type: text/vnd.tiddlywiki
#+url: https://www.kpkaiser.com/programming/writing-a-technical-book-in-emacs-and-org-mode/
```

So each bookmarks consists of:

-   a _name_
-   a _note_
-   an _url_
-   a _title_ (usually the same as _name_)

Now we can easily parse these files and create the desired structure. For this purpose I've used this tinny `Python` snippet:

```python
import sys
import re

note = ""
url = ""
title = ""
tags = ""
created = ""

for line in sys.stdin:

    # Extract created
    result = re.match("^#\+created: (.*)$", line, re.IGNORECASE)
    if result:
        created = result.group(1)

    # Extract note
    result = re.match("^#\+title: (.*)$", line, re.IGNORECASE)
    if result:
        title = result.group(1)

    # Extract note
    result = re.match("^#\+note: (.*)$", line, re.IGNORECASE)
    if result:
        note = result.group(1)

    # Extract URL
    result = re.match("^#\+url: (.*)$", line, re.IGNORECASE)
    if result:
        url = result.group(1)

    # Extract tags
    result = re.match("^#\+tags: (.*)$", line, re.IGNORECASE)
    if result:
        _tags = result.group(1)
        split = _tags.split(" ")
        tags = ":".join(split)
        if tags:
            tags = f":{tags}:"


# Print
print(f"* [[{url}][{title}]]\t\t{tags}\n  :PROPERTIES:\n  :CREATED: {created}\n  :NOTE: {note}\n  :END:\n ")
```

Used against our bookmark file it will yield:

```sh
cat org_tiddlers/bookmarks/writing_a_technical_book_in_emacs_and_org_mode_.org | python3 /tmp/extract-bookmark.py
```

```org
* [[https://www.kpkaiser.com/programming/writing-a-technical-book-in-emacs-and-org-mode/][Writing a Technical Book in Emacs and Org Mode ]]		:Bookmark:[[ORG:Mode]]:Writing:
  :PROPERTIES:
  :CREATED: 20220201125456750
  :NOTE: Author writes about the workflow itself, importance of pomodoro
  :END:
```

This way we get a nice [ORG mode headline](https://orgmode.org/guide/Headlines.html) with some [properties](https://orgmode.org/guide/Properties.html). Now let's convert
all available bookmarks and save into one big file:

```sh
cd org_tiddlers
rm /tmp/bookmarks.org
grep * -e "#+tags:.*Bookmark*" -l | xargs -I "{}" sh -c "grep -e '^#.*$' {} | python3 /tmp/extract-bookmark.py; mv {} bookmarks/" >> /tmp/bookmarks.org
```

Let's check how many entries we got:

```sh
cat /tmp/bookmarks.org | grep "\* \[\[" | wc -l -
```

```text
425 -
```


## Extract journal entries {#extract-journal-entries}

Collect all `journal` tiddlers and merge them into one big file.

```sh
cd org_tiddlers
rm /tmp/journals.org
grep * -e "#+tags: Journal" -l | xargs -I % sh -c \
   "echo -e '* %' | tr -d '.org' >> /tmp/journals.org; \
    cat % | sed '/^#+tmap.id/d;/^#+title:/d;/^#+tags:/d;/^#+created:/d;/^#+modified/d;/^#+revision/d;/^#+type/d' \
    >> /tmp/journals.org"
head -n 10 /tmp/journals.org
```

```org
* 2020-09-14

- [[https://www.swr.de/swr2/programm/broadcastcontrib-swr-13438.html][Wie funktioniert Selbstregulierung?]]
  - auch in der [[https://www.ardaudiothek.de/wissen/wie-funktioniert-selbstregulierung/80172244][ARD audiothek]]
- Un podcast interesant despre [[https://www.stareanatiei.ro/podcasts/][starea natiei]]
  - este si [[https://www.youtube.com/channel/UCtK5Oe8sHjp6WPcwWuHUVpQ][canal youtube]]
- [[https://stackoverflow.com/questions/42531643/amazon-s3-static-web-hosting-caching][how to use caching with S3 static site hosting]]
* 2020-09-15

- this site supports now [[https://brainfck.org][TLS/SSL]]
```


## Extract books {#extract-books}

This was the most difficult part and I'll try to explain why. This is how a `book` tiddler usually looks like ([1984](https://tw5.brainfck.org/#1984)):

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/1984-tiddler.png" title="1984 book" caption="There are different related tiddlers I've created to each book tiddler" pos="left" >}}

Usually I have some content inside the tiddler but also some additional tiddlers related to the book:

-   **notes/quotes**
    -   most of the time these are **quotes**
    -   Examples: `1984 - Note 1`, `1984 - Note 2` etc.
-   **subtopics**
    -   for each interesting thought/concept I've found in the book I create a new tiddler where the name has following syntax: `<book>/<subtopic>`.
        -   I've initially read about this idea on [Soren's Zettelkasten](https://zettelkasten.sorenbjornstad.com/) and I liked it
    -   Examples:
        -   [1984/Versklavung](https://tw5.brainfck.org/#1984/Versklavung)
        -   [1984/Krieg ist Frieden](https://tw5.brainfck.org/#1984/Krieg%20ist%20Frieden)
        -   [1984/Wohlstand](https://tw5.brainfck.org/#1984/Wohlstand)

Basically I wanted to merge every tiddler into one `ORG` file.

{{< figure src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/book-tiddlers.png" caption="<span class=\"figure-number\">Figure 3: </span>Merge every single tiddler related to 1984 into one big ORG file." >}}

Instead of applying some `sed` &amp; `awk` magic, I decided to use Tiddlywikis internal templating
system. The [$:/core/templates/static.tiddler.html](http://tw5.brainfck.org/#%24%3A%2Fcore%2Ftemplates%2Fstatic.tiddler.html) template for examples defines how a
single tiddler should be exported to its corresponding HTML file:

```html
\define tv-wikilink-template() $uri_doubleencoded$.html
\define tv-config-toolbar-icons() no
\define tv-config-toolbar-text() no
\define tv-config-toolbar-class() tc-btn-invisible
\import [[$:/core/ui/PageMacros]] [all[shadows+tiddlers]tag[$:/tags/Macro]!has[draft.of]]
`<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<meta name="generator" content="TiddlyWiki" />
<meta name="tiddlywiki-version" content="`{{$:/core/templates/version}}`" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
<meta name="mobile-web-app-capable" content="yes"/>
<meta name="format-detection" content="telephone=no">
<link id="faviconLink" rel="shortcut icon" href="favicon.ico">
<link rel="stylesheet" href="static.css">
<title>`<$view field="caption"><$view field="title"/></$view>: {{$:/core/wiki/title}}`</title>
</head>
<body class="tc-body">
`{{$:/StaticBanner||$:/core/templates/html-tiddler}}`
<section class="tc-story-river tc-static-story-river">
`<$view tiddler="$:/core/ui/ViewTemplate" format="htmlwikified"/>`
</section>
</body>
</html>
```

We can use the same mechanism to define a template for a book tiddler whenever this has to be
exported. But first of all let's see how a template is used when exporting:

```makefile
export-books : deps pre
    @echo "Exporting all book tiddlers from $(ORIGINAL_TIDDLYWIKI) to ORG with custom render template"
    $(NODEJS) $(TIDDLYWIKI_JS) $(WIKI_NAME) --load $(ORIGINAL_TIDDLYWIKI) \
        --render [!is[system]tag[Book]] [encodeuricomponent[]addprefix[books/]addsuffix[.org]] \
        text/plain $$:/vd/templates/render-book
    $(NODEJS) $(SAFE_RENAME_JS) $(TW_OUTPUT_DIR)
```

This is what happens:

-   we load the single HTML Tiddlywiki file via `--load`
-   we use `--render`
{{% sidenote %}}
    Read more about the [RenderCommand](https://tiddlywiki.com/static/RenderCommand.html).
    {{% /sidenote %}} to export a list of tiddlers
-   as a filter we use `[!is[system]tag[Book]]` which means:
    -   give me all non-[system tiddlers](https://tiddlywiki.com/static/SystemTiddlers.html) and from this selection
    -   give me all tiddlers tagged with `Book`
-   `[encodeuricomponent[]addprefix[books/]addsuffix[.org]]` handles the file path of tiddler to be exported
-   `$$:/vd/templates/render-book` is the name of the template to be used

And now `$:/vd/templates/render-book` :

```org
\define quotesFilter() [prefix<currentTiddler>!title<currentTiddler>tag[quote]sortan[]]
\define childrenFilter() [prefix<currentTiddler>!title<currentTiddler>!tag[quote]sortan[]]

<$list filter=[all[current]]>
* {{!!title}}
  :PROPERTIES:
  :FINISHED: {{!!finished_year}}-{{!!finished_month}}
  :END:
** Description
{{!!text}}
</$list>

** Notes
<$list filter="[subfilter<childrenFilter>]">
*** {{!!title}}                  :note:
      :PROPERTIES:
      :CREATED: {{!!created}}
      :TAGS: {{!!tags}}
      :END:
</$list>

** Quotes
<$list filter="[subfilter<quotesFilter>]">
*** {{!!title}}                  :quote:
{{!!text}}
</$list>
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3:</span>
  The Tiddlywiki render template I've used to export my books and related tiddlers.
</div>

Let's dissect the snippet fragment by fragment.


### Add book content {#add-book-content}

```org { linenos=true, linenostart=1 }
...
<$list filter=[all[current]]>
* {{!!title}}
  :PROPERTIES:
  :FINISHED: {{!!finished_year}}-{{!!finished_month}}
  :END:
** Description
{{!!text}}
</$list>
...
```

We create a list of tiddlers with following filter: `[all[current]]` (another way to express we just want the _current_ tiddler).
We then create an ORG mode headline consisting of the field `title` in the current tiddler (`{{!!title}}`). Then we add
a `FINISHED` property using the fields `finished_year` and `finished_month`

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/1984-fields.png" title="Fields of 1984 tiddler" caption="Every field in the tiddler can be accessed via {{!!field}}" pos="left" >}}

Then I create a sub-heading called `Description` where I put the tiddler's content (field `text`).


### Add notes {#add-notes}

```org
...
\define childrenFilter() [prefix<currentTiddler>!title<currentTiddler>!tag[quote]sortan[]]
...
** Notes
<$list filter="[subfilter<childrenFilter>]">
*** {{!!title}}                  :note:
      :PROPERTIES:
      :CREATED: {{!!created}}
      :TAGS: {{!!tags}}
      :END:
</$list>
...
```

We create a sub-heading called `Notes` where we add additional sub-nodes. For this to work we create again
a list of tiddlers where we apply the filter: `[subfilter<childrenFilter>]`. `childrenFilter` is defined
at the top:

-   `prefix<currentTiddler>`
    -   We focus only on the tiddlers which have the `currentTiddler` as a prefix.
    -   if `currentTiddler` is 1984, then this will match
        -   `1984 - Note 1`
        -   `1984/Wohlstand`
-   `!title<currentTiddler>`
    -   This makes sure we don't match ourself (the `currentTiddler`)
-   `!tag[quote]`
    -   Match only tiddlers which don't have tag `quote`
-   `sortan[]`

    -   Sort list of tiddlers by text field
{{% sidenote %}}
    The [sortan Operator](https://tiddlywiki.com/static/sortan%2520Operator.html)
    {{% /sidenote %}}

For the sub-heading we then add some properties: `CREATED` (field `created`) and `TAGS` (field `tags`).


### Add quotes {#add-quotes}

```org
\define quotesFilter() [prefix<currentTiddler>!title<currentTiddler>tag[quote]sortan[]]
...
** Quotes
<$list filter="[subfilter<quotesFilter>]">
*** {{!!title}}                  :quote:
{{!!text}}
</$list>
```

Also here we create a sub-heading called `Quotes` and underneath we create additional sub-nodes
for the quotes. As for `Notes` we have a subfilter (`quotesFilter`):

-   it matches all tiddlers which have the currentTiddler's title as a prefix
-   AND are tagged by `quote`.


### Put everything together {#put-everything-together}

Now that we have a template let's have a look at the output:

```sh
$ tiddlywiki . --load ./output/index.html \
               --render "[!is[system]prefix[1984]tag[Book]]" \
               "[encodeuricomponent[]addprefix[books/]addsuffix[.org]]" \
               "text/plain"\
               "$:/vd/templates/render-book"
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4:</span>
  Export everything related to '1984' by applying the <code>$:/vd/templates/render-book</code> template.
</div>

And this is what we get:

```sh
cat ./output/books/1984.org
```

```org
* 1984
  :PROPERTIES:
  :FINISHED: 2021-05
  :END:
** Description
* Theorie und Praxis des oligarchischen Kollektivismus
** von Emmanuel Goldstein
** Kapitel 1: Unwissenheit ist Stärke
** Kapitel 3: 1984/Krieg ist Frieden

** Notes
*** 1984/3 Arten von Menschen                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS: Definition
      :END:

*** 1984/Aufteilung der Welt                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS: Stub
      :END:

*** 1984/Der Große Bruder                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:

*** 1984/Doppeldenk                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:

*** 1984/Krieg                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:

*** 1984/Krieg ist Frieden                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:

*** 1984/Kulturelle Integrität                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:

*** 1984/Rolle der Partei                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:

*** 1984/Versklavung                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:

*** 1984/Wohlstand                  :note:
      :PROPERTIES:
      :CREATED:
      :TAGS:
      :END:
** Quotes
*** 1984 - Note 1                  :quote:
Krieg ist Frieden, Freiheit ist Sklaverei, Unwissenheit ist Stärke - Ministerium für Wahrheit


*** 1984 - Note 2                  :quote:
Gedankendelikt hat nicht den Tod zur Folge: Gedankendelikt IST der Tod.


*** 1984 - Note 3                  :quote:
"Begreifst du denn nicht, dass Neusprech zur ein Ziel hat, nämlich den Gedankenspielraum einzuengen? Zu guter Letzt werden wir
Gedankendelikte buchstäblich unmöglich machen, weil es keine Wörter mehr geben wird, um sie auszudrücken. Jeder
Begriff, der jemals benötigt werden könnte, wird durch exakt ein Wort ausgedrückt sein, dessen Bedeutung streng definiert ist und dessen
sämtliche Nebendeutungen eliminiert und vergessen sind."


*** 1984 - Note 4                  :quote:
Freiheit bedeutet die Freiheit, zu sagen, dass zwei und zwei vier ist. Gilt dies, ergibt sich alles übrige von selbst.


*** 1984 - Note 5                  :quote:
Die Massen revoltieren nie aus eigenem Antrieb, und sie revoltieren nie, nur weil sie unterdrückt werden. Solange man ihnen die Vergleichsmaßstäbe entzieht, werden sie nicht einmal merken, dass man sie unterdrückt.
```

I think that's pretty good.
{{% sidenote %}}
And this is the final [result](https://brainfck.org/book/1984/).
{{% /sidenote %}} {{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/brainfck-20220903-hugo.png" title="New brainfck.org" caption="" pos="left" >}}

I intentionally didn't add content in the `Notes` section to the sub-nodes. In the next post
I'll explain how I managed to quickly review my notes using `Emacs` and some `Elisp` and add content on the go.
