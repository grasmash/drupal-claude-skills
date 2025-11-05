#!/bin/bash
# Sync Ivan Grynenko's Cursor Rules as ONE skill with topic references
# Usage: ./sync-ivan-rules.sh
#
# Fully dynamic - auto-discovers ALL drupal-*.mdc files from repository
# Creates ONE ivangrynenko-cursorrules-drupal skill with all topics as references

set -e

UPSTREAM_REPO="https://raw.githubusercontent.com/ivangrynenko/cursorrules/main/.cursor/rules"
UPSTREAM_API="https://api.github.com/repos/ivangrynenko/cursorrules/contents/.cursor/rules"
UPSTREAM_URL="https://github.com/ivangrynenko/cursorrules/blob/main/.cursor/rules"
SKILLS_DIR=".claude/skills"
SKILL_NAME="ivangrynenko-cursorrules-drupal"
SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

# Create the main security skill
create_security_skill() {
  local topic_count=$1

  echo "Creating ivangrynenko-cursorrules-drupal skill..."

  mkdir -p "$SKILL_DIR"/{references,scripts,examples}

  # Generate main SKILL.md
  cat > "$SKILL_DIR/SKILL.md" <<'EOT'
---
name: ivangrynenko-cursorrules-drupal
description: Drupal development and security patterns from Ivan Grynenko's cursor rules. Covers OWASP Top 10, authentication, access control, injection prevention, cryptography, configuration, database standards, file permissions, and more.
---

# Ivan Grynenko - Drupal Cursor Rules

**Source**: [Ivan Grynenko - Cursor Rules](https://github.com/ivangrynenko/cursorrules)
**Author**: Ivan Grynenko
**License**: MIT

## When This Skill Activates

Activates when working with Drupal security topics including:
- Authentication and session management
- Access control and permissions
- SQL injection and XSS prevention
- Cryptography and data protection
- Security configuration
- Dependency management
- SSRF prevention
- Secure design patterns
- Software integrity
- Security logging and monitoring

---

## Available Topics

All topics are available as references in the `/references/` directory.

Each reference contains:
- OWASP classification and reference
- Security patterns and anti-patterns
- Enforcement checks
- Code examples
- Best practices

### OWASP Top 10 Coverage

- @references/authentication-security.md - Authentication failures (A07:2021)
- @references/access-control-security.md - Broken access control (A01:2021)
- @references/injection-prevention.md - Injection vulnerabilities (A03:2021)
- @references/data-security.md - Cryptographic failures (A02:2021)
- @references/security-configuration.md - Security misconfiguration (A05:2021)
- @references/dependency-security.md - Vulnerable components (A06:2021)
- @references/ssrf-prevention.md - Server-side request forgery (A10:2021)
- @references/secure-design.md - Insecure design (A04:2021)
- @references/integrity-validation.md - Software integrity failures (A08:2021)
- @references/logging-security.md - Logging and monitoring failures (A09:2021)

### Additional Security Topics

- @references/database-standards.md - Database best practices
- @references/file-permissions.md - File security and access control

See `/references/` directory for complete list.

---

**To update**: Run `.claude/scripts/sync-ivan-rules.sh`
EOT

  # Add sync metadata
  echo "Last synced: $(date -u +%Y-%m-%d)" > "$SKILL_DIR/.sync-metadata"
  echo "Upstream: $UPSTREAM_URL" >> "$SKILL_DIR/.sync-metadata"
  echo "Topics synced: $topic_count" >> "$SKILL_DIR/.sync-metadata"

  echo "✓ ivangrynenko-cursorrules-drupal skill created"
}

# Map upstream filename to reference name
map_to_reference_name() {
  local upstream_name=$1
  local base_name="${upstream_name%.mdc}"

  case "$base_name" in
    drupal-authentication-failures)
      echo "authentication-security"
      ;;
    drupal-broken-access-control)
      echo "access-control-security"
      ;;
    drupal-injection)
      echo "injection-prevention"
      ;;
    drupal-cryptographic-failures)
      echo "data-security"
      ;;
    drupal-security-misconfiguration)
      echo "security-configuration"
      ;;
    drupal-vulnerable-components)
      echo "dependency-security"
      ;;
    drupal-ssrf)
      echo "ssrf-prevention"
      ;;
    drupal-insecure-design)
      echo "secure-design"
      ;;
    drupal-integrity-failures)
      echo "integrity-validation"
      ;;
    drupal-logging-failures)
      echo "logging-security"
      ;;
    drupal-database-standards)
      echo "database-standards"
      ;;
    drupal-file-permissions)
      echo "file-permissions"
      ;;
    *)
      # Default: remove drupal- prefix
      echo "${base_name#drupal-}"
      ;;
  esac
}

