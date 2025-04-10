+++
title = "Add pagefind search to hugo"
author = ["Victor Dorneanu"]
lastmod = 2025-04-10T09:11:24+02:00
tags = ["hugo"]
draft = false
+++

Every PKMS/BASB needs a search functionality. Ever since I've created [brainfck](https://brainfck.org) to host my
own collection of thoughts/ideas/resources (aka Zettelkasten) I wanted to be able to
actually **search** within my collection of [org-roam](https://www.orgroam.com/) based notes. Meanwhile for all my sites I
own ([this](https://blog.dornea.nu) blog, my [CV/portfolio](https://dornea.nu), [brainfck](https://brainfck.org) and [defersec](https://defersec.com)) I use [hugo](https://gohugo.io/). All of them didn't
have proper search capabilities. That's why I was looking for a proper way to include
search functionalities without any major effort.

Hugo, indeed, has some [open-source and commercial search options](https://gohugo.io/tools/search/) you can choose from. I
have used this [fuse.js integration](https://gist.github.com/eddiewebb/735feb48f50f0ddd65ae5606a1cb41ae) in the past but I wasn't happy with it. It didn't index
well, I couldn't find all my content. Of course, I was thinking having [Algolia DocSearch](https://docsearch.algolia.com/)
do the magic but I one has to apply for it. Also, not all of my sites are about _technical
documentation_. So I had to find another alternative. Digging deeper I came across
[Pagefind](https://pagefind.app/).

Here is a screenshot how it currently looks like:

{{< gbox src="/posts/img/2025/add-pagefind-to-hugo/brainfck-search.png" title="Search function on brainfck.org using Pagefind" caption="" pos="left" >}}


## Pagefind {#pagefind}

[Pagefind](https://pagefind.app/) is a lightweight, static search solution designed specifically for static sites
like those built with Hugo. It works by generating a search index during your site's build
process, creating a client-side search experience that doesn't require any server
infrastructure.

The **indexing** works by crawling your static HTML files after they're built, extracting
content and metadata. Pagefind creates a compressed search index that's both fast and
efficient, typically resulting in index sizes of about 1/1000th of your original content
size. This means your search functionality remains _quick_ even on larger sites.

When examining a typical Pagefind implementation in a Hugo site, the folder structure
looks something like this:

```shell
tree public/pagefind
public/pagefind
├── fragment
│   ├── en_02aee83.pf_fragment
...
│   ├── en_2538bf9.pf_fragment
│   ├── en_2550e62.pf_fragment
│   ├── en_2582c6f.pf_fragment
│   ├── en_ffbbc35.pf_index
│   └── en_ffeab69.pf_index
├── pagefind-entry.json
├── pagefind-highlight.js
├── pagefind-modular-ui.css
├── pagefind-modular-ui.js
├── pagefind-ui.css
├── pagefind-ui.js
├── pagefind.en_19e6da436f.pf_meta
├── pagefind.en_1c7f38a66e.pf_meta
├── pagefind.en_1f95755b6e.pf_meta
├── pagefind.en_2a7661ff21.pf_meta
├── pagefind.en_4fdfe13af9.pf_meta
├── pagefind.en_5049ae833f.pf_meta
├── pagefind.en_603dab85b4.pf_meta
├── pagefind.en_6663d2c9c9.pf_meta
├── pagefind.en_7411b4b912.pf_meta
├── pagefind.en_791636c92e.pf_meta
├── pagefind.en_93f1fd4c5c.pf_meta
├── pagefind.en_94bcd0c843.pf_meta
├── pagefind.en_a8061c44f1.pf_meta
├── pagefind.en_a96223e65e.pf_meta
├── pagefind.en_b526d7e391.pf_meta
├── pagefind.en_b6e37679e1.pf_meta
├── pagefind.en_b7a63d2937.pf_meta
├── pagefind.en_c039de83fe.pf_meta
├── pagefind.en_d9c4de17e6.pf_meta
├── pagefind.en_deac3933f1.pf_meta
├── pagefind.en_eb3680ac82.pf_meta
├── pagefind.en_fab96f64ed.pf_meta
├── pagefind.js
├── wasm.en.pagefind
└── wasm.unknown.pagefind

3 directories, 3087 files
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Contents of the pagefind folder
</div>


### Configuration {#configuration}

You also have some [configuration options](https://pagefind.app/docs/config-options/). In my case:

```yaml
# Pagefind configuration

# Basic options (using Pagefind 1.0 naming)
site: public
output_subdir: pagefind

# Add date-based metadata for sorting
indexing_options:
  # Add date as metadata for all pages
  - metadata_date_field: date
    metadata_date_format: iso

  # Global metadata fields for all pages
  - metadata_fields:
      # Primary metadata sources
      - {
          tag: "meta[property='og:title']",
          as: "title",
          content_attr: "content",
          optional: true,
        }
      - { selector: ".post-title", as: "title", optional: true }
      - { selector: "h1", as: "title", optional: true }

      # Date and other metadata
      - {
          tag: "meta[property='og:type']",
          as: "type",
          content_attr: "content",
          optional: true,
        }
      - {
          tag: "meta[name='date']",
          as: "date",
          content_attr: "content",
          optional: true,
        }
      - {
          tag: "meta[property='article:published_time']",
          as: "published",
          content_attr: "content",
          optional: true,
        }
      - {
          selector: "time",
          as: "date",
          content_attr: "datetime",
          optional: true,
        }

# Added languages
language:
  code: en
  stemming: true

# Search options
search_options:
  ignore_missing_metadata_fields: true
  boost_exact_matches: true
  boost_title: 5.0
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  <a href="https://github.com/dorneanu/roam/blob/main/pagefind.yml">pagefind.yaml</a>
</div>

This configuration file sets up Pagefind with optimal settings for a **personal knowledge
base**. The key options include:

-   _Basic setup_: Specifies the source directory (public) and where to output the search
    files (pagefind subdirectory)
-   _Date-based metadata_: Adds date fields for each page, enabling chronological sorting of
    search results
-   _Metadata extraction_: Configures multiple fallback methods to extract page titles and
    dates from different HTML elements and meta tags
-   _Search optimization_: Boosts exact matches and increases the weight of title matches by
    5x, ensuring the most relevant results appear first


## Hugo integration {#hugo-integration}


### search page {#search-page}

```markdown
---
title: "Search"
---
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3:</span>
  Search page (<a href="https://github.com/dorneanu/roam/blob/main/content/search/_index.md">content/search/_index.md</a>)
</div>


### search template {#search-template}

The search page implementation works through several key components:

-   _Loading Pagefind scripts_: The template loads the necessary CSS and JavaScript files that
    Pagefind generated during the build process.
-   _Search parameter handling_: The implementation supports direct linking to search
    results using URL parameters. When someone visits `/search?q=zettelkasten`, the page
    automatically populates the search box with "zettelkasten" and triggers the search.
-   _URL updating_: As the user types in the search box, the URL is dynamically updated with
    the current query using the browser's History API (pushState). This creates a seamless
    experience where users can bookmark or share specific search results.

<!--listend-->

```html
{{ define "main" }}
<main class="center mv4 content-width ph3">
  <div class="f3 fw6 heading-color heading-font">{{ .Title }}</div>
  <div class="lh-copy mt4">
    <p>Search across all content.</p>

    <!-- Load Pagefind scripts -->
    <link href="/pagefind/pagefind-ui.css" rel="stylesheet" />
    <script src="/pagefind/pagefind-ui.js"></script>

    <!-- Create the search container with your site's styling -->
    <div id="search" class="w-100 mb4"></div>

    <script>
      // Set configuration for pagefind
      window.pagefindConfig = {
        bundlePath: "/pagefind/",
        processTerm: (term) => {
          // Simple processing to remove undefined text from search results
          return term.replace(/undefined/g, "");
        },
      };

      // Function to get URL parameters
      function getUrlParameter(name) {
        name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
        const regex = new RegExp("[\\?&]" + name + "=([^&#]*)");
        const results = regex.exec(location.search);
        return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
      }

      // Initialize the search UI when the DOM is loaded
      document.addEventListener("DOMContentLoaded", function () {
        // Get the search query from URL parameter 'q' if it exists
        const initialQuery = getUrlParameter("q");

        const searchUI = new PagefindUI({
          element: "#search",
          showSubResults: true,
          showImages: false,
          sort: {
            // Enable sorting by date (newest first) and relevance
            options: [
              { key: "date", label: "Date (Newest First)", order: "desc" },
              { key: "default", label: "Relevance" },
            ],
            // Use date as the default sorting method
            default: "date",
          },
          translations: {
            placeholder: "Search your notes...",
            zero_results: "No results found",
            many_results: "Found {results} results",
            sort_by: "Sort by:",
          },
        });

        // Set up a listener to watch for changes in the search input
        setTimeout(() => {
          // Find the search input after PagefindUI has initialized
          const searchInput = document.querySelector(
            ".pagefind-ui__search-input",
          );
          const searchForm = document.querySelector(".pagefind-ui__form");

          if (searchInput) {
            // Update URL when the search input changes
            searchInput.addEventListener("input", function () {
              updateSearchUrl(this.value);
            });

            // Also capture form submission (when user presses Enter)
            if (searchForm) {
              searchForm.addEventListener("submit", function (e) {
                // Don't prevent default as we want the search to execute
                updateSearchUrl(searchInput.value);
              });
            }
          }

          // Helper function to update the URL with the search query
          function updateSearchUrl(query) {
            const url = new URL(window.location);

            if (query && query.trim() !== "") {
              url.searchParams.set("q", query);
            } else {
              url.searchParams.delete("q");
            }

            window.history.pushState({}, "", url);
          }
        }, 500); // Short delay to ensure PagefindUI has initialized

        // If there's an initial query, set it and trigger the search
        if (initialQuery) {
          // Use a small timeout to ensure PagefindUI is fully initialized
          setTimeout(() => {
            searchUI.triggerSearch(initialQuery);
          }, 100);
        }
      });
    </script>
  </div>
</main>
{{ end }}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4:</span>
  The search template for Pagefind
</div>


### CSS {#css}

```css
/* Simple pagefind overrides to match site styling */
:root {
  --pagefind-ui-scale: 1;
  --pagefind-ui-primary: #3e5622;
  --pagefind-ui-text: #333;
  --pagefind-ui-background: #fff;
  --pagefind-ui-border: #ddd;
  --pagefind-ui-border-radius: 4px;
}

/* Search input styling */
.pagefind-ui__search-input {
  padding: 0.5rem !important;
  width: 100% !important;
  border: 1px solid #ddd !important;
  border-radius: 0.25rem !important;
  font-size: 1rem !important;
  /* Remove the search icon */
  background-image: none !important;
  padding-right: 16px !important;
  padding-left: 16px !important;
}

/* Adjust clear button position */
.pagefind-ui__search-clear {
  right: 16px !important;
}

/* Result title styling */
.pagefind-ui__result-title {
  font-weight: 600 !important;
}

.pagefind-ui__result-link {
  color: #3e5622 !important;
  text-decoration: none !important;
}

/* Highlight search terms */
.pagefind-ui__result-excerpt mark {
  background-color: rgba(255, 255, 0, 0.4) !important;
  color: inherit !important;
}

/* Load more button styling */
.pagefind-ui__button {
  background-color: #3e5622 !important;
  color: white !important;
  border: none !important;
  border-radius: 0.25rem !important;
  padding: 0.5rem 1rem !important;
  cursor: pointer !important;
}

/* Simple fix for undefined text */
.pagefind-ui__result-excerpt:contains('undefined'),
.pagefind-ui__result-title:contains('undefined') {
  visibility: hidden;
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5:</span>
  <a href="https://github.com/dorneanu/roam/blob/main/static/css/pagefind.css">pagefind.css</a>
</div>


## Netlify deployment {#netlify-deployment}

Deploying your Pagefind-enabled Hugo site on [Netlify](https://www.netlify.com/) is straightforward with this configuration:

```toml
[build]
  publish = "public"
  command = "hugo && npx pagefind --site public --output-subdir pagefind"

[build.environment]
  HUGO_VERSION = "0.145.0"  # Replace with your current Hugo version
  NODE_VERSION = "18"       # Ensure we have a recent Node version for Pagefind

# Cache control for Pagefind files
[[headers]]
  for = "/pagefind/*"
  [headers.values]
    Cache-Control = "public, max-age=604800"
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 6:</span>
  <a href="https://github.com/dorneanu/roam/blob/main/netlify.toml">netlify.toml</a>
</div>

The configuration does three critical things:

-   _Build command_: It extends the standard Hugo build process by adding Pagefind indexing as
    a second step. This ensures your search index is generated after Hugo creates all the
    HTML files.
-   _Environment setup_: It specifies the required Hugo and Node.js versions.
-   _Cache configuration_: It adds cache headers for all Pagefind files, setting a one-week
    cache period. This improves performance for returning visitors, as browsers won't need
    to download the search index again on every visit.

For **local development** this might be also useful:

```json
{
  "name": "brainfck-roam",
  "version": "1.0.0",
  "description": "Your org-roam notes on Hugo",
  "scripts": {
    "build": "hugo && npx pagefind --site public --output-subdir pagefind",
    "dev": "hugo server -b http://127.0.0.1:1315/ --disableFastRender --port 1315 --noHTTPCache --logLevel debug --gc",
    "search-index": "npx pagefind --site public --output-subdir pagefind",
    "full-dev": "npm run build && npm run dev"
  },
  "dependencies": {
    "pagefind": "^1.0.0"
  }
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 7:</span>
  package.json
</div>

The `package.json` file provides several convenient npm scripts that streamline your workflow:

-   `npm run dev`
    -   Starts a local Hugo server with debug logging and cache disabled.
-   `npm run search-index`
    -   Runs only the Pagefind indexing on your current build output. This is helpful when you
        want to rebuild just the search index without regenerating the entire site.
-   `npm run build`
    -   Performs the complete production build process—generating the Hugo site and then
        creating the Pagefind search index afterward.
-   `npm run full-dev`
    -   A comprehensive development command that builds the complete site with search index
        and then starts the development server. This is ideal when you need to test search
        functionality locally.


## Resources {#resources}

-   2025-04-10 ◦ [Hugo Search tools](https://gohugo.io/tools/search/)
-   2025-04-10 ◦ [Pagefind | Pagefind — Static low-bandwidth search at scale](https://pagefind.app/)
-   2025-04-10 ◦ [Adding local search to Hugo with Pagefind – jverkamp.com](https://blog.jverkamp.com/2023/09/25/adding-local-search-to-hugo-with-pagefind/)
    This is where I got the idea with the q parameter (e.g. `/search/q=string`)
-   2025-04-10 ◦ [Search with Pagefind - michael-le.dev](https://michael-le.dev/posts/pagefind-hugo/)
