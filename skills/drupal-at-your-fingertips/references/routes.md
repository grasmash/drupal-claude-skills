# Routes & Controllers

**Source**: [Drupal at Your Fingertips - routes](https://drupalatyourfingertips.com/routes)
**Author**: Selwyn Polit

Quick reference for Drupal routing and controllers with practical code examples.

---

## Core Concept

Routes map URLs to controller methods. Defined in `my_module.routing.yml`, they specify path, controller, title, and access requirements.

## Basic Route Definition

**In my_module.routing.yml**:
```yaml
my_module.hello:
  path: '/hello'
  defaults:
    _controller: '\Drupal\my_module\Controller\HelloController::hello'
    _title: 'Hello Page'
  requirements:
    _permission: 'access content'
```

**Controller** (src/Controller/HelloController.php):
```php
namespace Drupal\my_module\Controller;

use Drupal\Core\Controller\ControllerBase;

class HelloController extends ControllerBase {

  public function hello() {
    return [
      '#markup' => $this->t('Hello World!'),
    ];
  }
}
```

---

## Route Parameters

**Dynamic URL segments**:
```yaml
my_module.user_page:
  path: '/user/{user}/profile'
  defaults:
    _controller: '\Drupal\my_module\Controller\UserController::viewProfile'
    _title: 'User Profile'
  requirements:
    _permission: 'access user profiles'
    user: \d+  # Numeric only
```

**Controller receives parameters**:
```php
public function viewProfile($user) {
  $user_entity = User::load($user);

  if (!$user_entity) {
    throw new \Symfony\Component\HttpKernel\Exception\NotFoundHttpException();
  }

  return [
    '#markup' => $this->t('Profile for @name', [
      '@name' => $user_entity->getDisplayName(),
    ]),
  ];
}
```

**Auto-upcasting** (load entity from parameter):
```yaml
my_module.node_custom:
  path: '/node/{node}/custom'
  defaults:
    _controller: '\Drupal\my_module\Controller\NodeController::customView'
  requirements:
    _permission: 'access content'
  options:
    parameters:
      node:
        type: entity:node
```

```php
use Drupal\node\NodeInterface;

public function customView(NodeInterface $node) {
  // $node is automatically loaded
  return [
    '#markup' => $this->t('Node title: @title', [
      '@title' => $node->getTitle(),
    ]),
  ];
}
```

---

## Access Control

**Permission-based**:
```yaml
requirements:
  _permission: 'administer site configuration'
```

**Multiple permissions** (OR logic with +):
```yaml
requirements:
  _permission: 'edit own content+administer content'
```

**Role-based**:
```yaml
requirements:
  _role: 'administrator+editor'
```

**Custom access check**:
```yaml
requirements:
  _custom_access: '\Drupal\my_module\Controller\MyController::checkAccess'
```

```php
public function checkAccess() {
  $user = \Drupal::currentUser();
  return AccessResult::allowedIf($user->id() > 1);
}
```

---

## Dynamic Page Titles

**Title callback**:
```yaml
my_module.dynamic_title:
  path: '/content/{node}'
  defaults:
    _controller: '\Drupal\my_module\Controller\ContentController::view'
    _title_callback: '\Drupal\my_module\Controller\ContentController::getTitle'
```

```php
public function getTitle(NodeInterface $node) {
  return $this->t('@title Details', ['@title' => $node->getTitle()]);
}
```

---

## Returning Different Response Types

**Render array** (most common):
```php
public function buildPage() {
  return [
    '#theme' => 'my_template',
    '#data' => $this->getData(),
  ];
}
```

**JSON response**:
```php
use Symfony\Component\HttpFoundation\JsonResponse;

public function apiEndpoint() {
  $data = [
    'status' => 'success',
    'items' => $this->getItems(),
  ];

  return new JsonResponse($data, 200, [
    'Cache-Control' => 'no-cache, must-revalidate',
  ]);
}
```

**Redirect**:
```php
use Symfony\Component\HttpFoundation\RedirectResponse;
use Drupal\Core\Url;

public function redirectExample() {
  $url = Url::fromRoute('my_module.other_page');
  return new RedirectResponse($url->toString());
}
```

**File download**:
```php
use Symfony\Component\HttpFoundation\BinaryFileResponse;

public function downloadFile() {
  $file_path = '/path/to/file.pdf';
  return new BinaryFileResponse($file_path);
}
```

---

## ControllerBase Shortcuts

**No DI required for these**:
```php
class MyController extends ControllerBase {

  public function buildPage() {
    // Entity storage
    $storage = $this->entityTypeManager()->getStorage('node');

    // Current user
    $user = $this->currentUser();

    // Configuration
    $config = $this->config('system.site');

    // Messenger
    $this->messenger()->addStatus($this->t('Message'));

    // Module handler
    $this->moduleHandler()->moduleExists('views');

    // Form builder
    $form = $this->formBuilder()->getForm('Drupal\my_module\Form\MyForm');

    return $form;
  }
}
```

---

## Route Options

**Disable caching**:
```yaml
options:
  no_cache: TRUE
```

**Admin route** (uses admin theme):
```yaml
options:
  _admin_route: TRUE
```

**Parameter constraints**:
```yaml
options:
  parameters:
    node:
      type: entity:node
    user:
      type: entity:user
```

---

## Common Route Patterns

| Pattern | Example | Use Case |
|---------|---------|----------|
| Simple page | `/about` | Static content |
| Entity view | `/node/{node}` | Entity display |
| Entity edit | `/node/{node}/edit` | Entity forms |
| User-specific | `/user/{user}/messages` | User-related pages |
| Admin config | `/admin/config/my-module` | Settings forms |
| API endpoint | `/api/v1/content` | JSON responses |

---

---

## Debugging Routes

**List all routes**:
```bash
drush route
```

**Find route by path**:
```bash
drush route --path=/admin/config
```

**Find route by name**:
```bash
drush route --name=my_module.hello
```

**Generate controller**:
```bash
drush generate controller
```

---

## Key Guidelines

✅ **Use meaningful route names** - `my_module.action_description`
✅ **Validate parameters** - Check input before using
✅ **Use auto-upcasting** - Let Drupal load entities
✅ **Return correct response types** - Render array for pages, JsonResponse for APIs
✅ **Set appropriate access** - Always require permissions
✅ **Use title callbacks** - For dynamic titles
✅ **Follow URL patterns** - Use hyphens, not underscores

❌ **Don't use internal IDs in public URLs** - Use UUIDs for APIs
❌ **Don't skip access checks** - Always set requirements
❌ **Don't hardcode redirects** - Use `Url::fromRoute()`
❌ **Don't forget 404 responses** - Throw NotFoundHttpException
❌ **Don't use `_controller` for forms** - Use `_form` instead

---

**Full documentation**: https://drupalatyourfingertips.com/routes
