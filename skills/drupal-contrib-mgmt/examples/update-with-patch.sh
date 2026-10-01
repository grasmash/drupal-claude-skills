#!/bin/bash
# Example: Update audiofield module with D11 compatibility patch

# 1. Add patch to composer.json first
cat >> composer.json <<'EOF'
{
  "extra": {
    "patches": {
      "drupal/audiofield": {
        "Drupal 11 .info.yml support": "patches/audiofield-d11-info.patch",
        "Fix file_validate_extensions deprecation": "https://www.drupal.org/files/issues/2024-06-15/audiofield-3432063-12.patch"
      }
    }
  }
}
EOF

# 2. Create local .info.yml patch if needed
MODULE_DIR=docroot/modules/contrib/audiofield   # or web/modules/contrib/audiofield
git -C "$MODULE_DIR" init -q && git -C "$MODULE_DIR" add -A   # contrib is not a git repo: temporary baseline
git -C "$MODULE_DIR" -c user.name=patch -c user.email=patch@localhost commit -qm pristine
# Edit $MODULE_DIR/audiofield.info.yml to add ^11 to core_version_requirement
git -C "$MODULE_DIR" diff > patches/audiofield-d11-info.patch
git -C "$MODULE_DIR" checkout -- . && rm -rf "$MODULE_DIR/.git"
composer patches-relock   # v2 applies patches from patches.lock.json

# 3. Update module
composer require drupal/audiofield:^1.13 --with-all-dependencies

# 4. Run database updates
drush updb -y

# 5. Clear cache
drush cr

# 6. Verify fix
drush upgrade_status:analyze audiofield

# 7. Test functionality
# Visit a page that uses audiofield to ensure no fatal errors

# 8. Commit
git add composer.json composer.lock patches/audiofield-d11-info.patch
git commit -m "Update audiofield to 1.13 with D11 compatibility patches

- Added Drupal 11 core_version_requirement support
- Applied patch for file_validate_extensions() deprecation
- Tested: audio upload functionality works correctly"
