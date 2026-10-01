---
name: drupal-canvas
description: Entry point for Drupal Canvas Code Components (React/JSX). Points to the officially maintained drupal-canvas/skills suite (component definition, metadata, push, styling, data fetching, regions, page definition, content templates) and to this repo's complements for Twig SDCs and upstream contribution. Use when creating, modifying, or pushing Canvas Code Components, or when deciding which Canvas skill applies.
---

# Drupal Canvas Code Components — use the upstream suite

Canvas Code Components (React/JSX) are covered by the officially maintained
**[drupal-canvas/skills](https://github.com/drupal-canvas/skills)** suite
(MIT licensed). This repo does not mirror it: a local copy goes stale as
upstream evolves, and stale component rules are worse than none. Install the
real thing:

```bash
npx skills add drupal-canvas/skills
```

To scaffold a codebase for Code Components, upstream publishes a CLI:
`npx @drupal-canvas/create <project>`.

## When This Skill Activates

- Building, editing, or pushing a Canvas Code Component
- Choosing between a Code Component and a Twig SDC
- Looking for Canvas guidance and unsure which skill holds it

## Upstream skills

The suite ships these skills (check the repo for the current list):

- `canvas-component-composability`
- `canvas-component-definition`
- `canvas-component-metadata`
- `canvas-component-push`
- `canvas-component-utils`
- `canvas-content-templates`
- `canvas-data-fetching`
- `canvas-design-decomposition`
- `canvas-headless`
- `canvas-navigation-components`
- `canvas-page-definition`
- `canvas-regions`
- `canvas-styling-conventions`
- `canvas-workbench`

## Complements in this repo

The upstream suite is React/JSX only. For everything else:

- **`drupal-canvas-sdc`** — Twig Single Directory Components in themes and
  modules: `component.yml` schemas, Canvas registration rules, component
  config entities, versioning, and deploy pitfalls.
- **`canvas-contribution`** — contributing Canvas features and fixes back to
  drupal.org (issue forks, merge requests, composer patches).
