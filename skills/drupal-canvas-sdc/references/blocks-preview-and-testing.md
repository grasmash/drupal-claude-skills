# Traditional Blocks in Canvas Preview, and Testing SDCs

Making traditional Drupal blocks preview in Canvas, how they compare to SDCs, and how to test SDC components.

## Contents

- [Canvas Preview for Traditional Blocks](#canvas-preview-for-traditional-blocks)
- [SDC vs Traditional Blocks Comparison](#sdc-vs-traditional-blocks-comparison)
- [Testing SDC Components](#testing-sdc-components)

## Canvas Preview for Traditional Blocks

**CRITICAL**: Canvas renders block previews in iframes that only include CSS from explicitly attached libraries.

### Problem

Traditional Drupal blocks relying on theme global SCSS won't show styles in Canvas previews.

### Solution Pattern

1. **Create standalone CSS file** in module's `css/` directory
2. **Add library** to module's `.libraries.yml`
3. **Attach library** via `#attached` in block's `build()` method

```php
// In BlockClass.php build() method
public function build() {
  return [
    '#theme' => 'my_block_template',
    '#variables' => $variables,
    '#attached' => [
      'library' => [
        'my_module/my_block_styles',
      ],
    ],
  ];
}
```

```yaml
# my_module.libraries.yml
my_block_styles:
  version: VERSION
  css:
    theme:
      css/my-block.css: {}
```

### CSS Compilation for Standalone Files

When extracting from theme SCSS, compile variables to hardcoded values:

```css
/* Compiled from SCSS - replace variables */
.my-component {
  max-width: 1440px;  /* was $max-content-width */
  color: #7d11ff;     /* was $primary-color */
}
```

### Blocks That Return Empty

Blocks returning empty arrays `[]` won't preview in Canvas. Always render the template structure:

```php
public function build() {
  // Always return template for Canvas preview support
  return [
    '#theme' => 'my_block_template',
    '#content' => $content ?? NULL,
    '#attached' => [
      'library' => ['my_module/my_block'],
    ],
    '#cache' => ['contexts' => ['user']],
  ];
}
```

## SDC vs Traditional Blocks Comparison

| Feature | SDC Component | Traditional Block |
|---------|---------------|-------------------|
| CSS Loading | Auto-attached | Must use `#attached` |
| Canvas Preview | Automatic with `examples` | Requires explicit library |
| Props/Config | JSON Schema in YAML | Block configuration form |
| Template | `.twig` (no `.html.twig`) | `.html.twig` |
| Location | `components/` directory | `src/Plugin/Block/` |
| Reusability | High (theme-agnostic) | Module-specific |

## Testing SDC Components

### PHPUnit Kernel Tests

```php
namespace Drupal\Tests\my_module\Kernel;

use Drupal\KernelTests\KernelTestBase;

class CardComponentTest extends KernelTestBase {
  protected static $modules = ['system', 'sdc'];

  public function testCardRendering() {
    $build = [
      '#type' => 'component',
      '#component' => 'my_theme:card',
      '#props' => ['heading' => 'Test'],
    ];
    $output = \Drupal::service('renderer')->renderRoot($build);
    $this->assertStringContainsString('Test', (string) $output);
  }
}
```

### Storybook Integration

```javascript
// card.stories.js
export default {
  title: 'Molecules/Card',
  component: 'my_theme:card',
};

export const Default = {
  args: {
    heading: 'Card Title',
    body: '<p>Card content goes here</p>',
  },
};

export const Featured = {
  args: {
    heading: 'Featured Card',
    variant: 'featured',
  },
};
```
