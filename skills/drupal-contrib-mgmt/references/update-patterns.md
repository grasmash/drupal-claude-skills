# Common Update Patterns

Worked recipes for frequent contrib update scenarios.

## Common Patterns

### Pattern: Update Module with Known Patch

```bash
# 1. Find patch in issue queue
# 2. Add to composer.json patches section, then record it in patches.lock.json
#    (v2 applies from the lock; without the relock the update below skips the patch)
composer patches-relock
# 3. Update module
composer require drupal/module_name:^3.0 --with-all-dependencies
drush updb -y   # rebuilds caches when it finishes
# 4. Test
# 5. Commit
git add composer.json composer.lock patches.lock.json patches/
git commit -m "Update module_name to 3.0 with D11 compatibility patch"
```

### Pattern: Fix Contrib D11 Issue

```bash
# 1. Scan for issues
drush upgrade_status:analyze module_name

# 2. Create info.yml patch if needed (run from the project root)
MODULE_DIR=docroot/modules/contrib/module_name   # or web/modules/contrib/module_name
git -C "$MODULE_DIR" init -q                     # contrib is not a git repo: temporary baseline
git -C "$MODULE_DIR" add -A
git -C "$MODULE_DIR" -c user.name=patch -c user.email=patch@localhost commit -qm pristine
# Edit $MODULE_DIR/module_name.info.yml to add ^11
git -C "$MODULE_DIR" diff > patches/module-d11-info.patch
git -C "$MODULE_DIR" checkout -- .
rm -rf "$MODULE_DIR/.git"

# 3. Add patch to composer.json, then record it in patches.lock.json
composer patches-relock
# 4. Apply
composer reinstall drupal/module_name
drush cr

# 5. Verify
drush upgrade_status:analyze module_name
```

### Pattern: Major Version Upgrade with Breaking Changes

```bash
# 1. Read CHANGELOG/UPDATE.md for breaking changes
# 2. Check issue queue for upgrade path documentation
# 3. Backup database before upgrade
drush sql:dump > backup-before-update.sql

# 4. Update module
composer require drupal/module_name:^3.0 --with-all-dependencies

# 5. Run updates
drush updb -y

# 6. Check for errors
drush watchdog:show --severity=Error --count=20

# 7. Test thoroughly
# 8. If issues, can rollback:
# git checkout composer.json composer.lock
# composer install
# drush sql:cli < backup-before-update.sql
```
