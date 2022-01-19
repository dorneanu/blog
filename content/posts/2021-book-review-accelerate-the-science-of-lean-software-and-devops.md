+++
title = "Book review: Accelerate - The science of Lean software and DevOps"
author = ["Victor Dorneanu"]
date = 2021-11-24T20:24:00+01:00
lastmod = 2022-01-06T11:03:11+01:00
tags = ["books", "devops", "architecture"]
draft = false
+++

I always use to say: "_Software currently rules the world._" Almost every aspect in our
(digital) life has to do with software: The apps you use on your smartphone, the
mail/hosting services you rely on, online shopping, train tickets, in general everything
that somehow adds value to your life. Competition among organizations is driven by speed,
the ability to deliver new features to the customers, stable products, security within
their eco-systems and many other aspects. And what do they have in common? If you ask me:
**Software**.


## Key takeaways {#key-takeaways}

-   Software delivery performance is vital for business since it impacts the speed and velocity you deliver value to your customers
-   There are 24 practices that can have an influence on your software delivery and these are categorized into 5 categories
-   It takes technical but also organizational changes to create high-performing teams
-   Strong leadership but also agile practices like Lean, Scrum, Kanban will help you to focus on your customer needs, implement requested features and adapt if needed
-   Continuous Delivery (CD) plays a vital role and is driven by a DevOps oriented mindset


## Introduction {#introduction}

