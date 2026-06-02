# Hooks

**Source**: [Drupal at Your Fingertips - hooks](https://drupalatyourfingertips.com/hooks)
**Author**: Selwyn Polit

Quick reference for Drupal hook system with practical code examples.

---

## Core Concept

Hooks allow modules to alter and extend Drupal core or other modules without modifying their code. Implement hooks in `.module` files using naming convention `{module_name}_{hook_name}`.

## Form Hooks

**Target specific form**:
```php
function my_module_form_user_login_form_alter(&$form, FormStateInterface $form_state) {
  $form['actions']['submit']['#value'] = t('Sign In');
}
```

**Target all forms**:
```php
function my_module_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  if ($form_id === 'node_event_edit_form') {
    $form['title']['widget'][0]['value']['#required'] = FALSE;
  }
}
```

**Get form ID**: Inspect `$form['#form_id']` or use Devel module.

---

## Entity Hooks

**Before save**:
```php
function my_module_node_presave(NodeInterface $node) {
  if ($node->getType() === 'article') {
    // Auto-populate fields, validate data
    $node->set('field_updated', time());
  }
}
```

**After save**:
```php
function my_module_node_insert(NodeInterface $node) {
  // Send notifications, clear caches
  \Drupal::service('messenger')->addStatus(t('New @type created.', [
    '@type' => $node->getType(),
  ]));
}

function my_module_node_update(NodeInterface $node) {
  // Handle updates differently than inserts
}
```

**Before delete**:
```php
function my_module_node_predelete(NodeInterface $node) {
  // Clean up related data
  \Drupal::database()->delete('my_custom_table')
    ->condition('nid', $node->id())
    ->execute();
}
```

---

## Entity Lifecycle Order

**Save sequence**:
1. `preSave()` method on entity
2. `hook_ENTITY_TYPE_presave()`, `hook_entity_presave()`
3. Storage operation (insert/update)
4. `hook_ENTITY_TYPE_insert()` or `hook_ENTITY_TYPE_update()`
5. `hook_ENTITY_TYPE_insert()`, `hook_entity_insert()`

**Delete sequence**:
1. `hook_ENTITY_TYPE_predelete()`, `hook_entity_predelete()`
2. Storage deletion
3. `hook_ENTITY_TYPE_delete()`, `hook_entity_delete()`

---

## Update Hooks

**Database changes** (run via `drush updb`):
```php
function my_module_update_9001() {
  $schema = \Drupal::database()->schema();
  if (!$schema->indexExists('node_field_data', 'idx_type_created')) {
    $schema->addIndex('node_field_data', 'idx_type_created', ['type', 'created']);
  }
  return t('Added index for better performance.');
}
```

**Batch operations**:
```php
function my_module_update_9002(&$sandbox) {
  if (!isset($sandbox['progress'])) {
    $sandbox['progress'] = 0;
    $sandbox['max'] = \Drupal::entityQuery('node')
      ->condition('type', 'article')
      ->count()
      ->execute();
  }

  $nids = \Drupal::entityQuery('node')
    ->condition('type', 'article')
    ->range($sandbox['progress'], 25)
    ->execute();

  $nodes = \Drupal\node\Entity\Node::loadMultiple($nids);
  foreach ($nodes as $node) {
    $node->set('field_migrated', TRUE);
    $node->save();
    $sandbox['progress']++;
  }

  $sandbox['#finished'] = $sandbox['progress'] / $sandbox['max'];
}
```

**Numbering**: Use 9001+, increment by 1. Track in key_value table.

---

## Theme Hooks

**Preprocess variables** for templates:
```php
function my_theme_preprocess_node(&$variables) {
  $node = $variables['elements']['#node'];

  // Add custom variables
  $variables['custom_date'] = \Drupal::service('date.formatter')
    ->format($node->getCreatedTime(), 'custom', 'M d, Y');

  // Modify render arrays
  $variables['content']['field_image']['#suffix'] = '<p class="caption">Image caption</p>';
}
```

**Preprocessing order**:
1. `template_preprocess()`
2. `template_preprocess_HOOK()`
3. `MODULE_preprocess()`
4. `MODULE_preprocess_HOOK()`
5. `THEME_preprocess()`
6. `THEME_preprocess_HOOK()`

**Access in Twig**: `{{ custom_date }}`

---

## Commonly Used Hooks

| Hook | Purpose | File Location |
|------|---------|---------------|
| `hook_form_alter` | Modify any form | `.module` |
| `hook_form_FORM_ID_alter` | Modify specific form | `.module` |
| `hook_entity_presave` | Before entity save | `.module` |
| `hook_entity_insert` | After entity create | `.module` |
| `hook_entity_update` | After entity update | `.module` |
| `hook_entity_delete` | After entity delete | `.module` |
| `hook_preprocess_HOOK` | Prepare template vars | `.theme` |
| `hook_update_N` | Database updates | `.install` |
| `hook_install` | Module installation | `.install` |
| `hook_uninstall` | Module removal | `.install` |
| `hook_theme` | Register templates | `.module` |

---

---

## OOP Approach (Advanced)

For complex hook logic, use service classes:

```php
// In my_module.services.yml
services:
  my_module.form_handler:
    class: Drupal\my_module\FormHandler
    arguments: ['@current_user', '@entity_type.manager']

// In src/FormHandler.php
class FormHandler implements ContainerInjectionInterface {
  protected $currentUser;
  protected $entityTypeManager;

  public function __construct(AccountProxyInterface $current_user, EntityTypeManagerInterface $entity_type_manager) {
    $this->currentUser = $current_user;
    $this->entityTypeManager = $entity_type_manager;
  }

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('current_user'),
      $container->get('entity_type.manager')
    );
  }

  public function alterLoginForm(&$form, FormStateInterface $form_state) {
    // Complex logic with injected services
  }
}

// In my_module.module
function my_module_form_user_login_form_alter(&$form, FormStateInterface $form_state) {
  \Drupal::service('my_module.form_handler')->alterLoginForm($form, $form_state);
}
```

**Benefits**: Testable, uses DI, cleaner code organization.

---

## Finding Available Hooks

**Documentation locations**:
- Each module's `*.api.php` file (e.g., `node.api.php`, `views.api.php`)
- [Drupal API documentation](https://api.drupal.org)
- Search: "hook_" in `/core/lib/Drupal/Core/*.api.php`

**Common hook patterns**:
- `hook_{entity_type}_{operation}` - Entity operations
- `hook_form_{FORM_ID}_alter` - Specific form modifications
- `hook_preprocess_{HOOK}` - Template preprocessing
- `hook_{module}_{action}` - Module-specific actions

---

## Key Guidelines

✅ **Use specific hooks** - `hook_form_FORM_ID_alter` over `hook_form_alter`
✅ **Type-specific entity hooks** - `hook_node_presave` over `hook_entity_presave`
✅ **Clear cache** - Run `drush cr` after adding new hooks
✅ **Update hooks** - Number sequentially, use batch for large datasets
✅ **Document complex logic** - Add comments explaining why, not what

❌ **Don't modify core** - Always use hooks instead
❌ **Don't use generic hooks unnecessarily** - Impacts performance
❌ **Don't forget hook_update_N return** - Always return message string

---

**Full documentation**: https://drupalatyourfingertips.com/hooks
