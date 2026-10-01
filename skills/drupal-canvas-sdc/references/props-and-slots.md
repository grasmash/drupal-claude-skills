# Props, Validation and Slots

Prop types and their Canvas widgets, schema validation patterns, and slot composition for Twig SDCs.

## Contents

- [Rich Text Props](#rich-text-props)
- [Enum Labels (Human-Readable Dropdowns)](#enum-labels-human-readable-dropdowns)
- [Validation Patterns](#validation-patterns)
- [Slots for Composition](#slots-for-composition)

## Rich Text Props

```yaml
content:
  type: string
  title: Rich Text Content
  contentMediaType: text/html
  x-formatting-context: block  # or 'inline'
  examples: ['<p>Formatted <strong>content</strong></p>']
```

## Enum Labels (Human-Readable Dropdowns)

```yaml
color:
  type: string
  enum: ['primary', 'secondary', 'danger']
  meta:enum:
    primary: "Primary Brand Color"
    secondary: "Secondary Accent"
    danger: "Warning/Error State"
```

## Validation Patterns

### Required Properties

```yaml
props:
  type: object
  required:
    - title
    - url
  properties:
    title:
      type: string
```

### Numeric Constraints

```yaml
spacing:
  type: integer
  minimum: 0
  maximum: 100

heading_level:
  type: integer
  enum: [2, 3, 4, 5, 6]
```

### Nullable Values

```yaml
subtitle:
  type: ['string', 'null']
  title: Optional Subtitle
```

### Array Constraints

```yaml
tags:
  type: array
  items:
    type: string
  minItems: 1
  maxItems: 5
```
## Slots for Composition

Slots accept arbitrary markup or nested components. Props handle typed data; slots handle content.

### Define Slots

```yaml
slots:
  header:
    title: Header Content
    description: Optional header area
  body:
    title: Body Content
  footer: {}  # Minimal definition
```

### Render Slots in Twig

```twig
<article class="card">
  {% if header %}
    <header class="card__header">{{ header }}</header>
  {% endif %}
  <div class="card__body">{{ body }}</div>
  {% if footer %}
    <footer class="card__footer">{{ footer }}</footer>
  {% endif %}
</article>
```

### Populate Slots with Embed

```twig
{% embed 'my_theme:card' with { heading: 'Featured Article' } only %}
  {% block body %}
    {{ content.field_image }}
    <p>{{ content.field_summary }}</p>
    {{ include('my_theme:button', { text: 'Read More', url: url }) }}
  {% endblock %}
{% endembed %}
```

### Populate Slots from PHP

```php
$build = [
  '#type' => 'component',
  '#component' => 'my_theme:card',
  '#props' => ['heading' => $title],
  '#slots' => [
    'body' => ['#markup' => $content],
    'footer' => $footer_render_array,
  ],
];
```
