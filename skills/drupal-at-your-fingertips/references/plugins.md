# Plugins

**Source**: [Drupal at Your Fingertips - plugins](https://drupalatyourfingertips.com/plugins)
**Author**: Selwyn Polit

Quick reference for Drupal plugin system with practical code examples.

---

## Core Concept

Plugins are reusable, swappable components for similar functionality (blocks, field formatters, field widgets). Modules define plugin types, and other modules provide implementations via annotations.

## Basic Plugin Structure

**Block plugin example** (src/Plugin/Block/ExampleBlock.php):
```php
namespace Drupal\my_module\Plugin\Block;

use Drupal\Core\Block\BlockBase;

/**
 * Provides an example block.
 *
 * @Block(
 *   id = "my_module_example",
 *   admin_label = @Translation("Example Block"),
 *   category = @Translation("Custom")
 * )
 */
class ExampleBlock extends BlockBase {

  public function build() {
    return [
      '#markup' => $this->t('Hello from custom block!'),
    ];
  }
}
```

---

## Plugin with Configuration

**Configurable block**:
```php
/**
 * @Block(
 *   id = "configurable_block",
 *   admin_label = @Translation("Configurable Block")
 * )
 */
class ConfigurableBlock extends BlockBase {

  public function defaultConfiguration() {
    return [
      'message' => '',
    ];
  }

  public function blockForm($form, FormStateInterface $form_state) {
    $form['message'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Message'),
      '#default_value' => $this->configuration['message'],
    ];
    return $form;
  }

  public function blockSubmit($form, FormStateInterface $form_state) {
    $this->configuration['message'] = $form_state->getValue('message');
  }

  public function build() {
    return [
      '#markup' => $this->configuration['message'],
    ];
  }
}
```

---

## Plugin with Dependency Injection

**Inject services**:
```php
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Drupal\Core\Session\AccountProxyInterface;

/**
 * @Block(
 *   id = "user_info_block",
 *   admin_label = @Translation("User Info Block")
 * )
 */
class UserInfoBlock extends BlockBase implements ContainerFactoryPluginInterface {

  protected AccountProxyInterface $currentUser;

  public static function create(
    ContainerInterface $container,
    array $configuration,
    $plugin_id,
    $plugin_definition
  ) {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('current_user')
    );
  }

  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    AccountProxyInterface $current_user
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
    $this->currentUser = $current_user;
  }

  public function build() {
    return [
      '#markup' => $this->t('Welcome @name', [
        '@name' => $this->currentUser->getAccountName(),
      ]),
    ];
  }
}
```

---

## Common Plugin Types

| Type | Base Class | Purpose |
|------|------------|---------|
| Block | `BlockBase` | Blocks for layout |
| Field Formatter | `FormatterBase` | Display field values |
| Field Widget | `WidgetBase` | Edit field values |
| Field Type | `FieldItemBase` | Custom field storage |
| Action | `ActionBase` | Bulk operations |
| Condition | `ConditionPluginBase` | Boolean conditions |
| Filter | `FilterBase` | Text filters |

---

## Custom Field Type

**Field type** (stores the data):
```php
/**
 * @FieldType(
 *   id = "color",
 *   label = @Translation("Color"),
 *   default_widget = "color_widget",
 *   default_formatter = "color_formatter"
 * )
 */
class ColorItem extends FieldItemBase {

  public static function propertyDefinitions(FieldStorageDefinitionInterface $field_definition) {
    $properties['value'] = DataDefinition::create('string')
      ->setLabel(t('Color value'));

    return $properties;
  }

  public static function schema(FieldStorageDefinitionInterface $field_definition) {
    return [
      'columns' => [
        'value' => [
          'type' => 'varchar',
          'length' => 7,
        ],
      ],
    ];
  }

  public function isEmpty() {
    $value = $this->get('value')->getValue();
    return $value === NULL || $value === '';
  }
}
```

**Field widget**:
```php
/**
 * @FieldWidget(
 *   id = "color_widget",
 *   label = @Translation("Color picker"),
 *   field_types = {"color"}
 * )
 */
class ColorWidget extends WidgetBase {

  public function formElement(FieldItemListInterface $items, $delta, array $element, array &$form, FormStateInterface $form_state) {
    $element['value'] = $element + [
      '#type' => 'color',
      '#default_value' => $items[$delta]->value ?? '#000000',
    ];

    return $element;
  }
}
```

**Field formatter**:
```php
/**
 * @FieldFormatter(
 *   id = "color_formatter",
 *   label = @Translation("Color swatch"),
 *   field_types = {"color"}
 * )
 */
class ColorFormatter extends FormatterBase {

  public function viewElements(FieldItemListInterface $items, $langcode) {
    $elements = [];

    foreach ($items as $delta => $item) {
      $elements[$delta] = [
        '#markup' => '<div style="background-color: ' . $item->value . '; width: 50px; height: 50px;"></div>',
      ];
    }

    return $elements;
  }
}
```

---

## Plugin Discovery

**List all plugins of a type**:
```php
$plugin_manager = \Drupal::service('plugin.manager.block');
$definitions = $plugin_manager->getDefinitions();

foreach ($definitions as $plugin_id => $definition) {
  echo $plugin_id . ': ' . $definition['admin_label'] . "\n";
}
```

**Instantiate plugin**:
```php
$plugin_manager = \Drupal::service('plugin.manager.block');
$config = ['message' => 'Hello'];
$instance = $plugin_manager->createInstance('my_module_example', $config);
$build = $instance->build();
```

---

## Plugin Derivatives

**Create multiple plugins from one class**:
```php
namespace Drupal\my_module\Plugin\Derivative;

use Drupal\Component\Plugin\Derivative\DeriverBase;

class MenuBlockDeriver extends DeriverBase {

  public function getDerivativeDefinitions($base_plugin_definition) {
    $menus = \Drupal::entityTypeManager()->getStorage('menu')->loadMultiple();

    foreach ($menus as $menu_id => $menu) {
      $this->derivatives[$menu_id] = $base_plugin_definition;
      $this->derivatives[$menu_id]['admin_label'] = $menu->label() . ' menu';
    }

    return $this->derivatives;
  }
}
```

**Use in annotation**:
```php
/**
 * @Block(
 *   id = "menu_block",
 *   admin_label = @Translation("Menu block"),
 *   deriver = "Drupal\my_module\Plugin\Derivative\MenuBlockDeriver"
 * )
 */
```

---

## Debugging Plugins

**List available plugins**:
```bash
drush ev 'dump(\Drupal::service("plugin.manager.block")->getDefinitions());'
```

**Generate plugin code**:
```bash
drush generate plugin:block
drush generate plugin:field:type
drush generate plugin:field:widget
drush generate plugin:field:formatter
```

---

---

## Key Guidelines

✅ **Use annotations** - Document plugin metadata
✅ **Extend base classes** - Use framework-provided bases
✅ **Implement interfaces** - ContainerFactoryPluginInterface for DI
✅ **Use derivatives** - For dynamic plugin sets
✅ **Cache access** - Implement getCacheContexts/Tags/MaxAge
✅ **Generate code** - Use drush generate for scaffolding
✅ **Follow naming** - Plugin ID = module_name.suffix

❌ **Don't hardcode** - Use configuration for variable data
❌ **Don't skip validation** - Validate configuration input
❌ **Don't forget caching** - Implement cache methods
❌ **Don't use static calls** - Inject dependencies
❌ **Don't duplicate** - Use derivatives instead of similar plugins

---

**Full documentation**: https://drupalatyourfingertips.com/plugins
