+++
title = "Emacs and the Cybernetic Productivity"
author = ["Victor Dorneanu"]
lastmod = 2023-09-21T22:03:10+02:00
tags = ["productivity", "emacs"]
draft = false
+++

A few days ago I came across Cal Newport's episode on "[The failure of Cybernetic Productivity](https://www.youtube.com/watch?v=Udzf5F1GPME&ab_channel=CalNewport) " where he talked about a
term I've never heard before: _Cybernetic Productivity_. This productivity concept has been prominent since the early
2000s and has served as an effective strategy for managing the growing workload, particularly among _knowledge workers_ .
Now, let's delve into the **principles**:

1.  **Automate and speed up shallow task as much as possible**
    -   Have software tools "**speak**" with other ones, send data from your browser to your Exceel sheet or to your editor
        (and vice versa)
    -   use as **less clicks** as possible
    -   automate all the things ™
2.  **Try to keep needed information at your finger tips**
    -   make it **easy to organize** and get access to **information**
    -   the more we have the **right information** when we need it, the **more effective** knowledge workers we are going to be
    -   Example: Google
        -   You can search for all types of information
        -   In general [knowledge management tools](https://brainfck.org/book/building-a-second-brain) implement this principle that information
            should never be to far from the person who needs it
3.  **Remove friction from communication**
    -   communication has to be **easy**
    -   if friction is removed, **high velocity communication** / colaboration can be achieved
4.  **Simplify the extraction of actionable wisdom from data**
    -   the information we need to do things is often hidden in data
        -   we need tools that can find trends
        -   we need tools that can extract wisdom from data so we can have it at our finger tips

According to Cal Newport this approach doesn't work because of the so called **infinite buffer**.
{{% sidenote %}}
A sort of inbox that never ends
{{% /sidenote %}} He arguments that the **supply of work** is **infinite** for most knowledge workers. Instead of having a **pull approach** where
workers "pull" new tasks from a central registry, potential tasks are stored at individuals. This way tasks are pushed
towards people until they're ready to work on that task. The buffer of work is growing so people tend to have more and
more to do.

This mentality combined with the **cybernetic productivity** has the following effect: It speeds up the **shallow tasks**
(overhead work surrounding deeper work)
{{% sidenote %}}
Also check [Shallow Work](https://brainfck.org/t/shallow-work)
{{% /sidenote %}} and at the same time frees up more time (for more work to fill in the **infinite buffer**). Here is a quote from the
episode:

> We're jumping from project to project, google is findin this information or maybe if we're more advanced chatGPT is
> grabbing the information for us that we're automatically sending it over between different types of tools and this data
> automatically goes over there and it's the cloud and it syncs. We're moving faster, faster and faster and more work
> comes in to fill that void and there is no time left to do the important stuff all those overheads are trying to support
> in the first place.
>
> So we feel tired, we feel exhausted, the context switches are making us dumber and we're spending less time actually
> doing the underlying work that creates value, the actual work that is valued in the marketplace.
>
> -- <https://www.youtube.com/watch?v=Udzf5F1GPME&ab_channel=CalNewport>

I have read Cal Newport's books ([Deep Work](https://brainfck.org/book/deep-work), [Digital Minimalism](https://brainfck.org/book/digital-minimalism),
[So Good They Can't ignore you](https://brainfck.org/book/so-good-they-cant-ignore-you))
{{% sidenote %}}
His new book on "Slow Productivity" should be out for sale in March 2024!
{{% /sidenote %}} and I weekly listen to his podcast. So I'm quite familiar with the concepts he advertises for. However, in this case I
somehow disagree with his thoughts on the cybernetic productivity and tools that are supposed to speed up
communication/interaction.

As you might guess, I have a **strong opinion** why [Emacs](https://brainfck.org/t/emacs) is a perfect tool to adress the four principles
described earlier. Let me emphasize why by adding Emacs specific tools/methodologies to each one:

-   **Automate and speed up shallow task as much as possible**

    Again, this is about the interaction between several software tools, having as less clicks as possible and _automate
    all the things_.

    For writing this article I've used

    -   [elfeed](https://github.com/skeeto/elfeed) (and especially [elfeed-tube](https://github.com/karthink/elfeed-tube)) in order to watch the Youtube episode and copy the relevant quotes from the
        transcripts
        -   Of course, everything inside Emacs!
        -   Absolutely no (mouse) clicks
        -   I was able to copy the relevant text to a new buffer where I already started to prepare the text for this blog
            post
    -   [hugo](https://gohugo.io/) and [ox-hugo](https://ox-hugo.scripter.co/) to automatically export this org file to markdown and later to [my blog](https://blog.dornea.nu)
        -   I've used [xwidget-webkit](https://www.gnu.org/software/emacs/manual/html_node/emacs/Embedded-WebKit-Widgets.html) to have a vertical buffer where I opened the local `hugo` instance (`http://127.0.0.1:1314`)
            in a web browser (integrated within Emacs) to preview my writing progress

-   **Try to keep needed information at your finger tips**

    This is about so called PKMs (_Personal Knowledge Management Systems_) which should enable information searching and
    management in an easy manner.

    For writing this article I've used

    -   [org-roam](https://www.orgroam.com/) for managing my knowledge database
        -   using [consult-org-roam](https://github.com/jgru/consult-org-roam) I've searched for "cybernetic productivity" to find [ORG mode](https://orgmode.org/) files containing these
            keywords
    -   [rg.el](https://github.com/dajva/rg.el) for using `ripgrep` inside my `org-roam` directory
        -   I've searched for "deep work" to find those files which contain these keywords
    -   [Doom Emacs lookup modules](https://docs.doomemacs.org/v21.12/modules/tools/lookup/) to perform web search using different search engines (Google and DuckduckGo)

    I didn't have to do any context switch as I've performed every single operation within Emacs 😎

-   **Remove friction from communication**

    Well, for this post I didn't have to "communicate" something. But in case I have to export some notes (from ORG mode)
    to other formats I can use:

    -   [pandoc-mode](http://joostkremers.github.io/pandoc-mode/)
    -   [copy-as-format](https://github.com/sshaw/copy-as-format) (Emacs function to copy buffer locations as GitHub/Slack/JIRA etc... formatted code)
    -   check out for more [ORG-mode exporters](https://orgmode.org/worg/exporters/ox-overview.html)

    If I had to ask someone for a review (check if the arguments in this post are good enough):

    -   I could use [mu4e](https://djcbsoftware.nl/code/mu/mu4e.html), [notmuch](https://notmuchmail.org/), [gnus](https://www.emacswiki.org/emacs/GnusTutorial) to send an e-mail
    -   I'd definitely use [magit](https://magit.vc/) to check in code and push to some `git` based code hosting system (I use Github)
        -   using [forge](https://github.com/magit/forge) I could create a pull-request and add some friends as reviewers

    Again, everything inside Emacs possible!

-   **Simplify the extraction of actionable wisdom from data**

    So this one was about:

    > -   we need tools that can extract wisdom from data so we can have it at our finger tips

    There is a high chance I didn't get this right, but: AI/ML someone? At our finger tips? Of couse:

    -   [rksm/org-ai](https://github.com/rksm/org-ai)

        > Emacs as your personal AI assistant. Use LLMs such as ChatGPT or LLaMA for text generation or DALL-E and Stable
        > Diffusion for image generation. Also supports speech input / output.
    -   [emacs-openai/chatgpt](https://github.com/emacs-openai/chatgpt)

        > Use ChatGPT inside Emacs
    -   [xenodium/chatgpt-shell](https://github.com/xenodium/chatgpt-shell)

        > ChatGPT and DALL-E Emacs shells + Org babel + a shell maker for other providers

Not convinced yet? 😇