# Extract OWASP reference from file
extract_owasp_ref() {
  local file=$1
  grep -o 'OWASP.*A[0-9][0-9]:[0-9][0-9][0-9][0-9]' "$file" | head -1 || echo "OWASP Security"
}

# Create reference file for a topic
create_topic_reference() {
  local upstream_filename=$1
  local reference_name=$(map_to_reference_name "$upstream_filename")

  # Download the file
  local temp_file="/tmp/${upstream_filename}"
  curl -s -f "$UPSTREAM_REPO/${upstream_filename}" -o "$temp_file" || {
    echo "⚠ Failed to download $upstream_filename"
    return 1
  }

  # Extract title and OWASP reference
  local title=$(head -20 "$temp_file" | grep "^# " | head -1 | sed 's/^# //')
  local owasp_ref=$(extract_owasp_ref "$temp_file")

  cat > "$SKILL_DIR/references/${reference_name}.md" <<EOT
# ${title:-$reference_name}

**Source**: [Ivan Grynenko - ${upstream_filename}]($UPSTREAM_URL/${upstream_filename})
**Author**: Ivan Grynenko
**License**: MIT
**OWASP Reference**: $owasp_ref

---

## Full Documentation

**View online**: $UPSTREAM_URL/${upstream_filename}

This security pattern covers:
- OWASP Top 10 classification
- Common vulnerabilities and anti-patterns
- Enforcement checks for code review
- Secure coding examples
- Best practices and remediation

---

## Raw Content

\`\`\`markdown
$(cat "$temp_file")
\`\`\`

---

**Last verified**: $(date -u +%Y-%m-%d)
EOT

  rm -f "$temp_file"
}

# Discover all drupal-*.mdc files from upstream
discover_drupal_rules() {
  # Fetch all drupal-*.mdc files from repository
  local files=$(curl -s "$UPSTREAM_API" | grep -o '"name": "drupal-[^"]*\.mdc"' | cut -d'"' -f4)

  if [ -z "$files" ]; then
    echo "⚠ Could not discover files via API"
    return 1
  fi

  echo "$files"
}

# Main execution
echo "Auto-discovering all drupal-*.mdc files from upstream..."
echo ""

discovered_topics=$(discover_drupal_rules)

if [ -z "$discovered_topics" ]; then
  echo "❌ Could not discover topics from Ivan's repository"
  exit 1
fi

# Get count
topic_count=$(echo "$discovered_topics" | wc -l | xargs)
echo "Found $topic_count security topics"
echo ""

# Remove old skills (both individual security skills and drupal-security-owasp)
echo "Removing old skills..."
rm -rf "$SKILLS_DIR"/drupal-security-owasp \
       "$SKILLS_DIR"/drupal-authentication-security \
       "$SKILLS_DIR"/drupal-access-control-security \
       "$SKILLS_DIR"/drupal-injection-prevention \
       "$SKILLS_DIR"/drupal-data-security \
       "$SKILLS_DIR"/drupal-security-configuration \
       "$SKILLS_DIR"/drupal-dependency-security \
       "$SKILLS_DIR"/drupal-ssrf-prevention \
       "$SKILLS_DIR"/drupal-secure-design \
       "$SKILLS_DIR"/drupal-integrity-validation \
       "$SKILLS_DIR"/drupal-logging-security \
       "$SKILLS_DIR"/drupal-database-standards \
       "$SKILLS_DIR"/drupal-file-permissions
echo ""

# Create the main skill first
create_security_skill "$topic_count"
echo ""

# Create reference for each topic
echo "Creating security topic references..."
echo "$discovered_topics" | while read filename; do
  if [ -n "$filename" ]; then
    reference_name=$(map_to_reference_name "$filename")
    create_topic_reference "$filename"
    echo "  ✓ $reference_name"
  fi
done

echo ""
echo "✅ Done! ivangrynenko-cursorrules-drupal skill created"
echo ""
echo "Skill: .claude/skills/ivangrynenko-cursorrules-drupal/"
echo "References: $topic_count topic reference files"
