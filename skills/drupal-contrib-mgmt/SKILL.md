---
name: drupal-contrib-mgmt
description: Comprehensive guide for managing Drupal contributed modules via Composer, including updates, patches, version compatibility, and Drupal 11 upgrades. Use when updating modules or resolving dependency issues.
---

# Drupal Contrib Module Management

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

**Three methods to check if a module is D11 compatible** (in order of preference):

### Method 1: Check .info.yml File (Fastest, Most Reliable)

```bash
# Check the module's .info.yml file for core_version_requirement
cat docroot/modules/contrib/MODULE_NAME/MODULE_NAME.info.yml | grep core_version_requirement
```

**What to look for**:
```yaml
core_version_requirement: ^9.5 || ^10 || ^11     # ✅ D11 compatible
core_version_requirement: ^8 || ^9 || ^10 || ^11  # ✅ D11 compatible
core_version_requirement: ^9 || ^10                # ❌ Not D11 compatible yet
```

**Example**:
```bash
$ cat docroot/modules/contrib/admin_toolbar/admin_toolbar.info.yml | grep core_version
core_version_requirement: ^9.5 || ^10 || ^11
# ✅ This module declares D11 support!
```

### Method 2: Use Composer Commands (Works Before Installing)

```bash
# Check what versions are available and their constraints
composer show drupal/MODULE_NAME --all | grep -A5 "^versions"

# Check currently installed version
composer show drupal/MODULE_NAME | grep versions
```

**What to look for**:
- Version number (e.g., 3.6.2)
- Check Drupal.org for release notes mentioning D11

### Method 3: Check Drupal.org Project Page

Only use as fallback when above methods aren't conclusive.

```
https://www.drupal.org/project/MODULE_NAME
```

Look for:
- Latest release notes mentioning "Drupal 11"
- Module page header showing D11 compatibility badge
- Issue queue for D11 compatibility issues

**Important Notes**:
- ⚠️ Module may declare D11 support but still have deprecation warnings
- ⚠️ upgrade_status warnings don't mean module is incompatible
- ⚠️ "Check manually" status often means runtime version checks (false positive)
- ✅ If .info.yml declares `^11` support, module maintainer says it works

**Real-World Examples**:

```bash
# admin_toolbar - Already D11 compatible
$ cat docroot/modules/contrib/admin_toolbar/admin_toolbar.info.yml | grep core_version
core_version_requirement: ^9.5 || ^10 || ^11

# But upgrade_status shows warnings about _drupal_flush_css_js()
# This is a FALSE POSITIVE - module handles it with version checks

# audiofield - Already D11 compatible
$ cat docroot/modules/contrib/audiofield/audiofield.info.yml | grep core_version
core_version_requirement: ^8 || ^9 || ^10 || ^11

# Has deprecation warnings but maintainer declares D11 support
```

## Drupal Lenient Plugin

The `mglaman/composer-drupal-lenient` plugin allows installing modules that haven't updated their version requirements yet.

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
- **CRITICAL**: Hash-based caching - patches may not re-apply if module already installed

### Verifying Patches Are Applied

**PROBLEM**: composer-patches 2.x caches patch hashes in `composer.lock`. If modules are reinstalled or vendor updates occur without proper patch application, patches can silently go missing.

**SOLUTION**: Use a `verify-patches.sh` post-install hook:

```bash
# Run manually
./scripts/verify-patches.sh

# Attempt auto-fix for missing patches
./scripts/verify-patches.sh --fix
```

This script runs automatically after `composer install` and verifies critical patches are applied by checking for expected code patterns.

**Adding New Critical Patches to Verification**:

Edit `scripts/verify-patches.sh` and add to the `CRITICAL_PATCHES` array:
```bash
CRITICAL_PATCHES=(
  # Format: "module_path:file_path:search_pattern:description"
  "docroot/modules/contrib/MODULE:src/File.php:patternToFind:Description"
)
```

**When Patches Go Missing**:
1. Run `./scripts/verify-patches.sh` to identify missing patches
2. Run `./scripts/verify-patches.sh --fix` to auto-reinstall affected modules
3. Or manually: `composer reinstall drupal/module_name`
4. If still failing, update `composer.lock`: `composer update --lock`

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

### Debugging Errors: Find Patches BEFORE Creating

**CRITICAL WORKFLOW**: When encountering Drupal errors, ALWAYS search for existing patches before creating your own.

#### Step 1: Extract the Exact Error Signature

From the error message, extract the **exact** error string:

```bash
# Example error:
TypeError: Unsupported operand types: array + null in Drupal\field_ui\Form\EntityViewDisplayEditForm

# Extract this part:
"Unsupported operand types: array + null"
```

