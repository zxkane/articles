# Markdown Export Feature

This feature allows users to copy blog posts as Markdown or open them in AI tools (Claude/ChatGPT).

## How It Works

The "Copy Page" dropdown button provides options to:
1. **Copy as Markdown** - Copy page content in LLM-optimized format
2. **Open in Claude** - Open Claude with page URL to ask questions
3. **Open in ChatGPT** - Open ChatGPT with page URL to ask questions

## Markdown Source Strategy

### Current Implementation: GitHub Raw URLs (Recommended)

The system uses GitHub raw URLs to fetch original markdown files:

```
https://raw.githubusercontent.com/zxkane/articles/master/content/posts/YYYY/post-name/index.md
```

**Benefits:**
- Preserves original formatting (tables, code blocks, etc.)
- No build pipeline changes needed
- Always up-to-date with repository

**Configuration:** `config/_default/params.toml`
```toml
[github]
repo = "zxkane/articles"
branch = "master"
contentPath = "content"
```

### Alternative: Copy Markdown During Build

If you prefer serving markdown files locally:

1. **Script:** `scripts/copy-markdown-files.sh`
   - Copies all .md files from `content/posts/` to `public/posts/`
   - Maintains directory structure

2. **GitHub Actions:** `.github/workflows/hugo-with-markdown.yml.example`
   - Example workflow that runs the copy script after Hugo build

**To enable:**
```bash
# Make script executable
chmod +x scripts/copy-markdown-files.sh

# Run after hugo build
hugo --minify
./scripts/copy-markdown-files.sh
```

## Fallback Mechanism

The JavaScript implementation tries to fetch the original markdown file first:

1. **Try:** Fetch from GitHub raw URL
   - Success: Use original markdown (perfect formatting)
   - Fail: Continue to step 2

2. **Fallback:** Convert HTML to Markdown using Turndown.js
   - Converts rendered HTML back to markdown
   - May lose some formatting (complex tables, etc.)

## AI Tool Integration

Both Claude and ChatGPT receive URLs in this format:

```
https://claude.ai/new?q=Read%20from%20https://raw.githubusercontent.com/...index.md%20so%20I%20can%20ask%20questions%20about%20it.
```

This allows AI tools to fetch the content directly from GitHub.

## Files Modified

- `layouts/partials/copy-markdown.html` - Button UI with GitHub URL
- `static/js/markdown-export.js` - Fetch logic with fallback
- `static/css/copy-markdown.css` - Responsive styles
- `config/_default/params.toml` - GitHub configuration
- `scripts/copy-markdown-files.sh` - Optional build script

## Testing

Verify GitHub URL works:
```bash
curl -I "https://raw.githubusercontent.com/zxkane/articles/master/content/posts/2025/xiaozhi-agentcore-gateway-mcp/index.md"
# Should return HTTP 200
```
