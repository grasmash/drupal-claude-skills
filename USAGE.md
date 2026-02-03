# Quick Start Guide

## What's Included

A comprehensive collection of Drupal development skills for Claude Code:

1. **Five Drupal Skills**:
   - `drupal-at-your-fingertips` - 50+ Drupal development patterns
   - `drupal-contrib-mgmt` - Composer-based module management
   - `drupal-config-mgmt` - Safe configuration management
   - `drupal-ddev` - Local development environment
   - `ivangrynenko-cursorrules-drupal` - OWASP security patterns

2. **Plugin Structure**:
   - `.claude-plugin/plugin.json` - Plugin manifest
   - `.claude-plugin/marketplace.json` - Self-hosted marketplace

## Installation

### Via Claude Code Plugin System (Recommended)

The easiest way to install:

**Using the CLI:**
```bash
# Add the marketplace
claude plugin marketplace add grasmash/drupal-claude-skills

# Install the plugin
claude plugin install drupal-skills@drupal-plugins
```

**Using the interactive prompt:**
```
/plugin marketplace add grasmash/drupal-claude-skills
/plugin install drupal-skills@drupal-plugins
```

**Installation Scopes:**
```bash
# User-level (default) - available across all projects
claude plugin install drupal-skills@drupal-plugins

# Project-level - shared via version control
claude plugin install drupal-skills@drupal-plugins --scope project

# Local only - project-specific, gitignored
claude plugin install drupal-skills@drupal-plugins --scope local
```

### Manual Installation

**Project-level:**
```bash
mkdir -p /path/to/your/drupal/project/.claude/skills
cp -r skills/* /path/to/your/drupal/project/.claude/skills/
```

**Global installation:**
```bash
mkdir -p ~/.config/claude/skills
cp -r skills/* ~/.config/claude/skills/
```

## Updating Skills

**Via Plugin System:**
```bash
claude plugin update drupal-skills@drupal-plugins
```

**Via sync scripts (for maintainers):**
```bash
# Update Drupal at Your Fingertips patterns
./scripts/sync-d9book.sh

# Update Ivan Grynenko security patterns
./scripts/sync-ivan-rules.sh
```

## Repository Structure

```
drupal-claude-skills/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest
│   └── marketplace.json     # Self-hosted marketplace
├── skills/
│   ├── drupal-at-your-fingertips/
│   ├── drupal-contrib-mgmt/
│   ├── drupal-config-mgmt/
│   ├── drupal-ddev/
│   └── ivangrynenko-cursorrules-drupal/
├── scripts/
│   ├── sync-d9book.sh
│   └── sync-ivan-rules.sh
├── README.md
├── USAGE.md (this file)
├── CONTRIBUTING.md
├── CHANGELOG.md
└── LICENSE
```

## Usage

Once installed, skills activate automatically based on context. For example:

- Working with services → `drupal-at-your-fingertips` activates
- Updating modules → `drupal-contrib-mgmt` activates
- Managing config → `drupal-config-mgmt` activates
- Local development → `drupal-ddev` activates
- Security review → `ivangrynenko-cursorrules-drupal` activates

You can also explicitly invoke a skill:
```
"Using drupal-at-your-fingertips patterns, show me how to create a custom entity"
```

## For Maintainers: Syncing Updates

If you maintain a fork with additional content:

```bash
# Make improvements to Drupal skills
# Review changes
git diff skills/drupal-*

# Commit and push
git add skills/drupal-*
git commit -m "Update Drupal skills"
git push origin main
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Support

- **Issues**: Report on [GitHub Issues](https://github.com/grasmash/drupal-claude-skills/issues)
- **Content Questions**: Refer to upstream sources (Selwyn Polit, Ivan Grynenko)
- **Claude Code Help**: See [Claude Code docs](https://docs.claude.com/claude-code)
