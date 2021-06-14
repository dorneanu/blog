+++
title = "Golang"
author = ["Victor Dorneanu"]
lastmod = 2021-05-11T10:28:54+02:00
tags = ["bookmark", "golang"]
draft = false
weight = 2001
toc = true
+++

## Microservices {#microservices}

-   [Building a global services network using Go, QUIC and Micro](https://blog.gopheracademy.com/advent-2019/building-a-microservices-network)
-   [Microservices on Go with the Go Kit](https://sudonull.com/post/8187-Microservices-on-Go-with-the-Go-kit-Introduction)
-   [How I'm writing Serverless services in Golang](https://ewanvalentine.io/how-im-writing-serverless-services-in-golang-these-days/)

    > Service discovery allows you to register the location of services, with a user
    > friendly name, so that you can find other services by name. AWS provides a
    > Serverless offering for this, called [Cloudmap](https://aws.amazon.com/cloud-map/)

    [cloud application library](https://github.com/peak-ai/ais-service-discovery-go)

    > The most important lesson I hope you take away from this, however, is protecting your business logic from the sea of AWS services and technologies. Treat Lambda as an unimportant detail, treat DynamoDB as an unimportant detail
-   [Building a global services network using Go, QUIC and Micro](https://blog.gopheracademy.com/advent-2019/building-a-microservices-network/)
-   [Make resilient Go net/http servers using timeouts, deadlines and context cancellation](https://ieftimov.com/post/make-resilient-golang-net-http-servers-using-timeouts-deadlines-context-cancellation/)
    Initialize `net/http` server with timeouts:

    ```nil
          srv := &http.Server{
              ReadTimeout:       1 * time.Second,
              WriteTimeout:      1 * time.Second,
              IdleTimeout:       30 * time.Second,
              ReadHeaderTimeout: 2 * time.Second,
              TLSConfig:         tlsConfig,
              Handler:           srvMux,
          }
    ```

    -   the `net/http` packages provide a `TimeoutHandler`
    -   it returns a handler that runs a handler within the given time limit
    -   use `Context` to be aware of request
-   [A clean way to pass configs in a Go application](https://dev.to/ilyakaznacheev/a-clean-way-to-pass-configs-in-a-go-application-1g64)


## AppSec {#appsec}

-   [Implementing JWT based authentication in Golang](https://www.sohamkamani.com/blog/golang/2019-01-01-jwt-authentication/)


### Beyondcorp {#beyondcorp}

-   [ory.sh](https://github.com/ory)

    > ORY is the open source and cloud native identity infrastructure. ORY is written
    > in Go and open standards and consensus are the foundation. It is language and
    > platform independent, extremely lightweight, starts up in seconds and doesn’t
    > interfere with your code
    >
    > Inspired by Google's BeyondCorp


#### <span class="org-todo todo TODO">TODO</span> [ory ecosystem](https://www.ory.sh/docs/next/ecosystem/projects) {#ory-ecosystem}


## AWS {#aws}

-   [API Gateway Authorizer Blueprint in Golang](https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/blob/master/blueprints/go/main.go)
-   [API Gateway Custom Authorizer](https://cloudnative.ly/lambdas-with-golang-a-technical-guide-6f381284897b)
-   [A simple AWS API Gateway Authoriser in Go](https://dev.to/wingkwong/a-simple-amazon-api-gateway-lambda-authoriser-in-go-4cgd)
-   [expressive DynamoDB library for Go](https://github.com/guregu/dynamo)


### CDK {#cdk}

-   [Getting started with CDK and Golang](https://aws.amazon.com/blogs/developer/getting-started-with-the-aws-cloud-development-kit-and-go/)
-   [Using AWS CDK to configure deploy a Golang Lambda with API Gateway](https://blog.john-pfeiffer.com/using-aws-cdk-to-configure-deploy-a-golang-lambda-with-apigateway/)


## Books {#books}

-   [List of interesting Golang Books](https://github.com/dariubs/GoBooks)


## Configuration {#configuration}


### Spacemacs {#spacemacs}

Pre-requisites to use the [go-layer](https://develop.spacemacs.org/layers/+lang/go/README.html) inside `spacemacs`:

```nil
GO111MODULE=on go get -v golang.org/x/tools/gopls@latest
GO111MODULE=on CGO_ENABLED=0 go get -v -trimpath -ldflags '-s -w' github.com/golangci/golangci-lint/cmd/golangci-lint
go get -u -v golang.org/x/tools/cmd/godoc
go get -u -v golang.org/x/tools/cmd/goimports
go get -u -v golang.org/x/tools/cmd/gorename
go get -u -v golang.org/x/tools/cmd/guru
go get -u -v github.com/cweill/gotests/...
go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct
go get -u -v github.com/fatih/gomodifytags
go get -u -v github.com/godoctor/godoctor
go get -u -v github.com/haya14busa/gopkgs/cmd/gopkgs
go get -u -v github.com/josharian/impl
go get -u -v github.com/mdempsky/gocode
go get -u -v github.com/rogpeppe/godef
go get -u -v github.com/zmb3/gogetdoc
```


### doom emacs {#doom-emacs}

-   [Ladicle Golang Doom Emacs customizations](https://qiita.com/Ladicle/items/feb5f9dce9adf89652cf)


### GTAGS {#gtags}

`gtags` will create `CTAGS` files to [global](https://www.gnu.org/software/global/). For Go you can use [gogtags](https://github.com/juntaki/gogtags) to
generate the files. It also works well with [helm-gtags](https://melpa.org/#/helm-gtags).


## Code Examples {#code-examples}

-   [l3x.github.io/golang-code-examples/](http://l3x.github.io/golang-code-examples/)


## Code Style {#code-style}

-   [Cleaner go code with golines](https://yolken.net/blog/cleaner-go-code-golines)
-   [Effective Go (golang.org)](https://golang.org/doc/effective%5Fgo)
-   [Darker Corners of Go](https://rytisbiel.com/2021/03/06/darker-corners-of-go/)
    -   covers most of the 101 topics beginners should know about Golang


### Clean Code Examples {#clean-code-examples}

-   [github.com/ahmetb/kubectx](https://github.com/ahmetb/kubectx)
-   [github.com/gojek/heimdall](https://github.com/gojek/heimdall)
-   [github.com/ethereum/go-ethereum](https://github.com/ethereum/go-ethereum)
-   [github.com/drone/drone](https://github.com/drone/drone)
-   [github.com/google/exposure-notifications-server](https://github.com/google/exposure-notifications-server)


## Design {#design}

-   [SOLID Go Design](https://dave.cheney.net/2016/08/20/solid-go-design)
-   [The Zen of Go](https://the-zen-of-go.netlify.com/)
    -   [more detailed version](https://dave.cheney.net/2020/02/23/the-zen-of-go)
-   [Design Patterns by refactoring.guru](https://github.com/RefactoringGuru/design-patterns-go)
-   [Hexagonal Architecture in Go](https://medium.com/@matiasvarela/hexagonal-architecture-in-go-cfd4e436faa3)


## Fun {#fun}

-   [Evolution of a Go programmer](https://github.com/SuperPaintman/the-evolution-of-a-go-programmer)


## Internals {#internals}

-   [A recap of request handling in Go](https://www.alexedwards.net/blog/a-recap-of-request-handling)
-   [Diving deep into net/http : A look at http.RoundTripper](https://lanre.wtf/blog/2017/07/24/roundtripper-go/)
-   [Dissecting golang's HandlerFunc, Handle and DefaultServeMux](https://echorand.me/posts/golang-dissecting-listen-and-serve/)
-   [Requests richtig verarbeiten: Keine Sorge beim Multiplexen in Go](https://jaxenter.de/golumne-go-requests-multiplexen-81161)
-   [How to handle signals with Go to graceful shutdown HTTP server](https://rafallorenz.com/go/handle-signals-to-graceful-shutdown-http-server/)
-   [Life of an HTTP request in a Go server - Eli Bendersky's website](https://eli.thegreenplace.net/2021/life-of-an-http-request-in-a-go-server/)


### Context {#context}

-   [Contexts and structs](https://blog.golang.org/context-and-structs)

    > Context provides a means of transmitting deadlines, caller cancellations, and other request-scoped values across API boundaries and between processes. It is often used when a library interacts --- directly or transitively --- with remote servers, such as databases, APIs
    >
    > When designing an API with context, remember the advice: pass `context.Context` in as an argument; don't store it in structs.

-   [How to use context in different uses cases](https://steveazz.xyz/blog/import-context/)


## Interviews {#interviews}

-   [2020-05 | Rob Pike interview for Evrone: “Go has become the language of cloud infrastructure”](https://evrone.com/rob-pike-interview%20%20%20%20)


## Messaging {#messaging}


### Bots {#bots}


#### Slack {#slack}

-   [slack-go/slack examples](https://github.com/slack-go/slack/tree/master/examples)
-   [Create a Slack bot using Golang](https://blog.gopheracademy.com/advent-2017/go-slackbot/)
-   [Write an interactive message bot for Slack in Golang](https://medium.com/mercari-engineering/writing-an-interactive-message-bot-for-slack-in-golang-6337d04f36b9)
    -   full code: [go-slack-interactive](https://github.com/tcnksm/go-slack-interactive)
-   [bot tokens](https://api.slack.com/docs/token-types#bot)
-   [slack-message-builder](http://davestevens.github.io/slack-message-builder/)
-   [message attachments](https://api.slack.com/messaging/composing/layouts#attachments)
-   [block kit builder](https://api.slack.com/tools/block-kit-builder)
-   **Frameworks**
    -   [github.com/shomali11/slacker](https://github.com/shomali11/slacker)
-   [github.com/go-chat-bot/bot](https://github.com/go-chat-bot/bot)
    -   IRC, SLACK, Telegram and RocketChat bot written in Go
-   [github.com/alexandre-normand/slackscot](https://github.com/alexandre-normand/slackscot)
    -   Slack bot core/framework written in Go with support for reactions to message updates/deletes


## Malware {#malware}

-   [Blackrota, a heavily obfuscated backdoor written in Go](https://blog.netlab.360.com/blackrota-an-obfuscated-backdoor-written-in-go-en/amp/)


## Modules {#modules}

-   [How I Structure Go Packages](https://bencane.com/stories/2020/07/06/how-i-structure-go-packages/)
    Some great advice about logging and package structure
-   [Go best practices, 6 years in](https://peter.bourgon.org/go-best-practices-2016/#repository-structure)


## Testing {#testing}

-   [Learn go with test-driven development (TDD)](https://github.com/quii/learn-go-with-tests)
-   [Testing Go services using interfaces (deliveroo)](https://deliveroo.engineering/2019/05/17/testing-go-services-using-interfaces.html)
-   [Building and Testing a REST API in GoLang using Gorilla Mux and MySQL](https://medium.com/@kelvin%5Fsp/building-and-testing-a-rest-api-in-golang-using-gorilla-mux-and-mysql-1f0518818ff6)
-   [Testing with GoMock: A Tutorial - codecentric AG Blog](https://blog.codecentric.de/en/2017/08/gomock-tutorial/)
-   [GoMock vs. Testify: Mocking frameworks for Go](https://blog.codecentric.de/2019/07/gomock-vs-testify/)
    -   learn how to use `mockery` and `testify`
    -   3 classes fo failures:
        -   Unexpected calls
        -   Missing calls (expected, but not occurred)
        -   Expected calls with unexpected parameter values
-   [Golang basics - writing unit tests](https://blog.alexellis.io/golang-writing-unit-tests/)
-   [Testing HTTP Handlers in Go](https://lanre.wtf/blog/2017/04/08/testing-http-handlers-go/)
-   [Testing Clients to an HTTP API in Go](https://mkaz.blog/code/testing-clients-to-an-http-api-in-go/)
-   [Writing good unit tests for SOLID go](https://blog.gopheracademy.com/advent-2016/how-to-write-good-tests-for-solid-code/)
    -   structs will depend on interfaces instead of structs (easy for dependency injection)
    -   What should be tested:
        -   when testing, you can think of it as sending and receiving messages
        -   **incoming messages** refer to calls to methods
        -   **outgoing messages** refers to calls from the tested object on its dependencies
    -   most people go first to integration tests
-   [Testing Go at Stream](https://getstream.io/blog/how-we-test-go-at-stream/)
-   [Using Go Interfaces for Testable Code - The Startup - Medium](https://medium.com/swlh/using-go-interfaces-for-testable-code-d2e11b02dea)
    -   using interfaces for stubbing
-   [2020-05 | How I write my unit tests in Go quickly](https://dev.to/ilyakaznacheev/how-i-write-my-unit-tests-in-go-quickly-4bd5)
    -   on dependency injection
    -   duck typing interfaces
    -   BDD (Behaviour Driven Development)


### Fuzzing {#fuzzing}

-   [Go: Fuzz Testing in Go - A Journey With Go](https://medium.com/a-journey-with-go/go-fuzz-testing-in-go-deb36abc971f)


### TDD {#tdd}

-   More on [TDD](#tdd)

Great resources:

-   [github.com/quii/learn-go-with-tests](//github.com/quii/learn-go-with-tests)
-   [leanpub.com/golang-tdd/read](https://leanpub.com/golang-tdd/read)
    -   really good explanations


## Tools {#tools}

-   [An overview of Go's tooling](https://www.alexedwards.net/blog/an-overview-of-go-tooling)
-   [Emacs and Go mode](https://arenzana.org/2019/01/emacs-go-mode/)
-   [gojson](https://github.com/ChimeraCoder/gojson): Automatically generate Go (golang) struct definitions from example JSON
-   [golang.org/x/tools](https://godoc.org/golang.org/x/tools)
    -   [go-guru](http://golang.org/s/using-guru)
-   [go-spew](https://github.com/davecgh/go-spew): Implements a deep pretty printer for Go data structures to aid in debugging
-   [godocgen](https://zoralab.gitlab.io/godocgen/en-us/)

    > Godocgen is an app built using Go programming language to generate Go module
    > package's documentations. It parses the packages documentation data and
    > facilitates custom rendering, enabling Gopher to use other hosting solution
    > like Hugo to host the documents.
-   [3mux](https://github.com/aaronjanse/3mux): Terminal multiplexer inspired by i3
-   [tspur](https://github.com/jumbleview/tspur): Terminal Screen with Protected User Records (TSPUR)
-   [json-to-go](https://mholt.github.io/json-to-go/)
    -   This tool instantly converts JSON into a Go type definition


## Templates {#templates}

-   [Using go templates](https://blog.gopheracademy.com/advent-2017/using-go-templates/)


## Logging {#logging}

-   [About Go logging for reusable packages](https://www.0value.com/about-go-logging)

    Use some global variadic function:

    ```go
          package mypkg

          // LogFunc is a function that logs the provided message with optional
          // fmt.Sprintf-style arguments. By default, logs to the default log.Logger.
          var LogFunc func(string, ...interface{}) = log.Printf
    ```

-   [Some words about logging](https://www.reddit.com/r/golang/comments/em8uiu/how%5Fto%5Fstart%5Fwith%5Flogging%5Fin%5Fgo%5Fprojects%5Fpart%5F2/)
    -   Some tips:
        -   Never log in a package that isn't main
        -   Don't log things if the program is operating normally
        -   only log in package main

-   [Let's talk about logging](https://dave.cheney.net/2015/11/05/lets-talk-about-logging)
-   [go-kit/log](https://github.com/go-kit/kit/tree/master/log)


## OO {#oo}

-   [Object Oriented Go - The Basics](https://icyapril.com/go/programming/2017/12/17/object-orientation-in-go.html)


## Packaging {#packaging}

-   [Zombie Zen - How I packaged a Go program for Windows and Linux](https://www.zombiezen.com/blog/2020/09/how-i-packaged-go-program-windows-linux/)
-   [Packages as layers, not groups](https://www.gobeyond.dev/packages-as-layers/amp/)
    -   How to think of your modules as layers and not as groups
    -   by Ben Johnson (wo wrote the [standard package layout](https://medium.com/@benbjohnson/standard-package-layout-7cdbc8391fc1))
-   [How to Structure a Go Command-Line Project](https://bencane.com/2020/12/29/how-to-structure-a-golang-cli-project/)
-   [Go best practices, six years in](https://peter.bourgon.org/go-best-practices-2016/#repository-structure)


## Serialization {#serialization}

-   [Custom JSON Marshalling in Go](http://choly.ca/post/go-json-marshalling/)

    -   Nice elegant solution using aliases, e.g.

    <!--listend-->

    ```go
          func (u *MyUser) MarshalJSON() ([]byte, error) {
            type Alias MyUser
            return json.Marshal(&struct {
              LastSeen int64 `json:"lastSeen"`
              *Alias
            }{
              LastSeen: u.LastSeen.Unix(),
              Alias:    (*Alias)(u),
            })
          }
    ```
-   [Golang JSON Serialization With Interfaces](http://gregtrowbridge.com/golang-json-serialization-with-interfaces/)
    -   Working with plants and animals
    -   adds extra field `type` to know which struct to use
-   [Is there a way to have json.Unmarshal() select struct type based on “type” property?](https://stackoverflow.com/questions/42721732/is-there-a-way-to-have-json-unmarshal-select-struct-type-based-on-type-prope)
    -   how to do deserialization when field is a list of interfaces
    -   implement `UnmarshalJSON` on slice of interfaces
    -   [Example with []vehicle](https://play.golang.org/p/zQyL0JeB3b)


## Security {#security}

-   [Security assessment techniques for go projects](https://blog.trailofbits.com/2019/11/07/attacking-go-vr-ttps/)
    -   static analysis, fuzzing, dynamic testing etc.
-   [CSRF Attacks](https://goteleport.com/blog/csrf-attacks/)
    -   Implementing CSRF, auth handler


### Pentest {#pentest}

-   [github.com/sysdream/hershell](https://github.com/sysdream/hershell)
-   [github.com/sysdream/chashell](https://github.com/sysdream/chashell)
    -   using DNS as reverse shell
-   [github.com/sysdream/ligolo](https://github.com/sysdream/ligolo)


### Botnets {#botnets}

-   [github.com/gnxbr/Unbreakable-Botnet-C2](https://github.com/gnxbr/Unbreakable-Botnet-C2)
    -   using Blockchains for communication channel


### Scanners {#scanners}

-   [github.com/v-byte-cpu/sx](https://github.com/v-byte-cpu/sx)


## Surveys {#surveys}

-   [State of Go in 2021](https://blog.jetbrains.com/go/2021/02/03/the-state-of-go/)


## UI {#ui}

-   [Vugu](https://www.vugu.org/)
    -   A modern UI library for Go+WebAssembly
