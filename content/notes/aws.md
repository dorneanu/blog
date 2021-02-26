+++
title = "AWS"
author = ["Victor Dorneanu"]
lastmod = 2021-02-26T11:12:15+01:00
tags = ["note", "aws"]
draft = false
weight = 2002
toc = true
+++

## AMI {#ami}


## aws cli {#aws-cli}

Some currated list of useful `aws`  CLI commands.

-   API Gateway

    | desc             | command                               |
    |------------------|---------------------------------------|
    | get-domain-names | `$ aws apigatewayv2 get-domain-names` |

-   SSM

    | desc          | command                                                                                           |
    |---------------|---------------------------------------------------------------------------------------------------|
    | get parameter | `$ aws --profile default ssm get-parameter --with-decryption --name "<ssm path>"`                 |
    | put parameter | `$ aws ssm put-parameter --name <path> --value <value> --type SecureString --key-id <KMS key ID>` |

-   Cloudformation

    | desc               | command                                                              |
    |--------------------|----------------------------------------------------------------------|
    | tail for CF events | `$tail-stack-events -f --die -n 5 --region <region> -s <stack name>` |

-   SQS

    | desc                    | command                                                                                          |
    |-------------------------|--------------------------------------------------------------------------------------------------|
    | receive one message     | `$ aws sqs receive-message --queue-url <queue url> --region <region>`                            |
    | get attributes of queue | `$ aws sqs get-queue-attributes --queue-url <queue url> --region <region> --attribute-names All` |
    | purge queue             | `$ aws sqs purge-queue --queue-url <queue url>`                                                  |

-   DynamodDB

    | desc                 | command                                                                                                                                                                                  |
    |----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    | scan with expression | `$ aws dynamodb scan --table-name <table name> --filter-expression "repo_name = :repo" --expression-attribute-values '{":repo":{"S":"my_repo"}}' --projection-expression <table fields>` |
    | scan                 | `aws dynamodb scan --table-name tiddlers --endpoint http://127.0.0.1:8000`                                                                                                               |

    -   Delete multiple items

        Use `scan` to retrieve list of items and save to same file:

        ```shell
                $ aws dynamodb scan --table-name <table name> --filter-expression "repo_name = :repo" --expression-attribute-values '{":repo":{"S":"my_repo"}}' --projection-expression "unique_id" > results.log
        ```

        Then use `delete-item` to delete single entries:

        ```shell
                $ cat results.log | jq -r ".Items[] | tojson" | tr '\n' '\0' | xargs -0 -I keyItem aws dynamodb delete-item --table-name <table name> --key=keyItem
        ```


## Tools {#tools}

| Tool                                        | Description                         |
|---------------------------------------------|-------------------------------------|
| [awless](https://github.com/wallix/awless)  | A mighty CLI for AWS                |
| [saws](https://github.com/donnemartin/saws) | A supercharged CLI based on aws cli |


## SQS {#sqs}

-   [Amazon SQS visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html)
