---
description: Drupal Canvas SDC (Single Directory Components) with Twig templates. Use when creating, modifying, or troubleshooting Twig-based Canvas components in themes/modules, component.yml schemas, Canvas preview issues, or page builder functionality. For React/JSX Code Components, see drupal-canvas-code-components skill. (project)
globs:
  - "**/components/**/*.component.yml"
  - "**/components/**/*.twig"
  - "**/components/**/README.md"
  - "docroot/themes/custom/*/components/**/*"
  - "docroot/modules/custom/*/components/**/*"
triggers:
  - canvas sdc
  - sdc
  - single directory component
  - component.yml
  - twig component
  - twig template
  - component library
  - props and slots
  - component version
  - canvas versioning
  - outdated instances
  - upgrade instances
  - active_version
  - canvas dev mode
  - canvas vite
  - canvas audit
  - component audit
  - canvas migration
  - canvas api
alwaysApply: false
---

# Drupal Canvas SDC Components (Twig)

## Overview

**Drupal Canvas 1.0** (released December 2025) is a React-based visual page builder powered by Single Directory Components (SDC). Canvas consolidates three component types:
- **SDC components** from themes/modules
- **Code Components** written in-browser with React/JSX
- **Traditional Drupal Blocks**

Canvas becomes the default page builder in Drupal CMS 2.0 (January 2026).

## Installation

```bash
composer require 'drupal/canvas:^1.0'
drush en canvas -y
```

**Requirements**: Drupal ^11.2

## Component Discovery

SDC components live in a `components/` directory within any theme or module. Drupal scans enabled themes/modules for directories containing a `.component.yml` file.

**Component ID pattern**: `{provider}:{component-name}` (e.g., `mytheme:hero-banner`)

**Management UI**: Appearance > Components (`/admin/appearance/component`)

## SDC File Structure

Every SDC requires exactly two files. CSS/JS with matching names auto-attach.

```
theme_name/
└── components/
    ├── atoms/
    │   └── button/
    │       ├── button.component.yml   # REQUIRED
    │       ├── button.twig            # REQUIRED
    │       ├── button.css             # Auto-attached
    │       └── button.js              # Auto-attached
    └── molecules/
        └── card/
            ├── card.component.yml
            ├── card.twig
            ├── card.css
            └── thumbnail.png          # Optional preview
```

**Naming Rules**:
- Use **kebab-case** for directories and files
- All files share the same base name as the directory
- Templates use `.twig` extension (NOT `.html.twig`)
- Organizational folders (`atoms/`, `molecules/`) don't affect component IDs

## component.yml Schema

```yaml
$schema: https://git.drupalcode.org/project/drupal/-/raw/HEAD/core/assets/schemas/v1/metadata.schema.json
name: Hero Banner
description: Full-width hero with image background and CTA
status: stable  # experimental, stable, deprecated, obsolete
group: Content

props:
  type: object
  required:
    - heading
  properties:
    heading:
      type: string
      title: Heading
      examples: ['Welcome to our site']  # REQUIRED for Canvas preview
    background_image:
      type: object
      $ref: json-schema-definitions://canvas.module/image
    cta_text:
      type: string
      title: Button Text
      default: Learn More
    size:
      type: string
      title: Size
      enum: ['small', 'medium', 'large']
      default: medium
      meta:enum:
        small: "Compact"
        medium: "Standard"
        large: "Full Screen"

slots:
  content:
    title: Body Content
    description: Main content area below the heading

libraryOverrides:
  dependencies:
    - core/drupal
    - core/once
```

**CRITICAL**: The `examples` key is **required for Canvas** to display helpful placeholders.

## Prop Types and Canvas Widgets

| Schema Definition | Canvas Widget | Use Case |
|-------------------|---------------|----------|
| `type: string` | Text input | Simple text |
| `type: string` + `contentMediaType: text/html` | CKEditor 5 | Rich text |
| `type: boolean` | Checkbox | Toggle options |
| `type: integer` with `minimum`/`maximum` | Number input | Numeric values |
| `type: string` + `enum: [...]` | Dropdown | Preset options |
| `$ref: json-schema-definitions://canvas.module/image` | Media library | Image picker |
| `type: array` with `items:` | List input | Multiple values |

