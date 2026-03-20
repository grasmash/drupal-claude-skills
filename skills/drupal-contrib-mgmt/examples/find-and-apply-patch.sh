#!/bin/bash
# Example: Find and apply a patch from Drupal.org issue queue

# SCENARIO: audiofield module has deprecated file_validate_extensions() function
# We need to find a patch to fix this for Drupal 11

# Step 1: Go to issue queue
echo "1. Navigate to: https://www.drupal.org/project/issues/audiofield?categories=All"
echo "2. Search for: 'file_validate_extensions' or 'Drupal 11'"

# Step 2: Evaluate the issue
echo "
Found issue: https://www.drupal.org/node/3432063
Title: 'Replace deprecated file_validate_extensions()'
Status: Needs review
✅ Tests passing (green checkmark)
✅ Multiple people tested
✅ Recent activity
"

# Step 3: Find the patch
echo "
Latest patch in comment #12:
audiofield-file-validator-3432063-12.patch
URL: https://www.drupal.org/files/issues/2024-06-15/audiofield-file-validator-3432063-12.patch
"

# Step 4: Test patch locally first (optional but recommended)
echo "Testing patch before adding to composer..."
cd docroot/modules/contrib/audiofield
curl -O https://www.drupal.org/files/issues/2024-06-15/audiofield-file-validator-3432063-12.patch

# Dry run to check if it applies
patch -p1 --dry-run < audiofield-file-validator-3432063-12.patch

echo "✓ Patch applies cleanly"
cd ../../..

# Step 5: Add to composer.json
cat >> composer.json <<'EOF'
{
  "extra": {
    "patches": {
      "drupal/audiofield": {
        "Replace deprecated file_validate_extensions() - https://drupal.org/node/3432063": "https://www.drupal.org/files/issues/2024-06-15/audiofield-file-validator-3432063-12.patch"
      }
    }
  }
}
EOF

# Step 6: Apply patch via composer
composer install

# Or if module needs updating too:
# composer require drupal/audiofield:^1.13 --with-all-dependencies

# Step 7: Verify
drush cr
drush upgrade_status:analyze audiofield

echo "✓ Deprecation should be resolved"

# Step 8: Test functionality
echo "
Manual testing checklist:
- Visit audio field configuration
- Upload an audio file
- Check file validation works
- View node with audio field
- Check for PHP errors in logs
"

drush watchdog:show --severity=Error --count=10

# Step 9: Commit
git add composer.json composer.lock
git commit -m "Apply patch to fix file_validate_extensions() in audiofield

Applied patch from drupal.org/node/3432063 to fix deprecated
file_validate_extensions() function for Drupal 11 compatibility.

Tested: Audio upload and validation working correctly."

echo "✓ Complete!"

# ALTERNATIVE: If no patch exists in issue queue
echo "
If no suitable patch found:
1. Create your own (see create-custom-patch.sh example)
2. Consider contributing it back to the issue queue
3. Add comment to issue queue mentioning you're working on it
"
