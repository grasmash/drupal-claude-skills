# Drupal Claude Skills

A collection of Claude AI skills for Drupal development, covering best practices, security patterns, configuration management, and module updates.

## Overview

These skills are designed to work with [Claude Code](https://claude.com/claude-code) and provide context-aware assistance for Drupal development tasks. They include comprehensive patterns from industry experts and cover modern Drupal 9, 10, and 11 development.

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

**Location**: `.claude/skills/drupal-at-your-fingertips/`

### 2. Drupal Contrib Module Management
Comprehensive guide for managing Drupal contributed modules, including:
- Composer-based module update workflows
- Drupal 11 compatibility checking
- Patch management with cweagans/composer-patches
- Drupal Lenient plugin usage
- Major version upgrade patterns
- Troubleshooting dependency issues

**Location**: `.claude/skills/drupal-contrib-mgmt/`

### 3. Drupal Configuration Management
Safe patterns for inspecting and syncing Drupal configuration:
- Read-only config inspection techniques
- Avoiding accidental config imports
- Terminus drush patterns with `--no` flag
- Syncing config between environments
- Manual config editing workflows

**Location**: `.claude/skills/drupal-config-mgmt/`

### 4. Drupal Pantheon Platform
Pantheon hosting platform patterns and workflows:
- pantheon.yml configuration (PHP, database, Solr versions)
- Terminus CLI safe command patterns
- Environment management (dev, test, live, multidev)
- Deployment workflows and best practices
- Quicksilver platform hooks
- Platform limits and considerations

**Location**: `.claude/skills/drupal-pantheon/`

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

**Location**: `.claude/skills/ivangrynenko-cursorrules-drupal/`

## Installation

### For Claude Code CLI

1. Copy the `.claude` directory to your Drupal project root:
   ```bash
   cp -r .claude /path/to/your/drupal/project/
   ```

2. The skills will automatically be available in Claude Code when working in that project.

### For Global Use

To make these skills available across all your projects:

1. Copy to your Claude config directory (create if it doesn't exist):
   ```bash
   mkdir -p ~/.config/claude/skills
   cp -r .claude/skills/* ~/.config/claude/skills/
   ```

2. Or create a symbolic link:
   ```bash
   ln -s /path/to/drupal-claude-skills/.claude/skills ~/.config/claude/skills/drupal
   ```

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

## Updating Skills

The original skills are maintained in a private repository. To sync updates:

```bash
# Clone this repository
cd ~/Sites/drupal-claude-skills

# Pull latest changes
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
.claude/skills/
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
- [Drupal.org](https://drupal.org)
- [Drupal API Reference](https://api.drupal.org)
- [Upgrade Status Module](https://www.drupal.org/project/upgrade_status)

## Support

For issues or questions:
- Open an issue on GitHub
- Refer to individual skill sources for content-specific questions
- Check [Claude Code documentation](https://docs.claude.com/claude-code) for skill usage

## Roadmap

Future skills to add:
- [ ] Drupal performance optimization patterns
- [ ] Advanced theming with SDC (Single Directory Components)
- [ ] API-first/Headless Drupal patterns
- [ ] Commerce module patterns
- [ ] Migration patterns

---

Made with ❤️ for the Drupal community
