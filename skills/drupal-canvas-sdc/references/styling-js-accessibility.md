# Component Design, CSS, JavaScript and Accessibility

Atomic design, BEM-scoped CSS, Drupal behaviors and WCAG 2.2 AA patterns for SDCs.

## Contents

- [Atomic Design Principles](#atomic-design-principles)
- [CSS Styling with BEM](#css-styling-with-bem)
- [JavaScript Behaviors](#javascript-behaviors)
- [Accessibility (WCAG 2.2 AA)](#accessibility-wcag-22-aa)

## Atomic Design Principles

- **Atoms**: Buttons, icons, labels, form inputs
- **Molecules**: Cards, media objects, search forms
- **Organisms**: Headers, footers, article teasers
- **Templates**: Page layouts with slots for organisms

### Single Responsibility Pattern

```yaml
# ✅ Good: Single component with variants
name: Button
props:
  type: object
  properties:
    variant:
      type: string
      enum: ['primary', 'secondary', 'outline', 'ghost']
    size:
      type: string
      enum: ['small', 'medium', 'large']
```

```yaml
# ❌ Avoid: Separate components per variant
# button-primary.component.yml
# button-secondary.component.yml
```

## CSS Styling with BEM

**Component-Scoped CSS (CRITICAL)**: NEVER scope styles to route/path body classes (e.g., `.alias--articles`, `.path-some-page`). Instead, scope styles to the component's own classes (e.g., `.view-articles`, `.block-views-blockarticles-block-2`). The Canvas editor renders page previews in an iframe without the page's body classes, so route-scoped styles won't appear there. All styles must be componentized and portable -- they should look correct regardless of what route or context they render in.

SDC auto-attaches CSS when file matches component name. Use BEM for scoped styles:

```css
/* card.css */
.card {
  --card-padding: 1.5rem;
  --card-radius: 0.5rem;
  --card-shadow: 0 2px 8px rgba(0,0,0,0.1);

  display: flex;
  flex-direction: column;
  padding: var(--card-padding);
  border-radius: var(--card-radius);
  box-shadow: var(--card-shadow);
}

.card__header {
  margin-bottom: 1rem;
  font-weight: 700;
}

.card__body {
  flex: 1;
}

.card--featured {
  --card-shadow: 0 4px 16px rgba(0,0,0,0.15);
  border: 2px solid var(--color-primary);
}

.card--compact {
  --card-padding: 1rem;
}
```

### External Dependencies

```yaml
libraryOverrides:
  css:
    component:
      card.css: {}
      additional-styles.css: {}
  dependencies:
    - core/normalize
```

## JavaScript Behaviors

Use Drupal's behavior pattern with `once()`:

```javascript
// accordion.js
((Drupal, once) => {
  Drupal.behaviors.accordion = {
    attach(context) {
      once('accordion', '.accordion__trigger', context).forEach((trigger) => {
        trigger.addEventListener('click', (e) => {
          const panel = document.getElementById(trigger.getAttribute('aria-controls'));
          const expanded = trigger.getAttribute('aria-expanded') === 'true';

          trigger.setAttribute('aria-expanded', !expanded);
          panel.hidden = expanded;
        });
      });
    },
    detach(context, settings, trigger) {
      if (trigger === 'unload') {
        once.remove('accordion', '.accordion__trigger', context);
      }
    }
  };
})(Drupal, once);
```

**Key Patterns**:
- `once()` prevents duplicate event binding
- `context` scopes to newly added DOM
- `attach()` runs on page load and AJAX updates
- `detach()` handles cleanup

## Accessibility (WCAG 2.2 AA)

### Semantic HTML First

```twig
<nav aria-label="Main navigation">
  <ul>
    <li><a href="{{ url }}">{{ label }}</a></li>
  </ul>
</nav>

{# Accessible button with states #}
<button
  type="button"
  aria-expanded="{{ expanded ? 'true' : 'false' }}"
  aria-controls="panel-{{ id }}"
>
  {{ trigger_text }}
</button>

{# Modal dialog #}
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="dialog-title-{{ id }}"
>
  <h2 id="dialog-title-{{ id }}">{{ title }}</h2>
  {{ content }}
</div>

{# Live region for dynamic updates #}
<div aria-live="polite" class="visually-hidden">
  {{ status_message }}
</div>
```

### Keyboard Navigation Checklist

- All interactive elements focusable via Tab
- Visible focus indicators (never `outline: none` without alternative)
- Enter/Space activate buttons and links
- Escape closes modals and dropdowns
- Arrow keys navigate within composite widgets

### Dynamic Announcements

```javascript
Drupal.announce('Form submitted successfully');
Drupal.announce('Error: Please fix the highlighted fields', 'assertive');
```
