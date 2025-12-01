# Drupal Theme Integration Security

**Target**: Drupal 10/11 themes with Vue.js components
**Severity**: High
**Focus**: Safe integration patterns between Drupal and Vue

## Overview

Integrating Vue components into Drupal themes requires careful handling of data passing, template rendering, and security boundaries between PHP/Twig and JavaScript.

---

## Safe Data Passing Patterns

### ✅ SAFE: drupalSettings

```php
<?php
// mytheme.theme

/**
 * Implements hook_preprocess_page().
 */
function mytheme_preprocess_page(&$variables) {
  // Attach Vue library
  $variables['#attached']['library'][] = 'mytheme/vue-app';
  
  // Pass data safely to JavaScript
  $variables['#attached']['drupalSettings']['mytheme'] = [
    // Public, safe data only
    'apiEndpoint' => \Drupal::url('mytheme.api'),
    'currentLanguage' => \Drupal::languageManager()->getCurrentLanguage()->getId(),
    'userRoles' => _mytheme_get_safe_user_roles(),
    'csrfToken' => \Drupal::csrfToken()->get('rest'),
  ];
}

/**
 * Returns sanitized user roles (no sensitive data).
 */
function _mytheme_get_safe_user_roles() {
  $user = \Drupal::currentUser();
  
  // Only return role IDs, no permissions
  return $user->getRoles();
}
```

```vue
<!-- Vue component reading drupalSettings -->
<script setup>
import { ref, onMounted } from 'vue'

const config = ref(null)

onMounted(() => {
  // Validate drupalSettings exists
  if (window.drupalSettings?.mytheme) {
    // Validate structure
    const settings = window.drupalSettings.mytheme
    
    if (settings.apiEndpoint && typeof settings.apiEndpoint === 'string') {
      config.value = {
        apiEndpoint: settings.apiEndpoint,
        language: settings.currentLanguage || 'en',
        roles: Array.isArray(settings.userRoles) ? settings.userRoles : [],
        csrfToken: settings.csrfToken || null
      }
    }
  }
})
</script>
```

---

## Anti-Patterns (Vulnerabilities)

### ❌ DANGEROUS: Exposing Sensitive Data

```php
<?php
// VULNERABLE: Exposing sensitive data to JavaScript

function mytheme_preprocess_page(&$variables) {
  $user = User::load(\Drupal::currentUser()->id());
  
  $variables['#attached']['drupalSettings']['user'] = [
    'id' => $user->id(),
    'name' => $user->getAccountName(),
    'email' => $user->getEmail(), // SENSITIVE!
    'password' => $user->getPassword(), // NEVER!
    'api_key' => $user->get('field_api_key')->value, // SECRET!
    'permissions' => $user->getPermissions() // Don't trust client-side!
  ];
}
```

### ❌ DANGEROUS: Unescaped Output in Twig

```twig
{# VULNERABLE: Unescaped data passed to Vue #}
<div id="app" 
     data-user="{{ user }}"
     data-content="{{ node.body.value }}">
</div>
```

### ❌ DANGEROUS: Trusting Client-Side Permissions

```vue
<!-- VULNERABLE: Client-side authorization -->
<script setup>
const canDelete = computed(() => {
  // Never trust this! Server must validate
  return drupalSettings.user.permissions.includes('delete_node')
})

const deleteNode = async () => {
  if (canDelete.value) {
    // This check is insufficient!
    await api.delete(`/node/${node_id}`)
  }
}
</script>
```

---

## Secure Twig + Vue Integration

### ✅ SAFE: Data Attributes with Escaping

```twig
{# templates/page.html.twig #}
<div id="vue-app" 
     data-config="{{ vue_config|json_encode|escape('html_attr') }}"
     data-node-id="{{ node.id|escape('html_attr') }}">
</div>

{{ attach_library('mytheme/vue-app') }}
```

