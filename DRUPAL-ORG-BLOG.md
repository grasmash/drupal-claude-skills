# Drupal.org Blog Post

Post this at: https://www.drupal.org/blog/YOUR_USERNAME

---

**Title**: Drupal Claude Skills: AI-Assisted Development for Drupal 9/10/11

**Body**:

I'm excited to announce **[Drupal Claude Skills](https://github.com/grasmash/drupal-claude-skills)** - the first comprehensive collection of Claude Code skills specifically designed for Drupal development.

## What is Claude Code?

[Claude Code](https://claude.com/claude-code) is Anthropic's AI coding assistant that helps with software engineering tasks. Skills extend Claude with specialized knowledge for specific frameworks and workflows - think of them as expert knowledge packs that Claude loads when working on relevant tasks.

Until now, the Claude ecosystem had skills for document manipulation, creative tools, and general web development - but nothing for CMS platforms or PHP frameworks.

## What's Included?

**Five production-ready skills:**

1. **drupal-at-your-fingertips** - 50+ Drupal development patterns from Selwyn Polit's excellent [Drupal at Your Fingertips](https://drupalatyourfingertips.com)
   - Services, hooks, events, plugins
   - Entities, fields, forms, routing
   - Theming with Twig
   - Caching and performance
   - Testing with PHPUnit and DTT

2. **drupal-contrib-mgmt** - Complete Composer and module management workflows
   - Updating contrib modules safely
   - Drupal 11 compatibility checking
   - Patch management with cweagans/composer-patches
   - Handling major version upgrades

3. **drupal-config-mgmt** - Safe configuration management patterns
   - Read-only config inspection
   - Safe Drush command patterns
   - Syncing config between environments
   - Manual config editing workflows

4. **drupal-ddev** - Complete DDEV local development reference
   - .ddev/config.yaml configuration
   - Database operations and snapshots
   - Xdebug debugging
   - macOS performance optimization with mutagen

5. **ivangrynenko-cursorrules-drupal** - OWASP Top 10 security patterns from [Ivan Grynenko](https://github.com/ivangrynenko/cursorrules)
   - SQL injection prevention
   - XSS protection
   - Access control
   - Cryptography and data protection

## Why Use These Skills?

### Context-Aware Activation

Skills activate automatically based on what you're working on:
- Updating modules? → `drupal-contrib-mgmt` activates
- Local development? → `drupal-ddev` provides patterns
- Pantheon deployment? → `drupal-pantheon` guides you
- Security review? → `ivangrynenko-cursorrules-drupal` enforces OWASP

### Battle-Tested Patterns

These aren't theoretical - they come from:
- Real production Drupal development
- Industry expert documentation
- Modern Drupal 9/10/11 workflows
- Actual security best practices

### Expert Knowledge

Built on excellent work by:
- **Selwyn Polit** - Drupal at Your Fingertips patterns
- **Ivan Grynenko** - OWASP security rules for Drupal
- The broader Drupal community

## Quick Start

### Global Installation

```bash
# Clone the repository
git clone https://github.com/grasmash/drupal-claude-skills.git

# Install globally for all projects
mkdir -p ~/.config/claude/skills
cp -r drupal-claude-skills/.claude/skills/* ~/.config/claude/skills/
```

### Project-Level Installation

```bash
# Copy to your Drupal project
cp -r drupal-claude-skills/.claude /path/to/your/drupal/project/
```

### Use with Claude Code

Once installed, just start Claude Code in your Drupal project and the relevant skills activate automatically:

```bash
cd /path/to/drupal/project
claude
```

Then ask questions like:
- "Update the webform module to latest stable"
- "Show me the DDEV config for PHP 8.3 and MariaDB 10.6"
- "What's the safe way to check config differences on Pantheon?"
- "Create a custom entity with a field for storing JSON data"

## Examples

### Safe Config Management

The `drupal-config-mgmt` skill includes patterns for safely inspecting configuration:

```bash
# Read-only inspection
drush config:status
drush config:get system.site

# Safe diff checking
drush config:import --no --diff
```

### Composer Updates

The `drupal-contrib-mgmt` skill knows how to handle complex scenarios:

```bash
# Update module with constraint handling
composer update drupal/webform --with-all-dependencies

# Check Drupal 11 compatibility
composer why-not drupal/core:^11

# Apply patches via composer.json
```

### DDEV Workflows

Complete reference for local development:

```yaml
# .ddev/config.yaml with macOS optimization
name: myproject
type: drupal10
php_version: "8.3"
database:
  type: mariadb
  version: "10.6"
performance_mode: mutagen  # 5-10x faster on macOS!
```

## Contributing

This is open source (MIT license) and contributions are welcome!

- Repository: https://github.com/grasmash/drupal-claude-skills
- Issues: https://github.com/grasmash/drupal-claude-skills/issues
- Contributing guide: [CONTRIBUTING.md](https://github.com/grasmash/drupal-claude-skills/blob/main/CONTRIBUTING.md)

Ideas for future skills:
- Drupal Commerce patterns
- Migration patterns (Drupal 7 → 10)
- Acquia Cloud Platform
- Platform.sh hosting
- Layout Builder workflows

## Links

- **GitHub**: https://github.com/grasmash/drupal-claude-skills
- **Claude Code**: https://claude.com/claude-code
- **Drupal at Your Fingertips**: https://drupalatyourfingertips.com
- **Ivan's Security Rules**: https://github.com/ivangrynenko/cursorrules

---

Let's make AI understand Drupal! 🚀

I hope this helps the community be more productive with AI-assisted development. Please try it out and share your feedback!