Usually I don't do book reviews. I just tend to collect my notes and thoughts in my
[Zettelkasten](https://brainfck.org). But this time I wanted to share some insights, write them down and convince
you why you should read this book. [Accelerate](https://brainfck.org/#Accelerate) is not about **software
engineering** nor entirely about **DevOps**. It does have something to do with the [Agile
manifesto](https://agilemanifesto.org/) but from a more data-driven, scientific point of view. To be more precise, the
authors **analyzed** over many years factors that enabled teams to deliver software (features)
in short cycles while still limiting technical debt and having a stable and secure
deployment process.


### Big picture {#big-picture}

If you want to skip the details, just have a look at this diagram and try to understand how software delivery is impacted by different areas.

{{< gbox src="/posts/img/2021/accelerate-big-picture.png" title="Accelerate Big Picture" caption="Which factors lead to software deliver improvement? There are different factors that are somehow inter-dependent" pos="left" >}}


## Speed {#speed}

Why is speed so important? Because it does make a difference how fast you can "conquer" a market and
deliver value to your customers. Or as the authors put it:

> Business as usual is no longer enough to remain competitive. Organizations in all
> industries, from finance and banking to retail, telecommunications, and even government,
> are turning away from delivering new products and services using big projects with long
> lead times. Instead, they are using small teams that work in short cycles and measure
> feedback from users to build products and services that delight their customers and
> rapidly deliver value to their organizations. These high performers are working
> incessantly to get better at what they do, letting no obstacles stand in their path, even
> in the face of high levels of risk and uncertainty about how they may achieve their goals.
>
> At the heart of this acceleration is software.
>
> -- [Accelerate](https://brainfck.org/#Accelerate)


## Software delivery performance {#software-delivery-performance}

Research presented in the book has found **24** key capababilities that seem to drive **software
development performance**. If you are a **high-performer** or a **low-performer** merely depends on
the capabilities you, your team and your organization focus on. The authors have defined 5
categories for these capabilities:

-   **Continuous Delivery (CD)**
-   **Architecture**
    -   architectural characteristics
-   **Product and process**
-   **Lean Management and Monitoring**
-   **Culture**

Before we go into deep discussion, let me try to summarize why **capabilities** matter more than **maturity**.


## Capabilities vs Maturity {#capabilities-vs-maturity}

Lots of **mature** organizations think they own a quite big piece of cake when it comes to
market share. While relying on that, they tend to become less innovative, have complicated
internal processes (slows down the overall development process), lose talented
high-performers (who wants to work in a slow, process-heavy environment?). Instead they
should focus on certain capabilities in order to **drive continuously improvement**.

Once organizations arrive at a mature state, they see their journey as accomplished and
declare themselves done. However, this way they don't adapt to technological changes and
those within the business landscape. High-performing organizations are **always striving to
be better** and never consider themselves as done or mature.

> Technology leaders need to deliver software quickly and reliably to win in the market. For
> many companies, this requires significant changes to the way we deliver software. The key
> to successful change is measuring and understanding the right things with a focus on
> capabilities—not on maturity.
>
> -- [Accelerate](https://brainfck.org/#Accelerate)

Mature organizations not only have a bad time to keep up with new technologies but they
also **prescribe the same set of technologies** for every set of teams in order to progress.
The better approach would be to take into consideration current context, used systems,
goals and constraints and focus on the capabilities that will give the teams the most
benefit. This way different parts of the organization are allowed to take a customized
approach to improvement.

**Maturity models** also tend to define a static level of technological, procedural and
organizational abilities to be achieved. What is good enough and high-performing today,
might no longer be good enough next year.


## Measuring performance {#measuring-performance}

Most organizations focus on "old-school" technical measures like lines of code, velocity
which measure some performance locally (in general within a limited scope) rather than on
a more global one. Developers (and DevSecOps folks as well) are supposed to **solve business
problems** and therefore focus on a **global outcome** and not output. It doesn't matter how
many lines of code your team has, how often you deploy, how many Security tools you have
implemented within your CI/CD pipeline. If it doesn't help to achieve organizational
goals, then you're focussing more on the output rather than outcome.


### Software Delivery Performance {#software-delivery-performance}

Since it should be clear by now that the faster you are able to deliver your software to
your customers, the more you're confident you're doing the right things, the book defines
4 criterias for software delivery performance:

-   **Delivery Lead Time**
    -   you would usually measure
        -   time to design and validate customer request
        -   time to deliver feature to customer
-   **Deployment frequency**
    -   the work load here is very important
    -   you should slice you work in small batches that can be completed in a short time period (a week or even less)
    -   decompose your work into small features
        -   this will allow rapid development
        -   you should be able to deploy more frequently
    -   use **MVPs** to first validate the requirements and to incorporate customer feedback
        -   this way to can create value very quickly
        -   you can still have **clean code** and all the things **after** you're sure you're building the right thing
-   **Mean Time to Restore** (MTTR)
    -   the average time to restore services
-   **Change fail percentage**
    -   this failure rate measures how often deployment failures occur in production that require immediate attention and remediation (e.g. rollbacks)
    -   this also applies to infrastructure configuration changes


### How fast is fast? {#how-fast-is-fast}

After presenting the criterias, let's have a look at some raw numbers.

<div class="table-caption">
  <span class="table-number">Table 1</span>:
  Software Delivery Performance in 2017
</div>

| 2017                 | High Performers                    | Medium Performers                        | Low Performers                                 |
|----------------------|------------------------------------|------------------------------------------|------------------------------------------------|
| Deployment Frequency | on demand (multiple times per day) | Between once per week and once per month | Between once per month and once every 6 months |
| Delivery Lead Time   | < 1 hour                           | Between one week and one month           | Between one month and 6 months                 |
| MTTR                 | < 1 hour                           | < 1 day                                  | < 1 day                                        |
| Change fail rate     | 0-15%                              | 0-15%                                    | 31-45%                                         |

As you can see high-performers have a quite high deployment frequency and most important
the delivery lead time is extremely fast.


## How to accelerate {#how-to-accelerate}

Now that you knwo the key metrics when it comes to **software delivery performance** how do
you actually _accelerate_ and start changing your organization? Of course you can

-   change the **culture** within you deliver value
-   improve on a **technical** level
-   have an effective **architecture**
-   invest in a strong **leadership**

Let's dissect each one piece by piece.


### Change culture {#change-culture}

In order to understand which changes are good for your organizations, sociologist _Ron
Westrum_ has defined a model on importance of **organizational culture**. Before he was
researching on human factors in system saftey, especially in the context of accidents in
technological domains that were highly complex and risky (aviation and healthcare). From
his point of view organization culture is vital because it defines how **information flows
through an organization**. He defines following types of organizations:


#### Orgnization types {#orgnization-types}

-   **pathological (power-oriented)**
    -   characterized by large amounts of fear and threat
    -   information is not made transparent and/or is withhold for political reasons
-   **Bureaucratic (rule-oriented)**
    -   protect departments
    -   those in the department want to maintain their turf (area)
    -   insist on their own rules
    -   do things by their book
-   **Generative (performance-oriented)**
    -   focus on the mission
    -   everything is focused on good performance, to doing what is supposed to do

In Westrum's theory **information flow** within an organization has a **huge impact** on its performance:

-   good culture requires **trust** and **cooperation** between people across the organization
    -   it also maps the way how team collaborate in the company
-   having a good organization culture can have an impact on the quality of **decision-making**
    -   if information is made transparent and available, taking decisions is way easier
    -   you can also reverse the decisions if they turn out to be wrong
        -   no blame game
        -   seek for trial and error
-   teams within thise open environment are more likely to do a batter job, since problems and conflicts are rapidly discovered and addressed

{{< notice info >}}
You can read more about Westrum's organizational culture on [Google's DevOps guide](https://cloud.google.com/architecture/devops/devops-culture-westrum-organizational-culture).
{{< /notice >}}


### Change technical practices {#change-technical-practices}

Among the software and tools you use within your team, there is one _capability_ that seems
to have a big impact on your overall performance: **Continuous Delivery**.


#### Continuous Delivery {#continuous-delivery}

_Continuous Delivery_ is a set of capabilities to enable changes of all kinds (features, configuration changes, bug fixes, experiments) go into production "safely", "quickly" and "suistanably". There are some _principles_:

-   **Build quality in**
    -   Eliminate the need for mass inspection by building quality into the product in the first place
    -   invest a culture supported by tools and people where issues can be detected quickly
    -   issues should be fixed straight away when they're cheap to detect and resolve
-   **Work in small batches**
    -   split work in smaller chunks that deliver measurable business outcomes on a small part of the market
    -   through feedback the course can be corrected
    -   also a key goal is to change the economics of the software delivery process in order to minimize the cost of cost of changes
-   **Computers perform repetitive tasks, people solve problems**
    -   take long repetitive work (testing, deployments) and invest in simplyfing and automating this work
    -   this way "people" have more time for problem-solving work
-   **Relentlessly pursue continuous improvement**
    -   high-performers are never satisfied
    -   they make improvement part of their daily work and culture
-   **Everyone is responsible**
    -   everyone involved in the software delivery process has to work together

In order to implement **CD** following **foundations** should be created:

-   Comprehensive configuration management
    -   build, test and deploy software fully in an automated manner from information stored in a version control system
    -   any changes should be applied in the version control
-   [Continuous Integration (CI)](https://brainfck.org/#Continuous%20Integration%20(CI))
-   [ Continuous Testing](https://brainfck.org/#Continuous%20Testing)

During their research the authors have identified following **key drivers** for continuous delivery:

-   **Version Control**
    -   I guess this one is indisputable
-   **Deployment Automation**
-   **Continuous Integration**
    -   use Trunk-Based development
    -   each change triggers a build process (incl. running test suites)
    -   if any part of the process fails, developers should be notified immediately
-   **Trunk-Based Development**
    -   don't use long-lived feature branches; keep them short
    -   merge with trunk/master as soon as possible
    -   deploy changes into production as fast as possible
-   **Continuous Testing**
    -   tests should run as a vital part of the development process
    -   automated unit tests and acceptance tests should run against every change in VC (version control) in order to give developers immediate feedback on their changes
    -   also check [Software Testing](https://brainfck.org/#Software%20Testing)
-   **Test Data Management**
    -   when dealing with automated tests, managing test data can be challenging
    -   high-performers use to have proper test data for the testing
-   **Shift Left on Security**
    -   this is a broad topic and it's basically about the idea that you apply Security measures very early in the development process
    -   you could do consultancy work and help developers to implement new features with a hacker mindset
    -   you could apply automated Security testing as part of your tests suite
-   **Loosely Coupled Architecture**
    -   software architecture can become a significant barrier when you want to increase the stability of the release process and the speed you deliver new features
    -   architectural decisions and constraints do have an impact on delivery performance
    -   an effective architecture should enable teams to easily test and deploy **individual** components/services even if the organization or the number of systems it owns/operates grow
    -   this should allow productivity to increase while having scalability


### Change architecture {#change-architecture}

As I've mentioned previously a **loosely coupled architecture** enabled high-performers to better build and maintain systems. No matter what kind of systems you are building
there should be little communication required between delivery teams in order to get work done. Futhermore the architecture of your systems should _enable_ teams to test, deploy and change systems without depending on other teams. Communication channels should not be ignored completely. However, they should be used for discussing high-level _shared_ goals and how to achieve/implement them. Fine-grained decision-making on a technical level should only take place within the teams - unless you are required to
discuss technical stuff with other members as well. Also important: **Let the teams chose tools and technologies**. (Good software) architects should focus on concepts, engineers and outcomes, not on technical discussion and concrete tools/technologies.

{{< notice info >}}
Also check out my bookmarks and notes on [architecture](https://brainfck.org/#Architecture). I also recommend reading [The Clean Architecture](https://brainfck.org/#The%20Clean%20Architecture) and [The Clean Code](https://brainfck.org/#The%20Clean%20Code).
{{< /notice >}}


### Change product management {#change-product-management}

If you've noticed already, the book title mentions _The Science of Lean Software and DevOps_. While most of you probably know what **DevOps** is about, what is **Lean Software**?
The term itself (_Lean_) derives from _Lean Management_ and used to be Toyota's approach to car (manufacturing):

-   originally designed to solve the problem of creating a wide variety of different types of cars for the Japanese market
-   this enabled Toyota to build cars faster, cheaper and with higher quality than the competition
-   the US manufacturing industry only survived by adopting these ideas and methods

How can these methods be applied to software engineering? Well, let's have a look at some characteristics:

-   **Limit work in progress**
    -   work in small batches (as mentioned previously)
    -   the idea is to have work decomposed into features that allow rapid development, instead of complex features developed on (feature) branches and deployed infrequently
    -   merge with trunk/master as fast as possible
-   **Visual management**
    -   create and maintain visual displays to show key quality and productivity metrics and the current status of work (also problems)
    -   make these displays available to both engineers and leaders
    -   align these goals with operational goals
-   **Feedback from production**
    -   Use data from application performance and infrastructure monitoring tools to make business relevant decisions on a daily basis
-   **Lightweight change approvals**
    -   have a easy-to-follow change management process
    -   teams should be allowed to try out new ideas, create and update requirements during development process without any approval of people outside the team
    -   no time intensive approvals by external entities (boards, managers etc.)


### Make people happy {#make-people-happy}

While technical practices have an impact on the ability to deliver software quickly, they can also help to reduce stress and anxiety related to the fear of breaking something.
When people are not confident that their changes will break anything in production, their productivity and motivation decline. In order to reduce deployment pain and reduce the risk of a burnout, the authors recommend to:

-   design and build systems to be deployed easily into multiple environments
    -   failures can be asily detected and mitigated
    -   various components of the systems can be updated independently
-   make sure that state of production systems can be reproduced in an automated manner from version control
-   design and implement the deployment process as simple as possible


### Have strong leadership {#have-strong-leadership}

While _leader != manager_, leadership should be about inspiring and motivating people surrounding you. Even more: A **transformational leadership** should affects a team's
ability to:

-   deliver code
-   architect good systems
-   apply _Lean Software_ development pratices (as descrived before)

These are the characterstics of a good transformational leader (Rafferty and Griffin 2004):

-   **vision**
    -   has clear understanding where the currently the org is and where it should be in the next 5 years
-   **inspirational communication**
    -   inspires and motivates, even in an uncertain or changing environment
-   **intellectual stimulation**
    -   challenges followers to think about problems in new ways
-   **Supportive leadership**
    -   demonstrates care and consideration
-   **Personal recognition**
    -   praises and acknowledges achievement of goals/improvements in work quality


## Conclusion {#conclusion}

DevOps and Agile are already used by many organizations as part of their transformation strategy. They encourage a culture of transparency, shared responsability, faster feedback
and automization. [Accelerate](https://brainfck.org/#Accelerate) is the scientific, data-driven approach to put all pieces together, to show you how they depend on each other and finally achieve a better organizational performance.  And while software is at the heart of most modern companies it is essential to have a solid, stable and secure software delivery process.

For me this book was definitely one the most influencial ones I've read in the past years.
You might also check out [other books by
Gene Kim](https://itrevolution.com/faculty/gene-kimother) (he is one of the authors) if you're interested in DevOps, Agile transformation
and successful user stories. Beside that I also recommend the
[Google SRE books](https://sre.google/books/).
