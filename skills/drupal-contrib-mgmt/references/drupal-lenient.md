# Validating drupal-lenient Requirements

**CRITICAL**: When auditing modules in the `drupal-lenient` allowed-list, you MUST check UPSTREAM package requirements, NOT local patched versions.

## Correct Method to Check Upstream D11 Support

1. **Check Packagist/Drupal.org directly** - Not local files which may be patched
2. **Use `composer show drupal/MODULE --all`** - Shows all available versions
3. **Fetch package composer.json from drupal.org** - `https://git.drupalcode.org/project/MODULE/-/raw/HEAD/composer.json`

## Example: Checking if a Module Needs drupal-lenient

```bash
# WRONG - checks patched local version
grep core_version_requirement docroot/modules/contrib/MODULE/MODULE.info.yml

# WRONG - affected by drupal-lenient plugin
composer info drupal/MODULE | grep "drupal/core"

# CORRECT METHOD 1 - use composer prohibits to test D11 compatibility
composer prohibits drupal/core-recommended 11.2.5 --no-plugins
# Shows which packages prevent installing D11.2.5

# CORRECT METHOD 2 - check all available versions
composer show drupal/MODULE --all --no-plugins | head -30
# Look for "requires" section to see drupal/core constraints

# CORRECT METHOD 3 - fetch specific version's composer.json from upstream
curl -s https://git.drupalcode.org/project/MODULE/-/raw/8.x-VERSION/composer.json | grep -A 2 drupal/core
```

## When to Use drupal-lenient

A module should ONLY be in the `drupal-lenient` allowed-list if:
- The upstream package's `composer.json` requires `drupal/core` with constraints that EXCLUDE D11 (e.g., `^8 || ^9 || ^10`)
- You are patching it to add D11 support via `.info.yml` patch

**IMPORTANT**: drupal-lenient only affects `composer.json` constraints. If a module doesn't declare `drupal/core` in its `composer.json` at all, drupal-lenient does nothing and the module should NOT be in the allowed-list (even if the `.info.yml` has restrictions).

## When NOT to Use drupal-lenient

Remove from allowed-list if:
- Upstream already supports D11 in `composer.json` (e.g., `^10 || ^11`)
- Upstream has D11 support in `.info.yml` but NO `drupal/core` constraint in `composer.json` (e.g., s3fs 8.x-3.9)
- A new version with native D11 support is available
- You've contributed a patch that was merged upstream

## Checking BOTH composer.json AND .info.yml

Some modules (like s3fs) declare D11 compatibility ONLY in `.info.yml`, not in `composer.json`. For these modules:

```bash
# Check composer.json for drupal/core requirement
curl -s https://git.drupalcode.org/project/s3fs/-/raw/8.x-3.9/composer.json | grep "drupal/core"
# Returns: (nothing) - NO drupal/core constraint

# Check .info.yml for core_version_requirement
curl -s https://git.drupalcode.org/project/s3fs/-/raw/8.x-3.9/s3fs.info.yml | grep core_version_requirement
# Returns: core_version_requirement: ">=8.8 < 10.6 || >=11.0 < 11.2 || ~11.2.3"
```

Result: s3fs has D11 support and NO composer.json constraint, so it should NOT be in drupal-lenient.
