# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

This is a personal technical blog (kane.mx) built with the [Hugo](https://gohugo.io/) static site generator. The site focuses on cloud computing, AI/ML, and software engineering topics. It uses the `hugo-clarity` theme, which has been customized for extensive SEO and performance optimizations. The blog supports both English and Chinese content.

## Building and Running

### Development Commands

*   **Run the local development server:**
    ```bash
    hugo server -D --port 1313
    ```
*   **Create a new post:**
    This project uses page bundles, so new posts should be created as a directory with an `index.md` file.
    ```bash
    hugo new posts/YYYY/your-post-title/index.md
    ```
*   **Build for production:**
    The site is built and deployed automatically via GitHub Actions. However, a manual build can be run with:
    ```bash
    hugo --minify
    ```

### Scripts

*   **Image Optimization:** An image optimization script is available to generate modern image formats.
    ```bash
    ./scripts/image_optimize.sh
    ```

## Development Conventions

### Content Structure

*   **Page Bundles:** All posts should use page bundles (`usePageBundles: true` in front matter). This means each post is a directory containing an `index.md` file and an `images` subdirectory for its assets.
*   **Directory Organization:**
    *   `content/posts/YYYY/`: Blog posts are organized by year.
    *   `content/posts/series-name/`: Multi-part series are grouped in their own directories.
    *   `static/`: For global static assets like `robots.txt` or top-level images.
    *   `layouts/`: Contains custom Hugo templates and overrides for the `hugo-clarity` theme.
    *   `config/_default/`: Main Hugo configuration files.

### Front Matter

New posts should include comprehensive front matter for SEO and content management. Refer to `archetypes/post.md` for a basic template and `CLAUDE.md` for a more detailed example with explanations.

**Key Front Matter Fields:**
*   `title`: SEO-friendly title (under 60 characters).
*   `description`: Meta description for search engines (120-155 characters).
*   `date`: Post creation date.
*   `thumbnail`: Path to the post's thumbnail image (e.g., `./images/cover.png`).
*   `usePageBundles: true`: Must be set to `true`.
*   `categories`, `tags`, `keywords`: For content organization and SEO.
*   `isCJKLanguage`: Set to `true` for Chinese content.

### Linking

*   Use Hugo's `relref` shortcode for robust internal linking to avoid broken links.
    ```markdown
    [Link Text]({{< relref "../path/to/other-post/index.md" >}})
    ```

### SEO and Performance

The site has a strong focus on SEO and performance. Key considerations are documented in `SEO_OPTIMIZATIONS.md`. When creating or editing content, please adhere to the following:
*   Provide keyword-rich titles, descriptions, and keywords in the front matter.
*   Use a proper heading structure (H1, H2, H3).
*   Add alt text for all images.
*   Optimize images using the provided script before committing.

## Deployment

The site is automatically deployed to GitHub Pages on every push to the `master` branch. The workflow is defined in `.github/workflows/deploy.yml`. The process involves:
1.  Checking out the code.
2.  Setting up Hugo.
3.  Running the image optimization script.
4.  Building the Hugo site with minification.
5.  Committing the generated `public` directory to the `zxkane.github.io` repository.
