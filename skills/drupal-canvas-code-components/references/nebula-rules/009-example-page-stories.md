# Example page stories

Page stories showcase how components work together in realistic layouts. They
should closely mirror what end users will experience in Drupal Canvas, so avoid
patterns that won't be available in Canvas.

## Page story location and naming

- Page stories MUST be placed in `src/stories/example-pages/`
- Page story files should be named `<page-name>.stories.jsx`
- The Storybook title MUST use this format:
  `title: "Example pages/[Page Title]"`

**Use single-story hoisting for cleaner navigation.** Page stories should use
Storybook's single-story hoisting feature to avoid unnecessary nesting in the
sidebar. This is achieved by:

1. Including the full page name in the `title`
2. Exporting only one story (typically `Default`)
3. Setting the story's `name` property to match the last segment of the title

Example:

```jsx
// src/stories/example-pages/product-detail.stories.jsx
export default {
  title: "Example pages/Product: Detail",
  component: ProductDetailPage,
  parameters: {
    layout: "fullscreen",
  },
};

export const Default = {
  name: "Product: Detail",
};
```

This results in a flat sidebar entry "Product: Detail" under "Example pages",
rather than a nested "Product: Detail" → "Default" structure.

- When creating new components, consider adding them to existing page stories if
  they fit naturally, or create new page stories to demonstrate the component in
  context.
- When modifying existing components, review page stories in
  `src/stories/example-pages/` to ensure changes work well in composed layouts
  and update them if needed.

## Shared page layout (`page-layout.jsx`)

**CRITICAL: All example page stories MUST use a shared `PageLayout` component.**

When creating example page stories, a shared `page-layout.jsx` file must exist
in `src/stories/example-pages/`. This file provides consistent site-wide
structure across all example pages for Storybook demonstration purposes.

**Note:** This `PageLayout` is a Storybook-only wrapper—it is NOT a component in
`src/components/`. It exists solely to compose real components into realistic
page previews within Storybook, simulating how pages would look with shared
site-wide elements.

**Create `page-layout.jsx` when:**

- You are creating the first example page story, OR
- It doesn't already exist in `src/stories/example-pages/`

**The `PageLayout` component must:**

- Import and render the site-wide page structure (typically header, navigation,
  footer, etc.)
- Define shared data needed by these components (e.g., navigation links, footer
  content)
- Accept a `children` prop to render page-specific content
- Wrap components in appropriate layout components (e.g., `Section`)

**Example `page-layout.jsx` structure:**

```jsx
// src/stories/example-pages/page-layout.jsx
// Import your site-wide components
import Footer from "@/components/footer";
import Header from "@/components/header";
import Section from "@/components/section";

// Define shared data for site-wide components
const footerData = {
  // Links, copyright, etc.
};

const PageLayout = ({ children }) => {
  return (
    <>
      <Section width="wide" content={<Header />} />
      {children}
      <Section width="wide" content={<Footer {...footerData} />} />
    </>
  );
};

export default PageLayout;
```

**Using `PageLayout` in page stories:**

Every example page story must import and use `PageLayout` to wrap its content:

```jsx
// src/stories/example-pages/about-page.stories.jsx
import Section from "@/components/section";
import Text from "@/components/text";

import PageLayout from "./page-layout";

const AboutPage = () => {
  return (
    <PageLayout>
      <Section width="normal" content={<Text text="<p>About us...</p>" />} />
    </PageLayout>
  );
};

export default {
  title: "Example pages/About",
  component: AboutPage,
  parameters: {
    layout: "fullscreen",
  },
};

export const Default = {
  name: "About",
};
```

**Why this matters:**

- Ensures visual consistency across all example pages
- Centralizes site-wide layout changes in one place
- Demonstrates realistic page composition with shared elements
- Makes it easy to update global page structure without editing every story

## Composing components in page stories

**CRITICAL: Page stories must only IMPORT and COMPOSE components.**

Page stories should:

- Import components from `@/components/<component_name>`
- Pass props and compose components together
- Define sample data (strings, objects, arrays) for component props

Page stories must NOT:

- Define reusable React components inline (these belong in `src/components/`)
- Contain component logic that should be extracted to a proper component
- Duplicate component code that already exists
- Use raw HTML elements (like `<div>`, `<span>`) for layout or structure—use
  existing components instead

**Wrong - defining components inline or using raw HTML:**

```jsx
// ❌ BAD: Inline component definition and raw div wrappers
const Logo = ({ color }) => (
  <div className="flex items-center">
    <svg>...</svg>
    <span style={{ color }}>Brand Name</span>
  </div>
);

const Page = () => (
  <div className="flex flex-col gap-8">
    <Logo color="#000" />
    <div className="mx-auto max-w-3xl">Content here</div>
  </div>
);
```

