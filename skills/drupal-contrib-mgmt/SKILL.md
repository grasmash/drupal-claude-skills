---
name: drupal-contrib-mgmt
description: Manages Drupal contributed modules via Composer - module updates and major-version upgrades, cweagans/composer-patches v2 (patches.lock.json, composer patches-relock, verifying patches are applied), mglaman/composer-drupal-lenient, Drupal 11 compatibility checks with upgrade_status, committing an optimized vendor/ autoloader, and contributing fixes back to drupal.org via issue forks and merge requests. Use when updating or upgrading contrib modules, applying, finding or creating patches, a patch fails or keeps regressing after composer install, resolving Composer dependency or drupal/core version conflicts, checking Drupal 11 readiness or deprecations, or contributing to a drupal.org issue queue.
---

# Drupal Contrib Module Management

Use this skill for any Composer-managed contrib work: updating a module, adding or debugging a patch, unblocking a version constraint, preparing for Drupal 11, or pushing a fix upstream. The core update workflow and the patch rules below apply on every use; task-specific detail lives in `references/` (see the table at the end).

## Core Update Workflow

### Standard Module Update

```bash
# Update a single module
composer require drupal/module_name --with-all-dependencies

# Update to specific version
composer require drupal/module_name:^3.0 --with-all-dependencies

# Update multiple modules
composer require drupal/module_a drupal/module_b --with-all-dependencies

# After any update, ALWAYS run database updates
drush updb -y

# Clear cache if needed
drush cr

# CRITICAL: Test by visiting pages to check for fatal errors
# Visit at least one page that uses the updated module
```

### Major Version Upgrades

When upgrading to a new major version (e.g., 2.x → 3.x):

1. **Check compatibility**: Ensure module supports your Drupal core version
2. **Search issue queue** for patches: `https://www.drupal.org/project/issues/MODULE_NAME?categories=All`
3. **Use Drupal Lenient** for version requirement issues (see below)
4. **Apply patches** via composer.json (see Patch Management section)
5. **Run upgrade_status** to check for deprecations

## Checking Drupal 11 Compatibility

Three methods (`.info.yml`, Composer, drupal.org) and the full upgrade_status workflow: see [references/d11-upgrade-workflow.md](references/d11-upgrade-workflow.md).

## Drupal Lenient Plugin

The `mglaman/composer-drupal-lenient` plugin allows installing modules that haven't updated their version requirements yet.

Lenient/core-compat overrides: see references/drupal-lenient.md — that reference covers validating candidates against UPSTREAM `composer.json`/`.info.yml` requirements (not the local patched copy), the `composer prohibits` check, and when to add/remove a module from the allowed-list.

### Setup

```json
{
  "require": {
    "mglaman/composer-drupal-lenient": "^1.0"
  },
  "config": {
    "allow-plugins": {
      "mglaman/composer-drupal-lenient": true
    }
  },
  "extra": {
    "drupal-lenient": {
      "allowed-list": [
        "drupal/module_name",
        "drupal/another_module"
      ]
    }
  }
}
```

### Usage

```bash
# Add module to allowed-list, then install
composer require drupal/module_name --with-all-dependencies
```

## Patch Management (cweagans/composer-patches)

**IMPORTANT**: Use version 2.x for reliable patch application. Version 1.x uses the `patch` binary which can have issues on some systems. Version 2.x uses `git apply` by default.

### Patch Configuration

```json
{
  "require": {
    "cweagans/composer-patches": "^2.0"
  },
  "config": {
    "allow-plugins": {
      "cweagans/composer-patches": true
    }
  },
  "extra": {
    "composer-exit-on-patch-failure": true,
    "patches": {
      "drupal/module_name": {
        "Description of patch": "https://www.drupal.org/files/issues/2024-01-15/module-issue-1234567-8.patch",
        "Local patch": "patches/custom-fix.patch"
      }
    },
    "patchLevel": {
      "drupal/core": "-p2"
    }
  }
}
```

### Upgrading from 1.x to 2.x

If you're on version 1.x and experiencing patch failures:

```bash
composer require cweagans/composer-patches:^2.0 --with-all-dependencies
```