#### Step 2: Search Drupal.org Issue Queue FIRST

```bash
# Method 1: Direct URL search (BEST)
https://www.drupal.org/project/drupal/issues?text=Unsupported+operand+types+array+null

# Method 2: Search with file + line number
https://www.drupal.org/project/drupal/issues?text=EntityViewDisplayEditForm+line+166
```

**What to look for in search results**:
- Issues with status: "Needs review" or "Reviewed & tested by the community" (RTBC)
- Recent activity (check dates)
- Patch files in comments (look for `.patch` attachments)
- Merge requests (look for `!13611` references)

#### Step 3: Use WebFetch to Get Patch Details

```bash
# Once you find the issue, fetch details:
WebFetch(https://www.drupal.org/project/drupal/issues/3552531)
```

Look for:
- **Patch file URLs**: Usually `https://www.drupal.org/files/issues/YYYY-MM-DD/filename.patch`
- **Merge request numbers**: E.g., `!13611` → `https://git.drupalcode.org/project/drupal/-/merge_requests/13611`
- **Issue status**: RTBC means ready to use

#### Step 4: Download and Apply Official Patch

```bash
# Download to patches directory
curl -O https://www.drupal.org/files/issues/2025-10-16/field-ui--unsupported-operand-types--3552531-2.patch
mv field-ui--unsupported-operand-types--3552531-2.patch patches/

# Add to composer.json with descriptive name referencing issue
{
  "extra": {
    "patches": {
      "drupal/core": {
        "Fix TypeError: Unsupported operand types array + null in EntityViewDisplayEditForm - Issue #3552531": "patches/field-ui--unsupported-operand-types--3552531-2.patch"
      }
    }
  }
}

# Apply
composer install
```

#### Common Search Patterns

| Error Type | Search Term |
|------------|-------------|
| TypeError | Exact error message in quotes |
| Deprecated function | Function name (e.g., `user_roles`) |
| Missing method | Class name + method name |
| Fatal error | Exact error text |

#### Why This Matters

- **Saves time**: Don't recreate existing solutions
- **Better quality**: Community-reviewed patches are more robust
- **Upstream integration**: Using official patches means easier upgrades
- **Documentation**: Issue threads contain context and discussion

#### Anti-Pattern Example

❌ **What NOT to do**:
1. See error
2. Read code
3. Create patch
4. Apply patch
5. (Someone points out existing issue)

✅ **What TO do**:
1. See error
2. Extract exact error message
3. Search drupal.org issue queue
4. Find existing patch
5. Apply official patch

### Creating Local Patches

**IMPORTANT**: Always create patches from a separate clone of the contrib module repo, not from the installed version in your project.

```bash
# Step 1: Clone the module repo to a separate directory (one-time setup)
cd ~/Sites
git clone git@git.drupal.org:project/module_name.git module_name-contrib

# Step 2: Checkout the exact version you have installed
cd ~/Sites/module_name-contrib
git checkout 1.0.3  # Match your installed version

# Step 3: Make your changes in the contrib repo
# Edit files as needed...

# Step 4: Generate the patch using git diff
git diff > ~/Sites/your-project/patches/module_name-custom-fix.patch

# Step 5: Add to composer.json
{
  "extra": {
    "patches": {
      "drupal/module_name": {
        "Custom fix description": "patches/module_name-custom-fix.patch"
      }
    }
  }
}

# Step 6: Apply via composer
composer reinstall drupal/module_name
```

**Why use a separate repo?**
- Creates clean patches without local modifications bleeding in
- Matches the exact file structure composer expects
- Allows proper version tracking with git tags
- Enables contributing patches upstream to drupal.org

**Patch format**: Patches should use git diff format (includes `a/` and `b/` prefixes):
```
diff --git a/src/File.php b/src/File.php
index abc123..def456 100644
--- a/src/File.php
+++ b/src/File.php
```

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

### Step 1: Analyze Readiness

```bash
# Scan all modules
drush upgrade_status:analyze --all

# Scan specific modules
drush upgrade_status:analyze module1 module2 module3

# Machine-readable output
drush upgrade_status:analyze --all --format=json > d11-report.json
drush upgrade_status:analyze --all --format=codeclimate > d11-report-ci.json

# Scan only custom code
drush upgrade_status:analyze --all --ignore-contrib

# Scan only contrib
drush upgrade_status:analyze --all --ignore-custom
```

### Step 2: Identify Issues

**Major Issues** (blocking):
- `REQUEST_TIME` constant → Use `\Drupal::time()->getRequestTime()`
- `user_roles()` → Use `\Drupal\user\Entity\Role::loadMultiple()`
- `file_validate_extensions()` → Use `file.validator` service
- `system_retrieve_file()` → No replacement (refactor required)
- `_drupal_flush_css_js()` → Use `AssetQueryStringInterface::reset()`