### Rich Text Props

```yaml
content:
  type: string
  title: Rich Text Content
  contentMediaType: text/html
  x-formatting-context: block  # or 'inline'
  examples: ['<p>Formatted <strong>content</strong></p>']
```

### Enum Labels (Human-Readable Dropdowns)

```yaml
color:
  type: string
  enum: ['primary', 'secondary', 'danger']
  meta:enum:
    primary: "Primary Brand Color"
    secondary: "Secondary Accent"
    danger: "Warning/Error State"
```

## Validation Patterns

### Required Properties

```yaml
props:
  type: object
  required:
    - title
    - url
  properties:
    title:
      type: string
```

### Numeric Constraints

```yaml
spacing:
  type: integer
  minimum: 0
  maximum: 100

heading_level:
  type: integer
  enum: [2, 3, 4, 5, 6]
```

### Nullable Values

```yaml
subtitle:
  type: ['string', 'null']
  title: Optional Subtitle
```

### Array Constraints

```yaml
tags:
  type: array
  items:
    type: string
  minItems: 1
  maxItems: 5
```

### Default Values in Twig

**IMPORTANT**: Schema `default` values are documentation only. Always use `|default()` in Twig:

```twig
{% set heading_level = heading_level|default(2) %}
{% set color = color|default('primary') %}
```

## Slots for Composition

Slots accept arbitrary markup or nested components. Props handle typed data; slots handle content.

### Define Slots

```yaml
slots:
  header:
    title: Header Content
    description: Optional header area
  body:
    title: Body Content
  footer: {}  # Minimal definition
```

### Render Slots in Twig

```twig
<article class="card">
  {% if header %}
    <header class="card__header">{{ header }}</header>
  {% endif %}
  <div class="card__body">{{ body }}</div>
  {% if footer %}
    <footer class="card__footer">{{ footer }}</footer>
  {% endif %}
</article>
```

### Populate Slots with Embed

```twig
{% embed 'my_theme:card' with { heading: 'Featured Article' } only %}
  {% block body %}
    {{ content.field_image }}
    <p>{{ content.field_summary }}</p>
    {{ include('my_theme:button', { text: 'Read More', url: url }) }}
  {% endblock %}
{% endembed %}
```

### Populate Slots from PHP

```php
$build = [
  '#type' => 'component',
  '#component' => 'my_theme:card',
  '#props' => ['heading' => $title],
  '#slots' => [
    'body' => ['#markup' => $content],
    'footer' => $footer_render_array,
  ],
];
```

## Atomic Design Principles

- **Atoms**: Buttons, icons, labels, form inputs
- **Molecules**: Cards, media objects, search forms
- **Organisms**: Headers, footers, article teasers
- **Templates**: Page layouts with slots for organisms

### Single Responsibility Pattern

```yaml
# ✅ Good: Single component with variants
name: Button
props:
  type: object
  properties:
    variant:
      type: string
      enum: ['primary', 'secondary', 'outline', 'ghost']
    size:
      type: string
      enum: ['small', 'medium', 'large']
```

```yaml
# ❌ Avoid: Separate components per variant
# button-primary.component.yml
# button-secondary.component.yml
```

## CSS Styling with BEM

**Component-Scoped CSS (CRITICAL)**: NEVER scope styles to route/path body classes (e.g., `.alias--masterclasses`, `.path-some-page`). Instead, scope styles to the component's own classes (e.g., `.view-masterclasses`, `.block-views-blockmasterclasses-block-2`). The Canvas editor renders page previews in an iframe without the page's body classes, so route-scoped styles won't appear there. All styles must be componentized and portable -- they should look correct regardless of what route or context they render in.

SDC auto-attaches CSS when file matches component name. Use BEM for scoped styles:

