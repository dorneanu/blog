+++
title = "Documentation as Code for Cloud"
author = ["Victor Dorneanu"]
lastmod = 2023-07-17T15:27:29+02:00
tags = ["k8s", "architecture", "aws", "microservices"]
draft = true
series = ["Documentation as Code for Cloud"]
+++

## What to design {#what-to-design}

First let's define the cornerstones for the architecture we would like to
design. For the sake of simplicity and because I am most familiar with it, we
will be using AWS.

In order to have a concrete example, let's implement a **self-destructing Email
service** that allows users to send **self-destructing** emails a la "Mission
Impossible" 😎. The _software architecture_ for the self-destructing email service
consists of following components:

-   **Frontend**

    Handles user interactions and provides general UI for composing and sending
    the emails. Web but also mobile apps should be supported.

-   **Authentication and Access Control**

    Ensures that only authorized users can access the service and send
    self-destructing emails.

-   **Message Lifetime Management**

    Manages the lifespan of the self-destructing emails. It also tracks the time
    of the email creation and sets and expiration period after which the email
    will be automatically be deleted (or made inaccessible).

-   **Data storage**

    The email service requires a backend data storage system to store email
    metadata (sender, recipients, subject, expiration details). The email content
    can be stored encrypted using a cloud storage system.

-   **Notification**

    Handles the delivery of self-destructing email notifications to recipients. It
    can use email, SMS or push notifications to alert recipients about the
    received email and that it will self-destruct after a period of time.

-   **Expiration and Deletion**

    Once the specified lifetime of the email has expired, this component is
    responsible for permanently deleting the email content and the associated
    metadata from the storage system.

-   **Logging and Auditing**

    Records essential information, such as email creation, delivery and any access
    attempts. This helps with identifying potential security breaches or tracking
    email history.

Let's add more complexity and use [microservices](https://brainfck.org/t/microservices)
along with [AWS EKS](https://aws.amazon.com/eks/). The infrastructure for the self-destructing email service,
using AWS and EKS could consist of following components:

-   🗳 **EKS Cluster**

    Use the cluster to manage the containarized [microservices](https://brainfck.org/t/microservices).

-   🧰 **Microservices**

    Let's briefly outline some microservices and their responsibilities:

    -   **Frontend**

        This includes the containerized frontend component as a microservice. It
        handles user interactions and API calls against backend.

    -   **Message Lifetime Management**

        Containerize the message lifetime management functionality as a
        microservice, which tracks the email creation time, sets expiration periods,
        and triggers the deletion of expired emails.

    -   **Notification Service**

        Containerize the notification functionality as a microservice, responsible
        for sending out notifications to recipients about the self-destructing
        emails received.

-   🛡 **API Gateway**

    Allow API access (for frontend and other clients) through a single endpoint
    and implement all Security controls (e.g. authentication, authorization) at
    this layer.

-   🪣 **Data Storage**

    Utilize AWS managed services like Amazon RDS for storing email metadata,
    Amazon S3 or Amazon EFS for storing email content and attachments, and Amazon
    DynamoDB for tracking email history.

-   📊 **Logging and Monitoring**

    Use [AWS CloudWatch](https://aws.amazon.com/cloudwatch/) for logging and monitoring the infrastructure,
    microservices, and application health.

From an _organizational_ point of view there will be multiple **organizational units** (OUs) which
include `tech`, `devops` and `security`.

Within each organizational unit, there will be `multiple accounts`. This allows us
to have different deployment environments such as production (`prod`) and
development (`dev`).


## Introduction {#introduction}

As a Security Architect, my role encompasses reviewing existing architectures as
well as designing brand new ones _from scratch_. The opportunity to apply _Security
principles_ during the design phase and develop an entirely new infrastructure
with Security as the core focus is truly exceptional.

**Designing** a secure cloud architecture is not only vital for achieving _scalability_,
_reliability_, and _compliance with regulations_. It allows businesses to optimize
their cloud infrastructure while maintaining the highest levels of data
security.

Being able to **prototype** and **visualize** a draft for the upcoming architecture will
greatly support making thought-out decisions. In this blog post, I will present
some technologies and tools that I have come across.


## Draft using pen &amp; paper {#draft-using-pen-and-paper}

{{< gbox src="/posts/img/2023/documentation-as-code/cloud-architecture-paper.jpg" title="Cloud Architecture using Pen & Paper" caption="Initial draft for the architecture of the self-destructing mail service" pos="left" >}}

As described above, there will be multiple organizational units. I did not
include any accounts on paper, as doing so would have overcomplicated the entire
drawing:

-   OU: Tech

    This will host the **EKS cluster** as well as the **API Gateway** which serves as the
    main entrypoint for API calls.

-   OU: Security

    This is where **alert &amp; monitoring** will take place. Also here relevant data to
    the mail will be stored within **S3 buckets**. Finally we use **IAM** capabilities to
    make sure authentication and authorization works properly.

-   OU: DevOps

    The **CI/CD** build pipeline and **infrastructure provisioning** will take place here.
    The software artefacts will be built here and deployed into the accounts
    inside "OU: Tech".


## Outlook {#outlook}

In the next post, I'll show how to draw the architecture using [PlantUML](https://brainfck.org/t/plantuml).
