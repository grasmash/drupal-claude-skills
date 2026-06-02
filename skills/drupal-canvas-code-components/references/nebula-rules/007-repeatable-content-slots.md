# Repeatable content must use slots, not array props

**Drupal Canvas does not support array props with complex nested objects.** When
a component needs to render a list of items with multiple properties, you must
use slots instead of array props.

## What doesn't work

Canvas will reject components that define array props with nested object items:

```yaml
# ❌ WRONG: This will fail to upload
props:
  properties:
    items:
      title: Items
      type: array
      items:
        type: object
        properties:
          title:
            type: string
          description:
            type: string
          linkUrl:
            type: string
```

The upload will fail with an error like:

> Drupal Canvas does not know of a field type/widget to allow populating the
> items prop, with the shape {...}. [props.items.items] 'items' is not a
> supported key. [props.items.type] The value you selected is not a valid
> choice.

## The solution: slots + child components

Instead of array props, create a separate child component for the repeating item
and use a slot in the parent component.

### Step 1: Create the child component

Extract the item structure into its own component:

```yaml
# src/components/feature-card/component.yml
name: Feature Card
machineName: feature-card
status: true
required:
  - title
props:
  properties:
    title:
      title: Title
      type: string
      examples:
        - Feature One
    description:
      title: Description
      type: string
      examples:
        - A brief description of this feature and its benefits.
    linkText:
      title: Link Text
      type: string
      examples:
        - Learn more
    linkUrl:
      title: Link URL
      type: string
      format: uri-reference
      examples:
        - /features/feature-one
slots: []
```

### Step 2: Update the parent component to use a slot

Replace the array prop with a slot:

```yaml
# src/components/features-section/component.yml
name: Features Section
machineName: features-section
status: true
required:
  - heading
props:
  properties:
    heading:
      title: Heading
      type: string
      examples:
        - Our Features
slots:
  features:
    title: Features
```

### Step 3: Update the JSX to render the slot

In the parent component's JSX, render the slot as children:

```jsx
// src/components/features-section/index.jsx
const FeaturesSection = ({ heading, features, className }) => {
  return (
    <div className={className}>
      <h2>{heading}</h2>
      {/* Render the slot content */}
      <div className="flex gap-10">{features}</div>
    </div>
  );
};
```

### Step 4: Update stories to use child components

In Storybook stories, compose the parent with child components:

```jsx
// src/stories/features-section.stories.jsx
import FeatureCard from "@/components/feature-card";
import FeaturesSection from "@/components/features-section";

export const Default = {
  args: {
    heading: "Our Features",
    features: (
      <>
        <FeatureCard
          title="Feature One"
          description="A brief description of this feature..."
          linkText="Learn more"
          linkUrl="/features/feature-one"
        />
        <FeatureCard
          title="Feature Two"
          description="Another feature with its own benefits..."
          linkText="Learn more"
          linkUrl="/features/feature-two"
        />
      </>
    ),
  },
};
```

## Common patterns requiring this approach

These component patterns always need slots with child components:

| Parent Component    | Child Component     | Use Case                    |
| ------------------- | ------------------- | --------------------------- |
| `footer`            | `footer-link-group` | Footer navigation columns   |
| `footer-link-group` | `footer-link`       | Links within a footer group |
| `card-grid`         | `card`              | Grid/carousel of cards      |
| `testimonials`      | `testimonial-card`  | Customer testimonials       |
| `cta-section`       | `cta-card`          | Call-to-action cards        |
| `features-section`  | `feature-card`      | Feature highlight cards     |
| `stats-hero`        | `stat-item`         | Statistics display          |
| `metadata-list`     | `metadata-item`     | Key-value metadata pairs    |
| `carousel`          | `carousel-item`     | Carousel slides             |

## When array props ARE supported

Simple arrays of primitive values (strings, numbers) are supported:

```yaml
# ✅ OK: Array of simple strings
props:
  properties:
    tags:
      title: Tags
      type: array
      items:
        type: string
      examples:
        - - tag1
          - tag2
```

However, arrays of objects with multiple properties must always use the slot +
child component pattern.

## Naming conventions for child components

When creating child components for slots:

- Use descriptive names that indicate the item type: `feature-card`,
  `testimonial-card`, `team-member`
- For generic items, suffix with `-item`: `metadata-item`, `carousel-item`,
  `list-item`
- For link-related items, be specific: `footer-link`, `nav-link`, `social-link`

Always create a corresponding story file for each child component.
