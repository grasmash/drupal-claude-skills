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
type: drupal11
docroot: web
php_version: "8.3"
webserver_type: nginx-fpm
database:
  type: mariadb
  version: "10.6"
nodejs_version: "24"

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
ddev config --project-type=drupal11 --docroot=web --php-version=8.3

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

### Database Sync from a Remote/Production Environment

```bash
# Get latest backup from your hosting platform, e.g.:
#   Pantheon: terminus backup:create/backup:get
#   Acquia:   acli pull:database
#   Generic:  drush @alias sql:dump

# Import to local
ddev import-db --file=backup.sql.gz

# Run updates
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

**Measured, not assumed:** the macOS bind mount, not
contention, is what's slow. A 7-test Kernel class deconfounded to `none`+idle
597s vs `mutagen`+idle 3.06s — a ~195x mount effect vs. only ~1.6x from
removing multi-agent contention. `performance_mode: mutagen` is load-bearing;
do not flip it off casually. If it misbehaves: an empty/corrupt mutagen
volume makes `ddev start` fail before syncing — `docker volume rm
<project>_mutagen` is safe (code-only; the DB volume is separate). Check
`ddev debug mutagen sync list` when local and container contents diverge.
Recovery through the volume/daemon (below) should have exactly ONE owner at
a time — if multiple agent sessions or terminals share the same DDEV
instance, serialize `ddev start`/`ddev mutagen reset` behind a single lock;
ownership rotating mid-recovery manufactures mangled containers.

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

## PHPUnit Test Performance

### Fast Bootstrap

Stock Drupal core's PHPUnit bootstrap does a full-docroot-tree class scan on every
invocation — 76s of cold CLI parse before a single test runs. A generated,
project-specific bootstrap (e.g. a `scripts/phpunit-bootstrap.php` with the
PSR-4 namespace map pre-computed, no scan) cuts that to 0.47s; single-test
wall clock drops 89s → ~5s. Regenerate it when a module's namespace layout
changes, and prove parity by diffing the full test-ID list old vs. new
bootstrap (must be byte-identical).

### Run the Smallest Sufficient Scope

Run the smallest sufficient test scope per change (single test, then single
class); save full-suite runs for batch close. If multiple agent sessions
share one local DDEV instance, serialize container-disruptive or
memory-heavy operations (`ddev restart`, `drush cr`, phpunit, Playwright,
theme builds) behind a lock — N agents hitting one Docker VM concurrently
means OOM, Mutagen desync, and stale-code WSODs.

### Where to Run Kernel Suites

Kernel-test IO is dominated by the macOS bind mount, not the database driver.
SQLite (`SIMPLETEST_DB=sqlite://...`) is a verified-compatible KernelTestBase
backend, but it does NOT fix mount IO — a secondary lever, not the fix. If
Kernel-heavy suites get slow locally, prefer running them in CI rather than
laptop-only runs.

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

### Interrupted `ddev composer install` Leaves Phantom-Installed Packages (Patches Never Applied)

If `ddev composer install`/`update` is killed mid-run (Docker OOM exit 137, host timeout, crash), Composer may have already recorded the package as installed before the kill — so the NEXT `composer install` reports **"Nothing to install, update or remove"** and composer-patches never applies that package's patches. The result is a half-materialized contrib tree that produces impossible-looking runtime errors (e.g. DI `ServiceCircularReferenceException`s, TypeErrors from an unpatched constructor) that do NOT reproduce once the tree is repaired.

**Diagnose**:
```bash
# Verify patch application (a verify-patches script if your project has one,
# or spot-check a known-patched file in the vendored tree)
ddev composer install                # says "Nothing to install" despite the missing patches
```

**Fix** — force a clean reinstall of the affected package (re-applies its patches):
```bash
ddev composer reinstall drupal/<pkg>
```

**Rule**: after ANY interrupted composer run, treat the whole package tree as suspect. Reinstall the packages that were mid-flight, re-verify patches, and only THEN debug remaining errors — the error you saw during the broken window may already be gone. Check error-log timestamps: confirm a fatal reproduces NOW before engineering a fix for it.

### Timeout-Killed `ddev drush` Commands Orphan In-Container Processes

Killing the host-side `ddev drush ...` process (Ctrl-C, tool timeout) does NOT kill the php process inside the web container. Orphans accumulate, contend for CPU, and make every subsequent drush bootstrap crawl (10+ minutes for `drush cr`/`updb`/`updatedb:status` — looks like a hang, is actually starvation).

**Diagnose / clean up**:
```bash
ddev exec "ps aux | grep -v grep | grep -E 'vendor/bin/drush|php /var/www'"
ddev exec "pkill -f 'vendor/bin/drush'"
```

