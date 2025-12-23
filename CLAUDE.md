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

## Git Submodules

**IMPORTANT**: `themes/er/` is a git submodule (separate repository)

- **DO NOT** commit changes to the main repository that include the `themes/er` submodule
- If you modify files inside `themes/er/`, commit those changes separately within the submodule directory
- The submodule has its own git history and should be managed independently
- When committing main repository changes, always unstage `themes/er` if it appears in `git status`

Example workflow for theme changes:
```bash
# Commit changes inside the theme submodule
cd themes/er
git add <modified-files>
git commit -m "fix(theme): description"
# Note: User will decide whether to push theme changes

# Back to main repository - do NOT stage themes/er
cd ../..
git add <other-files>
git commit -m "fix: description"
```

## Testing and Visual Review

**IMPORTANT**: When making CSS or layout changes, always use the development server and MCP screenshot server to visually verify changes.

### Development Server
Start the Hugo development server to preview changes:
```bash
hugo server
```

The site will be available at http://localhost:1313 with live reload.

### Visual Testing with MCP
The repository has the `screenshot` MCP server installed for taking screenshots of rendered pages:

- Use the screenshot MCP tools to capture http://localhost:1313
- Review visual appearance of CSS changes, layout modifications, and styling updates
- Take screenshots of specific pages to verify improvements
- Compare before/after states when making design changes

This allows you to see the actual rendered output, not just the HTML/CSS code.

## CSS Debugging Workflow

**Use this systematic approach for diagnosing and fixing CSS styling issues, especially link color inconsistencies or other visual bugs.**

### 1. Visual Verification & Documentation
```bash
# Start development server
hugo server --port 1313

# Take initial screenshot to document the issue
mcp_screenshot_take_screenshot(url="http://localhost:1313/path/to/page")
```
- Capture visual evidence of the problem
- Note specific areas where styling is inconsistent

### 2. Programmatic Issue Detection
Use console debugging to systematically find problematic elements:

```javascript
// Find all elements with the wrong styling (e.g., blue links when they should be brown)
const problematicElements = Array.from(document.querySelectorAll('a')).filter(link => {
  const color = window.getComputedStyle(link).color;
  return color === 'rgb(0, 0, 238)'; // browser default blue
});

console.log(`Found ${problematicElements.length} problematic elements`);

// Analyze each element's location and context
problematicElements.forEach((element, index) => {
  console.log(`Element ${index + 1}:`);
  console.log(`  URL: ${element.href}`);
  console.log(`  Text: ${element.textContent.substring(0, 30)}...`);
  console.log(`  Current color: ${window.getComputedStyle(element).color}`);

  // Check element's position in DOM hierarchy
  console.log(`  In post-content: ${element.closest('.post-content') ? 'YES' : 'NO'}`);
  console.log(`  In main: ${element.closest('main') ? 'YES' : 'NO'}`);
  console.log(`  In footer: ${element.closest('footer') ? 'YES' : 'NO'}`);
});
```

### 3. HTML Structure Analysis
Investigate the DOM hierarchy to understand why CSS isn't applying:

```javascript
// Examine parent chain for a specific problematic element
const element = document.querySelector('problematic-selector');
let current = element;
let level = 0;
while (current && level < 6) {
  console.log(`Level ${level}: <${current.tagName.toLowerCase()}${current.className ? ' class="' + current.className + '"' : ''}>`);
  current = current.parentElement;
  level++;
}
```

### 4. CSS Specificity Investigation
- Check existing CSS selectors in `static/css/custom.css` and `themes/er/static/css/styles.css`
- Identify why current selectors aren't catching all elements
- Look for competing rules or insufficient specificity

### 5. Targeted CSS Solutions
Add CSS with appropriate specificity to cover all cases:

```css
/* Target multiple selector patterns to ensure comprehensive coverage */
main .post-content a,           /* Post content links */
main .sidenote a,              /* Sidenote links */
main a,                        /* All main area links */
footer a {                     /* Footer links */
  color: #8C6056 !important;
  border-bottom: 1.5px solid #8C6056 !important;
  text-decoration: none !important;
}

/* Include all pseudo-classes for comprehensive coverage */
main a:link,
main a:visited,
main a:any-link,
main a:hover,
main a:active {
  /* Same styling rules */
}
```

### 6. Iterative Testing & Verification
After each CSS change, verify programmatically:

```javascript
// Test if the fix worked
const stillProblematic = Array.from(document.querySelectorAll('a')).filter(link => {
  const color = window.getComputedStyle(link).color;
  return color === 'rgb(0, 0, 238)'; // Still blue?
});

console.log(`Remaining problematic elements: ${stillProblematic.length}`);

if (stillProblematic.length === 0) {
  console.log('🎉 SUCCESS! All elements now properly styled!');

  // Spot-check some previously problematic elements
  const testUrls = ['url1', 'url2'];
  testUrls.forEach(url => {
    const element = document.querySelector(`a[href="${url}"]`);
    if (element) {
      const color = window.getComputedStyle(element).color;
      console.log(`✅ ${url}: ${color === 'rgb(140, 96, 86)' ? 'CORRECT' : 'WRONG'}`);
    }
  });
}
```

### 7. Final Visual Confirmation
```bash
# Take final screenshot to confirm visual fix
mcp_screenshot_take_screenshot(url="http://localhost:1313/path/to/page")
```

### Key Benefits of This Approach:
- **Visual Documentation**: Screenshots provide clear before/after evidence
- **Programmatic Precision**: Console debugging finds exact problematic elements
- **Systematic Analysis**: Understand root causes rather than guessing
- **Comprehensive Coverage**: Ensure all edge cases are handled
- **Verifiable Results**: Confirm fixes work across all scenarios

### Common CSS Issues & Solutions:
- **Insufficient Specificity**: Add more specific selectors (`main .class a` vs `.class a`)
- **Missing Pseudo-classes**: Include `:link`, `:visited`, `:any-link` states
- **Competing Rules**: Use `!important` when necessary to override theme defaults
- **DOM Structure Variations**: Elements outside expected containers (sidenotes, footers, etc.)

### Example Commit:
```
fix(css): Ensure consistent link styling across all page areas

- Add comprehensive selectors for main, footer, and sidenote links
- Include all pseudo-class states (:link, :visited, :any-link)
- Increase specificity to override theme defaults
- Verified 0 remaining blue links with console debugging
```

## Git Commit Messages

- Use simple one-line commit messages following conventional commit format
- Format: `type(scope): brief description`
- Do NOT add "Generated with Claude Code" footer or Co-Authored-By lines
- Keep it concise and descriptive

Examples:
- `feat(shortcodes): Add GLightbox gallery support`
- `fix(layout): Correct responsive grid spacing`
- `chore(deps): Update Hugo version`

## Git Operations Permissions

**CRITICAL**: Never commit or push changes unless explicitly asked by the user.

- **ALWAYS** ask for permission before committing changes
- **NEVER** automatically commit after making modifications to files
- **NEVER** push to remote repositories without explicit user approval
- Wait for user confirmation with phrases like "commit this" or "push these changes"
- This applies to ALL git operations: commits, pushes, merges, etc.

The user maintains full control over when and what gets committed to the repository.

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