```css
/* card.css */
.card {
  --card-padding: 1.5rem;
  --card-radius: 0.5rem;
  --card-shadow: 0 2px 8px rgba(0,0,0,0.1);

  display: flex;
  flex-direction: column;
  padding: var(--card-padding);
  border-radius: var(--card-radius);
  box-shadow: var(--card-shadow);
}

.card__header {
  margin-bottom: 1rem;
  font-weight: 700;
}

.card__body {
  flex: 1;
}

.card--featured {
  --card-shadow: 0 4px 16px rgba(0,0,0,0.15);
  border: 2px solid var(--color-primary);
}

.card--compact {
  --card-padding: 1rem;
}
```

### External Dependencies

```yaml
libraryOverrides:
  css:
    component:
      card.css: {}
      additional-styles.css: {}
  dependencies:
    - core/normalize
```

## JavaScript Behaviors

Use Drupal's behavior pattern with `once()`:

```javascript
// accordion.js
((Drupal, once) => {
  Drupal.behaviors.accordion = {
    attach(context) {
      once('accordion', '.accordion__trigger', context).forEach((trigger) => {
        trigger.addEventListener('click', (e) => {
          const panel = document.getElementById(trigger.getAttribute('aria-controls'));
          const expanded = trigger.getAttribute('aria-expanded') === 'true';

          trigger.setAttribute('aria-expanded', !expanded);
          panel.hidden = expanded;
        });
      });
    },
    detach(context, settings, trigger) {
      if (trigger === 'unload') {
        once.remove('accordion', '.accordion__trigger', context);
      }
    }
  };
})(Drupal, once);
```

**Key Patterns**:
- `once()` prevents duplicate event binding
- `context` scopes to newly added DOM
- `attach()` runs on page load and AJAX updates
- `detach()` handles cleanup

## Accessibility (WCAG 2.2 AA)

### Semantic HTML First

```twig
<nav aria-label="Main navigation">
  <ul>
    <li><a href="{{ url }}">{{ label }}</a></li>
  </ul>
</nav>

{# Accessible button with states #}
<button
  type="button"
  aria-expanded="{{ expanded ? 'true' : 'false' }}"
  aria-controls="panel-{{ id }}"
>
  {{ trigger_text }}
</button>

{# Modal dialog #}
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="dialog-title-{{ id }}"
>
  <h2 id="dialog-title-{{ id }}">{{ title }}</h2>
  {{ content }}
</div>

{# Live region for dynamic updates #}
<div aria-live="polite" class="visually-hidden">
  {{ status_message }}
</div>
```

### Keyboard Navigation Checklist

- All interactive elements focusable via Tab
- Visible focus indicators (never `outline: none` without alternative)
- Enter/Space activate buttons and links
- Escape closes modals and dropdowns
- Arrow keys navigate within composite widgets

### Dynamic Announcements

```javascript
Drupal.announce('Form submitted successfully');
Drupal.announce('Error: Please fix the highlighted fields', 'assertive');
```

## Canvas Preview for Traditional Blocks

**CRITICAL**: Canvas renders block previews in iframes that only include CSS from explicitly attached libraries.

### Problem

Traditional Drupal blocks relying on theme global SCSS won't show styles in Canvas previews.

### Solution Pattern

1. **Create standalone CSS file** in module's `css/` directory
2. **Add library** to module's `.libraries.yml`
3. **Attach library** via `#attached` in block's `build()` method

```php
// In BlockClass.php build() method
public function build() {
  return [
    '#theme' => 'my_block_template',
    '#variables' => $variables,
    '#attached' => [
      'library' => [
        'my_module/my_block_styles',
      ],
    ],
  ];
}
```

```yaml
# my_module.libraries.yml
my_block_styles:
  version: VERSION
  css:
    theme:
      css/my-block.css: {}
```

### CSS Compilation for Standalone Files

When extracting from theme SCSS, compile variables to hardcoded values:

```css
/* Compiled from SCSS - replace variables */
.my-component {
  max-width: 1440px;  /* was $max-content-width */
  color: #7d11ff;     /* was $primary-color */
}
```

### Blocks That Return Empty

