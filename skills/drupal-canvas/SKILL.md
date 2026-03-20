---
name: drupal-canvas
description: Drupal Canvas Code Components - a framework for building interactive, server-side-rendered components in Drupal. Covers scaffolding with @drupal-canvas/create, the Nebula starter template, component architecture, and integration with Acquia Source Site Builder.
---

# Drupal Canvas Code Components

Canvas Code Components enable interactive, server-side-rendered components in Drupal using modern JavaScript patterns with full Drupal integration.

## When This Skill Activates

Activates when working with:
- Canvas Code Components (creation, configuration, styling)
- `@drupal-canvas/create` scaffolding tool
- Nebula starter template
- Acquia Source Site Builder integration
- Component-based Drupal architecture

---

## Quick Start

### Scaffold a New Canvas Project

```bash
npx @drupal-canvas/create my-project
```

This creates a complete Drupal project with Canvas Code Components pre-configured, including:
- Drupal core with Canvas module
- Example components
- Development tooling
- Nebula starter template

### Install Canvas Skills for Detailed Guidance

For comprehensive component development guidance (7 detailed skills covering definition, metadata, composability, styling, utilities, data fetching, and upload workflows):

```bash
npx skills add drupal-canvas/skills
```

---

## What Are Code Components?

Code Components are Drupal's approach to interactive, reusable UI components that:

- **Server-side rendered** — Full SSR with hydration, not client-only
- **Drupal-integrated** — Access entities, fields, views, and Drupal APIs
- **Composable** — Nest components, pass props, emit events
- **Styled** — Scoped CSS with design token support
- **Type-safe** — Full TypeScript support with prop validation

### Component Structure

```
my-component/
├── my-component.component.tsx   # Component logic
├── my-component.metadata.json   # Drupal integration metadata
├── my-component.styles.css      # Scoped styles
└── my-component.utils.ts        # Optional utilities
```

### Example Component

```tsx
import { type ComponentProps } from '@drupal-canvas/sdk';

export default function MyComponent({ title, items }: ComponentProps) {
  return (
    <div className="my-component">
      <h2>{title}</h2>
      <ul>
        {items.map((item, i) => (
          <li key={i}>{item.label}</li>
        ))}
      </ul>
    </div>
  );
}
```

---

## Ecosystem

### Nebula Starter Template
The recommended starting point for new Canvas projects. Includes:
- Pre-configured Drupal with Canvas module
- Example components demonstrating all patterns
- DDEV local development setup
- Deployment configuration

### Acquia Source Site Builder
Canvas components integrate with Acquia's Source Site Builder for:
- Visual component placement and configuration
- Content editor-friendly component management
- Design system integration
- Multi-site component sharing

### Canvas Skills Collection
Install the full Canvas skills collection for detailed development guidance:

```bash
npx skills add drupal-canvas/skills
```

Covers 7 topics:
1. **Component Definition** — Creating and registering components
2. **Metadata** — Drupal integration via metadata.json
3. **Composability** — Nesting, props, events, slots
4. **Styling** — Scoped CSS, design tokens, theming
5. **Utilities** — Helper functions and shared logic
6. **Data Fetching** — Entity queries, views integration, API calls
7. **Upload** — Deploying components to Drupal

---

## Resources

- **Scaffolding**: `npx @drupal-canvas/create`
- **Canvas Skills**: `npx skills add drupal-canvas/skills`
- **Drupal Canvas Module**: Available via Composer
- **Nebula Template**: Included with `@drupal-canvas/create`
