+++
title = "TDD"
author = ["Victor Dorneanu"]
lastmod = 2021-02-26T11:04:30+01:00
tags = ["note"]
draft = false
weight = 2006
toc = true
noauthor = true
nocomment = true
nodate = true
nopaging = true
noread = true
+++

## Definition {#definition}

<https://leanpub.com/golang-tdd/read>

> Test-driven development is a strict discipline for creating modular,
> well-designed and testable code without doing any upfront design. It achieves
> this by making you work in extremely short cycles: create an automated test,
> write the minimum amount of code to satisfy that test, and refactor your code to improve the quality.


## Cycles {#cycles}

There are **3 cycles**

-   Red
    -   The cycle starts by writing a test that captures the new requirement; this test is expected to fail. Many tools display test failures in red, hence the name.
-   Green
    -   The cycle continues by writing the minimal amount of code necessary to satify the tests. This name too is derived from the fact that many tools display test success in green. When you start practicing test-driven development, it is a common pitfall to write more than the minimal amount of code. Be aware of this, and keep asking yourself if you are doing more than the minimum required.
-   Refactor
    -   The latest step in the cycle is what makes test-driven development a viable process: it forces you to step back, to look at your code, and to improve its structure without adding any functionality. The refactor step is not an optional step6 – without this step your code will quickly degenerate into a well-tested but incomprehensible mess.


## Test doubles {#test-doubles}

Traditionally, there are five types of **test doubles**:

Dummies
: Types without any behavior at all, provided only because the signature of the unit under test requires them.

Stubs
: Types implementing the minimum amount of behavior to satisfy a test.

Mocks
: Partial implementations for which you can define expectations on how their methods will be called.

Spies
: Partial implementations on which you can assert that specific methods have been called.

Fakes
: Full, lightweight implementations such as in-memory databases.
