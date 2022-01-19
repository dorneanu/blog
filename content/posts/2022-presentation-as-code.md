+++
title = "Presentation as Code"
author = ["Victor Dorneanu"]
date = 2022-01-19T20:28:00+01:00
lastmod = 2022-01-19T20:46:34+01:00
tags = ["devops", "productivity", "emacs", "org"]
draft = false
+++

Last year I've done some experiments with the [Beamer LaTex class](https://ctan.org/pkg/beamer?lang=en) which you can use whenever
you want to export an ORG document to a [Beamer presentation](https://orgmode.org/worg/exporters/beamer/tutorial.html). I've done some customizations
and I've thought I have a quite decent presentation template. Till I've found [this](https://zenika.github.io/adoc-presentation-model/reveal/reveal-my-asciidoc.html).

That [reveal.js](https://revealjs.com/) presentation completely my mind and I've started digging into [asciidoc](https://asciidoctor.org/). And then
there is also [org-asciidoc](https://github.com/yashi/org-asciidoc) which will export your ORG buffer into `asciidoc`. However there were some
[issues](https://github.com/yashi/org-asciidoc/issues/14) and quickly after Christmas I decided I'll go on my own and setup my own revealjs theme.

{{< tweet user="victordorneanu" id="1481908662251704320" >}}

Here are some links:

-   [slides.dornea.nu](https://slides.dornea.nu)
    -   here I'd like to host my slides
    -   yes, I plan to do more
-   [github.com/dorneanu/slides](https://github.com/dorneanu/slides)
    -   check out the `content` folder and inspect the revealjs setup file
    -   for theming I use some of [Zenika's themes](https://github.com/Zenika/adoc-presentation-model/tree/master/docs/themes) with small customizations

And here some GIF I've put on Twitter:

{{< tweet user="victordorneanu" id="1482694904547586051" >}}
