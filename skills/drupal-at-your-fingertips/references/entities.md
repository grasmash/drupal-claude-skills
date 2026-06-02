# Entities

**Source**: [Drupal at Your Fingertips - entities](https://drupalatyourfingertips.com/entities)
**Author**: Selwyn Polit

Quick reference for Drupal Entity API with practical code examples.

---

## Core Concept

Entities are structured data objects in Drupal. Content entities (nodes, users, taxonomy terms) are fieldable and translatable. Config entities (views, content types) store configuration.

## Loading Entities

**By ID** (using entity class):
```php
$node = \Drupal\node\Entity\Node::load(123);
$user = \Drupal\user\Entity\User::load(1);
$term = \Drupal\taxonomy\Entity\Term::load(5);
```

**Multiple by IDs**:
```php
$nodes = \Drupal\node\Entity\Node::loadMultiple([1, 2, 3]);
```

**By property** (returns array):
```php
$nodes = \Drupal::entityTypeManager()
  ->getStorage('node')
  ->loadByProperties(['title' => 'My Article']);
```

**By UUID** (required for your project APIs):
```php
$entities = \Drupal::entityTypeManager()
  ->getStorage('node')
  ->loadByProperties(['uuid' => $uuid]);
$node = !empty($entities) ? reset($entities) : NULL;
```

---

## Entity Queries

**Basic query**:
```php
$storage = \Drupal::entityTypeManager()->getStorage('node');
$query = $storage->getQuery()
  ->accessCheck(FALSE)  // Explicitly disable access checks
  ->condition('type', 'article')
  ->condition('status', 1)
  ->sort('created', 'DESC')
  ->range(0, 10);

$nids = $query->execute();
$nodes = $storage->loadMultiple($nids);
```

**With relationships**:
```php
$query = $storage->getQuery()
  ->accessCheck(TRUE)
  ->condition('field_category.entity.name', 'Technology');
```

**Count query**:
```php
$count = $storage->getQuery()
  ->accessCheck(FALSE)
  ->condition('type', 'article')
  ->count()
  ->execute();
```

**IMPORTANT**: Always explicitly specify `accessCheck(TRUE)` or `accessCheck(FALSE)`.

---

## Creating Entities

**Preferred method** (using entity class):
```php
$node = \Drupal\node\Entity\Node::create([
  'type' => 'article',
  'title' => 'My New Article',
  'body' => [
    'value' => '<p>Article content</p>',
    'format' => 'basic_html',
  ],
  'field_tags' => [1, 2, 3],  // Term IDs
  'status' => 1,
  'uid' => \Drupal::currentUser()->id(),
]);
$node->save();
```

**With entity references**:
```php
$node = Node::create([
  'type' => 'article',
  'title' => 'Article with Image',
  'field_image' => [
    'target_id' => $file->id(),
    'alt' => 'Image alt text',
    'title' => 'Image title',
  ],
]);
$node->save();
```

---

## Updating Entities

**Simple field update**:
```php
$node = Node::load(123);
$node->set('title', 'Updated Title');
$node->set('field_category', $term->id());
$node->save();
```

**Multi-value field**:
```php
$node->field_tags->setValue([
  ['target_id' => 1],
  ['target_id' => 2],
  ['target_id' => 3],
]);
$node->save();
```

**Append to multi-value field**:
```php
$node->field_tags[] = ['target_id' => 4];
$node->save();
```

---

## Deleting Entities

**Single delete**:
```php
$node = Node::load(123);
$node->delete();
```

**Bulk delete**:
```php
$storage = \Drupal::entityTypeManager()->getStorage('node');
$entities = $storage->loadByProperties(['type' => 'article']);
$storage->delete($entities);
```

**IMPORTANT**: Use `hook_ENTITY_TYPE_predelete()` to clean up related data.

---

## Field Access & Manipulation

**Get field value**:
```php
// Simple field
$title = $node->get('title')->value;
$status = $node->get('status')->value;

// Entity reference
$category_id = $node->get('field_category')->target_id;
$category = $node->get('field_category')->entity;

// Multi-value field
foreach ($node->get('field_tags') as $item) {
  $term_id = $item->target_id;
  $term = $item->entity;
}
```

**Check if field has value**:
```php
if (!$node->get('field_image')->isEmpty()) {
  $image_url = $node->get('field_image')->entity->uri->value;
}
```

**Get referenced entity**:
```php
$author = $node->get('uid')->entity;  // User entity
$category = $node->get('field_category')->entity;  // Term entity
```

---

## Entity Type & Bundle Checks

**Check entity type**:
```php
if ($entity instanceof \Drupal\Core\Entity\ContentEntityInterface) {
  // It's a content entity
}

if ($entity->getEntityTypeId() === 'node') {
  // It's a node
}
```

**Check bundle**:
```php
if ($entity->getEntityTypeId() === 'node' && $entity->bundle() === 'article') {
  // It's an article node
}
```

---

## Common Entity Methods

| Method | Purpose | Returns |
|--------|---------|---------|
| `id()` | Get entity ID | Integer |
| `uuid()` | Get UUID | String |
| `label()` | Get entity label | String |
| `bundle()` | Get bundle (e.g., 'article') | String |
| `isNew()` | Check if unsaved | Boolean |
| `save()` | Persist to database | Integer |
| `delete()` | Remove from database | Void |
| `get($field)` | Get field object | FieldItemList |
| `set($field, $value)` | Set field value | $this |
| `hasField($field)` | Check field exists | Boolean |
| `toArray()` | Export field values | Array |
| `getEntityTypeId()` | Get type (e.g., 'node') | String |
| `access($op, $account)` | Check access | Boolean |

---

---

## Entity Validation

**Add field constraints**:
```php
function gg_example_entity_bundle_field_info_alter(&$fields, EntityTypeInterface $entity_type, $bundle) {
  if ($entity_type->id() === 'node' && $bundle === 'song') {
    if (!empty($fields['field_difficulty'])) {
      $fields['field_difficulty']->setPropertyConstraints('value', [
        'Range' => ['min' => 1, 'max' => 5],
      ]);
    }
  }
}
```

**Validate before save**:
```php
$violations = $node->validate();
if ($violations->count() > 0) {
  foreach ($violations as $violation) {
    \Drupal::messenger()->addError($violation->getMessage());
  }
  return;
}
$node->save();
```

---

## Dependency Injection Pattern

**In controllers/services**:
```php
use Drupal\Core\Entity\EntityTypeManagerInterface;

class MyController extends ControllerBase {
  protected EntityTypeManagerInterface $entityTypeManager;

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('entity_type.manager')
    );
  }

  public function __construct(EntityTypeManagerInterface $entity_type_manager) {
    $this->entityTypeManager = $entity_type_manager;
  }

  public function buildList() {
    $storage = $this->entityTypeManager->getStorage('node');
    $nodes = $storage->loadByProperties(['type' => 'article']);
    // ...
  }
}
```

---

## Key Guidelines

✅ **Use entity classes** - `Node::load()` over `entity_load('node')`
✅ **Always specify accessCheck** - Explicitly set TRUE or FALSE
✅ **Use UUIDs for APIs** - Never expose internal IDs
✅ **Load by properties for UUID** - `loadByProperties(['uuid' => $uuid])`
✅ **Check isEmpty()** - Before accessing field values
✅ **Use DI in classes** - Inject entity_type.manager service
✅ **Validate before save** - Use `$entity->validate()`

❌ **Don't use entity_load()** - Deprecated, use entity classes
❌ **Don't skip accessCheck** - Required in Drupal 10+
❌ **Don't expose internal IDs** - Security risk in APIs
❌ **Don't assume field exists** - Use `hasField()` first
❌ **Don't forget to save** - Changes aren't persisted until `save()`

---

**Full documentation**: https://drupalatyourfingertips.com/entities
