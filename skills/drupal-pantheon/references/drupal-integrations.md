# Pantheon Drupal Integrations Package

## Overview

The `pantheon-systems/drupal-integrations` package enables Composer-managed Drupal installations to work seamlessly on Pantheon's hosting platform. This package automatically configures essential settings for database credentials, file paths, security, and performance.

**GitHub Repository**: https://github.com/pantheon-systems/drupal-integrations

---

## Installation

### Step 1: Add Package via Composer

```bash
composer require pantheon-systems/drupal-integrations:^11.1
```

**Version Compatibility**: Match major version to Drupal core:

| Drupal Version | Package Version |
|---|---|
| 11.x | `^11` |
| 10.x | `^10` |
| 9.x | `^9` |
| 8.x | `^8` |

### Step 2: Enable in settings.php

Add this line to your `docroot/sites/default/settings.php`:

```php
/**
 * Include the Pantheon-specific settings file.
 */
include \Pantheon\Integrations\Assets::dir() . "/settings.pantheon.php";
```

**CRITICAL**: Always use the `\Pantheon\Integrations\Assets::dir()` method to reference the vendor file directly. Do NOT copy the file to a custom location.

### Step 3: Verify Installation

```bash
# Check package is installed
composer show pantheon-systems/drupal-integrations

# Test Drupal bootstrap
drush status
```

---

## What This Package Configures

The integration automatically handles:

1. **Database Credentials**: Injects Pantheon database connection details
2. **File Paths**:
   - Configuration directories (`config/sync`)
   - Private files (`sites/default/files/private`)
   - Temporary files (`/tmp`)
   - Twig cache directories
3. **Security**:
   - Secure, random hash salt generation
   - Trusted host patterns for Pantheon domains
4. **Edge Cache**: Pantheon Service Provider integration
5. **Performance**: Excludes large directories (node_modules, bower_components) from cache

---

## Common Issues and Solutions

### Issue: Custom Copy of settings.pantheon.php

**Problem**: Site has an outdated custom copy of `settings.pantheon.php` that references old service providers.

**Symptoms**:
- Using `PantheonServiceProvider` instead of `PantheonServiceProvider11` on Drupal 11
- References to Drupal 8/9/10 in comments when running Drupal 11
- Missing new features from updated package

**Solution**:

1. Update settings.php to use vendor file directly:
```php
// ❌ OLD - Custom copy
include __DIR__ . "/settings/settings.pantheon.php";

// ✅ NEW - Vendor file (always up-to-date)
include \Pantheon\Integrations\Assets::dir() . "/settings.pantheon.php";
```

2. Back up and remove custom copy:
```bash
mv docroot/sites/default/settings/settings.pantheon.php \
   docroot/sites/default/settings/settings.pantheon.php.bak
```

3. Verify Drupal bootstrap works:
```bash
drush status
```

### Issue: Scaffolding Conflicts (Drupal 10.4+)

**Problem**: Package Manager errors when using deprecated scaffolding method.

**Solution**: Update to modern include method shown above. The package no longer uses scaffolding and includes files directly from vendor directory.

---

## Service Provider Versions

The package includes different service providers for different Drupal versions:

```php
// Drupal 11
$GLOBALS['conf']['container_service_providers']['PantheonServiceProvider'] =
  '\Pantheon\Internal\PantheonServiceProvider11';

// Drupal 10
$GLOBALS['conf']['container_service_providers']['PantheonServiceProvider'] =
  '\Pantheon\Internal\PantheonServiceProvider';
```

This is handled automatically by the vendor file. Custom copies may reference wrong versions.

---

## Best Practices

### ✅ DO

1. **Use vendor file directly** via `\Pantheon\Integrations\Assets::dir()`
2. **Version pin** to match Drupal major version (e.g., `^11` for Drupal 11)
3. **Update regularly** with `composer update pantheon-systems/drupal-integrations`
4. **Test locally** with DDEV or Lando to catch issues before Pantheon deployment
5. **Commit composer.json and composer.lock** to version control

### ❌ DON'T

1. **Don't copy** `settings.pantheon.php` to a custom location
2. **Don't modify** the vendor file directly (changes will be lost)
3. **Don't version mismatch** (e.g., using `^10` package with Drupal 11)
4. **Don't skip** the package - it's required for proper Pantheon integration

---

## Upgrading Between Drupal Versions

When upgrading Drupal major versions:

```bash
# Example: Drupal 10 → Drupal 11

# 1. Update Drupal core
composer require drupal/core-recommended:^11.0 drupal/core-composer-scaffold:^11.0

# 2. Update Pantheon integrations
composer require pantheon-systems/drupal-integrations:^11.1

# 3. Verify settings.php uses vendor file (not custom copy)
grep "Pantheon\\Integrations\\Assets" docroot/sites/default/settings.php

# 4. Test bootstrap
drush status

# 5. Run updates
drush updatedb
drush cr
```

---

## Troubleshooting

### Check Current Configuration

```bash
# View installed version
composer show pantheon-systems/drupal-integrations

# Check settings.php include method
grep -A2 "pantheon" docroot/sites/default/settings.php | grep include

# Verify correct service provider is loaded
drush php:eval "print_r(\$GLOBALS['conf']['container_service_providers'] ?? []);"
```

### Verify Service Provider

The correct service provider should be loaded based on your Drupal version:

```bash
# Check vendor file contents
grep "PantheonServiceProvider" vendor/pantheon-systems/drupal-integrations/assets/settings.pantheon.php

# Should show PantheonServiceProvider11 for Drupal 11
```

### Compare Custom vs Vendor Files

If you have a custom copy:

```bash
# Check for differences
diff docroot/sites/default/settings/settings.pantheon.php \
     vendor/pantheon-systems/drupal-integrations/assets/settings.pantheon.php
```

If differences exist, the custom file is outdated.

---

## Configuration Override Patterns

If you need custom settings, add them AFTER the Pantheon include:

```php
// settings.php

// Include Pantheon integration (always first)
include \Pantheon\Integrations\Assets::dir() . "/settings.pantheon.php";

// Your custom overrides (after Pantheon defaults)
if (isset($_ENV['PANTHEON_ENVIRONMENT'])) {
  // Pantheon-specific customizations
  if ($_ENV['PANTHEON_ENVIRONMENT'] === 'live') {
    $config['system.logging']['error_level'] = 'hide';
  }
}
```

**Never modify the vendor file directly** - use overrides in settings.php instead.

---

## Package Contents

Key files in the package:

```
vendor/pantheon-systems/drupal-integrations/
├── assets/
│   ├── settings.pantheon.php           # Main integration file
│   ├── services.pantheon.production.yml    # Production services
│   └── services.pantheon.preproduction.yml # Dev/multidev services
└── src/
    ├── Assets.php                      # Helper for vendor path
    └── Internal/
        ├── PantheonServiceProvider11.php   # Drupal 11 provider
        └── PantheonServiceProvider.php     # Drupal 10 provider
```

---

## Related Documentation

- **Package Repository**: https://github.com/pantheon-systems/drupal-integrations
- **Pantheon Settings Documentation**: https://docs.pantheon.io/guides/php/settings-php
- **Composer Workflow**: https://docs.pantheon.io/guides/composer
- **Environment Configuration**: https://docs.pantheon.io/guides/environment-configuration

---

