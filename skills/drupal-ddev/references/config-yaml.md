# .ddev/config.yaml Reference

Complete reference for DDEV configuration file.

---

## Complete Example

```yaml
name: myproject
type: drupal10
docroot: web
php_version: "8.3"
webserver_type: nginx-fpm
xdebug_enabled: false
additional_hostnames: []
additional_fqdns: []
database:
  type: mariadb
  version: "10.6"
nodejs_version: "20"
composer_version: "2"
router_http_port: "80"
router_https_port: "443"
web_environment:
  - ENVIRONMENT=dev
  - CUSTOM_VAR=value
upload_dirs:
  - web/sites/default/files
performance_mode: mutagen  # macOS only
nfs_mount_enabled: false
use_dns_when_possible: true
timezone: America/New_York
omit_containers: []
additional_services: []
override_config: false
provider: default
hooks:
  post-start:
    - exec: drush cr
```

---

## Core Settings

### Project Name
```yaml
name: myproject
```
- Must be unique across all DDEV projects on machine
- Used for container names and URLs
- Convention: match directory name

### Project Type
```yaml
type: drupal10   # Or drupal9, drupal11
```

**Available Drupal types**:
- `drupal10` - Drupal 10 (recommended)
- `drupal9` - Drupal 9
- `drupal` - Auto-detect Drupal version
- `drupal11` - Drupal 11 (when available)

### Document Root
```yaml
docroot: web     # Or docroot, public_html, or ""
```
- Relative to project root
- Empty string `""` means project root
- Standard: `web` for modern Drupal

---

## PHP Configuration

### PHP Version
```yaml
php_version: "8.3"
```

**Drupal requirements**:
- Drupal 10: PHP 8.1, 8.2, or 8.3
- Drupal 9: PHP 7.4, 8.0, 8.1, or 8.2
- Drupal 11: PHP 8.3+

### Web Server
```yaml
webserver_type: nginx-fpm   # Or apache-fpm
```

**Options**:
- `nginx-fpm` (recommended, faster)
- `apache-fpm` (for .htaccess compatibility)

---

## Database Configuration

```yaml
database:
  type: mariadb      # Or mysql, postgres
  version: "10.6"    # MariaDB: 5.5, 10.4, 10.6, 10.11
```

**MariaDB versions**:
- `10.6` - Recommended for Drupal 10/11
- `10.4` - Legacy, still supported
- `10.11` - Latest

**PostgreSQL** (less common for Drupal):
```yaml
database:
  type: postgres
  version: "14"
```

---

## Node.js

```yaml
nodejs_version: "20"   # 18, 20, 21, etc.
```

Used for:
- Theme compilation (Gulp, Webpack)
- Frontend tooling
- Build processes

---

## Performance Settings

### Mutagen (macOS Performance Boost)

```yaml
performance_mode: mutagen
```

**Benefits**:
- 5-10x faster file operations on macOS
- Two-way sync between host and container
- Dramatically improves page load times

**Trade-off**:
- Small delay in file sync (~100ms)
- Slight memory overhead

### NFS Mount (Alternative)

```yaml
nfs_mount_enabled: true
```

**When to use**:
- macOS performance issues
- Alternative to mutagen
- Requires NFS server setup

---

## Xdebug

```yaml
xdebug_enabled: false   # Change to true to enable by default
```

**Better approach**: Enable on demand
```bash
ddev xdebug on   # Enable when needed
ddev xdebug off  # Disable for better performance
```

---

## Additional Hostnames

```yaml
additional_hostnames:
  - api
  - admin
```

Creates:
- `api.myproject.ddev.site`
- `admin.myproject.ddev.site`

**Use case**: Multi-domain or subdomain testing

---

## Additional FQDNs

```yaml
additional_fqdns:
  - example.local
  - test.example.com
```

Fully-qualified domain names for testing specific domains.

**Requires hosts file entry**:
```
127.0.0.1 example.local test.example.com
```

---

## Upload Directories

```yaml
upload_dirs:
  - web/sites/default/files
  - web/sites/default/private
```

Directories synced with `ddev import-files`

---

## Environment Variables

```yaml
web_environment:
  - ENVIRONMENT=dev
  - DRUPAL_ENV=local
  - CUSTOM_KEY=value
```

