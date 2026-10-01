#!/bin/bash
# Sync Selwyn Polit's D9 Book content as ONE skill with topic references
# Usage: ./sync-d9book.sh
#
# Fully dynamic - auto-discovers ALL topics from d9book repository
# Regenerates the drupal-at-your-fingertips SKILL.md topic index; reference
# files under references/ are hand-maintained and never generated

set -e

UPSTREAM_URL="https://drupalatyourfingertips.com"
UPSTREAM_REPO="https://github.com/selwynpolit/d9book"
SKILLS_DIR="skills"
SKILL_NAME="drupal-at-your-fingertips"
SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

# Create the main d9book skill. Topics with a hand-maintained reference file
# under references/ are linked in depth; every other chapter is linked online.
# Reference files are never generated, so a re-sync cannot create stubs.
create_d9book_skill() {
  local topic_count=$1
  local topics=$2

  echo "Creating drupal-at-your-fingertips skill..."

  mkdir -p "$SKILL_DIR/references"

  local in_depth="" online="" n_depth=0 n_online=0 topic title
  for topic in $topics; do
    if [ -f "$SKILL_DIR/references/${topic}.md" ]; then
      title=$(head -1 "$SKILL_DIR/references/${topic}.md" | sed 's/^# *//')
      in_depth="${in_depth}- @references/${topic}.md - ${title}"$'\n'
      n_depth=$((n_depth + 1))
    else
      online="${online}- [${topic}](${UPSTREAM_URL}/${topic})"$'\n'
      n_online=$((n_online + 1))
    fi
  done

  # Generate main SKILL.md
  {
    cat <<'EOT'
---
name: drupal-at-your-fingertips
description: "Drupal 9-11 core API patterns from Selwyn Polit's book \"Drupal at Your Fingertips\". In-depth references cover services and dependency injection, hooks, events, plugins, entities, Form API, routes and controllers, Twig, caching, AJAX, database queries, configuration, Paragraphs, and Drupal Test Traits; every other chapter (views, blocks, migrate, drush, taxonomy, and more) is linked online. Use when writing or reviewing custom Drupal module or theme code and a worked example or API refresher is needed for one of these subsystems."
---

# Drupal at Your Fingertips

**Source**: [drupalatyourfingertips.com](https://drupalatyourfingertips.com)
**Author**: Selwyn Polit
**License**: Open access documentation

## When This Skill Activates

Activates when working with Drupal development topics covered in the d9book including:
- Core APIs (services, hooks, events, plugins)
- Content (nodes, fields, entities, paragraphs, taxonomy)
- Forms and validation
- Routing and controllers
- Theming (Twig, render arrays, preprocess)
- Caching and performance
- Testing (PHPUnit, DTT)
- Common patterns and best practices

---

EOT
    echo "## Topics"
    echo ""
    echo "${n_depth} topics have in-depth reference files in this skill; the other ${n_online} chapters of the book are linked online."
    echo ""
    echo "### In depth (references/)"
    echo ""
    printf '%s' "$in_depth"
    echo ""
    echo "### Online chapters (drupalatyourfingertips.com)"
    echo ""
    printf '%s' "$online"
    echo ""
    echo "---"
    echo ""
    echo "**To update**: Run \`.claude/scripts/sync-d9book.sh\`"
  } > "$SKILL_DIR/SKILL.md"

  # Add sync metadata
  echo "Last synced: $(date -u +%Y-%m-%d)" > "$SKILL_DIR/.sync-metadata"
  echo "Upstream: $UPSTREAM_REPO" >> "$SKILL_DIR/.sync-metadata"
  echo "Topics synced: $topic_count" >> "$SKILL_DIR/.sync-metadata"

  echo "✓ drupal-at-your-fingertips skill created"
}

# Discover all .md files from d9book repository
discover_d9book_topics() {
  # Fetch all .md files from book/ directory
  local files=$(curl -s "https://api.github.com/repos/selwynpolit/d9book/contents/book" | \
    jq -r '.[] | select(.name | endswith(".md")) | .name' | \
    sed 's/\.md$//')

  if [ -z "$files" ]; then
    echo "⚠ Could not discover files via API"
    return 1
  fi

  echo "$files"
}

# Main execution
echo "Auto-discovering all topics from d9book repository..."
echo ""

discovered_topics=$(discover_d9book_topics)

if [ -z "$discovered_topics" ]; then
  echo "❌ Could not discover topics from d9book"
  exit 1
fi

# Get count
topic_count=$(echo "$discovered_topics" | wc -l | xargs)
echo "Found $topic_count topics in d9book"
echo ""

# Create the main skill first
create_d9book_skill "$topic_count" "$discovered_topics"
echo ""

echo ""
echo "✅ Done! drupal-at-your-fingertips skill created"
echo ""
echo "Skill: skills/drupal-at-your-fingertips/"
echo "Topics indexed: $topic_count (reference files under references/ are hand-maintained)"