```php
<?php
// mytheme.theme

function mytheme_preprocess_page(&$variables) {
  if (isset($variables['node'])) {
    $node = $variables['node'];
    
    // Build safe config object
    $vue_config = [
      'nodeType' => $node->bundle(),
      'node_id' => (int) $node->id(),
      'title' => $node->getTitle(), // Already sanitized by Drupal
      'created' => $node->getCreatedTime(),
    ];
    
    $variables['vue_config'] = $vue_config;
  }
}
```

```vue
<script setup>
import { ref, onMounted } from 'vue'

const config = ref(null)

onMounted(() => {
  const appElement = document.getElementById('vue-app')
  
  if (appElement && appElement.dataset.config) {
    try {
      const parsed = JSON.parse(appElement.dataset.config)
      
      // Validate parsed data
      if (parsed && typeof parsed.node_id === 'number') {
        config.value = parsed
      }
    } catch (e) {
      console.error('Invalid config data')
    }
  }
})
</script>
```

---

## Secure Custom Controllers

### ✅ SAFE: REST Endpoint for Vue

```php
<?php
// src/Controller/ApiController.php

namespace Drupal\mytheme\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Drupal\Core\Access\AccessResult;

class ApiController extends ControllerBase {
  
  /**
   * Returns node data for Vue component.
   */
  public function getNodeData(Request $request, $node) {
    // Access check already performed by routing
    
    /** @var \Drupal\node\NodeInterface $node */
    if (!$node->access('view')) {
      return new JsonResponse(['error' => 'Access denied'], 403);
    }
    
    // Return only safe, sanitized data
    $data = [
      'id' => $node->id(),
      'type' => $node->bundle(),
      'title' => $node->getTitle(),
      'created' => $node->getCreatedTime(),
      // Render body through text format
      'body' => $node->body->processed,
      // Metadata
      'changed' => $node->getChangedTime(),
    ];
    
    return new JsonResponse($data);
  }
  
  /**
   * Access callback.
   */
  public function access() {
    // Check permissions
    return AccessResult::allowedIfHasPermission(
      $this->currentUser(),
      'access content'
    );
  }
}
```

```yaml
# mytheme.routing.yml
mytheme.api.node:
  path: '/api/mytheme/node/{node}'
  defaults:
    _controller: '\Drupal\mytheme\Controller\ApiController::getNodeData'
  requirements:
    _custom_access: '\Drupal\mytheme\Controller\ApiController::access'
    node: \d+
  methods: [GET]
```

---

## Form Integration

### ✅ SAFE: Vue Forms with Drupal Validation

```php
<?php
// src/Form/VueFormProcessor.php

namespace Drupal\mytheme\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;

class VueFormProcessor extends FormBase {
  
  public function getFormId() {
    return 'mytheme_vue_form';
  }
  
  public function buildForm(array $form, FormStateInterface $form_state) {
    // Vue will handle UI, we provide endpoint
    return $form;
  }
  
  public function submitForm(array &$form, FormStateInterface $form_state) {
    // Already validated by Drupal
  }
  
  /**
   * AJAX callback for Vue form submission.
   */
  public function ajaxSubmit(Request $request) {
    // Verify CSRF token
    if (!$this->csrfToken()->validate($request->headers->get('X-CSRF-Token'), 'rest')) {
      return new JsonResponse(['error' => 'Invalid token'], 403);
    }
    
    $data = json_decode($request->getContent(), TRUE);
    
    // Validate all input server-side
    $errors = $this->validateInput($data);
    
    if (!empty($errors)) {
      return new JsonResponse(['errors' => $errors], 400);
    }
    
    // Process form
    // ...
    
    return new JsonResponse(['success' => TRUE]);
  }
  
  private function validateInput($data) {
    $errors = [];
    
    // Server-side validation (never trust client)
    if (empty($data['title']) || strlen($data['title']) > 255) {
      $errors['title'] = 'Invalid title';
    }
    
    if (empty($data['body']) || strlen($data['body']) > 10000) {
      $errors['body'] = 'Invalid body';
    }
    
    return $errors;
  }
}
```

