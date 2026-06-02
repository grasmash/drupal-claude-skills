# Config Split Deep Dive - Complete Technical Reference

Comprehensive technical documentation on Drupal Config Split 2.0 based on deep research and real-world analysis.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Complete vs Partial Splits - The Full Truth](#complete-vs-partial-splits---the-full-truth)
3. [File Naming Conventions](#file-naming-conventions)
4. [How Patch Files Work](#how-patch-files-work)
5. [Export Process Deep Dive](#export-process-deep-dive)
6. [Import Process Deep Dive](#import-process-deep-dive)
7. [Real-World Example Analysis](#real-world-example-analysis)
8. [Your Specific Issue Explained](#your-specific-issue-explained)
9. [Best Practices](#best-practices)

---

## Core Concepts

### The Three Lists

Config Split 2.0 uses three internal lists to manage configuration:

1. **Complete List (Blacklist)**: Config that is COMPLETELY removed from `config/default/` and moved to split directory
2. **Partial List (Graylist)**: Config that stays in `config/default/` but has overrides in split directory as patches
3. **Dependency-Driven Patches**: Config that depends on complete-split items gets automatic patches

### Key Behavioral Difference from 1.x

**Config Split 1.x**: Used "conditional splits" that duplicated entire config files
**Config Split 2.x**: Uses "partial splits" with quasi-patch files that store only differences

**Why the change?** The patch infrastructure was needed for module uninstallation logic (#3170204), and the maintainer realized: "why don't we use it also for the other scenario where you want to split some things that are different."

---

## Complete vs Partial Splits - The Full Truth

### Complete Split (Blacklist)

**What happens:**
- Config is REMOVED from `config/default/`
- Full config file is saved to `config/{split-name}/`
- When split is inactive, config doesn't exist at all
- When split is active, config is loaded from split directory

**File in split directory:**
```
config/local/search_api.server.pantheon_search.yml  (full file)
```

**File in default:**
```
DELETED - file does not exist
```

**Use cases:**
- Development modules (devel, kint, webprofiler)
- Environment-specific modules (stage_file_proxy)
- UI modules in production (views_ui, field_ui disabled in prod)
- Modules that should ONLY exist in specific environments

**Quote from research:**
> "Complete split removes the configuration from the config/sync directory and places it only in the split directory."

### Partial Split (Graylist/Quasi-Patch)

**What happens:**
- Base config STAYS in `config/default/`
- Only DIFFERENCES are stored in `config/{split-name}/config_split.patch.{name}.yml`
- When split is inactive, base config is used
- When split is active, patch is applied to base config

**File in split directory:**
```yaml
# config/local/config_split.patch.search_api.index.mixed_entities.yml
adding:
  dependencies:
    config:
      - search_api.server.pantheon_search
  server: pantheon_search
removing:
  dependencies:
    module:
      - gg_search
  server: null
```

**File in default:**
```
config/default/search_api.index.mixed_entities.yml  (full base config)
```

**Use cases:**
- Different API endpoints per environment
- Different server URLs (local Solr vs Pantheon Search)
- Cache settings that differ per environment
- Any config that exists everywhere but with different VALUES

**Quote from research:**
> "Partial Split compares config against the sync storage but instead of splitting the whole config to the split storage only the difference is kept in the split storage as a quasi-config-patch."

---

## File Naming Conventions

### Complete Split Files

Format: `{config_name}.yml`

Examples:
- `search_api.server.pantheon_search.yml`
- `devel.settings.yml`
- `stage_file_proxy.settings.yml`

These are FULL config files, identical in structure to what would be in `config/default/`.

### Partial Split Patch Files

Format: `config_split.patch.{config_name}.yml`

Examples:
- `config_split.patch.search_api.index.mixed_entities.yml`
- `config_split.patch.node.type.article.yml`
- `config_split.patch.system.performance.yml`

**Critical detail**: The `config_split.patch.` prefix is how Config Split identifies these as patch files rather than complete configs.

---

## How Patch Files Work

### Patch File Structure

```yaml
adding:
  # Keys/values to ADD or OVERRIDE in the base config
  server: pantheon_search
  dependencies:
    config:
      - search_api.server.pantheon_search

removing:
  # Keys/values to REMOVE from the base config
  server: null  # Removes the key entirely
  dependencies:
    module:
      - gg_search  # Removes this module from dependency list
```

### Important Notes on Patch Semantics

**Confusing terminology**: The patch uses `adding` and `removing` from the EXPORT perspective, which is backwards from the IMPORT perspective.

From the issue queue (#3232667):
> "The config patch has keys 'added' and 'removed' which reflect what happened when the config was exported, but when reviewing exported config it can be confusing to read 'removed' for things the split is adding when imported."

**What this means:**
- `adding:` section = "I'm adding these changes TO the split" = These values will be IN the config when split is active
- `removing:` section = "I'm removing these from default" = These values will be REMOVED when split is active

### Patch Merging Process

1. **Base config** is loaded from `config/default/`
2. **Patch file** is loaded from `config/{split-name}/`
3. **Values in `adding:`** override or add to base config
4. **Values in `removing:`** are removed from base config
5. **Result** is the merged config that Drupal imports

**From research:**
> "On import the config from the split storage is merged and the quasi-patches applied before Drupal imports the config from the sync storage."

---

## Export Process Deep Dive

### When You Run `drush cex`

1. **Drupal exports active config** to memory
2. **Config Split processes each split** (in weight order)
3. **For each config in complete_list:**
   - Write full config to `config/{split-name}/{config}.yml`
   - DELETE from `config/default/{config}.yml`
4. **For each config in partial_list:**
   - Compare active config with `config/default/{config}.yml`
   - Calculate differences
   - Write patch to `config/{split-name}/config_split.patch.{config}.yml`
   - KEEP base config in `config/default/{config}.yml`
5. **For configs with dependencies on complete-split items:**
   - Automatically create patches to remove those dependencies
   - Example: If `search_api.server.pantheon_search` is complete-split, all indexes that reference it get automatic patches

### Dependency-Driven Automatic Patches

**This is crucial!** Config Split 2.0 automatically creates patches for configs that depend on completely-split items.

**Quote from research:**
> "In 2.x things that you list explicitly or things that would be deleted if you would uninstall a module you split will be split completely, the other config which depends on those will be changed to not depend on it any more and the change is saved as a config patch."

**Real example from your site:**

`search_api.server.pantheon_search` is in `complete_list`, so it's removed from `config/default/`.

All search indexes that reference this server automatically get patches:
```yaml
# config/local/config_split.patch.search_api.index.mixed_entities.yml
adding:
  server: pantheon_search  # Re-add the server reference when local split is active
  dependencies:
    config:
      - search_api.server.pantheon_search
removing:
  server: null  # Remove the server when not in local (because server doesn't exist)
```

---

## Import Process Deep Dive

### When You Run `drush cim`

1. **Load base config** from `config/default/`
2. **Process splits in REVERSE weight order** (opposite of export)
3. **For each active split:**
   - Load complete configs from `config/{split-name}/` and add to import
   - Load patch files from `config/{split-name}/config_split.patch.*`
   - Apply patches to modify base configs
4. **Merge all configs** (later splits override earlier ones if stackable)
5. **Drupal imports** the final merged configuration

**Quote from research:**
> "Splits are processed in reverse order for import than for export, so a later split would override a previous one for the complete split and would patch what the previous splits put in place."

---

## Real-World Example Analysis

### Your Current Setup

**Config Split Definition:**
```yaml
# config/default/config_split.config_split.local.yml
complete_list:
  - search_api.server.pantheon_search
partial_list: {}
```

**Files in `config/local/`:**
```
search_api.server.pantheon_search.yml (FULL FILE - complete split)
config_split.patch.search_api.index.mixed_entities.yml (PATCH - auto-generated dependency)
config_split.patch.search_api.index.mobile_content.yml (PATCH - auto-generated dependency)
config_split.patch.search_api.index.teleport_groups.yml (PATCH - auto-generated dependency)
config_split.patch.search_api.index.users.yml (PATCH - auto-generated dependency)
```

**What happens on export:**

1. `search_api.server.pantheon_search` is in `complete_list`
2. Export DELETES it from `config/default/`
3. Export saves full file to `config/local/`
4. All indexes that reference this server get automatic patches
5. Patches remove server reference from base config, add it back in patch

**What happens on import (with local split active):**

1. Load base search index configs from `config/default/` (these have `server: null` or no server)
2. Load `search_api.server.pantheon_search.yml` from `config/local/`
3. Apply patches to indexes:
   - Add `server: pantheon_search`
   - Add dependency on server
4. Result: Indexes use Pantheon Search server (from local split)

**What happens on import (with local split inactive):**

1. Load base search index configs from `config/default/`
2. No patches applied
3. Result: Indexes have no server configured (or use whatever is in base)

---

## Your Specific Issue Explained

### Why `search_api.server.pantheon_search` is being deleted

**Root cause**: It's in `complete_list`, not `partial_list`!

```yaml
complete_list:
  - search_api.server.pantheon_search  # ← HERE'S THE PROBLEM
partial_list: {}
```

**What you probably want**: Use a partial split so the base config stays in `config/default/`

### Solution Options

#### Option 1: Move to Partial Split (Recommended if you want base config to exist)

Edit `config/default/config_split.config_split.local.yml`:

```yaml
complete_list: {}
partial_list:
  - search_api.server.pantheon_search
```

Then:
1. `ddev drush cex`
2. Check that `config/default/search_api.server.pantheon_search.yml` exists (base config)
3. Check that `config/local/config_split.patch.search_api.server.pantheon_search.yml` exists (patch)

**Result**: Base Pantheon Search config stays in `config/default/`, local overrides are in patch file.

#### Option 2: Keep as Complete Split (Current behavior)

If you want `search_api.server.pantheon_search` to ONLY exist in local environment:

```yaml
complete_list:
  - search_api.server.pantheon_search  # Keep here
partial_list: {}
```

Then ensure you have a DIFFERENT server config for other environments.

**Result**: `config/default/` doesn't have pantheon_search server at all. It's local-only.

#### Option 3: Different Servers Per Environment

Create separate complete splits:
- Local: Uses `search_api.server.local_solr` (complete split in local)
- Dev/Test/Live: Uses `search_api.server.pantheon_search` (in config/default)

Then indexes would need patches to swap servers per environment.

---

## Best Practices

### When to Use Complete Split

✅ **Use complete_list for:**
- Modules that should ONLY exist in certain environments
- Features that are environment-exclusive (development tools, debugging)
- Configuration that would be meaningless in other environments

❌ **Don't use complete_list for:**
- Config that needs to exist everywhere but with different values
- Config that other non-split config depends on (creates complex patch chains)
- Shared services with environment-specific settings

### When to Use Partial Split

✅ **Use partial_list for:**
- Same feature, different settings (API URLs, credentials)
- Performance settings that vary by environment
- Server endpoints (local Solr vs Pantheon Search)
- Any config where base version is importable and functional

❌ **Don't use partial_list for:**
- Modules (use complete split)
- Configuration that shouldn't exist at all in some environments

### Avoiding Dependency Issues

**Problem**: Complete-split config creates automatic patches in dependent config.

**Solutions**:
1. **Minimize complete splits**: Only use for modules and truly exclusive config
2. **Use partial splits for services**: Keep base version in sync directory
3. **Review automatic patches**: Check `config_split.patch.*` files after export
4. **Document dependencies**: Comment why certain configs are split

### File Organization

**Recommended structure**:
```
config/
├── default/           # Base config for all environments
│   ├── search_api.index.*.yml  # Indexes (base versions)
│   └── search_api.server.pantheon_search.yml  # Server (base version)
├── local/            # Local development overrides
│   ├── devel.settings.yml  # Complete split (module)
│   ├── stage_file_proxy.settings.yml  # Complete split (module)
│   └── config_split.patch.search_api.server.pantheon_search.yml  # Partial split (override to local Solr)
└── prod/             # Production-specific
    └── system.performance.yml  # Complete split (aggressive caching)
```

---

## Key Takeaways

1. **Complete splits DELETE from config/default/** - Files move entirely to split directory
2. **Partial splits PATCH config/default/** - Base stays, patches store differences
3. **Patch files use `config_split.patch.` prefix** - This is how they're identified
4. **Dependencies create automatic patches** - Complete-split items trigger patches in dependent configs
5. **Patch semantics are confusing** - `adding` means "add to config when split active", `removing` means "remove when split active"
6. **Import order is reversed** - Splits process in reverse weight order on import vs export
7. **Your issue**: `search_api.server.pantheon_search` is in `complete_list` when you want it in `partial_list`

---

## Further Research References

- Issue #3215319: Transition from conditional to partial splits
- Issue #3117841: Conditionally-split config removed from sync directory
- Issue #3232667: Change keys of config patch for easier review
- Issue #3240272: Better support for multiple splits
- Config Split 2.0 uses "quasi-patch" format inspired by module uninstallation logic

---

**Last Updated**: 2024-11-17
**Config Split Version Analyzed**: 2.0.2
**Drupal Version**: 10.x/11.x compatible
