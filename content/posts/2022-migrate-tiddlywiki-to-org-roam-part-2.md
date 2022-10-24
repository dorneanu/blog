+++
title = "Migrate Tiddlywiki to org-roam - Part 2: org-roam and hugo"
author = ["Victor Dorneanu"]
date = 2022-10-04T21:43:00+02:00
lastmod = 2022-10-18T22:12:10+02:00
tags = ["hugo", "pkms", "tiddlywiki", "emacs", "org"]
draft = false
series = ["Migrate Tiddlywiki to org-roam"]
+++

{{< notice warning >}}

In the [first part]({{< relref "2022-migrate-tiddlywiki-to-org-roam-part-1-export-tiddlers" >}}) of this series I've outlined the main factors for moving my digital
garden / braindump / Zettelkasten to [org-roam](https://github.com/org-roam/org-roam) and which factors have facilitated this
decision. In the **2nd part** I will expand more how I've built the new [brainfck.org](https://brainfck.org) using
[hugo](https://gohugo.io/), [ox-hugo](https://github.com/kaushalmodi/ox-hugo) and [org-roam](https://github.com/org-roam/org-roam).

{{< /notice >}}

Extracting tiddlers from my [Tiddlywiki setup](https://tw5.brainfck.org) was only the first step towards a [Second
Brain](https://brainfck.org/book/building-a-second-brain/) using [org-roam](https://www.orgroam.com/). Since I'm a clear advocate for **public** digital gardens, I didn't want
to keep my notes only for my self. Having built several sites with [hugo](https://gohugo.io) already, it felt
natural to chose it as a publishing system for my new setup.

In the following I will try to emphasize some important challenges I have experienced
while _migrating_ Tiddlywiki tiddlers to org-roam, creating and editing the content and finally
_export_ it to HTML via `hugo`.


## hugo {#hugo}

As a starting point I have used [Jethro's braindump repository](https://github.com/jethrokuan/braindump) especially for the `Elisp` part.
{{% sidenote %}}
You can also have a look at my [own repository](https://github.com/dorneanu/roam).
{{% /sidenote %}} First of all I'm a big fan of `Makefiles`:

```makefile
export:
	python build.py
dev:
	hugo server -b http://127.0.0.1:1315/ -v --port 1315 --noHTTPCache --cleanDestinationDir --debug --gc
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Makefile
</div>

I use `python`
{{% sidenote %}}
I plan to switch to some Makefile only version in the future.
{{% /sidenote %}} for the export task:

```python
#!/usr/bin/env python

import glob
from pathlib import Path

# files = glob.glob("org/books/done/*.org") + glob.glob("org/topics/*.org") + glob.glob("org/journal/*.org")

with open('build.ninja', 'w') as ninja_file:
    ninja_file.write("""
rule org2md                            ❶
  command = emacs --batch -l ~/.emacs.d/init.el -l publish.el --eval '(brainfck/publish "$in")'
  description = org2md $in
""")

    # Pages                            ❷
    files = glob.glob("org/*.org")
    for f in files:
        path = Path(f)
        output_file = f"content/pages/{path.with_suffix('.md').name}"
        ninja_file.write(f"""
build {output_file}: org2md {path}
""")

    # Books                            ❸
    files = glob.glob("org/books/done/*.org")
    for f in files:
        path = Path(f)
        output_file = f"content/books/{path.with_suffix('.md').name}"
        ninja_file.write(f"""
build {output_file}: org2md {path}
""")

    # Journal                          ❹
    files = glob.glob("org/journal/*.org")
    for f in files:
        path = Path(f)
        output_file = f"content/journal/{path.with_suffix('.md').name}"
        ninja_file.write(f"""
build {output_file}: org2md {path}
""")

    # Topics                           ❺
    files = glob.glob("org/topics/*.org")
    for f in files:
        path = Path(f)
        output_file = f"content/topics/{path.with_suffix('.md').name}"
        ninja_file.write(f"""
build {output_file}: org2md {path}
""")



import subprocess
subprocess.call(["ninja"])             ❻
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  build.py
</div>

This small snippet generates ❶ [build statements](https://ninja-build.org/manual.html#_build_statements) for [ninja](https://pypi.org/project/ninja/) ❻. The `build.ninja` file will contain something similar to:

```makefile
rule org2md
  command = emacs --batch -l ~/.emacs.d/init.el -l publish.el --eval '(brainfck/publish "$in")'
  description = org2md $in

build content/pages/index.md: org2md org/index.org

build content/pages/bookshelf.md: org2md org/bookshelf.org

build content/books/breath_the_new_science_of_a_lost_art.md: org2md org/books/done/breath_the_new_science_of_a_lost_art.org

[...]
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3:</span>
  build.ninja
</div>

For each folder in my `org-roam-directory` (pages ❷, books ❸, journal ❹, topics ❺)

-   [glob](https://docs.python.org/3/library/glob.html#) will find any ORG files
-   a new [ninja build statement](https://ninja-build.org/manual.html#_build_statements) will be written to `build.ninja`

Each build command consists of `org2md` which internally calls `publish.el`:

```emacs-lisp
(require 'package)
(package-initialize)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "http://orgmode.org/elpa/")))

(require 'find-lisp)
(require 'ox-hugo)

;; https://github.com/kaushalmodi/ox-hugo/issues/500#issuecomment-1006674469
(defun replace-in-string (what with in)
  (replace-regexp-in-string (regexp-quote what) with in nil 'literal))

(defun zeeros/fix-doc-path (path)          ❸
  ;; (replace-in-string "../../topics/" "" (replace-in-string "../../topics/" "" path)
  (replace-in-string "../../topics/" "../topics/" path)
  (replace-in-string "../books/done/" "../books/" path)
  (replace-in-string "books/done/" "books/" path)

  )

❹
(advice-add 'org-export-resolve-id-link :filter-return #'zeeros/fix-doc-path)

(defun brainfck/publish (file)             ❶
  (with-current-buffer (find-file-noselect file)
    (setq-local org-hugo-base-dir "/cs/priv/repos/roam")
    ;; (setq-local org-hugo-section "posts")
    (setq-local org-export-with-tags nil)
    (setq-local org-export-with-broken-links t)
    (add-to-list 'org-hugo-special-block-type-properties '("sidenote" . (:trim-pre t :trim-post t)))
    (setq org-agenda-files nil)
    (let ((org-id-extra-files (directory-files-recursively org-roam-directory "\.org$")))
      (org-hugo-export-wim-to-md))))       ❷
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4:</span>
  publish.el
</div>

The main function `brainfck/publish` ❶ basically calls `org-hugo-export-wim-to-md` ❷ which
will "export the current subtree/all subtrees/current file to a Hugo post". Before doing
so some local variables are set and `org-id-extra-files` is populated with all available ORG
roam file paths. This variable holds all files/paths where ORG should search for IDs.

And because some IDs couldn't be resolved properly
{{% sidenote %}}
Obviously there is a [bug](https://github.com/kaushalmodi/ox-hugo/issues/500#issuecomment-1006674469).
{{% /sidenote %}} I had to use some "hook" ❹ for rewriting ❸
some file paths within the generated markdown files.

For testing purposes you can call the `publish.el` with just one argument:

```sh
$ emacs --batch -l ~/.emacs.d/init.el -l publish.el --eval "(brainfck/publish \"org/books/done/building_microservices_2nd_edition.org\")"

[...]
Loading gnus (native compiled elisp)...
Ignoring ’:ensure t’ in ’lsp-ui’ config
Ignoring ’:ensure t’ in ’json-snatcher’ config
Initializing org-roam database...
Clearing removed files...
Clearing removed files...done
Processing modified files...
Processing modified files...done
Clearing removed files...
Clearing removed files...done
Processing modified files...
Processing modified files...done
org-super-agenda-mode enabled.
[...]
Loading linum (native compiled elisp)...
768 files scanned, 410 files contains IDs, and 426 IDs found.
[ox-hugo] Exporting ‘Building Microservices (2nd edition)’ (building_microservices_2nd_edition.org)
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5:</span>
  Example call for publish.el
</div>


### Backlinks {#backlinks}

Backlinks are an essential feature that let you visualize inter-connected content.
Whenever I set a link to another `org-roam` node in an ORG file, the exported markdown content will look like this:

```markdown
...
-   2022-09-05 ◦ [Authenticating SSH via User Certificates (server) · Yubikey Handbook](https://ruimarinho.gitbooks.io/yubikey-handbook/content/ssh/authenticating-ssh-via-user-certificates-server/)  ([SSH]({{</* relref "../topics/ssh.md" */>}}))
...
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 6:</span>
  Excerpt from my journal entry <a href="https://brainfck.org/j/2022-09-05">2022-09-05</a>
</div>

You can see I've set a reference to [SSH](https://brainfck.org/t/ssh) which looks like this:

```nil
[SSH]({{</* relref "../topics/ssh.md" */>}})
```

The question is: For a given node/topic how can we find all nodes containing a link to current node? Well we can parse
content and actually _search_ for that specific topic. In `hugo` you can do something like this:

```go
...
{{ $re := printf `["/(]%s.+["/)]` .page.File.LogicalName | lower }} ❶
{{ $backlinks := slice }}

{{ range where site.RegularPages "RelPermalink" "ne" .page.RelPermalink }}
{{ if (findRE $re .RawContent 1) }}                                 ❷
        {{ $backlinks = $backlinks | append . }}                    ❸
    {{ end }}
{{ end }}
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 7:</span>
  hugo partial to scan for backlinks for a given page
</div>

-   ❶ `.page.File.LogicalName` is sth like `ssh.md`
    -   `` `["/(]%s.+["/)]` .page.File.LogicalName | lower `` will then yield `` `["/(]ssh.md.+["/)]` ``
-   ❷ find any lines containing the logical file name (`ssh.md`) inside parantheses
    -   examples: [ssh.md], "ssh.md", (ssh.md)
-   ❸ if we have any matches add page to `$backlinks` slice

Let's have a look at the regular expression. Therefore I'll use some `Go` snippets to test the regexp:
{{% sidenote %}}
You can also play [here](https://regex101.com/r/agR7Ko/2).
{{% /sidenote %}}
```go
package main

import (
    "fmt"
    "regexp"
)

func main() {
    pattern := regexp.MustCompile(`(?i)["/(]ssh.md.+["/)]`)
    inputs := []string{
        "[SSH]({{</* relref \"../topics/ssh.md\" */>}})",
        "[we mention SSH in the link description]({{</* relref \"../topics/ssh.md\" */>}})",
        "[no mention at all]({{</* relref \"../topics/ssh.md\" */>}})",
        "[no mention at all, also in the ref]({{</* relref \"../topics/other.md\" */>}})",
    }

    for _, i := range inputs {
        matches := pattern.FindAllString(i, -1)
        if len(matches) > 0 {
            fmt.Println(matches)
        }
    }
}
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 8:</span>
  Small Go utility to test our regexp against some common use cases.
</div>

```nil
[/ssh.md" */>}})]
[/ssh.md" */>}})]
[/ssh.md" */>}})]
```

Once we have populated the `backlinks` slice with a list of pages backlinking to the current page
we can then search inside the page content for exactly the lines containing the backlink:

```go
{{ $content_re := printf `.*\[%s\].*` .page.Title }}                    ❶
...
    {{ range $backlinks }}
        {{ $matches := findRE $content_re .RawContent}}
            <li class="lh-copy"><a class="link f5" href="{{ .RelPermalink }}">{{ .Title }}</a></li>
            {{ if $matches }}                                           ❷
                <blockquote>
                    {{ range $matches }}
                    {{ . | markdownify }}
                    {{ end }}
                </blockquote>
        {{ end }}
    {{ end }}
...
```

-   We search for any line containing the current page title (❶)
-   If we have any matches we call `markdownify` against that line (❷)

And this is how the result [looks like](https://brainfck.org/t/ssh):

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/backlinks.png" title="Backlinks for the SSH page" caption="For any available hugo page/node we search for backlinks. These are the backlinks for the SSH topic: https://brainfck.org/t/ssh " pos="left" >}}

For the sake of completeness here's the full [backlinks partial](https://github.com/dorneanu/roam/blob/main/layouts/partials/backlinks.html):

```html
{{ $re := printf `["/(]%s.+["/)]` .page.File.LogicalName | lower }}
{{ $content_re := printf `.*\[%s\].*` .page.Title }}
{{ $backlinks := slice }}

{{ range where site.RegularPages "RelPermalink" "ne" .page.RelPermalink }}
    {{ if (findRE $re .RawContent 1) }}
        {{ $backlinks = $backlinks | append . }}
    {{ end }}
{{ end }}

<hr>
{{ if gt (len $backlinks) 0 }}
<div class="bl-section">
    <h3>Links to this note</h3>
    <div class="backlinks">
        <ul>
            {{ range $backlinks }}
                {{ $matches := findRE $content_re .RawContent}}
                    <li class="lh-copy"><a class="link f5" href="{{ .RelPermalink }}">{{ .Title }}</a></li>
                    {{ if $matches }}
                        <blockquote>
                            {{ range $matches }}
                            {{ . | markdownify }}
                            {{ end }}
                        </blockquote>
                {{ end }}
            {{ end }}
        </ul>
    </div>
</div>
{{ else }}
<div class="bl-section">
    <h4>No notes link to this note</h4>
</div>
{{ end }}
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 9:</span>
  hugo partial for generating backlinks
</div>

As a last step I had to make use of this partial in my [single.html](https://github.com/dorneanu/roam/blob/main/layouts/_default/single.html) template:

```html
...

  <div class="lh-copy post-content">{{ .Content }}</div>
  {{ partial "backlinks.html" (dict "page" .) }}

...
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 10:</span>
  In order to use the backlinks partial, you'll have to embed in your <code>single</code> template.
</div>


### Section pages {#section-pages}


#### Group topics by capital letter {#group-topics-by-capital-letter}

For the [topics](https://brainfck.org/topics) page I wanted to group my topics by the first letter. Therefore in `layouts/topics/list.html` I've inserted following:

```html
{{ define "main" }}
<main class="center mv4 content-width ph3">
    <h1 class="f2 fw6 heading-font">{{ .Title }}</h1>
    <div class="post-content">
    {{ .Content }}

    <!-- create a list with all uppercase letters -->
    {{ $letters := split "ABCDEFGHIJKLMNOPQRSTUVWXYZ" "" }}

    <!-- range all pages sorted by their title -->
    {{ range .Data.Pages.ByTitle }}
        <!-- get the first character of each title. Assumes that the title is never empty! -->
        {{ $firstChar := substr .Title 0 1 | upper }}

        <!-- in case $firstChar is a letter -->
        {{ if $firstChar | in $letters }}

            <!-- get the current letter -->
            {{ $curLetter := $.Scratch.Get "curLetter" }}

            <!-- if $curLetter isn't set or the letter has changed -->
            {{ if ne $firstChar $curLetter }}
                <!-- update the current letter and print it -->
                <!-- https://gohugohq.com/howto/hugo-create-first-letter-indexed-list/ -->

                </ul>
                {{ $.Scratch.Set "curLetter" $firstChar }}
                <h1>{{ $firstChar }}</h2>
                <ul class="list-pages">
            {{ end }}
                <li class="">
                    <a class="title" href="{{ .Params.externalLink | default .RelPermalink }}">{{ .Title }}</a>
                </li>
        {{ end }}
    {{ end }}
    </div>
</main>
{{ partial "table-of-contents" . }}

<div class="pagination tc db fixed-l bottom-2-l right-2-l mb3 mb0-l">
    {{ partial "back-to-top.html" . }}
</div>
{{ end }}
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 11:</span>
  Define how to show list of topics (group by first letter)
</div>


#### Group books by year and month {#group-books-by-year-and-month}

Following snippet will show a [list of books](https://brainfck.org/books) grouped by year. For each year each book will be shown
along with the `date` in `yyyy-mm` format.

```html
{{ define "main" }}
<main class="center mv4 content-width ph3">
    <h1 class="f2 fw6 heading-font">{{ .Title }}</h1>
    {{ .Content }}

    {{ range (where .Site.RegularPages "Type" "in" (slice "books")).GroupByDate "2006" }}
    <h2>{{ .Key }}</h2>
    <ul class="list-pages">
        {{ range .Pages.ByDate }}
        <li class="lh-copy">
            {{ $curDate := .Date.Format (.Site.Params.dateFormat | default "2006-02" ) }}
            <span class="date">{{ printf "%s " (slicestr $curDate 0 7 ) }}</span>
            <a class="title" href="{{ .Params.externalLink | default .RelPermalink }}">{{ .Title }}</a>
        </li>
        {{- end -}}
    </ul>
    {{ end }}
</main>
<div class="pagination tc db fixed-l bottom-2-l right-2-l mb3 mb0-l">
    {{ partial "back-to-top.html" . }}
</div>
{{ end }}
```

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/group-books-by-year.png" title="Group books by year and month" caption="I like to have an overview which books I've read each year grouped by the month when I completed. " pos="left" >}}


## org-roam {#org-roam}

{{< notice info >}}

As a complete `org-roam` novice I've found [Getting Started with Org Roam - Build a Second
Brain in Emacs](https://www.youtube.com/watch?v=AyhPmypHDEw&ab_channel=SystemCrafters) ([notes](https://systemcrafters.cc/build-a-second-brain-in-emacs/getting-started-with-org-roam/)) to be a quite good introduction. It will give you enough background
to get you started with `org-roam`. For more advanced topics you could also read [5 Org Roam
Hacks for Better Productivity in Emacs](https://systemcrafters.net/build-a-second-brain-in-emacs/5-org-roam-hacks/) or check out my [org-roam topic](https://brainfck.org/t/org-roam) for more resources.

{{< /notice >}}

By default all org-roam nodes are placed within the **same directory**. However, one big directory
for all notes didn't resonate with me at all. I came up with following _hierarchy_ inside `org-roam-directory`:
{{% sidenote %}}
Check out the org folder inside the [roam repository](https://github.com/dorneanu/roam/tree/main/org).
{{% /sidenote %}}
-   **org/**
    This is the root org-roam directory.
    -   **books/**
        -   this is where all books (stored as individual ORG files) should be located at
        -   I consider these files my _literature_ notes

            > "A literature note is a source reference in a reference manager, optionally with one
            > or more attached notes. The term ‘literature note’ derives from the note cards on
            > which Niklas Luhmann, the prolific sociologist and originator of the Zettelkasten
            > Method, recorded bibliographic references (Ahrens, 18)." -- [zettelkasten.de](https://zettelkasten.de/posts/concepts-sohnke-ahrens-explained)
        -   _thoughts_ and _concepts_ found within one book _may_ remain here
            -   or at same time I move it to an individual topic
                -   For example the topic [P.A.R.A.](https://brainfck.org/book/building-a-second-brain/#para) is contained withing the book [Building a Second Brain](https://brainfck.org/book/building-a-second-brain/#para).
        -   _quotes_ are now stored in the same (book ORG mode) file ([example](https://brainfck.org/book/building-a-second-brain/#quotes))
    -   **topics/**
        -   all individual topics are stored here
            -   Examples: [SSH](https://brainfck.org/t/ssh), [DDD](https://brainfck.org/t/ddd), [Attention Economy](https://brainfck.org/t/attention-economy/)
        -   I don't distinguish between _collection_ nodes, _thoughts_ and _concepts_
    -   **journal/**
        -   files inside this folder are daily [journals](https://brainfck.org/journal)
        -   each file name has following format: `YYYY-MM-DD.org`
        -   this is where I usually store thoughts, links which I haven't categorized yet
            -   or put into the right topic
    -   **notes/**
        -   I don't use this section yet (I'm also not sure if it's needed at all)
        -   This category relates to notes writen in my _own_ words
            -   can link to concepts inside a [book](https://brainfck.org/books)
            -   can refer to multiple [topics](https://brainfck.org/topics)

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/org-roam-buffer-with-backlinks.png" title="ORG Roam buffer with backlinks" caption="On the left side you can see my notes for the topic DDD. On the right side you see all other notes containing a link (back-reference) to the DDD note." pos="left" >}}


### Capture templates {#capture-templates}

For rapid capture `org-roam` uses pre-defined capture templates
{{% sidenote %}}
You can also store [templates in Org files](https://systemcrafters.net/build-a-second-brain-in-emacs/capturing-notes-efficiently/#storing-templates-in-org-files).
{{% /sidenote %}} (similar to [ORG mode capture templates](https://orgmode.org/manual/Capture-templates.html)) whenever a new entry (topic, book, note, quote etc.) should be added. These are mine:

```emacs-lisp
(org-roam-capture-templates
'(("d" "default" plain
  "%?"
  :if-new (file+head "topics/${slug}.org" "#+title: ${title}\n")    ❶
  :unnarrowed t)
  ("j" "Journal" plain "%?"                                         ❷
   :if-new (file+head "journal/%<%Y-%m-%d>.org"
            "#+title: %<%Y-%m-%d>\n#+filetags: journal\n#+date: %<%Y-%m-%d>\n")
   :immediate-finish t
   :unnarrowed t)
 ("b" "book" plain "%?"                                             ❸
  :if-new
  (file+head "books/${slug}.org" "#+title: ${title}\n#+filetags: book\n")
  :immediate-finish t
  :unnarrowed t)
  ))
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 12:</span>
  ORG Roam capture templates
</div>

Per default ❶ every new entry is a topic. Additionally I want every journal ❷ file to contain several meta information (properties) (like `#+date` and `#+filetags`).

Last but not least I want every book ❸ to be stored under `<ORG Roam directory root>/books/`.


## Emacs Kung Fu {#emacs-kung-fu}

As I was transitioning content from multiple folders into the `org-roam` directory
I've used Emacs editing capabilities to edit and create content using small `Elisp` snippets and _macros_. Let's explore some workflows.


### Insert content at point {#insert-content-at-point}

Whenever I was adding content (e.g. from sub-tiddlers) to main topic nodes (previsouly main tiddler in Tiddlywiki), I wanted to quickly **jump between directories** where my tiddlers
were exported as org content.

```emacs-lisp
(defun dorneanu/roam-insert (dir)     ❶
  (let* (
        (filename (read-file-name "filename: " dir nil nil nil)))
        (insert-file-contents filename))
)

;; Define global key bindings         ❷
(global-set-key (kbd "C-c m b") (lambda () (interactive) (dorneanu/roam-insert "/cs/priv/repos/brainfck.org/tw5/output/books")))
(global-set-key (kbd "C-c m t") (lambda () (interactive) (dorneanu/roam-insert "/cs/priv/repos/tiddlywiki-migrator/org_tiddlers")))
(global-set-key (kbd "C-c m .") (lambda () (interactive) (dorneanu/roam-insert "/cs/priv/repos/roam/org/topics/")))
```

Therefore I've defined a function ❶ which reads a file content after this has been
selected. The (temporary) key bindings ❷ allowed me to **jump between** following **folders**
and insert content quickly:

-   `/cs/priv/repos/brainfck.org/tw5/output/books`
    -   This is where I've exported my book tiddlers along with their correspondig sub-tiddlers (read the [first post]({{< relref "2022-migrate-tiddlywiki-to-org-roam-part-1-export-tiddlers" >}}) for the explanations regarding books and their sub-tiddlers)
-   `/cs/priv/repos/tiddlywiki-migrator/org_tiddlers`
    -   This is where **all** tiddlers got exported to initially
-   `/cs/priv/repos/roam/org/topics`
    -   this is the **root** org-roam folder for topics


### Add structure template for quotes {#add-structure-template-for-quotes}

Let's say you have following ORG content:

```org
* Book title
** Notes
*** Note 1
     Some text
*** Note 2
     Another text
*** Note 3
     Some loooooong text
```

How can you easily put the content underneath each note (Note 1, Note 2, Note 3) into
quote blocks? Here is where _macros_ came to my rescue. With my cursor on `Note 1` I typed:

-   `C-x (`
    -   `kmacro-start-macro`
    -   start macro
-   `g j`
    -   `outline-forward-same-level`
    -   go to next headline (in the same level)
-   `j` (move cursor to next line)
-   `M-m i p`
    -   `mark-paragraph`
    -   mark whole paragraph
-   `C-c C-,`
    -   `org-insert-structure-template`
    -   wrap marked region into ...
-   `q`
    -   a quote block
-   `C-x )`
    -   `kmacro-end-macro`
    -   end macro sequence

Here is some screencast:

{{< gbox src="/posts/img/2022/migrate-tiddlywiki-to-org-roam/macro-edit-notes.gif" title="Using macros for adding block quotes" caption="" pos="left" >}}


## Conclusion {#conclusion}

In retrospect I think I've spent way to much pretious lifetime for this project - and I'm
not finished yet. There are still to many empty topics (no content at all) and links
pointing to nirvana (e.g. links in old Tiddlywiki syntax). However, I think, the effort
      will pay off in the long run! In fact I already feel more productive as I'm able to quickly
      search for notes (in books, topics, journals etc.) and create these on-the-fly if not existant.

I've definitely improved my Emacs Kung Fu™ and learned even more about its editing
features (macros!). I also hope `org-roam` will help me produce even more content and
prevent me from just [collecting random notes](https://zettelkasten.de/posts/collectors-fallacy/).
