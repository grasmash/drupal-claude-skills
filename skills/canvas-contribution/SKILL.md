---
name: canvas-contribution
description: "Workflow for contributing features and fixes to the Drupal Canvas module on drupal.org while consuming it from a separate project: the two-repository setup, Canvas UI development, issue forks, merge requests, and composer patches. Use when developing a Canvas feature or bug fix intended for upstream, or when moving a local Canvas change onto a drupal.org issue. Extends drupal-contrib-mgmt with Canvas-specific details."
---

# Canvas Contribution Workflow

This skill extends the general `drupal-contrib-mgmt` skill with Canvas-specific details.

For the general drupal.org contribution workflow (issue creation, issue forks, commit format, HTML formatting), see the **drupal-contrib-mgmt** skill.

## Canvas-Specific Setup

### Repository Structure

- **Canvas clone**: `<canvas-clone>` — your clone of the Canvas project from git.drupal.org (for example `canvas-contrib/`)
- **Your app repo**: `<project-root>` — the Drupal project that consumes Canvas

### Initial Clone (One-Time)

```bash
git clone git@git.drupal.org:project/canvas.git <canvas-clone>
```

## Canvas UI Development

Canvas has a React-based UI that requires building.

### Build Commands

```bash
cd <canvas-clone>/ui
npm install
npm run lint    # Check for lint errors
npm run lint -- --fix  # Auto-fix lint errors
npm run build   # Build for production
```

### After Applying Patches in Your App

```bash
cd <project-root>
ddev composer reinstall drupal/canvas
cd <docroot>/modules/contrib/canvas/ui && npm run build
ddev drush cr
```

## Canvas Issue Fork Example

Using issue #3569725 as an example:

```bash
cd <canvas-clone>

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
