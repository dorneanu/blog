+++
title = "10 years in the InfoSec industry"
author = ["Victor Dorneanu"]
date = 2022-12-02T14:36:00+01:00
lastmod = 2022-12-02T14:36:26+01:00
draft = false
+++

Ten years ago, in December 2012, I have _officially_
{{% sidenote %}}
Before that I had several _student_ jobs and _internships_ which at least
from most recruiters view don't count in as professional experience.
{{% /sidenote %}} started my career in the (Information) Security industry. During this period I
have done _pentesting_, _code reviews_, _architecture reviews_, _software engineering_,
_reverse engineering_, _consultancy_, _secure design_ and probably many other things I
cannot remember anymore. I am grateful for what I've _learned_ but most important
for the lovely _people_ I have met and I'm still in contact with.

After these 10 years
{{% sidenote %}}
Some years ago, I remember a blog post called something like "10 years in infosec - the
obligatory recap". Unconciously, that somehow incepted the idea for this post.
{{% /sidenote %}} of experience, learnings and countless sessions I've spent working with my colleagues I
thought I could do a small restrospective and give some advice to whoever wants to start
this journey. Here are my **top 10 recommendations** for juniors, professionals and anyone
willing to take a deep dive into Security.


## Chose one field of expertise {#chose-one-field-of-expertise}

