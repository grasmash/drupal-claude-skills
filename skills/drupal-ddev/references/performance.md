# DDEV Performance

macOS file-sync, database tuning and PHPUnit test-speed guidance, moved from SKILL.md.

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

To shrink the sync payload, customize `.ddev/mutagen/mutagen.yml` (remove the
`#ddev-generated` header first; never ignore `node_modules` globally) — see
[load-and-recovery.md](load-and-recovery.md#trimming-the-mutagen-payload).

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
means OOM, Mutagen desync, and stale-code WSODs. Lock design (exclusive vs
counting-semaphore tiers, coalesced cache rebuilds):
[load-and-recovery.md](load-and-recovery.md#coordinating-multiple-agents-on-one-ddev-project).

### Where to Run Kernel Suites

Kernel-test IO is dominated by the macOS bind mount, not the database driver.
SQLite (`SIMPLETEST_DB=sqlite://...`) is a verified-compatible KernelTestBase
backend, but it does NOT fix mount IO — a secondary lever, not the fix. If
Kernel-heavy suites get slow locally, prefer running them in CI rather than
laptop-only runs. KernelTestBase never needs the site DB: a throwaway MariaDB
container plus `SIMPLETEST_DB` decouples Kernel runs from DDEV entirely —
see [load-and-recovery.md](load-and-recovery.md#kernel-tests-against-a-throwaway-database).
