---
name: drupal-api-endpoints
description: Custom Drupal API endpoint patterns with UUID-based security. Use when creating custom routes, AJAX endpoints, or JSON:API filter access. Critical for preventing JSON:API cache poisoning. Always check for existing endpoints before creating new ones.
---

# Drupal API Endpoint Patterns

## Critical Rules

**ALWAYS follow these rules for ALL endpoints**:

1. **ALWAYS use UUIDs** - never expose entity IDs.
2. **ALWAYS check for existing endpoints** before creating a new one.
3. **NEVER use the core REST module** - use custom routes.
4. **ALWAYS use JSON** for request/response.
5. **ALWAYS implement access controls** and caching.
6. **Place routes in the correct module** - the module that owns the functionality.
7. **AVOID `/api/*` paths** for custom routes - reserved for JSON:API.

## URL Pattern Convention

**Preferred pattern**: `/MODULE-api/resource/action`

### Examples
```
✅ /achievements-api/unlock          # my_achievements module
✅ /scoring-api/ingest                # my_scoring module

❌ /api/custom-endpoint               # Conflicts with JSON:API
```

## Check for Existing Endpoints

**ALWAYS search before creating**:

```bash
# Search all custom module routes
grep -r "path: '/" web/modules/custom/*/routing.yml

# Search for API patterns
grep -r "path: '/.*-api" web/modules/custom/

# Check by pattern
ddev drush ev "print_r(\Drupal::service('router.route_provider')->getRoutesByPattern('/scoring-api')->all());"
```

## Creating API Endpoints

### Step 1: Define Route (MODULE.routing.yml)

```yaml
my_module.api.action_name:
  path: '/my-module-api/entity-type/{uuid}/action'
  defaults:
    _controller: '\Drupal\my_module\Controller\ApiController::actionName'
  methods: [POST]
  requirements:
    _user_is_logged_in: 'TRUE'  # For authenticated
    # OR for public: _access: 'TRUE'
    _format: 'json'
  options:
    parameters:
      uuid:
        type: 'string'
    no_cache: 'TRUE'  # Disable caching if needed
```

### Step 2: Implement Controller

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Access\AccessResult;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;

final class ApiController extends ControllerBase {

  /**
   * Check access for the endpoint.
   */
  public function access($uuid) {
    // Load entity by UUID
    $entities = \Drupal::entityTypeManager()
      ->getStorage('entity_type')
      ->loadByProperties(['uuid' => $uuid]);

    if (empty($entities)) {
      return AccessResult::forbidden('Entity not found');
    }

    $entity = reset($entities);

    // Check permissions
    return AccessResult::allowedIf(
      $entity->access('update') &&
      \Drupal::currentUser()->hasPermission('permission_name')
    )->addCacheableDependency($entity);
  }

  public function actionName(Request $request, $uuid) {
    try {
      // Parse JSON payload
      $payload = json_decode($request->getContent(), TRUE);

      // Validate payload
      if (!$payload || !isset($payload['required_field'])) {
        return new JsonResponse([
          'success' => FALSE,
          'error' => 'Invalid payload'
        ], 400);
      }

      // Load entity by UUID
      $entities = \Drupal::entityTypeManager()
        ->getStorage('entity_type')
        ->loadByProperties(['uuid' => $uuid]);

      if (empty($entities)) {
        return new JsonResponse([
          'success' => FALSE,
          'error' => 'Entity not found'
        ], 404);
      }

      $entity = reset($entities);

      // Perform action
      // ... business logic ...

      // Clear caches
      \Drupal::service('cache_tags.invalidator')
        ->invalidateTags($entity->getCacheTags());

      return new JsonResponse([
        'success' => TRUE,
        'data' => [
          'uuid' => $entity->uuid(),
          'status' => 'completed'
        ]
      ]);

    } catch (\Exception $e) {
      \Drupal::logger('my_module')->error(
        'API error: @message',
        ['@message' => $e->getMessage()]
      );
      return new JsonResponse([
        'success' => FALSE,
        'error' => 'An error occurred'
      ], 500);
    }
  }
}
```

### Step 3: Client Implementation (fetch)

Use `fetch` with optimistic UI and revert-on-failure — not jQuery `$.ajax`.

```javascript
try {
  const response = await fetch(`/my-module-api/entity-type/${entityUuid}/action`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken, // from /session/token
    },
    body: JSON.stringify({ required_field: value }),
  });
  const data = await response.json();
  if (!data.success) {
    throw new Error(data.error);
  }
} catch (err) {
  // revert optimistic UI change; show error via your project's message helper
}
```

## Common Patterns

### Load by UUID (required for all endpoints)
```php
$entities = \Drupal::entityTypeManager()
  ->getStorage('entity_type')
  ->loadByProperties(['uuid' => $uuid]);
$entity = !empty($entities) ? reset($entities) : NULL;
```

### Multiple Permission Check
```php
$access = AccessResult::allowedIf(
  $user->hasPermission('permission_1') ||
  $user->hasPermission('permission_2')
)->cachePerPermissions();
```

### Cache Metadata
```php
$response->getCacheableMetadata()
  ->addCacheContexts(['user', 'user.permissions'])
  ->addCacheTags($entity->getCacheTags());
```

## Debugging

### Check Watchdog Logs
```bash
# Error logs only
ddev drush watchdog:show --severity=3 --count=10

# Check specific module
ddev drush watchdog:show --type=my_module
```

### Test Endpoint
```bash
# GET request
curl -H "Content-Type: application/json" https://<project>.ddev.site/my-module-api/test

# POST with JSON
curl -X POST -H "Content-Type: application/json" \
  -d '{"field":"value"}' \
  https://<project>.ddev.site/my-module-api/entity/UUID/action
```

## Apply to Files
- `web/modules/custom/my_module/routing.yml`
- `web/modules/custom/my_module/src/Controller/*Controller.php`

## Testing with cURL

For testing API endpoints with authenticated requests, see the comprehensive guide:
- @references/authenticated-curl-examples.md

Quick authenticated GET example:
```bash
# Get session with drush, then use cookie
curl -b /tmp/cookies.txt \
  -H "Content-Type: application/json" \
  https://<project>.ddev.site/my-module-api/status
```

## JSON:API Filter Access (Critical)

When exposing entities via JSON:API with filtering, you MUST implement
`hook_jsonapi_ENTITY_TYPE_filter_access()`. Without it, Drupal's `TemporaryQueryGuard`
adds `WHERE 1 = 0` to queries, causing **cache poisoning**.

### Quick Fix Pattern

```php
/**
 * Implements hook_jsonapi_ENTITY_TYPE_filter_access() for my_entity.
 */
function mymodule_jsonapi_my_entity_filter_access(EntityTypeInterface $entity_type, AccountInterface $account) {
  if ($account->isAuthenticated()) {
    return [
      JSONAPI_FILTER_AMONG_ALL => AccessResult::allowed()
        ->cachePerPermissions()
        ->addCacheContexts(['user.roles:authenticated']),
    ];
  }
  return [
    JSONAPI_FILTER_AMONG_ALL => AccessResult::forbidden()->cachePerPermissions(),
  ];
}
```

**See**: @references/jsonapi-filter-access.md for full documentation on JSON:API cache
poisoning prevention.

## References
- @references/authenticated-curl-examples.md
- @references/jsonapi-filter-access.md
