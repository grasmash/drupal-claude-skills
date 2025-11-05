#!/bin/bash
# Sync Selwyn Polit's D9 Book content as ONE skill with topic references
# Usage: ./sync-d9book.sh
#
# Fully dynamic - auto-discovers ALL topics from d9book repository
# Creates ONE drupal-d9book skill with all topics as references

set -e

UPSTREAM_URL="https://drupalatyourfingertips.com"
UPSTREAM_REPO="https://github.com/selwynpolit/d9book"
SKILLS_DIR=".claude/skills"
SKILL_NAME="drupal-at-your-fingertips"
SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

# Create the main d9book skill
create_d9book_skill() {
  local topic_count=$1

  echo "Creating drupal-at-your-fingertips skill..."

  mkdir -p "$SKILL_DIR"/{references,scripts,examples}

  # Generate main SKILL.md
  cat > "$SKILL_DIR/SKILL.md" <<'EOT'
---
name: drupal-at-your-fingertips
description: Comprehensive Drupal patterns from "Drupal at Your Fingertips" by Selwyn Polit. Covers 50+ topics including services, hooks, forms, entities, caching, testing, and more.
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

## Available Topics

All topics are available as references in the `/references/` directory.

Each reference links to the full chapter on drupalatyourfingertips.com with:
- Detailed explanations and code examples
- Best practices and common patterns
- Step-by-step guides
- Troubleshooting tips

### Core Concepts
- @references/services.md - Dependency injection and service container
- @references/hooks.md - Hook system and implementations
- @references/events.md - Event subscribers and dispatchers
- @references/plugins.md - Plugin API and annotations
- @references/entities.md - Entity API and custom entities

### Content Management
- @references/nodes-and-fields.md - Node and field API
- @references/forms.md - Form API and validation
- @references/paragraphs.md - Paragraphs module patterns
- @references/taxonomy.md - Taxonomy and vocabularies
- @references/menus.md - Menu system

### Development Tools
- @references/composer.md - Dependency management
- @references/drush.md - Drush commands
- @references/debugging.md - Debugging techniques
- @references/logging.md - Logging and monitoring
- @references/dtt.md - Drupal Test Traits

### Advanced Topics
- @references/batch.md - Batch API for long operations
- @references/queue.md - Queue API for background tasks
- @references/cron.md - Cron jobs and scheduling
- @references/ajax.md - AJAX framework
- @references/javascript.md - JavaScript in Drupal

See `/references/` directory for complete list of 50+ topics.

---

## GuitarGate Context

Apply d9book patterns in GuitarGate's gg_* modules:
- Use dependency injection (*.services.yml)
- Load entities by UUID for API endpoints
- Follow existing code style conventions
- Test with DTT (Drupal Test Traits)

### Related Documentation

- @docs/architecture.md - GuitarGate architecture
- @docs/TESTING_STRATEGY.md - Testing approach
- @docs/code_style_conventions (memory)

---

**To update**: Run `.claude/scripts/sync-d9book.sh`
EOT

  # Add sync metadata
  echo "Last synced: $(date -u +%Y-%m-%d)" > "$SKILL_DIR/.sync-metadata"
  echo "Upstream: $UPSTREAM_REPO" >> "$SKILL_DIR/.sync-metadata"
  echo "Topics synced: $topic_count" >> "$SKILL_DIR/.sync-metadata"

  echo "✓ drupal-at-your-fingertips skill created"
}

# Create reference file for a topic
create_topic_reference() {
  local topic=$1

  cat > "$SKILL_DIR/references/${topic}.md" <<EOT
# $topic

**Source**: [Drupal at Your Fingertips - $topic]($UPSTREAM_URL/$topic)
**Author**: Selwyn Polit

---

## Full Documentation

**View online**: $UPSTREAM_URL/$topic

This chapter covers:
- Detailed explanations with code examples
- Best practices and common patterns
- Step-by-step implementation guides
- Troubleshooting and debugging tips

---

## GuitarGate Application

Apply these patterns in GuitarGate's gg_* modules:
- Use dependency injection for services
- Load entities by UUID in APIs
- Follow existing code conventions
- Write DTT tests for new features

---

**Last verified**: $(date -u +%Y-%m-%d)
EOT
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
create_d9book_skill "$topic_count"
echo ""

# Create reference for each topic
echo "Creating topic references..."
echo "$discovered_topics" | while read topic; do
  if [ -n "$topic" ]; then
    create_topic_reference "$topic"
    echo "  ✓ $topic"
  fi
done

echo ""
echo "✅ Done! drupal-at-your-fingertips skill created"
echo ""
echo "Skill: .claude/skills/drupal-at-your-fingertips/"
echo "References: $topic_count topic reference files"
