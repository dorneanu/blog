+++
title = "Bye bye Scout24!"
author = ["Victor Dorneanu"]
lastmod = 2021-09-15T09:52:48+00:00
tags = ["byebye"]
draft = false
+++

![](/posts/img/2021/bye-bye-scout24.jpg)
I guess it's become a tradition to write _[bye bye](/tags/byebye)_ posts whenever I switch jobs. So this happens again as I've decided to pursue new opportunities elsewhere. I feel sad but also excited at the same time. Working for 5 years for the same company (I do know that's not thaaaat long) feels like I've spent half of my life there. Since 2016 many colleagues have left the company and new ones joined the Security team which I was part of. During these 5 years the Security team has made a quite succesful transition from a mostly **red team** to a **blue team** one. While at the beginning I was doing **penetration tests** like there was no tomorrow, I now leave my team with internal self-built, self-managed security products (mostly in [Python](/tags/python) ,[Golang](/tags/golang) ) for the developer teams at Scout24.


## <span class="org-todo done DELEGATED">DELEGATED</span> Things I've learned {#things-i-ve-learned}

And while I had the opportunity to improve my pentest skills (mostly web applications), there are tons of new
things I've learned:

-   [AWS](/tags/aws)
    -   Before joining Scout24 I completely had no cloud experience
    -   I'm still not an expert but I can get along. My team got used to this quote:
        _AWS is like a kitchen. You just use whatever you need for your dish._
-   [Serverless](https://brainfck.org/#Serverless)
    -   The very first time I worked on a serverless project (codestripper) it felt like magic
    -   It was so _magic_ that I've generated my first so called _5k Issue_
    -   I've learned that coding for a cloud + serverless environment is so much different than running your code on your laptop/inside docker
-   [Golang](/tags/golang)
    -   I was the first one in the team to setup a quite complex Golang project
        -   @Ralph: I know you were actually the first one. But the mini snippets you've used don't really count :D
    -   This year I was able to convince the team to start a new project (related to [dependabot](https://dependabot.com/)) in Go (instead of [Python](/tags/python) )
    -   I was amazed and surprised how fast we were able to add more and more features while having a steep learning curve
    -   I've held my "**Golang for Hackers**" workshop for the Security team where I've shown how to build small Golang applications for compromised systems (e.g. port scanners, TOR clients, DNS tunneling)
-   [Python](/tags/python)
    -   Although I've been coding in Python since years, contributing to an enterprise software project was a different experience
    -   For the first time in my life I was forced to write unit tests (thanks David!) and think about CI/CD
    -   Doing complex stuff in Python also showed me it's weaknesses and there are some good reasons why I still prefer static typed languages (like [Golang](/tags/golang)) for big projects


## Thanks to {#thanks-to}

Without any claim to completeness I've setup a list of people I'd like to express my gratitude and appreciation to. Many of them already left Scout24 but their thoughts (and attitude!) had a huge impact on my personal growth. Here it goes (in somehow chronological order):

-   **Ralph**
    -   Thanks for being a buddy and for our lovely _office romance_
    -   You still owe me a bottle of [Țuică](https://en.wikipedia.org/wiki/%C8%9Auic%C4%83)
    -   Thanks for sharing your _Netzwerkgehampel_ (German for colloquial "network stuff") with me
-   **David V**.
    -   Dude, do you remember our pentest sessions?
    -   Especially the PHP related ones?
    -   I hope you're well (what about your cats?)
-   **Fridtjöf**
    -   Thanks for on-boarding me
    -   Do you remember that 1:1 ssession where I've told you behind you some strange guy is wattering his plants on the balcony completely **naked**? Sorry for this (funny) anecdote but I guess I won't forget that situation for my whole life
-   **Markus**
    -   Thanks for pushing me beyond my limits, for making me to think big
    -   You were like a mentor for me, always calm and always close to the team
    -   Also thanks for the BBQ partys and the discussions we had at [AWS Re:inforce](https://reinforce.awsevents.com/)
-   **Alex**
    -   Mon ami, I've really enjoyed our lunch dates and the training sessions we had in the fitness room
    -   I wish you all the best on your new carrer path
-   **Hussam**
    -   I really convinced you to learn [Golang](/tags/golang)! I'm so proud of you
    -   Also thanks for your AWS knowledge-sharing sessions
    -   _The best or nothing_, right?
-   **Slava**
    -   Man, if you only knew how deep I got into Emacs and ORG mode! It basically changed the way I work and organize my life
    -   Thanks for your inspiration
-   **Gervais**
    -   Mon ami 2, I really enjoyed our political discussions after lunch
    -   I still hope you'll do some ice baths some day :)
    -   And in case you feel cold, just do some Scala compiling (ya know what I'm talking about)
-   **David**
    -   Unit tests, unit tests, unit tests!
    -   Thanks for doing the frontend related workshops
    -   I really enjoyed our infrastructure/design sessions
-   **Mostafa**
    -   Quote of the year: "People with fast internet can be very sensitive"
    -   Thanks for taking care of all the shit nobody wanted to take care of
    -   Your appsec related workshops/presentations were awesome!
-   **Daniel**
    -   Thanks for introducing "organized work/planning" to the team
    -   I also thank you for making me a more responsible engineer and adopting "constructive criticism"
-   **Felix**
    -   Thanks for attending my "Golang for Hackers" session
    -   I hope DNS tunneling will have some benefit for you
-   **Abed**
    -   Was a pleasure to meet you and do some real work with you
    -   I'm looking forward to the next rewrite: Golang to Kotlin, back to Python?
    -   One more thing: Your mouse is still moving! :)
-   **Rakib**
    -   Our pairing sessions on some Python code were amazing
    -   I wish you all the best with your studies
