# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hugo-based personal technical blog (kane.mx) focusing on cloud computing, AI/ML, and software engineering. The site uses the hugo-clarity theme with comprehensive SEO optimizations and supports both English and Chinese content.

## Development Commands

### Hugo Commands
```bash
# Start development server
hugo server -D --port 1313

# Build for production
hugo --minify

# Create new post
hugo new posts/YYYY/post-name/index.md

# Create new post with page bundles
hugo new posts/YYYY/post-title/index.md --kind post-bundle
```

### Content Management
```bash
# Optimize images (existing script)
./scripts/image_optimize.sh

# Check for broken links (if needed)
hugo --gc --minify --cleanDestinationDir
```

## Content Structure and Organization

### Directory Structure
- `content/posts/YYYY/` - Blog posts organized by year (2016-2025)
- `content/posts/series-name/` - Multi-part series (e.g., deep-dive-clickstream-analytics, effective-cloud-computing)
- `static/` - Static assets (images, files, robots.txt, manifest.json)
- `layouts/` - Custom Hugo templates and partials
- `config/_default/` - Hugo configuration files

### Post Organization Patterns
- **Single Posts**: `content/posts/YYYY/post-title/index.md` (with page bundles)
- **Series Posts**: `content/posts/series-name/part-name/index.md`
- **Archive Posts**: `content/posts/archive/` for older content

## Blog Writing Style and SEO Guidelines

### Front Matter Template
Always include comprehensive front matter for optimal SEO:

```yaml
---
title: "Descriptive Title with Keywords" # 60 chars max for SEO
description: "Detailed description with key concepts and value proposition" # 155 chars max
date: YYYY-MM-DD
lastmod: YYYY-MM-DD # Update when making significant changes
draft: false # Set to true for drafts
thumbnail: ./images/cover.png # Use page bundles with local images
usePageBundles: true # Enable for posts with images
featured: true # For homepage sidebar
codeMaxLines: 70 # Default 70, adjust based on content
codeLineNumbers: true # Enable for technical posts
toc: true # Enable for long posts
categories:
- Primary Category # Use existing categories from other posts
- Secondary Category
isCJKLanguage: false # Set to true for Chinese content
tags:
- Technology Tag 1 # Use specific, searchable tags
- Technology Tag 2
- Framework Name
- Programming Language
keywords: # SEO keywords for better search visibility
- primary keyword phrase
- secondary keyword phrase
- technology specific terms
series: series-name # For multi-part content
---
```

### Writing Style Guidelines

#### Technical Content Structure
1. **Introduction** - Clear problem statement and value proposition
2. **Architecture/Overview** - High-level system design with diagrams
3. **Implementation Details** - Step-by-step technical implementation
4. **Code Examples** - Working code with syntax highlighting
5. **Best Practices** - Lessons learned and recommendations
6. **Conclusion** - Summary and resources

#### Content Characteristics
- **Professional and Technical**: Focus on practical, implementable solutions
- **Detailed Implementation**: Include working code examples and architectural diagrams
- **SEO-Optimized**: Use keyword-rich titles, descriptions, and structured content
- **Bilingual Support**: Support both English and Chinese content (set `isCJKLanguage` accordingly)
- **Visual Elements**: Include cover images, diagrams, and code snippets
- **External Resources**: Link to official documentation, GitHub repos, and related articles

#### Technical Writing Best Practices
- Use Mermaid diagrams for system architecture and flow charts
- Include practical, runnable code examples
- Provide context for why certain technical decisions were made
- Link to official documentation and external resources
- Use structured headings (H2, H3) for better SEO and readability
- Include "Resources" section at the end with relevant links
- **Reference-Style Links**: Use reference-style links (footer annotations) for ALL links (both external URLs and internal Hugo relref) to keep content clean and maintainable

#### Reference-Style Link Guidelines

**Format**: All links should use `[link text][reference-id]` in content, with definitions at the end of the document.

**External Links** (URLs):
```markdown
For detailed information, see the [AWS documentation][aws-docs].

<!-- At end of document -->
[aws-docs]: https://docs.aws.amazon.com/
```

**Internal Links** (Hugo relref):
```markdown
See my previous post on [MCP Authorization][mcp-oauth-guide].

<!-- At end of document -->
[mcp-oauth-guide]: {{< relref "/posts/2025/post-name/index.md" >}}
```

**Link Organization at Document End**:

Organize all reference links by category with HTML comments for clarity:

```markdown
---

<!-- OAuth and RFC Specifications -->
[rfc-7636]: https://datatracker.ietf.org/doc/html/rfc7636
[rfc-8707]: https://datatracker.ietf.org/doc/html/rfc8707

<!-- Official Documentation -->
[keycloak-docs]: https://www.keycloak.org/documentation
[aws-docs]: https://docs.aws.amazon.com/

<!-- GitHub Repository -->
[project-repo]: https://github.com/username/repository

<!-- Related Articles (Internal Links) -->
[mcp-oauth-guide]: {{< relref "/posts/2025/mcp-oauth/index.md" >}}
[other-post]: {{< relref "/posts/2025/other-post/index.md" >}}
```

**Benefits**:
- Clean, readable content without inline URLs
- Single source of truth for all links
- Easy to update URLs in one place
- Clear organization by category
- Works for both external URLs and internal Hugo links

### SEO Optimization Standards

The blog implements comprehensive SEO optimizations (see `SEO_OPTIMIZATIONS.md`):
- Structured data (schema.org) for articles and breadcrumbs
- Open Graph and Twitter Card meta tags
- Optimized sitemaps with priorities and change frequencies
- PWA support with web manifest
- Image lazy loading and WebP support
- Security headers and performance optimizations