Blocks returning empty arrays `[]` won't preview in Canvas. Always render the template structure:

```php
public function build() {
  // Always return template for Canvas preview support
  return [
    '#theme' => 'my_block_template',
    '#content' => $content ?? NULL,
    '#attached' => [
      'library' => ['my_module/my_block'],
    ],
    '#cache' => ['contexts' => ['user']],
  ];
}
```

## SDC vs Traditional Blocks Comparison

| Feature | SDC Component | Traditional Block |
|---------|---------------|-------------------|
| CSS Loading | Auto-attached | Must use `#attached` |
| Canvas Preview | Automatic with `examples` | Requires explicit library |
| Props/Config | JSON Schema in YAML | Block configuration form |
| Template | `.twig` (no `.html.twig`) | `.html.twig` |
| Location | `components/` directory | `src/Plugin/Block/` |
| Reusability | High (theme-agnostic) | Module-specific |

## Testing SDC Components

### PHPUnit Kernel Tests

```php
namespace Drupal\Tests\my_module\Kernel;

use Drupal\KernelTests\KernelTestBase;

class CardComponentTest extends KernelTestBase {
  protected static $modules = ['system', 'sdc'];

  public function testCardRendering() {
    $build = [
      '#type' => 'component',
      '#component' => 'my_theme:card',
      '#props' => ['heading' => 'Test'],
    ];
    $output = \Drupal::service('renderer')->renderRoot($build);
    $this->assertStringContainsString('Test', (string) $output);
  }
}
```

### Storybook Integration

```javascript
// card.stories.js
export default {
  title: 'Molecules/Card',
  component: 'my_theme:card',
};

export const Default = {
  args: {
    heading: 'Card Title',
    body: '<p>Card content goes here</p>',
  },
};

export const Featured = {
  args: {
    heading: 'Featured Card',
    variant: 'featured',
  },
};
```

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
| `canvas_dev_mode` | **Keep enabled locally** | Local only, NEVER production | Always during development. Unlocks experimental APIs and extensions toolbar. |
| `canvas_vite` | **Keep disabled** | Local only when needed | ONLY when developing the Canvas editor UI itself (the React app). Requires Vite dev server running. Causes `ERR_CONNECTION_REFUSED` errors if Vite is not running. |
| `canvas_ai` | Hidden/internal | Per-environment | AI-assisted page building. Enable if using Canvas AI features. |
| `canvas_oauth` | As needed | Production + local | Only if external apps need authenticated Canvas API access. |
| `canvas_styling_traits` | **Enabled** | All environments | Provides shared styling schema definitions (`spacing-padding`, etc.) for components. Note: has a known non-fatal `#/$defs/spacing-padding` schema error on `drush cr` that doesn't affect functionality. |

**`canvas_dev_mode`** details:
- Removes `Choice` constraint on ComponentSource plugins, allowing unstable plugin types
- Shows the extensions toolbar in the Canvas editor UI
- Enable: `ddev drush en canvas_dev_mode -y`

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

## Canvas Component Versioning (CRITICAL)

**Understanding component versioning is essential when modifying SDC components.**

### How Versioning Works

Canvas uses a **version-pinning system** for backward compatibility:

1. Each component has an `active_version` (an xxh64 hash)
2. Component instances are **pinned to the version they were created with**
3. When you add/change props, Canvas creates a new `active_version`
4. **Existing instances stay on their old version** - they won't show new fields

### The Problem

When you add a new prop to a component (e.g., adding `gap` to `section`):
- **New** component instances will have the new field
- **Existing** instances created before the change **will NOT show the new field**

This is intentional - Canvas preserves backward compatibility so existing pages don't break.

### Solution: Migrate Instances to Active Version

**IMPORTANT**: After modifying component props, always run the upgrade command to migrate existing instances.

Use the custom drush commands to upgrade existing instances:

