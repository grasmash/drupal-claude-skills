# Component metadata files (`component.yml`)

Each component requires a `component.yml` file that defines its metadata, props,
and slots.

## File structure

Every `component.yml` must include these top-level keys:

```yaml
name: Component Name # Human-readable display name
machineName: component_name # Machine name in snake_case
status: true # Whether the component is enabled
required: [] # Array of required prop names
props:
  properties:
    # ... prop definitions
slots: [] # Array of slot definitions or empty
```

**Props must have title and examples.**

Every prop definition must include a `title` for the UI label. The `examples`
array is required for required props and recommended for all others. Only the
first example value is used by Drupal Canvas.

```yaml
props:
  properties:
    heading:
      title: Heading
      type: string
      examples:
        - Enter a heading...
```

**Prop IDs must be camelCase versions of their titles.**

The prop ID (the key under `properties`) must be the camelCase conversion of the
`title` value.

```yaml
# Correct - prop ID is camelCase of title
props:
  properties:
    buttonText:           # camelCase of "Button Text"
      title: Button Text
      type: string
    backgroundColor:      # camelCase of "Background Color"
      title: Background Color
      type: string
    isVisible:            # camelCase of "Is Visible"
      title: Is Visible
      type: boolean

# Wrong - prop IDs don't match titles
props:
  properties:
    btn_text:             # should be "buttonText" for title "Button Text"
      title: Button Text
    bgColor:              # should be "backgroundColor" for title "Background Color"
      title: Background Color
```

## Prop types

### Text

Basic text input. Stored as a string value.

```yaml
type: string
examples:
  - Hello, world!
```

### Formatted text

Rich text content with HTML formatting support, displayed in a block context.

```yaml
type: string
contentMediaType: text/html
x-formatting-context: block
examples:
  - <p>This is <strong>formatted</strong> text with HTML.</p>
```

### Link

URL or URI reference for links to internal or external resources.

```yaml
type: string
format: uri-reference
examples:
  - /about/contact
```

**Note:** The format can be either `uri` (accepts only absolute URLs) or
`uri-reference` (accepts both absolute and relative URLs).

**IMPORTANT: Use proper path examples for URL props.** Do not use `#` as an
example value for `uri-reference` props—it can cause validation failures during
upload. Always use realistic path-like examples:

```yaml
# ✅ Correct - proper path examples
examples:
  - /resources
  - /about/team
  - https://example.com/page

# ❌ Wrong - can cause upload failures
examples:
  - "#"
  - ""
```

### Image

Reference to an image object with metadata like alt text, dimensions, and file
URL. Only the file URL is required to exist, all other metadata is always
optional.

```yaml
type: object
$ref: json-schema-definitions://canvas.module/image
examples:
  - src: >-
      https://images.unsplash.com/photo-1484959014842-cd1d967a39cf?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1770&q=80
    alt: Woman playing the violin
    width: 1770
    height: 1180
```

### Video

Reference to a video object with metadata like dimensions and file URL. Only the
file URL is required to exist, all other metadata is always optional.

```yaml
type: object
$ref: json-schema-definitions://canvas.module/video
examples:
  - src: https://media.istockphoto.com/id/1340051874/video/aerial-top-down-view-of-a-container-cargo-ship.mp4?s=mp4-640x640-is&k=20&c=5qPpYI7TOJiOYzKq9V2myBvUno6Fq2XM3ITPGFE8Cd8=
    poster: https://example.com/600x400.png
```

### Boolean

True or false value.

```yaml
type: boolean
examples:
  - false
```

### Integer

Whole number value without decimal places.

```yaml
type: integer
examples:
  - 42
```

### Number

Numeric value that can include decimal places.

```yaml
type: number
examples:
  - 3.14
```

### List: text

A predefined list of text options that the user can select from.

```yaml
type: string
enum:
  - option1
  - option2
  - option3
meta:enum:
  option1: Option 1
  option2: Option 2
  option3: Option 3
examples:
  - option1
```

### List: integer

A predefined list of integer options that the user can select from.

```yaml
type: integer
enum:
  - 1
  - 2
  - 3
meta:enum:
  1: Option 1
  2: Option 2
  3: Option 3
examples:
  - 1
```

## Enum value naming

Enum values must use lowercase, machine-friendly identifiers. Use `meta:enum` to
provide human-readable display labels for the UI.

**Note:** Enum values cannot contain dots.

```yaml
# Correct
enum:
  - left_aligned
  - center_aligned
meta:enum:
  left_aligned: Left aligned
  center_aligned: Center aligned
examples:
  - left_aligned

# Wrong - using display labels as enum values
enum:
  - Left aligned
  - Center aligned
```

The `examples` value must be the enum value, not the display label.

### Enum values must match JSX component variants

When using class-variance-authority (CVA) or similar libraries in the JSX
component, the variant keys must exactly match the enum values defined in
`component.yml`.

```jsx
// component.yml defines: enum: [left_aligned, center_aligned]
// CVA variants must match:
const variants = cva("base-classes", {
  variants: {
    layout: {
      left_aligned: "text-left", // matches enum value
      center_aligned: "text-center", // matches enum value
    },
  },
});
```

## Slots

Slots allow other components to be embedded within a component. In React, slots
are received as props containing the rendered children.

```yaml
slots:
  content:
    title: Content
  buttons:
    title: Buttons
```

In the JSX component, slots are destructured as props and rendered directly:

```jsx
const Section = ({ width, content }) => {
  return <div className={sectionVariants({ width })}>{content}</div>;
};
```

Use an empty array when the component has no slots:

```yaml
slots: []
```
