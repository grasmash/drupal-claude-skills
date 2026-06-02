---
description: Canvas Code Components (React/JSX) for Drupal Canvas page builder. Use when creating, modifying, or uploading JavaScript-based components built in Storybook with React, Tailwind CSS, and CVA for the Canvas visual editor.
globs:
  - "**/src/components/**/*.jsx"
  - "**/src/components/**/component.yml"
  - "**/src/stories/**/*.stories.jsx"
  - "**/examples/components/**/*"
triggers:
  - code component
  - code components
  - canvas component
  - react component
  - jsx component
  - storybook
  - CVA
  - class-variance-authority
  - tailwind component
  - canvas upload
  - upload component
alwaysApply: false
---

# Canvas Code Components (React/JSX)

## Overview

Canvas Code Components are React/JSX components built locally in Storybook and uploaded to Drupal Canvas via CLI. They're distinct from SDC (Single Directory Components) which use Twig templates.

**Official Documentation:** https://project.pages.drupalcode.org/canvas/code-components

**Getting Started:** Create a new project with the Nebula template:
```bash
npx @drupal-canvas/create@latest
```

**Technology Stack:**
- React 19
- Tailwind CSS 4.1+
- class-variance-authority (CVA) for component variants
- `clsx` and `tailwind-merge` via the `cn()` utility from `drupal-canvas`
- SWR for data fetching
- `FormattedText` component from `drupal-canvas` for rendering HTML content

## CLI Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start Storybook development server |
| `npm run storybook` | Alias for `dev` |
| `npm run code:check` | Run all code checks (Prettier + ESLint) |
| `npm run code:fix` | Run all code fixes with auto-fix |
| `npx canvas upload -c component1,component2 -y` | Upload components to Canvas |
| `npx canvas` | List all Canvas CLI commands |

## Project Structure

```
src/
├── components/     # Working components (Storybook reads from here)
│   └── global.css  # Base styles with @theme tokens
├── stories/        # Working stories (Storybook reads from here)
│   └── example-pages/  # Page composition stories
└── lib/            # Library utilities and mocks

examples/
├── components/     # Example component implementations (for reference)
└── stories/        # Example stories (for reference)
```

## Required Component Structure

**CRITICAL:** Every component folder MUST contain exactly two files:

```
src/components/<component_name>/
├── index.jsx      # React component source code (REQUIRED)
└── component.yml  # Component metadata and props (REQUIRED)
```

The directory name must exactly match the `machineName` value in `component.yml`.

## component.yml Schema (Code Components)

```yaml
name: Component Name        # Human-readable display name
machineName: component_name # Machine name (snake_case, matches directory)
status: true                # Whether the component is enabled
required:                   # Array of required prop names
  - heading
props:
  properties:
    heading:
      title: Heading        # UI label
      type: string
      examples:             # REQUIRED for required props
        - Enter a heading...
slots:
  content:
    title: Content
```

### Prop ID Naming Convention

Prop IDs (keys under `properties`) MUST be camelCase versions of their `title`:

```yaml
# Correct
props:
  properties:
    buttonText:           # camelCase of "Button Text"
      title: Button Text
    backgroundColor:      # camelCase of "Background Color"
      title: Background Color

# Wrong
props:
  properties:
    btn_text:             # Should be "buttonText"
      title: Button Text
```

## Prop Types Reference

### Text
```yaml
type: string
examples:
  - Hello, world!
```

### Formatted Text (Rich Text with HTML)
```yaml
type: string
contentMediaType: text/html
x-formatting-context: block
examples:
  - <p>This is <strong>formatted</strong> text.</p>
```

### Link (URI)
```yaml
type: string
format: uri-reference
examples:
  - /about/contact    # Use real paths, NOT "#"
```

### Image
```yaml
type: object
$ref: json-schema-definitions://canvas.module/image
examples:
  - src: https://example.com/image.jpg
    alt: Description
    width: 800
    height: 600
```

### Video
```yaml
type: object
$ref: json-schema-definitions://canvas.module/video
examples:
  - src: https://example.com/video.mp4
    poster: https://example.com/poster.png
```

