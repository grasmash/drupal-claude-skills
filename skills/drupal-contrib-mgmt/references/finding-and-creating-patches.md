# Finding and Creating Patches

Search the issue queue for an existing patch before creating one; when none exists, create it from a clean clone.

## Debugging Errors: Find Patches BEFORE Creating

**CRITICAL WORKFLOW**: When encountering Drupal errors, ALWAYS search for existing patches before creating your own.

### Step 1: Extract the Exact Error Signature

From the error message, extract the **exact** error string:

```bash
# Example error:
TypeError: Unsupported operand types: array + null in Drupal\field_ui\Form\EntityViewDisplayEditForm

# Extract this part:
"Unsupported operand types: array + null"
```

### Step 2: Search Drupal.org Issue Queue FIRST

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

### Step 3: Use WebFetch to Get Patch Details

```bash
# Once you find the issue, fetch details:
WebFetch(https://www.drupal.org/project/drupal/issues/3552531)
```

Look for:
- **Patch file URLs**: Usually `https://www.drupal.org/files/issues/YYYY-MM-DD/filename.patch`
- **Merge request numbers**: E.g., `!13611` → `https://git.drupalcode.org/project/drupal/-/merge_requests/13611`
- **Issue status**: RTBC means ready to use

### Step 4: Download and Apply Official Patch

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

### Common Search Patterns

| Error Type | Search Term |
|------------|-------------|
| TypeError | Exact error message in quotes |
| Deprecated function | Function name (e.g., `user_roles`) |
| Missing method | Class name + method name |
| Fatal error | Exact error text |

### Why This Matters

- **Saves time**: Don't recreate existing solutions
- **Better quality**: Community-reviewed patches are more robust
- **Upstream integration**: Using official patches means easier upgrades
- **Documentation**: Issue threads contain context and discussion

### Anti-Pattern Example

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

## Creating Local Patches

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
