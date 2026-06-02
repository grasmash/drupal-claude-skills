# Requirements for creating or modifying components

**Always study `examples/` first and follow their patterns.**

## Technology stack

- React 19;
- Tailwind CSS 4.1+;
- class-variance-authority (CVA) for component variants;
- `clsx` and `tailwind-merge` via the `cn()` utility;
- `FormattedText` component from `@/lib/FormattedText` for rendering HTML
  content.

## Component patterns

- Use CVA (`cva()`) to define variant styles for components.
- Use the `cn()` utility from `@/lib/utils` to merge class names.
- Always export components as default exports.
- Accept a `className` prop for style customization.
- Use the `@/components` import alias when importing other components.
- Only use dependencies listed in the technology stack; do not add third-party
  imports or create new library utilities.
- Place each component in its own folder under `src/components/` with an
  `index.jsx` and `component.yml` file. Do not create nested folder structures.

## Styling conventions

- Use Tailwind's theme colors (`primary-*`, `gray-*`) defined in `global.css`.
- Avoid hardcoded color values; use theme tokens instead.
- Follow the existing focus, hover, and active state patterns from examples.

## Tailwind 4 theme variables

This project uses Tailwind CSS 4's `@theme` directive to define design tokens in
`global.css`. Variables defined inside `@theme { }` automatically become
available as Tailwind utility classes.

**Always check `global.css` for available design tokens.** The `@theme` block is
the source of truth for colors, fonts, breakpoints, and other design tokens in
this project.

### How theme variables map to utility classes

When you define a CSS variable in `@theme`, Tailwind 4 automatically generates
corresponding utility classes based on the variable's namespace prefix:

| CSS Variable in `@theme`    | Generated Utility Classes                                  |
| --------------------------- | ---------------------------------------------------------- |
| `--color-primary-600: #xxx` | `bg-primary-600`, `text-primary-600`, `border-primary-600` |
| `--color-gray-100: #xxx`    | `bg-gray-100`, `text-gray-100`, `border-gray-100`          |
| `--font-sans: ...`          | `font-sans`                                                |
| `--breakpoint-md: 48rem`    | `md:` responsive prefix                                    |

The pattern is: `--{namespace}-{name}` becomes `{utility}-{name}`.

### Examples

Given this definition in `global.css`:

```css
@theme {
  --color-primary-600: #1899cb;
  --color-primary-700: #1487b4;
}
```

You can use these colors with any color-accepting utility:

```jsx
// ✅ GOOD: Using theme tokens via utility classes
<button className="bg-primary-600 hover:bg-primary-700 text-white">
  Click me
</button>

<div className="border border-primary-600">
  Bordered content
</div>

<span className="text-primary-600">
  Colored text
</span>
```

```jsx
// ❌ AVOID: Hardcoding hex values when theme tokens exist
<button className="bg-[#1899cb] text-white hover:bg-[#1487b4]">Click me</button>
```

Arbitrary values (e.g., `bg-[#xxx]`) are acceptable for rare, one-off cases
where adding a theme variable would be overkill. However, if a color appears in
multiple places or represents a brand/design system value, add it to `@theme`
instead.

### Semantic aliases

Theme variables can reference other variables to create semantic aliases:

```css
@theme {
  --color-primary-700: #1487b4;
  --color-primary-dark: var(--color-primary-700);
}
```

Both `bg-primary-700` and `bg-primary-dark` will work. Use semantic aliases when
they better express intent (e.g., `primary-dark` for a darker brand variant).

### Adding or updating theme variables

When a design requires a color, font, or other value not yet defined in the
theme, add it to the `@theme` block in `global.css` rather than hardcoding the
value in a component.

**When to add new theme variables:**

- A design introduces a new brand color or shade
- You need a semantic alias for an existing value (e.g., `--color-accent`)
- The design uses a specific spacing, font, or breakpoint value repeatedly

**When to update existing theme variables:**

- The brand colors change (update the hex values)
- Design tokens need adjustment across the system

**Example - adding a new color:**

```css
@theme {
  /* Existing tokens */
  --color-primary-600: #1899cb;

  /* New token for a success state */
  --color-success: #22c55e;
  --color-success-dark: #16a34a;
}
```

After adding, you can immediately use `bg-success`, `text-success-dark`, etc.

**Keep the theme organized.** Group related tokens together with comments
explaining their purpose. Follow the existing naming conventions in `global.css`
(e.g., numbered shades like `primary-100` through `primary-900`, semantic names
like `primary-dark`).

## Color props must use variants, not color codes

**Never create props that allow users to pass color codes** (hex values, RGB,
HSL, or any raw color strings). Instead, define a small set of human-readable
variants using CVA that map to the design tokens in `global.css`.

**Always check `global.css` for available design tokens.** The tokens defined
there (such as `primary-*`, `gray-*`, etc.) are the source of truth for color
values in this project.

**Wrong - allowing raw color values:**

```yaml
# ❌ BAD: Allows arbitrary color codes as prop values
props:
  properties:
    backgroundColor:
      title: Background Color
      type: string
      examples:
        - "#3b82f6"
```

```jsx
// ❌ BAD: Uses inline style with raw color value
const Card = ({ backgroundColor }) => (
  <div style={{ backgroundColor }}>{/* ... */}</div>
);
```

**Correct - using CVA variants with design tokens:**

```yaml
# ✅ GOOD: Offers curated color scheme options
props:
  properties:
    colorScheme:
      title: Color Scheme
      type: string
      enum:
        - default
        - primary
        - muted
        - dark
      meta:enum:
        default: Default (White)
        primary: Primary (Blue)
        muted: Muted (Light Gray)
        dark: Dark
      examples:
        - default
```

```jsx
// ✅ GOOD: Uses CVA variants mapped to design tokens
import { cva } from "class-variance-authority";

const cardVariants = cva("rounded-lg p-6", {
  variants: {
    colorScheme: {
      default: "bg-white text-black",
      primary: "bg-primary-600 text-white",
      muted: "bg-gray-100 text-gray-700",
      dark: "bg-gray-900 text-white",
    },
  },
  defaultVariants: {
    colorScheme: "default",
  },
});

const Card = ({ colorScheme, children }) => (
  <div className={cardVariants({ colorScheme })}>{children}</div>
);
```

This approach ensures:

- Consistent colors across the design system
- Users select from curated, meaningful options (not arbitrary values)
- Easy theme updates by modifying `global.css` tokens
- Better accessibility through tested color combinations

## Storybook stories

**CRITICAL: Every component MUST have an individual story file.**

Each component in `src/components/` requires a corresponding story file in
`src/stories/`. The story file:

- Must be named `<component-name>.stories.jsx` (kebab-case with hyphens)
- Must import the component from `@/components/<component_name>`
- Must showcase the component's props and variants

**Example structure:**

```
src/components/my_card/
├── index.jsx
└── component.yml

src/stories/my-card.stories.jsx  # Required story file for my_card component
```

**Story file requirements:**

- Use Storybook CSF3 format (object-based stories).
- Include `argTypes` for props with predefined options (like enums).
- Create multiple story exports to showcase different variants.
- Use decorators when components need specific backgrounds (e.g., dark
  backgrounds for light-colored components).

After creating components, verify story files exist:

```bash
# List all story files
ls src/stories/*.stories.jsx

# Verify a specific component has its story
ls src/stories/<component-name>.stories.jsx
```
