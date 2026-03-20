---
name: drupal-ddev
description: DDEV local development environment patterns for Drupal, including configuration, commands, database management, debugging tools, and performance optimization.
---

# DDEV for Drupal Development

Comprehensive patterns for using DDEV as your local Drupal development environment, including setup, configuration, workflow optimization, and troubleshooting.

## When This Skill Activates

Activates when working with DDEV local development including:
- DDEV configuration (.ddev/config.yaml)
- Local environment setup and management
- Database import/export operations
- Drush integration
- Xdebug and debugging tools
- Performance optimization
- Multi-site and custom commands

---

## Available Topics

### Core Setup
- @references/installation.md - Installing and configuring DDEV
- @references/config-yaml.md - .ddev/config.yaml reference
- @references/commands.md - Essential DDEV commands

### Database Operations
- @references/database.md - Import, export, and snapshot workflows
- @references/drush.md - Using Drush with DDEV

### Development Tools
- @references/xdebug.md - Debugging with Xdebug
- @references/mailhog.md - Email testing with MailHog
- @references/solr.md - Local Solr search setup

### Advanced
- @references/custom-commands.md - Creating project-specific commands
- @references/hooks.md - Pre/post hooks automation
- @references/performance.md - Optimizing DDEV performance
- @references/multisite.md - Multi-site configuration

See `/references/` directory for complete documentation.

---

## Quick Reference

### Essential Commands

```bash
# Start project
ddev start

# Stop project
ddev stop

# Restart services
ddev restart

# SSH into web container
ddev ssh

# Run Drush commands
ddev drush cr
ddev drush status
ddev drush config:status

# Run Composer
ddev composer require drupal/module_name
ddev composer update

# Database operations
ddev import-db --file=backup.sql.gz
ddev export-db --file=backup.sql.gz
ddev snapshot

# View logs
ddev logs
ddev logs -f    # Follow mode

# Describe project
ddev describe

# Access URLs
ddev launch     # Open site in browser
```

### Basic .ddev/config.yaml

```yaml
name: myproject
type: drupal10
docroot: web
php_version: "8.3"
webserver_type: nginx-fpm
database:
  type: mariadb
  version: "10.6"
nodejs_version: "20"

# Additional services
additional_services:
  - solr

# Custom upload/execution limits
upload_dirs:
  - web/sites/default/files

# Performance settings
performance_mode: mutagen  # For macOS
```

---

## Common Workflows

### New Drupal Project

```bash
# Create project directory
mkdir myproject && cd myproject

# Initialize DDEV
ddev config --project-type=drupal10 --docroot=web --php-version=8.3

# Install Drupal via Composer
ddev composer create drupal/recommended-project

# Install Drush
ddev composer require drush/drush

# Start DDEV
ddev start

# Install Drupal
ddev drush site:install standard --site-name="My Site" --account-name=admin

# Launch site
ddev launch
```

### Import Existing Project

```bash
# Clone repository
git clone repo-url myproject && cd myproject

# Start DDEV (reads .ddev/config.yaml)
ddev start

# Install dependencies
ddev composer install

# Import database
ddev import-db --file=path/to/backup.sql.gz

# Import files (if needed)
ddev import-files --source=/path/to/files

# Run updates
ddev drush updb -y
ddev drush cr

# Launch
ddev launch
```

### Database Sync from Remote

```bash
# Option 1: Download backup and import
# Use your hosting provider's CLI or dashboard to create/download a DB backup
# Example with a generic provider:
scp user@remote.server:/path/to/backup.sql.gz backup.sql.gz

# Import to local
ddev import-db --file=backup.sql.gz

# Option 2: Using DDEV pull (if configured with a provider integration)
ddev pull --environment=live

# Run updates after import
ddev drush updb -y
ddev drush cr

# Sanitize for local (optional)
ddev drush sql-sanitize -y
```

### Daily Development Workflow

```bash
# Morning: Start project
ddev start

# Pull latest code
git pull origin main

# Update dependencies if needed
ddev composer install

# Clear cache
ddev drush cr

# Work on features...

# Create database snapshot before testing
ddev snapshot --name=before-testing

# Test changes...

# If needed, restore snapshot
ddev snapshot restore --name=before-testing

# Evening: Stop project
ddev stop
```

---

## Debugging with Xdebug

```bash
# Enable Xdebug
ddev xdebug on

# Run your debugger in IDE (PHPStorm, VSCode)
# Set breakpoints and refresh page

# Disable when done (improves performance)
ddev xdebug off

# Check Xdebug status
ddev xdebug status
```

**VSCode launch.json**:
```json
{
  "name": "Listen for Xdebug",
  "type": "php",
  "request": "launch",
  "port": 9003,
  "pathMappings": {
    "/var/www/html": "${workspaceFolder}"
  }
}
```

---

## Performance Optimization

### macOS Performance (Mutagen)

```yaml
# .ddev/config.yaml
performance_mode: mutagen
```

```bash
# Restart after config change
ddev restart
```

### NFS Mount (Alternative for macOS)

```yaml
# .ddev/config.yaml
nfs_mount_enabled: true
```

### Database Tuning

```yaml
# .ddev/config.yaml
database:
  type: mariadb
  version: "10.6"

# Create .ddev/mysql/my.cnf
[mysqld]
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
```

---

## Custom Commands

Create project-specific commands in `.ddev/commands/web/`:

