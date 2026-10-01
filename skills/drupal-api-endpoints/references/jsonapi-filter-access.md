# JSON:API Filter Access (Critical for Cache Poisoning Prevention)

## The Problem

JSON:API endpoints that allow filtering entity collections require a specific hook implementation. Without it, Drupal's `TemporaryQueryGuard` denies all filter access, resulting in:
- Empty responses (`{"data":[], "meta":{"count":0}}`)
- These empty responses get cached
- All subsequent requests receive the cached empty response (cache poisoning)

## Root Cause

The JSON:API module requires `hook_jsonapi_ENTITY_TYPE_filter_access()` to return an **array keyed by `JSONAPI_FILTER_AMONG_*` constants**.

If you return just `AccessResult::neutral()` or `AccessResult::allowed()` without the array structure, `TemporaryQueryGuard` interprets this as "no opinion" and adds `WHERE 1 = 0` to queries.

## Symptoms

- JSON:API collection endpoints return `{"data":[], "meta":{"count":0}}`
- Database has valid data
- `x-drupal-dynamic-cache: HIT` header shows cached response
- Cache clear temporarily fixes the issue
- Issue returns after cache is repopulated

## The Fix

### Correct Implementation

```php
/**
 * Implements hook_jsonapi_ENTITY_TYPE_filter_access() for ENTITY_TYPE.
 */
function mymodule_jsonapi_ENTITY_TYPE_filter_access(EntityTypeInterface $entity_type, AccountInterface $account) {
  // Allow authenticated users to filter all entities
  if ($account->isAuthenticated()) {
    return [
      JSONAPI_FILTER_AMONG_ALL => AccessResult::allowed()
        ->cachePerPermissions()
        ->addCacheContexts(['user.roles:authenticated']),
    ];
  }

  // Deny anonymous users
  return [
    JSONAPI_FILTER_AMONG_ALL => AccessResult::forbidden()
      ->cachePerPermissions(),
  ];
}
```

### WRONG Implementation (Causes Cache Poisoning)

```php
// THIS CAUSES CACHE POISONING - DO NOT USE
function mymodule_jsonapi_ENTITY_TYPE_filter_access(EntityTypeInterface $entity_type, AccountInterface $account) {
  return AccessResult::neutral()
    ->addCacheContexts(['url.query_args']);
}
```

## Available Filter Subsets

The hook must return an array with one or more of these constants as keys:

| Constant | Description |
|----------|-------------|
| `JSONAPI_FILTER_AMONG_ALL` | All entities of the given type |
| `JSONAPI_FILTER_AMONG_PUBLISHED` | Published entities only |
| `JSONAPI_FILTER_AMONG_ENABLED` | Enabled entities only |
| `JSONAPI_FILTER_AMONG_OWN` | Entities owned by the user |

## Real Example: Flagging Entities

From `my_flag.module`:

```php
/**
 * Implements hook_jsonapi_ENTITY_TYPE_filter_access() for flagging.
 *
 * This hook controls whether users can filter flagging collections via JSON:API.
 * Without properly returning JSONAPI_FILTER_AMONG_* constants, the TemporaryQueryGuard
 * will add "WHERE 1 = 0" to queries, causing empty results that get cached and
 * served to all users (cache poisoning).
 */
function my_flag_jsonapi_flagging_filter_access(EntityTypeInterface $entity_type, AccountInterface $account) {
  // Allow authenticated users to filter all flaggings
  if ($account->isAuthenticated()) {
    return [
      JSONAPI_FILTER_AMONG_ALL => AccessResult::allowed()
        ->cachePerPermissions()
        ->addCacheContexts(['user.roles:authenticated']),
    ];
  }

  // Anonymous users cannot filter flaggings
  return [
    JSONAPI_FILTER_AMONG_ALL => AccessResult::forbidden()
      ->cachePerPermissions(),
  ];
}
```

## Debugging Cache Poisoning

### Check if Response is Cached

```bash
curl -s -D - 'https://<project>.ddev.site/jsonapi/entity/bundle?filter[field]=value' \
  | grep -E "x-drupal-dynamic-cache|x-drupal-cache"
```

- `HIT` = cached response (potentially poisoned)
- `MISS` = fresh response
- `UNCACHEABLE` = not cacheable

### Verify Database Has Data

```bash
ddev drush sql:query "SELECT COUNT(*) FROM entity_table WHERE conditions"
```

### Check What Hook Returns

```php
ddev drush eval '
  $entity_type = \Drupal::entityTypeManager()->getDefinition("entity_type");
  $account = \Drupal::currentUser();
  $result = \Drupal::moduleHandler()->invokeAll("jsonapi_entity_type_filter_access", [$entity_type, $account]);
  print_r($result);
'
```

## Cache Contexts for Filter Access

Always include appropriate cache contexts:

| Context | Use When |
|---------|----------|
| `user.permissions` | Access varies by permission set |
| `user.roles:authenticated` | Different for anon vs auth |
| `user` | Different for each user (expensive!) |
| `cachePerPermissions()` | Shorthand for permission-based caching |

## Related Issues

- Drupal.org: #3376470 - JSON:API filtering returns empty despite permissions
- Drupal.org: #3091824 - Flag module JSON:API integration
- Drupal.org: #3091866 - Add FlaggingAccessControlHandler

## Testing

After implementing the hook, test:

1. Clear cache: `ddev drush cr`
2. Make request as authenticated user
3. Verify data returns
4. Make second request, verify still returns data (from cache)
5. Make request as anonymous, verify appropriate response

```bash
# Test as authenticated user
LOGIN_URL=$(ddev drush uli --uid=1 | head -1)
curl -c /tmp/cookies.txt -L -k "$LOGIN_URL" -o /dev/null
curl -b /tmp/cookies.txt -k 'https://<project>.ddev.site/jsonapi/flagging/follow?filter[entity_id]=123'
```
