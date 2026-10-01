# Common Update Patterns

Worked recipes for frequent contrib update scenarios.

## Common Patterns

### Pattern: Update Module with Known Patch

```bash
# 1. Find patch in issue queue
# 2. Add to composer.json patches section
# 3. Update module
composer require drupal/module_name:^3.0 --with-all-dependencies
drush updb -y
drush cr
# 4. Test
# 5. Commit
git add composer.json composer.lock patches/
git commit -m "Update module_name to 3.0 with D11 compatibility patch"
```

### Pattern: Fix Contrib D11 Issue

```bash
# 1. Scan for issues
drush upgrade_status:analyze module_name

# 2. Create info.yml patch if needed
cd docroot/modules/contrib/module_name
# Edit module.info.yml to add ^11
git diff module.info.yml > ../../../patches/module-d11-info.patch

# 3. Add patch to composer.json
# 4. Apply
composer install
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