**Info.yml Issues**:
- Update `core_version_requirement` to include `^11`
- Example: `core_version_requirement: ^9 || ^10 || ^11`

### Step 3: Fix Custom Code

**Example: Inject Time Service**

```php
use Drupal\Core\Datetime\TimeInterface;

class MyController extends ControllerBase {
  protected $time;

  public function __construct(TimeInterface $time) {
    $this->time = $time;
  }

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('datetime.time')
    );
  }

  public function myMethod() {
    // OLD: $timestamp = REQUEST_TIME;
    $timestamp = $this->time->getRequestTime();
  }
}
```

**Example: Replace user_roles()**

```php
// OLD:
$roles = user_roles(TRUE);

// NEW:
use Drupal\user\Entity\Role;

$roles = Role::loadMultiple();
$role_options = [];
foreach ($roles as $role_id => $role) {
  if ($role_id !== 'anonymous') {
    $role_options[$role_id] = $role->label();
  }
}
```

### Step 4: Create .info.yml Patches

```bash
# Create patch for contrib module
cd docroot/modules/contrib/module_name
git diff module.info.yml > /path/to/patches/module-d11-info.patch

# Patch content:
--- a/module.info.yml
+++ b/module.info.yml
@@ -2,7 +2,7 @@
 name: Module Name
 type: module
 description: Module description
-core_version_requirement: ^9 || ^10
+core_version_requirement: ^9 || ^10 || ^11
```

### Step 5: Apply Patches & Update Lenient List

```json
{
  "extra": {
    "patches": {
      "drupal/module_name": {
        "Drupal 11 .info.yml support": "patches/module-d11-info.patch"
      }
    },
    "drupal-lenient": {
      "allowed-list": [
        "drupal/module_name"
      ]
    }
  }
}
```

```bash
composer install
drush updb -y
drush cr
```

### Step 6: Verify Fixes

```bash
# Re-scan to confirm issues resolved
drush upgrade_status:analyze module_name

# Should show "No known issues found"
```

## Complete Update Checklist

- [ ] Check current module version: `composer show drupal/module_name`
- [ ] Search issue queue for known issues
- [ ] Check if module is D11 compatible
- [ ] Update composer.json with new version
- [ ] Add to drupal-lenient if needed
- [ ] Search for and apply necessary patches
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

When deploying to production environments, always optimize the Composer install:

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

# 3. Commit the optimized vendor files
git add composer.json composer.lock vendor/
git commit -m "Update module_name with production optimization"

# 4. Push to production
git push origin master

# 5. On production, clear caches
ssh user@remote.server "cd /path/to/drupal && drush cr"
```

**NEVER commit vendor/ with dev dependencies to production branches!**

## Developing Contrib Modules Locally

When actively developing a contrib module for drupal.org, use this workflow to avoid constantly updating via composer:

### Symlink Development Workflow

```bash
# 1. Set up module repository in temp location
cd /tmp
git clone git@git.drupal.org:project/module_name.git
cd module_name
# Make your changes...

# 2. Remove composer-installed version and symlink your dev copy
cd /path/to/project
rm -rf docroot/modules/contrib/module_name
ln -s /tmp/module_name docroot/modules/contrib/module_name

# 3. Develop and test
# Make changes in /tmp/module_name
# Test immediately in your Drupal site
drush cr  # Clear cache as needed

# 4. When ready to publish
cd /tmp/module_name
git add -A
git commit -m "Your changes"
git push origin 1.0.x

# 5. Clean up: remove symlink and reinstall from composer
cd /path/to/project
rm docroot/modules/contrib/module_name
composer install  # Reinstalls from drupal.org
```

**Benefits**:
- Test changes immediately without composer update cycles
- Keep git history in the module's own repo
- Easy to commit and push changes
- No risk of accidentally committing module code to main project

**Important Notes**:
- Don't forget to remove the symlink before committing project changes
- Clear Drupal cache after changes: `drush cr`
- When done developing, always reinstall via composer to ensure clean state
- Useful for fixing autoloader issues, adding features, or troubleshooting

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

## Contributing Back to drupal.org

When you've developed a fix or feature that should be contributed upstream, use the issue fork workflow.

### Step 1: Create Issue on drupal.org

1. Go to `https://www.drupal.org/project/issues/MODULE_NAME`
2. Click "Create a new issue"
3. Fill in:
   - **Title**: Descriptive title of the feature/fix
   - **Category**: Bug report, Feature request, or Task
   - **Priority**: Normal (unless exceptional)
4. Note the issue number (e.g., 3569725)

### Issue Description Format

