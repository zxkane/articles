#!/bin/bash
# Copy original markdown files to public directory
# This script runs after Hugo build to make .md files accessible

set -e

CONTENT_DIR="content/posts"
PUBLIC_DIR="public/posts"

echo "Copying markdown files to public directory..."

# Create public/posts directory structure
mkdir -p "$PUBLIC_DIR"

# Find all index.md files and copy maintaining structure
find "$CONTENT_DIR" -name "index.md" -o -name "*.md" | while read -r md_file; do
  # Get relative path from content/posts/
  rel_path="${md_file#$CONTENT_DIR/}"

  # Create target directory
  target_dir="$PUBLIC_DIR/$(dirname "$rel_path")"
  mkdir -p "$target_dir"

  # Copy markdown file
  cp "$md_file" "$target_dir/"

  echo "Copied: $md_file -> $target_dir/"
done

echo "✓ Markdown files copied successfully!"