### Boolean
```yaml
type: boolean
examples:
  - false
```

### Enum (Dropdown)
```yaml
type: string
enum:
  - left_aligned      # Machine-friendly, lowercase
  - center_aligned
meta:enum:
  left_aligned: Left aligned    # Human-readable labels
  center_aligned: Center aligned
examples:
  - left_aligned      # Must be enum value, not label
```

**Note:** Enum values cannot contain dots.

## JSX Component Patterns

### Basic Component with CVA

```jsx
import { cva } from "class-variance-authority";
import { cn } from "drupal-canvas";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-lg px-4 py-3 font-medium transition-colors",
  {
    variants: {
      variant: {
        solid: "bg-primary-600 text-white hover:bg-primary-700",
        outline: "border border-primary-600 text-primary-600 hover:bg-primary-100",
      },
    },
    defaultVariants: {
      variant: "solid",
    },
  }
);

const Button = ({ text, link = "#", variant, className }) => {
  return (
    <a className={cn(buttonVariants({ variant }), className)} href={link}>
      {text}
    </a>
  );
};

export default Button;
```

### Component with Slots

```jsx
const Section = ({ width, content }) => {
  return (
    <div className={sectionVariants({ width })}>
      {content}
    </div>
  );
};

export default Section;
```

### Key Patterns

- Use CVA (`cva()`) to define variant styles
- Use `cn()` utility from `drupal-canvas` to merge class names
- Always export components as **default exports**
- Accept a `className` prop for style customization
- Use `@/components` import alias for other components
- Slots are received as props and rendered directly

## Color Props: Use Variants, Not Color Codes

**Never create props that accept raw color values.** Use CVA variants with design tokens:

```yaml
# WRONG
props:
  properties:
    backgroundColor:
      type: string
      examples:
        - "#3b82f6"
```

```yaml
# CORRECT
props:
  properties:
    colorScheme:
      type: string
      enum:
        - default
        - primary
        - muted
      meta:enum:
        default: Default (White)
        primary: Primary (Blue)
        muted: Muted (Light Gray)
```

```jsx
const cardVariants = cva("rounded-lg p-6", {
  variants: {
    colorScheme: {
      default: "bg-white text-black",
      primary: "bg-primary-600 text-white",
      muted: "bg-gray-100 text-gray-700",
    },
  },
});
```

## Repeatable Content: Use Slots, Not Array Props

**Canvas does NOT support array props with nested objects.** This will fail:

```yaml
# WRONG - Will fail to upload
props:
  properties:
    items:
      type: array
      items:
        type: object
        properties:
          title:
            type: string
          description:
            type: string
```

**Solution:** Create a child component and use a slot in the parent:

```yaml
# Parent: features-section/component.yml
slots:
  features:
    title: Features
```

```yaml
# Child: feature-card/component.yml
props:
  properties:
    title:
      title: Title
      type: string
    description:
      title: Description
      type: string
```

```jsx
// Parent component
const FeaturesSection = ({ heading, features }) => (
  <div>
    <h2>{heading}</h2>
    <div className="flex gap-10">{features}</div>
  </div>
);
```

### Common Patterns Requiring Slots

| Parent Component | Child Component | Use Case |
|-----------------|-----------------|----------|
| `footer` | `footer-link-group` | Footer columns |
| `card-grid` | `card` | Grid of cards |
| `testimonials` | `testimonial-card` | Customer quotes |
| `features-section` | `feature-card` | Feature highlights |

## Slot Container Minimum Sizes

When slots are inside flex/grid containers, add minimum dimensions for Canvas editor:

```jsx
// WRONG - Container collapses when slot empty
<header className="flex items-center justify-between">
  <div>{branding}</div>
  <nav>{navigation}</nav>
</header>

// CORRECT - Minimum width keeps slot interactive
<header className="flex items-center justify-between">
  <div className="min-w-32">{branding}</div>
  <nav>{navigation}</nav>
</header>
```

## Component Composability

### Signs a Component Should Be Decomposed