Use the standard drupal.org template with HTML formatting:

```html
<h3 id="overview">Overview</h3>

<p>Problem description here.</p>
<ul>
<li>Bullet point one</li>
<li>Bullet point two</li>
</ul>

<h3 id="proposed-resolution">Proposed resolution</h3>

<p><strong>Behavior:</strong></p>
<ul>
<li>Feature behavior one</li>
<li>Feature behavior two</li>
</ul>

<p><strong>Technical implementation:</strong></p>
<ul>
<li><code>SomeClass</code> - description</li>
<li><code>some_function()</code> - description</li>
</ul>

<p><strong>Files changed:</strong></p>
<ul>
<li><code>path/to/file.php</code> - Description of changes</li>
</ul>

<h3 id="ui-changes">User interface changes</h3>

<p>Description of UI changes (or "None" if no UI changes).</p>

<h3 id="steps-to-test">Steps to test</h3>

<ol>
<li>First step</li>
<li>Second step</li>
<li>Expected result</li>
</ol>
```

**Formatting reference**: https://www.drupal.org/filter/tips
- `<code>...</code>` for inline code
- `<strong>...</strong>` for bold
- `<ul><li>...</li></ul>` for unordered lists
- `<ol><li>...</li></ol>` for ordered lists
- `<h3 id="section-name">...</h3>` for section headers
- `<p>...</p>` for paragraphs

### Step 2: Create Issue Fork on drupal.org

1. On the issue page, click "Create issue fork"
2. Copy the Git commands provided

### Step 3: Clone Module and Set Up Fork

```bash
# Clone the module repo (if not already cloned)
cd ~/Sites
git clone git@git.drupal.org:project/module_name.git module_name-contrib
cd module_name-contrib

# Add the issue fork as a remote (replace XXXXXXX with issue number)
git remote add module_name-XXXXXXX git@git.drupal.org:issue/module_name-XXXXXXX.git
git fetch module_name-XXXXXXX

# Checkout the issue branch
git checkout -b 'XXXXXXX-short-description' --track module_name-XXXXXXX/'XXXXXXX-short-description'
```

### Step 4: Make Changes and Test

```bash
# Make your changes
# For PHP modules, ensure code follows Drupal coding standards
# For modules with JS/UI, run linting and build

# Test your changes locally
```

### Step 5: Commit and Push

```bash
# Stage changed files
git add path/to/changed/files

# Commit with proper message format
git commit -m "$(cat <<'EOF'
Issue #XXXXXXX: Short description

- Bullet point of change 1
- Bullet point of change 2
- Bullet point of change 3
EOF
)"

# Push to issue fork
git push module_name-XXXXXXX XXXXXXX-short-description
```

### Step 6: Create Merge Request

After pushing, you'll see a URL in the output:
```
remote: To create a merge request for XXXXXXX-short-description, visit:
remote:   https://git.drupalcode.org/issue/module_name-XXXXXXX/-/merge_requests/new?merge_request%5Bsource_branch%5D=XXXXXXX-short-description
```

1. Visit that URL to create the merge request
2. Return to the issue page on drupal.org
3. Set issue status to "Needs review"

### Commit Message Format

Drupal.org standard format:
```
Issue #XXXXXXX: Short description (50 chars max)

- Detail about what changed
- Another detail
- Technical implementation note
```

### Two-Repository Workflow

When contributing to a module you also use in your project:

1. **Contrib Repo** (`~/Sites/module-contrib/`) - Clean checkout for developing and contributing
2. **App Repo** (`~/Sites/your-app/`) - Uses composer patches to apply changes

**Benefits**:
- Clean separation between contribution work and app usage
- Patches can be applied/removed easily via Composer
- App stays functional while iterating on the feature

**Workflow**:
```bash
# 1. Develop in contrib repo
cd ~/Sites/module-contrib
# Make changes...

# 2. Generate patch
git diff > feature-name.patch

# 3. Copy to app and apply via composer
cp feature-name.patch ~/Sites/your-app/patches/
# Add to composer.json patches section
cd ~/Sites/your-app
composer reinstall drupal/module_name

# 4. Test in app, iterate as needed

# 5. When ready, commit and push from contrib repo
cd ~/Sites/module-contrib
git add -A && git commit -m "Issue #XXXXXXX: Description"
git push fork-remote branch-name
```

### Using Remote Patches (After MR Created)

Once a merge request exists, you can use the remote diff URL:

```json
{
  "extra": {
    "patches": {
      "drupal/module_name": {
        "Feature (https://www.drupal.org/project/module_name/issues/XXXXXXX)": "https://git.drupalcode.org/project/module_name/-/merge_requests/XXX.diff"
      }
    }
  }
}
```

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
