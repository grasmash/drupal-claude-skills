# Drupal Claude Skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-orange.svg)](https://claude.com/claude-code)
[![Drupal](https://img.shields.io/badge/Drupal-9%20%7C%2010%20%7C%2011-blue.svg)](https://www.drupal.org)
[![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-green.svg)](https://docs.anthropic.com/en/docs/claude-code)

A comprehensive collection of Claude AI skills for Drupal development, covering best practices, security patterns, configuration management, and module updates.

> **First comprehensive skill collection for Drupal + Claude Code** - Install these battle-tested skills to supercharge your Drupal development workflow with AI assistance.

## Overview

These skills are designed to work with [Claude Code](https://claude.com/claude-code) and provide context-aware assistance for Drupal development tasks. They include comprehensive patterns from industry experts and cover modern Drupal 9, 10, and 11 development.

## Installation

### Via Claude Code Plugin System (Recommended)

The easiest way to install these skills is via the Claude Code plugin system:

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

If you prefer manual installation or need to customize:

**Project-level:**
```bash
# Clone the repository
git clone https://github.com/grasmash/drupal-claude-skills.git

# Copy skills to your project
mkdir -p /path/to/your/drupal/project/.claude/skills
cp -r drupal-claude-skills/skills/* /path/to/your/drupal/project/.claude/skills/
```

**Global installation:**
```bash
mkdir -p ~/.config/claude/skills
cp -r skills/* ~/.config/claude/skills/
```

## Included Skills

### 1. Drupal at Your Fingertips
**Source**: [drupalatyourfingertips.com](https://drupalatyourfingertips.com) by Selwyn Polit

Comprehensive Drupal patterns covering 50+ topics including:
- Core APIs (services, hooks, events, plugins)
- Content management (nodes, fields, entities, paragraphs, taxonomy)
- Forms and validation
- Routing and controllers
- Theming (Twig, render arrays, preprocess)
- Caching and performance
- Testing (PHPUnit, Drupal Test Traits)
- Common patterns and best practices

**Location**: `skills/drupal-at-your-fingertips/`

### 2. Drupal Contrib Module Management
Comprehensive guide for managing Drupal contributed modules, including:
- Composer-based module update workflows
- Drupal 11 compatibility checking
- Patch management with cweagans/composer-patches
- Drupal Lenient plugin usage
- Major version upgrade patterns
- Troubleshooting dependency issues

**Location**: `skills/drupal-contrib-mgmt/`

### 3. Drupal Configuration Management
Safe patterns for inspecting and syncing Drupal configuration:
- Read-only config inspection techniques
- Avoiding accidental config imports
- Safe remote drush patterns with `--no` flag
- Syncing config between environments
- Manual config editing workflows

**Location**: `skills/drupal-config-mgmt/`

### 4. DDEV Local Development
DDEV local development environment for Drupal:
- .ddev/config.yaml complete reference
- Essential DDEV commands and workflows
- Database import/export operations
- Xdebug debugging setup
- Performance optimization (mutagen for macOS)
- Custom commands and hooks

**Location**: `skills/drupal-ddev/`

### 5. Ivan Grynenko - Drupal Security Patterns
**Source**: [Ivan Grynenko's Cursor Rules](https://github.com/ivangrynenko/cursorrules)

OWASP Top 10 security patterns for Drupal:
- Authentication and session management
- Access control and permissions
- SQL injection and XSS prevention
- Cryptography and data protection
- Security configuration
- Dependency management
- SSRF prevention
- Secure design patterns
- Software integrity and logging

**Location**: `skills/ivangrynenko-cursorrules-drupal/`

## Usage

Once installed, Claude will automatically activate the appropriate skill based on your task context. For example:

- Working with service injection → `drupal-at-your-fingertips` activates
- Updating a module → `drupal-composer-updates` activates
- Checking security → `ivangrynenko-cursorrules-drupal` activates
- Managing config → `drupal-config-mgmt` activates

You can also explicitly invoke a skill by mentioning it in your prompt:
```
"Using the drupal-at-your-fingertips patterns, show me how to create a custom entity"
```

## Plugin Structure

This repository is structured as a Claude Code plugin:

```
drupal-claude-skills/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest
│   └── marketplace.json     # Self-hosted marketplace catalog
├── skills/                  # All Drupal skills
│   ├── drupal-at-your-fingertips/
│   ├── drupal-contrib-mgmt/
│   ├── drupal-config-mgmt/
│   ├── drupal-ddev/
│   └── ivangrynenko-cursorrules-drupal/
├── scripts/                 # Upstream sync scripts
├── README.md
├── USAGE.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── LICENSE
```

## Updating

**Via Plugin System:**
```bash
claude plugin update drupal-skills@drupal-plugins
```

**Via Git (manual installation):**
```bash
cd ~/Sites/drupal-claude-skills
git pull origin main
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Maintain skill structure**: Each skill should have a `SKILL.md` file with metadata
2. **Include references**: Place detailed documentation in `references/` subdirectories
3. **Credit sources**: Always attribute original authors and link to source material
4. **Test thoroughly**: Verify skills work with Claude Code before submitting
5. **Follow Drupal standards**: Align with official Drupal coding standards

### Skill Structure

```
skills/
├── skill-name/
│   ├── SKILL.md              # Main skill file with metadata
│   └── references/           # Detailed reference documentation
│       ├── topic1.md
│       └── topic2.md
└── simple-skill.md           # For single-file skills
```

### Skill File Format

```markdown
---
name: skill-name
description: Brief description of when this skill activates
---

# Skill Name

**Source**: [Link to original content]
**Author**: Author name
**License**: License type

## When This Skill Activates

Description of contexts that activate this skill

## Available Topics

List of topics covered with links to references

## Usage Patterns

Common patterns and examples
```

## License

This collection includes content from multiple sources:

- **Drupal at Your Fingertips**: Open access documentation by Selwyn Polit
- **Ivan Grynenko Cursor Rules**: MIT License
- **Original compilation and scripts**: MIT License (see LICENSE file)

Please respect individual content licenses when using or distributing.

## Credits

- **Selwyn Polit** - [Drupal at Your Fingertips](https://drupalatyourfingertips.com)
- **Ivan Grynenko** - [Cursor Rules for Drupal](https://github.com/ivangrynenko/cursorrules)
- **Drupal Community** - For ongoing contributions to documentation and best practices

## Related Resources

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Claude Code Plugins](https://docs.anthropic.com/en/docs/claude-code)
- [Drupal.org](https://drupal.org)
- [Drupal API Reference](https://api.drupal.org)
- [Upgrade Status Module](https://www.drupal.org/project/upgrade_status)

## Support

For issues or questions:
- Open an issue on GitHub
- Refer to individual skill sources for content-specific questions
- Check [Claude Code documentation](https://docs.claude.com/claude-code) for skill usage

## Why These Skills?

### Fills a Gap
The Claude Code ecosystem has skills for document manipulation, creative tools, and web development - but **nothing for CMS/PHP frameworks**. This is the first comprehensive skill collection for Drupal development.

### Battle-Tested
These patterns come from:
- Years of production Drupal development
- Industry expert documentation (Selwyn Polit, Ivan Grynenko)
- Real-world security best practices (OWASP Top 10)
- Modern Drupal 9/10/11 workflows

### Context-Aware
Skills activate automatically based on your task:
- Updating modules? `drupal-contrib-mgmt` activates
- Local development? `drupal-ddev` provides DDEV patterns
- Security review? `ivangrynenko-cursorrules-drupal` enforces OWASP
- Configuration management? `drupal-config-mgmt` ensures safety

## Roadmap

Future skills to add:
- [ ] Drupal performance optimization patterns
- [ ] Advanced theming with SDC (Single Directory Components)
- [ ] API-first/Headless Drupal patterns
- [ ] Drupal Commerce patterns
- [ ] Migration patterns (Migrate API, Drupal 7 → 10)
- [ ] Platform-specific hosting patterns (Acquia, Platform.sh, etc.)

Want to contribute a skill? See [CONTRIBUTING.md](CONTRIBUTING.md)!

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=grasmash/drupal-claude-skills&type=Date)](https://star-history.com/#grasmash/drupal-claude-skills&Date)

---

Made with ❤️ for the Drupal community by developers who believe AI should understand your stack
