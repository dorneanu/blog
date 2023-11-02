+++
title = "Documentation as Code for Cloud - C4 Model & Structurizr"
author = ["Victor Dorneanu"]
lastmod = 2023-11-02T20:02:33+01:00
tags = ["aws", "c4", "architecture", "documentation"]
draft = false
series = ["Documentation as Code for Cloud"]
+++

## Introduction {#introduction}

In the [last post](/2023/07/30/documentation-as-code-for-cloud-plantuml/), I've used [PlantUML](https://brainfck.org/t/plantuml) to draw things like **groups**, **accounts**, and **clusters**. However, I didn't focus on how
different parts inside the business layer interact (usually components related to the main application/system relevant
for your business). Now, we'll use a DSL
{{% sidenote %}}
Domain-Specific Language specific for this use case
{{% /sidenote %}} to show these interactions between _components_, _services_, and _systems_. I'll use the **C4 model** to show the same system in **different ways** based on who we're showing it to. It allows us to adjust how much detail we include.

{{< gbox src="/posts/img/2023/documentation-as-code/structurizr-LiveDeployment.png" title="To learn how this diagram was created, continue reading 👇" caption="Deployment View" pos="left" >}}


## C4 Model {#c4-model}

The C4 model was developed by [Simon Brown](https://simonbrown.je/) as a means of providing a **visual map** of system components across **four levels
of abstraction**, as suggested by its title. Each level of abstraction in the C4 model suits different **audiences**, from the
non-technical management level to detailed developer perspectives, each level of abstraction is tailored to meet its
observer's understanding. To maintain consistency when describing the system design, the C4 model uniformly applies the same terminology and abstractions across all its levels, effectively implementing ubiquitous language principles from Domain-Driven Design ([DDD](https://brainfck.org/t/ddd)).

{{< gbox src="/posts/img/2023/documentation-as-code/c4-summary.png" title="The 4 perspectives in the C4 model" caption="The 4 perspectives in the C4 model" pos="left" >}}


### Abstractions {#abstractions}

The C4 model uses [abstractions](https://c4model.com/#Abstractions) to form an hierarchy of well-defined diagrams (at different levels). Currently these
abstractions are available:

1.  **Person**
    -   Represents human users interacting with the system (e.g., Administrator, End User, Customer).

2.  **System**
    -   A top-level view showing different people interacting with different software systems. (e.g., E-commerce Platform,
        Payment Gateway, our self-destructing email service 😎).

3.  **Container**
    -   Involves zooming into an individual system to reveal containers within. Examples include server-side applications, client-side applications, databases, etc.
    -   not to be confused with Docker containers

4.  **Component**
    -   Dives deeper into an individual container to expose its components, like classes, interfaces or objects in your code.


### Diagram types {#diagram-types}


#### Level 1: Context diagram {#level-1-context-diagram}

Shows how your system fits into the larger system environment ([system landscape](#system-landscape)). It basically shows **interactions**
between users and systems:

-   e.g. A payment system interacting with an user and a banking system

{{< gbox src="/posts/img/2023/documentation-as-code/c4-context-diagram.png" title="Context diagram" caption="Context diagram" pos="left" >}}


#### Level 2: Container diagram {#level-2-container-diagram}

Higher level view within a system itself. Shows software "[containers](#containers)" like web servers,
standalone apps, or databases. (e.g., An API server, a database, and a client app in a
single system)

{{< gbox src="/posts/img/2023/documentation-as-code/c4-container-diagram.png" title="Container diagram" caption="Container diagram" pos="left" >}}


#### Level 3: Component diagram {#level-3-component-diagram}

Shows internal parts of a container. Mostly used with complex software. (e.g.,
Controllers, services, repositories inside of a web application)

{{< gbox src="/posts/img/2023/documentation-as-code/c4-component-diagram.png" title="Component diagram" caption="Component diagram" pos="left" >}}


#### Level 4: Code diagram {#level-4-code-diagram}

A detailed view of the code level. For systems with little internal complexity, it can be
skipped. (e.g., UML class diagrams)

{{< gbox src="/posts/img/2023/documentation-as-code/c4-code-diagram.png" title="Code diagram" caption="Code diagram" pos="left" >}}


## Structurizr DSL {#structurizr-dsl}

[Structurizr](https://structurizr.com/) is used for _describing_ and _visualizing_ architecture using the C4 model. One of the main selling points is
the fact you can define an entire (IT) architecture model using _text_. A typical model consists of:

-   relationships between abstractions
-   different **views**

Let's have a look at a simple example:

```structurizr
workspace {

    model {
        user = person "User"

        webApp = softwareSystem "Web Application" {
            tags "System"
        }

        database = softwareSystem "Database" {
            tags "Database"
        }

        team = person "Development Team"

        user -> webApp "Uses"
    }

    views {
        container webApp {
            include *
            autoLayout
        }

        styles {
            element "Database" {
                color "#0000ff"
            }
        }
    }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Structurizr DSL: Basic structure
</div>

What do we have?

-   ****Entities****:
    -   "User": a person who uses the "Web Application".
    -   "Web Application": a software system tagged as "System".
    -   "Database": another software system tagged as "Database".
    -   "Development Team": a person representing the team that develops the "Web Application".
-   ****Relationships****:
    -   The "User" uses the "Web Application".
-   ****Container View****:
    -   Focused on "Web Application".
    -   Includes all elements in the model.
    -   Uses automatic layout.
-   ****Styles****:
    -   The "Database" elements are colored in blue ("#0000ff").

Before we move on, let's briefly discuss the installation steps.


### Installation {#installation}

I'd suggest you use the [Docker image](https://hub.docker.com/r/structurizr/lite) for a safe playground:

```shell
docker run -it --rm -p 1337:8080 -v ./:/usr/local/structurizr structurizr/lite
```

This will fetch the `structurizr/lite` Docker image from [Dockerhub](https://hub.docker.com/r/structurizr/lite), start the container, mount the current working
directory to `/usr/local/structurizr` and setup a port forwarding from `localhost:1337` to `<docker container>:8000`.

{{< notice info >}}

👉 I've setup a github repository with the code I'll be using in the next sections. Feel free to clone from
<https://github.com/dorneanu/ripmail>.

{{< /notice >}}


### Short recap {#short-recap}

If you recall my [initial post](/2023/07/18/documentation-as-code-for-cloud/) the entire aim was to document a hypothetical self-destructing e-mail service.
In my [2nd blog post](/2023/07/30/documentation-as-code-for-cloud-plantuml/#sequence-diagrams) (about PlantUML) I've generated following _sequence diagram_:

{{< gbox src="/posts/img/2023/documentation-as-code/plantuml-seq-send-aws-logging.png" title="" caption="" pos="left" >}}

<center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-seq-send-aws-logging.puml">Full PlantUML Code</a></center>

In the following I'll try to implement exactly this workflow using C4 and Structurizr DSL.


## ripmail {#ripmail}

👉 Checkout the code at <https://github.com/dorneanu/ripmail>.


### Model {#model}

Let's start with the basic construct:

```nil
workspace {  ❶
  name "Self-Destructing Email Service"
  description "The sofware architecture of the self-destructing email service"

  model {    ❷
    //  ...
  }

  views {    ➌
    // System Landscape
 ❺ systemlandscape "SystemLandscape" {
      include *
      # autoLayout
    }

    // Themes
    // You can combine multiple themes!
 ❻ theme https://static.structurizr.com/themes/amazon-web-services-2023.01.31/theme.json

    styles { ❹
      element "Person" {
        color #ffffff
        fontSize 22
        shape Person
      }
      element "Sender" {
        color #ffffff
        background #8FB5FE
        shape Person
      }
      element "Recipient" {
        color #ffffff
        background #E97451
        shape Person
      }
    }
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  Basic Structurizr construct
</div>

So, what do we have?

-   ❶ `workspace`
    -   Defines the workspace for a self-destructing email service.
-   ❷ `model`
    -   This has to be implemented but basically it's a
    -   Placeholder section where you'd define the elements (software systems, people, containers) and their relations.
-   ➌ `views`
    -   A **[System Landscape view](#system-landscape)** ❺ that includes all elements defined in the model.
    -   The [specified theme](https://www.structurizr.com/help/themes) ❻ comes from an external JSON file, allowing broad customization of the look-and-feel.
    -   Three styles are defined for different types of elements labeled as _Person_, _Sender_, and _Recipient_. These
        characters are all represented by the _Person_ shape.

Let's focus more on the `model`:

```nil

...

  model {
 ❶ sender = person "Sender" "Sender creates self-destructing email" {
      tags "Sender"
    }
 ❷ recipient = person "Recipient" "Recipient receives self-destructing email" {
      tags "Recipient"
    }

 ➌ group "Self-Destructing Email Service" {
      // Logging keeps track of several events
 ❹   logging = softwaresystem "Logging System" "Logs several events related to mail generation" {
        tags "Service API"
      }
 ❺   storage = softwaresystem "Storage System" "Stores encrypted mail content" {
        tags "Database"
        storageBackend = container "Storage Backend"
      }

 ❻   notification = softwaresystem "Notification System" "Sends notification to recipient to view email" {
        tags "System"

        // --- Notification Service
        notificationService = group "Notification Service" {
          notificationAPI = container "Notification API" {
            tags "NotificationService" "Service API"
          }
        }
      }

   ...

```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3:</span>
  Adding actors and different systems
</div>

We have following **elements** and **groups**:

-   ❶ _Sender_: Person who creates the self-destructing email.
-   ❷ _Recipient_: Person who receives the self-destructing email.
-   ➌ _Self-Destructing Email Service_: Represents the overall service/system being described.

Additionally we have these **systems** inside the group:

-   ❹ _Logging System_: Keeps track of events related to mail creation.
-   ❺ _Storage System_: Stored encrypted email content. Includes a _Storage Backend_ container.
-   ❻ _Notification System_: Sends notification to recipient. Contains a [Notification Service](#notification-service) group with a _Notification
    API_ container.


#### Main backend system {#main-backend-system}

Now the **backend system** responsible for the business logic:

```nil
...

      // Backend system responsible for the business logic
❶    backend = softwaresystem "Backend System" "Contains logic how self-destructing mails should be created and dispatched to the recipient." {
        tags "BackendSystem"
❷       webapplication = container "Web Application"

        // Services/
        // --- Authentication Service
➌      authService = group "Authentication Service" {
❹        authAPI = container "Auth Service API" {
            tags "AuthService" "Service API"
          }
❺        authDB = container "Auth Service Database" {
            tags "AuthService" "Database"
❻          authAPI -> this "Checks if credentials match"
          }
        }


        // --- Email Composition Service
❼      mailCompositionService = group "Email Composition Service" {
❽        mailCompositionAPI = container "Email Composition API" {
            tags "EmailCompositionService" "Service API"
          }
❾        mailDB = container "Email Composition Database" {
            tags "Emailcompositionservice" "Database"
❿          mailCompositionAPI -> this "Stores metadata of mails"
          }

        }

        // --- Email Composition Service
⓫      viewEmailService = group "View Email Service" {
⓬          viewEmailFrontend = container "Email View Frontend" {
            tags "ViewEmailService"
          }
        }

...
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4:</span>
  Main backend system and ther underlying services
</div>

The _Backend System_ is the core system, with business logic, for creating/dispatching self-destructing mails.
of following **containers** and **services**:

-   ❷ _Web Application_: The **frontend** component within the backend system for _creating_ mails.
-   ➌ _Authentication Service_: Group handling user credential verification.
    -   ❹ _Auth Service API_: Provides interface for authentication service.
    -   ❺ _Auth Service Database_: Stores user credential data.
    -   ❻ _Auth Service API-&gt;Auth Service Database_: Indicates API checks credentials against this database.
-   ❼ _Email Composition Service_: Group handling creation/storage of emails.
    -   ❽ _Email Composition API_: Interface for the email composition service.
    -   ❾ _Email Composition Database_: Stores meta-information of emails.
    -   ❿ _Email Composition API -&gt; Email Composition Database_: Indicates API stores mail metadata in this database.
-   ⓫ _View Email Service_: Group handling email display.
    -   ⓬ _Email View Frontend_: The **frontend** component withing the backend system for _viewing_ emails.


#### Relationships {#relationships}

And finally the **relationships** between different components:

```nil
...
        // Store mail data and encrypted content
        mailCompositionAPI -> storage "Store mail metadata and content"

        // Notify recipient
        mailCompositionAPI -> notificationAPI "Notify recipient"
        notificationAPI -> mailcompositionAPI "Recipient notified"

        // Log events
        notificationAPI -> logging "Log Email sent event"

        // Sender creates new email
        sender -> webapplication "Create new mail"
        webapplication -> authAPI "Authenticate user"
        webapplication -> mailCompositionAPI "Create mails"
        notification -> recipient "Send out notification"
        backend -> logging "Create events"

        // Recipient receives new mail
        recipient -> webapplication "View self-destructing mail"
        webapplication -> viewEmailFrontend "View email"
        viewEmailFrontend -> mailDB
        viewEmailFrontend -> storage
...
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5:</span>
  Relationships between different components
</div>

| From                 | To                   | Description                               |
|----------------------|----------------------|-------------------------------------------|
| Mail Composition API | Storage              | Store mail metadata and encrypted content |
| Mail Composition API | Notification API     | Notify recipient                          |
| Notification API     | Mail Composition API | Recipient notified                        |
| Notification API     | Logging              | Log Email sent event                      |
| Sender               | Web Application      | Create new mail                           |
| Web Application      | Auth API             | Authenticate user                         |
| Web Application      | Mail Composition API | Create mails                              |
| Notification         | Recipient            | Send out notification                     |
| Backend System       | Logging              | Create events                             |
| Recipient            | Web Application      | View self-destructing mail                |
| Web Application      | View Email Frontend  | View email                                |
| View Email Frontend  | MailDB               | Fetches email data for visualization      |
| View Email Frontend  | Storage              | Fetches email details for visualization   |


#### Deployments {#deployments}

Deployment components are required for the [deployment diagrams](#deployment-live). These illustrate how software systems are deployed onto
infrastructure elements in an environment. They also enable you to visualize how containers within a system map onto the infrastructure.

This kind of diagrams are very important as they provide important information regarding system runtime environment such
as scaling, redundancy, network topology, and communication protocols. They are crucial to understanding the physical
aspects and deployment context of a system.

```structurizr
workspace {

  model {
  //  ...
  live = deploymentEnvironment "Live" { ❶
    // AWS
    deploymentNode "Amazon Web Services" { ❷
        tags "Amazon Web Services - Cloud"

          // Which region
    ➌     deploymentNode "eu-central-1" {
            tags "Amazon Web Services - Region"
            ...
          }
    }
  }
  }

  views {
  // ...
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 6:</span>
  The live deployment environment
</div>

We're still defining the `model`. Now we have defined a `deploymentEnvironment` _live_ ❶ which should be deployed into the AWS
Cloud ❷, namely in `eu-central-1` ➌. In this region we'll have different _organizational units_ (OUs):

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

<!--listend-->

```nil
...

       // Which region
       deploymentNode "eu-central-1" {
         tags "Amazon Web Services - Region"

         // ------------------------------------------------
         // Organizational Unit: DevOps
         // ------------------------------------------------
         deploymentNode "OU-DevOps" {...}

         // ------------------------------------------------
         // Organizational Unit: Tech
         // ------------------------------------------------
         ou_tech = deploymentNode "OU-Tech" {...}


         // ------------------------------------------------
         // Organizational Unit: Security
         // ------------------------------------------------
         deploymentNode "OU-Security" {...}
       }

...
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 7:</span>
  Outline main organizational units (OUs)
</div>

<!--list-separator-->

-  OU: DevOps

    But one thing at a time:

    ```nil
          // --------------------------------------------
          // Organizational Unit: DevOps
          // --------------------------------------------
          deploymentNode "OU-DevOps" {
    ❶      tags "Amazon Web Services - AWS Organizations Organizational Unit"

    ❷        deploymentNode "acc-devops-prod" {
    ➌          tags "Amazon Web Services - AWS Organizations Account"

    ❹          vpc_management = deploymentNode "VPC (management)" {
    ❺            tags "Amazon Web Services - VPC Virtual private cloud VPC"

    ❻            gitlab_server = infrastructureNode "Gitlab Server" {
    ❼              tags "Amazon Web Services - EC2"
                }

              }
            }
          }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 8:</span>
      Deployment components for the OU DevOps
    </div>

    The DevOps OU deployment components are:

    -   Organizational Unit (**OU-DevOps**): Represents a unit in the organization.
        -   ❶ Tagged as an Amazon Web Services (AWS) Organizations Organizational Unit.
    -   ❷ _acc-devops-prod_: Represents an account within the **OU-DevOps** unit.
        -   ➌ Tagged as an AWS Organizations Account.
    -   ❹ VPC (_vpc_management_): A Virtual Private Cloud (VPC) within the _acc-devops-prod_ account.
        -   ❺ Tagged as an AWS VPC Virtual private cloud VPC.
    -   ❻ Gitlab Server (_gitlab_server_): Infrastructure node within the VPC.
        -   ❼ Tagged as AWS EC2.

<!--list-separator-->

-  OU: Security

    ```nil
         // ---------------------------------------------
         // Organizational Unit: Security
         // ---------------------------------------------
    ❶    deploymentNode "OU-Security" {
    ❷      tags "Amazon Web Services - AWS Organizations Organizational Unit"

    ➌      deploymentNode "acc-security-logging" {
    ❹        tags "Amazon Web Services - AWS Organizations Account"

    ❺        s3_logging = infrastructureNode "S3 Bucket" {
    ❻          tags "Amazon Web Services - Simple Storage Service"
             }

    ❼        infrastructureNode "CloudWatch Logs" {
    ❽          tags "Amazon Web Services - CloudWatch Logs"
             }
           }

    ❾      deploymentNode "acc-security-monitoring" {
    ❿        tags "Amazon Web Services - AWS Organizations Account"

    ⓫        infrastructureNode "CloudWatch" {
    ⓬          tags "Amazon Web Services - CloudWatch Alarm"
             }
           }
         }

    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 9:</span>
      Deployment components for the OU Security
    </div>

    The Security OU deployment components are:

    -   Organizational Unit (**OU-Security**): Represents a security unit in the organization.
        -   ❶ Tagged as an AWS Organizations Organizational Unit.
    -   ➌ _acc-security-logging_: Represents an account within the **OU-Security** unit for logging purposes.
        -   ❹ Tagged as an AWS Organizations Account.
        -   ❺ Contains an "S3 Bucket" infrastructure node.
            -   ❻ Tagged as AWS Simple Storage Service.
        -   ❼ Contains a "CloudWatch Logs" infrastructure node.
            -   ❽ Tagged as AWS CloudWatch Logs.
    -   ❾ _acc-security-monitoring_: Represents another account within the **OU-Security** unit for monitoring purposes.
        -   ❿ Tagged as an AWS Organizations Account.
        -   ⓫ Contains a "CloudWatch" infrastructure node.
            -   ⓬ Tagged as AWS CloudWatch Alarm.

<!--list-separator-->

-  OU: TECH

    Now the most complicated one:

    ```nil
         // --------------------------------------------
         // Organizational Unit: Tech
         // --------------------------------------------
    ❶    ou_tech = deploymentNode "OU-Tech" {
           tags "Amazon Web Services - AWS Organizations Organizational Unit"

    ❷      deploymentNode "acc-tech-prod" {
             tags "Amazon Web Services - AWS Organizations Account"

             // EKS control plane
    ➌        eks_vpc = deploymentNode "EKS VPC" {
               tags = "Amazon Web Services - VPC Virtual private cloud VPC"

    ❹          eks_control_plane = infrastructureNode "EKS Control Plane" {
                 tags = "Amazon Web Services - EKS Cloud"
               }
             }

             // ECR
    ❺        ecr = infrastructureNode "ECR" {
               tags "Amazon Web Services - Elastic Container Registry"
               description "Private ECR registry"
             }

             // EKS cluster
    ❻        workload_vpc = deploymentNode "Workload VPC" {...}



             // DynamoDB instances
    ❼        dbs = group "Databases" {...}

             // S3 (Storage System)
    ❽        s3_storage = infrastructureNode "S3 Bucket (storage)" {
               tags "Amazon Web Services - Simple Storage Service"
             }

           }
         }

    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 10:</span>
      Deployment components for the OU Tech
    </div>

    This will result in following components hierarchy:

    -   ❶ Organizational Unit (OU-Tech): Represents a technology unit within the organization.
    -   ❷ _acc-tech-prod_: Represents a production account within the "**OU-Tech**" unit.
        -   **EKS control plane** deployed within an EKS VPC.
            -   ➌ _EKS VPC_: VPC where the EKS control plane is deployed,
            -   ❹ _EKS Control Plane_: infrastructure node within EKS VPC.
        -   ❺ _ECR_: Infrastructure node for the Elastic Container Registry with private ECR registry.
        -   ❻ _Workload VPC_: Deployment node holding different workloads.
        -   ❼ Databases group holds _DynamoDB_ instances.
        -   ❽ _S3 Bucket (storage)_: Infrastructure node for the storage system.

    Let's have a look what's inside the _workload VPC_:

    ```nil
      // EKS cluster
      workload_vpc = deploymentNode "Workload VPC" {
        tags = "Amazon Web Services - VPC Virtual private cloud VPC"

        // AZ 1
    ❶   deploymentNode "Availability Zone 1" {
          tags = "Amazon Web Services - Region"

    ❷     deploymentNode "Subnet 1" {
            tags = "Amazon Web Services - VPC VPN Gateway"

    ➌       eks_node_group1 = deploymentNode "EKS Managed Node Group" {
              tags = "Amazon Web Services - EKS Cloud"

    ❹         eks_node_group1_pod1 = deploymentNode "Pod 1" {
                tags = "Kubernetes - pod"
    ❺           pod1_authAPI = containerInstance authAPI
              }

    ❻         eks_node_group1_pod2 = deploymentNode "Pod 2" {
                tags = "Kubernetes - pod"
    ❼           pod2_mailCompositionAPI = containerInstance mailcompositionAPI
    ❽           pod2_notificationAPI = containerInstance notificationAPI

              }

            }
          }

        }

        // AZ 2
    ❾   deploymentNode "Availability Zone 2" {
          tags = "Amazon Web Services - Region"

    ❿     deploymentNode "Subnet 1" {
            tags = "Amazon Web Services - VPC VPN Gateway"

    ⓫       eks_node_group2 = infrastructureNode "EKS Managed Node Group" {
              tags = "Amazon Web Services - EKS Cloud"
            }

          }
        }
      }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 11:</span>
      Components of the workload VPC
    </div>

    The workload VPC consists of 2 availability zones:

    -   ❶ **Availability Zone 1**: A separate deployment node categorized as an AWS Region.
        -   ❷ _Subnet 1_: Deployment node within Availability Zone 1.
        -   ➌ _EKS Managed Node Group_: Node group for managing EKS resources.
        -   ❹ _Pod 1_: Deployment node within the _EKS Managed Node Group_.
            -   ❺ Houses instance of _authAPI_ container.
        -   ❻ _Pod 2_: Another deployment node within the _EKS Managed Node Group_.
            -   ❼ Houses instance of _mailcompositionAPI_ container.
            -   ❽ Houses instance of _notificationAPI_ container.
    -   ❾ _Availability Zone 2_: Another separate deployment node categorized as an AWS Region.
        -   ❿ _Subnet 1_: Deployment node within Availability Zone 2.
        -   ⓫ _EKS Managed Node Group_: Infrastructure node for managing EKS resources.

    Let's also have a look how we can use `containerInstance` for the databases:

    ```nil
    	 // DynamoDB instances
    ❶	 dbs = group "Databases" {
    	   deploymentNode "DB VPC" {
    		 tags = "Amazon Web Services - VPC Virtual private cloud VPC"

    ❷		 deploymentNode "DynamoDB (Auth)" {
    		   tags "Amazon Web Services - DynamoDB"

    ➌		   liveUserDB = containerInstance authDB
    		 }

    ❹		 deploymentNode "DynamoDB (Mails)" {
    		   tags "Amazon Web Services - DynamoDB"

    ❺		   liveMailDB = containerInstance mailDB
    		 }
    	   }
    	 }

    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 12:</span>
      Components of the DB VPC
    </div>

    This will create:

    -   ❶ _Databases_: A group of databases within a DB VPC deployment node.
    -   ❷ _DynamoDB (Auth)_: DynamoDB instance for authentication.
        -   ➌ Contains a live instance of _authDB_.
    -   ❹ _DynamoDB (Mails)_: DynamoDB instance for mail metadata.
        -   ❺ Contains a live instance of _mailDB_.


### Views {#views}

Views in Structurizr are used to create **visual** diagrams of your software architecture model. They provide a way to
communicate the different aspects of your system to **various stakeholders**. Views can be thought of as 'camera angles' on
your architecture model, each designed to present a certain perspective of the system.


#### System Landscape {#system-landscape}

The _System Landscape_ view in Structurizr is the **highest** level view of a software system's architecture. It shows all
users, software systems and external systems or services in scope. It informs about the overall system context and
interaction among systems and users.

```nil
    // System Landscape
    systemlandscape "SystemLandscape" {
      include *
    }
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 13:</span>
  The System Landscape where every component (*) is included in the diagram
</div>

{{< gbox src="/posts/img/2023/documentation-as-code/structurizr-SystemLandscape.png" title="System Landscape" caption="System Landscape" pos="left" >}}


#### Deployment Live {#deployment-live}

The **Deployment View** in Structurizr is a type of view that visualizes the **mapping of software building blocks** (like
Containers or Components) to **infrastructure elements**, including servers, containers or cloud services. It gives a clear
indication of how and where the software system runs in different environments (like development, staging, production).

```nil
    // Deployment live
    deployment backend live "LiveDeployment"  {
      include *
      description "An example live deployment for the self-destructing email service"
    }

```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 14:</span>
  The deployment view for live
</div>

{{< gbox src="/posts/img/2023/documentation-as-code/structurizr-LiveDeployment.png" title="Deployment View" caption="Deployment View" pos="left" >}}


#### Containers {#containers}

In Structurizr, a _Container_ represents an **executable unit** (application, data store, microservice, etc.) that
encapsulates a portion of your software system. Containers run inside software systems and have interfaces that let them
interact with other containers and/or software systems. The Container view shows the internal layout of a software
system, specifying contained components and their interactions. This level of abstraction is valuable for developers and
others dealing with system implementation and operation.

```nil
    // Backend
    container backend "Containers_All" {
      include *
      # autolayout
    }
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 15:</span>
  The container view for all resources
</div>

{{< gbox src="/posts/img/2023/documentation-as-code/structurizr-Containers_All.png" title="Containers (global)" caption="Containers (global)" pos="left" >}}

And now for specific services:

<!--list-separator-->

-  Notification Service

    ```nil
        container backend "Containers_NotificationService" {
          include ->notificationService->
          autolayout
        }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 16:</span>
      Container view for the notification service
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/structurizr-Containers_NotificationService.png" title="Container view for the notification service" caption="Container view for the Notification Service" pos="left" >}}

<!--list-separator-->

-  Mail Composition Service

    ```nil
        container backend "Containers_MailCompositionService" {
          include ->mailCompositionService->
          autolayout
        }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 17:</span>
      Container view for the email composition service
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/structurizr-Containers_MailCompositionService.png" title="Container view for the Mail Composition Service" caption="Container view for the Mail Composition Service" pos="left" >}}

<!--list-separator-->

-  Authentication Service

    ```nil
        container backend "Containers_AuthenticationService" {
          include ->authService->
          autolayout
        }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 18:</span>
      Container view for the authentication service
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/structurizr-Containers_AuthenticationService.png" title="Container view for the Authentication Service" caption="Container view for the Authentication Service" pos="left" >}}


## Extra features {#extra-features}

With the [online version of Structurizr](https://www.structurizr.com/dsl) you get access to diffeerent exporting features:

-   **PlantUML**: Export your model as PlantUML diagrams.
-   **C4-PlantUML**: Export your model as [C4-PlantUML diagrams](https://github.com/plantuml-stdlib/C4-PlantUML).
-   **Mermaid**: Generate Mermaid diagrams from your model.
-   **DOT**: Export containers and components as DOT graph description language.
-   **ilograph**: Export the model and the views for [ilograph.com](https://www.ilograph.com/)

Among these I've found **ilograph** to be the most interactive one.


### Ilograph {#ilograph}

Once you've exported your _workspace_ in ilograph format, follow these steps:

-   [Create a new ilograph diagram](https://app.ilograph.com/?createNew=1)
-   Paste in the exported ilograph code

And this is what you get:

{{< gbox src="/posts/img/2023/documentation-as-code/c4-ilograph.png" title="ilograph with code" caption="ilograph with code" pos="left" >}}

{{< gbox src="/posts/img/2023/documentation-as-code/c4-ilograph.png" title="ilograph without code" caption="ilograph without code" pos="left" >}}

-   👉 Here's the [ilograph code](https://github.com/dorneanu/ripmail/tree/main/docs/ilograph).
-   👉 Check out [other architecture diagrams](https://www.ilograph.com/architecture-center/index.html) made with ilograph.


## Resources {#resources}

The resources I've consumed for generating the content and diagrams for this blog post:

**Tools**:

-   2023-10-05 ◦ [IcePanel.io](https://icepanel.io/blog/2022-10-03-c4-model-for-system-architecture-design?utm_source=dev_to&utm_medium=post&utm_campaign=should_you_use_c4)

    A _visual_ modelling tool for C4
-   2023-10-05 ◦ [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML)

    > C4-PlantUML combines the benefits of PlantUML and the C4 model for providing a simple way of describing and communicate software architectures

**Articles**:

-   2023-10-08 ◦ [Software Diagrams - C4 Models with Structurizr](https://www.dandoescode.com/blog/c4-models-with-structurizr)
-   2023-07-10 ◦ [Structurizr - Practicalli Engineering Playbook](https://practical.li/engineering-playbook/architecture/structurizr/)
-   2022-10-31 ◦ [C4 model for system architecture design](https://dev.to/icepanel/c4-model-for-system-architecture-design-16dh)
-   2022-10-10 ◦ [C4 Models: Architecture From Simple To Complex](https://dev.to/indrive_tech/c4-models-architecture-from-simple-to-complex-38fk)

**Structurizr**:

-   2023-10-07 ◦ [Structurizr - Help - Themes](https://www.structurizr.com/help/themes)

**Videos**:

-   2023-07-10 ◦ [C4 Models as Code • Simon Brown • YOW! 2022 - YouTube](https://www.youtube.com/watch?v=f7i2wxQVffk&list=PLEx5khR4g7PLf2kQn3nYaZJC2Zv2GPbnY&ab_channel=GOTOConferences)


## Outlook {#outlook}

In the next post I'll deep-dive into the [D2](https://d2lang.com/) language which also has a huge set of features. Stay tuned.
