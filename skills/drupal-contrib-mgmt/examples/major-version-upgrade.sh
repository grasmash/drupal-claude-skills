#!/bin/bash
# Example: Upgrade entity_limit from 2.x to 3.x with D11 compatibility

# 1. Check current version
composer show drupal/entity_limit
# Output: drupal/entity_limit 2.0.0

# 2. Search issue queue for known issues
# Visit: https://www.drupal.org/project/issues/entity_limit?categories=All
# Find: Issue #3432063 - Drupal calls should be avoided in classes

# 3. Backup database (major version upgrade!)
drush sql:dump > backup-before-entity-limit-3x.sql

# 4. Allow the 3.x install despite its core constraint, and register the
#    upstream patch (composer config --merge writes valid JSON and keeps
#    existing entries; appending with cat >> composer.json would corrupt it)
composer config --json --merge extra.drupal-lenient.allowed-list '["drupal/entity_limit"]'
composer config --json --merge extra.patches.drupal/entity_limit \
  '{"Drupal calls should be avoided in classes": "https://www.drupal.org/files/issues/2024-03-19/3432063-2.patch"}'
composer patches-relock   # v2 applies patches from patches.lock.json

# 5. Update to 3.x BEFORE cutting the local .info.yml patch: a patch cut against
#    the installed 2.x would be diffed against the wrong file and may not apply
#    to 3.x (or would silently revert 3.x changes in that file)
composer require drupal/entity_limit:^3.0@beta --with-all-dependencies

# 6. Create the .info.yml patch against the now-installed 3.x
MODULE_DIR=docroot/modules/contrib/entity_limit   # or web/modules/contrib/entity_limit
git -C "$MODULE_DIR" init -q && git -C "$MODULE_DIR" add -A   # contrib is not a git repo: temporary baseline
git -C "$MODULE_DIR" -c user.name=patch -c user.email=patch@localhost commit -qm pristine
# Manually edit $MODULE_DIR/entity_limit.info.yml to add ^11 to core_version_requirement
git -C "$MODULE_DIR" diff > patches/entity_limit-d11-info.patch
git -C "$MODULE_DIR" checkout -- . && rm -rf "$MODULE_DIR/.git"
composer config --json --merge extra.patches.drupal/entity_limit \
  '{"Drupal 11 .info.yml support": "patches/entity_limit-d11-info.patch"}'
composer patches-relock
composer reinstall drupal/entity_limit   # re-installs 3.x and applies both patches

# 7. Run database updates
drush updb -y

# 8. Check for errors
drush watchdog:show --severity=Error --count=10

# 9. Clear cache
drush cr

# 10. Run upgrade_status check
drush upgrade_status:analyze entity_limit

# 11. Test functionality
# - Visit entity limit configuration page
# - Test creating content with entity limits
# - Check permissions work correctly

# 12. If successful, commit
git add composer.json composer.lock patches.lock.json patches/entity_limit-d11-info.patch
git commit -m "Upgrade entity_limit to 3.0.0-beta1 with D11 compatibility

Breaking changes:
- Updated API methods (see https://www.drupal.org/node/XXXXX)
- New permission system

Applied patches:
- Drupal calls fix (#3432063)
- D11 core version requirement

Tested: All entity limit functionality working correctly"

# 13. If issues occur, rollback:
# git checkout composer.json composer.lock
# composer install
# drush sql:cli < backup-before-entity-limit-3x.sql
# drush cr