Key differences in 2.x:
- Uses `git apply` instead of `patch` binary (more reliable)
- `enable-patching` option removed (patching is always enabled)
- Better error messages and debugging
- **CRITICAL — the `patches.lock.json` apply source**: v2 applies patches from `patches.lock.json` on `composer install` / `composer reinstall`. It does **NOT** read `extra.patches` in `composer.json` during those commands — only `composer update` and `composer patches-relock` re-read `composer.json` and regenerate the lock. So adding a patch to `composer.json` and running `composer install` applies **nothing** for that patch until you relock. This is the #1 cause of patches that "keep regressing": local dev looks fixed (you hand-applied it or ran `update`), but the next clean install — CI, a teammate, a fresh deploy — reads the stale lock and drops the patch. **Always run `composer patches-relock` after editing `extra.patches`, and commit `patches.lock.json`.**

### Verifying Patches Are Applied

**THREE DIFFERENT PROBLEMS, ONE SCRIPT**:

1. **Lock-sync staleness (the root cause)**: a patch is registered in `composer.json` `extra.patches` but never added to `patches.lock.json` because `composer patches-relock` was skipped. v2 applies from the lock on `composer install`, so the patch is silently a no-op on every clean install. The fix is the relock; the script's job is to *catch* the skip by asserting every local patch in `composer.json` is present in `patches.lock.json`.

2. **Committed file drift**: a patch IS applied to the working tree, but the resulting contrib file change is never committed to git. Pantheon (and any platform that deploys from committed git state without running `composer install`) never sees it, so production silently runs un-patched code. Local dev looks fine. See CLAUDE.md "Contrib/Core Patch Policy" for context.

3. **Patch hash cache staleness**: even with the lock in sync, a stray reinstall or vendor update can skip re-applying. Rare next to (1) and (2), but the same materialized-file check catches it.

**SOLUTION**: `scripts/verify-patches.sh`

```bash
# Run manually (verifies committed state)
./scripts/verify-patches.sh

# Auto-reinstall affected modules to re-apply patches
./scripts/verify-patches.sh --fix
```

**Behavior**:
- Runs two checks. (1) **Lock-sync**: every local patch in `composer.json` `extra.patches` must also appear in `patches.lock.json` — catches the skipped `patches-relock`. (2) **Materialized-file**: the patched lines must be present in the committed contrib file — catches "patched but not committed".
- Auto-derives the verification list from `composer.json` `extra.patches` — **no manual curation required**. Adding a patch entry is enough; the script picks it up automatically.
- For each local patch (value starting with `patches/`), it parses all `+++ b/<path>` headers, extracts up to 5 distinctive added lines (≥ 8 non-whitespace chars, not a substring of any `-` line in the same patch), and greps the target file for them. Handles the `drupal/core` package's `core/` path-prefix quirk and is bash 3 compatible.
- URL-based patches (`https://...`) are skipped with a notice — add a local mirror under `patches/` if the patch is critical.
- Runs in CI **before** `composer install` in the `lint` job (`.github/workflows/test.yml`), so it validates the COMMITTED tree — not the post-install state. This is the ordering that matters.

**Adding a new patch** (the relock step is the one everyone forgets):
1. Drop the `.patch` file in `patches/`
2. Register it in `composer.json` under `extra.patches`
3. **Run `composer patches-relock`** — adds the patch to `patches.lock.json`. WITHOUT this, step 4's `composer install` applies nothing (v2 reads the lock, not `composer.json`).
4. Run `composer install` to apply the patch to the working tree
5. **`git add` and commit the modified contrib file** along with `composer.json`, `patches.lock.json`, and the new `.patch` file — platforms that deploy from git (Pantheon) can't apply patches on their own, so the committed contrib file must already be in its patched form
6. **Write a behavior test for the patched functionality** (see below)
7. Run `./scripts/verify-patches.sh` locally to sanity-check before pushing
8. CI will re-run the same verification on every push

**Every patch ships a behavior test.** `verify-patches.sh` is structural: it proves the patch *lines* are present in the committed file, not that the patched code *behaves* correctly. A patch can be applied and still not fix anything (wrong hunk, upstream refactor moved the logic, a later patch undid it). The test is what makes the patch durable across module bumps:
- **Negative case**: exercise the exact edge condition the patch fixes. For a new patch, write this test first against the **unpatched** module and watch it fail for the reported reason — otherwise you have not proven it tests the bug.
- **Positive case**: the normal path still works (no regression).
- Place the test in the consuming custom module's `tests/` directory and reference the `.patch` file in the test's docblock, so whoever bumps the module can find it.
- **Never bump a patched module whose patch has no behavior test.** Write the test first, then bump, then confirm it still passes (or that the patch is now upstream and can be dropped).

