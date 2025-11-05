---
name: drupal-config-mgmt
description: Safe patterns for inspecting and syncing Drupal configuration across environments without accidentally importing changes. Critical for Terminus/Pantheon workflows.
---

# Drupal Configuration Management

Safe patterns for inspecting and syncing Drupal configuration across environments without accidentally importing changes.

## When This Skill Activates

Activates when working with Drupal configuration management including:
- Inspecting config differences between environments
- Syncing config from remote environments (Pantheon, Acquia, etc.)
- Using Terminus drush commands safely
- Avoiding accidental config imports
- Manual config editing workflows

---

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

---

## Available Topics

Full documentation available in references:

- @references/safe-inspection.md - Read-only config inspection patterns
- @references/terminus-patterns.md - Safe Terminus drush usage
- @references/manual-sync.md - Manual config editing workflow
- @references/examples.md - Common sync scenarios

---

## Quick Reference

### Get Config from Remote
```bash
terminus drush {site}.{env} -- config:get config.name --format=yaml
```

### Compare Environments
```bash
# View import diff (safe with --no)
terminus drush {site}.{env} -- cim --no --diff

# Get specific config for manual comparison
terminus drush {site}.{env} -- config:get config.name > /tmp/remote.yml
diff -u config/default/config.name.yml /tmp/remote.yml
```

### Manual Edit Workflow
1. Get remote config: `terminus drush {site}.{env} -- config:get config.name`
2. Edit local file with Edit tool
3. Review: `git diff config/default/config.name.yml`
4. Commit: `git add config/default/config.name.yml && git commit`

---

## Best Practices

1. **Always use `--no` flag** with cim/cex on Terminus
2. **Manual edits preferred** over automated imports
3. **One config type per commit** for clean history
4. **Clear commit messages** referencing source environment
5. **Clean up temp files** after comparison operations

---

**Last updated**: 2024-11-05
