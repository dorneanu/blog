+++
title = "Using forge with gh CLI token"
author = ["Victor Dorneanu"]
date = 2026-04-13
lastmod = 2026-04-20T14:00:16+02:00
tags = ["emacs", "github"]
draft = false
+++

> **Update 2026-04-17:** A [Reddit comment](https://www.reddit.com/r/emacs/comments/1sl1lex/using_forge_with_gh_cli_token/) pointed out a cleaner approach: instead of advising `ghub--token`
> directly, you can register a proper `auth-source` backend. This way _any_ package that uses `auth-source`
> (not just ghub/forge) benefits automatically. Both approaches are documented below.

[Forge](https://github.com/magit/forge) requires a GitHub token stored in `~/.authinfo` or `~/.netrc`. For GitHub Enterprise (e.g.,
corporate instances), this means:

-   Manually creating a PAT (Personal Access Token) in the GitHub UI
-   Figuring out the right OAuth scopes
-   Storing it securely
-   Remembering to rotate it

If you already use the `gh` CLI and are authenticated, you have a perfectly good token — why not reuse
it?


## Advise ghub to use gh CLI {#advise-ghub-to-use-gh-cli}

Instead of storing a token manually, we can intercept forge's token lookup and delegate it to the `gh`
CLI.

```emacs-lisp
(defun my/ghub-token-from-gh-cli (host username package &optional nocreate forge)
  "Get token from gh CLI for HOST."
  (when (and host (string-match-p "github\\.example\\.corp" (format "%s" host)))
    (let ((token (string-trim (shell-command-to-string
                               "gh auth token --hostname github.example.corp"))))
      (message "Using gh CLI token for %s" host)
      token)))

(advice-add 'ghub--token :before-until #'my/ghub-token-from-gh-cli)
```

The key is `:before-until`: it runs our function first, and only falls back to the default token
lookup if our function returns `nil`.


## Full forge setup {#full-forge-setup}

```emacs-lisp
(use-package forge
  :straight t
  :after magit
  :custom
  (forge-github-token-scopes '(repo user))
  :config
  ;; Register your GitHub Enterprise instance
  (push '("github.example.corp" "github.example.corp/api/v3"
          "github.example.corp" forge-github-repository)
        forge-alist)

  ;; Reuse the gh CLI token
  (defun my/ghub-token-from-gh-cli (host username package &optional nocreate forge)
    "Get token from gh CLI for HOST."
    (when (and host (string-match-p "github\\.example\\.corp" (format "%s" host)))
      (let ((token (string-trim (shell-command-to-string
                                 "gh auth token --hostname github.example.corp"))))
        (message "Using gh CLI token for %s" host)
        token)))

  (advice-add 'ghub--token :before-until #'my/ghub-token-from-gh-cli))
```


## Prerequisites {#prerequisites}

-   `gh` CLI installed and authenticated: `gh auth login --hostname github.example.corp`
-   Verify it works: `gh auth token --hostname github.example.corp`


## Why this works {#why-this-works}

`ghub` (Forge's HTTP layer) calls `ghub--token` to resolve credentials. By advising it with
`:before-until`, we short-circuit the lookup for matching hostnames and return the `gh` CLI token
directly — no `~/.authinfo` entry needed.


## Better alternative: a proper auth-source backend {#better-alternative-a-proper-auth-source-backend}

The approach above works, but it's ghub-specific. A [Reddit commenter](https://www.reddit.com/r/emacs/comments/1sl1lex/using_forge_with_gh_cli_token/) pointed out that Magit
ultimately resolves tokens via `auth-source-search`, so you can register a custom `auth-source`
backend instead. This is cleaner because:

-   No monkey-patching of `ghub--token`
-   Any package using `auth-source` gets the token automatically
-   Follows the intended extension point of the `auth-source` API

<!--listend-->

```emacs-lisp
(defun auth-source-backend-gh-parse (entry)
  (when (string= "gh" entry)
    (auth-source-backend
     :source "."
     :type 'gh
     :search-function #'auth-source-gh-search)))
(add-hook 'auth-source-backend-parser-functions #'auth-source-backend-gh-parse)

(cl-defun auth-source-gh-search (&rest spec &allow-other-keys)
  (when-let* ((host (plist-get spec :host))
              ((string-match-p "github\\.example\\.corp" (format "%s" host))))
    (let* ((token (string-trim (shell-command-to-string
                                "gh auth token --hostname github.example.corp")))
           (user (or (plist-get spec :user) user-login-name)))
      (message "Using gh CLI token for %s" host)
      (list (list :host host :user user :secret token)))))

(add-to-list 'auth-sources "gh")
(auth-source-forget-all-cached)
```

You can drop this inside your `forge` `use-package` `:config` block, or load it independently — it
doesn't depend on forge at all.

The old `advice-add` approach still works if you prefer to keep it scoped strictly to ghub. But for a
new setup, the `auth-source` backend is the right way to go.


## Alternative: consult-gh {#alternative-consult-gh}

If you prefer a more interactive, completing-read-based workflow over Forge's Magit integration,
[consult-gh](https://github.com/armindarvish/consult-gh) is worth a look. It wraps the `gh` CLI directly and surfaces PRs, issues, repos, and
notifications via [consult](https://github.com/minad/consult) — no `~/.authinfo` token needed at all, since it shells out to `gh` for
everything.

A minimal setup:

```emacs-lisp
(use-package consult-gh
  :straight t
  :custom
  (consult-gh-default-host "github.example.corp"))
```

The two tools complement each other well:

-   **Forge** integrates deeply with Magit (review PRs, open issues from `magit-status`)
-   **consult-gh** is faster for ad-hoc browsing and searching across repos


## Last thoughts {#last-thoughts}

-   The token is fetched via shell on every call
-   Works for GitHub Enterprise; for github.com, adjust the `string-match-p` pattern
-   Requires `gh` to remain authenticated (`gh auth status` to check)

💡 As always you can check my [Emacs configuration file](https://github.com/dorneanu/dotfiles/blob/master/minimal-emacs/config.org).
