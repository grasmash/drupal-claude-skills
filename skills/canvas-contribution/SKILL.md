---
description: Canvas contribution workflow for contributing features/fixes back to drupal.org. Use when developing features for Canvas module that will be contributed upstream. Covers two-repository workflow, issue forks, merge requests, and composer patches.
globs:
  - "patches/canvas-*.patch"
  - "**/Sites/canvas-contrib/**/*"
triggers:
  - contribute to canvas
  - canvas contribution
  - canvas patch
  - canvas issue
  - canvas merge request
  - drupal.org canvas
  - canvas fork
  - upstream canvas
alwaysApply: false
---

# Canvas Contribution Workflow

This skill extends the general `drupal-contrib-mgmt` skill with Canvas-specific details.

For the general drupal.org contribution workflow (issue creation, issue forks, commit format, HTML formatting), see the **drupal-contrib-mgmt** skill.

## Canvas-Specific Setup

### Repository Structure

- **Canvas Contrib Repo**: `~/Sites/canvas-contrib/`
- **GG App Repo**: `~/Sites/myproject/`

### Initial Clone (One-Time)

```bash
cd ~/Sites
git clone git@git.drupal.org:project/canvas.git canvas-contrib
```

## Canvas UI Development

Canvas has a React-based UI that requires building.

### Build Commands

```bash
cd ~/Sites/canvas-contrib/ui
npm install
npm run lint    # Check for lint errors
npm run lint -- --fix  # Auto-fix lint errors
npm run build   # Build for production
```

### After Applying Patches in GG

```bash
cd ~/Sites/myproject
composer reinstall drupal/canvas
cd docroot/modules/contrib/canvas/ui && npm run build
ddev drush cr
```

## Canvas Issue Fork Example

Using issue #3569725 as an example:

```bash
cd ~/Sites/canvas-contrib

# Add fork remote
git remote add canvas-3569725 git@git.drupal.org:issue/canvas-3569725.git
git fetch canvas-3569725

# Checkout issue branch
git checkout -b '3569725-auto-scale-to-fit' --track canvas-3569725/'3569725-auto-scale-to-fit'

# Make changes, then commit
git add ui/src/path/to/files
git commit -m "$(cat <<'EOF'
Issue #3569725: Add auto scale-to-fit feature

- Feature detail 1
- Feature detail 2
EOF
)"

# Push
git push canvas-3569725 3569725-auto-scale-to-fit
```

## Key Canvas Files

| Area | Location |
|------|----------|
| UI source | `ui/src/` |
| UI components | `ui/src/features/` |
| CSS modules | `ui/src/**/*.module.css` |
| PHP module | `src/` |
| Tests | `tests/` |

## Canvas Project Links

- **Project**: https://www.drupal.org/project/canvas
- **Issue Queue**: https://www.drupal.org/project/issues/canvas
- **Documentation**: https://project.pages.drupalcode.org/canvas/