#### SEO Checklist for New Posts
- [ ] Keyword-optimized title (under 60 characters)
- [ ] Meta description (120-155 characters)
- [ ] Relevant tags and categories
- [ ] Internal links to related posts
- [ ] External links to authoritative sources
- [ ] Alt text for images
- [ ] Proper heading structure (H1 > H2 > H3)
- [ ] Cover image optimized for social sharing

### Content Optimization with Gemini CLI

Use **gemini** (Gemini CLI) in headless mode to optimize blog post writing style based on guidelines in `GEMINI.md`:

```bash
# Create optimization prompt
cat > /tmp/optimize_prompt.txt << 'EOF'
You are optimizing a technical blog post for kane.mx based on these guidelines:

GUIDELINES FROM GEMINI.MD:
- SEO-friendly titles (under 60 characters)
- Meta descriptions (120-155 characters)
- Proper heading structure (H1, H2, H3)
- Keyword-rich content
- Professional technical writing style
- Use reference-style links for external URLs
- Clear, concise technical explanations

CURRENT BLOG POST:
EOF

# Append the blog post content
cat content/posts/YYYY/post-name/index.md >> /tmp/optimize_prompt.txt

# Add task instructions
cat >> /tmp/optimize_prompt.txt << 'EOF'

TASK:
Optimize this blog post's writing style to be:
1. More professional and technically precise
2. Better structured for SEO
3. Clearer and more concise
4. Following the blog's established style guidelines

Return ONLY the optimized markdown content without any explanations or comments.
EOF

# Run gemini to optimize (with 16GB memory and latest flash model)
NODE_OPTIONS="--max-old-space-size=16384" gemini --model gemini-2.5-flash --output-format text "$(cat /tmp/optimize_prompt.txt)" > /tmp/optimized_post.md

# Extract clean content (skip error messages)
tail -n +20 /tmp/optimized_post.md > content/posts/YYYY/post-name/index.md

# Clean up
rm /tmp/optimize_prompt.txt /tmp/optimized_post.md
```

**When to Use Gemini Optimization**:
- After creating a new blog post draft
- When refining technical explanations
- To improve SEO optimization
- For consistency with blog's writing style

**Benefits**:
- Professional technical writing style
- Better SEO optimization
- Improved clarity and structure
- Consistent tone across posts

## Theme Configuration

### Hugo Clarity Theme
- Location: `themes/hugo-clarity/`
- Custom overrides in: `layouts/` directory
- Modified files for SEO: `layouts/partials/head.html`, `layouts/partials/json-ld.html`

### Site Configuration
- Main config: `config/_default/config.toml`
- Languages: `config/_default/languages.toml`
- Menus: `config/_default/menus/menu.en.toml`, `config/_default/menus/menu.zh.toml`
- Parameters: `config/_default/params.toml`

## Multi-Language Support

### Language Configuration
- Default language: English (`en`)
- Supported languages: English and Chinese
- Chinese posts: Set `isCJKLanguage: true` in front matter
- Language-specific menus in `config/_default/menus/`

### Content Organization
- English posts: Standard organization
- Chinese posts: Include `isCJKLanguage: true` in front matter
- Shared resources: Use Hugo's i18n system when needed

## Image Handling

### Cover Image Generation

Use the **canvas-design** skill to generate cover images for blog posts:

```bash
# Invoke the canvas-design skill
/canvas-design

# Provide a design brief:
# - Post topic and key concepts
# - Desired visual style (modern, technical, abstract)
# - Color preferences (align with AWS/tech branding)
# - Required dimensions: 1200x630px for social sharing
```

**Design Guidelines for Cover Images**:
- **Style**: Modern, professional, tech-focused aesthetic
- **Content**: Visual representation of the post's main concept
- **Text**: Minimal or no text overlay (title is in metadata)
- **Format**: PNG with high quality
- **Dimensions**: 1200x630px (optimized for social media cards)
- **File location**: Save to `./images/cover.png` in post directory

**Post-Generation Cleanup**:
After the canvas-design skill generates the cover image, clean up the intermediate design philosophy file:
```bash
# Remove the design philosophy markdown file (not needed in final post)
rm content/posts/YYYY/post-name/design-philosophy.md
```

**Example Design Brief**:
```
Create a cover image for a blog post about Amazon QuickSuite.
- Theme: AI-powered business intelligence
- Style: Modern, professional with AWS color palette
- Elements: Abstract data visualization, AI brain/neural network motifs
- Dimensions: 1200x630px
- Format: PNG
```

### Image Optimization
- Use page bundles (`usePageBundles: true`) for posts with images
- Store images in `./images/` relative to post
- Use `scripts/image_optimize.sh` for optimization
- Include WebP versions when possible
- Optimize for lazy loading (already implemented site-wide)

### Image Best Practices
- Cover images: 1200x630px for social sharing (use canvas-design skill)
- Thumbnails: 400x225px for homepage cards
- Screenshots: Use high-resolution with proper compression
- Diagrams: Prefer Mermaid or SVG for scalability

## Series and Multi-Part Content

### Series Configuration
- Use `series: series-name` in front matter
- Organize in dedicated directories: `content/posts/series-name/`
- Include navigation between parts
- Create series landing page with overview

### Cross-Referencing
Use Hugo's `relref` shortcode for internal links:
```markdown
[Part 2]({{< relref "/posts/series-name/part-2/index.md" >}})
```

## Performance and Deployment

### Build Process
- Site builds via GitHub Actions (see `.github/workflows/hugo.yml`)
- Deploys to GitHub Pages automatically
- Minification and optimization enabled in production

### Performance Features
- Resource hints (preconnect, dns-prefetch)
- Asset preloading for critical resources
- Image lazy loading
- Service worker for PWA capabilities
- Optimized CSS and JS minification