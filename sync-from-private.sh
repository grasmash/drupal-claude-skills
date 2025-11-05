#!/bin/bash

# Sync Drupal skills from private GuitarGate repository to open-source repository
# Usage: ./sync-from-private.sh [/path/to/private/repo]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default source repository path
DEFAULT_SOURCE_REPO="$HOME/Sites/gg"
SOURCE_REPO="${1:-$DEFAULT_SOURCE_REPO}"

# Target repository is current directory
TARGET_REPO="$(pwd)"

echo -e "${GREEN}=== Drupal Claude Skills Sync ===${NC}"
echo "Source: $SOURCE_REPO"
echo "Target: $TARGET_REPO"
echo ""

# Verify source repository exists
if [ ! -d "$SOURCE_REPO" ]; then
    echo -e "${RED}Error: Source repository not found at $SOURCE_REPO${NC}"
    echo "Usage: $0 [/path/to/private/repo]"
    exit 1
fi

# Verify source has .claude/skills directory
if [ ! -d "$SOURCE_REPO/.claude/skills" ]; then
    echo -e "${RED}Error: Source repository missing .claude/skills directory${NC}"
    exit 1
fi

# Verify we're in the target repository
if [ ! -d "$TARGET_REPO/.git" ]; then
    echo -e "${RED}Error: Not in a git repository. Run this script from drupal-claude-skills directory.${NC}"
    exit 1
fi

# List of Drupal-specific skills to sync (excluding GuitarGate-specific ones)
DRUPAL_SKILLS=(
    "drupal-at-your-fingertips"
    "drupal-composer-updates"
    "drupal-config-mgmt"
    "drupal-pantheon"
    "ivangrynenko-cursorrules-drupal"
)

# Scripts to sync
DRUPAL_SCRIPTS=(
    "sync-d9book.sh"
    "sync-ivan-rules.sh"
)

# Check for uncommitted changes in target
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Warning: You have uncommitted changes in target repository${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Sync cancelled."
        exit 1
    fi
fi

# Create backup branch
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}Creating backup branch: $BACKUP_BRANCH${NC}"
git branch "$BACKUP_BRANCH"

# Function to remove GuitarGate sections from a file
remove_guitargate_section() {
    local file="$1"

    # Skip if file doesn't contain GuitarGate references
    if ! grep -q "## GuitarGate" "$file" 2>/dev/null; then
        return 0
    fi

    # Create temp file
    local tmpfile=$(mktemp)

    # Process file with awk to remove GuitarGate sections
    awk '
        /^## GuitarGate (Context|Application)/ {
            skip = 1
            next
        }
        /^## / && skip {
            skip = 0
        }
        /^---/ && skip {
            skip = 0
            print
            next
        }
        !skip
    ' "$file" > "$tmpfile"

    # Replace original
    mv "$tmpfile" "$file"
    echo "  → Removed GuitarGate references from $(basename "$file")"
}

# Sync scripts
echo ""
echo -e "${GREEN}Syncing upstream sync scripts...${NC}"
mkdir -p "$TARGET_REPO/.claude/scripts"

for script in "${DRUPAL_SCRIPTS[@]}"; do
    SOURCE_PATH="$SOURCE_REPO/.claude/scripts/$script"
    TARGET_PATH="$TARGET_REPO/.claude/scripts/$script"

    if [ -f "$SOURCE_PATH" ]; then
        # Copy script and remove GuitarGate references
        cp "$SOURCE_PATH" "$TARGET_PATH"
        remove_guitargate_section "$TARGET_PATH"
        echo -e "${GREEN}  ✓ $script${NC}"
    else
        echo -e "${YELLOW}  ⚠ $script not found in source${NC}"
    fi
done

# Sync each skill
echo ""
echo -e "${GREEN}Syncing skills...${NC}"
for skill in "${DRUPAL_SKILLS[@]}"; do
    echo -e "\n${YELLOW}→ Syncing: $skill${NC}"

    SOURCE_PATH="$SOURCE_REPO/.claude/skills/$skill"
    TARGET_PATH="$TARGET_REPO/.claude/skills/$skill"

    if [ ! -e "$SOURCE_PATH" ]; then
        echo -e "${RED}  ✗ Not found in source repository${NC}"
        continue
    fi

    # Ensure target directory exists
    mkdir -p "$(dirname "$TARGET_PATH")"

    # Copy skill (preserve directory structure)
    if [ -d "$SOURCE_PATH" ]; then
        # It's a directory
        rsync -av --delete "$SOURCE_PATH/" "$TARGET_PATH/"
        echo -e "${GREEN}  ✓ Directory synced${NC}"

        # Remove GuitarGate references from all markdown files
        echo -e "${YELLOW}  → Cleaning GuitarGate references...${NC}"
        find "$TARGET_PATH" -name "*.md" -type f | while read -r mdfile; do
            remove_guitargate_section "$mdfile"
        done
    else
        # It's a file
        cp "$SOURCE_PATH" "$TARGET_PATH"
        remove_guitargate_section "$TARGET_PATH"
        echo -e "${GREEN}  ✓ File synced${NC}"
    fi
done

# Check for changes
if git diff --quiet && git diff --cached --quiet; then
    echo -e "\n${GREEN}✓ No changes detected - skills are already up to date${NC}"
    echo -e "${YELLOW}Removing backup branch...${NC}"
    git branch -d "$BACKUP_BRANCH"
    exit 0
fi

# Show what changed
echo ""
echo -e "${GREEN}=== Changes detected ===${NC}"
git status --short

echo ""
echo -e "${YELLOW}Review changes with:${NC}"
echo "  git diff"
echo ""
echo -e "${YELLOW}To commit changes:${NC}"
echo "  git add .claude"
echo "  git commit -m 'Sync Drupal skills from private repository'"
echo ""
echo -e "${YELLOW}To revert changes:${NC}"
echo "  git reset --hard HEAD"
echo "  git clean -fd"
echo ""
echo -e "${GREEN}Backup branch created: $BACKUP_BRANCH${NC}"
echo "Delete backup with: git branch -d $BACKUP_BRANCH"