```bash
# List components with outdated instances
ddev drush canvas:upgrade-instances

# Preview what would be migrated (dry run)
ddev drush canvas:upgrade-instances sdc.mytheme.section --dry-run

# Migrate a specific component's instances
ddev drush canvas:upgrade-instances sdc.mytheme.section

# Migrate ALL outdated instances at once
ddev drush canvas:upgrade-instances --all

# Show detailed version info for a component
ddev drush canvas:component-info sdc.mytheme.section
```

### Development Workflow for Component Prop Changes

When modifying SDC component props during development:

1. **Modify the component** (`component.yml`, `.twig`, `.css`)
2. **Clear cache**: `ddev drush cr`
3. **Check for outdated instances**: `ddev drush canvas:upgrade-instances`
4. **Migrate if needed**: `ddev drush canvas:upgrade-instances <component_id>`

### canvas_styling_traits Schema Changes

When modifying `canvas_styling_traits/schema.json` (adding/removing/renaming enum values):

1. **Update schema.json** with new enum values
2. **Clear cache**: `ddev drush cr`
3. **Upgrade instances**: `ddev drush canvas:upgrade-instances --all -y`

**CRITICAL**: If you **remove** an enum value (e.g., removing "none" from spacing enums), existing component instances that have that value stored will fail validation at render time with `Does not have a value in the enumeration`. You must also clean the stored data. The `canvas:upgrade-instances` command migrates instances to the new component version but does NOT update stored field values that are no longer valid.

To fix invalid stored values, use a drush script or `hook_update_N()`:
```php
$database = \Drupal::database();
$tables = ['canvas_page__components', 'canvas_page_revision__components'];
foreach ($tables as $table) {
  $results = $database->select($table, 'c')
    ->fields('c')
    ->condition('c.components_component_id', 'sdc.mytheme.page-header')
    ->execute();
  foreach ($results as $row) {
    $inputs = json_decode($row->components_inputs, TRUE);
    $changed = FALSE;
    foreach (['margin_top', 'margin_bottom'] as $field) {
      if (isset($inputs[$field]) && $inputs[$field] === 'none') {
        unset($inputs[$field]); // Or set to a valid value
        $changed = TRUE;
      }
    }
    if ($changed) {
      $database->update($table)
        ->fields(['components_inputs' => json_encode($inputs)])
        ->condition('entity_id', $row->entity_id)
        ->condition('revision_id', $row->revision_id)
        ->condition('delta', $row->delta)
        ->execute();
    }
  }
}
\Drupal::cache('entity')->deleteAll();
\Drupal::cache('render')->deleteAll();
```

