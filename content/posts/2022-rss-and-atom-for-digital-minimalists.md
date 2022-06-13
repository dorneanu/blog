+++
title = "RSS and Atom for digital minimalists"
author = ["Victor Dorneanu"]
date = 2022-06-13T07:00:00+02:00
lastmod = 2022-06-13T14:16:44+02:00
tags = ["rss", "emacs"]
draft = false
+++

## Digital Minimalism {#digital-minimalism}

A few days after I have started working on this post, I begun reading Cal
Newport's [ Digital Minimalism](https://brainfck.org/#Digital%20Minimalism) book and quickly
realized how both topics interrelate to each other. But now one by one:

> Digital minimalism is a philosophy of technology use in which you focus your
> entire time on a small number of carefully selected and optimized activities to
> strongly support things you value and happily miss out everything else. -- Cal
> Newport

I think there is so much essence in this statement thus emphasizing the need for
focussed and intentional attention for our daily activities. I've finished
[reading the book](/2022/05/02/book-summary-digital-minimalism/) before releasing this post and as main takeaways
I can for sure recommend the key [principles](https://brainfck.org/#Digital%20Minimalism%20/%20Philosophy)
behind [digital minimalism](https://brainfck.org/#Digital%20Minimalism):

-   **clutter** is costly
-   **Optimization** is important
    -   deciding **which** technology to use is only the first step
    -   **how** to use it to fully extract its potential is even more important
-   **Intentionality** is satisfying
    -   intention trumps convenience
    -   about the benefits from technology chosen intentionally

I think [RSS](https://en.wikipedia.org/wiki/RSS)/[Atom](https://en.wikipedia.org/wiki/Atom_(Web_standard)) should be one of the technologies every digital **minimalist** should
have in her/her repertoire:

-   it will **de-clutter** your daily inbox of input (articles, podcasts, videos etc.)
    by allowing you to access them in a standardized, machine-readable format
-   access is completely **anonymous** and requires no registration, no e-mail subscription
    and **data consumption** is completely under your control
-   subscribing to some RSS/Atom feeds won't bring you any value unless you
    -   come up with your own system of consuming information
    -   **organize** your feeds in a way that isn't sucking up your whole attention and
        energy
    -   don't give up your good **intentions** to decide when and how to consume content
        -   don't let big companies decide for you whether content is good or not


## So-called social websites {#so-called-social-websites}

Almost everything we do in our lifes requires our mental focus and the will to
address some attention to that specific activity. Human capacity for attention
is limited and because the industry knows how to exploit human behaviour, there
is a huge competition within the **attention economy**. You're asked to subscribe to
all kind of newsletters and eventually you'll get bombarded with content you
didn't ask for.

Searching for all kind of RSS services I've stumbled upon [rss-bridge](https://github.com/RSS-Bridge/rss-bridge) which has
some critical standing on "so-called social websites":

> Your catchword is "share", but you don't want us to share. You want to keep us within your
> walled gardens. That's why you've been removing RSS links from webpages, hiding them deep
> on your website, or removed feeds entirely, replacing it with crippled or demented
> proprietary API. FUCK YOU. -- [rss-bridge](https://github.com/RSS-Bridge/rss-bridge)

Again: it's against their business to simply let you decide what to do with your content.
They're like [tech giants selling tobacco products](https://brainfck.org/#Digital%20Minimalism%20-%20Note%202).

> We want to share with friends, using open protocols: RSS, Atom, XMPP, whatever. Because no
> one wants to have your service with your applications using your API force-feeding them.
> Friends must be free to choose whatever software and service they want. --  [rss-bridge](https://github.com/RSS-Bridge/rss-bridge)

Don't try to reinvent the wheel. The technology is already there and has worked fine for decades now.

{{< tweet user="danielnemenyi" id="1470385279383089153" >}}

Also recently there have been lots of [RSS related entries on Hackernews](https://hn.algolia.com/?dateRange=all&page=0&prefix=true&query=RSS&sort=byDate&type=story).


## Media consumption {#media-consumption}

I don't like fast food neither **fast media**. I try not to consume media as soon
it's published and I don't subscribe to every possible news source - my reading
time is limited anyways.

What I instead try to do is to consume media with a **mindset of slowness**:

-   I limit my attention to the best of the best
    -   you will find currated lists of people you should follow/subscribe to
        depending of your interests
-   I commit to maximize the quality of what I consume and the conditions under
    which I do it
    -   I like to allocate dedicated time for reading (and watching videos!)
    -   A distraction free environment is essential for me to consume the content
        and extract what's most important for me
        -   the chosen location should support me in giving my full attention to the
            reading
    -   I usually download (web) articles in advance and send them to my e-reader
        using [getpocket.com](https://getpocket.com) (also check out my previous blog entry for [getpocket
        best practices](/2021/09/01/inbox-zero-using-getpocket/))
    -   I aggregate news content/feeds in one place
        -   most of the time I use [Emacs](https://brainfck.org/#Emacs) along with [elfeed](https://github.com/skeeto/elfeed) to decide
            which content I'll send to the reading queue (more on my Emacs setup
            in a separate post)

Besides adopting [slow media](https://en.wikipedia.org/wiki/Slow_media) and while I'm not against social media I do think you can extract
value out of it if used the proper way. Also [Cal Newport](https://calnewport.com) suggests using it like a professional:

-   extract most possible value while avoiding much of the low-value distraction
    (ads, related content, comments) the services deploy to lure users into
    compulsive [behaviour](https://brainfck.org/#Behavioural%20Addiction%20)
-   use **thresholding** (only see tweets with X likes/re-tweets) and other mechanisms
    for relevant content
-   show links with most upvotes/comments
    -   I can recommend [hnrss](https://hnrss.github.io/) for HN


## Really Simple Stuff {#really-simple-stuff}

RSS (Really Simple Syndication) and Atom feeds have been for decades the best way to consume
content and the let the consumer decide **when** to do so.


### Format {#format}

I don't care if it's JSON, [RSS](https://en.wikipedia.org/wiki/RSS) or [ATOM](https://en.wikipedia.org/wiki/Atom_(Web_standard)). It should be a standard, parseable
format! That's what I'm asking for. Even worse: There are sites without any RSS
feeds that have a public API for fetching things. Please, stop doing so! There
is nothing wrong with RSS/ATOM and standardization is good.

In the following sections I'll give some advice how you can get RSS/ATOM feeds from
well known services.


### Social Media {#social-media}

The social media list is definitely not complete. I will just list the ones I use from time
to time.

-   **Youtube**

    Fortunately YouTube still has RSS feeds. You just need the `channel_id` of a
    channel and use this URL to actually get the feeds:

    ```nil
        https://youtube.com/feeds/videos.xml?channel_id=<channel_id>
    ```

    That's it. But wait. Sometimes you don't have a `channel_id` and need to find it
    out. In this case have a look at source of that specific Youtube page and extract
    the `channel_id` from there as described [here](https://stackoverflow.com/questions/14366648/how-can-i-get-a-channel-id-from-youtube).

-   **Twitter**
    -   [nitter.net](https://nitter.net)
    -   [rss-bridge](https://github.com/RSS-Bridge/rss-bridge)
-   **Reddit**

    While Reddit always had a high volume of content posted on daily basis, meanwhile I
    only check for the top posts this month ([example: top posts in /r/golang](https://www.reddit.com/r/golang/top/?t=week)). I also
    like reddit for the [RSS features](https://www.reddit.com/wiki/rss) it implements on a quite granular level:

    -   [reddit front page](http://www.reddit.com/.rss)
    -   [RSS feeds for a subreddit](http://www.reddit.com/r/netsec/.rss)
    -   [RSS feeds for a specific user](http://www.reddit.com/user/cyneox/.rss)
    -   [submissions for a specific domain](https://www.reddit.com/domain/blog.dornea.nu/.rss)
-   **LinkedIn**

    Currently LinkedIn has no feeds at all. But I'm already working on a solution
    which will allow an user to subscribe (of course, via RSS/Atom) to all updates
    and posts within his/her business network on LinkedIn.


### Engineering {#engineering}

-   **Github**

    With Github it's quite easy to stay up-to-date with activities within a repository. Take the
    project page and just append `/releases.atom`, `/tags.atom/` or `/commits/master.atom`. Example:

    -   [releases](https://github.com/golang/go/releases.atom)
    -   [tags](https://github.com/golang/go/tags.atom)
    -   [commits (master branch)](https://github.com/golang/go/commits/master.atom)
-   **Gitlab**

    Some examples:

    -   [tags](https://gitlab.com/vdorneanu/widdly/-/tags?format=atom)
    -   [commits](https://gitlab.com/vdorneanu/widdly/-/commits/master?format=atom)


### Podcasts {#podcasts}

I mainly use [player.fm](https://player.fm/) for listening to podcasts and finding new content.
However, I use Emacs/elfeed to make a pre-selection of episodes because it's
really fast and convenient to integrate within my daily workflow. Using the
mobile app instead is time consuming and I'm always distracted by something
else. As I've mentioned before: Use technology wisely and come up with a
workflow that doesn't distract you from the real task.

In the case of player.fm you can easily export your feeds in [OPML](https://en.wikipedia.org/wiki/OPML) format:

```text
https://player.fm/<username>/subs.opml
```

This is how it looks like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<opml version='1.0'>
<head>
<title>Player FM Feeds from All</title>
<dateCreated>June 08, 2022 19:29</dateCreated>
<dateModified>June 08, 2022 19:29</dateModified>
</head>
<body>
<outline text="extra 3  HQ" type="rss" xmlUrl="https://www.ndr.de/fernsehen/sendungen/extra_3/video-podcast/extradrei196_version-hq.xml"  htmlUrl="https://www.ndr.de/fernsehen/sendungen/extra_3/video-podcast/index.html" />
<outline text="The Tim Ferriss Show" type="rss" xmlUrl="https://rss.art19.com/tim-ferriss-show"  htmlUrl="https://tim.blog/podcast" />
<outline text="Zur Diskussion - Deutschlandfunk" type="rss" xmlUrl="https://www.deutschlandfunk.de/zur-diskussion-102.xml"  htmlUrl="https://www.deutschlandfunk.de/zur-diskussion-100.html" />
<outline text="Update - Deutschlandfunk Nova" type="rss" xmlUrl="https://www.deutschlandfunknova.de/podcast/update"  htmlUrl="https://www.deutschlandfunknova.de/podcasts/download/update" />
....
```

I then used some Python foo to parse the XML file and extract `xmlUrl` and `text`
attributes which were then used to generate an ORG file with all the podcasts
feeds.


### Services {#services}

Below you'll find a list of (paid/free) services/tools which further enhance
the RSS/Atom feed subscription feature.

-   [rss-bridge](https://github.com/RSS-Bridge/rss-bridge)

    > RSS-Bridge is a PHP project capable of generating RSS and Atom feeds for websites that don't have one. It can be used on webservers or as a stand-alone application in CLI mode.

    -   <https://feed.eugenemolotov.ru/>
    -   <https://college.kre.dp.ua/rss/>
    -   <https://rss.searchdaddy.ie/>
    -   <https://rss.garichankar.com/>
-   [brutalist.report](https://brutalist.report/)
    -   delivers daily headlines without bullshit
    -   you'll get ads-free headlines from
        -   Hackernews
        -   The Verge
        -   Slashdot
        -   ArsTechnica
        -   The Register
        -   Protocol
        -   Linux Weekly News
        -   The New York Times
        -   NPR
        -   and many others
-   [elink.io RSS feed reader](https://about.elink.io/rss-feed-reader)

    > Read and curate content with elink's robust RSS feed reader. elink allows you to easily stay informed by retrieving the latest content from the sites you are interested in. Simply grab the RSS feeds from the sites you love and we will display them for you to read articles or create content.
-   [fetchrss.com](http://fetchrss.com/)

    > First of all it's an online RSS feed generator. This service allows you to
    > create RSS feed out of almost any web page. Your only task is to provide us
    > with target URL and point on desired blocks in our visual RSS builder.

    I really liked the **visual RSS builder** functionality which allows you for which
    parts of a page you'd like to get RSS feeds. Also the auto-update feature lets you
    know if a page has changed.
-   [rss.app](https://rss.app)

    > Aggregate and curate your favorite websites by turning them into auto-updated RSS feeds. Fastest RSS finder and creator on the market.
-   [ratt](https://sr.ht/~ghost08/ratt/)

    > RSS all the things: ratt is a tool for converting websites to rss/atom feeds. It uses config files which define the extraction of the feed data by using css selectors, or Lua script.
-   [granary.io](http://granary.io/)

    > Fetches and converts data between social networks, HTML and JSON with microformats2, ActivityStreams 1 and 2, Atom, RSS, JSON Feed, and more

    What I do **not** like about it: The OAuth tokens are used as URL parameters. From a Security perspective that really sucks.

-   [kill-the-newsletter.com](https://kill-the-newsletter.com/)

    Converts Email newsletters into Atom feeds. Definitely one of my favourite ones.


## Distribute content {#distribute-content}

You can also use RSS to distribute to share your content to social media. Using workflows
provided by services like [zapier](https://zapier.com/) or [ifttt](https://ifttt.com/) you can easily use RSS feeds to automatically
post and share new content via Twitter, Facebook, LinkedIn and other major social media
platforms.

You can use [hugo](https://gohugo.io/) (or any static site generator) to generate RSS/Atom feeds after
you've added your content. Some while ago I've setup a PoC
([github.com/dorneanu/feeds](https://github.com/dorneanu/feeds)) to automatically share content to Twitter and
LinkedIn using hugo. Let's have a look at this [sample post](https://github.com/dorneanu/feeds/blob/main/content/feeds/2021-simple-post.md) (in Markdown):

```markdown
+++
title = "Simple post"
author = ["Victor Dorneanu"]
lastmod = 2021-10-04T19:51:54+02:00
tags = ["twitter", "linkedin"]
draft = false
weight = 2005
posturl = "https://heise.de"
+++

Some text here and there.

-   text here
-   text [some link](https://google.de)
```

This post is tagged with `twitter` and `linkedin`. Accordingly this post should be part of

-   [the LinkedIn RSS feed list](https://feeds.brainfck.org/tags/linkedin/index.xml)
-   [the Twitter RSS feed list](https://feeds.brainfck.org/tags/twitter/index.xml)

Using hugo's [front matter](https://gohugo.io/content-management/front-matter/) you can add specific metadata like `posturl`. Let's have a look how
the correspondig RSS entry looks like:

```xml
<item>
<title>Simple post</title>
<link>http://feeds.brainfck.org/feeds/2021-simple-post/</link>
<pubDate>Mon, 04 Oct 2021 19:51:54 +0200</pubDate>
<guid>http://feeds.brainfck.org/feeds/2021-simple-post/</guid>
<description>Some text here and there. text here text some link </description>
<postUrl>https://heise.de</postUrl>
<htmlContent><p>Some text here and there.</p> <ul> <li>text here</li> <li>text <a href="https://google.de">some link</a></li> </ul> </htmlContent>
<plainContent>Some text here and there. text here text some link </plainContent>
</item>
```

Now you can use this mechanism to automatically share content to LinkedIn/Twitter
from a specific taxonomy RSS feed.


### zapier {#zapier}

I like [zapier](https://zapier.com) for its intuitive simplicity for creating so called **zaps**. A zap is an integration
between one service (e.g. Twitter/LinkedIn) and a specific event (new item was added to a RSS feed).
This way you can automatically share content via social media services using RSS feeds.

This is the overall workflow:

{{< gbox src="/posts/img/2022/rss/zapier-workflow.png" title="RSS workflow using Hugo and Zapier" caption="RSS Workflow" pos="left" >}}

Chose which RSS to trigger events

{{< gbox src="/posts/img/2022/rss/zapier_rss_trigger.png" title="RSS Trigger" caption="RSS Trigger" pos="left" >}}

And configure how your new LinkedIn share update should look like

{{< gbox src="/posts/img/2022/rss/zapier_send_to_linkedin.png" title="Send new content to LinkedIn as a new share update" caption="" pos="left" >}}

This workflow has quite many steps and requires some `hugo` knowledge. You're also
limited by the maximal number of zaps you can trigger each month and the number
of services you'd like to sent your (RSS) content to. All these limitations lead
to a custom implementation (in [Golang](https://brainfck.org/#Golang)) which I will release (as
a web service) soon.


## Conclusion {#conclusion}

RSS/Atom has been on of the standardized ways how applications can retrieve content from each other.
It doesn't require authentication and it's way simpler to implement than a REST API. I think it was
like 2 years ago when I started to reduce my content consumption behaviour and started looking for a
simple way to do it when I want it and in the way I like it. I don't have to visit every single page
nor do I have to go through my emails and skip promotions/ads before the real content is revealed.
With modern RSS/Atom readers these days you can easily filter and label articles which will definitely
improve your daily newsflow and reading habits.

You can find this blogs RSS feed at [blog.dornea.nu/feed.xml](https://blog.dornea.nu/feed.xml). I've also exported my current RSS subscription
list to [this gist](https://gist.github.com/dorneanu/c3db1683e68137ff84775e87bd225ae4).