- More than 6-8 props serving distinct purposes
- Props for elements that could be standalone (breadcrumbs, metadata)
- Built-in layout assumptions limiting reuse
- Multiple distinct visual sections

### Prefer Slots Over Complex Props

```jsx
// BAD: Complex data as props
const ResourceDetail = ({ metadata }) => (
  <div>
    {metadata.map(item => <MetadataItem {...item} />)}
  </div>
);

// GOOD: Use slot for composition
const ResourceMetadata = ({ items }) => (
  <div className="flex flex-col gap-2">{items}</div>
);
```

### Design for Composability

Don't build layout constraints into individual components:

```jsx
// GOOD: Component adapts to container
const Card = ({ title, children }) => (
  <div className="rounded-lg border p-4">
    <h3>{title}</h3>
    {children}
  </div>
);

// BAD: Built-in width constraints
const Card = ({ title, children }) => (
  <div className="mx-auto max-w-md rounded-lg border p-4">
    <h3>{title}</h3>
    {children}
  </div>
);
```

## Storybook Stories

**Every component MUST have an individual story file.**

```
src/components/my_card/
├── index.jsx
└── component.yml

src/stories/my-card.stories.jsx  # Required (kebab-case naming)
```

### Story File Requirements

- Use Storybook CSF3 format (object-based stories)
- Include `argTypes` for props with predefined options
- Create multiple story exports for different variants

```jsx
import Button from "@/components/button";

export default {
  title: "Components/Button",
  component: Button,
  argTypes: {
    variant: {
      control: "select",
      options: ["solid", "outline", "ghost"],
    },
  },
};

export const Solid = {
  args: {
    text: "Click Me",
    variant: "solid",
  },
};

export const Outline = {
  args: {
    text: "Click Me",
    variant: "outline",
  },
};
```

## Example Page Stories

Page stories go in `src/stories/example-pages/` and must use a shared `PageLayout`:

```jsx
// src/stories/example-pages/page-layout.jsx
import Footer from "@/components/footer";
import Header from "@/components/header";
import Section from "@/components/section";

const PageLayout = ({ children }) => (
  <>
    <Section width="wide" content={<Header />} />
    {children}
    <Section width="wide" content={<Footer />} />
  </>
);

export default PageLayout;
```

### Page Story Rules

1. **Only import and compose components** - no inline component definitions
2. **No raw HTML elements** - use existing components for structure
3. **No className props** - Canvas users can't use them
4. **Use Spacer component** for vertical spacing between sections
5. **Use layout components** instead of inline Tailwind for structure

```jsx
// CORRECT
import Spacer from "@/components/spacer";
import Section from "@/components/section";

const AboutPage = () => (
  <PageLayout>
    <Hero title="About Us" />
    <Spacer height="large" />
    <Section width="normal">
      <Text content="<p>Our story...</p>" />
    </Section>
  </PageLayout>
);

// WRONG - Using className and wrapper divs
const AboutPage = () => (
  <PageLayout>
    <Hero title="About Us" />
    <div className="mt-16">
      <Section width="normal" className="mb-8">
        <Text content="<p>Our story...</p>" />
      </Section>
    </div>
  </PageLayout>
);
```

## Data Fetching with SWR

```jsx
import { getNodePath, JsonApiClient } from "drupal-canvas";
import { DrupalJsonApiParams } from "drupal-jsonapi-params";
import useSWR from "swr";

const Articles = () => {
  const client = new JsonApiClient();
  const { data, error, isLoading } = useSWR(
    ["node--article", {
      queryString: new DrupalJsonApiParams()
        .addSort("created", "DESC")
        .addFields("node--article", ["title", "created", "field_image"])
        .addInclude(["field_image"])
        .getQueryString(),
    }],
    ([type, options]) => client.getCollection(type, options)
  );

  if (error) return "An error has occurred.";
  if (isLoading) return "Loading...";
  return (
    <ul>
      {data.map(article => (
        <li key={article.id}>
          <a href={getNodePath(article)}>{article.title}</a>
        </li>
      ))}
    </ul>
  );
};
```

### Avoid Circular References

**Do not include self-referential fields** (e.g., `field_related_articles` on articles). Use `addFields` to limit response data.