**When `verify-patches.sh` reports MISSING in CI**:
- Lock-sync failure → someone skipped `composer patches-relock` (step 3). Fix: run it, commit `patches.lock.json`, push.
- Materialized-file failure → someone forgot to commit the patched contrib file (step 5). Fix: `composer patches-relock && composer install` locally, `git add docroot/modules/contrib docroot/core patches.lock.json`, commit, and push.

**Caveats**:
- "Combined patches" (one `.patch` file with multiple `+++ b/<same_file>` headers, usually squashed commits with conflicting hunks) may slip through — the script accepts any distinctive added line, so a partial match passes. If you see a patch land in `patches/` with multiple hunks revising the same file, regenerate it as a clean single-commit diff instead.
- PHPCS: committing patched contrib files can trip `grumphp`'s pre-commit `phpcs` task on pre-existing sniff violations in upstream code. `grumphp.yml` already ignores `docroot/modules/contrib`, `docroot/core`, and `docroot/libraries` for this task — don't remove those ignores.

### Finding Patches

**Issue Queue Search**: `https://www.drupal.org/project/issues/MODULE_NAME?categories=All`

**Patch Naming Convention**:
- Format: `module-issue-NODEID-COMMENT.patch`
- Example: `audiofield-d11-3432063-12.patch`
- Node ID is the issue number (visit `drupal.org/node/NODEID`)

**When Existing Patches Fail After Update**:
1. Extract node ID from patch filename (e.g., `3432063` from above)
2. Visit `https://www.drupal.org/node/3432063`
3. Look for updated patch in latest comments
4. Update composer.json with new patch URL

### Debugging Errors and Creating Local Patches

Search the issue queue for an existing patch BEFORE writing one; the step-by-step search and the separate-clone patch workflow are in [references/finding-and-creating-patches.md](references/finding-and-creating-patches.md).

### Patch Application

```bash
# Install with patches
composer install

# If patches fail, composer will error
# Update or remove failing patches, then retry
composer install

# Re-patch a single module (most common)
composer update drupal/module_name

# Re-patch ALL patched dependencies (use when changing multiple patches)
composer patches-repatch
```

**For detailed patch workflows, see:** `references/drupal-patches-workflow.md`
## Drupal 11 Compatibility Workflow

The six-step upgrade_status workflow (analyze, identify, fix custom code, `.info.yml` patches, lenient list, verify) is in [references/d11-upgrade-workflow.md](references/d11-upgrade-workflow.md).

## Complete Update Checklist

- [ ] Check current module version: `composer show drupal/module_name`
- [ ] Search issue queue for known issues
- [ ] Check if module is D11 compatible
- [ ] Update composer.json with new version
- [ ] Add to drupal-lenient if needed
- [ ] Search for and apply necessary patches
- [ ] Confirm every existing patch on the module has a behavior test, and run it after the bump
- [ ] Run `composer require drupal/module_name:^X.0 --with-all-dependencies`
- [ ] Run `drush updb -y`
- [ ] Run `drush cr`
- [ ] Run `drush upgrade_status:analyze module_name`
- [ ] Test module functionality by visiting relevant pages
- [ ] Check for PHP errors/warnings in logs
- [ ] Commit changes with descriptive message

## Troubleshooting

### Patch Won't Apply

```bash
# Error: "Cannot apply patch..."
# 1. Check if module version changed
composer show drupal/module_name

# 2. Search issue queue for updated patch
# Visit drupal.org/node/NODEID (from patch filename)

# 3. Update composer.json with new patch URL
# 4. Or remove patch if merged upstream
```

### Version Conflict

```bash
# Error: "drupal/module_name requires drupal/core ^9"
# Add to drupal-lenient allowed-list
```

### Patch Already Applied

```bash
# Error: "patch ... has already been applied"
# Module maintainer merged the patch - remove from composer.json
```

### Database Update Fails

```bash
# Error during drush updb
# 1. Check error message carefully
# 2. May need to disable module, update, re-enable
drush pm:uninstall module_name
composer require drupal/module_name --with-all-dependencies
drush pm:enable module_name
drush updb -y
```

## Best Practices

1. **Always use `--with-all-dependencies`** for module updates
2. **Always run `drush updb`** after composer updates
3. **Test immediately** after updates (visit pages, check logs)
4. **Keep patches organized** in a `patches/` directory
5. **Document patches** with descriptive names and comments
6. **Check issue queues first** before creating custom patches
7. **Use upgrade_status** to validate D11 compatibility
8. **Commit atomically**: one module update per commit
9. **Use descriptive commit messages** with patch references
10. **Keep drupal-lenient list minimal** (only when necessary)

## Production Deployment

