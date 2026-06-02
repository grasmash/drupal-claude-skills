# Local Solr with DDEV

## Overview

DDEV can run a local Solr service for Search API development and testing. This is useful for testing search functionality without relying on Pantheon's Solr service.

## Installation

### Add Solr Service

```bash
ddev get ddev/ddev-solr
ddev restart
```

This creates:
- `.ddev/docker-compose.solr.yaml` - Solr service configuration
- `.ddev/solr/` - Solr configuration directory
- `.ddev/commands/host/solr-admin` - Command to open Solr admin UI

### Configuration Files Created

```
.ddev/
├── docker-compose.solr.yaml    # Solr service definition
├── solr/
│   ├── configsets/             # Solr core configurations
│   ├── lib/                    # Custom Solr libraries
│   └── security.json           # Basic auth config
└── commands/
    ├── host/solr-admin         # Open Solr admin UI
    └── solr/                   # Solr commands inside container
```

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Solr Admin UI | `https://sitename.ddev.site:8943/solr` | solr / SolrRocks |
| Internal (from Drupal) | `http://solr:8983/solr` | solr / SolrRocks |

**Note**: External port is **8943** (HTTPS), internal port is **8983** (HTTP).

## Drupal Configuration

### Override Search API Server in settings.ddev.php

**CRITICAL**: Use `settings.ddev.php` for DDEV-specific overrides, NOT `settings.local.php`.

```php
// Override Pantheon Solr server to use local DDEV Solr
$config['search_api.server.pantheon_search']['backend_config']['connector'] = 'standard';
$config['search_api.server.pantheon_search']['backend_config']['connector_config'] = [
  'scheme' => 'http',
  'host' => 'solr',              // DDEV container hostname
  'port' => '8983',              // Internal port
  'path' => '/',
  'core' => 'drupal',            // Core name from configset
  'timeout' => 5,
  'index_timeout' => 5,
  'optimize_timeout' => 10,
  'finalize_timeout' => 30,
  'solr_version' => '9',
  'http_method' => 'AUTO',
  'commit_within' => 1000,
  'username' => 'solr',
  'password' => 'SolrRocks',
];
```

### Why settings.ddev.php?

✅ **DO**: Put DDEV overrides in `settings.ddev.php`
- Only loads when `IS_DDEV_PROJECT=true`
- Never loads on Pantheon
- DDEV-managed file

❌ **DON'T**: Put DDEV overrides in `settings.local.php`
- May be tracked in git
- May be deployed to production
- Can break production if it contains DDEV-specific config

## Common Workflows

### Verify Solr is Running

```bash
# Check service status
ddev describe

# Should show:
# solr    OK    https://sitename.ddev.site:8943
```

### Index Content

```bash
# Clear and reindex
ddev drush search-api:clear
ddev drush search-api:index

# Check status
ddev drush search-api:status
```

### Test Search Queries

```bash
# Search via Drush
ddev drush search-api:search mixed_entities "guitar"

# Or via Solr admin UI
ddev solr-admin
```

### View Solr Logs

```bash
# Recent logs
ddev logs -s solr | tail -50

# Follow logs
ddev logs -s solr -f
```

### Access Solr Admin UI

```bash
# Open in browser
ddev solr-admin

# Or manually visit
# https://sitename.ddev.site:8943/solr
# Username: solr
# Password: SolrRocks
```

## Troubleshooting

### Connection Refused

**Problem**: Drupal can't connect to Solr

**Solution**:
```bash
# Verify Solr is running
ddev describe | grep solr

# Restart if needed
ddev restart

# Check Drupal can reach Solr
ddev exec curl http://solr:8983/solr/admin/ping
```

### Wrong Connector on Pantheon

**Problem**: Production shows `Could not resolve host: solr`

**Cause**: DDEV Solr config deployed to Pantheon

**Solution**:
- Move config from `settings.local.php` → `settings.ddev.php`
- Ensure `settings.local.php` is in `.gitignore`
- Never commit DDEV-specific settings to git if they override production services

### Core Not Found

**Problem**: Solr core 'drupal' doesn't exist

**Solution**:
```bash
# Check cores
ddev solr-admin
# Navigate to Core Admin

# If missing, recreate configset
ddev restart
```

### Indexing Fails

**Problem**: Search API indexing times out or fails

