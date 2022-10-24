+++
title = "Hexagonal Architecture in Python"
author = ["Victor Dorneanu"]
date = 2022-10-24T20:11:00+02:00
lastmod = 2022-10-24T20:11:42+02:00
tags = ["python", "architecture", "slides"]
draft = false
+++

What do have clean, layered, [hexagonal](https://brainfck.org/t/hexagonal-architecture) hexagonal,
onion architecture and ports &amp; adapters in common? They kind of share the same principles:
Separation of concerns (business vs infrastructure code), data encapsulation
([information hiding](https://brainfck.org/t/information-hiding)),
[low coupling](https://brainfck.org/t/solid#open-close-principle), strict dependency flow (how
layers should depend on other ones).

Still these concepts are not easy to digest unless you put them into practice. Furthermore
architectural decisions are figured out based on personal, past experiences and the degree
of knowledge people have when discussing viable solutions.

{{< figure src="/posts/img/2022/hexagonal-architecture/hexagonal-architecture-presentation.png" caption="<span class=\"figure-number\">Figure 1: </span>View [presentation](https://slides.dornea.nu/2022/hexagonal-architecture/)" >}}

As already mentioned in [Accelerate](https://brainfck.org/book/accelerate) architectural decissions and
effective architecture enable teams to easily test and deploy individual
components/services also when the organization grows or the amount of services changes.
Architectural characteristics rather than implementation details were more important in
order to have a portable and sustainable architecture. As you define (logical) layers,
clear boundaries and relationships between individual packages/modules inside your
software, this will improve overall maintainability and testability of your code.

Some months ago I gave a presentation on "[Hexagonal Architecture in Python](https://slides.dornea.nu/2022/hexagonal-architecture/)" for the TECH
team at **Cashlink**. More than a year ago, me and my ex-colleagues at **Scout24** were
implementing small services using the same principles, but in
[Golang](https://brainfck.org/t/golang). At that time I've found it rather easy to find examples for
Golang. For [Python](https://brainfck.org/t/python) I still miss examples of big projects embracing
hexagonal architecture. (But maybe because I didn't search as long as I did with Go ... )

In [this presentation](https://slides.dornea.nu/2022/hexagonal-architecture/) I somehow mix "hexagonal architecture" and "ports &amp; adapters" for
architecting an application meant to upload documents to several storage systems (S3,
Dropbox etc.) Let me know if you think this is useful and/or abstractions (as interfaces)
are somehow obsolete in Python making code even unreadable.
