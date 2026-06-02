# Slots in content-sized containers need a minimum size

When outputting a slot inside a container that sizes based on its content (flex
items, grid items, inline elements, etc.), the container will collapse to zero
dimensions when the slot is empty. This prevents the Drupal Canvas editor from
showing instrumentation overlays to place components into that slot.

## The problem

Consider this component with a `branding` slot:

```jsx
// ❌ PROBLEM: Container collapses when slot is empty
const Header = ({ branding, navigation }) => {
  return (
    <header className="flex items-center justify-between">
      <div>{branding}</div>
      <nav>{navigation}</nav>
    </header>
  );
};
```

When the `branding` slot is empty, its surrounding `<div>` has no width because
flex items size to their content. The Canvas editor can't display drop zone
instrumentation for a zero-width element. (The _Layers_ panel will still work,
but the visual editor overlay won't.)

## The solution

Add a minimum size to slot containers so they remain interactive even when
empty:

```jsx
// ✅ GOOD: Minimum width ensures the slot is always interactive
const Header = ({ branding, navigation }) => {
  return (
    <header className="flex items-center justify-between">
      <div className="min-w-32">{branding}</div>
      <nav>{navigation}</nav>
    </header>
  );
};
```

## When to apply minimum sizes

Add minimum dimensions to slot containers when they are:

- **Flex items** (`flex` parent) — use `min-w-*` for horizontal layouts,
  `min-h-*` for vertical layouts
- **Grid items** (`grid` parent) — use `min-w-*` and/or `min-h-*` as needed
- **Inline elements** (`inline`, `inline-block`, `inline-flex`) — use `min-w-*`

Choose a minimum size that makes sense for the expected content.

## When minimum sizes are NOT needed

You don't need to add minimum sizes when:

- The slot container has a fixed width/height already
- The container uses `block` layout (full width by default)
- The slot is the only content and the parent has defined dimensions
