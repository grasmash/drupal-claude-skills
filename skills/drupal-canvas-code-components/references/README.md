# Canvas Code Components References

This directory contains reference materials from the Nebula project - the official template for Drupal Canvas Code Components.

## Directory Structure

### nebula-rules/

AI development rules from the Nebula project's `.ruler/rules/` directory. These are detailed instructions for creating and modifying Canvas Code Components:

| File | Description |
|------|-------------|
| `001-project-structure.md` | Project folder structure overview |
| `002-package-manager.md` | NPM usage requirements |
| `003-creating-new-components.md` | How to create new components from examples |
| `004-requirements-for-creating-or-modifying-components.md` | Technology stack and coding conventions |
| `005-component-composability.md` | Designing composable, slot-based components |
| `006-component-metadata.md` | component.yml schema and prop types |
| `007-repeatable-content-slots.md` | Why arrays don't work and how to use slots |
| `008-slot-container-minimum-size.md` | Making slots work in flex/grid containers |
| `009-example-page-stories.md` | Rules for composing page-level stories |
| `010-validating-changes.md` | Running code checks before completion |
| `011-uploading-components.md` | Using the Canvas CLI to upload |
| `012-scraping-urls-for-design.md` | WebFetch patterns for design reference |
| `013-dynamic-content-and-data-fetching.md` | SWR and JSON:API data fetching |

### nebula-examples/

Example components and stories from the Nebula project. Use these as starting points when creating new components:

- **components/** - Example component implementations (copy to `src/components/` as starting point)
- **stories/** - Corresponding Storybook stories (copy to `src/stories/`)
- **global.css** - Base styles with Tailwind 4 `@theme` tokens

## Usage

When creating a new Canvas Code Component:

1. Browse `nebula-examples/components/` for a similar component
2. Copy both the component folder AND its story file
3. Modify to implement your specific needs
4. Follow patterns in `nebula-rules/` for best practices

## Source

These references come from the Nebula project:
- Repository: https://github.com/e0ipso/nebula (or via `npx @drupal-canvas/create@latest`)
- Documentation: https://project.pages.drupalcode.org/canvas/code-components
