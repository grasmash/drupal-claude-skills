# Canvas API Stability, Dev Submodules, Admin UI, API Endpoints and Services

Canvas development and migration tooling: submodules, admin pages, JSON endpoints and PHP services.

## Contents

- [Canvas API Stability](#canvas-api-stability)
- [Canvas Development & Migration Tools](#canvas-development--migration-tools)

## Canvas API Stability

| Feature | Status |
|---------|--------|
| SDC component integration | **Stable** |
| Props and slots structure | **Stable** |
| Component discovery | **Stable** |
| Code Components (React/JSX) | **Stable** |
| Block integration | **Stable** |
| Content Templates | **Experimental** |
| AI Assistant | **Evolving** |
| ComponentSource plugin API | **In flux** |

## Canvas Development & Migration Tools

### Canvas Submodules

| Module | Status | Environment | When to Use |
|--------|--------|-------------|-------------|
| `canvas_dev_mode` | **Only when you need it** | Local only, NEVER production | When you need the experimental APIs or extensions toolbar. Production runs without it, so also check new SDCs with it uninstalled (see below). |
| `canvas_vite` | **Keep disabled** | Local only when needed | ONLY when developing the Canvas editor UI itself (the React app). Requires Vite dev server running. Causes `ERR_CONNECTION_REFUSED` errors if Vite is not running. |
| `canvas_ai` | Hidden/internal | Per-environment | AI-assisted page building. Enable if using Canvas AI features. |
| `canvas_oauth` | As needed | Production + local | Only if external apps need authenticated Canvas API access. |
| `canvas_styling_traits` | **Enabled** | All environments | Provides shared styling schema definitions (`spacing-padding`, etc.) for components. Note: has a known non-fatal `#/$defs/spacing-padding` schema error on `drush cr` that doesn't affect functionality. |

**`canvas_dev_mode`** details:
- Removes `Choice` constraint on ComponentSource plugins, allowing unstable plugin types
- Shows the extensions toolbar in the Canvas editor UI
- Enable: `ddev drush en canvas_dev_mode -y`
- **Check new SDCs without it.** Its only hook in the Canvas 1.7.1 source removes the `Choice` constraint on the component `source` key, so it is not known to change SDC registration. But production runs without it, and a production-only 5xx was once seen alongside missing prop titles (unexplained; see [references/registration-and-config.md](registration-and-config.md)). As cheap insurance, before shipping a new or changed SDC:
  ```bash
  ddev drush pm:uninstall canvas_dev_mode -y && ddev drush cr
  # render a page (or a test) that includes the component; it must not throw
  ddev drush en canvas_dev_mode -y   # re-enable afterwards if you use it
  ```

**`canvas_vite`** details:
- Connects to Vite dev server at `localhost:5173`
- Disables CSS/JS preprocessing so changes are instant (no cache clearing for CSS/JS)
- Injects React Refresh runtime for live component updates
- Set `VITE_SERVER_ORIGIN` env var to customize the Vite server URL
- Enable: `ddev drush en canvas_vite -y` then start Vite: `cd docroot/modules/contrib/canvas/ui && npm run dev`
- Disable when done: `ddev drush pm:uninstall canvas_vite -y`

### Canvas Admin UI Pages

Use these during migration and development:

| URL | Purpose |
|-----|---------|
| `/admin/appearance/component` | List all Canvas components |
| `/admin/appearance/component/status` | Component status dashboard (enabled/disabled, incompatibilities) |
| `/admin/appearance/component/{component}/audit` | **Audit page** - shows WHERE a component is used (pages, templates, patterns, regions) |
| `/admin/appearance/component/{component}/enable` | Enable a component |
| `/admin/appearance/component/{component}/disable` | Disable a component |
| `/admin/content/pages/add` | Add a new Canvas page |

The **audit page** is the most useful during migration - it shows every canvas page, content template, pattern, and region that uses a given component.

### Canvas API Endpoints (JSON)

Useful for scripting or programmatic migration:

```
GET /canvas/api/v0/usage/component                          # List all component usage (paginated)
GET /canvas/api/v0/usage/component/{component}              # Usage summary for one component
GET /canvas/api/v0/usage/component/{component}/details      # Detailed usage breakdown
GET /canvas/api/v0/config/{type}                            # List all components/content-templates/patterns
GET /canvas/api/v0/config/{type}/{id}                       # Get specific config entity
GET /canvas/api/v0/layout/{entity_type}/{entity}            # Get entity's component tree layout
GET /canvas/api/v0/auto-saves/pending                       # Get pending auto-saves
POST /canvas/api/v0/log-error                               # JS error logging from Canvas UI
```

### Canvas PHP Services (Dependency Injection)

Key services available for custom code:

| Service | Use Case |
|---------|----------|
| `Drupal\canvas\Audit\ComponentAudit` | Find all content/config using a component |
| `Drupal\canvas\ComponentSource\ComponentSourceManager` | Trigger component discovery/regeneration |
| `Drupal\canvas\Storage\ComponentTreeLoader` | Load component trees from entities |
| `Drupal\canvas\CanvasConfigUpdater` | Auto-migrate config structures |
| `Drupal\canvas\ComponentTreeInputExtractor` | Extract inputs from component trees |
| `Drupal\canvas\ShapeMatcher\PropSourceSuggester` | Shape matching for field-to-prop mapping |
| `logger.channel.canvas` | Canvas-specific logging |

### ComponentAudit Service (Migration Key Tool)

```php
$audit = \Drupal::service(Drupal\canvas\Audit\ComponentAudit::class);

// Find all content using a component
$audit->getContentRevisionsUsingComponent($component);

// Find config entities (templates, patterns, regions) using it
$audit->getConfigEntityDependenciesUsingComponent($component);

// Quick boolean check
$audit->hasUsages($component);
```
