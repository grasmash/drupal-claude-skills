---
name: drupal-config-mgmt
description: Guides Drupal configuration management safely - single-config export/set/delete, config:import and config:export (cim/cex) with preview-first --no --diff, config:status checks, Config Split (complete vs partial splits, csex/csim, activation), and syncing config from remote environments through Terminus, acli, platform/upsun, lagoon or drush aliases. Use when exporting or importing Drupal config, inspecting or changing a single config object, merging production config into a feature branch, working with config_split, or diagnosing config that will not import or vanishes from config/default on export.
---

# Drupal Configuration Management

Comprehensive guide for Drupal configuration management including imports, exports, config splits, and environment syncing.

## Remote CLI — host-neutral

Examples below use Pantheon's **Terminus** (`terminus drush <site>.<env> -- <cmd>`). The commands are identical on any host — substitute your platform's remote-drush form. If your platform provides Drush site aliases, the generic `drush @<alias> <cmd>` works everywhere.

| Task | Acquia (`acli`) | Pantheon (Terminus) | Platform.sh / Upsun | Lagoon (amazee.io) | Generic (Drush aliases) |
|---|---|---|---|---|---|
| Remote drush | `acli remote:drush -- <cmd>` | `terminus drush <site>.<env> -- <cmd>` | `platform drush -e <env> -- <cmd>` (Upsun: `upsun drush …`) | `lagoon ssh -p <project> -e <env> -C "drush <cmd>"` | `drush @<alias> <cmd>` |
| Get/inspect config | `acli remote:drush -- config:get <name>` | `terminus drush <site>.<env> -- config:get <name>` | `platform drush -e <env> -- config:get <name>` | `lagoon ssh -p <project> -e <env> -C "drush config:get <name>"` | `drush @<alias> config:get <name>` |

> **The auto-confirm warning below applies to every host** — append `--no` to `cim`/`config:import` to preview instead of apply. Drush defaults to `--yes` when invoked non-interactively (which all remote-CLI wrappers do).

## Problem: Avoid Accidental Config Imports

**CRITICAL**: Terminus drush commands default to `--yes` unless explicitly told `--no`. This means commands like `config:import` or `cim` will AUTO-CONFIRM and import configuration even when you only want to inspect differences.

### Dangerous vs Safe Patterns

❌ **DANGEROUS** - Auto-imports without confirmation:
```bash
terminus drush {site}.{env} -- cim --diff  # DON'T DO THIS!
```

✅ **SAFE** - Shows diff without importing:
```bash
terminus drush {site}.{env} -- cim --no --diff
```

✅ **SAFEST** - Read-only commands:
```bash
terminus drush {site}.{env} -- config:get config.name
terminus drush {site}.{env} -- config:status
```

## Table of Contents

