#!/bin/bash
# Pre-commit hook: Check if SEO optimization was run for blog posts
# Exit 0 = allow, Exit 2 = block (Claude Code convention)

# Check for required dependencies
if ! command -v jq &> /dev/null; then
    echo "Warning: jq not installed, skipping SEO optimization check" >&2
    exit 0  # Allow operation to continue
fi

STATE_MANAGER="$(dirname "$0")/state-manager.sh"

# Read tool input from stdin (JSON)
TOOL_INPUT=$(cat)

# Extract the actual command from JSON
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check for git commit commands (not other commands)
if ! echo "$COMMAND" | grep -qE '^git\s+commit'; then
    exit 0  # Not a commit, allow
fi

# Check if any blog post files are staged
STAGED_POSTS=$(git diff --cached --name-only 2>/dev/null | grep -E '^content/posts/.*\.(md|markdown)$' || true)

# If no blog posts are staged, allow commit without SEO check
if [ -z "$STAGED_POSTS" ]; then
    exit 0  # No posts to check, allow
fi

# Check if seo-optimization was completed
if "$STATE_MANAGER" check seo-optimization >/dev/null 2>&1; then
    exit 0  # Allow
else
    # Output message to stderr for Claude to see
    cat >&2 << 'EOF'
**[run-seo-optimization-before-commit]**
## Blog Post SEO Optimization Required

Before committing blog posts, you must run SEO optimization:

1. **Run SEO optimization skill:**
   ```
   /seo-technical-optimization
   ```
   Or use the SEO analysis agent to review the post.

2. **Mark as completed:**
   ```bash
   .claude/hooks/state-manager.sh mark seo-optimization
   ```

3. **Retry the commit**

**Skip conditions:** For non-content changes (config, theme, etc.), run:
```bash
.claude/hooks/state-manager.sh mark seo-optimization
```

**Staged blog posts detected:**
EOF
    echo "$STAGED_POSTS" | sed 's/^/  - /' >&2
    exit 2  # Block (exit code 2 is Claude Code's blocking code)
fi
