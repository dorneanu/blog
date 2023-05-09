+++
title = "AWS Summit 2023 in Berlin"
author = ["Victor Dorneanu"]
lastmod = 2023-05-09T21:20:17+02:00
tags = ["events", "aws"]
draft = false
+++

{{< gbox src="/posts/img/2023/aws-summit/aws-summit-keynote.png" title="The stage for the keynote" caption="The stage for the keynote at the AWS Summit 2023 in Berlin" pos="left" >}}


## Introduction {#introduction}

During this year's keynote, the main focus was on the **velocity** companies - and
_especially_ start-ups - need in order to bring their products to the market,
highlighting the importance of agility. I was particularly surprised to learn
that Flixbus is fully managing their infrastructure in AWS, showcasing the power
and potential of cloud technologies. It's impressive to see how [Flixbus](https://aws.amazon.com/de/solutions/case-studies/flixbus/) has
invested in their tech stack, especially during the pandemic when travel was at
an all-time low.

As with any start-up, challenges such as **speed**, **regulatory compliance**, **costs**,
and **growth** can pose significant obstacles. However, with the right mindset and
strategy, start-ups can overcome these challenges and battle prove their
products on the market. The ability to move quickly while still being compliant
to regulations, minimizing costs, and driving sustainable growth is key to
success in today's fast-paced market.


## Attended talks {#attended-talks}


### PAS216: Overcoming Cloud Security Challenges at Scale {#pas216-overcoming-cloud-security-challenges-at-scale}


#### Summary {#summary}

