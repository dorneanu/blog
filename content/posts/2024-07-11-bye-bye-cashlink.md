+++
title = "Bye Bye Cashlink!"
author = ["Victor Dorneanu"]
lastmod = 2024-07-11T09:12:32+02:00
tags = ["byebye"]
draft = false
+++

In the midst of the Corona pandemic back in 2021, I joined the team at [Cashlink](https://cashlink.de/en/), a company focused on **tokenization** and **digital securities**.
{{% sidenote %}}
You can also check out their whitepaper and learn more [here](https://cashlink.de/en/tokenization-explained-4-steps-of-tokenization/).
{{% /sidenote %}} With little understanding of these concepts, I embarked on this new journey as a _Senior Security Engineer_ within the TECH team. Promised a _greenfield_ environment, I stepped into the unknown, excited yet uncertain about what I was expected to to.

{{< gbox src="/posts/img/2024/bye-bye-cashlink/laptop.png" title="Back of my laptop" caption="I wish I had more funny stickers, like the ones I had at Scout24 🧐" pos="left" >}}

As I look back on almost three years of knowledge sharing at Cashlink, I realize just how much I've learned. Embracing one of Cashlink's core values, I consistently strived to _challenge the status quo_. Throughout this journey, I've gained a deep understanding of what DevSecOps truly is about, with a particular focus on the _operational side_.

Having said this, I'm looking forward to my newest challenge, where I'll switch focus to the _Dev_ part in DevSecOps and delve deeper into _software engineering_, but still within the Security context. I also anticipate doing more coding, particularly in _Golang_, which kind of makes me happy. I remain grateful for all that I've experienced and learned at Cashlink and hope to see you all soon again, whether in Frankfurt, Cluj, or Berlin!
{{% sidenote %}}
Cashlink was and still is a remote first company. Also check their [career page](https://cashlink.de/en/career/).
{{% /sidenote %}}


## What I've learned {#what-i-ve-learned}

As I was implementing security in the greenfield area, I had the chance to strengthen my knowledge in specific areas but also deep-dive into new ones.

-   **AWS**
    -   One of the first things I wanted to introduce was **SSO** which mainly included configuration of the [AWS Identity Center](https://aws.amazon.com/iam/identity-center/) with an _external_ Identity Provider (IdP). Later I was introducing **SSO for SSH** (using [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)) which required employees to first do _authentication_ against the **IdP** before SSHing into machines.
    -   While I had no clue about [SAML based SSO](https://support.google.com/a/answer/6262987) later on I've also had the chance to implement several [OIDC based](https://auth0.com/docs/authenticate/login/oidc-conformant-authentication/oidc-adoption-sso) workflows
    -   Back at Scout24 I've barely had to deal with IaC (Infrastructure as Code) where **CDK** was mainly used. At Cashlink I've created my first [CDK applications](https://aws.amazon.com/cdk/) for different setups. While being an convinced CDK is the way to go, I later on had the chance to learn _Terraform_ which is my prefered IaC solution at the moment. Using [Terraform](https://www.terraform.io/) I was able to quickly create PoCs and manage complex infrastructure setups
{{% sidenote %}}
        You can read about my latest Terraform based projects at [defersec.com](https://defersec.com/)
        {{% /sidenote %}}
    -   Personally, setting up the networking infrastrcture (several [VPCs](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html), with several [TGWs](https://aws.amazon.com/transit-gateway/) in a [multi-account organization](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html)) was the biggest challenge which taught me a lot about networking and what Network Security is about.
-   **IAM** (as a _concept_)

    -   Especially within _distributed systems_ proper and granular **access management** becomes of the most fundamental Security pillars
    -   _IAM_ (Identity &amp; Access Management), when done properly, definitly can reduce the _blast radius_ in case of a Security incident.
    -   Besides _OIDC_ and _SAML_ I definitely learned how to setup IAM concepts which include _authentication_ and _authorization_ for different entities (people and machines, generally speaking) within an organization. Later on, while setting up the **K8s** cluster I've learned about [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) based authentication.
{{% sidenote %}}
    AWS lately introduced [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).
    {{% /sidenote %}}
-   **K8s**
    -   Retrospectively, I wish I'd have started learning about the concepts way earlier. While I was learning by implementing stuff, I didn't have a proper introduction which also explained the underlying technologies. Only a few weeks ago, I've decided to take a more structured approach and purchased [Kubernetes in Action](https://www.manning.com/books/kubernetes-in-action) which I think is an excellent introduction with good practical examples.
    -   Nevertheless I was fortunate enough to have some close insights into [AWS EKS](https://aws.amazon.com/eks/), what it takes to _manage it_, how to deal with _secrets_ and _configurations_. As I already was mentioning in in the IAM section understanding [Kubernets RBAC system](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) and how one can map AWS IAM to it, took a while (right _Aron_? 😎)
    -   As I'm reading more all the concepts suddenly make sense and I can finally grasp better how all the pieces work together. I will definitely create my own cluster soon (most probably using [k3s](https://k3s.io/)) for having a playground where I can safely play with [helm charts](https://helm.sh/), deploy applications.
-   **Smart Contract Security**
    -   Smart contracts are at the heart of Cashlink's core business. Diving deep into smart contracts, especially using Solidity, was quite a challenge as a complete beginner.
    -   Understanding all the potential attacks related to these contracts proved to be a challenging task as long as you don't have to deal with it on a daily basis. I hope that someday I'll have the time and resources to set up a playground where I can experiment with these technologies and simulate various smart contract attacks.


## Shoutout to {#shoutout-to}

-   **Cashlink Team**
    -   A 💗 thanks to everyone I had the opportunity to meet, for all the conversations we shared, and the lively kicker sessions we enjoyed in Frankfurt. Last but not least, thank you for welcoming me in Cluj, where I had the chance to say "goodbye" in person to (almost) all of you!
-   **Verena**
    -   Thank you for your kindness and patience in just listening and guiding me through some difficult times in my life. See you soon in Berlin!
-   **Dragos**
    -   You might not be able to read this as you're on your trip on the [Via Transilvanica](https://www.viatransilvanica.com/en/). I hope you'll finish your tour and come back full of energy. Also thanks for our coffee sessions, our discussions and sometimes for some good advice whenever something didn't go smooth. Let's do that 🏰 thing again, once we turn 50! 🤎
-   **Mariano**
    -   You were right! Our first discussion back in Frankfurt was about working in _full-remote_ and the fact I still need a community / colleagues around me. You remembered that when we met in Cluj this year! I really enjoyed our discussoin around _nutrition_, _sports_ and life in general. Take care and see you end of August 😋
-   **Aron**
    -   Thanks for your patience and for the fact you were the one to teach me K8s! Let's keep in touch and conquer the world with Golang, Terraform and Kubernetes. I also wish you all the best with your climbing career 🧗
-   **Maik**
    -   Let's go to _Aventura_, right? I guess we both won't forget that evening. I wish you all the best becoming a 🇧🇬 and let's do the _Moldova trip_ soon again.
-   **Anca**
    -   I admire you for your discipline and perseverance! I hope to see you someday at the Olympics 🏃
-   **George**
    -   "Who's Rosa?" 🤣 I really enjoyed our discussion lately in Cluj! I hope you'll find your place and get rich soon 😎
-   **Rafael**
    -   I'm glad I've convinced you to buy a [La Pavoni](https://www.lapavoni.com/en/families/domestic-machines/lever-coffee-machines). You definitely have reached nerd level 500 with all the [mods and customizations](https://coffee-sensor.com/product-category/la-pavoni-parts-and-accessories-custom-made-from-coffee-sensor/) 😎. I'm still looking forward meeting your home roaster.
-   **Yubikey Gang**
    -   Without mentioning any names, y'all know: It was **RDCSLY** fun spending time with you 🫶
