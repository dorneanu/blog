+++
title = "Documentation as Code for Cloud - PlantUML"
author = ["Victor Dorneanu"]
lastmod = 2023-07-30T21:27:03+02:00
tags = ["documentation", "architecture", "plantuml", "aws"]
draft = false
series = ["Documentation as Code for Cloud"]
+++

## Basics {#basics}

I've become a huge fan of [PlantUML](https://plantuml.com/) even before I came across the concept of
"**documentation as code**"
{{% sidenote %}}
I also code for presentations. So the term [presentation as code](https://slides.dornea.nu/2022/presentation-as-code) is also a thing.
{{% /sidenote %}} and it instantly won me over with its capabilities. I have used it in many
different roles (software engineer, security engineer, security architect)
extensively to draw diagrams ([components](https://plantuml.com/component-diagram), [sequences](https://plantuml.com/sequence-diagram)) and [mind maps](https://plantuml.com/mindmap-diagram).

Though initially, the general syntax might seem a bit challenging to understand,
I believe that with some dedication, the learning curve becomes quite
manageable. The reward of mastering PlantUML is well worth the effort, as it
empowers you to create _visually engaging_ and _informative diagrams_ seamlessly.

One aspect where PlantUML might fall short is its default styling, which may not
be as visually impressive as some other tools. However, this drawback can easily
be overcome by incorporating icons and leveraging different themes to _breathe
life_ into your diagrams.
{{% sidenote %}}
For really cool diagrams you might want to have a look at [PlantUML Hitchhikers Guide](https://crashedmind.github.io/PlantUMLHitchhikersGuide/).
{{% /sidenote %}} By doing so, you can elevate the aesthetic appeal and
overall quality of your visual representations significantly by using standard
icons (included withing the [standard library](https://plantuml.com/stdlib)) and 3rd-party ones .

Let's have a look how how a typical PlantUML document could look like:

```nil
<<styling options>> ❶

<<import of additional resources/modules>>  ❷
<<import of 3rd-party resources>>  ➌

<<resources>>  ❹
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  General structure of the PlantUML document
</div>

At the top of the document ❶ you define the basic layout of the resulting
drawing (landscape mode, font size, font family, default direction in which
resources should be created, etc.). Then you start adding different modules ❷
and ➌ which provide different entities and icons based on your needs. Finally
you use your resources/entities, arrange them correspondingly and make
relationships between them ❹.

This is what I'll use for the examples within this blog post:

{{< notice info >}}

In this example I've cloned [aws-icons-for-plantuml](https://github.com/awslabs/aws-icons-for-plantuml) locally. That's why I've used
`/home/victor/work/repos/aws-icons-for-plantuml/dist` as the location of the AWS
icon distribution. But you can still use an external URL such as
<https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v16.0/dist>.

{{< /notice >}}

<a id="org-example-block--plantuml-includes"></a>
```text
' !define AWSPuml https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v16.0/dist
!define AWSPuml /home/victor/work/repos/aws-icons-for-plantuml/dist
!include AWSPuml/AWSCommon.puml
!include AWSPuml/AWSSimplified.puml
!include AWSPuml/ApplicationIntegration/APIGateway.puml
!include AWSPuml/ApplicationIntegration/SimpleNotificationService.puml
!include AWSPuml/ManagementGovernance/CloudWatch.puml
!include AWSPuml/Compute/EC2.puml
!include AWSPuml/Compute/EC2Instance.puml
!include AWSPuml/Compute/LambdaLambdaFunction.puml
!include AWSPuml/Groups/all.puml
!include AWSPuml/Containers/EKSCloud.puml
!include AWSPuml/Containers/ElasticKubernetesService.puml
!include AWSPuml/Containers/Containers.puml
!include AWSPuml/NetworkingContentDelivery/VPCNATGateway.puml
!include AWSPuml/NetworkingContentDelivery/VPCInternetGateway.puml
!include AWSPuml/NetworkingContentDelivery/VPCEndpoints.puml
!include AWSPuml/Storage/SimpleStorageService.puml
!include AWSPuml/SecurityIdentityCompliance/IAMIdentityCenter.puml

hide stereotype
skinparam linetype ortho
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#org-example-block--plantuml-includes">Code Snippet 1</a>:</span>
  Styling option and includes for plantuml (basically the <b>epilogue</b> for everything else used in this post)
</div>

PlantUML is a powerful tool that goes beyond just creating basic diagrams; it
also supports various types of grouped areas. These groupings play a crucial
role in emphasizing the logical connections between different components or
resources that belong to the same category, making it easier to understand
complex systems.

When working with PlantUML, you have the flexibility to employ different types
of groups to organize your diagrams effectively. Some of these groups include:

<a id="table--aws-icons-plantuml-groups"></a>
<div class="table-caption">
  <span class="table-number"><a href="#table--aws-icons-plantuml-groups">Table 1</a>:</span>
  List of available groups within aws-icons-plantuml
</div>

| Group name                     | Description                                                                                          |
|--------------------------------|------------------------------------------------------------------------------------------------------|
| GenericGroup                   | If the predefined groups don't suit your needs, you can use this group type for custom arrangements. |
| GenericAltGroup                | Similar to the generic group, this one allows for alternative custom groupings.                      |
| AWSCloudAltGroup               | This group allows you to represent alternative cloud arrangements in your AWS diagrams.              |
| VPCGroup                       | It lets you create a clear representation of components within an AWS Virtual Private Cloud.         |
| RegionGroup                    | It enables you to logically group components based on AWS regions.                                   |
| AvailabilityZoneGroup          | With this group, you can highlight components grouped by availability zones in AWS.                  |
| SecurityGroupGroup             | Use this group to demonstrate the logical connections between security groups in AWS.                |
| AutoScalingGroupGroup          | This group is perfect for showcasing auto-scaling groups and their relationships.                    |
| PrivateSubnetGroup             | This group emphasizes components that are part of private subnets in AWS.                            |
| PublicSubnetGroup              | Similar to the previous one, but for components in public subnets in AWS.                            |
| ServerContentsGroup            | Use this group to illustrate the contents of a server or its internal                                |
| CorporateDataCenterGroup       | It helps you highlight components within a corporate data center.                                    |
| EC2InstanceContentsGroup       | Use this group to show the internal structure or contents of an EC2 instance.                        |
| SpotFleetGroup                 | This group allows you to group instances in AWS Spot Fleet.                                          |
| AWSAccountGroup                | With this group, you can demonstrate various components within an AWS account.                       |
| IoTGreengrassDeploymentGroup   | Use this group to illustrate deployments in AWS IoT Greengrass.                                      |
| IoTGreengrassGroup             | This group lets you represent components within AWS IoT Greengrass.                                  |
| ElasticBeanstalkContainerGroup | Use this group to showcase container-related elements in AWS Elastic Beanstalk.                      |
| StepFunctionsWorkflowGroup     | This group is perfect for visually representing AWS Step Functions workflows.                        |


### Groups {#groups}

Let's have a look at the most common groups:

-   Generic group

    The most useful group (without any icons) is the **generic group**:
    ```plantuml
      GenericGroup(generic_group, "Generic Group") {
        package "Some Group" {
          HTTP - [First Component]
          [Another Component]
        }

        node "Other Groups" {
          FTP - [Second Component]
          [First Component] --> FTP
        }
      }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 2:</span>
      Using generic group
    </div>

{{< gbox src="/posts/img/2023/documentation-as-code/plantuml-group-generic.png" title="" caption="" pos="left" >}}

<center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-group-generic.puml">Full PlantUML Code</a></center>

-   Generic alt group

    If you want to use another layout (without dotted lines) you could go for **generic alt group**:
    ```plantuml
      GenericAltGroup(generic_alt_group, "Generic Alt Group") {
        node node1
        node node2
        node node3
        node node4
        node node5
        node1 -- node2 : label1
        node1 .. node3 : label2
        node1 ~~ node4 : label3
        node1 == node5
      }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 3:</span>
      Using generic alt group
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/plantuml-group-generic-alt.png" title="" caption="" pos="left" >}}

    <center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-group-generic-alt.puml">Full PlantUML Code</a></center>

<!--listend-->

-   AWS Cloud Group

    The **AWSCloudGroup** along with **AWSAccountGroup** provides a more AWS-like grouping of resources.
    Here is one example using VPCs and private subnets:
    ```plantuml
      AWSCloudGroup(aws_cloud, "AWS Cloud Group") {
        AWSAccountGroup(aws_acc_group, "AWS Account Group") {
          VPCGroup(vpc_group, "VPC Group") {
            PrivateSubnetGroup(priv_subnet1, "Private Subnet Group") {
              [component] as C1
            }
            PrivateSubnetGroup(priv_subnet2, "Private Subnet Group") {
              [component] as C2
            }
          }
        }
      }
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 4:</span>
      Using AWS cloud group
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/plantuml-group-awscloud.png" title="" caption="" pos="left" >}}

    <center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-group-awscloud.puml">Full PlantUML Code</a></center>


## AWS Architecture {#aws-architecture}

On our journey of designing the AWS architecture for our innovative
self-destroying email service, we should begin with a **high-level overview** to lay
down the foundation. With PlantUML at our disposal, it's a wise approach to
start by sketching the fundamental **high-level concepts**
{{% sidenote %}}
You may also check the first post for some diagrams using pen &amp; paper.
{{% /sidenote %}} before going to deep into details.

By starting with the _organizational units_ and gradually adding layers of
complexity, we can systematically build upon the architecture, ensuring a
coherent and comprehensive representation of the entire system. This
step-by-step approach allows us to understand each component's role and
_relationships_ before moving forward.

In this initial phase, we'll focus on capturing the **essence of the architecture**,
identifying the **main components** and their relationships. As we move on, we can
gradually introduce additional elements/components to achieve a holistic and
detailed representation of the mail service.

Remember, a well-structured high-level design serves as a **roadmap**, guiding us
through the design process and identifying potential challenges or areas that
require further refinement. With PlantUML as our visual design tool, we can
easily iterate and modify the architecture as needed, ensuring that our
self-destroying email service is built on a solid and scalable foundation. So,
let's start with the **big picture** and refine it step by step to create an AWS
architecture that meets our requirements.


### Account level {#account-level}

On the organizational level, we have three accounts: **OU-Tech**, **OU-Security**, and
**OU-DevOps**. Each account has a **prod** environment.

```plantuml
AWSCloudGroup(cloud) {
  GenericGroup(ou_tech, "OU-Tech") {
    AWSAccountGroup(acc_tech_prod, "prod") {
    }
  }

  GenericGroup(ou_security, "OU-Security") {
    AWSAccountGroup(acc_security_prod, "prod") {
    }
  }

  GenericGroup(ou_devops, "OU-DevOps") {
    AWSAccountGroup(acc_devops_prod, "prod") {
    }
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5:</span>
  Using AWS cloud group
</div>

{{< gbox src="/posts/img/2023/documentation-as-code/plantuml-aws-accounts.png" title="" caption="" pos="left" >}}

<center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-aws-accounts.puml">Full PlantUML Code</a></center>


### VPCs and responsibilities {#vpcs-and-responsibilities}

On the VPC level, we have a custom VPC with two private subnets. The VPC has a
VPC endpoint to API Gateway. The VPC endpoint is used by the API Gateway to
access the EKS cluster.

The **DevOps** organizational unit also has some responsibilities which are highlighted
as "groups" inside the OU.

```plantuml
AWSCloudGroup(cloud) {
  GenericGroup(ou_tech, "OU-Tech") {
    AWSAccountGroup(acc_tech_prod, "prod") {
      VPCGroup(vpc_tech, "Custom VPC") {
        EKSCloud(tech_eks_cluster, "Tech EKS Cluster", "Cluster") {
        }
        VPCEndpoints(tech_vpc_endpoint, "VPC Endpoint", "VPC Endpoint")
      }
    }
  }

  GenericGroup(ou_security, "OU-Security") {
    AWSAccountGroup(acc_security_prod, "prod") {
    }
  }

  GenericGroup(ou_devops, "OU-DevOps") {
    AWSAccountGroup(acc_devops_prod, "prod") {
      GenericAltGroup(devops_cicd_group, "CI/CD") {
      }

      GenericAltGroup(devops_infraprov_group, "Infrastructure provisioning") {
      }

      GenericAltGroup(devops_releasemgmt_group, "Release Management") {
      }
    }
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 6:</span>
  Using AWS cloud group
</div>

{{< gbox src="/posts/img/2023/documentation-as-code/plantuml-aws-vpc.png" title="" caption="" pos="left" >}}

<center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-aws-vpc.puml">Full PlantUML Code</a></center>


### Relations {#relations}

```plantuml
AWSCloudGroup(cloud) {
  GenericGroup(ou_tech, "OU-Tech") {
    AWSAccountGroup(acc_tech_prod, "prod") {
      VPCGroup(vpc_tech, "Custom VPC") {
        EKSCloud(tech_eks_cluster, "Tech EKS Cluster", "Cluster") {
        }
        VPCEndpoints(tech_vpc_endpoint, "VPC Endpoint", "VPC Endpoint")
      }
      APIGateway(tech_api_gw, "API GW", "API GW")
    }

    ' Relationships
    tech_api_gw --> tech_vpc_endpoint
  }

  GenericGroup(ou_security, "OU-Security") {
    AWSAccountGroup(acc_security_prod, "prod") {
      CloudWatch(sec_cloudwatch, "Cloudwatch", "Cloudwatch")
      SimpleStorageService(sec_s3, "S3 Bucket", "S3 Bucket")
      IAMIdentityCenter(sec_iam_center, "IAM", "IAM")

      GenericAltGroup(sec_alerting_group, "Alerting") {
        SimpleNotificationService(sec_sns, "SNS", "SNS")
        LambdaLambdaFunction(sec_lambda, "Lambda", "Lambda")
      }

    }
    ' Relationships
    tech_api_gw --> sec_iam_center
    sec_cloudwatch --> sec_alerting_group
    tech_eks_cluster -- sec_s3
  }

  GenericGroup(ou_devops, "OU-DevOps") {
    AWSAccountGroup(acc_devops_prod, "prod") {
      GenericAltGroup(devops_cicd_group, "CI/CD") {
      }

      GenericAltGroup(devops_infraprov_group, "Infrastructure provisioning") {
      }

      GenericAltGroup(devops_releasemgmt_group, "Release Management") {
      }

      ' Relationships
      devops_infraprov_group -right- acc_tech_prod
      devops_cicd_group -right- tech_eks_cluster
    }
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 7:</span>
  Using AWS cloud group
</div>

{{< gbox src="/posts/img/2023/documentation-as-code/plantuml-aws-full.png" title="" caption="" pos="left" >}}

<center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-aws-full.puml">Full PlantUML Code</a></center>


### What about the rest? {#what-about-the-rest}

Our diagram is not complete yet. Every group region could have its own diagram (as if you would zoom in into a specific component). Let's have a look how we add Kubernetes related components such as _nodes_, _pods_ and _services_.
{{% sidenote %}}
Also have a look at [Hitchhikers Guide on Kubernetes](https://crashedmind.github.io/PlantUMLHitchhikersGuide/kubernetes/kubernetes.html).
{{% /sidenote %}}
```plantuml
AWSCloudGroup(cloud) {
  GenericGroup(ou_tech, "OU-Tech") {
    AWSAccountGroup(acc_tech_prod, "prod") {
      VPCGroup(vpc_tech, "Custom VPC") {
        EKSCloud(tech_eks_cluster, "EKS Cluster", "Cluster") {
          GenericGroup(grou_tech_eks_service, "Kubernetes Service") {
            Containers(tech_eks_pod1, "pod", "Pods")
            Containers(tech_eks_pod2, "pod", "Pods")
          }
        }
        VPCEndpoints(tech_vpc_endpoint, "VPC Endpoint", "VPC Endpoint")
      }
      APIGateway(tech_api_gw, "API GW", "API GW")
    }

    ' Relationships
    tech_api_gw --> tech_vpc_endpoint
  }

  GenericGroup(ou_security, "OU-Security") {
    AWSAccountGroup(acc_security_prod, "prod") {
      CloudWatch(sec_cloudwatch, "Cloudwatch", "Cloudwatch")
      SimpleStorageService(sec_s3, "S3 Bucket", "S3 Bucket")
      IAMIdentityCenter(sec_iam_center, "IAM", "IAM")

      GenericGroup(sec_alerting_group, "Alerting") {
        SimpleNotificationService(sec_sns, "SNS", "SNS")
        LambdaLambdaFunction(sec_lambda, "Lambda", "Lambda")
      }

    }
    ' Relationships
    tech_api_gw --> sec_iam_center
    sec_cloudwatch --> sec_alerting_group
    tech_eks_cluster -- sec_s3
  }

  GenericGroup(ou_devops, "OU-DevOps") {
    AWSAccountGroup(acc_devops_prod, "prod") {
      GenericAltGroup(devops_cicd_group, "CI/CD") {
      }

      GenericAltGroup(devops_infraprov_group, "Infrastructure provisioning") {
      }

      GenericAltGroup(devops_releasemgmt_group, "Release Management") {
      }

      ' Relationships
      devops_infraprov_group -right- acc_tech_prod
      devops_cicd_group -right- tech_eks_cluster
    }
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 8:</span>
  Using AWS cloud group
</div>

{{< gbox src="/posts/img/2023/documentation-as-code/plantuml-aws-full-eks.png" title="" caption="" pos="left" >}}

<center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-aws-full-eks.puml">Full PlantUML Code</a></center>


## Sequence diagrams {#sequence-diagrams}

When examining the previsouly sketched architecture, it is not immediately clear
how the mail service can be used. To gain a better understanding of the
**fundamental workflows**, it is necessary to adopt [sequence diagrams](https://plantuml.com/sequence-diagram). These
diagrams should be created for each business use case.

{{< notice info >}}

The examples below don't require the **epilogue** (styling and additional modules).

{{< /notice >}}


### Without fancy icons {#without-fancy-icons}

Let's explore some sequence diagrams **without** icons and additional styling:

-   Compose and send mails
    ```plantuml
      @startuml
      title Sending a Self-Destructing Email

      actor User
      participant Frontend
      participant AuthenticationService
      participant EmailCompositionService
      participant EncryptionService
      participant LifetimeManagementService
      participant NotificationService

      User -> Frontend: Compose email
      Frontend -> AuthenticationService: Authenticate user
      AuthenticationService --> Frontend: User authenticated
      Frontend -> EmailCompositionService: Compose email with content
      EmailCompositionService -> EncryptionService: Encrypt email content
      EncryptionService --> EmailCompositionService: Email content encrypted
      EmailCompositionService -> LifetimeManagementService: Set expiration time
      note right: Expire after N hours
      LifetimeManagementService --> EmailCompositionService: Expiration time set
      EmailCompositionService -> NotificationService: Notify recipient
      NotificationService --> EmailCompositionService: Recipient notified
      EmailCompositionService --> Frontend: Email composition complete
      Frontend --> User: Email sent
      @enduml
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 9:</span>
      Plantuml
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/plantuml-seq-send.png" title="" caption="" pos="left" >}}

    <center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-seq-send.puml">Full PlantUML Code</a></center>

<!--listend-->

-   Receive and view mails
    ```plantuml
      @startuml
      actor Recipient
      participant NotificationMicroservice
      participant Frontend
      participant EncryptionMicroservice
      participant LifetimeManagementMicroservice

      Recipient -> NotificationMicroservice: Received Email Notification
      NotificationMicroservice -> Frontend: Get Email Data
      Frontend -> EncryptionMicroservice: Decrypt Email Content
      Frontend -> Frontend: Display Email
      Frontend -> LifetimeManagementMicroservice: Check Expiration Status
      LifetimeManagementMicroservice -> Frontend: Email Expired
      @enduml
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 10:</span>
      Plantuml sequence diagram for receiving and viewing mails
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/plantuml-seq-receive.png" title="" caption="" pos="left" >}}

    <center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-seq-receive.puml">Full PlantUML Code</a></center>

<!--listend-->

-   Compose and send mails (with logging)

    Now let's complicate things a little bit and also make sure we **log** requests and **store** necessary data to our storage system:
    ```plantuml
      @startuml
      actor User
      participant Frontend
      participant AuthMicroservice
      participant EncryptionMicroservice
      participant CompositionMicroservice
      participant LifetimeManagementMicroservice
      participant LoggingService
      participant DataStorage

      User -> Frontend: Compose Email
      Frontend -> AuthMicroservice: Authenticate User
      AuthMicroservice -> Frontend: User Authenticated
      Frontend -> CompositionMicroservice: Send Email Data
      CompositionMicroservice -> EncryptionMicroservice: Encrypt Email Content
      EncryptionMicroservice -> LifetimeManagementMicroservice: Set Expiration Time
      LifetimeManagementMicroservice -> Frontend: Expiration Time Set
      Frontend -> Frontend: Notify User (Email Sent)
      Frontend -> LoggingService: Log Email Sent Event
      Frontend -> DataStorage: Store Email Metadata
      CompositionMicroservice -> DataStorage: Store Encrypted Email Content
      @enduml
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 11:</span>
      Plantuml sequence diagram for composing and sending mails (with logging)
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/plantuml-seq-send-logging.png" title="" caption="" pos="left" >}}

    <center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-seq-send-logging.puml">Full PlantUML Code</a></center>


### With AWS Icons {#with-aws-icons}

Let's add some AWS related icons and some boxes (for emphasizing components that belong together):

-   Send mails
    ```plantuml
      @startuml
      ' Epilogue
      skinparam BoxPadding 10

      ' !define AWSPuml https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v16.0/dist
      !define AWSPuml /home/victor/work/repos/aws-icons-for-plantuml/dist
      !include AWSPuml/AWSCommon.puml
      !include AWSPuml/Compute/all.puml
      !include AWSPuml/ApplicationIntegration/APIGateway.puml
      !include AWSPuml/General/Internetalt1.puml
      !include AWSPuml/Database/DynamoDB.puml

      ' Components
      actor User as User
      APIGatewayParticipant(api_gateway, "API Gateway", "")

      box "EKS" #LightBlue
        participant AuthenticationService
        participant EncryptionService
        participant EmailCompositionService
        participant NotificationService
        participant LifetimeManagementService
      end box

      ' Relationships
      User -> api_gateway: POST /create-mail
      == Authentication ==
      api_gateway -> AuthenticationService: Authenticate user
      AuthenticationService -> api_gateway: User authenticated

      == Mail creation ==
      api_gateway -> EmailCompositionService: POST /create-mail
      EncryptionService --> EmailCompositionService: Email content encrypted
      EmailCompositionService -> LifetimeManagementService: Set expiration time
      note right: Expire after N hours
      LifetimeManagementService --> EmailCompositionService: Expiration time set

      == Notification ==
      EmailCompositionService -> NotificationService: Notify recipient
      NotificationService --> EmailCompositionService: Recipient notified
      EmailCompositionService --> api_gateway: Email composition complete
      api_gateway --> User: Email sent
      @enduml
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 12:</span>
      Sending mail workflow (with icons and boxes)
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/plantuml-seq-send-aws.png" title="" caption="" pos="left" >}}

    <center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-seq-send-aws.puml">Full PlantUML Code</a></center>

<!--listend-->

-   Send mail (with logging and data storage)

    Now let's add **logging** and **data storage** to the sequence diagram
    ```plantuml
      @startuml
      ' Epilogue
      skinparam BoxPadding 10

      ' !define AWSPuml https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v16.0/dist
      !define AWSPuml /home/victor/work/repos/aws-icons-for-plantuml/dist
      !include AWSPuml/AWSCommon.puml
      !include AWSPuml/Compute/all.puml
      !include AWSPuml/Storage/all.puml
      !include AWSPuml/ManagementGovernance/CloudWatch.puml
      !include AWSPuml/ApplicationIntegration/APIGateway.puml
      !include AWSPuml/General/Internetalt1.puml
      !include AWSPuml/Database/DynamoDB.puml

      ' Components
      actor User as User
      APIGatewayParticipant(api_gateway, "API Gateway", "")

      box "EKS" #LightBlue
        participant AuthenticationService
        participant EncryptionService
        participant EmailCompositionService
        participant NotificationService
        participant LifetimeManagementService
      end box

      box "Storage" #LightGray
        SimpleStorageServiceParticipant(DataStorage, "S3", "")
      end box

      box "Logging" #LightCyan
        CloudWatchParticipant(LoggingService, "CloudWatch", "CloudWatch")
      end box


      ' Relationships
      User -> api_gateway: POST /create-mail
      == Authentication ==
      api_gateway -> AuthenticationService: Authenticate user
      AuthenticationService -> api_gateway: User authenticated

      == Mail creation ==
      api_gateway -> EmailCompositionService: POST /create-mail
      EncryptionService --> EmailCompositionService: Email content encrypted
      EmailCompositionService -> DataStorage: Save mail metadata and encrypted content
      EmailCompositionService -> LifetimeManagementService: Set expiration time
      note right: Expire after N hours
      LifetimeManagementService --> EmailCompositionService: Expiration time set

      == Notification ==
      EmailCompositionService -> NotificationService: Notify recipient
      NotificationService -> LoggingService: Log Email sent event
      NotificationService --> EmailCompositionService: Recipient notified
      EmailCompositionService --> api_gateway: Email composition complete
      api_gateway --> User: Email sent
      @enduml
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 13:</span>
      Sending mail workflow (with icons and boxes)
    </div>

    {{< gbox src="/posts/img/2023/documentation-as-code/plantuml-seq-send-aws-logging.png" title="" caption="" pos="left" >}}

    <center>👉 <a href="https://github.com/dorneanu/blog/blob/master/static/code/2023/documentation-as-code/plantuml//plantuml-seq-send-aws-logging.puml">Full PlantUML Code</a></center>


## Outlook {#outlook}

Here are some useful PlantUML related resources:

-   [plantuml.com](https://plantuml.com/)
    -   Especially [sequences](https://plantuml.com/sequence-diagram), [mindmaps](https://plantuml.com/mindmap-diagram), [components](https://plantuml.com/component-diagram)
    -   And for software architecture: [class diagrams](https://plantuml.com/class-diagram)
-   [real-world-plantuml.com](http://real-world-plantuml.com/)
-   [The Hitchhiker's Guide to PlantUML documentation](https://crashedmind.github.io/PlantUMLHitchhikersGuide/)

In the next post, we'll cover the [C4 model](https://c4model.com/), a powerful framework for visualizing
software and infrastructure architecture using a unified model and language.
Stay tuned!
