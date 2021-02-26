+++
title = "Scaling Static Analyses at Facebook"
author = ["Victor Dorneanu"]
lastmod = 2021-02-26T11:12:17+01:00
tags = ["note", "sca", "facebook"]
draft = false
weight = 4002
toc = true
+++

<https://cacm.acm.org/magazines/2019/8/238344-scaling-static-analyses-at-facebook/fulltext>

> To industry professionals we say: advanced static analyses, like those found in
> the research literature, can be deployed at scale and deliver value for general
> code. And to academics we say: from an industrial point of view the subject
> appears to have many unexplored avenues, and this provides research
> opportunities to inform future tools.


## Deployments {#deployments}


### "diff time" deployment {#diff-time-deployment}

-   analyzers participate as bots in code review
-   make automatic comments when engineer submits code modification
-   this kind of deployment lead to **70% fix rate**
-   traditional (offline or batch) deployment saw a **0% fix rate**
-   security related issues are pushed to the security engineer on-call for
    commenting on code modification


### Software Development at Facebook {#software-development-at-facebook}

-   there is a main codebase (master)
-   this gets altered by modifications submitted by devs
-   CI/CD:
    -   anaylyses run on the code modification and participate by **commenting their
        findings directly in the code review tool**


## Reporting {#reporting}

> The actioned reports and missed bugs are related to the classic concepts of true
> positives and false negatives from the academic static analysis literature. A
> true positive is a report of a potential bug that can happen in a run of the
> program in question (whether or not it will happen in practice); a false
> positive is one that cannot happen.


### False positives {#false-positives}

> the false positive rate is challenging to measure for a large, rapidly changing
> codebase: it would be extremely time consuming for humans to judge all reports
> as false or true as the code is changing.

-   don't focus on true positives and false negatives (even if valuable concepts)
-   pay more attention to **action rate** and the observed **missed bugs**


### Actioned reports {#actioned-reports}


### Observable missed bugs {#observable-missed-bugs}

-   has been observed in some way
-   but was not reported by an analysis


## Tools {#tools}

Tools used by Fb to conduct static analysis


### [Infer](https://github.com/facebook/infer) {#infer}

> Infer has its roots in academic research on program analysis with separation
> logic,5 research, which led to a startup company (Monoidics Ltd.) that was
> acquired by Facebook in 2013. Infer was open sourced in 2015 (www.fbinfer.com)
> and is used at Amazon, Spotify, Mozilla, and other companies.

-   targets mobile apps
-   applied to Java, Objective C and C++
-   processes about 10s of millions of Android and Objective C code
-   uses analysis logic based on the theory of **Separation Logic**
-   finds errors related to more than 30 types of issues:
    -   memory safety
    -   concurrency (deadlocks and starvation)
    -   security (information flow)
    -   custom errors (suggested by Fb devs)


### Zocolan {#zocolan}

-   mainly does "taint" analysis
    -   builds a dependency graph that related methods to their potential callers
    -   uses this graph to schedule parallel analyses of individual methods
-   deployed for more than 2 years (in 2019), first to security engineers then to
    software engineers
-   report can trigger the security expert to create tasks
-   can process over 100-million lines of [Hack](https://hacklang.org) code in less than 30 minutes
-   implements new modular parallel taint analysis algorithm


## Lessons learned {#lessons-learned}


### First run {#first-run}

First deployment was rather batch than continous:

-   run once (per night)
-   generate list of issues
-   assign issues to devs

Results:

-   devs didn't act on the issues assigned
-   Fb reduced the false positive rate (down to 20%) but devs still didn't take
    actions on issues


### Switch to Diff time {#switch-to-diff-time}

-   the response of engineers was at about 70%
-   positive rate didn't change
-   but the impact was bigger when the static analysis was deployed at diff time


### Human factors {#human-factors}

The success of the diff time came as no surprise to Fb's devs:

-   mental effort of context switch+
    -   if dev is working on one problem, and the assigned issue is about another
        one, they must swap out the mental context of the first problem and swap in
        the second
    -   by participating as a bot in the code review process, the context switch was
        kind of solved
-   relevance
    -   sometimes it's hard to find the right person to assign issues to
    -   by commenting on a diff that introduces an issue we have a pretty good
        chance to find the relevant person


## Additional resources {#additional-resources}

-   ["Move fast and secure things (with static analysis)" by Ibrahim Mohamed El-Sayed](https://www.youtube.com/watch?v=Vj0QVRaw8A4)
-   [How Facebook uses static analysis to detect and prevent static issues](https://engineering.fb.com/security/zoncolan/)