## Creating New Components

1. **Start from an example** - Browse `examples/components/` for similar components
2. **Copy both files** - Component folder AND corresponding story
3. **Analyze dependencies** - Check for `@/components` imports
4. **Copy dependencies first** - Ensure all required components exist
5. **Never overwrite existing** - Don't replace components in `src/components/`

```bash
# Copy example component and story
cp -r examples/components/button src/components/
cp examples/stories/button.stories.jsx src/stories/
```

## Naming Conventions

- **Component folders**: `snake_case` (matching `machineName`)
- **Story files**: `kebab-case.stories.jsx`
- **Component names**: Simple, generic (never prefix with project name)
- **Prop IDs**: camelCase matching title

```
# Correct
footer, hero, navigation, contact_form

# Wrong - project-prefixed
nebula_footer, acme_hero, mysite_navigation
```

## Styling Best Practices

**Component-Scoped CSS (CRITICAL)**: NEVER scope styles to route/path body classes (e.g., `.alias--masterclasses`, `.path-some-page`). Instead, scope styles to the component's own classes (e.g., `.view-masterclasses`, `.block-views-blockmasterclasses-block-2`). The Canvas editor renders page previews in an iframe without the page's body classes, so route-scoped styles won't appear there. All styles must be componentized and portable -- they should look correct regardless of what route or context they render in.

## Tailwind 4 Theme Variables

Define design tokens in `global.css` using `@theme`:

```css
@theme {
  --color-primary-600: #1899cb;
  --color-primary-700: #1487b4;
  --color-gray-100: #f3f4f6;
}
```

Variables automatically become utility classes: `bg-primary-600`, `text-primary-700`, etc.

**Always check `global.css` for available tokens** before hardcoding values.

## Validation and Upload

### Validate Changes

```bash
npm run code:fix
```

Runs Prettier and ESLint with auto-fix. Run before considering work complete.

### Upload Components

```bash
npx canvas upload -c component1,component2,component3 -y
```

### Upgrade Existing Instances After Prop Changes

Canvas pins component instances to the version they were created with. When you add, remove, or rename props, existing instances won't reflect the changes and may error with `'propName' is not an explicit input prop`. After uploading a component with changed props, run:

```bash
ddev drush canvas:upgrade-instances --all -y
```

This migrates all placed component instances to the active version. You can also target a specific component:

```bash
ddev drush canvas:upgrade-instances js.container -y
```

Use `--dry-run` to preview changes without applying them.

### Handling Upload Failures

- **Retry on failure** - Transient issues are common
- **Dependencies** - If component A depends on component B, B must upload first
- Simply retry the command; previously uploaded dependencies will exist

## Component Reuse

**Always check `src/components/` before creating new UI elements.** Import and use existing components rather than duplicating functionality:

```jsx
// GOOD: Import existing button
import Button from "@/components/button";

const Newsletter = () => (
  <form>
    <input type="email" placeholder="Enter email" />
    <Button variant="primary">Subscribe</Button>
  </form>
);

// BAD: Duplicating button styles
const Newsletter = () => (
  <form>
    <input type="email" placeholder="Enter email" />
    <button className="rounded bg-primary-600 px-4 py-2 text-white">
      Subscribe
    </button>
  </form>
);
```

## Reference Examples

This skill includes the complete Nebula project examples in `references/`:

- **`references/nebula-rules/`** - 13 detailed AI development rules covering component creation, composability, metadata, slots, page stories, and data fetching
- **`references/nebula-examples/components/`** - 23 example components (blockquote, breadcrumb, button, card, footer, grid_container, header, heading, hero, image, logo, main_navigation, search components, section, spacer, text, two_column_text, video)
- **`references/nebula-examples/stories/`** - Corresponding Storybook stories
- **`references/nebula-examples/global.css`** - Tailwind 4 `@theme` tokens

When creating a new component, browse these examples for a similar starting point.

## Apply to Files

- `**/src/components/**/*.jsx`
- `**/src/components/**/component.yml`
- `**/src/stories/**/*.stories.jsx`
- `**/examples/components/**/*`
