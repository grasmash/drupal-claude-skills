# Developing and Contributing Contrib Modules

Local development of a contrib module and the drupal.org issue-fork workflow for contributing fixes upstream.

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

**Example**: Fixing an autoloader issue in example_module
```bash
# Module needed composer.json autoload section
cd /tmp/example_module
# Edit composer.json to add autoload section
git commit -m "Add PSR-4 autoload configuration"
git push origin 1.0.x

# Back in main project
rm docroot/modules/contrib/example_module
composer install  # Gets latest with fix
drush cr
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
# Clone the module repo (if not already cloned), outside the project
cd <workspace-dir>
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

1. **Contrib Repo** (`<workspace-dir>/module-contrib/`) - Clean checkout for developing and contributing
2. **App Repo** (`<project-root>/`) - Uses composer patches to apply changes

**Benefits**:
- Clean separation between contribution work and app usage
- Patches can be applied/removed easily via Composer
- App stays functional while iterating on the feature

**Workflow**:
```bash
# 1. Develop in contrib repo
cd <workspace-dir>/module-contrib
# Make changes...

# 2. Generate patch
git diff > feature-name.patch

# 3. Copy to app and apply via composer
cp feature-name.patch <project-root>/patches/
# Add to composer.json patches section
cd <project-root>
composer patches-relock   # composer-patches v2 applies from patches.lock.json
composer reinstall drupal/module_name

# 4. Test in app, iterate as needed

# 5. When ready, commit and push from contrib repo
cd <workspace-dir>/module-contrib
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
