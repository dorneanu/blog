+++
title = "Implement an access key rotator"
author = ["Victor Dorneanu"]
date = 2021-04-25T00:00:00+02:00
lastmod = 2021-04-25T11:29:13+02:00
tags = ["golang", "architecture", "aws", "github"]
draft = false
+++

## Introduction {#introduction}

With the recent success of [Github actions](https://docs.github.com/en/actions/learn-github-actions) you can automate lots of things whenever something in your repos changes, e.g. automatically generate static HTML content (using [hugo](/tags/hugo)) and push it to some repository for which GitHub Pages has been configured. Check this [awesome actions](https://github.com/sdras/awesome-actions) list for more use cases.

Using [encrypted secrets](https://docs.github.com/en/actions/reference/encrypted-secrets) defined either per repository or organization, you can bring your Github workflow to the next level: Authenticate against APIs, login to different services while keeping your secrets/credentials away from your repositories. As a general you should **never** store credentials in your repositories, even
if they're private. Misconfigurations happen all the time and private repos can become public ones without further notice.

In this post I want to show the [Golang](/tags/golang) way how to update Github **secrets** in some repository. These secrets (more concrete an `AWS IAM access key ID` and an `AWS IAM access secret key`) should be used to interact with [AWS](/tags/aws). Rotating these keys regularly is essential and also part of the [AWS access keys best practices](https://docs.aws.amazon.com/general/latest/gr/aws-access-keys-best-practices.html).

{{% notice tip %}}
Make sure you also check [github.com/dorneanu/access-key-rotator](https://github.com/dorneanu/access-key-rotator) for the complete project.
{{% /notice %}}


## Clean architecture {#clean-architecture}

I'm obsessed with clean code, clean architecture and almost everything that has an easy to understand structure.
First of all I'll start with the `use cases` which describe what the application is capabable of doing. In our case we have

-   Rotate keys
    -   Given a `key manager` the existing access keys will be rotated
-   Upload secrets
    -   using a `secrets store` we'll upload the **encrypted** access key to some storage for later usage

The `KeyManager` and the `SecretsStore` are interfaces to be implemented by different service providers. What the both have in common is the
`AccessKey` data structure which holds everything we need to know about an access key.

{{< figure src="/posts/img/2021/key-rotator-interfavces-entities.png" caption="Figure 1: Interfaces using entities" >}}

Now that we have defined the general application design, let's go more into details and see which components have to implement the declared interfaces:

-   `KeyManager`
    -   a key manager is something that holds/stores your access keys and provides functionalities (CRUD: create, read, update, delete) in order to manage those
    -   examples: AWS IAM, Google Cloud IAM, Azure IAM
-   `SecretsStore`
    -   something that stores your access keys in a secure manner
    -   examples: GitHub Secrets, Gitlab Secrets, LastPass
-   `ConfigStore`
    -   something related to a parameter store
    -   examples: AWS SecretsManager, Google Cloud Secret Manager

Each of these components (using 3rd-party libraries etc.) will need to implement the correspondig interface.

{{< figure src="/posts/img/2021/key-rotator.png" caption="Figure 2: Components implementing interfaces" >}}


## AWS Golang SDK v2 {#aws-golang-sdk-v2}

I'll be using the latest Golang SDK which is [v2](https://github.com/aws/aws-sdk-go-v2). In order to manage the [IAM access](https://aws.github.io/aws-sdk-go-v2/docs/code-examples/iam/) keys we're going to need these endpoints:

-   list all available access keys using [ListAccessKeysV2](https://aws.github.io/aws-sdk-go-v2/docs/code-examples/iam/listaccesskeys/)
-   generate new IAM access key using [CreateAccessKeyv2](https://aws.github.io/aws-sdk-go-v2/docs/code-examples/iam/createaccesskey/)
-   delete old access keys using [DeleteAccessKeyv2](https://aws.github.io/aws-sdk-go-v2/docs/code-examples/iam/deleteaccesskey/)

In order the make the code more **testable** I'll be using an **interface** called `IAMAPI` which should contain all methods an IAM API real implementation
should provide. Generating mocks should be then also an easy task as described in [Unit Testing with the AWS SDK for Go V2](https://aws.github.io/aws-sdk-go-v2/docs/unit-testing/).

```go
type IAMAPI interface {
	ListAccessKeys() ...
	CreateAccessKey() ...
	DeleteAccessKey() ...
}
```

Additionally I'll use an own `Configuration` type meant to hold all information my applications needs. I find [github.com/kelseyhightower/envconfig](https://github.com/kelseyhightower/envconfig) to be quite
handy when you have to deal with **environment** variables:

```go
// Config holds all relevant information for this application to run
type Config struct {
	IAM_User   string `envconfig:"IAM_USER", required:"true"`
	AWS_REGION string `envconfig:"AWS_REGION" required:"true"`
	...
}
```


### List/Fetch all available IAM keys {#list-fetch-all-available-iam-keys}

First of all let's list all available IAM access keys.

```go
package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/kelseyhightower/envconfig"
)

// Config holds all relevant information for this application to run
type Config struct {
	IAM_User   string `envconfig:"IAM_USER", required:"true"`
	AWS_REGION string `envconfig:"AWS_REGION" required:"true"`
}

// We'll define an interface fot the IAM API in order to make testing easy
// This interface will be extended as we go through the different steps
type IAMAPI interface {
	ListAccessKeys(ctx context.Context, params *iam.ListAccessKeysInput, optFns ...func(*iam.Options)) (*iam.ListAccessKeysOutput, error)
}

// ListAccessKeys retrieves the IAM access keys for an user
func ListAccessKeys(c context.Context, api IAMAPI, username string) (*iam.ListAccessKeysOutput, error) {
	input := &iam.ListAccessKeysInput{
		MaxItems: aws.Int32(int32(10)),
		UserName: &username,
	}
	return api.ListAccessKeys(c, input)
}

// loadConfig will return an instance of Config
func loadConfig() *Config {
	var c Config
	err := envconfig.Process("", &c)
	if err != nil {
		log.Fatal(err.Error())
	}
	return &c
}

func main() {
	// Get configuration
	c := loadConfig()

	// Initialize AWS
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		panic("configuration error, " + err.Error())
	}

	// Create new IAM client
	iam_client := iam.NewFromConfig(cfg)
	result, err := ListAccessKeys(context.TODO(), iam_client, c.IAM_User)
	if err != nil {
		fmt.Println("Got an error retrieving user access keys:")
		fmt.Println(err)
		return
	}

	// Print available IAM access keys
	for _, key := range result.AccessKeyMetadata {
		fmt.Println("Status for access key " + *key.AccessKeyId + ": " + string(key.Status))
	}
}
```

```text
Status for access key AKIAWSIW5AN47M5YY72J: Active
```

As you can see there is an IAM access key with the ID `AKIAWSIW5AN47M5YY72J` and it's active.


### Generate new IAM access key {#generate-new-iam-access-key}

In the next step we'll generate a new pair of access key. Therefore we'll extend the `IAMAPI` interface with a 2nd method:

```go
type IAMAPI interface {
	ListAccessKeys(ctx context.Context, params *iam.ListAccessKeysInput, optFns ...func(*iam.Options)) (*iam.ListAccessKeysOutput, error)
	CreateAccessKey(ctx context.Context, params *iam.CreateAccessKeyInput, optFns ...func(*iam.Options)) (*iam.CreateAccessKeyOutput, error)
}
```

Creating a new key pair should also be straght forwards:

```go
// CreateAccessKey will create a new IAM access key for a specified user
func CreateAccessKey(c context.Context, api IAMAPI, username string) (*iam.CreateAccessKeyOutput, error) {
	input := &iam.CreateAccessKeyInput{
		UserName: &username,
	}
	return api.CreateAccessKey(c, input)
}
```

And then in the `main()` we add:

```go
	// Create new IAM access key
	new_key, err := CreateAccessKey(context.TODO(), iam_client, c.IAM_User)
	if err != nil {
		fmt.Println("Couldn't create new key: " + err.Error())
		return
	}

	// Print new key
	fmt.Println("Created new access key with ID: " + *new_key.AccessKey.AccessKeyId + " and secret key: " + *new_key.AccessKey.SecretAccessKey)
```

And if we run it, we'll get the new key id and the secret key:

```text
...
Created new access key with ID: AKIAWSIW5AN46DT2ENLL and secret key: ****************************************
```


### Delete old access key {#delete-old-access-key}

We'll extend the `IAMAPI` interface again:

```go
type IAMAPI interface {
	ListAccessKeys(ctx context.Context, params *iam.ListAccessKeysInput, optFns ...func(*iam.Options)) (*iam.ListAccessKeysOutput, error)
	CreateAccessKey(ctx context.Context, params *iam.CreateAccessKeyInput, optFns ...func(*iam.Options)) (*iam.CreateAccessKeyOutput, error)
	DeleteAccessKey(ctx context.Context, params *iam.DeleteAccessKeyInput, optFns ...func(*iam.Options)) (*iam.DeleteAccessKeyOutput, error)
}
```

The `DeleteAccessKey` will also need an `access key ID` and an `username`:

```go
// DeleteAccessKey disables and removes an IAM access key
func DeleteAccessKey(c context.Context, api IAMAPI, keyID, username string) (*iam.DeleteAccessKeyOutput, error) {
	input := &iam.DeleteAccessKeyInput{
		AccessKeyId: &keyID,
		UserName:    &username,
	}
	return api.DeleteAccessKey(c, input)
}
```

For this example we'll just delete the previously created IAM access key:

```go
	// Delete key
	_, err = DeleteAccessKey(
		context.TODO(),
		iam_client,
		*new_key.AccessKey.AccessKeyId,
		c.IAM_User,
	)
	if err != nil {
		fmt.Println("Couldn't delete key: " + err.Error())
		return
	}
	fmt.Printf("Deleted key: %s\n", *new_key.AccessKey.AccessKeyId)
```


## Github setup {#github-setup}

The Github implementation will have to satisfy the `SecretsStore` interface:

```golang
type SecretsStore interface {
	EncryptKey(context.Context, entity.AccessKey) (*entity.EncryptedKey, error)
	ListSecrets(context.Context) ([]entity.AccessKey, error)
	CreateSecret(context.Context, entity.EncryptedKey) error
	DeleteSecret(context.Context, entity.EncryptedKey) error
}
```


### SecretsStore implementation {#secretsstore-implementation}

As we have done with **AWS** we'll try to decouple everything and have less cohesion. This will make every part of our code testable.
The `GithubSecretsStore` (implementing `SecretsStore`) will look like this:

```golang
type GithubSecretsStore struct {
	repo_owner    string
	repo_name     string
	secretsClient GithubSecretsService
}
```


### Make secrets service abstract {#make-secrets-service-abstract}

The `secretsClient` is a **service** that allows us to create, upload and delete secrets using [Github's Secrets API](https://docs.github.com/en/rest/reference/actions#secrets). The `GithubSecretsService`
will have following definition (make sure to have a look at the methods provided by the [ActionsService](https://pkg.go.dev/github.com/google/go-github/v32/github#ActionsService)):

```golang
type GithubSecretsService interface {
	GetRepoPublicKey(ctx context.Context, owner, repo string) (*github.PublicKey, *github.Response, error)
	CreateOrUpdateRepoSecret(ctx context.Context, owner, repo string, eSecret *github.EncryptedSecret) (*github.Response, error)
	ListRepoSecrets(ctx context.Context, owner, repo string, opts *github.ListOptions) (*github.Secrets, *github.Response, error)
	DeleteRepoSecret(ctx context.Context, owner, repo, name string) (*github.Response, error)
}
```

This way we can create a `GithubSecretsStore` with a mocked version of `GithubSecretsService`. But there is still something missing. Of course, the `Github client` itself:

```golang
type GithubClient struct {
	client *github.Client
}
```


### Use a real Github client {#use-a-real-github-client}

And how does this structure fit together with the **service** and the **store**? Following _constructor_ should provide the answer:

```golang
func NewGithubClient(accessToken string) GithubSecretsService {
	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: accessToken},
	)
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)
	return client.Actions
}
```

Here I initialize a new `github.Client` by using an OAUTH2 token. Afterwards I return `client.Actions` which btw satisfies the `GithubSecretsService` interface. Now let's code a constructor for the `GithubSecretsStore`:

```golang
func NewGithubSecretsStore(secretsService GithubSecretsService, repoOwner, repoName string) *GithubSecretsStore {
	return &GithubSecretsStore{
		secretsClient: secretsService,
		repo_owner:    repoOwner,
		repo_name:     repoName,
	}
}
```

Here `NewGithubSecretsStore` expects a `GithubSecretsService` and some other additional information (repository owner/name). As the [ Liskow Substitution Principle](https://brainfck.org/#LSP) says:

> Express dependencies between packages in terms of interfaces and not concrete types

in `NewGithubSecretsStore` we don't expect an `ActionsService` as it is returned by `github.Client.Actions`. So, in order to glue everything together we'll have to

-   first create a concrete implementation of `GithubSecretsService`
-   and then create a new `GithubSecretsStore` with that concrete implementation

So in the real code this will look like this:

```golang
accessToken, err := configStore.GetValue(context.Background(), "github-token")
if err != nil {
    log.Fatalf("Unable to get value from config store: %s", err)
}
githubSecretsClient := s.NewGithubClient(accessToken)
secretsStore = s.NewGithubSecretsStore(githubSecretsClient, settings.RepoOwner, settings.RepoName)
```


## Conclusion {#conclusion}

Setting up a project with clean code in mind is not an easy task. You have to abstract things
and always keep in mind:

> How can you know your code works? That’s easy. Test it. Test it again. Test it up. Test it down. Test it seven ways to Sunday -- [ Source](https://brainfck.org/bib.html#The%20Clean%20Code%20-%20Note%208)

And how do you make sure your code is _testable_? By using abstractions instead of concrete implementations and making each single part of your code _mockable_ aka testable.
