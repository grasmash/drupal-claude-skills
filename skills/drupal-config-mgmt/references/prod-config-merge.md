# Preferred Prod Config Merge Workflow

Merging production config into a branch that carries local feature config, moved from SKILL.md.

## Preferred Prod Config Merge Workflow

**Purpose**: Safely merge production config changes while preserving local feature work.

### The Process

**Step 1: Commit local changes first**
```bash
git add config/default/your-new-field.yml docroot/modules/custom/your_module/your_module.module
git commit -m "feat: add new feature"
```

`docroot/` here is the web root; yours may be `web/` instead.

**Step 2: Pull production database**
```bash
ddev pull pantheon --environment=live
# Or your preferred method
```

**Step 3: Export config from prod DB**
```bash
ddev drush config:export -y
```

**Step 4: Review git diff on config directory**
```bash
git diff --stat config/           # Summary of changes
git status --short config/        # See added/modified/deleted
```

**Step 5: Identify files to revert vs keep**

Look for these patterns:
- **D (Deleted)** - Your new feature files deleted by prod export → **REVERT**
- **M (Modified)** - UUID changes from prod → **KEEP**
- **M (Modified)** - Actual prod config changes → **KEEP**
- **M (Modified)** - Local changes overwritten → **REVERT** (case by case)

**Step 6: Restore your local feature files**
```bash
# Restore deleted files (your new feature config)
git checkout HEAD -- config/default/field.storage.node.your_new_field.yml
git checkout HEAD -- config/default/field.field.node.bundle.your_new_field.yml

# Or restore specific modified files
git checkout HEAD -- config/default/some.config.yml
```

**Step 7: Verify and commit prod config**
```bash
git status --short config/        # Verify your files are restored
git diff config/                  # Review remaining prod changes
git add config/
git commit -m "chore: sync config from production"
```

### Quick Reference Table

| git status | Meaning | Action |
|------------|---------|--------|
| `D config/default/field.*.your_feature.yml` | Your new feature deleted | `git checkout HEAD -- <file>` |
| `M config/default/*.yml` (UUID only) | Prod UUID sync | Keep (stage for commit) |
| `M config/default/views.view.*.yml` | View changed in prod | Keep (review first) |
| `M config/default/system.*.yml` | System config from prod | Keep (review first) |

### Example Session

```bash
# After pulling prod DB and exporting config
$ git status --short config/
 M config/default/core.entity_view_display.node.article.teaser.yml
 M config/default/field.storage.group.field_member_count.yml
 D config/default/field.field.node.article.field_related_count.yml
 D config/default/field.storage.node.field_related_count.yml
 M config/default/views.view.articles.yml

# The D files are our new feature - restore them
$ git checkout HEAD -- config/default/field.field.node.article.field_related_count.yml \
                       config/default/field.storage.node.field_related_count.yml

# Verify
$ git status --short config/
 M config/default/core.entity_view_display.node.article.teaser.yml
 M config/default/field.storage.group.field_member_count.yml
 M config/default/views.view.articles.yml

# Our feature files are no longer in the diff - commit prod changes
$ git add config/ && git commit -m "chore: sync config from production"
```