```vue
<script setup>
import { ref } from 'vue'
import { useDrupalApi } from '@/composables/useDrupalApi'

const { apiRequest } = useDrupalApi()
const formData = ref({ title: '', body: '' })
const errors = ref({})

const submitForm = async () => {
  errors.value = {}
  
  try {
    // Client-side validation for UX
    if (!formData.value.title) {
      errors.value.title = 'Title is required'
      return
    }
    
    // Submit to Drupal (will validate server-side)
    const response = await apiRequest('/api/mytheme/form-submit', {
      method: 'POST',
      body: JSON.stringify(formData.value)
    })
    
    if (!response.ok) {
      const data = await response.json()
      errors.value = data.errors || {}
      return
    }
    
    // Success
    console.log('Form submitted')
  } catch (error) {
    console.error('Submit error:', error)
  }
}
</script>
```

---

## File Upload Integration

### ✅ SAFE: Secure File Upload

```php
<?php
// src/Controller/FileUploadController.php

public function uploadFile(Request $request) {
  // Verify CSRF
  if (!$this->csrfToken()->validate($request->headers->get('X-CSRF-Token'), 'rest')) {
    return new JsonResponse(['error' => 'Invalid token'], 403);
  }
  
  // Check permission
  if (!$this->currentUser()->hasPermission('upload files')) {
    return new JsonResponse(['error' => 'Access denied'], 403);
  }
  
  $files = $request->files->get('files', []);
  
  if (empty($files)) {
    return new JsonResponse(['error' => 'No file provided'], 400);
  }
  
  $file = reset($files);
  
  // Validate file
  $validators = [
    'file_validate_extensions' => ['jpg jpeg png gif'],
    'file_validate_size' => [5 * 1024 * 1024], // 5MB
    'file_validate_image_resolution' => ['4000x4000'],
  ];
  
  $errors = file_validate($file, $validators);
  
  if (!empty($errors)) {
    return new JsonResponse(['errors' => $errors], 400);
  }
  
  // Save file
  $destination = 'public://vue-uploads/' . date('Y-m');
  $saved_file = file_move($file, $destination, FileSystemInterface::EXISTS_RENAME);
  
  if (!$saved_file) {
    return new JsonResponse(['error' => 'Upload failed'], 500);
  }
  
  return new JsonResponse([
    'fid' => $saved_file->id(),
    'url' => $saved_file->createFileUrl(),
  ]);
}
```

---

## Audit Checklist

- [ ] No sensitive data in drupalSettings
- [ ] All Twig output properly escaped
- [ ] CSRF tokens validated on mutations
- [ ] Server-side permission checks implemented
- [ ] Client-side permissions for UI only
- [ ] API endpoints have access callbacks
- [ ] Form input validated server-side
- [ ] File uploads validated (type, size, content)
- [ ] SQL queries use entity API or parameterized
- [ ] No user input directly in queries
- [ ] Error messages don't expose system info
- [ ] Rate limiting on API endpoints
- [ ] Logging of security events

---

## Testing Strategy

```php
<?php
// tests/src/Functional/VueSecurityTest.php

namespace Drupal\Tests\mytheme\Functional;

use Drupal\Tests\BrowserTestBase;

class VueSecurityTest extends BrowserTestBase {
  
  public function testDrupalSettingsNoSensitiveData() {
    $this->drupalGet('<front>');
    
    $settings = $this->getDrupalSettings();
    
    // Should not contain sensitive keys
    $this->assertArrayNotHasKey('password', $settings);
    $this->assertArrayNotHasKey('api_key', $settings);
  }
  
  public function testApiRequiresCsrfToken() {
    // Try without CSRF token
    $response = $this->drupalPost('/api/mytheme/submit', [
      'title' => 'Test'
    ]);
    
    $this->assertSession()->statusCodeEquals(403);
  }
}
```

---

## References

- [Drupal Security Best Practices](https://www.drupal.org/docs/security-in-drupal)
- [Drupal Render API](https://www.drupal.org/docs/drupal-apis/render-api)
- [Drupal REST API](https://www.drupal.org/docs/core-modules-and-themes/core-modules/rest)

