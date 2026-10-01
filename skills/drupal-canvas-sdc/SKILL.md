---
name: drupal-canvas-sdc
description: Drupal Canvas SDC (Single Directory Components) with Twig templates. Use when creating, modifying, or troubleshooting Twig-based Canvas components in themes/modules, component.yml schemas, Canvas registration (props need title, required props need examples), canvas.component config entities, component versioning and outdated instances, config drift after a Canvas upgrade, Canvas preview issues, or page builder functionality. For React/JSX Code Components, see the upstream drupal-canvas/skills suite.
---

# Drupal Canvas SDC Components (Twig)

## When to Use This Skill

Use it for **Twig-based SDCs** that Canvas places in its editor: creating or changing a `*.component.yml` and its `.twig`/`.css`/`.js`, getting a component registered in Canvas, keeping `canvas.component.*` config stable across deploys, Canvas preview problems, and outdated component instances after a prop change.

Use the upstream [drupal-canvas/skills](https://github.com/drupal-canvas/skills) suite (or this repo's `drupal-canvas` pointer skill) instead(https://github.com/drupal-canvas/skills) suite instead for **Code Components** (React/JSX written in-browser or uploaded with the Canvas CLI) and for general Canvas editor usage.

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

**Registration requirements:** `title:` on every prop and slot, and `examples:` on every required prop, are Canvas registration requirements, not cosmetic. Canvas checks them on cache rebuild; an SDC that fails is disabled in Canvas (it cannot be placed in the editor) and the reasons are recorded. The first example must also validate against the prop schema, since Canvas uses it as the default value. There are more rules; see [references/registration-and-config.md](references/registration-and-config.md) for the full Canvas 1.7.1 checklist, how to read the recorded reasons, and an unexplained production 5xx that was seen alongside missing prop titles.

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

## Default Values in Twig

**IMPORTANT**: Schema `default` values are documentation only. Always use `|default()` in Twig:

```twig
{% set heading_level = heading_level|default(2) %}
{% set color = color|default('primary') %}
```

## Core Workflow: Create or Modify a Twig SDC

1. Create or edit `components/<group>/<name>/<name>.component.yml` and `<name>.twig` (plus optional `.css`/`.js` with the same base name).
2. Give every prop and slot a `title:`, every required prop an `examples:` value that validates against its schema, and use `|default()` in Twig for optional props.
3. Clear cache: `ddev drush cr`. Confirm the component is enabled at `/admin/appearance/component/status`; if it is not, read the recorded reasons ([references/registration-and-config.md](references/registration-and-config.md)).
4. New component: export its auto-created `canvas.component.sdc.<extension>.<name>` config object in the same change.
5. Changed props: check for and migrate outdated instances (`ddev drush canvas:upgrade-instances`), then re-export the component's config ([references/component-versioning.md](references/component-versioning.md)).
6. Open the Canvas editor on a page using the component before pushing.

## Critical Rules

The registration, config-export and upgrade-drift rules are in "Registration, Config Entities and Deploys" below. In addition:

- **Version pinning**: existing instances stay on the component version they were created with; prop changes need an instance upgrade ([references/component-versioning.md](references/component-versioning.md)).
- **Component-scoped CSS**: never scope styles to route/path body classes; the Canvas editor preview iframe does not have them ([references/styling-js-accessibility.md](references/styling-js-accessibility.md)).
- **Twig defaults**: schema `default` values are documentation only; use `|default()` (see "Default Values in Twig" above).

## Registration, Config Entities and Deploys

Details, commands and detection steps: [references/registration-and-config.md](references/registration-and-config.md).

- **Registration rules**: every prop and slot needs `title:`, every required prop needs `examples:`, every prop shape must be storable. Ineligible SDCs are disabled in Canvas (no entity is created, an existing one is disabled); reasons are recorded in `ComponentIncompatibilityReasonRepository`. As cheap insurance, check with `canvas_dev_mode` uninstalled after a `drush cr`.
- **New SDC = new config**: Canvas auto-creates `canvas.component.sdc.<extension>.<name>` in the database. Export that one object in the same change, or the deploy's config import deletes it.
- **Canvas module upgrade**: version-hash inputs change, so `drush cr` recomputes `active_version` on many `canvas.component.*` objects. Re-export each drifting name, confirm drift stays at zero across two more cache rebuilds, and never prune `versioned_properties`.
- **`Different` right after an import**: if only `active_version` and one archived version differ, it is versioned-config recompute noise from a stale committed hash, not a settings change.
- **Content templates**: no node-level in-context editor (Canvas 1.7.1 to 1.9.0, checked August 2026; [drupal.org/i/3498525](https://www.drupal.org/i/3498525)). Editors use the node form.

## References

| File | Read it when |
|------|--------------|
| [references/registration-and-config.md](references/registration-and-config.md) | A component does not appear or is disabled in Canvas; adding a new SDC (config export); after a Canvas module upgrade; `config:status` shows `Different` on `canvas.component.*`; content-template editing questions. |
| [references/props-and-slots.md](references/props-and-slots.md) | Writing prop schemas beyond simple strings: rich text, enum labels, required/numeric/nullable/array validation, defining and populating slots (Twig embed or PHP render arrays). |
| [references/styling-js-accessibility.md](references/styling-js-accessibility.md) | Deciding component granularity (atomic design, variants), writing component CSS (BEM, `libraryOverrides`), adding JS behaviors with `once()`, or meeting WCAG 2.2 AA. |
| [references/blocks-preview-and-testing.md](references/blocks-preview-and-testing.md) | A traditional Drupal block has no styles or does not render in the Canvas preview; choosing SDC vs block; writing Kernel tests or Storybook stories for an SDC. |
| [references/canvas-dev-tools-and-api.md](references/canvas-dev-tools-and-api.md) | Enabling Canvas submodules (`canvas_dev_mode`, `canvas_vite`, ...), finding where a component is used (audit page, usage API, `ComponentAudit`), scripting migrations against Canvas endpoints or services, or checking API stability. |
| [references/component-versioning.md](references/component-versioning.md) | Changing props on an existing component, instances not showing a new field, removing a `canvas_styling_traits` enum value, deploying prop changes, or reading `versioned_properties` / instance storage. |
| [references/troubleshooting-version-mismatches.md](references/troubleshooting-version-mismatches.md) | The Canvas editor throws a 500 `'propName' is not a prop on this version of the Component`, or a 500 persists after upgrading instances (stale auto-saves). |

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
