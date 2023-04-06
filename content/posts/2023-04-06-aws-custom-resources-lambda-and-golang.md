+++
title = "AWS Custom resources with Lambda and Golang"
author = ["Victor Dorneanu"]
lastmod = 2023-04-06T16:11:12+02:00
tags = ["aws", "serverless", "cdk", "golang"]
draft = false
+++

## Motivation {#motivation}

[CDK](https://aws.amazon.com/cdk/) is a great framework by AWS that allows you to define cloud infrastructure
as code (IaC). You can use your favourite programming language such as
TypeScript, Python, Java, [Golang](https://brainfck.org/t/golang) to define your resources.
This feature is particularly convenient as it automates the generation of
CloudFormation templates in a readable and more manageable way.

However, not every AWS resource can be mapped directly to a CloudFormation
template using CDK. In my particular case I had to create **secure** SSM parameters
from within CDK. Typically this is how you create a SSM parameter in
CloudFormation:

```yaml
Resources:
  MySSMParameter:
    Type: "AWS::SSM::Parameter"
    Properties:
      Type: "String"     ❶
      Name: "/my/ssm/parameter"
      Value: "myValue"
      Description: "Description"
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Sample CloudFormation template for creating SSM parameters
</div>

In ❶ you specify the type of the SSM parameter:

-   _standard_ (`String`)
    -   simple key-value string pair
    -   does **not** support versioning
-   _advanced_ (`StringList`)
    -   key-value pairs with additional metadata
    -   does support versioning
-   _secure string_ (`SecureString`)
    -   similar to standard parameters but the data is encrypted at rest using AWS KMS
    -   this is used for storing sensitive data such as passwords, API keys and other credentials

> Depending on the stack action, CloudFormation sends your function a Create,
> Update, or Delete event. Because each event is handled differently, make sure
> that there are no unintended behaviors when any of the three event types is
> received. -- [Source](https://aws.amazon.com/premiumsupport/knowledge-center/best-practices-custom-cf-lambda/)

Custom resources can be used in an AWS CloudFormation stack to _create_, _update_,
_delete_ some resources that are not available as a native CFN (CloudFormation)
resource. This could be SSL certificates that need to be generated in a certain
way, custom DNS records or anything outside AWS. The Lambda function will take
care of the lifecycle management of that specific resource.

{{< gbox src="/posts/img/2023/custom-resource-poc/sequence.png" title="General workflow" caption="The general workflow and how each component relates to each other." pos="left" >}}

In CDK you would create your custom resource which has a so called `provider`
attached (in our case it's a [Lambda function](#aws-lambda)) meant to implement the logic
whenever the resource is created, updated or deleted. After `cdk synth` a new
CloudFormation template for the CDK stack is created. Whenever a resource is
created/updated/deleted a new CloudFormation **event** will occur. This event will
be sent to the Lambda function which eventually will create/update/delete SSM
parameters based on the event's properties.

This gives you enough flexibility to define _what_ should happen when certain
events occur. Let's dig into deeper into the specifics.


## AWS Lambda {#aws-lambda}


### Basic template {#basic-template}

As mentioned before the custom resource should be _baked_ by an AWS Lambda function. This is how you would write the basic function structure:

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"

    "github.com/aws/aws-lambda-go/cfn"
)
// Global AWS session variable
var awsSession aws.Config  // ❶

// init will setup the AWS session
func init() {              // ❷
    cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion("eu-central-1"))
    if err != nil {
        log.Fatalf("unable to load SDK config, %v", err)
    }
    awsSession = cfg
}

// lambdaHandler handles incoming CloudFormation events
// and is of type cfn.CustomResourceFunction
func lambdaHandler(ctx context.Context, event cfn.Event) (string, map[string]interface{}, error) {
    var physicalResourceID string
    responseData := map[string]interface{}{}

    switch event.ResourceType {    // ❹
    case "AWS::CloudFormation:CustomResource":
        customResourceHandler := NewSSMCustomResourceHandler(awsSession)
        return customResourceHandler.HandleEvent(ctx,event)
    default:
        return "",nil, fmt.Errorf("Unknown resource type: %s", event.ResourceType)
    }
    return physicalResourceID, nil, nil
}

// main function
func main() {
	// From : https://github.com/aws/aws-lambda-go/blob/main/cfn/wrap.go
	//
	// LambdaWrap returns a CustomResourceLambdaFunction which is something lambda.Start()
	// will understand. The purpose of doing this is so that Response Handling boiler
	// plate is taken away from the customer and it makes writing a Custom Resource
	// simpler.
	//
	//	func myLambda(ctx context.Context, event cfn.Event) (physicalResourceID string, data map[string]interface{}, err error) {
	//		physicalResourceID = "arn:...."
	//		return
	//	}
	//
	//	func main() {
	//		lambda.Start(cfn.LambdaWrap(myLambda))
	//	}
	lambda.Start(cfn.LambdaWrap(lambdaHandler))  // ➌
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  Basic structure of the AWS Lambda function in Go
</div>

Some explanations:

-   The `main` function will call a lambda handler ➌
-   Before `main` gets executed the `init` function will be executed first ❷
    -   it will try to connect to AWS and populate the global variable defined at ❶
-   within `lambdaHandler` we also have to make sure check for the right CFN custom resource **type** ❹


### Custom resource handler {#custom-resource-handler}

```go
// handleSSMCustomResource decides what to do in case of CloudFormation event
func (s SSMCustomResourceHandler) HandleSSMCustomResource(ctx context.Context, event cfn.Event) (string, map[string]interface{}, error) {

    switch event.RequestType {   //  ❶
    case cfn.RequestCreate:
        return s.Create(ctx, event)
    case cfn.RequestUpdate:
        return s.Update(ctx, event)
    case cfn.RequestDelete:
        return s.Delete(ctx, event)
    default:
        return "", nil, fmt.Errorf("Unknown request type: %s", event.RequestType)
    }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  The main handler of the Lambda function
</div>

Supposing we use a custom type called `SSMCustomResourceHandler` we can have a main entrypoint (in this example called `HandleSSMCustomResource`) where we call a different method depending on the events request type ❶.

Each method will apply trigger different sorts of operations. This is what will happen whenever a new custom resource is **created**:

```go
// Create creates a new SSM parameter
func (s SSMCustomResourceHandler) Create(ctx context.Context, event cfn.Event) (string, map[string]interface{}, error) {
    var physicalResourceID string

    // Get custom resource parameter from event
    ssmPath, err := strProperty(event, "key")    // ❶
    if err != nil {
        return physicalResourceID, nil, fmt.Errorf("Couldn't extract credential's key: %s", err)
    }
    physicalResourceID = ssmPath                 // ❷

    ssmValue, err := strProperty(event, "value") // ❶
    if err != nil {
        return physicalResourceID, nil, fmt.Errorf("Couldn't extract credential's value: %s", err)
    }

    // Put new parameter                            ➌
    _, err = s.ssmClient.PutParameter(context.Background(), &ssm.PutParameterInput{
        Name:      aws.String(ssmPath),
        Value:     aws.String(ssmValue),
        Type:      types.ParameterTypeSecureString,
        Overwrite: aws.Bool(true),
    })
    log.Printf("Put parameter into SSM: %s", physicalResourceID)

    if err != nil {
        return physicalResourceID, nil, fmt.Errorf("Couldn't put parameter (%s): %s\n", ssmPath, err)
    }
    return physicalResourceID, nil, nil
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Create method of the SSMCustomResourceHandler
</div>

`Create` should create a new SSM parameter (of type `SecureString`) based on the information contained within the CloudFormation
event. In ❶ I use a helper function to extract a property out of the `event`. Once we have the `ssmPath` we also set the `physicalResourceID` to that value ❷. Afterwards we will call `PutParameter` which should create a new SSM parameter.

The CloudFormation event contains much information. This is what it looks like:

```json
{
  "RequestType": "Create",
  "RequestID": "b37cee19-f52d-4801-89f0-eed1be454756",
  "ResponseURL": "",
  "ResourceType": "AWS::CloudFormation::CustomResource",
  "PhysicalResourceID": "",
  "LogicalResourceID": "SSMCredential63DBA3F67",
  "StackID": "arn:aws:cloudformation:eu-central-1:xxxx:stack/CustomResourcesGolang/a0de3b10-c3e1-11ed-9d97-02c",
  "ResourceProperties": {
    "ServiceToken": "arn:aws:lambda:eu-central-1:xxxxxxxxxxxx:function:CustomResourcesGolang-ProviderframeworkonEvent83C1-Dt9Jv3RwL9KT",
    "key": "/testing6",
    "value": "some-secret-value"
  },
  "OldResourceProperties": {}
}
```


## CDK {#cdk}

Now that we know how to deal with CloudFormation events and how to manage the custom resource, let's deep-dive into DevOps and setup a small CDK application. Usually I would write the CDK part in Python but for this project I've setup my very first CDK application in TypeScript 😏. Let's start with the basic template.


### Deployment Stack {#deployment-stack}

The deployment stack I've defined which resources/components should be created:

```typescript
import * as cdk from "aws-cdk-lib";
import * as path from "path";
import * as customResources from "aws-cdk-lib/custom-resources";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as iam from 'aws-cdk-lib/aws-iam';
import { spawnSync, SpawnSyncOptions } from "child_process";
import { Construct } from "constructs";
import { SSMCredential } from "./custom-resource";

export class DeploymentsStack extends cdk.Stack {  // ❶
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Build the Golang based Lambda function
    const lambdaPath = path.join(__dirname, "../../");

    // Create IAM role
    const iamRole = new iam.Role(this, 'Role', {...});  // ❷

    // Add further policies to IAM role
    iamRole.addToPolicy(...);                           // ➌

    // Create Lambda function
    const lambdaFunc = new lambda.Function(this, "GolangCustomResources", {...});   // ❹

    // Create a new custom resource provider
    const provider = new customResources.Provider(this, "Provider", {...});   // ❺

    // Create custom resource
    new SSMCredential(this, "SSMCredential1", provider, {...});               // ❻
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  deployments-stack.ts
</div>

So my CDK application will:

-   create a new CloudFormation stack called `DeploymentsStack` ❶
-   create a new IAM role ❷
    -   used to attach it to the lambda function
    -   here we define the IAM policies required to operate on SSM parameters
-   add several IAM policies to the IAM role ➌
-   create a new AWS Lambda function ❹
-   create a so called provider ❺ which is responsible for the lifecycle management of the custom resources in AWS
    -   in our case this is our lambda function
    -   I'm not sure if this can be something different 😕


### Custom resource {#custom-resource}

In the previous section I've mentioned `SSMCredential` which is our new custom resource to implement a SSM parameter of type `SecureString`.

```typescript
import * as path from "path";
import * as cdk from "aws-cdk-lib";
import * as customResources from "aws-cdk-lib/custom-resources";
import { Construct } from "constructs";
import fs = require("fs");

export interface SSMCredentialProps {   // ❶
  key: string;
  value: string;
}

// SSMCredential is an AWS custom resource
//
// Example code from: https://github.com/aws-samples/aws-cdk-examples/blob/master/typescript/custom-resource/my-custom-resource.ts
export class SSMCredential extends Construct {  // ❷
  public readonly response: string;

  constructor(
    scope: Construct,
    id: string,
    provider: customResources.Provider,
    props: SSMCredentialProps
  ) {
    super(scope, id);

    const resource = new cdk.CustomResource(this, id, {  // ➌
      serviceToken: provider.serviceToken,               // ❹
      properties: props,                                 // ❺
    });

    this.response = resource.getAtt("Response").toString();
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  custom-resource.ts
</div>

-   the `SSMCredentialProps` define the arguments ❶  to be passed to the custom resource
    -   `key`: the parameter's name
    -   `value`: the value the parameter should hold
-   the custom resource itself is of type `SSMCredential` ❷
    -   it has a `constructor`
    -   inside it a new CDK custom resource is being initialized ➌
        -   the serviceToken is the ARN of the provider which implements this custom resource type.
        -   additionally we pass in the arguments ❺ (as properties)

And this is how it's used withing the previously defined `DeploymentsStack`:

```typescript
import { SSMCredential } from "./custom-resource";
...

export class DeploymentsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    ...

    // Create a new custom resource provider
    const provider = new customResources.Provider(this, "Provider", {
      onEventHandler: lambdaFunc,
    });

    // Create custom resource
    new SSMCredential(this, "SSMCredential1", provider, {
      key: "/test/testing",
      value: "some-secret-value",
    });
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  How to use a SSMCredential in your CDK stack
</div>


## Screenshots {#screenshots}

As pictures say more than words, let's have a look at some screenshots to better
understand what's happening under the hood. Doing so you might get a better
understanding of the workflow and all the involved components that are created
by CDK.

{{< gbox src="/posts/img/2023/custom-resource-poc/cloudformation-tree-view.png" title="The CloudFormation stack in the AWS console. Here we have created 2 custom resources of type SSMCredential." caption="Different resources are created by CloudFormation. " pos="left" >}}

{{< gbox src="/posts/img/2023/custom-resource-poc/ssm-parameter-securestring.png" title="The SSM parameters created by the Lambda function are of type SecureString." caption="THe SSM parameters are of type SecureString" pos="left" >}}

{{< gbox src="/posts/img/2023/custom-resource-poc/ssm-parameter-tags.png" title="Each SSM parameter has a tag (stackID) assigned." caption="Each SSM parameter has a tag assigned. " pos="left" >}}


## Testing {#testing}


### Unit tests {#unit-tests}

The SSMCustomResourceHandler [structure has a SSM client](https://github.com/dorneanu/aws-custom-resource-golang/blob/37e54831c1251c22fa4c37bafdbccf413a8e049c/internal/aws_custom_resource.go#L23-L25) in order to PUT and DELETE parameters:

```go
// SSMParameterAPI defines an interface for the SSM API calls
// I use this interface in order to be able to mock out the SSM client and implement unit tests properly.
//
// Also check https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/gov2/ssm
type SSMParameterAPI interface {
	DeleteParameter(ctx context.Context, params *ssm.DeleteParameterInput, optFns ...func(*ssm.Options)) (*ssm.DeleteParameterOutput, error)
	PutParameter(ctx context.Context, params *ssm.PutParameterInput, optFns ...func(*ssm.Options)) (*ssm.PutParameterOutput, error)
}

type SSMCustomResourceHandler struct {
	ssmClient SSMParameterAPI
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  In <a href="https://github.com/dorneanu/aws-custom-resource-golang/tree/37e54831c1251c22fa4c37bafdbccf413a8e049c/internal/aws_custom_resource.go">aws_custom_resource.go</a>
</div>

I use my own interface for the SSM parameter API as this can be easily mocked out when writing unit tests:

```go
// SSMParameterApiImpl is a mock for SSMParameterAPI
type SSMParameterApiImpl struct{}

// PutParameter
func (s SSMParameterApiImpl) PutParameter(ctx context.Context, params *ssm.PutParameterInput, optFns ...func(*ssm.Options)) (*ssm.PutParameterOutput, error) {
	output := &ssm.PutParameterOutput{}
	return output, nil
}


// DeleteParameter
func (s SSMParameterApiImpl) DeleteParameter(ctx context.Context, params *ssm.DeleteParameterInput, optFns ...func(*ssm.Options)) (*ssm.DeleteParameterOutput, error) {
	output := &ssm.DeleteParameterOutput{}
	return output, nil
}

```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  In aws_custom_resource_test.go
</div>

Now I can use the `SSMParameterApiImpl` as a mocked client as it satisfies the `SSMParameterAPI` interface:

```go
func TestPutParameter(t *testing.T) {
	mockedAPI := SSMParameterApiImpl{}
	ssmHandler := SSMCustomResourceHandler{
		ssmClient: mockedAPI,
	}
	...
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  In aws_custom_resource_test.go
</div>

All we have to do now is to create a cfn.Event and call the Create method of the SSMHandlerCustomResource class:

```go
func TestPutParameter(t *testing.T) {
	mockedAPI := SSMParameterApiImpl{}
	ssmHandler := SSMCustomResourceHandler{
		ssmClient: mockedAPI,
	}

	// Create new SSM parameter
	cfnEvent := cfn.Event{
		RequestType:        "Create",
		RequestID:          "xxx",
		ResponseURL:        "some-url-here",
		ResourceType:       "AWS::CloudFormation::CustomResource",
		PhysicalResourceID: "",
		LogicalResourceID:  "SSMCredentialTesting1",
		StackID:            "arn:aws:cloudformation:eu-central-1:9999999:stack/CustomResourcesGolang",
		ResourceProperties: map[string]interface{}{
			"ServiceToken": "arn:aws:lambda:eu-central-1:9999999:function:CustomResourcesGolang-Function",
			"key":          "/testing3",
			"value":        "some-secret-value",
		},
	}
	_, _, _ = ssmHandler.Create(context.TODO(), cfnEvent)

}

```


### Integration tests {#integration-tests}

I've used [AWS SAM](https://aws.amazon.com/de/serverless/sam/) to locally invoke the Lambda function created via CDK.  Make sure you have `aws-sam-cli` installed on your machine.

After the initial call `aws-sam` will first download the Docker image for your function:

```sh
...
Invoking /main (go1.x)
Local image was not found.
Removing rapid images for repo public.ecr.aws/sam/emulation-go1.x
...
```

Afterwards invoking the Lambda locally is quite easy:

```sh
$ cdk synth
$ sam local invoke -t cdk.out/CustomResourcesGolang.template.json GolangCustomResources
...
Mounting /home/victor/work/repos/aws-custom-resource-golang/deployments/cdk.out/asset.1ac1b002ba7d09e11c31702e1724d092e837796c2ed40541947abdfc6eb75947 as /var/task:ro,delegated, inside runt
ime container
2023/03/31 11:42:29 Starting lambda
2023/03/31 11:42:29 event: cfn.Event{RequestType:"", RequestID:"", ResponseURL:"", ResourceType:"", PhysicalResourceID:"", LogicalResourceID:"", StackID:"", ResourceProperties:map[string]in
terface {}(nil), OldResourceProperties:map[string]interface {}(nil)}
2023/03/31 11:42:29 sending status failed: Unknown resource type:
Put "": unsupported protocol scheme "": Error
null
{"errorMessage":"Put \"\": unsupported protocol scheme \"\"","errorType":"Error"}END RequestId: 93eed487-2441-4d41-a0b6-d939efeab99f
REPORT RequestId: 93eed487-2441-4d41-a0b6-d939efeab99f  Init Duration: 0.30 ms  Duration: 224.84 ms     Billed Duration: 225 ms Memory Size: 128 MB     Max Memory Used: 128 M
```

Of course you need to specify a payload to your function. You can store your payload (of type CloudFormation event) as a JSON file:

```sh
$ cat tests/create.json
{
  "RequestType": "Create",
  "RequestID": "9bf90339-c6f0-47ff-ad67-e19226facf6e",
  "ResponseURL": "https://some-url",
  "ResourceType": "AWS::CloudFormation::CustomResource",
  "PhysicalResourceID": "",
  "LogicalResourceID": "SSMCredential21D358858",
  "StackID": "arn:aws:cloudformation:eu-central-1:xxxxxxxxxxxx:stack/CustomResourcesGolang/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "ResourceProperties": {
    "ServiceToken": "arn:aws:lambda:eu-central-1:xxxxxxxxxxxx:function:CustomResourcesGolang-ProviderframeworkonEvent83C1-Dt9Jv3RwL9KT",
    "key": "/test/testing12345",
    "value": "some-secret-value"
  },
  "OldResourceProperties": {}
}
```

Then you can specify the JSON file

```sh
$ sam local invoke -t cdk.out/CustomResourcesGolang.template.json GolangCustomResources -e ../tests/create.json

Invoking /main (go1.x)
Local image is up-to-date
Using local image: public.ecr.aws/lambda/go:1-rapid-x86_64.

Mounting /home/victor/work/repos/aws-custom-resource-golang/deployments/cdk.out/asset.1ac1b002ba7d09e11c31702e1724d092e837796c2ed40541947abdfc6eb75947 as /var/task:ro,delegated, inside runt
ime container
START RequestId: cb8c7882-269c-434e-ace1-f6958940ee2e Version: $LATEST
2023/03/31 11:48:16 Starting lambda
2023/03/31 11:48:16 event: cfn.Event{RequestType:"Create", RequestID:"9bf90339-c6f0-47ff-ad67-e19226facf6e", ResponseURL:"https://some-file", ResourceType:"AWS::CloudFormation::CustomResour
ce", PhysicalResourceID:"", LogicalResourceID:"SSMCredential21D358858", StackID:"arn:aws:cloudformation:eu-central-1:xxxxxxxxxxxx:stack/CustomResourcesGolang/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxx", ResourceProperties:map[string]interface {}{"ServiceToken":"arn:aws:lambda:eu-central-1:xxxxxxxxxxxx:function:CustomResourcesGolang-ProviderframeworkonEvent83C1-Dt9Jv3RwL9KT", "key":
"/test/testing12345", "value":"some-secret-value"}, OldResourceProperties:map[string]interface {}{}}
2023/03/31 11:48:16 Creating SSM parameter
2023/03/31 11:48:16 Put parameter into SSM: /test/testing12345
Put "https://some-file": dial tcp: lookup some-file on 192.168.179.1:53: no such host: Error
null
END RequestId: cb8c7882-269c-434e-ace1-f6958940ee2e
REPORT RequestId: cb8c7882-269c-434e-ace1-f6958940ee2e  Init Duration: 0.13 ms  Duration: 327.24 ms     Billed Duration: 328 ms Memory Size: 128 MB     Max Memory Used: 128 MB
{"errorMessage":"Put \"https://some-file\": dial tcp: lookup some-file on 192.168.179.1:53: no such host","errorType":"Error"}%
```

This one fails coz I didn't specify any valid `ResponseURL`.


## Conclusion {#conclusion}

I think this approach opens a lot of possibilities to create advanced custom resources based on your needs. You could for example use custom resources to **deploy resources across multiple accounts**. For Security reasons you could **enforce several compliance policies** and monitor for compliance deviations. Or you could **use some 3rd-party APIs** to pass data back and forth (e.g. user management, product stocks etc.)

As you have control over the logic implemented in the AWS Lambda function and therefore define how your custom resources should be managed, the possibilities are endless. Have fun creating your own custom resources!


## Resources {#resources}


### General {#general}

-   2023-02-07 ◦ [aws-doc-sdk-examples/gov2 at main · awsdocs/aws-doc-sdk-examples · GitHub](https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/gov2)
-   2023-01-31 ◦ [CloudFormation needs physicalResourceId for custom-resources.AwsSdkCall when used in custom-resources.AwsCustomResource as onDelete property · Issue #5796 · aws/aws-cdk · GitHub](https://github.com/aws/aws-cdk/issues/5796)
-   2023-01-20 ◦ [Create AWS Custom Resources in Go | by Mo Asgari | Medium](https://medium.com/@mo.asgari/creating-aws-custom-resources-in-go-2e128cacb964)
-   2023-01-20 ◦ [github.com/aws-cdk-examples/typescript/custom-resource](https://github.com/aws-samples/aws-cdk-examples/tree/master/typescript/custom-resource)


### Security {#security}

-   2023-04-06 ◦ [Welcome to the Jungle: Pentesting AWS](https://www.slideshare.net/MichaelFelch/welcome-to-the-jungle-pentesting-aws)


### Golang {#golang}

-   2023-02-08 ◦ [Unit Testing with the AWS SDK for Go V2 | AWS SDK for Go V2](https://aws.github.io/aws-sdk-go-v2/docs/unit-testing/)
