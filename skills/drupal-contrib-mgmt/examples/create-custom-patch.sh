#!/bin/bash
# Example: Create a custom patch when no upstream patch exists

# SCENARIO: licensing module uses deprecated user_roles() function
# No patch exists in issue queue, so we create our own

echo "Creating custom patch for licensing module user_roles() deprecation"

# Step 1: Verify the issue
echo "Step 1: Checking current code..."
drush upgrade_status:analyze licensing

# Shows: "Call to deprecated function user_roles() at line 77"

# Step 2: Navigate to module
cd docroot/modules/contrib/licensing

# Step 3: Check git status (should be clean)
git status
# Should show: nothing to commit, working tree clean

# Step 4: Identify the file and make changes
echo "Step 4: Editing src/Form/LicenseTypeForm.php..."

# BEFORE (line ~77):
# $role_options = user_roles(TRUE);

# AFTER: Use proper dependency injection
# Add to file header:
# use Drupal\user\Entity\Role;

# In the form builder method, replace:
# $role_options = user_roles(TRUE);
#
# With:
# $roles = Role::loadMultiple();
# $role_options = [];
# foreach ($roles as $role_id => $role) {
#   if ($role_id !== 'anonymous') {
#     $role_options[$role_id] = $role->label();
#   }
# }

# For this example, let's show the actual edit:
cat > /tmp/licensing_patch_snippet.txt <<'EOF'
This is what you would edit in src/Form/LicenseTypeForm.php:

1. Add to top of file (around line 5):
   use Drupal\user\Entity\Role;

2. Replace (around line 77):
   OLD: $role_options = user_roles(TRUE);

   NEW:
   $roles = Role::loadMultiple();
   $role_options = [];
   foreach ($roles as $role_id => $role) {
     if ($role_id !== 'anonymous') {
       $role_options[$role_id] = $role->label();
     }
   }
EOF

cat /tmp/licensing_patch_snippet.txt

# After making your edits in your editor:
echo "
Make the changes shown above using your text editor, then continue...
Press Enter when changes are made"
# read -p ""

# Step 5: Create the patch
echo "Step 5: Creating patch file..."
git diff > ../../../patches/licensing-user-roles-d11-fix.patch

# Step 6: Verify patch format
echo "Step 6: Verifying patch..."
cat ../../../patches/licensing-user-roles-d11-fix.patch

# Should show:
# diff --git a/src/Form/LicenseTypeForm.php b/src/Form/LicenseTypeForm.php
# index abc123..def456 100644
# --- a/src/Form/LicenseTypeForm.php
# +++ b/src/Form/LicenseTypeForm.php
# ... changes ...

# Step 7: Test patch applies
echo "Step 7: Testing patch application..."
git apply --check ../../../patches/licensing-user-roles-d11-fix.patch
echo "✓ Patch applies cleanly"

# Step 8: Reset changes (patch will be applied via composer)
git checkout .

# Step 9: Add to composer.json
cd ../../..

echo "Step 9: Adding patch to composer.json..."

# Edit composer.json to add:
cat >> composer.json <<'EOF'
{
  "extra": {
    "patches": {
      "drupal/licensing": {
        "Replace deprecated user_roles() for D11 compatibility": "patches/licensing-user-roles-d11-fix.patch",
        "Drupal 11 .info.yml support": "patches/licensing-d11-info.patch"
      }
    }
  }
}
EOF

# Step 10: Apply via composer
echo "Step 10: Applying patch via composer..."
composer install

# Should show:
# - Applying patches for drupal/licensing
#   patches/licensing-user-roles-d11-fix.patch (Replace deprecated user_roles()...)

# Step 11: Test
echo "Step 11: Testing..."
drush cr
drush upgrade_status:analyze licensing

# Should now show: "No known issues found"

# Test functionality
echo "
Manual testing:
1. Visit /admin/licensing/types
2. Add/edit a license type
3. Check role selection works
4. Save and verify
"

drush watchdog:show --severity=Error --count=10

# Step 12: Commit
git add composer.json composer.lock patches/licensing-user-roles-d11-fix.patch
git commit -m "Fix deprecated user_roles() in licensing module for D11

Created custom patch to replace deprecated user_roles() function with
Role::loadMultiple() pattern following Drupal best practices.

The patch:
- Adds proper use statement for Role entity
- Replaces user_roles(TRUE) with Role::loadMultiple()
- Filters out anonymous role manually
- Maintains same functionality

Tested: License type form works correctly, role selection functioning."

echo "✓ Custom patch created and applied!"

# BONUS: Consider contributing back
echo "
Optional: Contribute patch to drupal.org

1. Check if issue exists: https://www.drupal.org/project/issues/licensing
2. If not, create new issue:
   - Title: 'Replace deprecated user_roles() for Drupal 11'
   - Category: Bug report
   - Priority: Normal
   - Version: 2.0.x-dev
3. Upload your patch file
4. Explain changes and testing
5. Set status to 'Needs review'
"
