# Drupal 11 Compatibility: Checking and Upgrading

How to tell whether a module supports Drupal 11, and the upgrade_status workflow for fixing what it does not.

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
