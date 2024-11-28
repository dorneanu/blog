+++
title = "Mastering Golang Debugging in Emacs"
author = ["Victor Dorneanu"]
date = 2024-11-28
lastmod = 2024-11-28T07:04:01+01:00
tags = ["debug", "emacs", "golang"]
draft = false
+++

## Introduction {#introduction}

Since I've started developing in Golang I didn't really use the _debugger_. Instead I was
naively adding `fmt.Print` statements everywhere to validate my code 🙈. While print
statements and logs might be also your first debugging instinct, they often fall short
when dealing with large and complex code base, with sophisticated runtime behaviour and
(of course!) complex concurrency issues that seem impossible to reproduce.

After starting working on more complex projects
{{% sidenote %}}
Like this one: <https://github.com/cloudoperators/heureka>
{{% /sidenote %}} I had to force myself to have a deeper look at `delve` (the Golang debugger) and
see what Emacs offers for interacting with it. While the Go ecosystem offers
excellent debugging tools, integrating them into a comfortable development
workflow can be challenging.

In this post I'll elaborate the powerful combination of [Emacs](https://brainfck.org/t/Emacs),
[Delve](https://github.com/go-delve/delve), and [dape](https://github.com/svaante/dape). Together, these tools create a debugging experience that mimics
(and often surpasses) traditional IDEs, while preserving the flexibility and
extensibility that Emacs is famous for.

This is what you can expect:

-   Set up and configure [Delve](https://github.com/go-delve/delve) with [dape](https://github.com/svaante/dape)
-   Debug both standard applications and [Ginkgo](https://github.com/onsi/ginkgo) tests (this is what I'm using at
    the moment 🤷)
-   Optimize your debugging workflow with Emacs specific customizations


## Setting Up the Development Environment {#setting-up-the-development-environment}

In this post I assume you already have some Emacs experience and now how to configure
packages and write small `Elisp` snippets. I personally use [straight.el](https://github.com/radian-software/straight.el) as a package
manager, [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d) as a minimal vanilla Emacs configuration (along with my own
[custommizations)](https://github.com/dorneanu/dotfiles/blob/master/minimal-emacs/config.org), [dape](https://github.com/svaante/dape) as the debug adapter client and [eglot](https://github.com/joaotavora/eglot) as my _LSP client_.


### Required Emacs Packages {#required-emacs-packages}

For Emacs 29+ users, `eglot` is built-in.
{{% sidenote %}}
Check out [configuring eglot for gopls](https://github.com/golang/tools/blob/master/gopls/doc/emacs.md#configuring-eglot) and some more advanced [gopls settings](https://github.com/golang/tools/blob/master/gopls/doc/settings.md).
{{% /sidenote %}} We'll first add `dape`:

```elisp
(use-package dape
  :straight t
  :config
  ;; Pulse source line (performance hit)
  (add-hook 'dape-display-source-hook 'pulse-momentary-highlight-one-line)

  ;; To not display info and/or buffers on startup
  ;; (remove-hook 'dape-start-hook 'dape-info)
  (remove-hook 'dape-start-hook 'dape-repl))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Configure dape
</div>

and `go-mode`:

```elisp
(use-package go-mode
  :straight t
  :mode "\\.go\\'"
  :hook ((before-save . gofmt-before-save))
  :bind (:map go-mode-map
              ("M-?" . godoc-at-point)
              ("M-." . xref-find-definitions)
              ("M-_" . xref-find-references)
              ;; ("M-*" . pop-tag-mark) ;; Jump back after godef-jump
              ("C-c m r" . go-run))
  :custom
  (gofmt-command "goimports"))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  Configure go-mode
</div>


### Installing Required Go Tools {#installing-required-go-tools}

Install Delve and [gopls](https://pkg.go.dev/golang.org/x/tools/gopls), the LSP server:

```bash
# Install Delve
go install github.com/go-delve/delve/cmd/dlv@latest

# Install gopls
go install golang.org/x/tools/gopls@latest
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3:</span>
  Install the Golang debugger and LSP server
</div>

Additionally I have a bunch of other tools which I use from time to time:

```shell
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/onsi/ginkgo/v2/ginkgo@latest

go install -v golang.org/x/tools/cmd/godoc@latest
go install -v golang.org/x/tools/cmd/goimports@latest
go install -v github.com/stamblerre/gocode@latest
go install -v golang.org/x/tools/cmd/gorename@latest
go install -v golang.org/x/tools/cmd/guru@latest
go install -v github.com/cweill/gotests/...@latest

go install -v github.com/davidrjenni/reftools/cmd/fillstruct@latest
go install -v github.com/fatih/gomodifytags@latest
go install -v github.com/godoctor/godoctor@latest
go install -v github.com/haya14busa/gopkgs/cmd/gopkgs@latest
go install -v github.com/josharian/impl@latest
go install -v github.com/rogpeppe/godef@latest
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4:</span>
  Additional Golang tools
</div>

Then you need to configure the corresponding Emacs packages:

```elisp
(use-package ginkgo
  :straight (:type git :host github :repo "garslo/ginkgo-mode")
  :init
  (setq ginkgo-use-pwd-as-test-dir t
        ginkgo-use-default-keys t))

(use-package gotest
  :straight t
  :after go-mode
  :bind (:map go-mode-map
              ("C-c t f" . go-test-current-file)
              ("C-c t t" . go-test-current-test)
              ("C-c t j" . go-test-current-project)
              ("C-c t b" . go-test-current-benchmark)
              ("C-c t c" . go-test-current-coverage)
              ("C-c t x" . go-run)))

(use-package go-guru
  :straight t
  :hook
  (go-mode . go-guru-hl-identifier-mode))

(use-package go-projectile
  :straight t
  :after (projectile go-mode))

(use-package flycheck-golangci-lint
  :straight t
  :hook
  (go-mode . flycheck-golangci-lint-setup))

(use-package go-eldoc
  :straight t
  :hook
  (go-mode . go-eldoc-setup))

(use-package go-tag
  :straight t
  :bind (:map go-mode-map
              ("C-c t a" . go-tag-add)
              ("C-c t r" . go-tag-remove))
  :init (setq go-tag-args (list "-transform" "camelcase")))

(use-package go-fill-struct
  :straight t)

(use-package go-impl
  :straight t)

(use-package go-playground
  :straight t)

```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5:</span>
  Configure additional Golang related Emacs packages
</div>


### Dape Configuration {#dape-configuration}

There is no particular reason why I use `dape` instead of [dap](https://github.com/emacs-lsp/dap-mode). When I was still
using [MinEmacs](https://github.com/abougouffa/minemacs) it was part of it and I just got used to it. As the [documentation](https://github.com/svaante/dape?tab=readme-ov-file#differences-with-dap-mode)
states:

> -   Dape does not support launch.json files, if per project configuration is
>     needed use dir-locals and dape-command.
> -   Dape enhances ergonomics within the minibuffer by allowing users to modify or
>     add PLIST entries to an existing configuration using options. For example
>     dape-config :cwd default-directory :program ＂/home/user/b.out＂ compile ＂gcc
>     -g -o b.out main.c＂.
> -   No magic, no special variables like ${workspaceFolder}. Instead, functions and
>     variables are resolved before starting a new session.
> -   Tries to envision how debug adapter configurations would be implemented in
>     Emacs if vscode never existed.

If you ever worked with VSCode you already know that it uses a `launch.json` to
store different debugging profiles.

```json
{
    "name": "Launch file",
    "type": "go",
    "request": "launch",
    "mode": "auto",
    "program": "${file}"
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 6:</span>
  Sample configuration to debug the current file
</div>

You have different fields/properties which according to [this page](https://github.com/microsoft/vscode-go/blob/master/docs/Debugging-Go-code-using-VS-Code.md) you can tweak
in your debugging configuration:

<div class="table-caption">
  <span class="table-number">Table 1:</span>
  Properties to use for the Golang debugger
</div>

| Property   | Description                                                                                                                                                                                             |
|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name       | Name for your configuration that appears in the drop down in the Debug viewlet                                                                                                                          |
| type       | Always set to "go". This is used by VS Code to figure out which extension should be used for debugging your code                                                                                        |
| request    | Either of \`launch\` or \`attach\`. Use \`attach\` when you want to attach to an already running process.                                                                                               |
| mode       | For launch requests, either of \`auto\`, \`debug\`, \`remote\`, \`test\`, \`exec\`. For attach requests, use either \`local\` or \`remote\`                                                             |
| program    | Absolute path to the package or file to debug when in \`debug\` &amp; \`test\` mode, or to the pre-built binary file to debug in \`exec\` mode. Not applicable to attach requests.                      |
| env        | Environment variables to use when debugging. Example: \`{ "ENVNAME": "ENVVALUE" }\`                                                                                                                     |
| envFile    | Absolute path to a file containing environment variable definitions. The environment variables passed in the \`env\` property overrides the ones in this file.                                          |
| args       | Array of command line arguments that will be passed to the program being debugged.                                                                                                                      |
| showLog    | Boolean indicating if logs from delve should be printed in the debug console                                                                                                                            |
| logOutput  | Comma separated list of delve components (\`debugger\`, \`gdbwire\`, \`lldbout\`, \`debuglineerr\`, \`rpc\`) that should produce debug output when \`showLog\` is set to \`true\`.                      |
| buildFlags | Build flags to be passed to the Go compiler                                                                                                                                                             |
| remotePath | Absolute path to the file being debugged on the remote machine in case of remote debugging i.e when \`mode\` is set to \`remote\`. See the section on [Remote Debugging](#remote-debugging) for details |
| processId  | Applicable only when using the \`attach\` request with \`local\` mode. This is the id of the process that is running your executable which needs debugging.                                             |

In `dape` you can use these properties to setup `dape-configs`:

```elisp
;; Basic dape configuration
(with-eval-after-load 'dape
  ;; Add Go debug configuration
  (add-to-list 'dape-configs
               `(go-debug-main
                 modes (go-mode go-ts-mode)
                 command "dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-command-cwd
                 port :autoport
                 :type "debug"
                 :request "launch"
                 :name "Debug Go Program"
                 :cwd "."
                 :program "."
                 :args [])))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 7:</span>
  Basic dape config
</div>

Usually I like to store my different debugging profiles in [directory variables](https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html)
(stored in `.dir-locals.el`). At the root of each project (you can as well have
different configs per folder/package) I store my debugging profiles like this:

```elisp
((go-mode . ((dape-configs .
        ((go-debug-main
          modes (go-mode go-ts-mode)
          command "dlv"
          command-args ("dap" "--listen" "127.0.0.1:55878" "--log-dest" "/tmp/dlv.log")
          command-cwd "/home/victor/projects/repo1"
          host "127.0.0.1"
          port 55878
          :request "launch"
          :mode "debug"
          :type "go"
          :showLog "true"
          :program "/home/victor/projects/repo1/main.go")
         (go-test
          modes (go-mode go-ts-mode)
          command "dlv"
          command-args ("dap" "--listen" "127.0.0.1:55878")
          command-cwd "/home/victor/projects/repo1"
          host "127.0.0.1"
          port 55878
          :request "launch"
          :mode "test"
          :type "go"
          :program "/home/victor/projects/repo1/test/some_file_test.go")
         (go-test-ginkgo
          modes (go-mode go-ts-mode)
          command "dlv"
          command-args ("dap" "--listen" "127.0.0.1:55878")
          command-cwd "/home/victor/projects/repo1/"
          host "127.0.0.1"
          port 55878
          :request "launch"
          :mode "test"
          :type "go"
          :showLog "true"
          :args ["-ginkgo.v" "-ginkgo.focus" "MyGinkgoTest*"]
          :program "/home/victor/projects/repo1/package/"))))))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 8:</span>
  Debugging profiles in <code>.dir-locals.el</code>
</div>


## Sample Application {#sample-application}

Now let's put our knowledge into practice by debugging a real application implementint a
REST API.


### Project Structure {#project-structure}

Our example is a REST API for task management with the following structure:

```nil
taskapi/
├── go.mod
├── go.sum
├── main.go
├── task_store.go
└── task_test.go
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 9:</span>
  Basic code structure
</div>


### Core Components {#core-components}

Let's have a look at the **core components**.

The `Task` represents our core domain model which we'll use to demonstrate different debugging scenarios:

<a id="code-snippet--task-store-task"></a>
```go
import (
    "fmt"
)

type Task struct {
    ID          int    `json:"id"`
    Title       string `json:"title"`
    Description string `json:"description"`
    Done        bool   `json:"done"`
}
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--task-store-task">Code Snippet 10</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/task_store.go">task_store.go</a>: Task entity
</div>

The `TaskStore` handles our in-memory data operations:

<a id="code-snippet--task-store-store"></a>
```go
type TaskStore struct {
    tasks  map[int]Task
    nextID int
}

func NewTaskStore() *TaskStore {
    return &TaskStore{
        tasks:  make(map[int]Task),
        nextID: 1,
    }
}

```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--task-store-store">Code Snippet 11</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/task_store.go">task_store.go</a>: The TaskStore storing multiple tasks
</div>


#### REST API {#rest-api}

The API should expose following endpoints:

-   `POST /task/create` - Creates a new task
-   `GET /task/get?id=<id>` - Retrieves a task by ID

<!--listend-->

<a id="code-snippet--task-store-api"></a>
```go
// CreateTask stores a given Task internally
func (ts *TaskStore) CreateTask(task Task) Task {
    task.ID = ts.nextID
    ts.tasks[task.ID] = task
    ts.nextID++
    return task
}

// GetTask retrieves a Task by ID
func (ts *TaskStore) GetTask(id int) (Task, error) {
    task, exists := ts.tasks[id]
    if !exists {
        return Task{}, fmt.Errorf("task with id %d not found", id)
    }
    return task, nil
}

// UpdateTask updates task ID with a new Task object
func (ts *TaskStore) UpdateTask(id int, task Task) error {
    if _, exists := ts.tasks[id]; !exists {
        return fmt.Errorf("task with id %d not found", id)
    }
    task.ID = id
    ts.tasks[id] = task
    return nil
}

```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--task-store-api">Code Snippet 12</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/task_store.go">task_store.go</a>: Rest API handlers
</div>


#### Server {#server}

Let's continue with the **server**:

<a id="code-snippet--task-server-api-handlers"></a>
```go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
)

// Server implements a web application for managing tasks
type Server struct {
    store *TaskStore
}

func (s *Server) handleCreateTask(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }
    var task Task
    if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    createdTask := s.store.CreateTask(task)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(createdTask)
}

func (s *Server) handleGetTask(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }
    // For demonstration, we'll extract ID from query parameter
    id := 0
    fmt.Sscanf(r.URL.Query().Get("id"), "%d", &id)

    task, err := s.store.GetTask(id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(task)
}
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--task-server-api-handlers">Code Snippet 13</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/task_server.go">task_server.go</a>: API handlers
</div>


### main package {#main-package}

<a id="code-snippet--main-function"></a>
```go
package main

import (
    "log"
    "net/http"
)

func main() {
    store := NewTaskStore()
    server := &Server{store: store}
    http.HandleFunc("/task/create", server.handleCreateTask)
    http.HandleFunc("/task/get", server.handleGetTask)

    log.Printf("Starting server on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--main-function">Code Snippet 14</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/main.go">main.go</a>
</div>


### go.mod {#go-dot-mod}

Create Go module:

```shell
go mod init taskapi
go mod tidy
```

Check dependencies:

```shell
cat go.mod
```

```go
module taskapi

go 1.23.0

require (
    github.com/onsi/ginkgo/v2 v2.21.0
    github.com/onsi/gomega v1.35.1
)

require (
    github.com/go-logr/logr v1.4.2 // indirect
    github.com/go-task/slim-sprig/v3 v3.0.0 // indirect
    github.com/google/go-cmp v0.6.0 // indirect
    github.com/google/pprof v0.0.0-20241029153458-d1b30febd7db // indirect
    golang.org/x/net v0.30.0 // indirect
    golang.org/x/sys v0.26.0 // indirect
    golang.org/x/text v0.19.0 // indirect
    golang.org/x/tools v0.26.0 // indirect
    gopkg.in/yaml.v3 v3.0.1 // indirect
)
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 15:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/go.mod">go.mod</a>
</div>


### Build application {#build-application}

Let's start the server:

```shell
go build -o taskapi *.go
ls -c
```

Now run it:

```shell
$ ./taskapi
2024/11/14 07:03:48 Starting server on :8080

```

Now from a different terminal **create** a new task:

```shell
curl -X POST -s http://localhost:8080/task/create \
-H "Content-Type: application/json" \
-d '{"title":"Learn Debugging","description":"Master Emacs debugging with dape","done":false}'
```

```json
{"id":3,"title":"Learn Debugging","description":"Master Emacs debugging with dape","done":false}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 16:</span>
  Results
</div>

Let's see if we can fetch it:

```shell
curl -X GET -s "http://localhost:8080/task/get?id=1"
```

```json
{"id":1,"title":"Learn Debugging","description":"Master Emacs debugging with dape","done":false}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 17:</span>
  Results
</div>


### Unit tests {#unit-tests}

Below are some unit tests (writen in [Ginkgo](https://pkg.go.dev/github.com/onsi/ginkgo)) for the `TaskStore`:

<a id="code-snippet--task-test"></a>
```go
package main
import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
    "testing"
)

func TestTasks(t *testing.T) {
    RegisterFailHandler(Fail)
    RunSpecs(t, "Task API Suite")
}


var _ = Describe("Task API", func() {
    var (
        store  *TaskStore
        server *Server
    )
    BeforeEach(func() {
        store = NewTaskStore()
        server = &Server{store: store}
    })

    Describe("POST /task/create", func() {
        Context("when creating a new task", func() {
            It("should create and return a task with an ID", func() {
                task := Task{
                    Title:       "Test Task",
                    Description: "Test Description",
                    Done:        false,
                }

                payload, err := json.Marshal(task)
                Expect(err).NotTo(HaveOccurred())

                req := httptest.NewRequest(http.MethodPost, "/task/create",
                    bytes.NewBuffer(payload))
                w := httptest.NewRecorder()

                server.handleCreateTask(w, req)

                Expect(w.Code).To(Equal(http.StatusOK))

                var response Task
                err = json.NewDecoder(w.Body).Decode(&response)
                Expect(err).NotTo(HaveOccurred())
                Expect(response.ID).To(Equal(1))
                Expect(response.Title).To(Equal("Test Task"))
            })

            It("should handle invalid JSON payload", func() {
                req := httptest.NewRequest(http.MethodPost, "/task/create",
                    bytes.NewBufferString("invalid json"))
                w := httptest.NewRecorder()

                server.handleCreateTask(w, req)

                Expect(w.Code).To(Equal(http.StatusBadRequest))
            })
        })
    })

    Describe("GET /task/get", func() {
        Context("when fetching an existing task", func() {
            var createdTask Task

            BeforeEach(func() {
                task := Task{
                    Title:       "Test Task",
                    Description: "Test Description",
                    Done:        false,
                }
                createdTask = store.CreateTask(task)
            })

            It("should return the correct task", func() {
                req := httptest.NewRequest(http.MethodGet, "/task/get?id=1", nil)
                w := httptest.NewRecorder()

                server.handleGetTask(w, req)

                Expect(w.Code).To(Equal(http.StatusOK))

                var response Task
                err := json.NewDecoder(w.Body).Decode(&response)
                Expect(err).NotTo(HaveOccurred())
                Expect(response).To(Equal(createdTask))
            })
        })

        Context("when fetching a non-existent task", func() {
            It("should return a 404 error", func() {
                req := httptest.NewRequest(http.MethodGet, "/task/get?id=999", nil)
                w := httptest.NewRecorder()

                server.handleGetTask(w, req)

                Expect(w.Code).To(Equal(http.StatusNotFound))
            })
        })

        Context("when using invalid task ID", func() {
            It("should handle non-numeric ID gracefully", func() {
                req := httptest.NewRequest(http.MethodGet, "/task/get?id=invalid", nil)
                w := httptest.NewRecorder()

                server.handleGetTask(w, req)

                Expect(w.Code).To(Equal(http.StatusNotFound))
            })
        })
    })
})
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--task-test">Code Snippet 18</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/task_test.go">task_test.go</a>
</div>

Add the Ginkgo dependencies to our `go.mod` file:

```shell
go get github.com/onsi/ginkgo/v2@latest
go get github.com/onsi/gomega
```

Now we should have a full list of dependencies in our `go.mod` file:

```shell
cat go.mod
```

```go
module taskapi

go 1.23.0

require (
    github.com/onsi/ginkgo/v2 v2.21.0
    github.com/onsi/gomega v1.35.1
)

require (
    github.com/go-logr/logr v1.4.2 // indirect
    github.com/go-task/slim-sprig/v3 v3.0.0 // indirect
    github.com/google/go-cmp v0.6.0 // indirect
    github.com/google/pprof v0.0.0-20241029153458-d1b30febd7db // indirect
    golang.org/x/net v0.30.0 // indirect
    golang.org/x/sys v0.26.0 // indirect
    golang.org/x/text v0.19.0 // indirect
    golang.org/x/tools v0.26.0 // indirect
    gopkg.in/yaml.v3 v3.0.1 // indirect
)
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 19:</span>
  Results
</div>

Let's run the tests:

```shell
go test -v
```

```shell
=== RUN   TestTasks
Running Suite: Task API Suite - /home/victor/repos/priv/blog/static/code/2024/emacs-golang-debugging
======================================================================================================
Random Seed: [1m1731647885[0m

Will run [1m5[0m of [1m5[0m specs
[38;5;10m•[0m[38;5;10m•[0m[38;5;10m•[0m[38;5;10m•[0m[38;5;10m•[0m

[38;5;10m[1mRan 5 of 5 Specs in 0.001 seconds[0m
[38;5;10m[1mSUCCESS![0m -- [38;5;10m[1m5 Passed[0m | [38;5;9m[1m0 Failed[0m | [38;5;11m[1m0 Pending[0m | [38;5;14m[1m0 Skipped[0m
--- PASS: TestTasks (0.00s)
PASS
ok  	taskapi	0.193s
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 20:</span>
  Results
</div>

In Emacs I would then call `ginkgo-run-this-container` as shown in this screenshot:

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-ginkgo.png" title="Ginkgo functions in Emacs" caption="Comfortable way of running different ginkgo container with Emacs" pos="left" >}}


## Basic Debugging with Delve and Dape {#basic-debugging-with-delve-and-dape}

In order to debug our Task API we have following approaches

-   we can _launch_ the application directly and debug it
-   we can _attach_ to a running process
-   we can _attach_ to a running debugging session

<div class="table-caption">
  <span class="table-number">Table 2:</span>
  Options for different request types (<a href="https://github.com/go-delve/delve/blob/master/Documentation/api/dap/README.md">source</a>)
</div>

| request  | mode   | required     | optional                                                     |
|----------|--------|--------------|--------------------------------------------------------------|
| _launch_ | debug  | program      | dlvCwd, env, backend, args, cwd, buildFlags, output, noDebug |
|          | test   | program      | dlvCwd, env, backend, args, cwd, buildFlags, output, noDebug |
|          | exec   | program      | dlvCwd, env, backend, args, cwd, noDebug                     |
|          | core   | program      | dlvCwd, env                                                  |
|          |        | corefilePath |                                                              |
|          | replay | traceDirPath | dlvCwd, env                                                  |
| _attach_ | local  | processId    | backend                                                      |
|          | remote |              |                                                              |

So for each `request` we have different `modes`. For the `attach` request type I'll only focus on the `remote` mode which requires you to start the debugger externally and then use the DAP client (within Emacs) to connect to it. I couldn't find any way how to interactively select the process ID before starting the debugger client. Now let's delve into each workflow.


### Profile 1: Launch application {#profile-1-launch-application}

As I've mentioned at the beginning I like to keep my debugging profiles in `.dir-locals` for each propject:

<a id="code-snippet--debug-profile1"></a>
```emacs-lisp
;; Profile 1: Launch application and start DAP server
(go-debug-taskapi
  modes (go-mode go-ts-mode)
  command "dlv"
  command-args ("dap" "--listen" "127.0.0.1:55878")
  command-cwd default-directory
  host "127.0.0.1"
  port 55878
  :request "launch"
  :mode "debug"
  :type "go"
  :showLog "true"
  :program ".")
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--debug-profile1">Code Snippet 21</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/.dir-locals.el">.dir-locals.el</a> (only the launch debug profile is configured)
</div>

💡 You may want to use a different value for `command-cwd` (the default setting is `dape-cwd-fn`). In my case I wanted to start the debugger in a directory which currently is not a project. `default-directory` is a variable which holds the working directory for the current buffer you're currently in.

Start debugging:

-   Run `dape-info` to show debugging information

    {{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-dape-info.png" title="Show debugging related buffers" caption="" pos="left" >}}

<!--listend-->

-   Create breakpoint using `dape-breakpoint-toggle`:

    {{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-dape-breakpoint.png" title="Set breakpoint" caption="" pos="left" >}}

-   Launch `dape`

    In the `dape-repl` buffer you should something like:
    ```shell
    Available Dape commands: debug, next, continue, pause, step, out, up, down, restart, kill, disconnect, quit
    Empty input will rerun last command.

    DAP server listening at: 127.0.0.1:55878
    debugserver-@(#)PROGRAM:LLDB  PROJECT:lldb-1600.0.36.3
     for arm64.
    Got a connection, launched process /home/victor/repos/priv/blog/static/code/2024/emacs-golang-debugging/__debug_bin3666561508 (pid = 43984).
    Type 'dlv help' for list of commands.
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 22:</span>
      The debugger compiled the binary and also launched it
    </div>

    You might have noticed that we didn't specify any binary/file to debug (we had `:program "."` in `.dir-locals.el`). `delve` will automatically _build_ the binary before it launches the application:
    ```shell
    go build -gcflags=all="-N -l" .
    ```
    <div class="src-block-caption">
      <span class="src-block-number">Code Snippet 23:</span>
      How delve builds the application when you have <code>:program "."</code>
    </div>


### Profile 2: Attach to an external debugger {#profile-2-attach-to-an-external-debugger}

Let's say you now want to connect to an existing debugging session:

<a id="code-snippet--debug-profile2"></a>
```emacs-lisp
;; Profile 2: Attach to external debugger
(go-attach-taskapi
 modes (go-mode go-ts-mode)
 command "dlv"
 command-cwd default-directory
 host "127.0.0.1"   ;; can also be skipped
 port 55878
 :request "attach"  ;; this will run "dlv attach ..."
 :mode "remote"     ;; connect to a running debugger session
 :type "go"
 :showLog "true")
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--debug-profile2">Code Snippet 24</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/.dir-locals.el">.dir-locals.el</a>: Additional config for attaching to a running process
</div>

Now let's start the **debugger** on the CLI:

```shell
~/emacs-golang-debugging $ go build -gcflags=all="-N -l" -o taskapi .
~/emacs-golang-debugging $ dlv debug taskapi --listen=localhost:55878 --headless
API server listening at: 127.0.0.1:55878
debugserver-@(#)PROGRAM:LLDB  PROJECT:lldb-1600.0.36.3
 for arm64.
Got a connection, launched process /home/victor/repos/priv/blog/static/code/2024/emacs-golang-debugging/__debug_bin794004190 (pid = 23979).
```

Now within Emacs you can launch `dape` and select the `go-attach-taskapi` profile:

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-attach-to-external-debugger.png" title="Attach to external debugger" caption="" pos="left" >}}


### Profile 3: Attach to a running process {#profile-3-attach-to-a-running-process}

In this scenario the application is _already_ running but you want to _attach_ the debugger to it and use Emacs to connect to the debugger session. First we launch the application:

```shell
$ ./taskapi
2024/11/20 06:34:29 Starting server on :8080
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 25:</span>
  Start the taskapi application
</div>

Find out its process ID (PID):

```shell
ps -A | grep -m1 taskapi | awk '{print $1}'
```

Now let's add a 3rd debug profile:

<a id="code-snippet--debug-profile3"></a>
```emacs-lisp
;; Profile 3: Attach to running process (by PID)
(go-attach-pid
 modes (go-mode go-ts-mode)
 command "dlv"
 command-args ("dap" "--listen" "127.0.0.1:55878" "--log")
 command-cwd default-directory
 host "127.0.0.1"
 port 55878
 :request "attach"
 :mode "local"      ;; Attach to a running process local to the server
 :type "go"
 :processId (+get-process-id-by-name "taskapi")
 :showLog "true")
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--debug-profile3">Code Snippet 26</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/.dir-locals.el">.dir-locals.el</a>: Attach to running process (by pid)
</div>

<a id="code-snippet--get-process-id-by-name"></a>
```emacs-lisp
;; Add helpful function
(eval . (progn
          (defun +get-process-id-by-name (process-name)
            "Return the process ID of a process specified by PROCESS-NAME. Works on Unix-like systems (Linux, MacOS)."
            (interactive)
            (let ((pid nil))
              (cond
               ((memq system-type '(gnu/linux darwin))
                (setq pid (shell-command-to-string
                           (format "pgrep -f %s"
                                   (shell-quote-argument process-name)))))
               (t
                (error "Unsupported system type: %s" system-type)))

              ;; Clean up the output and return first PID
              (when (and pid (not (string-empty-p pid)))
                (car (split-string pid "\n" t)))))))
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--get-process-id-by-name">Code Snippet 27</a>:</span>
  <a href="https://github.com/dorneanu/blog/tree/master/static/code/2024/emacs-golang-debugging/.dir-locals.el">.dir-locals.el</a>: Helper function
</div>

I've also added `+get-process-id-by-name` which will return the process ID for the `taskapi` application.
Now you can use the same debug profile (`go-attach-taskapi`) to start a new DAP server and let it attach to a running processs.

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-attach-running-process-breakpoint.png" title="Set breakpoint to CreateTask" caption="" pos="left" >}}

Now I start the debugger:

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-attach-running-process-pid.png" title="Specify PID" caption="" pos="left" >}}

If I now send a POST request like this one:

```shell
curl -X POST -s http://localhost:8080/task/create \
-H "Content-Type: application/json" \
-d '{"title":"Learn Debugging","description":"Master Emacs debugging with dape","done":false}'
```

The debugger should automatically halt at the set breakpoint:

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-attach-running-process-debugging.png" title="Running debugger" caption="" pos="left" >}}


## Debugging Ginkgo Tests {#debugging-ginkgo-tests}

Being able to debug tests in Golang is a crucial step in the development
process. Until recently it was still a struggle for me, until I've decided to
look into `dape-mode` and some other details.


### Dape Configuration for Ginkgo {#dape-configuration-for-ginkgo}

For running ginkgo tests I use [ginkgo-mode](https://github.com/garslo/ginkgo-mode) which has several features:

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-ginkgo-mode-options.png" title="Ginkgo options in Emacs" caption="" pos="left" >}}

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-ginkgo-focus-on-container.png" title="Focus on specific container" caption="" pos="left" >}}

And as an output I get:

```shell
Running Suite: Task API Suite - /home/victor/repos/priv/blog/static/code/2024/emacs-golang-debugging
======================================================================================================
Random Seed: 1732600680

Will run 1 of 5 specs
•SSSS

Ran 1 of 5 Specs in 0.001 seconds
SUCCESS! -- 1 Passed | 0 Failed | 0 Pending | 4 Skipped
PASS

Ginkgo ran 1 suite in 1.481440083s
Test Suite Passed
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 28:</span>
  Ginkgo output
</div>

This is the basic configuration for debugging Ginkgo tests:

<a id="code-snippet--debug-profile4"></a>
```emacs-lisp
;; Profile 4: Debug Ginkgo tests
(go-test-ginkgo
 modes (go-mode go-ts-mode)
 command "dlv"
 command-args ("dap" "--listen" "127.0.0.1:55878" "--log")
 command-cwd default-directory
 host "127.0.0.1"
 port 55878
 :request "launch"
 :mode "test"      ;; Debug tests
 :type "go"
 :args ["-ginkgo.v" "-ginkgo.focus" "should create and return a task with an ID"]
 :program ".")
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--debug-profile4">Code Snippet 29</a>:</span>
  Debug profile for Ginkgo tests
</div>

If I chose the `go-test-ginkgo` debug profile I should be able to debug the tests as shown in this screenshot:

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-ginkgo-debug-profile.png" title="Debugging profile for Ginkgo tests" caption="" pos="left" >}}

Now the configuration is quite static and therefore you cannot preselect the unit test / container. We need to somehow make the parameter `-ginkgo.focus` dynamic.

<a id="code-snippet--debug-ginkgo-focus"></a>
```emacs-lisp
(defun my/dape-debug-ginkgo-focus (focus-string)
  "Start debugging Ginkgo tests with a specific focus string."
  (interactive "sEnter focus string: ")
  (make-local-variable 'dape-configs)  ; Make buffer-local copy of dape-configs
  (setq dape-configs
        (list
         `(debug-focused-test
           modes (go-mode)
           command "dlv"
           command-args ("dap" "--listen" "127.0.0.1:55878")
           command-cwd default-directory
           port 55878
           :request "launch"
           :name "Debug Focused Test"
           :mode "test"
           :program "."
           :args ["-ginkgo.v" "-ginkgo.focus" ,focus-string]))))
```
<div class="src-block-caption">
  <span class="src-block-number"><a href="#code-snippet--debug-ginkgo-focus">Code Snippet 30</a>:</span>
  Helper function
</div>

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-debug-ginkgo-call-function.png" title="Call my/dape-debug-ginkgo-focus" caption="" pos="left" >}}

{{< gbox src="/posts/img/2024/emacs-golang-debugging/emacs-debug-ginkgo-set-focus-string.png" title="Set Ginkgo focus string" caption="" pos="left" >}}

Afterwards If I have a look at the `dape-configs` variable I should see this value:

```emacs-lisp
Value:
((debug-focused-test modes
                     (go-mode)
                     command "dlv" command-args
                     ("dap" "--listen" "127.0.0.1:55878")
                     command-cwd default-directory port 55878 :request "launch" :name "Debug Focused Test" :mode "test" :program "." :args
                     ["-ginkgo.v" "-ginkgo.focus" "when using invalid*"]))
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 31:</span>
  Value of dape-configs in the buffer
</div>

After starting the debugger (with the `debug-focused-test` profile) in the dape-repl buffer
I get:

```shell
Welcome to Dape REPL!
Available Dape commands: debug, next, continue, pause, step, out, up, down, restart, kill, disconnect, quit
Empty input will rerun last command.

DAP server listening at: 127.0.0.1:55878
debugserver-@(#)PROGRAM:LLDB  PROJECT:lldb-1600.0.39.3
 for arm64.
Got a connection, launched process /home/victor/repos/priv/blog/static/code/2024/emacs-golang-debugging/__debug_bin2799839715 (pid = 31882).
Type 'dlv help' for list of commands.
Running Suite: Task API Suite - /home/victor/repos/priv/blog/static/code/2024/emacs-golang-debugging
======================================================================================================
Random Seed: 1732685749

❶ Will run 1 of 5 specs
SSSS
------------------------------
❷ Task API GET /task/get when using invalid task ID should handle non-numeric ID gracefully
/home/victor/repos/priv/blog/static/code/2024/emacs-golang-debugging/task_store_test.go:108
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 32:</span>
  The dape-repl buffer
</div>

💡Notice that just "1 of 5 specs" (❶) were ran, meaning that `ginkgo` only focussed on the container we have specified (❷).


## Best Practices and Tips {#best-practices-and-tips}

Throughout my debugging experience, I have come to appreciate the importance of **version
control**, as it enables me to track my debugging configurations and their evolution over
time. To streamline this process, I now maintain my debug configurations in a separate
file, such as `.dir-locals.el`, which helps keep them organized and easily accessible.
Additionally, I make sure to use **meaningful names** for these configurations to avoid
confusion and ensure that the correct settings are used when needed. Moreover, I have
found it useful to create **project-specific** debugging **helper functions** that can be easily
customized to suit my needs. Finally, by making **customizations locally** (bound to a
specific buffer), I can ensure that these settings apply only to the relevant context and
do not interfere with other parts of my workflow.


## Resources and References {#resources-and-references}

-   [vscode-go/docs/debugging.md at master · golang/vscode-go](https://github.com/golang/vscode-go/blob/master/docs/debugging.md)
-   [support delve/dlv dap-mode directly · Issue #318 · emacs-lsp/dap-mode](https://github.com/emacs-lsp/dap-mode/issues/318)
-   [Dape GitHub Repository](https://github.com/svaante/dape)
-   [Delve Debugger](https://github.com/go-delve/delve)
-   [Eglot Documentation](https://github.com/joaotavora/eglot)
-   [Ginkgo Testing Framework](https://onsi.github.io/ginkgo/)