1. [Preferred Prod Config Merge Workflow](references/prod-config-merge.md#preferred-prod-config-merge-workflow)
2. [Configuration Import & Export Basics](#configuration-import--export-basics)
3. [Config Splits Overview](references/config-splits.md#config-splits-overview)
4. [Complete vs Partial Splits](references/config-splits.md#complete-vs-partial-splits)
5. [Config Split Commands](#config-split-commands)
6. [Safe Inspection Workflow](#safe-inspection-workflow)
7. [Syncing Config from Upstream Environments](#syncing-config-from-upstream-environments)

---

## Configuration Import & Export Basics

### Exporting Configuration

**Export ALL configuration** (from active config to YAML files):
```bash
# Local
ddev drush config:export
ddev drush cex

# Remote
terminus drush {site}.{env} -- config:export
```

**Export a SINGLE config object**:
```bash
# Get config and save to file
ddev drush config:get config.name --format=yaml > config/default/config.name.yml

# Example: Export a specific view
ddev drush config:get views.view.content --format=yaml > config/default/views.view.content.yml
```

### Importing Configuration

**Import ALL configuration** (from YAML files to active config):
```bash
# Local
ddev drush config:import
ddev drush cim

# Remote (DANGEROUS - auto-confirms with terminus!)
terminus drush {site}.{env} -- config:import --no  # Use --no to preview only
```

**Import a SINGLE config object**:
```bash
# Delete from active config first, then import
ddev drush config:delete config.name
ddev drush config:import --partial --source=config/default

# Or use config:set for specific values
ddev drush config:set config.name key.subkey value
```

**Best Practice**: Always preview changes first:
```bash
ddev drush config:import --no --diff  # Show what would change
ddev drush cim --no --diff            # Alias
```

---

## Config Split Commands

### CRITICAL: Active vs Exported Configuration

**⚠️ IMPORTANT**: When updating config split definitions, changes must be in **ACTIVE configuration** (database), not just exported files!

**Workflow**:
1. Edit `config/default/config_split.config_split.{name}.yml`
2. **Import to make active**: `ddev drush config:import --partial` OR use PHP (see below)
3. Export: `ddev drush cex`

**Quick method - Set active config via PHP**:
```bash
ddev drush php:eval "\$config = \Drupal::configFactory()->getEditable('config_split.config_split.local'); \$config->set('partial_list', ['config.name']); \$config->save();"
```

See [examples.md](references/examples.md#updating-config-split-definitions) for detailed workflow.

### Export Config with Splits

**Export ALL config including active splits**:
```bash
ddev drush config:export
```

This exports:
- Base config to `config/default/`
- Active split config to `config/{split-name}/`

**Export a specific split**:
```bash
ddev drush config-split:export {split-name}
ddev drush csex {split-name}
```

### Import Config with Splits

**Import ALL config including active splits**:
```bash
ddev drush config:import
ddev drush cim
```

This imports:
- Base config from `config/default/`
- Active split config from `config/{split-name}/`

**Import a specific split**:
```bash
ddev drush config-split:import {split-name}
ddev drush csim {split-name}
```

**Import only base config (ignore splits)**:
```bash
ddev drush config:import --skip-modules=config_split
```

### Activate/Deactivate Splits

**Activate a split**:
```bash
ddev drush config-split:activate {split-name}
```

**Deactivate a split**:
```bash
ddev drush config-split:deactivate {split-name}
```

### Check Split Status

**List all splits and their status**:
```bash
ddev drush config-split:status
ddev drush css
```

**Example output**:
```
Split       Active  Configuration directory
local       Yes     ../config/local
dev         No      ../config/dev
test        No      ../config/test
```

---

## Safe Inspection Workflow

Use `config:get` and `config:status` for read-only inspection, or use `--no` flag with `cim`/`cex` to prevent auto-confirmation.

### Get Config Values

```bash
# Get full config object
terminus drush {site}.{env} -- config:get config.name

# Get as YAML
terminus drush {site}.{env} -- config:get config.name --format=yaml

# Extract specific values
terminus drush {site}.{env} -- config:get config.name 2>&1 | grep "setting_name"
```

### Compare Local vs Remote

```bash
# View diffs without importing (SAFE with --no)
terminus drush {site}.{env} -- cim --no --diff

# Get remote and compare manually
terminus drush {site}.{env} -- config:get config.name --format=yaml > /tmp/remote.yml
diff -u config/default/config.name.yml /tmp/remote.yml
```

**CRITICAL**: Always use `--no` flag with terminus! Without it, commands auto-confirm.

### Apply Changes

**Preferred**: Edit config files directly, then commit:
```bash
# Use Edit tool on config/default/config.name.yml
git diff config/default/config.name.yml
git add config/default/config.name.yml
git commit -m "Update config from {env}"
```

---

## Syncing Config from Upstream Environments

### Quick Methods

**Single config object**:
```bash
terminus drush {site}.{env} -- config:get config.name --format=yaml > config/default/config.name.yml
git add config/default/config.name.yml && git commit -m "Update from {env}"
ddev drush config:import --partial
```

**Full config sync via rsync**:

> **Caution:** a remote `cex` writes every drifted config object on that environment, and a local `cim` imports (and deletes) everything that differs. Never run a blanket export/import against a shared or remote environment as a casual step — prefer the single-config method above, and review the full diff before anything is imported. See [surgical-config.md](references/surgical-config.md).

```bash
terminus drush {site}.{env} -- cex
terminus rsync {site}.{env}:code/config/default /tmp/remote
diff -r config/default /tmp/remote  # Review
cp /tmp/remote/*.yml config/default/
git add config/default/ && git commit -m "Sync from {env}"
ddev drush cim
```

**Via database pull** (DDEV + Pantheon):
```bash
ddev pull pantheon --environment={env}  # Warning: Overwrites local DB!
ddev drush cex
git diff config/ && git add config/ && git commit -m "Config from {env}"
```

See [examples.md](references/examples.md) for detailed workflows.

**Best practices**: Review diffs, commit separately, test locally, document source, avoid syncing environment-specific config.

---

## Deep Dive References

For comprehensive technical documentation, see:
- **[config-split-deep-dive.md](references/config-split-deep-dive.md)** - Complete technical reference on Config Split 2.0, patch files, export/import process, and dependency handling
- **[surgical-config.md](references/surgical-config.md)** - One-config-at-a-time export/set/delete for agents, the `core.extension.yml` exception, raw config writes that drop `dependencies`, baked (PHP-computed) config, and verifying imports with `config:status`
- [examples.md](references/examples.md) - Practical examples and workflows

## References

| File | Read it when |
|---|---|
| [references/surgical-config.md](references/surgical-config.md) | Before any config change an agent makes: exporting, setting or deleting ONE named config object, the `core.extension.yml` exception, raw config writes that drop `dependencies`, baked (PHP-computed) config, verifying an import with `config:status`, shipping a config-only change |
| [references/prod-config-merge.md](references/prod-config-merge.md) | Merging production config changes into a branch that carries local feature config (pull prod DB, export, restore your deleted/overwritten files) |
| [references/config-splits.md](references/config-splits.md) | Deciding whether to use a split, or choosing between a Complete and a Partial split |
| [references/config-split-deep-dive.md](references/config-split-deep-dive.md) | You need the Config Split 2.0 internals: patch files, file naming, the export/import process, dependency handling, and worked local-vs-remote Solr examples (including a complete-split server with auto-generated index patches) |
| [references/examples.md](references/examples.md) | You want worked examples: syncing one config from dev, syncing Search API config, comparing environments, updating split definitions |

## Config Status Check

Check what config would be imported (read-only):

```bash
# Local environment
ddev drush config:status

# Remote environment
terminus drush {site}.{env} -- config:status
```

## Best Practices

1. **Always inspect before importing** - Use `config:get` and `--no --diff` flags
2. **Manual edits preferred** - Edit config files directly for precision
3. **One config type per commit** - Separate concerns for clean history
4. **Clear commit messages** - Reference source environment
5. **Clean up temp files** - Remove temporary YAML files
6. **Verify before committing** - Always review `git diff` output
7. **Test locally first** - Import and test before deploying
8. **Use config splits** - Keep environment-specific config separate

---

## Troubleshooting

### Config files deleted from working directory

If files are marked as deleted in `git status`:
```bash
git checkout HEAD -- config/default/*.yml
```

This can happen if a drush command runs unexpectedly.

### Split not activating

Check split status:
```bash
ddev drush config-split:status
```

Manually activate:
```bash
ddev drush config-split:activate {split-name}
ddev drush cex  # Export to save activation state
```

### Config deleted from config/default on export

**COMMON ISSUE**: Config (like `search_api.server.my_search_server`) gets removed from `config/default/` when you run `drush cex`.

**Root cause (99% of cases)**: Config is in `complete_list` instead of `partial_list`!

**Complete split** = Config is REMOVED from `config/default/` and moved to split directory entirely
**Partial split** = Config STAYS in `config/default/`, only differences are patched

**Diagnosis**:
```bash
# Check if config is in complete_list (will be deleted from config/default)
grep -A10 "complete_list:" config/default/config_split.config_split.local.yml

# Check if config is in partial_list (will stay in config/default)
grep -A10 "partial_list:" config/default/config_split.config_split.local.yml
```

**Solution**: Move from `complete_list` to `partial_list`

```bash
# Edit the split definition
# Move: search_api.server.my_search_server
# FROM: complete_list
# TO: partial_list

ddev drush cex  # Re-export
# Check that config/default/search_api.server.my_search_server.yml exists
# Check that config/local/config_split.patch.search_api.server.my_search_server.yml exists
```

See [config-split-deep-dive.md](references/config-split-deep-dive.md) for complete technical explanation.

### Config won't import

Common issues:
- **Dependencies missing**: Install required modules first
- **UUID mismatch**: Use `--partial` flag
- **Locked config**: Some config (like system.site) has immutable values

```bash
# Skip specific config during import
ddev drush config:import --skip-config=system.site
```

## Related Commands

**Read-only**: `config:get`, `config:status`
**Exports**: `config:export` (alias: `cex`)
**Imports**: `config:import` (alias: `cim`) - Use with `--no --diff` to preview
**Splits**: `config-split:status`, `csex`, `csim`, `config-split:activate`