**Solution**:
```bash
# Check Solr logs for errors
ddev logs -s solr

# Verify core is healthy
curl -u solr:SolrRocks "https://sitename.ddev.site:8943/solr/drupal/admin/ping"

# Clear and retry
ddev drush search-api:clear
ddev drush search-api:index
```

## Configuration Best Practices

### 1. Settings File Hierarchy

```php
// settings.php - Shared settings
include 'settings.pantheon.php';  // Pantheon auto-config

// settings.ddev.php - DDEV-only (only loads if IS_DDEV_PROJECT=true)
$config['search_api.server.pantheon_search']['backend_config']['connector'] = 'standard';

// settings.local.php - Developer-specific (gitignored)
// Use for personal overrides only, never DDEV service config
```

### 2. Connector Selection

| Environment | Connector | Config |
|-------------|-----------|--------|
| **Pantheon** (dev/test/live) | `pantheon` | Auto-configured by Pantheon |
| **DDEV Local** | `standard` | Override in `settings.ddev.php` |
| **Other Local** | `standard` or `pantheon` | Override in `settings.local.php` |

### 3. .gitignore

Ensure these are ignored:
```gitignore
docroot/sites/default/settings.local.php
docroot/sites/default/settings.ddev.php  # DDEV manages this
```

## Integration with Pantheon

### Syncing Data

```bash
# Pull database from Pantheon
terminus backup:create sitename.dev --element=db
terminus backup:get sitename.dev --element=db --to=backup.sql.gz

# Import locally
ddev import-db --file=backup.sql.gz

# Reindex with local Solr
ddev drush search-api:clear
ddev drush search-api:index
```

### Testing Before Deploy

```bash
# Test search functionality locally
ddev drush search-api:status

# Run searches
ddev drush search-api:search mixed_entities "test query"

# Verify via UI
ddev launch /search
```

### Deploy Checklist

- [ ] Verify no DDEV Solr config in `settings.local.php`
- [ ] Ensure `settings.local.php` is in `.gitignore`
- [ ] DDEV overrides only in `settings.ddev.php`
- [ ] Test that Pantheon connector works after config import
- [ ] Clear cache after deployment

## Advanced: Custom Solr Configuration

### Add Custom Configset

```bash
# Create custom configset
mkdir -p .ddev/solr/configsets/mycore

# Copy base config
cp -r .ddev/solr/configsets/drupal/* .ddev/solr/configsets/mycore/

# Edit schema
vim .ddev/solr/configsets/mycore/conf/managed-schema.xml

# Restart to apply
ddev restart
```

### Use Different Solr Version

```yaml
# .ddev/docker-compose.solr.yaml
services:
  solr:
    image: solr:8  # Change version
```

## Related Documentation

- [Pantheon Search API Solr](https://pantheon.io/docs/solr)
- [DDEV Solr Add-on](https://github.com/ddev/ddev-solr)
- [Drupal Search API](https://www.drupal.org/project/search_api)
- [Drupal Search API Solr](https://www.drupal.org/project/search_api_solr)

## Lessons Learned

### Settings File Isolation Incident

**What Happened**:
- Added Solr config to `settings.local.php`
- File was tracked in git and deployed to Pantheon
- Overwrote Pantheon's Solr connector with DDEV hostname `solr:8983`
- Production search failed with "Could not resolve host: solr"

**Root Cause**:
```php
// settings.local.php (WRONG - deployed to production)
$config['search_api.server.pantheon_search']['backend_config']['connector'] = 'standard';
$config['search_api.server.pantheon_search']['backend_config']['connector_config']['host'] = 'solr';
```

**Fix**:
1. Moved config to `settings.ddev.php` (only loads in DDEV)
2. Removed `settings.local.php` from git
3. Added `settings.local.php` to `.gitignore`

**Prevention**:
- ✅ Always use `settings.ddev.php` for DDEV service overrides
- ✅ Keep `settings.local.php` gitignored and developer-specific
- ✅ Test configuration sync: `ddev drush config:status`
- ✅ Verify settings load order in `settings.php`

### Key Principle

**DDEV settings should ONLY exist in files that are environment-aware:**

```php
// settings.php - Check before loading
if (getenv('IS_DDEV_PROJECT') == 'true' && is_readable($ddev_settings)) {
  require $ddev_settings;  // ✅ Only loads in DDEV
}

if (!isset($_ENV['PANTHEON_ENVIRONMENT']) && file_exists($local_settings)) {
  include $local_settings;  // ✅ Only loads outside Pantheon
}
```

This prevents DDEV configuration from breaking production environments.