When deploying to production environments (Pantheon, Acquia, etc.), always optimize the Composer install:

```bash
# CRITICAL: Always use these flags for production
composer install --no-dev -o

# --no-dev: Excludes development dependencies (phpunit, rector, etc.)
# -o (--optimize-autoloader): Optimizes autoloader for performance
```

**Why This Matters**:
- `--no-dev` reduces codebase size by excluding testing/dev tools
- `-o` creates optimized class maps for faster autoloading
- Reduces security surface by excluding dev dependencies
- Improves performance on production servers

**Production Deployment Workflow**:

```bash
# 1. After making composer changes locally
composer update drupal/module_name --with-all-dependencies

# 2. Before committing, optimize for production
composer install --no-dev -o

# 3. Commit the optimized vendor files. If you stage selectively, vendor/autoload.php
#    MUST go with vendor/composer/: the autoloader class suffix lives in vendor/autoload.php,
#    vendor/composer/autoload_real.php and vendor/composer/autoload_static.php, and staging
#    only some of them is a site-wide "ComposerAutoloaderInit... not found" fatal.
#    Never commit the autoloader left behind by a later dev `composer install`.
git add composer.json composer.lock vendor/
git commit -m "Update module_name with production optimization"

# 4. Push to production
git push origin master

# 5. Rebuild caches on the remote env (use your platform's remote-drush form):
acli remote:drush -- cr                       # Acquia
# terminus drush <site>.<env> -- cr           # Pantheon
# platform drush -e <env> -- cr               # Platform.sh (Upsun: upsun drush -- cr)
# lagoon ssh -p <project> -e <env> -C "drush cr"   # Lagoon / amazee.io
# drush @<alias> cr                            # generic, any host with Drush aliases
```

**NEVER commit vendor/ with dev dependencies to production branches!**
## Developing and Contributing Contrib Modules

The symlink development workflow and the drupal.org issue-fork / merge-request workflow are in [references/contributing-upstream.md](references/contributing-upstream.md). Worked update recipes (known patch, D11 fix, breaking major upgrade) are in [references/update-patterns.md](references/update-patterns.md).

## References

| File | Read it when |
|------|--------------|
| [references/d11-upgrade-workflow.md](references/d11-upgrade-workflow.md) | Checking whether a module supports Drupal 11, or running an upgrade_status scan and fixing what it finds |
| [references/d11-common-deprecations.md](references/d11-common-deprecations.md) | Replacing a specific deprecated constant, function, class constant or Twig filter |
| [references/drupal-lenient.md](references/drupal-lenient.md) | Deciding whether a module belongs on (or can come off) the drupal-lenient allowed-list |
| [references/finding-and-creating-patches.md](references/finding-and-creating-patches.md) | Hitting a Drupal error and looking for an existing patch, or writing a new local patch from a clean clone |
| [references/drupal-patches-workflow.md](references/drupal-patches-workflow.md) | Any deeper composer-patches question: plugin commands, remote/local/MR-diff patches, stacking a patch on already-patched modules |
| [references/issue-queue-rss-feeds.md](references/issue-queue-rss-feeds.md) | Querying a drupal.org issue queue programmatically (RSS filters, curl/WebFetch parsing) |
| [references/update-patterns.md](references/update-patterns.md) | Following a worked recipe for a patched update, a D11 contrib fix, or a major upgrade with rollback |
| [references/contributing-upstream.md](references/contributing-upstream.md) | Developing a contrib module locally via symlink, or contributing a fix through an issue fork and merge request |
| [examples/](examples/) | Runnable shell walk-throughs of the same scenarios |

## Reference Links

- **Composer Patches**: https://github.com/cweagans/composer-patches
- **Drupal Lenient**: https://github.com/mglaman/composer-drupal-lenient
- **Upgrade Status Module**: https://www.drupal.org/project/upgrade_status
- **Drupal 11 Deprecations**: https://www.drupal.org/about/core/policies/core-change-policies/drupal-deprecation-policy
- **Patch Naming Standards**: https://www.drupal.org/node/1054616
- **Creating Issue Forks**: https://www.drupal.org/docs/develop/git/using-gitlab-to-contribute-to-drupal/creating-issue-forks
- **Issue Report Guide**: https://www.drupal.org/community/contributor-guide/reference-information/quick-info/creating-or-updating-an-issue-report
- **Text Formatting Tips**: https://www.drupal.org/filter/tips
- **Git Workflow for Drupal**: https://www.drupal.org/docs/develop/git/using-git-to-contribute-to-drupal