For the Security team it's crucial to be aware of the challenges that come with
migrating to the cloud. While it can be beneficial to move to the cloud, there
are still certain challenges that need to be taken into consideration. It's
important for organizations to grow with the technology as well. To manage these
challenges, having the right tool(s) is necessary. In selecting a tool suite,
it's critical to make sure that it aligns with the needs of both developers and
the organization as a whole as everyone sits in the same boat. In this
presentation, the author mainly talked how [ORCA Security](https://orca.security/) was able to solve their
security problems.


#### Notes {#notes}

<!--list-separator-->

-  Cloud Challenges in general

    -   **Scalability**
        -   The size becomes very abstract
        -   "You can't walk through a data center to get a sense"
        -   Even small mistakes get _expensive quickly_
        -   Every _manual process_ will break
    -   **Growth During Transformation**
        -   There is no time - growth drives its own momentum
        -   Delay makes any problem bigger
        -   _Organizational change is hard_
            -   Even more for non-tech teams
    -   **Level of Complexity**
        -   Multicloud by strategy (at least for SAP)
        -   Large portfolio of products, often deployed in regulated industries
        -   Transitioning to cloud-native and [microservices](https://brainfck.org/t/microservices) architectures
        -   Bewildering organization with high autonomy within business units and developer teams

<!--list-separator-->

-  Cloud Challenges for Security

    -   **Scale**
        -   Large scale means many findings (good or bad)
        -   everything is an engineering job
        -   Everything can break at any time, no 'test' environment
    -   **Growth During Transformation**
        -   Our secunty budget doesn't grow linearly with growth in the landscape
        -   Security organizations often don't run or adapt to change as fast as DevOps teams
    -   **Level of Complexity**
        -   How do you _centralize Security functions_ when developer teams have even more autonomy?
        -   How do you _make them not hate you_, for making them do work to get more work?
        -   How do you get access to systems or get tooling deployed?

<!--list-separator-->

-  Shared Fate

    -   _We are all in this together_
    -   main keys with regards to the rest of the team
        -   collaborative
        -   Relieving Operational Burden
        -   Enabling
            -   Aligned Goals and Targets

<!--list-separator-->

-  Contextualization and Risk-Based Prioritization

    -   **Context**
        -   Context determines the severity and urgency of the finding
        -   _Enrich with organizational metadata to assess business risk to the organization_
        -   Avoid wild goose chase or impossible standards and SLAs
    -   **Tool Sprawl**
        -   Every additional data source requires data enrichment
        -   Each have their own costs
        -   Very nice if one tool does a lot and contextualizes across
    -   **Alert Fatigue**
        -   The organization doesn't scale with the size of the landscape
        -   We have to focus on what is most important
        -   Limited developer time for security
        -   Don't misuse Security teams resources


### COM204: Building Infrastructure AWS CDK vs Terraform {#com204-building-infrastructure-aws-cdk-vs-terraform}


#### Summary {#summary}

The ongoing "[CDK](https://brainfck.org/t/cdk) vs. Terraform" controversy is deemed to be
a highly debated topic among IT professionals. Though the writer was known to be
a fan of Terraform, she now showed its main pain points and highlighted some
solutions with [CDK](https://brainfck.org/t/cdk). The author believes that most DevOps
professionals opt for Terraform due to its ease of use as it doesn't require any
programming knowledge, and it is considered one of the best frameworks for
coding infrastructure. However, the often mentioned multi-cloud argument as
deploying the same Terraform stack to another cloud provider is not an easy
task. Additionally there are major differences in the state management of both
solutions, and it's crucial to consider distinct approaches for the safe and
reliable deployment of infrastructure components.


#### Notes {#notes}

<!--list-separator-->

-  Pain points with Terraform

    <!--list-separator-->

    -  Conditions

        ```terraform
        variable "environment" {
          description = "Environment for security groups"
          type        = string
          default     = "dev"
        }

        resource "aws_security_group" "web" {
          count = var.environment == "prod" ? 1 : 0

          name_prefix = "web-"
          ingress {
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }

        resource "aws_security_group" "db" {
          count = var.environment == "prod" ? 1 : 0

          name_prefix = "db-"
          ingress {
            from_port   = 3306
            to_port     = 3306
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
        ```
        <div class="src-block-caption">
          <span class="src-block-number">Code Snippet 1:</span>
          Example of using conditionals in Terraform
        </div>

        ```typescript
        // Define the VPC
        const vpc = new ec2.Vpc(stack, 'VPC', {
          maxAzs: 2,
          natGateways: 1,
        });

        let enablePublicIp: boolean = true;

        // Use a condition to determine whether to create an instance with a public IP
        if (process.env.ENABLE_PUBLIC_IP == 'false') {
          enablePublicIp = false;
        }
        ```
        <div class="src-block-caption">
          <span class="src-block-number">Code Snippet 2:</span>
          Example of using conditionals in CDK
        </div>

    <!--list-separator-->

    -  Policy handling

        ```terraform
        resource "aws_iam_policy" "example_policy" {
          name        = "example_policy"
          policy      = data.template_file.example_policy.rendered
        }

        data "template_file" "example_policy" {
          template = <<EOF
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Action": [
                "s3:GetObject",
                "s3:PutObject"
              ],
              "Effect": "Allow",
              "Resource": [
                "arn:aws:s3:::example-bucket/*"
              ]
            },
            {
              "Action": [
                "ec2:DescribeInstances"
              ],
              "Effect": "Allow",
              "Resource": "*"
            }
          ]
        }
        EOF
        }
        ```
        <div class="src-block-caption">
          <span class="src-block-number">Code Snippet 1:</span>
          Example of Terraform code defining IAM policies
        </div>

        ```typescript
        const dynamoTable = new dynamodb.Table(this, 'MyDynamoTable', {
          partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
        });

        const ec2SecurityGroup = new ec2.SecurityGroup(this, 'MySecurityGroup', {
          vpc,
          allowAllOutbound: true,
        });

        dynamoTable.grantReadWriteData(ec2SecurityGroup);
        ```
        <div class="src-block-caption">
          <span class="src-block-number">Code Snippet 1:</span>
          Allow EC2 instances to read from and write to a DynamoDB table:
        </div>

    <!--list-separator-->

    -  Create Lambdas

        ```terraform
        provider "aws" {
          region = "us-west-2"
          access_key = "your_access_key"
          secret_key = "your_secret_key"
        }

        resource "aws_iam_role" "lambda_role" {
          name = "lambda_role"
          assume_role_policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Principal = {
                  Service = "lambda.amazonaws.com"
                }
                Action = "sts:AssumeRole"
              }
            ]
          })
        }

        resource "aws_lambda_function" "my_lambda_function {
          filename = "my_lambda_function.zip"
          function_name = "my_lambda_function"
          role = aws_iam_role.lambda_role.arn
          runtime = "nodejs12.x"
          handler = "index.handler"
        }
        ```
        <div class="src-block-caption">
          <span class="src-block-number">Code Snippet 1:</span>
          Create a Lambda function with Terraform
        </div>

        ```typescript
        import * as cdk from 'aws-cdk-lib';
        import * as lambda from 'aws-cdk-lib/aws-lambda';
        import * as lambdaNodejs from 'aws-cdk-lib/aws-lambda-nodejs';

        export class LambdaStack extends cdk.Stack {
         constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
           super(scope, id, props);

           const lambdaFn = new lambdaNodejs.NodejsFunction(this, "SimpleLambda", {
             entry: 'src/index.ts',
             handler: 'handler',
             runtime: lambda.Runtime.NODEJS_12_X,
             memorySize: 256
           });

           new cdk.CfnOutput(this, "LambdaFunctionArn", {
             value: lambdaFn.functionArn
           });
         }
        }
        ```
        <div class="src-block-caption">
          <span class="src-block-number">Code Snippet 1:</span>
          Create a Lambda function with CDK
        </div>

    <!--list-separator-->

    -  Testing

        -   For terraform you have `terratest`

        In CDK it's quite easy to test your expectations:

        ```typescript
        import { expect as expectCDK, SynthUtils } from '@aws-cdk/assert';
        import * as cdk from '@aws-cdk/core';
        import * as myapp from '../lib/myapp-stack';

        test('MyAppStack creates an S3 bucket', () => {
          const app = new cdk.App();
          const stack = new myapp.MyAppStack(app, 'MyAppStack');
          const expected = SynthUtils.toCloudFormation(stack);

          // Assert that the S3 bucket is created
          expect(expected.Resources).toHaveProperty('MyAppS3Bucket');

          // Assert that the S3 bucket has the correct properties
          const bucket = expected.Resources.MyAppS3Bucket.Properties;
          expect(bucket).toHaveProperty('BucketName', 'myapp-bucket');
          expect(bucket).toHaveProperty('VersioningConfiguration', {
            Status: 'Enabled'
          });
        });
        ```

    <!--list-separator-->

    -  State management

        -   Terraform
            -   tf state
                -   keep it in S3 bucket
                -   enable versioning to be able to "rollback" to a previous workable state
                -   What if state is gone (for whatever reasons)?
        -   CDK
            -   CloudFormation based
            -   rollbacks are handled automagically

<!--list-separator-->

-  Decisions template

    Whether Terraform or [CDK](https://brainfck.org/t/cdk) this depends on:

    -   team _staffing_
    -   the _preferences_ of the developers
    -   availability of the services to be provisioned
    -   if workflows are _easily automatable_
    -   quality of the _documentation_
    -   _compliance rules_ of the company


### STP204: Web3 - Build, launch and scale your Web3 startup on AWS ft. 1inch {#stp204-web3-build-launch-and-scale-your-web3-startup-on-aws-ft-dot-1inch}


#### Summary {#summary}

[Tim Berger](https://www.linkedin.com/in/bergertim/) from AWS highlighted what is necessary in order to interact with a
blockchain. With blockchain technology gaining significant traction, Tim
emphasized the importance of understanding the fundamentals of blockchain
interaction in order to take full advantage of its potential.

Furthermore, Tim also showcased some sample architectures where [Amazon Managed
Blockchain](https://aws.amazon.com/managed-blockchain/) service has been successfully implemented. The audience gained
insights into the various use cases of the service and how it can be integrated
with other AWS products to achieve a seamless blockchain experience.

In addition to Tim's presentation, [Sergej Kunz](https://www.linkedin.com/in/deacix/), the co-founder of [1inch](https://1inch.io/), also
gave an exciting talk on how he and his team use AWS services for providing web3
based applications.

Also have a look at

-   [Build, launch, and scale your Web3 startup at AWS (from AWS Summit ANZ 2022)](https://www.youtube.com/watch?v=UcwuTkN15Uc&ab_channel=AWSEvents).
-   [Deep Dive on Amazon Managed Blockchain](https://www.youtube.com/watch?v=UcwuTkN15Uc&ab_channel=AWSEvents)


#### Open Datasets {#open-datasets}

-   [Open Datasets for Ethereum and Bitcoin](https://aws.amazon.com/blogs/database/access-bitcoin-and-ethereum-open-datasets-for-cross-chain-analytics/)
    -   [high-level architecture](https://d2908q01vomqb2.cloudfront.net/887309d048beef83ad3eabf2a79a64a389ab1c9f/2022/09/16/DBBLOG-2500-image001.png)

<!--list-separator-->

-  For `BTC`:

    -   blocks/date={YYYY-MM-DD}/{id}.snappy.parquet
    -   transactions/date={YYYY-MM-DD}/{id}.snappy.parquet

    <!--listend-->

    ```sh
    aws s3 ls --no-sign-request s3://aws-public-blockchain/v1.0/btc/
    ```

<!--list-separator-->

-  For `ETH`

    -   blocks/date={YYYY-MM-DD}/{id}.snappy.parquet
    -   transactions /date={YYYY-MM-DD}/{id}.snappy.parquet
    -   logs/date={YYYY-MM-DD}/{id}.snappy.parquet
    -   token_transfers/date={YYYY-MM-DD}/{id}.snappy.parquet
    -   traces/date={YYYY-MM-DD}/{id}.snappy.parquet
    -   contracts/date={YYYY-MM-DD}/{id}.snappy.parquet

    <!--listend-->

    ```sh
    aws s3 ls --no-sign-request s3://aws-public-blockchain/v1.0/eth/
    ```

    Some example:

    ```text
    aws s3 ls --no-sign-request s3://aws-public-blockchain/v1.0/btc/transactions/2023-05-08/4ed1639d0b03a562def6755a0c0465a11248c04cd389ea09cf87a35f6c95b6f9.snappy.parquet
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 1:</span>
      How to get transaction metadata
    </div>


### ARC304: Reactive Architecture on AWS: from 0 to 1.6M events/minute {#arc304-reactive-architecture-on-aws-from-0-to-1-dot-6m-events-minute}


#### Reactive systems {#reactive-systems}

First of all some introductory words about reactive systems. As stated in the
[Reactive Manifesto](https://www.reactivemanifesto.org/) today's user expectations have changed dramatically over the
past years. Users expect applications to be **responsive** (response time measured
in _miliseconds_) and software developers hope their system will be **resilient**
enough to cope with failures in an elegant way rather than full disaster.

The manifesto emphasized the important of building software that can easily
adapt to changes in user demand, system loads and failure conditions. And all
this has to be taken into consideration while still remaining flexible and
scalable enough to handle future growth and evolution.

Reactive systems are:

-   **responsive**
    -   responsiveness is key here
    -   problems can be detected quickly
    -   response time is also an spect of the quality of service
-   **resilient**
    -   systems stay responsive in case of failure
    -   resilience is achieved by
        -   [replication](https://www.reactivemanifesto.org/glossary#Replication)
        -   containment
        -   [isolation](https://www.reactivemanifesto.org/glossary#Isolation)
        -   [delegation](https://www.reactivemanifesto.org/glossary#Delegation)
-   **elastic**
    -   systems remain responsiveness under various loads
    -   auto-scaling of resources
-   **message-driven**
    -   in contrast to event-driven
    -   systems use async [message-passing](https://www.reactivemanifesto.org/glossary#Message-Driven) for communication between components


#### Bitpanda Pro {#bitpanda-pro}

[Bitpanda Pro](https://pro.bitpanda.com/en) is a trading platform that allow users to trade _digital assets_
(such as cryptocurrencies) but also _metals_ against fiat currencies such as EUR,
USD, GBP. The platform offers various trading tools such as charts, advanced
order types, _real-time data_ and access to liquidity providers.

In this talk Bitpanda talks about their _reactive_ architecture and how they
managed to setup their infrastructure accordingly. Impressive enough was also
the fact they've managed to server 1.6m events / minute!


#### Notes {#notes}

<!--list-separator-->

-  The first take

    The initial step taken to build the reactive infrastructure in AWS:

    | Target                                                           | Solution                                                                                 |
    |------------------------------------------------------------------|------------------------------------------------------------------------------------------|
    | Avoid complexity of container orchestration                      | [AWS ECS](https://aws.amazon.com/ecs/) on [AWS Fargate](https://aws.amazon.com/fargate/) |
    | Push back on the microservices hype                              | [Mono-repo](https://en.wikipedia.org/wiki/Monorepo) + single deployments                 |
    | High-performance message-passing framework                       | [vertx.io](https://vertx.io/)                                                            |
    | App responsive during rapid client activity spike                | ALB + Auto-Scaling groups                                                                |
    | Isolate failures and guarantuee uninterrupted trading experience | Redundant deployment across 3 AZ                                                         |
    | (near) Zero downtime - uninterrupted trading venue               | [Amazon Aurora](https://aws.amazon.com/rds/aurora/)                                      |

<!--list-separator-->

-  Second take

    This one was about elasticity and message passing. Each traded pair (BTC, EUR, USD etc.) lives in an isolated world:

    -   they used a dedicated **Kafka topic** partition and ECS task
    -   one Kafka topic partition per traded pair

    They've also implemented [back-pressure control](https://www.reactivemanifesto.org/glossary#Back-Pressure) and **load-shedding**.


## Fun stuff {#fun-stuff}


### serverlesspresso {#serverlesspresso}

The [serverlesspresso](https://github.com/aws-samples/serverless-coffee) application is a [serverless](https://brainfck.org/t/serverless)
coffee bar exibit, first seen at AWS re:Invent 2021. I had the chance to see and
also try it in Berlin 😎.


#### Serverless application {#serverless-application}

{{< gbox src="/posts/img/2023/aws-summit/serverlesspresso-application.png" title="The serverlesspresso application on my smartphone" caption="The application is rather simple and you can chose different beverages" pos="left" >}}


#### Ordering {#ordering}

{{< gbox src="/posts/img/2023/aws-summit/serverlesspresso-order-was-placed.png" title="Order was placed" caption="After selecting your beverage you'll get a new order ID." pos="left" >}}

{{< gbox src="/posts/img/2023/aws-summit/serverlesspresso-order-queue.png" title="The ordering queue for the coffee shop" caption="This where you can see your order and also the expected time to delivery" pos="left" >}}


#### The result ☕ {#the-result}

{{< gbox src="/posts/img/2023/aws-summit/serverlesspresso-flatwhite.png" title="The final flatwhite" caption="At the end you'll get a receipt and of course, your coffee " pos="left" >}}


#### The architecture {#the-architecture}

{{< gbox src="/posts/img/2023/aws-summit/serverlesspresso-how-it-works.png" title="The serverless architecture" caption="Different APIs are used but step functions are at the heart of the application." pos="left" >}}
