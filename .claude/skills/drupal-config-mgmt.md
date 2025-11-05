# Drupal Configuration Management

Safe patterns for inspecting and syncing Drupal configuration across environments without accidentally importing changes.

## Problem: Avoid Accidental Config Imports

**CRITICAL**: Terminus drush commands default to `--yes` unless explicitly told `--no`. This means commands like `config:import` or `cim` will AUTO-CONFIRM and import configuration even when you only want to inspect differences.

### Dangerous vs Safe Patterns

❌ **DANGEROUS** - Will auto-import without confirmation:
```bash
terminus drush {site}.{env} -- cim --diff
terminus drush {site}.{env} -- config:import --diff
terminus drush {site}.{env} -- cex --diff
```

✅ **SAFE** - Will show diff without importing:
```bash
terminus drush {site}.{env} -- cim --no --diff
terminus drush {site}.{env} -- config:import --no --diff
terminus drush {site}.{env} -- cex --no --diff
```

✅ **SAFEST** - Use read-only commands:
```bash
terminus drush {site}.{env} -- config:get config.name
terminus drush {site}.{env} -- config:status
```

## Safe Inspection Workflow

Use `config:get` and `config:status` for read-only inspection, or use `--no` flag with `cim`/`cex` to prevent auto-confirmation.

### 1. Get Specific Config Values from Remote Environment

```bash
# Get full config object
terminus drush {site}.{env} -- config:get config.name

# Get specific nested value
terminus drush {site}.{env} -- config:get config.name key.subkey

# Get as YAML for easy comparison
terminus drush {site}.{env} -- config:get config.name --format=yaml
```

### 2. Extract Specific Values from Config

```bash
# Use grep to find specific settings
terminus drush {site}.{env} -- config:get config.name 2>&1 | grep "setting_name"

# Extract CTA text from hero block
terminus drush guitargate8.dev -- config:get block.block.ggfresh_parallaxheroblock 2>&1 | grep -A2 "cta_text\|cta_url"
```

### 3. Compare Local vs Remote Config

#### Option A: View config export diff (safe with --no)

```bash
# View what would be exported from active config to files (read-only)
terminus drush {site}.{env} -- cex --no --diff

# View what would be imported from files to active config (read-only)
terminus drush {site}.{env} -- cim --no --diff
```

**CRITICAL**: Always include `--no` flag! Without it, terminus auto-confirms and will actually import/export.

#### Option B: Get specific config and compare manually

```bash
# Get remote config to temp file
terminus drush {site}.{env} -- config:get config.name --format=yaml > /tmp/remote_config.yml

# Compare with local
echo "=== LOCAL ===" && grep "setting" config/default/config.name.yml
echo "=== REMOTE ===" && grep "setting" /tmp/remote_config.yml

# Or use diff
diff -u config/default/config.name.yml /tmp/remote_config.yml
```

### 4. Apply Config Changes Manually

**Preferred method**: Use `Edit` tool to update config files directly, then commit.

```bash
# Read local config
cat config/default/config.name.yml

# Edit the file (use Edit tool)
# Then verify changes
git diff config/default/config.name.yml

# Commit changes
git add config/default/config.name.yml
git commit -m "Update config from {env} environment"
```

## Example: Syncing CTA Messaging from Dev

```bash
# 1. Get current values from dev
echo "=== DEV: block.block.ggfresh_parallaxheroblock ===" && \
  terminus drush guitargate8.dev -- config:get block.block.ggfresh_parallaxheroblock 2>&1 | grep -A2 "cta_text\|cta_url"

echo "=== DEV: gg_core.stats_hero ===" && \
  terminus drush guitargate8.dev -- config:get gg_core.stats_hero 2>&1 | grep "cta_text\|cta_url"

echo "=== DEV: gg_core.teleport ===" && \
  terminus drush guitargate8.dev -- config:get gg_core.teleport 2>&1 | grep "membership_text\|button_text"

# 2. Get current local values
echo "=== LOCAL: block.block.ggfresh_parallaxheroblock ===" && \
  grep -A2 "cta_text:" config/default/block.block.ggfresh_parallaxheroblock.yml

echo "=== LOCAL: gg_core.stats_hero ===" && \
  grep "cta_text\|cta_url" config/default/gg_core.stats_hero.yml

echo "=== LOCAL: gg_core.teleport ===" && \
  grep "membership_text\|button_text" config/default/gg_core.teleport.yml

# 3. Manually edit files using Edit tool to match dev values

# 4. Review and commit changes
git diff config/default/block.block.ggfresh_parallaxheroblock.yml \
  config/default/gg_core.stats_hero.yml \
  config/default/gg_core.teleport.yml

git add config/default/*.yml
git commit -m "Update CTA messaging from dev environment"
```

## Example: Syncing Search API Config

```bash
# 1. Export full config from remote
terminus drush guitargate8.test -- config:get search_api.server.pantheon_search --format=yaml > /tmp/server.yml
terminus drush guitargate8.test -- config:get search_api.index.mobile_content --format=yaml > /tmp/index.yml

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

## Config Status Check

Check what config would be imported (read-only):

```bash
# Local environment
ddev drush config:status

# Remote environment
terminus drush {site}.{env} -- config:status
```

## Common Config Patterns

### Hero/CTA Blocks
- `block.block.ggfresh_parallaxheroblock` - Main hero block
  - `settings.cta_text` - CTA button text
  - `settings.cta_url` - CTA button URL

### Custom GG Core Settings
- `gg_core.stats_hero` - Stats section hero
  - `cta_text` - CTA button text
  - `cta_url` - CTA button URL

- `gg_core.teleport` - Teleport section
  - `membership_text` - Membership status text
  - `button_text` - Button text

### Search API
- `search_api.server.{server_name}` - Search server config
- `search_api.index.{index_name}` - Search index config
  - `server` - References server machine name
  - `status` - true/false (enabled/disabled)

## Best Practices

1. **Always inspect before importing**: Use `config:get` to see what will change
2. **Manual edits preferred**: Edit config files directly with Edit tool for precision
3. **One config type per commit**: Separate search config changes from CTA changes, etc.
4. **Clear commit messages**: Reference which environment you're pulling from
5. **Clean up temp files**: Remove temporary YAML files after copying
6. **Verify after restore**: If files get deleted from working directory, restore from git:
   ```bash
   git checkout HEAD -- config/default/file.yml
   ```

## Troubleshooting

### Config files deleted from working directory

If you see files marked as deleted in `git status` that should exist:

```bash
# Restore from last commit
git checkout HEAD -- config/default/search_api.*.yml

# Verify files exist
ls -la config/default/search_api.*.yml
```

This can happen if a drush command or config import runs unexpectedly.

### Comparing environments

```bash
# Get same config from different environments
terminus drush guitargate8.dev -- config:get config.name > /tmp/dev.yml
terminus drush guitargate8.test -- config:get config.name > /tmp/test.yml
terminus drush guitargate8.live -- config:get config.name > /tmp/live.yml

# Compare
diff -u /tmp/dev.yml /tmp/test.yml
diff -u /tmp/test.yml /tmp/live.yml
```

## Related Commands

- `config:get` - Get a config object (read-only)
- `config:status` - Show config sync status (read-only)
- `config:export` - Export active config to files (writes files)
- `config:import` - Import config from files (DESTRUCTIVE - modifies database)
- `cex` - Alias for config:export
- `cim` - Alias for config:import (AVOID - use manual Edit instead)
