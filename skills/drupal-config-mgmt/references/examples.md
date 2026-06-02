# Drupal Config Management Examples

Practical examples for common configuration management scenarios.

## Table of Contents

1. [Syncing CTA Messaging from Dev](#syncing-cta-messaging-from-dev)
2. [Syncing Search API Config](#syncing-search-api-config)
3. [Comparing Environments](#comparing-environments)
4. [Updating Config Split Definitions](#updating-config-split-definitions)

---

## Syncing CTA Messaging from Dev

```bash
# 1. Get current values from dev
echo "=== DEV: block.block.mytheme_parallaxheroblock ===" && \
  terminus drush mysite.dev -- config:get block.block.mytheme_parallaxheroblock 2>&1 | grep -A2 "cta_text\|cta_url"

echo "=== DEV: my_module.stats_hero ===" && \
  terminus drush mysite.dev -- config:get my_module.stats_hero 2>&1 | grep "cta_text\|cta_url"

echo "=== DEV: my_module.myfeature ===" && \
  terminus drush mysite.dev -- config:get my_module.myfeature 2>&1 | grep "membership_text\|button_text"

# 2. Get current local values
echo "=== LOCAL: block.block.mytheme_parallaxheroblock ===" && \
  grep -A2 "cta_text:" config/default/block.block.mytheme_parallaxheroblock.yml

echo "=== LOCAL: my_module.stats_hero ===" && \
  grep "cta_text\|cta_url" config/default/my_module.stats_hero.yml

echo "=== LOCAL: my_module.myfeature ===" && \
  grep "membership_text\|button_text" config/default/my_module.myfeature.yml

# 3. Manually edit files using Edit tool to match dev values

# 4. Review and commit changes
git diff config/default/block.block.mytheme_parallaxheroblock.yml \
  config/default/my_module.stats_hero.yml \
  config/default/my_module.myfeature.yml

git add config/default/*.yml
git commit -m "Update CTA messaging from dev environment"
```

---

## Syncing Search API Config

```bash
# 1. Export full config from remote
terminus drush mysite.test -- config:get search_api.server.pantheon_search --format=yaml > /tmp/server.yml
terminus drush mysite.test -- config:get search_api.index.mobile_content --format=yaml > /tmp/index.yml

# 2. Copy to local config
cp /tmp/server.yml config/default/search_api.server.pantheon_search.yml
cp /tmp/index.yml config/default/search_api.index.mobile_content.yml

# 3. If server was renamed, remove old config
git rm config/default/search_api.server.old_name.yml

# 4. Review and commit
git diff config/default/search_api.*
git add config/default/search_api.*
git commit -m "Update Search API config from test environment"

# 5. Clean up temp files
rm -f /tmp/*.yml
```

---

## Comparing Environments

```bash
# Get same config from different environments
terminus drush mysite.dev -- config:get config.name > /tmp/dev.yml
terminus drush mysite.test -- config:get config.name > /tmp/test.yml
terminus drush mysite.live -- config:get config.name > /tmp/live.yml

# Compare
diff -u /tmp/dev.yml /tmp/test.yml
diff -u /tmp/test.yml /tmp/live.yml
```

---

## Updating Config Split Definitions

**CRITICAL**: Config split definitions must be in **ACTIVE configuration** (database), not just exported files!

### The Workflow

When you edit a config split definition:

1. **Edit the file**: `config/default/config_split.config_split.{name}.yml`
2. **Import to active config**: Make the change active in the database
3. **Export**: Run `drush cex` to apply the new split behavior

**Why this matters**: Config Split reads from active configuration when exporting, so file edits alone won't work!

### Method 1: Import the Change

```bash
# After editing config/default/config_split.config_split.local.yml
ddev drush config:import --partial --source=config/default

# Or import specific config
ddev drush config:set config_split.config_split.local complete_list []
ddev drush config:set config_split.config_split.local partial_list ['search_api.server.pantheon_search']
```

### Method 2: Set Active Config Directly via PHP

**Use this if import has issues**:

```bash
ddev drush php:eval "
  \$config = \Drupal::configFactory()->getEditable('config_split.config_split.local');
  \$config->set('complete_list', []);
  \$config->set('partial_list', ['search_api.server.pantheon_search']);
  \$config->save();
  echo 'Updated active config';
"

# Verify
ddev drush config:get config_split.config_split.local complete_list
ddev drush config:get config_split.config_split.local partial_list

# Export to apply new split behavior
ddev drush cex
```

---

## Examples of Split Definition Updates

When you need to add or remove config from a split:

### Add Module to Split (Complete Split)

```bash
# 1. Edit split config file
# Example: Add webprofiler to local split
# Edit: config/default/config_split.config_split.local.yml

module:
  devel: 0
  kint: 0
  webprofiler: 0  # Add this line

# 2. Export config to update split directory
ddev drush config:export

# 3. Enable the module (if complete split and split is active)
ddev drush pm:enable webprofiler

# 4. Export again to capture module config
ddev drush config:export

# 5. Commit changes
git add config/
git commit -m "Add webprofiler to local split"
```

### Add Config Override to Split (Partial Split)

```bash
# 1. Create override file in split directory
# Example: Override search server for local environment

# Copy base config
cp config/default/search_api.server.main.yml \
   config/local/config_split.patch.search_api.server.main.yml

# 2. Edit the override file with local-specific settings
# Use Edit tool to modify config/local/config_split.patch.search_api.server.main.yml

# 3. Update split config to reference it
# Edit: config/default/config_split.config_split.local.yml

partial_list:
  - search_api.server.main

# 4. Export and commit
ddev drush config:export
git add config/
git commit -m "Add local search server override to local split"
```

### Remove Config from Split

```bash
# 1. Edit split definition to remove config
# Edit: config/default/config_split.config_split.{name}.yml

# Remove from module:, complete_list:, or partial_list:

# 2. Delete config from split directory if present
rm config/{split-name}/config.name.yml

# 3. Export to update
ddev drush config:export

# 4. Commit
git add config/
git commit -m "Remove config.name from {split-name} split"
```

### Change Split from Complete to Partial (or vice versa)

```bash
# Example: Change from complete to partial

# 1. Edit split definition
# Edit: config/default/config_split.config_split.{name}.yml

# Move from complete_list to partial_list:
complete_list:
  # - search_api.server.main  # Remove from here

partial_list:
  - search_api.server.main    # Add here

# 2. Create override file in split directory
cp config/default/search_api.server.main.yml \
   config/{split-name}/config_split.patch.search_api.server.main.yml

# 3. Edit override with environment-specific settings

# 4. Export and commit
ddev drush config:export
git add config/
git commit -m "Convert search_api.server.main to partial split"
```
