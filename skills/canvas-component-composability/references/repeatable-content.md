# Repeatable Content

Use this pattern for lists, grids, carousels, and similar repeatable UI blocks
in Canvas.

## Why this pattern exists

Canvas does not support array props whose items are objects.

- Avoid modeling repeatable cards/items as `type: array` with object `items`
- Model repeatable content with a parent slot and child components instead

## Parent/child slot pattern

1. Create a child component for one repeated item
2. Define a named slot on the parent component
3. Render the named slot prop in parent JSX
4. Compose parent + multiple child instances in stories

### Example pairings

- `footer` + `footer-link-group`
- `footer-link-group` + `footer-link`
- `card-grid` + `card`
- `testimonials` + `testimonial-card`
- `cta-section` + `cta-card`
- `features-section` + `feature-card`
- `stats-hero` + `stat-item`
- `metadata-list` + `metadata-item`
- `carousel` + `carousel-item`

## Slot schema authority

Do not redefine slot schema here. For exact `component.yml` slot rules and
examples (object map vs `slots: []`, slot key naming, and JSX slot consumption),
follow `canvas-component-metadata`.

## Slot container minimum size

When a slot is inside a container that sizes to content (flex items, grid items,
inline elements), the container can collapse to zero size when empty. This can
hide Canvas drop zones.

Add a minimum size to keep slots interactive while empty:

```jsx
const Header = ({ branding, navigation }) => {
  return (
    <header className="flex items-center justify-between">
      <div className="min-w-32">{branding}</div>
      <nav>{navigation}</nav>
    </header>
  );
};
```

Apply minimum sizes when:

- Slot wrapper is a flex item
- Slot wrapper is a grid item
- Slot wrapper is inline/inline-block/inline-flex

Usually not needed when:

- Wrapper already has fixed dimensions
- Wrapper is block-level with full width and stable layout

## Naming child components

- Use descriptive names for specific item types (`feature-card`,
  `testimonial-card`, `team-member`)
- Use `-item` suffix for generic repeated elements (`metadata-item`,
  `carousel-item`, `list-item`)
- Use specific names for link-related items (`footer-link`, `nav-link`,
  `social-link`)