Security is such a broad topic and you might lose yourself if you don't specialize in a
specific topic. Security is not only about technical details or risks. It's about
_information_, _quality_, _people_ and yes, _risks_ and _technology_. The principles of _information
Security_
{{% sidenote %}}
I mean the protection of data itself, because (not only) this is what Security is about:
Protecting valuable information.
{{% /sidenote %}} can be applied almost in the same manner regardless of the _domain_ you're working in.
Whether it's _application,_ _network_, physical Security, _reverse engineering_ or _ISMS_
(Information Security Management System) try to become an _expert_ in that field you'll
benefit from it in _other ones_ (also [Focus on skills, rather than career paths](#focus-on-skills-rather-than-career-paths))


## Don't fall into the CTF trap {#don-t-fall-into-the-ctf-trap}

I think _pentesting_ is the most common entrypoint for Security enthusiasts to
enter the InfoSec world. It takes time, skills but also
[practice](https://brainfck.org/t/deliberate-practice) to gain knowledge and master skills
in a certain domain (e.g. application security). One way to do so is to
participate in so called [CTF](/tags/ctf) (capture the flag) competitions usually held at
Security conferences or solving small challanges (also called [wargames](/tags/wargames)).

While I think [deliberate practice](https://brainfck.org/t/deliberate-practice) is the key
to _improve_ your skills and keep your attention where it's mostly needed, I would
not focus primarly on mastering these skills. Real _professional_ experience is
gained through _real-world examples_.

My problem with CTFs are the _environment_ and the _specific circumstances_ under which
an attack can be successful. Unless you're a Security _researcher_ I would first
go for the low-hanging fruits because these are the ones most attackers use to
initially gain access to a system. At the same time I would still recommend
_reading_ [CTF writeups](https://github.com/topics/ctf-writeups)  as you learn (from an attackers perspective) how to
deal with new technologies or how to exploit a common vulnerability in a rather
exotic setup.


## Deperimetrization is key {#deperimetrization-is-key}

As recent hacks have shown ([Uber](https://www.nytimes.com/2022/09/26/opinion/uber-hack-data.html)) assuming you **internal** network is safe is just _wrong_.
Once attackers have their foot in, they will be treated as normal users. For exactly this
reason **authentication** and **authorization** for _every_ operation is key to modern architecture.
I hope more and more companies will adopt [Zero Trust](https://brainfck.org/t/zero-trust) and [Zero
Trust Architecture (ZTA)](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf).


## Security research is not daily business {#security-research-is-not-daily-business}

Do you know this feeling when you're at a [Security conference](https://blog.dornea.nu/tags/events/), listening carefully to a
talk and suddenly you realize you don't really understand anything?
{{% sidenote %}}
Hint: It's not the language 😃
{{% /sidenote %}} It must be one of these talks where a super sophisticated attack (or a piece of malware)
is presented to the audience from which only 2% really get it 🙈. It happens quite often
that Security juniors attend these conferences and are super excited to do the same type
of work (research) in their professional day-to-day life. But the reality is a different
one and quite boring sometimes. Be prepared to understand business and developers
requirements and help where needed. These requirements will differ a lot from what are you
expected to do in an academic environment or as an (employed) researcher.


## Don't do Security. Enable it! {#don-t-do-security-dot-enable-it}

I saved this quote from [Agile Application Security](https://brainfck.org/book/agile-application-security) and I think it kind of summarizes how the perception of Security changed in
the last decade. Security was often perceived as something that has to be _proven_ (by
checklists) and _passed_ (in the sense of quality gates in **SDLC**). However risks should not
be evaluated once but _continously_. The role of Security is to ensure that concepts, risks,
hacker mindests are included in the whole **SDLC** (requirements, design, coding, testing,
implementation). Considering Security early on and throughout the process not only goes
well with _Agile_ but definitely contributes to a more sucessful end product. Be ready to
talk to different stakeholders (developers, product managers, C-level etc.), at different
stages instead of having a regular (every X months) checklist approach. Be proactive and
share knowledge as much as you can.


## IAM &amp; SSO are fundamental {#iam-and-sso-are-fundamental}

Information Security (InfoSec) defines certain assets (code, business logic, financial
reports, employers etc.) to be protected from malicious activities with regards to
[CIA](https://brainfck.org/t/cia). Identifying _who_ is doing _what_ and assigning policies/permissions
to different _entities_ will enable _granular_ access based on **ACLs** (Access Control Lists)
and/or **RBACs** (Role Based Access Control). IAM (Identity and Access Management) will also
allow you to _impersonate_ other identies (in more AWS like language: _assume_ other roles
temporarly).


## DevSecOps is more than a mindset {#devsecops-is-more-than-a-mindset}

I consider this more than a mindset - I literally embrace it in my work with developers
and operation folks. Being literally between **SWE** (software engineering) and **operations**
you'll have to take it seriously. This is indeed demanding and requires you to leave your
comfort zone and learn about concepts far away from your _home base_. Once you take an
_hollistic_ approach to Security you'll not only have discussions at same-eye level but
expand your knowledge horizon for further career options.


## ISMS is your friend {#isms-is-your-friend}

Early in my career I've decided to go for the the hands-on/technical path in Information
Security. However, **ISMS** and **compliance** will give you the _acceptance_ to implement security
measures. Don't be afraid of [ISO 27001](https://www.iso.org/isoiec-27001-information-security.html). As you cannot avoid laws and regulations, ISMS
will provide you with the compliance framework needed to get things actually done.


## Shift-left your radius of influence {#shift-left-your-radius-of-influence}

As I've mentioned in [Don't do Security. Enable it!](#don-t-do-security-dot-enable-it) you have to expose yourself to lots of
topics and work in a _cross-functional_ position. You'll talk to developers, DevOps
engineers, product managers, engineering managers etc. All these people live within their
own boundaries, talk a different "language" and have different opinions. That's why you
should

-   learn about [system design](https://brainfck.org/t/system-design)
-   teach yourself about [software architecture](https://brainfck.org/t/software-architecture)
-   learn how software is delivered in an enterprise environment


## Cloud Security is complex {#cloud-security-is-complex}

I once read in [Introduction to Cloud Security for InfoSec professionals](https://www.fugue.co/blog/an-introduction-to-cloud-security-for-infosec-professionals):

> "The cloud is software-defined everything."

With the increasing adoption of **IaC** (Infrastructure as Code) _everything_ becomes a resource
mapped to an _object_ in some code construct. Nowadays you can easily setup complex
infrastructures, destroy them and redeploy again... just by running some code aka
_software_! And as we know: _Software is susceptible to vulnerabilities_.

Running _safe code_ is hard enough. But running _safe infrastructure_ based on code might
become a nightmare. That's why Security professionals are often overwhelmed by the sheer
complexity modern infrastructure creates. You have distributed systems, you have different
actors (persons, machines, applications) accessing all kinds of resources, different
programming languages / frameworks. All this is hard to understand in detail. For this
reason embrace _cloud-agnostic_ **design patterns** meant to protect your assets in-depth. Start
with _best pratices_, setup a _playground_, learn about IAM (as [IAM &amp; SSO are fundamental](#iam-and-sso-are-fundamental)),
start little projects.


## Focus on skills, rather than career paths {#focus-on-skills-rather-than-career-paths}

Last but not least embrace _learning_ as a **life philosophy**. Learn a new programming
language, be passionate about technology, make yourself familiar with a new cloud
provider, listen to topics, read [books](https://brainfck.org/books/)... The goal is to constantly sharpen your _tools_ and
_skills_ and master any topic to a degree that fits your purposes. Be a _generalist_ but
_specialize_ in 1-2 topics (I highly recommend [Range](https://brainfck.org/book/range)).
