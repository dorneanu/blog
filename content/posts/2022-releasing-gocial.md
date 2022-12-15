+++
title = "Releasing Gocial"
author = ["Victor Dorneanu"]
date = 2022-12-15T21:40:00+01:00
lastmod = 2022-12-15T21:40:50+01:00
tags = ["golang", "project"]
draft = false
+++

More than a year ago I started working on a [side project](https://brainfck.org/t/deliberate-practice) born out of the furstration I had with [buffer](https://buffer.com/), [ifttt](https://ifttt.com/) and [zapier](https://zapier.com/). The use
case was pretty simple: I just wanted to share an article and some comments about it on
multiple social media platforms from a single location.

All sharing services had great functionalities (e.g. automated workflows)
{{% sidenote %}}
Initially I played with [RSS and hugo](/2022/06/13/rss-and-atom-for-digital-minimalists/#distribute-content) for publishing content via a RSS feed which
will then trigger posts on Twitter, LinkedIn &amp; co.
{{% /sidenote %}} but you're always limited in the number of shares you can distribute withing a time
frame without paying for premium. At the same time they all lacked support for LinkedIn
which then sparked the idea for [gocial](https://gocial.netlify.app/). After having a look at the [LinkedIn Post API](https://learn.microsoft.com/en-us/linkedin/marketing/integrations/community-management/shares/ugc-post-api?view=li-lms-unversioned&tabs=http)
{{% sidenote %}}
Which apparently now it's legacy and got replaced by the [posts API](https://learn.microsoft.com/en-us/linkedin/marketing/integrations/community-management/shares/posts-api?view=li-lms-2022-11&tabs=http).
{{% /sidenote %}} I decided I'll implement my own service in [Golang](/tags/golang) and learn more about
[OAuth](https://brainfck.org/t/OAuth) and [JWT](https://brainfck.org/t/JWT) tokens.

<div title="Gocial main page">

<figure><a href="https://gocial.netlify.app"><img src=" /posts/img/2022/gocial/2022-12-screenshot.png"></a><figcaption> gocial main page</figcaption></figure>

</div>


## Design {#design}

For the overall _system design_ I use a [serverless](https://brainfck.org/t/serverless) environment to run my Golang binary. Currently I use [netlify.com](https://www.netlify.com/) to host my Lambda function which serves all the functionalities via
HTTP and some REST API.

As for the _software architecture_ I've used [hexagonal architecture](https://brainfck.org/t/hexagonal-architecture)
to have more or less strict boundaries between the _domains_ and enable _lose coupling_.


### Sketching ideas {#sketching-ideas}

As always I've started with a rough idea how the code structure should like. Initially I wrote
down some ideas on my whiteboard
{{% sidenote %}}
And yeah, coding and drawing with kids is possible! 😊
{{% /sidenote %}} and codified these later on.

{{< gbox src="/posts/img/2022/gocial/architecture-sketches.jpg" title="Early ideas" caption="This is how everything began. I've sketched some initial ideas before implementing the core parts." pos="left" >}}


### Hexagonal Architecture {#hexagonal-architecture}

I know the picture below doesn't look like an _hexagonal_ structure but it should at least emphasize what the _core domain_ is about.

{{< notice info >}}

I've recently release an online presentation on this topic. Checkout [Hexagonal Architecture (Basic Introduction using Python)](https://slides.dornea.nu/2022/hexagonal-architecture/).

{{< /notice >}}

{{< gbox src="/posts/img/2022/gocial/architecture.png" title="Hexagonal Architecture" caption="Read more at <a href='https://github.com/dorneanu/gocial'>github.com/dorneanu/gocial</a>" pos="left" >}}


## Project layout {#project-layout}

For the project structure/layout I've decided to go with this structure:

```text
gocial:

├── cli
├── docs
├── internal
├── lambda
└── server
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Overall project structure
</div>


### `/internal` {#internal}

This is where the _gocial_ specific domain code goes to. This includes _entities_, different _services_ and the _authentication_ part.

```text
  ./internal
  ├── config
  │   └── config.go
  ├── entity
  │   ├── identity.go
  │   ├── providers.go
  │   └── share.go
  ├── identity
  │   ├── cookie_repository.go
  │   ├── file_repository.go
  │   └── repository.go
  ├── jwt
  │   └── token.go
  ├── oauth
  │   ├── goth_repository.go
  │   ├── repository.go
  │   └── service.go
  └── share
      ├── linkedin_repository.go
      ├── repository.go
      ├── service.go
      └── twitter_repository.go
```


### `/server` {#server}

```text
  ./server
  ├── api.go
  ├── html
  │   ├── html.go
  │   ├── package.json
  │   ├── package-lock.json
  │   ├── postcss.config.js
  │   ├── static
  │   │   └── main.css
  │   ├── tailwind.config.js
  │   ├── tailwind.css
  │   ├── tailwind.js
  │   └── templates
  │       ├── about.html
  │       ├── auth
  │       ├── base.html
  │       ├── index.html
  │       ├── partials
  │       └── share
  ├── http.go
  ├── oauth.go
  └── share.go
```

This folder contains HTTP server specific functionalities:

-   `/html`
    -   here I put all the HTML templates and components (partials)
    -   I use [tailwindCSS](https://tailwindcss.com/) so there is a little bit of `npm` foo
-   `http.go`
    -   responsible for launching the HTTP server and setting up API routes
    -   renders HTML templates
-   `api.go`
    -   handles different API routes (e.g. sharing articles/comments)
-   `oauth.go`
    -   defines API endpoints for doing OAuth


## Project repository {#project-repository}

<figure><a href="https://github.com/dorneanu/gocial"><img src=" https://socialify.git.ci/dorneanu/gocial/image?description=1&descriptionEditable=gocial%20-%20social%20media%20interactions&font=Source%20Code%20Pro&forks=1&language=1&name=1&owner=1&pattern=Solid&stargazers=1&theme=Light"></a><figcaption> Check out the github repository</figcaption></figure>
