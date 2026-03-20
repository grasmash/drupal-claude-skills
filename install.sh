#!/bin/bash
# Install Drupal Claude Skills into a Drupal project
# Usage: curl -s https://raw.githubusercontent.com/grasmash/drupal-claude-skills/main/install.sh | bash
#   or:  bash install.sh /path/to/your/project

set -e

TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "Error: Directory $TARGET does not exist"
  exit 1
fi

REPO_URL="https://github.com/grasmash/drupal-claude-skills.git"
TEMP_DIR=$(mktemp -d)

echo "Cloning drupal-claude-skills..."
git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR"

# Install skills
echo "Installing skills..."
mkdir -p "$TARGET/.claude/skills"
cp -r "$TEMP_DIR/skills/"* "$TARGET/.claude/skills/"

# Install agents
echo "Installing agents..."
mkdir -p "$TARGET/.claude/agents"
cp -r "$TEMP_DIR/.claude/agents/"* "$TARGET/.claude/agents/"

# Install settings (don't overwrite existing)
if [ ! -f "$TARGET/.claude/settings.json" ]; then
  echo "Installing sample settings.json..."
  cp "$TEMP_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
else
  echo "Skipping settings.json (already exists)"
fi

# Append agent workflow guide to CLAUDE.md if it exists, or create it
AGENTS_SECTION="## Agent Workflow Guide"
if [ -f "$TARGET/CLAUDE.md" ]; then
  if ! grep -q "$AGENTS_SECTION" "$TARGET/CLAUDE.md"; then
    echo ""
    echo "Your project has an existing CLAUDE.md."
    echo "Consider adding the agent workflow guide from:"
    echo "  $TEMP_DIR/AGENTS.md"
    echo ""
    echo "Key sections to copy: Parallelization, Quality Gate, Done Gate,"
    echo "Contrib/Core Patch Policy, Session Completion"
  fi
else
  echo "No CLAUDE.md found — skipping (create one for your project)"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Installed to $TARGET/.claude/"
echo "   Skills: $(ls -1 "$TARGET/.claude/skills/" | wc -l | xargs) skills"
echo "   Agents: $(ls -1 "$TARGET/.claude/agents/" | wc -l | xargs) agents"
echo ""
echo "Next steps:"
echo "  1. Review .claude/settings.json and customize for your project"
echo "  2. Add agent workflow sections to your CLAUDE.md (see AGENTS.md in the repo)"
echo "  3. Start Claude Code in your project directory"
