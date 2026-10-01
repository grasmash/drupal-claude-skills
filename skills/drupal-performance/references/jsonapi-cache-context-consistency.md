# JSON:API Cache Context Consistency Pattern

## Table of Contents
1. [Problem Overview](#problem-overview)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Solution Architecture](#solution-architecture)
4. [Implementation Details](#implementation-details)
5. [Testing Patterns](#testing-patterns)
6. [Troubleshooting](#troubleshooting)
7. [Entity Access Hooks (CRITICAL)](#entity-access-hooks-critical)

Applies to any Drupal site running JSON:API together with the `consumers`
module (typically alongside `simple_oauth`). Module/service names below use a
generic `my_jsonapi` custom module as the example — substitute your own.

---

## Problem Overview

### The Error

```
PHP Warning: Trying to overwrite a cache redirect with one that has nothing in common
with the stored cache contexts...
Stored context hierarchy: url.query_args:consumerId
New context hierarchy: user
```

### Impact

- Production warnings in logs
- Cache inefficiency (redirects not reused)
- Potential stale cache issues
- Performance degradation from cache misses

### Affected Entities

Common in entities with access control tied to:
- Group membership (Group module)
- Flagging state (Flag module)
- Custom access hooks

---

## Root Cause Analysis

### Cache Context Hierarchy Requirements

Drupal's `VariationCache` stores cache redirects that allow the cache system
to determine which variation of cached content to serve based on context.
When overwriting a redirect, the new contexts must either:

1. **Be identical** to the stored contexts
2. **Share a common parent** in the context hierarchy

### The Conflict

1. **ConsumerRouteEnhancer** (from the `consumers` module) adds:
   ```
   url.query_args:consumerId
   ```

2. **Access hooks** (Group, Flag, custom) add:
   ```
   user
   ```

3. **No shared hierarchy** — these contexts are independent branches

### Flow Diagram

```
Request 1 (anonymous):
  ConsumerRouteEnhancer → adds consumerId context
  Entity cache stores: redirect with [url.query_args:consumerId]

Request 2 (authenticated):
  Group access hook → adds user context
  Entity cache tries to overwrite redirect
  VariationCache: "nothing in common" warning!
```

---

## Solution Architecture

### Core Principle

**Always add both linked contexts together for JSON:API requests.**

By ensuring both contexts are present from the start, VariationCache never
encounters the "nothing in common" situation.

### Implementation Approach

Use an EventSubscriber that listens on multiple kernel events:

| Event | Priority | Purpose |
|-------|----------|---------|
| REQUEST | 100 | Flag request early for context linking |
| RESPONSE | 0 | Add linked contexts to response metadata |
| TERMINATE | 100 | Final safety net before normalization caching |

### Why Multiple Events?

- **REQUEST**: Sets up state before any processing
- **RESPONSE**: Catches standard response flow
- **TERMINATE**: Runs before `ResourceObjectNormalizationCacher::onTerminate()`
  (priority 0)

---

## Implementation Details

### The Subscriber

Location: `web/modules/custom/my_jsonapi/src/EventSubscriber/CacheContextConsistencySubscriber.php`

```php
<?php

declare(strict_types=1);

namespace Drupal\my_jsonapi\EventSubscriber;

use Drupal\Core\Cache\CacheableResponseInterface;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

final class CacheContextConsistencySubscriber implements EventSubscriberInterface {

  /**
   * Cache contexts that MUST be added together.
   */
  public const LINKED_CONTEXTS = [
    'user',
    'url.query_args:consumerId',
  ];

  public static function getSubscribedEvents(): array {
    return [
      KernelEvents::REQUEST => ['onRequest', 100],
      KernelEvents::RESPONSE => ['onResponse', 0],
      KernelEvents::TERMINATE => ['onTerminate', 100],
    ];
  }

  public function onRequest(RequestEvent $event): void {
    $path = $event->getRequest()->getPathInfo();
    if (!str_starts_with($path, '/jsonapi/')) {
      return;
    }
    // Mark request for context linking
    $event->getRequest()->attributes->set('_my_jsonapi_linked_contexts', TRUE);
  }

  public function onResponse(ResponseEvent $event): void {
    $response = $event->getResponse();
    if (!$response instanceof CacheableResponseInterface) {
      return;
    }

    $path = $event->getRequest()->getPathInfo();
    if (!str_starts_with($path, '/jsonapi/')) {
      return;
    }

    // Add both linked contexts
    $response->getCacheableMetadata()->addCacheContexts(self::LINKED_CONTEXTS);
  }

  public function onTerminate(\Symfony\Component\HttpKernel\Event\TerminateEvent $event): void {
    $response = $event->getResponse();
    if (!$response instanceof CacheableResponseInterface) {
      return;
    }

    $path = $event->getRequest()->getPathInfo();
    if (!str_starts_with($path, '/jsonapi/')) {
      return;
    }

    // Final safety net
    $response->getCacheableMetadata()->addCacheContexts(self::LINKED_CONTEXTS);
  }
}
```

### Service Registration

Location: `web/modules/custom/my_jsonapi/my_jsonapi.services.yml`

```yaml
services:
  my_jsonapi.cache_context_consistency_subscriber:
    class: Drupal\my_jsonapi\EventSubscriber\CacheContextConsistencySubscriber
    tags:
      - { name: event_subscriber }
```

### Access Hook Pattern

When implementing access hooks that add cache contexts:

```php
/**
 * Implements hook_node_access().
 */
function my_module_node_access(NodeInterface $node, $operation, AccountInterface $account) {
  // Access logic...

  // CRITICAL: Add both linked contexts
  return AccessResult::allowed()
    ->addCacheContexts([
      'user',
      'url.query_args:consumerId',
    ])
    ->addCacheTags($node->getCacheTags());
}
```

---

## Testing Patterns

### Unit Test: Subscriber Events

```php
public function testSubscriberDeclaresEvents() {
  $events = CacheContextConsistencySubscriber::getSubscribedEvents();

  $this->assertArrayHasKey(KernelEvents::REQUEST, $events);
  $this->assertArrayHasKey(KernelEvents::RESPONSE, $events);
  $this->assertArrayHasKey(KernelEvents::TERMINATE, $events);
}
```

### Integration Test: Context Addition

```php
public function testLinkedContextsAddedForJsonApiRequest() {
  $request = Request::create('/jsonapi/node/article/test-uuid');
  $response = new CacheableResponse('{}', 200);

  $event = new ResponseEvent(
    \Drupal::service('http_kernel'),
    $request,
    HttpKernelInterface::MAIN_REQUEST,
    $response
  );

  $subscriber = \Drupal::service('my_jsonapi.cache_context_consistency_subscriber');
  $subscriber->onResponse($event);

  $contexts = $response->getCacheableMetadata()->getCacheContexts();
  $this->assertContains('user', $contexts);
  $this->assertContains('url.query_args:consumerId', $contexts);
}
```

### Regression Test: No Warning Triggered

```php
public function testJsonApiRequestCacheConsistency() {
  $cache_backend = \Drupal::cache('jsonapi_normalizations');
  $cache_backend->deleteAll();

  $warning_triggered = FALSE;
  set_error_handler(function ($errno, $errstr) use (&$warning_triggered) {
    if (strpos($errstr, 'nothing in common') !== FALSE) {
      $warning_triggered = TRUE;
    }
    return FALSE;
  }, E_USER_WARNING);

  try {
    // Request as anonymous
    $request1 = Request::create('/jsonapi/node/article/' . $uuid);
    $response1 = $http_kernel->handle($request1);
    $http_kernel->terminate($request1, $response1);

    // Request as authenticated
    $account_switcher->switchTo($user);
    $request2 = Request::create('/jsonapi/node/article/' . $uuid);
    $response2 = $http_kernel->handle($request2);
    $http_kernel->terminate($request2, $response2);
  } finally {
    restore_error_handler();
  }

  $this->assertFalse($warning_triggered);
}
```

---

## Troubleshooting

### Warning Still Appearing

1. **Clear all caches**:
   ```bash
   ddev drush cr
   ```

2. **Verify the subscriber service is registered**:
   ```bash
   ddev drush eval "print_r(\Drupal::hasService('my_jsonapi.cache_context_consistency_subscriber'));"
   ```

3. **Check subscriber priority**: Ensure TERMINATE priority > 0
   (ResourceObjectNormalizationCacher uses priority 0)

### Debugging Cache Contexts

```php
// In access hook
$access = AccessResult::allowed()->addCacheContexts(['user', 'url.query_args:consumerId']);
\Drupal::logger('my_module')->notice('Access contexts: @contexts', [
  '@contexts' => implode(', ', $access->getCacheContexts()),
]);
return $access;
```

### Bypassing the Normalization Cache While Debugging

```php
$settings['cache']['bins']['jsonapi_normalizations'] = 'cache.backend.null';
```

---

## Entity Access Hooks (CRITICAL)

**The response-level subscriber alone is NOT sufficient.** JSON:API caches
each entity's normalization **separately** via
`ResourceObjectNormalizationCacher`. The entity's access cacheability is
collected during normalization, not just at the response level.

### All Entity Access Hooks MUST Include Both Contexts

Every `hook_entity_access()`, `hook_node_access()`,
`hook_ENTITY_TYPE_access()` that returns an AccessResult with `user` context
MUST also include `url.query_args:consumerId`. Audit EVERY custom module
that implements an access hook — on the codebase this pattern comes from,
six separate modules (content access, group access, per-bundle access,
taxonomy access, licensing) each needed the fix; missing any one of them
keeps the warning alive.

### Standard Pattern for Access Hooks

```php
/**
 * Implements hook_entity_access().
 */
function my_module_entity_access(EntityInterface $entity, $operation, AccountInterface $account) {
  // Include 'url.query_args:consumerId' alongside 'user' to prevent
  // VariationCache redirect conflicts during JSON:API normalization caching.
  // @see \Drupal\my_jsonapi\EventSubscriber\CacheContextConsistencySubscriber
  $linked_contexts = ['user', 'url.query_args:consumerId'];

  if ($entity->getEntityTypeId() == 'node' && $entity->bundle() == 'mytype') {
    if ($some_condition) {
      return AccessResult::allowed()->addCacheContexts($linked_contexts);
    }
    return AccessResult::forbidden()->addCacheContexts($linked_contexts);
  }

  return AccessResult::neutral()->addCacheContexts($linked_contexts);
}
```

### NEVER Use These Alone

```php
// BAD - causes VariationCache conflicts
return AccessResult::allowed()->cachePerUser();
return AccessResult::allowed()->addCacheContexts(['user']);

// GOOD - always add both contexts
return AccessResult::allowed()->addCacheContexts(['user', 'url.query_args:consumerId']);
```

### Filter Access Hooks

Also applies to `hook_jsonapi_entity_filter_access()`:

```php
function my_module_jsonapi_entity_filter_access(EntityTypeInterface $entity_type, AccountInterface $account) {
  if ($entity_type->id() === 'group_relationship') {
    return [
      'filter_among_all' => AccessResult::allowed()
        ->addCacheContexts(['user.group_permissions', 'user', 'url.query_args:consumerId']),
      'filter_among_published' => AccessResult::allowed()
        ->addCacheContexts(['user.group_permissions', 'user', 'url.query_args:consumerId']),
    ];
  }
}
```

---

## External References

- [Drupal Cache Contexts](https://www.drupal.org/docs/drupal-apis/cache-api/cache-contexts)
- [VariationCache API](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21Cache%21VariationCache.php/class/VariationCache)
- [JSON:API Caching](https://www.drupal.org/docs/core-modules-and-themes/core-modules/jsonapi-module/caching)