**Summary of enum semantics for styling traits:**
- **"- None -"** (Drupal's built-in for non-required `list_string`) = unset, no CSS class applied, element keeps its default styling
- **"zero"** (explicit enum value) = `margin: 0` / `padding: 0`, actively removes spacing via CSS class `cst-mt-zero` etc.

### Production Deployment Workflow

For production deployments where you change component props:
- Write a `hook_update_N()` to migrate instances (see `my_module_update_9015` for example)
- Or run `drush canvas:upgrade-instances --all` as part of deployment scripts

### Canvas Config Entity Structure

Component config entities store versions in `config/default/canvas.component.*.yml`:

```yaml
active_version: c533daa1ccfd0fba  # Current version hash
versioned_properties:
  active:
    settings:
      prop_field_definitions:
        gap:  # New prop - only in active version
          field_type: list_string
          # ...
  2076209c0228c2bb:  # Old version - no gap prop
    settings:
      prop_field_definitions:
        # ...
```

### Instance Storage

Component instances live in the `canvas_page__components` table:
- `components_component_id` - which component (e.g., `sdc.mytheme.section`)
- `components_component_version` - pinned version hash
- `components_inputs` - JSON blob of prop values
- `components_uuid` - unique instance identifier
- Revision data in `canvas_page_revision__components`

## Drush Commands

```bash
# Clear cache after component changes
ddev drush cr

# List all SDC components
ddev drush ev "print_r(array_keys(\Drupal::service('plugin.manager.sdc')->getDefinitions()));"

# Canvas component version management (your project custom)
ddev drush canvas:upgrade-instances          # List outdated
ddev drush canvas:upgrade-instances --all    # Migrate all
ddev drush canvas:component-info             # Show all components
ddev drush canvas:component-info <id>        # Show specific component
```

## Troubleshooting: Component Version Mismatches (500 Errors)

### Symptom

Canvas editor throws 500: `'propName' is not a prop on this version of the Component 'Code component: ComponentName'`

### Root Cause

The Canvas component entity's `active_version` was generated from an older build of the component that didn't include the prop. The source `component.yml` has the prop, but the deployed Canvas entity doesn't.

**Key distinction by component type:**
- **SDC components** (`sdc.*`): Canvas regenerates versions on `drush cr` from the source `component.yml`
- **JS code components** (`js.*`): Canvas versions are set when the component is **uploaded** via CLI. `drush cr` alone does NOT update them.

### Recovery Steps

#### For JS Code Components (`js.*`)

```bash
# 1. Re-upload the component to generate a new version from source component.yml
npx canvas upload --components container -y

# 2. Upgrade existing instances to the new active version
ddev drush canvas:upgrade-instances js.container -y

# 3. Verify
ddev drush canvas:component-info js.container
```

The upload command is configured via `.env` in the canvas-components project:
- `CANVAS_SITE_URL=http://example.ddev.site`
- `CANVAS_CLIENT_ID=canvas_cli`
- `CANVAS_CLIENT_SECRET=canvas_cli_secret`

#### For SDC Components (`sdc.*`)

```bash
# 1. Clear cache to trigger re-discovery from source
ddev drush cr

# 2. Upgrade existing instances
ddev drush canvas:upgrade-instances sdc.mytheme.component-name -y

# 3. Export updated config entity
ddev drush cex -y
```

### Diagnosis Commands

```bash
# Check what props the active version has
ddev drush ev "\$c = \Drupal::entityTypeManager()->getStorage('component')->load('js.container'); echo implode(', ', array_keys(\$c->get('versioned_properties')['active']['settings']['prop_field_definitions'] ?? []));"

# Check what version/inputs an instance has on a specific page
ddev drush ev "\$p = \Drupal::entityTypeManager()->getStorage('canvas_page')->load(6); foreach (\$p->toArray()['components'] ?? [] as \$c) { if (\$c['component_id'] === 'js.container') echo \$c['component_version'] . ': ' . \$c['inputs']; }"

# Compare: does the instance version match the active version?
ddev drush canvas:upgrade-instances  # Lists all mismatches
```

### Stale Auto-Saves

Canvas auto-saves can reference old component versions. If a 500 persists after upgrading instances, check for and delete stale auto-saves:

```bash
# Check pending auto-saves
curl -s -b /tmp/cookies.txt "https://example.ddev.site/canvas/api/v0/auto-saves/pending"

# Delete a stale auto-save (need CSRF token)
CSRF=$(curl -s -b /tmp/cookies.txt "https://example.ddev.site/session/token")
curl -s -b /tmp/cookies.txt -X DELETE -H "X-CSRF-Token: $CSRF" \
  "https://example.ddev.site/canvas/api/v0/auto-saves/canvas_page/{PAGE_ID}"
```

### Prevention

After modifying any component's `component.yml` props:
1. **JS components**: `npx canvas upload --components <name> -y`
2. **SDC components**: `ddev drush cr`
3. **Always**: `ddev drush canvas:upgrade-instances` to check for stale instances
4. **Always**: Test the Canvas editor page before pushing

## Resources

- Canvas project: https://www.drupal.org/project/canvas
- Canvas docs: https://project.pages.drupalcode.org/canvas/
- SDC docs: https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components
- Canvas SDC Starterkit: https://www.drupal.org/project/canvas_sdc_starterkit
- SDC Examples: https://www.drupal.org/project/sdc_examples

## Apply to Files

- `**/components/**/*.component.yml`
- `**/components/**/*.twig`
- `**/components/**/*.css`
- `**/components/**/*.js`
- `docroot/themes/custom/mytheme/components/**/*`
- `docroot/modules/custom/*/components/**/*`
