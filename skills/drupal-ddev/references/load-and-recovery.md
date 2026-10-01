# Load, Recovery, and Shared-Instance Patterns

Failure modes that show up when a DDEV project runs under heavy load (several AI agents, browser test suites, renders) or after a Docker crash, plus the patterns that keep a shared instance usable.

## Contents

- [Host CPU saturation (containers healthy, requests hang)](#host-cpu-saturation-containers-healthy-requests-hang)
- [Post-Docker-crash recovery traps](#post-docker-crash-recovery-traps)
- [Trimming the Mutagen payload](#trimming-the-mutagen-payload)
- [Kernel tests against a throwaway database](#kernel-tests-against-a-throwaway-database)
- [Coordinating multiple agents on one DDEV project](#coordinating-multiple-agents-on-one-ddev-project)

## Host CPU saturation (containers healthy, requests hang)

**Symptom:** host load is well above the CPU core count. Every container reports healthy, the database answers and `ddev exec php -v` returns instantly, but every real page request and every `drush` bootstrap hangs indefinitely. nginx logs `client prematurely closed connection ... fastcgi://unix:/run/php-fpm.sock`, the router resets TLS, and restarts "succeed" yet nothing serves.

A related flap: php-fpm cannot warm up within DDEV's start wait, so the health check reports `phpstatus:FAILED`, the container exits, Docker recreates it, and the site oscillates between 200, 502 and 404.

**Cause:** the starved Docker VM's file-sharing bridge (virtiofs/FUSE) stalls, so php-fpm workers block in the kernel waiting on file I/O. Single file reads still work; a full Drupal bootstrap (thousands of autoloader file stats) does not.

**Diagnostic tell** (separates this from a dead engine or a wedged router):

```bash
ddev exec "ps -eo pid,time,comm | grep php-fpm"     # workers show near-zero CPU time
ddev exec "cat /proc/<worker-pid>/wchan; echo"      # prints request_wait_answer
```

**Fix:** no DDEV or Docker recovery step fixes this while the host is still saturated. First shed load (stop browser suites, renders, extra agents) until load is below roughly the core count. Then do one `ddev poweroff && ddev start`, which usually stabilizes in 2-3 minutes.

Never overlap two `ddev start`/`ddev restart` invocations: they produce container-name conflicts and supervisord port-conflict crash loops. Check `ps aux | grep "ddev start"` before recovering, and keep one recovery owner at a time.

Under multi-agent load the box is usually CPU-bound, not memory-bound; real browsers (Playwright/Chromium) are the main consumer. Adding Docker RAM does not help. Serialize browser jobs or move them to another host.

## Post-Docker-crash recovery traps

After restarting a crashed Docker engine (see "Docker Engine Wedge" in SKILL.md):

- **Kill hung starts first.** A `ddev start` left over from before the crash will fight the new one.
- **The app process can outlive the engine.** `com.docker.backend` may still be resident while the engine underneath is gone; `timeout 5 docker version` hanging on the Server section is the check. On macOS, `~/Library/Containers/com.docker.docker/Data/log/host/com.docker.backend.log` records "engine crash" / "recovery action" lines.
- **Sweep orphan containers all at once.** "Container name already in use" on every start means leftovers from the crash. Removing them one at a time is whack-a-mole:

  ```bash
  docker ps -aq --filter name=ddev | xargs -r docker rm -f
  ```

- **The first cold drush is slow.** The first `drush` after a real engine restart can take around two minutes. A health probe or watchdog with a short timeout reads that as a failure and triggers recovery again, forever. Warm drush once (`ddev drush core:status`) before trusting any health output or starting test suites.

## Trimming the Mutagen payload

With `performance_mode: mutagen`, everything under the project root syncs into the container. Large directories the container never uses (for example `node_modules` belonging to serverless functions or sibling non-Drupal projects in the repo) slow the initial sync and every rescan. Trimming them took one project from about 620K synced files to about 268K, with an initial sync of under two minutes.

Customize `.ddev/mutagen/mutagen.yml`:

1. **Remove the `#ddev-generated` header line.** While it is present, DDEV regenerates the file and discards your changes.
2. Add the heavy paths to the ignore list:

   ```yaml
   sync:
     defaults:
       ignore:
         paths:
           # keep the paths DDEV already lists, then add yours:
           - "/path/to/functions/*/node_modules"
           - "/unrelated-subproject"
   ```

3. `ddev mutagen reset && ddev start` to resync.

**Do not ignore `node_modules` globally.** Theme and custom-module builds that run inside the container need theirs synced.

Ignored paths do not exist inside the container. Any tool you run in the container (tests that read fixture files from those trees, linters that scan them) sees an empty directory; run those checks on the host.

## Kernel tests against a throwaway database

`KernelTestBase` installs its own schema and never needs the site's database. Point `SIMPLETEST_DB` at a disposable MariaDB container and run PHPUnit with host PHP (needs `pdo_mysql`), and Kernel runs no longer depend on the DDEV project being healthy:

```bash
docker run -d --rm --name kernel-db -p 3307:3306 \
  -e MARIADB_ROOT_PASSWORD=root -e MARIADB_DATABASE=kernel mariadb:10.11

SIMPLETEST_DB='mysql://root:root@127.0.0.1:3307/kernel' \
  vendor/bin/phpunit -c phpunit.xml web/modules/custom/my_module/tests/src/Kernel

docker stop kernel-db
```

This also takes the macOS bind mount out of the loop for Kernel suites, which is the dominant cost there (see "Where to Run Kernel Suites" in SKILL.md). Tests that need the installed site (`ExistingSite`, Functional, real config) still run in DDEV.

## Coordinating multiple agents on one DDEV project

Several agents sharing one DDEV project each running `drush cr`, a theme build, PHPUnit or `ddev restart` at the same time leads to OOM kills, Mutagen desync, stale code being served, and WSODs. A small wrapper script that every agent calls before container work prevents most of it. The concept:

- **Two tiers of lock.**
  - **Exclusive:** `ddev start`/`restart`/`poweroff`, `ddev mutagen reset`, recovery, theme builds. Takes every slot; nothing else runs.
  - **Heavy:** `drush cr`, config import, `updatedb`, PHPUnit, Playwright. A **counting semaphore** with a small number of slots (around 3 worked on a large workstation). Strict one-at-a-time serialization of this tier tends to cap throughput before memory does. If OOM symptoms return, drop to one slot.
- **Atomic, self-expiring locks.** `mkdir` is atomic on a local filesystem and makes a simple slot lock. Break locks older than a generous timeout so a crashed agent cannot hold one forever.
- **Coalesce cache rebuilds.** Record when the last rebuild started. Skip a requested `drush cr` if a rebuild already started after the request was made; the result is the same and N agents stop queueing N rebuilds.
- **One owner for restarts and builds.** Sub-agents edit source and commit; the lead does the single theme build and any restart. Git worktrees isolate source files, not the shared containers, so worktree agents still need the lock for container operations.
- **One recovery owner.** Recovery (Mutagen flush, web restart, full poweroff/start) should be single-flight and should not tear DDEV down while other agents hold locks.
- **Enforce it.** Advice in an instructions file is easily skipped; a pre-command hook that blocks bare `ddev restart` / PHPUnit / Playwright invocations outside the wrapper is what makes the lock real.
