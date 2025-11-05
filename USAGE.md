# Quick Start Guide

## What's Included

A comprehensive collection of Drupal development skills for Claude Code:

1. **Six Drupal Skills**:
   - `drupal-at-your-fingertips` - 50+ Drupal development patterns
   - `drupal-contrib-mgmt` - Composer-based module management
   - `drupal-config-mgmt` - Safe configuration management
   - `drupal-ddev` - Local development environment
   - `drupal-pantheon` - Pantheon platform workflows
   - `ivangrynenko-cursorrules-drupal` - OWASP security patterns

2. **Documentation**:
   - `README.md` - Comprehensive project overview
   - `LICENSE` - MIT license with third-party notices
   - `.gitignore` - Standard ignores

## For Maintainers: Syncing Updates

If you maintain a private fork with additional project-specific content, you can sync Drupal-only improvements back to this repository:

```bash
# Example sync workflow (customize for your setup)
# 1. Make improvements to Drupal skills in private repo
# 2. Filter out project-specific references
# 3. Review changes
git diff .claude/skills/drupal-*

# 4. Commit and push
git add .claude/skills/drupal-*
git commit -m "Update Drupal skills"
git push origin main
```

## Installation

### Project-Level Installation

Copy the `.claude` directory to your Drupal project root:

```bash
cp -r .claude /path/to/your/drupal/project/
```

### Global Installation

Install globally to make skills available across all projects:

```bash
mkdir -p ~/.config/claude/skills
cp -r .claude/skills/* ~/.config/claude/skills/
```

### Via Claude Code Marketplace (Recommended)

Coming soon: Install via Claude Code's plugin marketplace system.

## Updating Skills

Skills with upstream sources can be updated using the sync scripts:

```bash
# Update Drupal at Your Fingertips patterns
./.claude/scripts/sync-d9book.sh

# Update Ivan Grynenko security patterns
./.claude/scripts/sync-ivan-rules.sh
```

These scripts automatically pull the latest content from upstream sources.

## Repository Structure

```
drupal-claude-skills/
├── .claude/
│   ├── skills/
│   │   ├── drupal-at-your-fingertips/
│   │   ├── drupal-contrib-mgmt/
│   │   ├── drupal-config-mgmt/
│   │   ├── drupal-ddev/
│   │   ├── drupal-pantheon/
│   │   └── ivangrynenko-cursorrules-drupal/
│   └── scripts/
│       ├── sync-d9book.sh
│       └── sync-ivan-rules.sh
├── README.md
├── LICENSE
├── USAGE.md (this file)
└── .gitignore
```

## Usage

Once installed, skills activate automatically based on context. For example:

- Working with services → `drupal-at-your-fingertips` activates
- Updating modules → `drupal-contrib-mgmt` activates
- Managing config → `drupal-config-mgmt` activates
- Local development → `drupal-ddev` activates
- Pantheon deployment → `drupal-pantheon` activates
- Security review → `ivangrynenko-cursorrules-drupal` activates

You can also explicitly invoke a skill:
```
"Using drupal-at-your-fingertips patterns, show me how to create a custom entity"
```

## Contributing

Contributions are welcome! Please see the main [README.md](README.md) for contribution guidelines.

## Support

- **Issues**: Report on [GitHub Issues](https://github.com/grasmash/drupal-claude-skills/issues)
- **Content Questions**: Refer to upstream sources (Selwyn Polit, Ivan Grynenko)
- **Claude Code Help**: See [Claude Code docs](https://docs.claude.com/claude-code)
