# Claude Code Instructions

## Repository Overview

This is **blog.dornea.nu**, a personal blog by Victor Dorneanu built with Hugo static site generator. The blog covers technical topics including security, programming, and productivity. It's deployed via Netlify and uses a custom theme called "er".

### Directory Structure

**Content directories** (where blog posts live):
- `content/posts/` - Main blog posts (200+ posts, markdown and org-mode files)
- `content/notes/` - Shorter notes and braindumps
- `content/gists/` - Code snippets and gists
- `content/jupyter/` - Jupyter notebook posts
- `content/bookmarks/` - Bookmarked links and resources
- `content/projects/` - Project showcases
- `content/dev/` - Development-related content

**Theme and layout customization**:
- `layouts/` - Hugo layout overrides for the theme
  - `layouts/_default/` - Base templates (list, single, etc.)
  - `layouts/partials/` - Reusable template components
  - `layouts/shortcodes/` - Custom Hugo shortcodes (habit-tracker, galleries, etc.)
  - `layouts/section/` - Section-specific templates

**Static assets**:
- `static/` - Static files served directly
  - `static/posts/img/` - Blog post images organized by year and post slug
  - `static/css/` - Custom stylesheets
  - `static/js/` - JavaScript files
  - `static/data/` - Data files (CSV for habit tracker, etc.)
  - `static/code/` - Code examples
  - `static/casts/` - Asciinema recordings

**Other directories**:
- `themes/er/` - Custom Hugo theme (git submodule)
- `public/` - Generated site output (git-ignored, built by Hugo)
- `org/` - Org-mode configuration
- `resources/` - Hugo's build cache

**Configuration**:
- `config.toml` - Main Hugo configuration
- `Makefile` - Build and deployment commands

### Key Features

- Supports both Markdown and Org-mode content
- Custom shortcodes for interactive features (habit tracker, galleries, etc.)
- Permalink structure: `/YYYY/MM/DD/title`
- RSS feed at `/feed.xml`
- Syntax highlighting with line numbers
- Related posts feature
- Custom CSS and JavaScript

## Git Commit Messages

- Use simple one-line commit messages following conventional commit format
- Format: `type(scope): brief description`
- Do NOT add "Generated with Claude Code" footer or Co-Authored-By lines
- Keep it concise and descriptive

Examples:
- `feat(shortcodes): Add GLightbox gallery support`
- `fix(layout): Correct responsive grid spacing`
- `chore(deps): Update Hugo version`

## Blog Post Creation Workflow

Claude Code acts as a blogging assistant to reduce friction in creating and publishing posts. When the user wants to create a blog post:

### 1. Create Org-Mode File
- Ask the user for: title, tags, and whether it's a draft
- Create file in `content/posts/` with name format: `YYYY-title-slug.org`
- Add Hugo frontmatter:
  ```org
  #+TITLE: Post Title
  #+DATE: YYYY-MM-DD
  #+TAGS[]: tag1 tag2 tag3
  #+DRAFT: false
  ```

### 2. Handle Images
- When user pastes screenshots/images in chat:
  - Save to `static/posts/img/YYYY/post-slug/`
  - Use descriptive filenames (e.g., `screenshot-github-stats.png`)
  - Add org-mode image links: `[[/posts/img/YYYY/post-slug/image.png]]`
- Images are visible in the chat - use them to understand context

### 3. Content Creation
- Help structure the post (headings, sections)
- Format code blocks, quotes, lists as needed
- Keep the user's voice - don't over-edit
- Ask clarifying questions if needed

### 4. Publishing
- When ready to publish:
  - Ensure `#+DRAFT: false` is set
  - Git add the org file and any images
  - Commit with format: `feat(post): Add post about X`
  - Push to trigger Netlify deployment

### 5. Quick Tips
- User may want to write directly in markdown for quick posts - that's fine too
- Default to org-mode unless user specifies otherwise
- Ask before publishing - user should review first
- Keep it conversational and low-friction

### Example Interaction
```
User: "I want to write about debugging Go programs"
Claude: Creates content/posts/2025-debugging-go-programs.org with frontmatter

User: [pastes screenshot of debugger]
Claude: Saves to static/posts/img/2025/debugging-go-programs/debugger-view.png
        Adds image link to org file

User: "Looks good, publish it"
Claude: Sets draft to false, commits, pushes
```