**Example**: `.ddev/commands/web/fresh-install`
```bash
#!/bin/bash
## Description: Fresh Drupal install from scratch
## Usage: fresh-install
## Example: ddev fresh-install

set -e

echo "Installing fresh Drupal site..."

# Drop existing database
drush sql-drop -y

# Install Drupal
drush site:install standard \
  --site-name="My Site" \
  --account-name=admin \
  --account-pass=admin \
  -y

# Import config if exists
if [ -d /var/www/html/config/default ]; then
  drush config:import -y
fi

# Clear cache
drush cr

echo "Fresh install complete!"
echo "Login: admin / admin"
```

Make it executable:
```bash
chmod +x .ddev/commands/web/fresh-install
ddev fresh-install
```

---

## Best Practices

1. **Commit .ddev/config.yaml** - Share config with team
2. **Use ddev composer** instead of local composer
3. **Don't commit database snapshots** - Too large
4. **Create snapshots before risky operations**
5. **Disable Xdebug when not debugging** - Performance impact
6. **Use mutagen on macOS** - Much faster file sync
7. **Regular ddev poweroff** - Free up system resources
8. **Version pin services** - PHP, database, Node.js
9. **Use hooks for automation** - Post-start tasks
10. **Document custom commands** - Help team members

---

## Common Issues

### Site Not Loading

```bash
# Restart project
ddev restart

# Check status
ddev describe

# View logs
ddev logs

# Clear Drupal cache
ddev drush cr
```

### Database Connection Error

```bash
# Check database is running
ddev describe

# Verify settings.php or settings.ddev.php exists
ddev ssh
ls web/sites/default/settings*.php
```

### Port Conflicts

```bash
# Stop all DDEV projects
ddev poweroff

# Check for port conflicts
lsof -i :80 -i :443

# Change router HTTP port if needed
ddev config --router-http-port=8080 --router-https-port=8443
```

### Slow Performance on macOS

```bash
# Enable mutagen
ddev config --performance-mode=mutagen
ddev restart

# Or use NFS
ddev config --nfs-mount-enabled=true
ddev restart
```

### PHP Deprecation Warnings in Drush

If you're seeing PHP deprecation warnings when running Drush commands (especially with PHP 8.4), create a custom PHP configuration file to suppress them:

**`.ddev/php/drush.ini`**:
```ini
; Suppress PHP deprecation warnings for Drush commands
[PHP]
error_reporting = 22527
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /tmp/php-errors.log
```

Then restart DDEV:
```bash
ddev restart
```

**How it works**:
- `error_reporting = 22527` equals `E_ALL & ~E_DEPRECATED`
- `display_errors = Off` prevents warnings from appearing on STDERR
- `display_startup_errors = Off` suppresses bootstrap warnings
- Errors are logged to `/tmp/php-errors.log` instead of being displayed

This configuration applies to both web and CLI contexts since DDEV copies `.ddev/php/*.ini` files to both `/etc/php/[version]/cli/conf.d/` and `/etc/php/[version]/fpm/conf.d/`.

### Docker Desktop overlay2 I/O Errors

If Docker Desktop gets into a bad state producing overlay2 or containerd I/O errors such as:

```
Error response from daemon: error creating temporary lease: write /var/lib/desktop-containerd/daemon/io.containerd.metadata.v1.bolt/meta.db: input/output error
```
```
Error response from daemon: open /var/lib/docker/overlay2/...: input/output error
```

A normal quit and restart of Docker Desktop is **not sufficient**. You must **force quit ALL Docker processes** (via Activity Monitor or `killall -9 Docker` / `killall -9 com.docker.hyperkit`), then relaunch Docker Desktop. Only a full force quit clears the corrupted state.

### Unhealthy Containers / Mutagen Sync Hanging

After Docker crashes or force-quits, DDEV can get into a bad state where:
- `ddev start` hangs at "Starting Mutagen sync process..."
- Web container reports unhealthy (`phpstatus:FAILED`, `mailpit:FAILED`)
- `ddev mutagen reset` fails with "CreateOrResumeMutagenSync Failure"

**Fix** (run in order):

```bash
# 1. Full power off to clean up all containers and networks
ddev poweroff

# 2. Start fresh
ddev start
```

If `ddev poweroff` doesn't resolve it:

```bash
# 1. Stop DDEV
ddev stop

# 2. Reset the Mutagen daemon
~/.ddev/bin/mutagen daemon stop
~/.ddev/bin/mutagen daemon start

# 3. Reset Mutagen sync (removes Docker volume, forces full resync)
ddev mutagen reset

# 4. Start fresh
ddev start
```

**Monitoring commands** while troubleshooting:
```bash
ddev mutagen status -l      # Detailed sync status
ddev mutagen monitor        # Real-time sync progress
docker inspect --format "{{ json .State.Health }}" ddev-<project>-web  # Container health
```

---

## Multi-Project Management

```bash
# List all projects
ddev list

# Stop all projects
ddev poweroff

# Remove stopped projects
ddev delete <project-name>

# Remove all project containers (keep files)
ddev delete --omit-snapshot --yes <project-name>
```

---

## Related Skills

- @drupal-config-mgmt - Config management workflows
- @drupal-contrib-mgmt - Module management with Composer
- @drupal-at-your-fingertips - General Drupal patterns

---

**Official Documentation**: https://ddev.readthedocs.io
**Drupal DDEV Quickstart**: https://ddev.readthedocs.io/en/stable/users/quickstart/
**Community Support**: https://discord.gg/5wjP76mBJD