Available in PHP as `$_ENV['ENVIRONMENT']`

---

## Composer Version

```yaml
composer_version: "2"   # Or "1", ""
```

- `"2"` - Composer 2 (recommended)
- `"1"` - Composer 1 (legacy)
- `""` - Latest stable

---

## Custom Ports

```yaml
router_http_port: "80"
router_https_port: "443"
```

Change if port conflicts:
```yaml
router_http_port: "8080"
router_https_port: "8443"
```

Access via: `http://myproject.ddev.site:8080`

---

## Additional Services

```yaml
additional_services:
  - solr
  - elasticsearch
  - redis
  - memcached
```

### Solr Example
```yaml
additional_services:
  - solr:8

# Create .ddev/docker-compose.solr.yaml if needed
```

### Redis Example
```yaml
additional_services:
  - redis
```

---

## Hooks

Automate tasks at specific points:

```yaml
hooks:
  # After ddev start
  post-start:
    - exec: composer install
    - exec: drush cr
    - exec-host: echo "Project started"

  # Before ddev start
  pre-start:
    - exec: echo "Starting project..."

  # After composer
  post-composer:
    - exec: drush cr

  # After database import
  post-import-db:
    - exec: drush updb -y
    - exec: drush cr
    - exec: drush user:password admin "admin"
```

**Hook types**:
- `pre-start`, `post-start`
- `pre-stop`, `post-stop`
- `pre-import-db`, `post-import-db`
- `pre-composer`, `post-composer`
- `pre-snapshot`, `post-snapshot`

**Exec types**:
- `exec` - Run in web container
- `exec-host` - Run on host machine

---

## Omit Containers

```yaml
omit_containers:
  - ddev-ssh-agent
  - dba
```

Skip containers you don't need to save resources.

---

## Timezone

```yaml
timezone: America/New_York
```

Sets container timezone (affects logs, cron, etc.)

---

## Override Config

```yaml
override_config: true
```

Prevent `ddev config` from modifying config.yaml.

**Use case**: When config.yaml is managed by team/CI

---

## Provider Integration

```yaml
provider: pantheon   # Or platform, default
```

**Pantheon**:
```yaml
provider: pantheon

web_environment:
  - PANTHEON_ENVIRONMENT=dev
```

**Platform.sh**:
```yaml
provider: platform
```

---

## Full Drupal 10 Example

```yaml
name: mysite
type: drupal10
docroot: web
php_version: "8.3"
webserver_type: nginx-fpm
xdebug_enabled: false

database:
  type: mariadb
  version: "10.6"

nodejs_version: "20"
composer_version: "2"

# Performance (macOS)
performance_mode: mutagen

# Additional services
additional_services:
  - solr:8

# Upload directories
upload_dirs:
  - web/sites/default/files

# Environment variables
web_environment:
  - ENVIRONMENT=local
  - DRUPAL_ENV=dev

# Hooks
hooks:
  post-start:
    - exec: composer install
    - exec: drush cr

  post-import-db:
    - exec: drush updb -y
    - exec: drush cr
    - exec: drush user:password admin "admin"
    - exec: drush sql-sanitize -y

# Timezone
timezone: America/New_York
```

---

## Best Practices

1. **Commit to repository** - Share with team
2. **Pin versions explicitly** - PHP, database, Node
3. **Use mutagen on macOS** - Huge performance boost
4. **Disable Xdebug by default** - Enable only when needed
5. **Automate with hooks** - Post-import, post-start tasks
6. **Document custom settings** - Add comments in YAML
7. **Match production** - Same PHP/DB versions as live

---

## Migration Examples

### From Lando

```yaml
# Lando .lando.yml
name: mysite
recipe: drupal10
config:
  php: '8.2'
  webroot: web

# DDEV equivalent
name: mysite
type: drupal10
docroot: web
php_version: "8.2"
```

### From MAMP/XAMPP

```yaml
# DDEV config for existing MAMP site
name: mysite
type: drupal10
docroot: .     # Often no subdirectory
php_version: "8.1"
database:
  type: mysql  # If was using MySQL not MariaDB
  version: "8.0"
```

---

**Last updated**: 2024-11-05
**Official docs**: https://ddev.readthedocs.io/en/stable/users/configuration/config/
