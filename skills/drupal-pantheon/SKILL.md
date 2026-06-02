---
name: drupal-pantheon
description: Pantheon platform patterns including pantheon.yml configuration, Terminus CLI workflows, environment management, and deployment best practices.
---

# Drupal Pantheon Platform

Comprehensive patterns for developing and deploying Drupal on Pantheon, including platform configuration, Terminus CLI usage, and workflow best practices.

## When This Skill Activates

Activates when working with Pantheon-specific topics including:
- pantheon-systems/drupal-integrations package setup
- pantheon.yml configuration
- Terminus CLI commands
- Environment management (dev, test, live, multidev)
- Deployment workflows
- Platform integrations (Solr, Redis, New Relic)
- Performance optimization
- Backup and restore operations

---

## Available Topics

### Core Configuration
- @references/drupal-integrations.md - Pantheon Drupal integrations package
- @references/pantheon-yml.md - Platform configuration file
- @references/php-versions.md - PHP version management
- @references/database-versions.md - MariaDB version selection

### Terminus CLI
- @references/terminus-basics.md - Essential Terminus commands
- @references/terminus-drush.md - Safe drush command patterns
- @references/terminus-environments.md - Environment operations
- @references/terminus-multidev.md - Multidev workflow

### Platform Features
- @references/solr-search.md - Pantheon Search (Solr) integration
- @references/redis-cache.md - Object cache configuration
- @references/new-relic.md - APM monitoring
- @references/autopilot.md - Visual regression testing

### Deployment Workflows
- @references/deployment-best-practices.md - Safe deployment patterns
- @references/quicksilver.md - Platform hooks and automation
- @references/backup-restore.md - Backup strategies

See `/references/` directory for complete documentation.

---

## Quick Reference

### pantheon.yml Configuration

```yaml
api_version: 1
web_docroot: true          # Use web/ or docroot/ subdirectory
drush_version: 12          # Drush 12 for Drupal 10+
php_version: 8.3           # PHP 8.1, 8.2, or 8.3
database:
  version: 10.6            # MariaDB 10.4 or 10.6
search:
  version: 8               # Solr 8
```

### Essential Terminus Commands

```bash
# Authentication
terminus auth:login --email=you@example.com
terminus auth:whoami

# Environment info
terminus env:list site-name
terminus env:info site-name.env

# Code deployment
terminus env:deploy site-name.test --sync-content --note="Deploy message"
terminus env:deploy site-name.live --note="Deploy message"

# Database operations
terminus backup:create site-name.env --element=db
terminus backup:get site-name.env --element=db --to=backup.sql.gz
terminus import:database site-name.env backup.sql.gz

# Clear cache
terminus env:clear-cache site-name.env

# Drush (CRITICAL: always use --no flag for safety)
terminus drush site-name.env -- cr
terminus drush site-name.env -- config:status
```

### Safe Terminus Drush Pattern

**CRITICAL**: Terminus defaults to `--yes` for all prompts. Always use `--no` for inspection commands:

```bash
# ✅ SAFE - Won't auto-import
terminus drush site.env -- cim --no --diff

# ❌ DANGEROUS - Will auto-import!
terminus drush site.env -- cim --diff
```

---

## Common Patterns

### Deploy from Dev → Test → Live

```bash
# 1. Commit code to dev
git add -A && git commit -m "Feature complete"
git push origin master

# 2. Deploy to test with database sync
terminus env:deploy site.test --sync-content --note="Deploy feature X"

# 3. Test on test environment
# Visit https://test-site.pantheonsite.io

# 4. Deploy to live (no sync)
terminus env:deploy site.live --note="Deploy feature X"

# 5. Clear cache
terminus env:clear-cache site.live
```

### Create Multidev Environment

```bash
# Create from dev
terminus multidev:create site.dev multidev-name

# Or from existing environment
terminus multidev:create site.test multidev-name

# Work on multidev
terminus drush site.multidev-name -- cr

# Merge back to dev
terminus multidev:merge-to-dev site.multidev-name

# Delete when done
terminus multidev:delete site.multidev-name
```

### Database Sync Between Environments

```bash
# Clone database from live to test
terminus env:clone-content site.live test --db-only

# Or use backup/restore
terminus backup:create site.live --element=db
terminus backup:restore site.test --element=db
```

---

## Best Practices

1. **Always use `--no` flag** with Terminus drush for inspection commands
2. **Test deploys on test environment** before pushing to live
3. **Include deployment notes** with `--note` flag for audit trail
4. **Use multidev** for feature development and testing
5. **Regular backups** before major deployments
6. **Monitor New Relic** after deployments for performance issues
7. **Clear cache** after code and config deployments
8. **Version pin** PHP and database in pantheon.yml

---

## Platform Limits and Considerations

- **File upload**: 100MB per file (256MB on elite plans)
- **Execution timeout**: 120 seconds for web requests
- **PHP memory**: 512MB (can request increase)
- **Database**: InnoDB only, no MyISAM
- **Git repository**: 2GB soft limit
- **Multidev**: 10 environments (more on elite plans)

---

## Related Skills

- @drupal-config-mgmt - Safe config management with Terminus
- @drupal-composer-updates - Module updates and dependencies
- @drupal-at-your-fingertips - General Drupal development patterns

---

**Official Documentation**: https://docs.pantheon.io
**Terminus Documentation**: https://pantheon.io/docs/terminus
**Community**: https://pantheon.io/developers/community