**Two corollaries**:
1. Run long drush operations (`updb` on a big upgrade, cold `cr`) ONCE, in the background, with a generous timeout — do not fire repeated shorter attempts; each kill adds another orphan.
2. A "hung then killed" `updb` may have already completed its real work — update hooks are recorded per-hook. Before re-running or panicking, check what actually executed:
```bash
ddev mysql -e "SELECT value FROM key_value WHERE collection='system.schema' AND name='<module>'"
ddev mysql -N -e "SELECT value FROM key_value WHERE collection='post_update' AND name='existing_updates'" | grep -o "<module>_post_update_[a-z0-9_]*"
```

### Docker Engine Wedge (Check Before Iterating on DDEV)

phpunit exits 137, background jobs die mid-run, `ddev exec` re-triggers full
image rebuilds, or every `ddev start` hits "container name already in use" —
looks like a DDEV problem but is often the Docker Desktop **engine** crashed
underneath still-resident app processes. Check this FIRST:

```bash
timeout 5 docker version   # hangs on the Server section -> engine is dead
docker ps                  # if this responds while `docker version` hangs, engine is wedged
```

**Fix**: `killall -9 com.docker.backend && open -a Docker`, poll `docker ps`
until it responds, then `ddev start`. Don't keep iterating on ddev-level
fixes (poweroff/mutagen reset/etc.) while the engine itself is down — none
of them can succeed.

### Post-Recovery 404s With Route-Discovery Warnings

A 404 with route-discovery warnings right after a recovery (Docker restart,
mutagen reset, core update) that `ddev drush cr` does not fix is usually an
APCu-stale compiled container: php-fpm's opcode cache still holds pre-change
code even though `cache_container` in the DB is fresh. **Fix**: `docker
restart ddev-<project>-web` (forces fresh APCu) — not another cache clear.

### Router TLS Reset While Containers Report Healthy

`curl` to `https://<project>.ddev.site` fails instantly with exit 35 ("Connection reset by peer" during TLS handshake) even though `ddev describe` shows everything OK and `docker ps` says `ddev-router` is healthy. The app is fine — the router is wedged.

**Discriminate app vs router** (bypasses the router entirely):
```bash
ddev exec "curl -s -o /dev/null -w '%{http_code}' http://localhost/<path>"
```

**Fix**:
```bash
docker restart ddev-router
```

### Docker Desktop overlay2 I/O Errors

If Docker Desktop gets into a bad state producing overlay2 or containerd I/O errors such as:

```
Error response from daemon: error creating temporary lease: write /var/lib/desktop-containerd/daemon/io.containerd.metadata.v1.bolt/meta.db: input/output error
```
```
Error response from daemon: open /var/lib/docker/overlay2/...: input/output error
```

A normal quit and restart of Docker Desktop is **not sufficient**. You must **force quit ALL Docker processes** (via Activity Monitor or `killall -9 Docker` / `killall -9 com.docker.hyperkit`), then relaunch Docker Desktop. Only a full force quit clears the corrupted state.

**"readdirent bad message" variant**: signals VM-disk corruption at the
container-metadata level, not a transient overlay2 hiccup — repeated `ddev
start` will not fix it. Quarantine the corrupted container's metadata
directory instead of looping restarts (enter an alpine container via
`nsenter` and `mv` the offending `/var/lib/docker/containers/<id>` dir aside).

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

### Disk Usage: Don't Trust `ls` or `du`

`ls -la` reports the logical size of sparse files (e.g. `Docker.raw`), which
can be far larger than what's actually consumed on disk; `du` over-reports on
APFS because it double-counts copy-on-write clones shared between snapshots.
Neither answers "how much space would this operation actually cost/free."
Trust only `df` deltas taken immediately before and after the operation.

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

### Agent Worktree Cleanup

Multi-agent workflows that dispatch via `git worktree` accumulate one
directory per agent under `.claude/worktrees/` and nothing removes them on
its own — left unmanaged this is unbounded disk growth (one project found
46GB of stale worktrees in a single session). A SessionStart "worktree
janitor" hook can sweep entries that are unlocked, old
enough, and either clean or dirty with only junk files; anything with real
tracked-file changes is left alone and logged, never bulldozed. Never `rm -rf`
a worktree by hand — use `git worktree remove` (it refuses on genuine dirty
state, which is the safety you want). Executors that spin up their own
worktree should clean it up themselves when done.

---

## Related Skills

- @drupal-config-mgmt - Config management workflows
- @drupal-contrib-mgmt - Module management with Composer
- @drupal-at-your-fingertips - General Drupal patterns

---

**Official Documentation**: https://ddev.readthedocs.io
**Drupal DDEV Quickstart**: https://ddev.readthedocs.io/en/stable/users/quickstart/
**Community Support**: https://discord.gg/5wjP76mBJD
