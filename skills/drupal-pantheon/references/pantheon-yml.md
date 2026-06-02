# pantheon.yml Configuration

**Official Docs**: https://docs.pantheon.io/pantheon-yml

The `pantheon.yml` file configures your Pantheon platform settings and must be in your repository root.

---

## Complete Configuration Reference

```yaml
api_version: 1

# Web docroot - use true for web/ or docroot/ subdirectory
web_docroot: true

# PHP version (8.1, 8.2, 8.3)
php_version: 8.3

# Drush version (12 for Drupal 10+, 11 for Drupal 9)
drush_version: 12

# MariaDB version (10.4 or 10.6)
database:
  version: 10.6

# Solr search version
search:
  version: 8

# Protected web paths (prevent public access)
protected_web_paths:
  - /private/
  - /sites/default/files/private/

# Quicksilver hooks (platform automation)
workflows:
  # After code sync to any environment
  sync_code:
    after:
      - type: webphp
        description: Example after code sync
        script: private/scripts/example.php

  # After database clone
  clone_database:
    after:
      - type: webphp
        description: Sanitize after clone
        script: private/scripts/sanitize.php

  # Before deployment
  deploy:
    before:
      - type: webphp
        description: Pre-deployment checks
        script: private/scripts/deploy-check.php
    after:
      - type: webphp
        description: Post-deployment tasks
        script: private/scripts/post-deploy.php

  # After clear cache
  clear_cache:
    after:
      - type: webphp
        description: Warm cache
        script: private/scripts/warm-cache.php
```

---

## Minimal Configuration (Recommended Start)

```yaml
api_version: 1
web_docroot: true
drush_version: 12
php_version: 8.3
database:
  version: 10.6
search:
  version: 8
```

---

## PHP Version Selection

**Drupal 10 Requirements**:
- Minimum: PHP 8.1
- Recommended: PHP 8.3 (best performance)
- Avoid: PHP 8.0 (end of life)

```yaml
# Drupal 10 with PHP 8.3
php_version: 8.3

# Drupal 9 legacy
php_version: 8.1
```

**Upgrade Strategy**:
1. Test on multidev first
2. Update pantheon.yml
3. Push to dev and test
4. Monitor logs and APM
5. Deploy through test → live

---

## Database Version Selection

**MariaDB 10.6** (Recommended):
- Better performance
- UTF8MB4 by default
- Required for Drupal 11+

**MariaDB 10.4** (Legacy):
- Default for older sites
- Upgrade recommended

```yaml
# Recommended
database:
  version: 10.6

# Legacy
database:
  version: 10.4
```

**Upgrade Process**:
1. **Backup database** first!
2. Update pantheon.yml
3. Push to dev
4. Test thoroughly
5. Deploy through environments

**Important**: Database downgrades are not supported!

---

## Drush Version

```yaml
# Drupal 10+ (use Drush 12)
drush_version: 12

# Drupal 9 (can use Drush 11 or 12)
drush_version: 11

# Drupal 8 (legacy)
drush_version: 10
```

**Note**: Drush version set here is for Pantheon's CLI/dashboard integration. Your project's composer.json still controls the actual Drush version used.

---

## Web Docroot

```yaml
# Use docroot/ or web/ subdirectory
web_docroot: true

# Use repository root (legacy)
web_docroot: false
```

**Standard Drupal Structure**:
```
repository-root/
├── pantheon.yml
├── composer.json
├── web/              # ← web_docroot: true points here
│   ├── index.php
│   ├── core/
│   └── modules/
└── vendor/
```

---

## Protected Web Paths

Prevent public HTTP access to sensitive directories:

```yaml
protected_web_paths:
  - /private/
  - /sites/default/files/private/
  - /sites/default/private/
  - /admin/
  - /.env
```

**Important**:
- Paths are relative to web docroot
- Returns 403 Forbidden for HTTP requests
- Does not protect from PHP file access
- Use Drupal's file access controls too

---

## Search Configuration

```yaml
# Solr 8 (recommended)
search:
  version: 8

# Solr 3.6 (legacy, deprecated)
search:
  version: 3
```

**Solr 8 Features**:
- Better performance
- Modern query parser
- More analysis options
- Required for search_api_pantheon 8.x-2.x+

---

## Quicksilver Workflows

Automate tasks at specific platform events:

### Available Triggers

- `sync_code` - After code deployed
- `deploy` - Before/after deployment
- `clone_database` - After database clone
- `clone_files` - After files clone
- `clear_cache` - After cache clear
- `deploy_product` - Custom upstream updates

### Example: Post-Deploy Cache Warm

```yaml
workflows:
  deploy:
    after:
      - type: webphp
        description: Warm cache after deployment
        script: private/scripts/warm-cache.php
```

**private/scripts/warm-cache.php**:
```php
<?php
// Warm critical pages
$urls = [
  '/node/1',
  '/blog',
  '/products',
];

foreach ($urls as $url) {
  exec("curl -I https://{$_ENV['PANTHEON_ENVIRONMENT']}-{$_ENV['PANTHEON_SITE_NAME']}.pantheonsite.io{$url}");
}
```

### Example: Database Sanitization After Clone

```yaml
workflows:
  clone_database:
    after:
      - type: webphp
        description: Sanitize user data
        script: private/scripts/sanitize.php
```

**private/scripts/sanitize.php**:
```php
<?php
// Sanitize emails on non-live environments
if ($_ENV['PANTHEON_ENVIRONMENT'] !== 'live') {
  passthru('drush sql-sanitize -y');
}
```

---

## Best Practices

1. **Version control pantheon.yml** - Commit to repository
2. **Test changes on multidev** before deploying
3. **Pin versions explicitly** - Don't rely on defaults
4. **Document custom workflows** - Comment Quicksilver scripts
5. **Backup before upgrades** - Especially database version
6. **Monitor after changes** - Check New Relic APM
7. **Use protected paths** - Prevent accidental exposure

---

## Common Issues

### pantheon.yml Not Taking Effect

**Problem**: Changes to pantheon.yml don't apply
**Solution**:
1. Ensure file is in repository root
2. Commit and push changes
3. Clear environment cache: `terminus env:clear-cache site.env`
4. Check Pantheon dashboard for errors

### Database Version Upgrade Failed

**Problem**: Database won't upgrade
**Solution**:
1. Backup first: `terminus backup:create site.env --element=db`
2. Check MariaDB compatibility
3. Fix deprecated queries
4. Contact Pantheon support if stuck

### Quicksilver Script Not Running

**Problem**: Workflow hook doesn't execute
**Solution**:
1. Check script path is correct (relative to repo root)
2. Verify script permissions
3. Check Pantheon dashboard logs
4. Test script manually via Terminus

---

## Migration from Legacy Settings

**Old**: `.platform.yml` or undocumented settings
**New**: Use pantheon.yml exclusively

**Old**: PHP version in dashboard
**New**: Set in pantheon.yml (takes precedence)

**Example Migration**:
```yaml
# Before (dashboard settings)
# PHP 7.4, Drush 8, no docroot

# After (pantheon.yml)
api_version: 1
php_version: 8.3
drush_version: 12
web_docroot: true
database:
  version: 10.6
```

---

**Last updated**: 2024-11-05
**Official docs**: https://docs.pantheon.io/pantheon-yml
