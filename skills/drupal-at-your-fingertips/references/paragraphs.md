# Paragraphs

**Source**: [Drupal at Your Fingertips - paragraphs](https://drupalatyourfingertips.com/paragraphs)
**Author**: Selwyn Polit

Quick reference for Drupal Paragraphs module with practical code examples.

---

## Core Concept

Paragraphs are reusable content components embedded within nodes. They function like mini-entities with their own fields, allowing flexible page layouts by mixing different paragraph types (text, image, video, etc.) in a single field. Uses Entity Reference Revisions for versioning.

## Creating Paragraph Types

**Via UI**:
1. Navigate to `/admin/structure/paragraphs_type`
2. Add paragraph type (e.g., "Text Block", "Image + Caption", "Call to Action")
3. Add fields to the paragraph type
4. Configure display modes

**Common paragraph types**:
- Text block (body field)
- Image with caption (image + text)
- Video embed (video URL + description)
- Call to action (title + link + button style)
- Accordion item (title + body + collapsed state)

---

## Adding Paragraphs Field to Content Type

**Field settings**:
```
Field type: Entity reference revisions
Reference type: Paragraph
Allowed paragraph types: Select which types
Number of values: Unlimited
```

**Important**: Use Entity Reference Revisions field type, not standard Entity Reference.

---

## Programmatic Access

**Load paragraphs from node**:
```php
use Drupal\paragraphs\Entity\Paragraph;

$node = Node::load(123);

// Get paragraph field
$paragraphs = $node->get('field_paragraphs')->referencedEntities();

foreach ($paragraphs as $paragraph) {
  // Get paragraph type
  $type = $paragraph->getType();

  // Access paragraph fields
  if ($type === 'text_block') {
    $title = $paragraph->get('field_title')->value;
    $body = $paragraph->get('field_body')->value;
  }

  if ($type === 'image_caption') {
    $image = $paragraph->get('field_image')->entity;
    $caption = $paragraph->get('field_caption')->value;
  }
}
```

**Access specific paragraph**:
```php
// Get first paragraph
$first_paragraph = $node->get('field_paragraphs')->first()->entity;

// Get paragraph by index
$second_paragraph = $node->get('field_paragraphs')[1]->entity;

// Check if paragraph exists
if (!$node->get('field_paragraphs')->isEmpty()) {
  $paragraph = $node->get('field_paragraphs')->first()->entity;
}
```

---

## Entity Reference Revisions

**Important distinction**:
```php
// CORRECT - Use target_revision_id for paragraphs
$revision_id = $node->get('field_paragraphs')[0]->target_revision_id;

// WRONG - Don't use target_id alone
$id = $node->get('field_paragraphs')[0]->target_id;  // ❌

// WRONG - Don't use .value
$value = $node->get('field_paragraphs')[0]->value;  // Returns NULL
```

**Load by revision ID**:
```php
use Drupal\paragraphs\Entity\Paragraph;

$revision_id = $node->get('field_paragraphs')[0]->target_revision_id;
$paragraph = Paragraph::load($revision_id);
```

---

## Creating Paragraphs Programmatically

**Create and attach paragraph**:
```php
use Drupal\paragraphs\Entity\Paragraph;

// Create paragraph
$paragraph = Paragraph::create([
  'type' => 'text_block',
  'field_title' => 'My Title',
  'field_body' => [
    'value' => '<p>My content</p>',
    'format' => 'full_html',
  ],
]);
$paragraph->save();

// Attach to node
$node = Node::load(123);
$node->get('field_paragraphs')->appendItem($paragraph);
$node->save();
```

**Create multiple paragraphs**:
```php
$paragraphs = [];

// Create text paragraph
$text_paragraph = Paragraph::create([
  'type' => 'text_block',
  'field_title' => 'Section 1',
  'field_body' => ['value' => 'Content...', 'format' => 'full_html'],
]);
$text_paragraph->save();
$paragraphs[] = $text_paragraph;

// Create image paragraph
$image_paragraph = Paragraph::create([
  'type' => 'image_caption',
  'field_image' => ['target_id' => $file_id],
  'field_caption' => 'Image caption',
]);
$image_paragraph->save();
$paragraphs[] = $image_paragraph;

// Attach all to node
$node->set('field_paragraphs', $paragraphs);
$node->save();
```

---

## Nested Paragraphs

**Paragraph within paragraph**:
```php
// Create inner paragraph
$inner = Paragraph::create([
  'type' => 'text_block',
  'field_title' => 'Inner Content',
]);
$inner->save();

// Create outer paragraph with reference to inner
$outer = Paragraph::create([
  'type' => 'container',
  'field_paragraphs' => [$inner],  // Reference inner paragraph
]);
$outer->save();

// Access nested paragraphs
$outer_paragraph = $node->get('field_paragraphs')->first()->entity;
$inner_paragraphs = $outer_paragraph->get('field_paragraphs')->referencedEntities();
```

---

## Updating Paragraphs

**Update existing paragraph**:
```php
$paragraph = $node->get('field_paragraphs')->first()->entity;
$paragraph->set('field_title', 'Updated Title');
$paragraph->save();

// Node doesn't need to be re-saved for paragraph updates
```

**Replace paragraph**:
```php
// Remove old paragraph
$old_paragraph = $node->get('field_paragraphs')[0]->entity;

// Create new paragraph
$new_paragraph = Paragraph::create([
  'type' => 'text_block',
  'field_title' => 'New Content',
]);
$new_paragraph->save();

// Replace in node
$node->get('field_paragraphs')[0] = $new_paragraph;
$node->save();
```

---

## Rendering Paragraphs

**In Twig templates**:
```twig
{# Render all paragraphs #}
{{ content.field_paragraphs }}

{# Render specific paragraph #}
{{ content.field_paragraphs.0 }}

{# Loop through paragraphs #}
{% for paragraph in node.field_paragraphs %}
  <div class="paragraph paragraph--{{ paragraph.entity.bundle }}">
    {{ paragraph.entity.field_title.value }}
    {{ paragraph.entity.field_body.value|raw }}
  </div>
{% endfor %}

{# Check paragraph type #}
{% for paragraph in node.field_paragraphs %}
  {% if paragraph.entity.bundle == 'text_block' %}
    <div class="text-block">
      {{ paragraph.entity.field_body.value|raw }}
    </div>
  {% elseif paragraph.entity.bundle == 'image_caption' %}
    <figure>
      <img src="{{ paragraph.entity.field_image.entity.uri.value|file_url }}" />
      <figcaption>{{ paragraph.entity.field_caption.value }}</figcaption>
    </figure>
  {% endif %}
{% endfor %}
```

---

## Accessing Entity References in Paragraphs

**Taxonomy terms**:
```php
$paragraph = $node->get('field_paragraphs')->first()->entity;

// Get referenced terms
$terms = $paragraph->get('field_tags')->referencedEntities();

foreach ($terms as $term) {
  $term_name = $term->label();
  $term_id = $term->id();
}
```

**In Twig**:
```twig
{% for paragraph in node.field_paragraphs %}
  {% for tag in paragraph.entity.field_tags %}
    <span class="tag">{{ tag.entity.label }}</span>
  {% endfor %}
{% endfor %}
```

---

## Validation

**Validate paragraph fields**:
```php
function my_module_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  if ($form_id === 'node_article_edit_form') {
    $form['#validate'][] = 'my_module_validate_paragraphs';
  }
}

function my_module_validate_paragraphs(array &$form, FormStateInterface $form_state) {
  $paragraphs = $form_state->getValue('field_paragraphs');

  foreach ($paragraphs as $delta => $item) {
    if (isset($item['subform'])) {
      // Validate paragraph field
      $title = $item['subform']['field_title'][0]['value'];

      if (empty($title)) {
        $form_state->setErrorByName(
          "field_paragraphs][$delta][subform][field_title",
          t('Title is required.')
        );
      }
    }
  }
}
```

---

## Deleting Paragraphs

**Remove paragraph from node**:
```php
$node = Node::load(123);

// Remove first paragraph
$node->get('field_paragraphs')->removeItem(0);
$node->save();

// Remove all paragraphs
$node->set('field_paragraphs', []);
$node->save();
```

**Delete paragraph entity**:
```php
$paragraph = Paragraph::load($paragraph_id);
$paragraph->delete();
```

---

## View Modes for Paragraphs

**Configure view modes** at `/admin/structure/display-modes/view`

**Render with specific view mode**:
```php
$view_builder = \Drupal::entityTypeManager()->getViewBuilder('paragraph');

$paragraph = $node->get('field_paragraphs')->first()->entity;
$build = $view_builder->view($paragraph, 'teaser');

return $build;
```

---

## Query Paragraphs

**Find nodes with specific paragraph type**:
```php
$query = \Drupal::entityQuery('node')
  ->condition('type', 'article')
  ->accessCheck(FALSE);

// Join to paragraph field table
$query->condition('field_paragraphs.entity.type', 'text_block');

$nids = $query->execute();
```

---

---

## Key Guidelines

✅ **Use Entity Reference Revisions** - Required field type
✅ **Use target_revision_id** - For paragraph references
✅ **Use referencedEntities()** - To load paragraphs
✅ **Create logical paragraph types** - Text, image, video, etc.
✅ **Use view modes** - For different display contexts
✅ **Save paragraph before attaching** - Call $paragraph->save()
✅ **Check paragraph type** - Before accessing type-specific fields
✅ **Use paragraphs for flexibility** - Better than fixed layouts

❌ **Don't use target_id alone** - Use target_revision_id
❌ **Don't use .value on references** - Returns NULL
❌ **Don't forget to save paragraphs** - Before attaching to nodes
❌ **Don't hardcode paragraph order** - Allow reordering in UI
❌ **Don't nest too deeply** - Max 2-3 levels
❌ **Don't mix paragraph types carelessly** - Group related types
❌ **Don't skip validation** - Validate required fields

---

**Full documentation**: https://drupalatyourfingertips.com/paragraphs
