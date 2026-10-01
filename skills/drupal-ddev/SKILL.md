---
name: drupal-ddev
description: Provides DDEV local development patterns for Drupal - ddev commands, .ddev/config.yaml, database import/export and snapshots, Drush and Composer through ddev, Xdebug, local Solr, Mutagen performance, and recovery from Docker, Mutagen and router failures. Use when running ddev start/restart/exec/drush/composer, editing .ddev/config.yaml, importing or snapshotting a database, debugging slow or hung DDEV containers, or recovering a local environment after a Docker crash.
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
- @references/load-and-recovery.md - Host CPU saturation, post-crash recovery traps, trimming the Mutagen payload, Kernel tests on a throwaway DB, coordinating multiple agents on one project

See `/references/` directory for complete documentation.

## References

Read the matching file when the task needs that detail; the Common Issues section below stays here because it is needed on almost every use.

| File | Read it when |
|---|---|
| [references/workflows.md](references/workflows.md) | Setting up a new project, importing an existing one, syncing a database from a remote environment, following the daily start/stop routine, managing several DDEV projects, or cleaning up agent `git worktree` directories |
| [references/performance.md](references/performance.md) | DDEV feels slow on macOS (Mutagen vs NFS), tuning MariaDB, or PHPUnit/Kernel runs are slow (fast bootstrap, smallest test scope, where to run Kernel suites) |
| [references/xdebug.md](references/xdebug.md) | Turning Xdebug on/off or wiring an IDE (VSCode `launch.json`) to it |
| [references/custom-commands.md](references/custom-commands.md) | Writing a project-specific `ddev <command>` under `.ddev/commands/web/` |
| [references/config-yaml.md](references/config-yaml.md) | Editing `.ddev/config.yaml` beyond the basic example below (PHP, database, ports, hostnames, hooks, services, env vars) |
| [references/database.md](references/database.md) | Importing, exporting, snapshotting, accessing or sanitizing the database, or a database import fails |
| [references/solr.md](references/solr.md) | Running a local Solr service for Search API |
| [references/load-and-recovery.md](references/load-and-recovery.md) | Requests hang under heavy host load, after a Docker crash, trimming the Mutagen payload, running Kernel tests against a throwaway DB, or several agents share one DDEV project |

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
of them can succeed. After the restart, watch for orphan containers and a
slow first drush: [post-crash traps](references/load-and-recovery.md#post-docker-crash-recovery-traps).

### Host CPU Saturation (Containers Healthy, Requests Hang)

Host load well above core count; containers healthy and `php -v` instant, but
every request and drush bootstrap hangs (php-fpm workers blocked in
`request_wait_answer` on a stalled virtiofs bridge). No DDEV recovery fixes it
until load drops — shed load, then one `ddev poweroff && ddev start`. Details:
[load-and-recovery.md](references/load-and-recovery.md#host-cpu-saturation-containers-healthy-requests-hang).

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

## Related Skills

- @drupal-config-mgmt - Config management workflows
- @drupal-contrib-mgmt - Module management with Composer
- @drupal-at-your-fingertips - General Drupal patterns

---

**Official Documentation**: https://ddev.readthedocs.io
**Drupal DDEV Quickstart**: https://ddev.readthedocs.io/en/stable/users/quickstart/
**Community Support**: https://discord.gg/5wjP76mBJD
