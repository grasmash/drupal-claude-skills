# Forms

**Source**: [Drupal at Your Fingertips - forms](https://drupalatyourfingertips.com/forms)
**Author**: Selwyn Polit

Quick reference for Drupal Form API with practical code examples.

---

## Core Concept

Forms in Drupal are render arrays with validation and submission handlers. Forms extend `FormBase` or `ConfigFormBase` and implement three required methods: `getFormId()`, `buildForm()`, and `submitForm()`.

## Basic Form Structure

**Minimal form class**:
```php
namespace Drupal\my_module\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;

class ExampleForm extends FormBase {

  public function getFormId() {
    return 'my_module_example_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state) {
    $form['name'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Your Name'),
      '#required' => TRUE,
    ];

    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Submit'),
    ];

    return $form;
  }

  public function submitForm(array &$form, FormStateInterface $form_state) {
    $name = $form_state->getValue('name');
    \Drupal::messenger()->addStatus($this->t('Hello @name!', ['@name' => $name]));
  }
}
```

---

## Common Form Elements

| Element Type | Purpose | Example |
|--------------|---------|---------|
| `textfield` | Single-line text | Name, email (no validation) |
| `email` | Email with validation | Email address |
| `number` | Numeric input | Age, quantity |
| `select` | Dropdown | Category selection |
| `radios` | Radio buttons | Single choice |
| `checkboxes` | Multiple checkboxes | Multi-select |
| `checkbox` | Single checkbox | Accept terms |
| `textarea` | Multi-line text | Description, body |
| `password` | Password field | Credentials |
| `date` | Date picker | Birth date |
| `submit` | Submit button | Save, Update |

**Element example**:
```php
$form['quantity'] = [
  '#type' => 'number',
  '#title' => $this->t('Quantity'),
  '#min' => 0,
  '#max' => 100,
  '#default_value' => 1,
  '#required' => TRUE,
  '#description' => $this->t('Enter quantity (0-100)'),
];

$form['category'] = [
  '#type' => 'select',
  '#title' => $this->t('Category'),
  '#options' => [
    'tech' => $this->t('Technology'),
    'news' => $this->t('News'),
    'sports' => $this->t('Sports'),
  ],
  '#empty_option' => $this->t('- Select -'),
];
```

---

## Form Validation

**Add validation method**:
```php
public function validateForm(array &$form, FormStateInterface $form_state) {
  $name = $form_state->getValue('name');

  if (strlen($name) < 3) {
    $form_state->setErrorByName('name',
      $this->t('Name must be at least 3 characters.')
    );
  }

  $email = $form_state->getValue('email');
  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $form_state->setErrorByName('email',
      $this->t('Invalid email address.')
    );
  }
}
```

**Validation runs before submit** - If `validateForm()` sets errors, `submitForm()` won't execute.

---

## Form Submission

**Access submitted values**:
```php
public function submitForm(array &$form, FormStateInterface $form_state) {
  // Get single value
  $name = $form_state->getValue('name');

  // Get all values
  $values = $form_state->getValues();

  // Create entity
  $node = Node::create([
    'type' => 'article',
    'title' => $values['title'],
    'body' => $values['body'],
  ]);
  $node->save();

  // Show message
  $this->messenger()->addStatus($this->t('Article created.'));

  // Redirect
  $form_state->setRedirect('entity.node.canonical', ['node' => $node->id()]);
}
```

---

## Dependency Injection in Forms

**Inject services**:
```php
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class ExampleForm extends FormBase {

  protected EntityTypeManagerInterface $entityTypeManager;

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('entity_type.manager')
    );
  }

  public function __construct(EntityTypeManagerInterface $entity_type_manager) {
    $this->entityTypeManager = $entity_type_manager;
  }

  public function buildForm(array $form, FormStateInterface $form_state) {
    $storage = $this->entityTypeManager->getStorage('node');
    // Use storage...
  }
}
```

---

## Conditional Fields (#states)

**Show/hide based on other fields**:
```php
$form['show_advanced'] = [
  '#type' => 'checkbox',
  '#title' => $this->t('Show advanced options'),
];

$form['advanced'] = [
  '#type' => 'textarea',
  '#title' => $this->t('Advanced Settings'),
  '#states' => [
    'visible' => [
      ':input[name="show_advanced"]' => ['checked' => TRUE],
    ],
  ],
];
```

**Multiple conditions**:
```php
$form['field'] = [
  '#type' => 'textfield',
  '#states' => [
    'visible' => [
      ':input[name="type"]' => ['value' => 'custom'],
    ],
    'required' => [
      ':input[name="type"]' => ['value' => 'custom'],
    ],
  ],
];
```

---

## AJAX in Forms

**Add AJAX to button**:
```php
$form['category'] = [
  '#type' => 'select',
  '#title' => $this->t('Category'),
  '#options' => ['tech' => 'Tech', 'news' => 'News'],
  '#ajax' => [
    'callback' => '::updateSubcategory',
    'wrapper' => 'subcategory-wrapper',
    'event' => 'change',
  ],
];

$form['subcategory'] = [
  '#type' => 'select',
  '#title' => $this->t('Subcategory'),
  '#prefix' => '<div id="subcategory-wrapper">',
  '#suffix' => '</div>',
];

public function updateSubcategory(array &$form, FormStateInterface $form_state) {
  return $form['subcategory'];
}
```

---

## Configuration Forms

**For storing settings**:
```php
use Drupal\Core\Form\ConfigFormBase;

class SettingsForm extends ConfigFormBase {

  protected function getEditableConfigNames() {
    return ['my_module.settings'];
  }

  public function getFormId() {
    return 'my_module_settings_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state) {
    $config = $this->config('my_module.settings');

    $form['api_key'] = [
      '#type' => 'textfield',
      '#title' => $this->t('API Key'),
      '#default_value' => $config->get('api_key'),
    ];

    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state) {
    $this->config('my_module.settings')
      ->set('api_key', $form_state->getValue('api_key'))
      ->save();

    parent::submitForm($form, $form_state);
  }
}
```

---

## Altering Forms

**In .module file**:
```php
function my_module_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  if ($form_id === 'node_article_edit_form') {
    $form['title']['widget'][0]['value']['#required'] = FALSE;
    $form['body']['#access'] = FALSE;
  }
}

function my_module_form_user_login_form_alter(&$form, FormStateInterface $form_state) {
  $form['actions']['submit']['#value'] = $this->t('Sign In');
}
```

---

---

## Translatable Strings

**Always use $this->t()**:
```php
$form['name'] = [
  '#type' => 'textfield',
  '#title' => $this->t('Name'),
  '#description' => $this->t('Enter your full name.'),
];

$this->messenger()->addStatus(
  $this->t('Welcome @name!', ['@name' => $name])
);
```

---

## Key Guidelines

✅ **Use form classes** - Extend `FormBase` or `ConfigFormBase`
✅ **Validate early** - Implement `validateForm()` for input checking
✅ **Use #states** - For conditional fields without custom JS
✅ **Inject services** - Use DI for entity storage, config
✅ **Translate strings** - Always use `$this->t()`
✅ **Use #required** - For mandatory fields
✅ **Set redirects** - Use `$form_state->setRedirect()`

❌ **Don't process in buildForm** - Only build, don't save data
❌ **Don't skip validation** - Always validate user input
❌ **Don't hardcode strings** - Use translation functions
❌ **Don't use static calls in classes** - Use DI instead
❌ **Don't forget error messages** - Use `setErrorByName()`

---

**Full documentation**: https://drupalatyourfingertips.com/forms
