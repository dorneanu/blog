+++
title = "4 years and 7 days later"
author = "Victor"
date = "2021-02-08"
tags = ["misc"] 
category = "blog"
+++

# Hello from the other side

If you read this post today you might have noticed there was a huge break since the last post. More than 4 years ago I was actively blogging about [security]({{< relref "/tags/security" >}}) (mostly offensive stuff) and [appsec]({{< relref "/tags/appsec" >}}). 

So what happened since then? Well not only in private some things have changed but also professionally I kind of switched sides. While being involved in *pentests* for a while I decided to become more *blue-team* oriented and help others to *build* secure products. Software engineering combined with security is what still keeps me busy and also motivated. 

# Golang

After my sabbatical from 2017 - 2018 I thought it might be the perfect time to learn a new programming language. After flirting for a while with *Golang* I've ordered [The Go Programming language](https://www.goodreads.com/book/show/25080953-the-go-programming-language) which still has been a very good introduction and many times used as a reference. And of course I was finally introduced to the world of *cloud computing*, especially to [AWS]({{< relref "/tags/aws" >}}). 

# Serverless

During this journey I also realized how much potential *FaaS* has and I also started working on some private project which used Golang, Serverless and DynamoDB for storing [TiddlyWiki]({{< relref "/tags/tiddly" >}}) tiddlers in a more fancy way. The project is called [widdly](https://github.com/dorneanu/widdly) and is a fork of [opennota/widdly](https://gitlab.com/opennota/widdly) and has serverless and dynamodb support for Tiddlywiki. A [demo](https://tiddly.info/serverless) is also available. 

{{% notice tip %}}
Recently I've been using [TiddlyWiki](https://tiddlywiki.com/) to build a Zettelkasten, similar to [roam](https://roamresearch.com/). You can find it at [brainfck.org](https://brainfck.org).
{{% /notice %}}
 
# Migrate from Pelican

Before resurrecting this blog, I had to migrate all my [markdown](https://github.com/dorneanu/blog/tree/master/content/posts) content, all my [jupyter notebooks](https://github.com/dorneanu/blog/tree/master/content/jupyter) from Pelican to [hugo](https://gohugo.io/). The pelican engine did its job but it was way to slow compared to *hugo* and after all I wanted to try something new.

Converting [jupyter]({{< relref "/tags/ipython" >}}) notebooks was an easy task thanks to [PelicanToHugo](https://github.com/anthonynelzin/PelicanToHugo). With the magic of [GitHub Actions](https://github.com/dorneanu/blog/blob/master/.github/workflows/main.yml) I am now able to separate blog content from generated HTML content **and** automatically deploy this blog to GitHub pages whenever content is pushed to the repository.

What's missing? Actually a lot:

* pictures (from old *dl.dornea.nu*) 
  + This time I would put them into each posts folder like I did [here](https://github.com/dorneanu/blog/tree/master/static/posts/2015-10-02-manage-a-pki-using-openssl). 
* since there is no [graphviz]({{< relref "/tags/graphviz" >}}) module/plugin for hugo I need a new solution
  + there is [gravizo](http://www.gravizo.com/) but this is 3rd-party service which might not be available in a couple of years
  + I could parse all the graphviz code, run the `graphviz` CLI, generate the picture and adapt the markdown file (probably the preferred solution)
* add more *shortcodes*
  + e.g. for showing [notices](https://github.com/dorneanu/blog/blob/master/layouts/shortcodes/notice.html)

BTW: Read [here](https://jawher.me/5-years-3-days-later/) why blogging is hard. With this in mind: Nice to see you again :)  
