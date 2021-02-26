+++
title = "Lessons from building static analysis tools at Google"
author = ["Victor Dorneanu"]
lastmod = 2021-02-26T11:04:26+01:00
tags = ["note", "sca", "google"]
draft = false
weight = 4001
toc = true
+++

<https://cacm.acm.org/magazines/2018/4/226371-lessons-from-building-static-analysis-tools-at-google/fulltext>


## Problems to solve {#problems-to-solve}

-   tool not integrated into developer's workflow
-   users don't trust the results
-   reported bug is theoretically possible, but the problem doesn't really manifest in practice
-   findings are to expensive to fix
-   users don't understand the warnings
-   On "effective false positives":
    -   developers didn't take action after seeing the issue
    -   developers don't understand the fault and therefore don't take action

> Developers, not tool authors, will determine and act on a tool's perceived false-positive rate.

-   Lessons learned from integrating FindBugs into CI/CD
    -   integrate vulns dashboard with devs workflow
    -   Manually triaging issues and filing bug reports is not sustainable at a large scale.
    -   post results (from scanners) as comments on the code-review thread
    -   this integration was discontinued due
        -   the presence of effective false positives caused developers to lose confidence in the tool


## [**Tricorder**](https://research.google/pubs/pub43322/) {#tricorder}

-   Architecture
    ![](images/tricorder_arch.png)

    > Tricorder. Tricorder is designed to be easily extensible and support many different kinds of program-analysis tools, including static and dynamic analyses

    <!--quoteend-->

    > ricorder analyzers report results for more than 30 languages, support simple
    > syntactic analyses like style checkers, leverage compiler information for Java,
    > JavaScript, and C++, and are straightforward to integrate with production data
    > (such as about jobs that are currently running).

-   Scaling
    -   As of January 2018, Tricorder had analyzed approximately 50,000 code review changes per day
    -   Reviewers clicked "Please Fix" more than 5,000 times per day
    -   Tricorder analyzers received "Not useful" clicks 250 times per day.


## Lessons learned {#lessons-learned}

-   Google's initial implementation of FindBugs relied on engineers choosing to
    visit a central dashboard to see the issues found in their projects, though
    few of them actually made such a visit
-   finding bugs in already check-in code is too late
-   analysis tools must be integrated into the workflow and enabled by default for everyone
-   For a static analysis project to succeed, developers must feel they benefit from and enjoy using it.
    -   there is a team behind Tricorder
    -   team performs surveys to understand developer sentiment
    -   developers need to build trust in the tools
    -   If a tool wastes developer time with false positives and low-priority issues, developers will lose faith and ignore results.