**Correct - composing only with existing components:**

```jsx
// ✅ GOOD: Use only imported components, no raw HTML elements
import Footer from "@/components/footer";
import Header from "@/components/header";
import Section from "@/components/section";
import Text from "@/components/text";

const Page = () => (
  <>
    <Header />
    <Section width="normal">
      <Text content="<p>Content here</p>" />
    </Section>
    <Footer />
  </>
);
```

If you find yourself reaching for a `<div>` or other HTML element, look for an
existing component that serves the same purpose. If none exists, create the
component in `src/components/` first, then import and use it in the story.

## Do not use className props in page stories

**The `className` prop is NOT exposed to end users in Drupal Canvas.** While
many components accept a `className` prop for style customization, this is only
intended for internal use when one component imports and renders another
component directly.

Page stories should never pass `className` props to components, because this
doesn't reflect what end users can do in Canvas.

```jsx
// ❌ BAD: Passing className in a page story
const AboutPage = () => (
  <PageLayout>
    <Section width="normal">
      <Text className="mt-8 mb-12" content="<p>About us...</p>" />
    </Section>
    <Card className="shadow-xl" title="Our Mission" />
  </PageLayout>
);
```

```jsx
// ✅ GOOD: No className props - matches Canvas behavior
const AboutPage = () => (
  <PageLayout>
    <Section width="normal">
      <Text content="<p>About us...</p>" />
    </Section>
    <Card title="Our Mission" />
  </PageLayout>
);
```

**When `className` IS appropriate:**

- Inside a component's `index.jsx` when it imports and renders another component
- In individual component stories (not page stories) to demonstrate flexibility
- Never in page stories or when simulating Canvas page composition

## Use the spacer component for vertical spacing

**Control spacing between components using the `spacer` component.** In Canvas,
users cannot add arbitrary margins or padding between components. Instead, they
use a dedicated spacer component to create vertical space.

Page stories must follow this same pattern to accurately represent what users
will experience in Canvas.

**If the spacer component doesn't exist in `src/components/`**, copy it from
`examples/components/spacer/` before using it in page stories:

```bash
cp -r examples/components/spacer src/components/
cp examples/stories/spacer.stories.jsx src/stories/
```

**Example usage in page stories:**

```jsx
// ✅ GOOD: Use Spacer component for vertical spacing
import Hero from "@/components/hero";
import Section from "@/components/section";
import Spacer from "@/components/spacer";
import Text from "@/components/text";

const AboutPage = () => (
  <PageLayout>
    <Hero title="About Us" />
    <Spacer height="large" />
    <Section width="normal">
      <Text content="<p>Our story begins...</p>" />
    </Section>
    <Spacer height="medium" />
    <Section width="normal">
      <Text content="<p>Our mission is...</p>" />
    </Section>
  </PageLayout>
);
```

```jsx
// ❌ BAD: Using margin classes or wrapper divs for spacing
const AboutPage = () => (
  <PageLayout>
    <Hero title="About Us" />
    <div className="mt-16">
      <Section width="normal">
        <Text content="<p>Our story begins...</p>" />
      </Section>
    </div>
    <Section width="normal" className="mt-12">
      <Text content="<p>Our mission is...</p>" />
    </Section>
  </PageLayout>
);
```

**Why this matters:**

- Accurately represents how spacing works in Canvas
- Ensures page stories can be translated to Canvas without surprises
- Maintains consistency with the component-based composition model
- Prevents reliance on styling patterns unavailable to Canvas users

## Use layout components for structure

**Use existing layout components instead of inline styles or raw HTML
wrappers.** Check `src/components/` and `examples/components/` for layout
components that handle common structural patterns like:

- **Width constraints**: Components that center content and control max-width
  (often called `section`, `container`, or similar)
- **Column layouts**: Components that arrange content in grid or flex columns
  (often called `grid-container`, `columns`, `layout`, or similar)
- **Spacing**: Components that add vertical space between sections (often called
  `spacer`, `divider`, or similar)

When composing pages, look for and use these layout components rather than
adding inline Tailwind classes for structure.

```jsx
// ✅ GOOD: Use layout components from the codebase
<WidthConstraintComponent variant="wide">
  <ColumnLayoutComponent columns="sidebar-main">
    {/* Content here */}
  </ColumnLayoutComponent>
</WidthConstraintComponent>
```

```jsx
// ❌ BAD: Inline layout styles in page stories
<div className="mx-auto max-w-6xl px-4">
  <div className="grid grid-cols-[300px_1fr] gap-8">{/* Content here */}</div>
</div>
```

**Why this matters:**

- Layout components can be reused and configured consistently
- Changes to layout behavior happen in one place
- Page stories remain focused on content composition, not styling
- Inline styles in page stories can't be replicated in Canvas
