# Caching

**Source**: [Drupal at Your Fingertips - caching](https://drupalatyourfingertips.com/caching)
**Author**: Selwyn Polit

Quick reference for Drupal caching with practical code examples.

---

## Core Concept

Drupal's caching system uses three components: **cache tags** (what data it depends on), **cache contexts** (how it varies), and **max-age** (how long it lasts). These must always be set together to ensure proper cacheability.

## Cache Metadata Triplet

**The three required components**:
```php
$build = [
  '#markup' => 'Your content here',
  '#cache' => [
    'tags' => ['node:5', 'user:3'],           // What invalidates this
    'contexts' => ['user.roles', 'url.path'], // How it varies
    'max-age' => 3600,                        // How long (seconds)
  ],
];
```

| Component | Purpose | Example |
|-----------|---------|---------|
| **Cache Tags** | Dependencies - invalidate when data changes | `node:5`, `user:3`, `custom_list` |
| **Cache Contexts** | Variations - create different versions | `user`, `url.query_args:id`, `languages` |
| **Max-Age** | Lifetime - how long before stale | `3600`, `Cache::PERMANENT`, `0` |

---

## Cache Tags

**Format**: `thing:identifier` or just `thing`
```php
use Drupal\Core\Cache\Cache;

// Entity cache tags
$cache_tags = [
  'node:' . $node->id(),
  'user:' . $user->id(),
  'node_list',
  'user_list',
];

// Get entity cache tags (recommended)
$node_tags = $node->getCacheTags();
$user_tags = $user->getCacheTags();
```

**Invalidate cache tags**:
```php
use Drupal\Core\Cache\Cache;

// Invalidate specific tags
Cache::invalidateTags(['node:5', 'custom_tag_example']);

// Invalidate when entity changes
function my_module_node_update(NodeInterface $node) {
  Cache::invalidateTags($node->getCacheTags());
}
```

---

## Cache Contexts

**Hierarchical variations** (more specific encompasses less specific):
```php
// User contexts (hierarchical)
'contexts' => ['user'],                      // Varies per user
'contexts' => ['user.roles'],                // Varies per role set
'contexts' => ['user.roles:authenticated'],  // Only for authenticated

// URL contexts
'contexts' => ['url.path'],                  // Varies per path
'contexts' => ['url.query_args'],            // Varies per any query arg
'contexts' => ['url.query_args:id'],         // Only varies on ?id=

// Language contexts
'contexts' => ['languages:language_interface'],
```

**Common cache contexts**:
| Context | Use Case |
|---------|----------|
| `user` | Per-user content |
| `user.roles` | Per-role visibility |
| `user.permissions` | Per-permission access |
| `url.path` | Different for each path |
| `url.query_args` | Query parameter variations |
| `languages` | Multilingual content |
| `theme` | Theme-specific rendering |

---

## Cache Max-Age

**Lifetime control**:
```php
use Drupal\Core\Cache\Cache;

// Permanent caching
$build['#cache']['max-age'] = Cache::PERMANENT;

// Time-based expiration (seconds)
$build['#cache']['max-age'] = 3600;  // 1 hour
$build['#cache']['max-age'] = 86400; // 1 day

// Disable caching
$build['#cache']['max-age'] = 0;

// Calculate expiration from timestamp
$expiration_time = strtotime('+1 hour');
$current_time = \Drupal::time()->getRequestTime();
$build['#cache']['max-age'] = max(0, $expiration_time - $current_time);
```

---

## Render Array Caching

**Basic pattern**:
```php
public function build() {
  $node = Node::load(5);

  return [
    '#theme' => 'my_template',
    '#node' => $node,
    '#cache' => [
      'tags' => $node->getCacheTags(),
      'contexts' => ['user.roles'],
      'max-age' => Cache::PERMANENT,
    ],
  ];
}
```

**Multiple cache tags**:
```php
public function buildList() {
  $nodes = Node::loadMultiple([1, 2, 3]);

  $cache_tags = ['node_list'];
  foreach ($nodes as $node) {
    $cache_tags = Cache::mergeTags($cache_tags, $node->getCacheTags());
  }

  return [
    '#theme' => 'node_list',
    '#nodes' => $nodes,
    '#cache' => [
      'tags' => $cache_tags,
      'contexts' => ['url.query_args:page'],
      'max-age' => 3600,
    ],
  ];
}
```

---

## JSON Response Caching

**Use CacheableJsonResponse**:
```php
use Drupal\Core\Cache\CacheableJsonResponse;
use Drupal\Core\Cache\Cache;

public function apiEndpoint() {
  $data = ['status' => 'success', 'items' => $this->getItems()];

  $response = new CacheableJsonResponse($data, 200, [
    'Cache-Control' => 'public, max-age=3600',
  ]);

  // Add cache metadata
  $response->getCacheableMetadata()
    ->addCacheTags(['custom_api_data'])
    ->addCacheContexts(['url.query_args:filter'])
    ->setCacheMaxAge(3600);

  return $response;
}
```

**Add cacheable dependency**:
```php
use Drupal\Core\Cache\CacheableMetadata;

public function configBasedApi() {
  $config = $this->config('my_module.settings');

  $response = new CacheableJsonResponse(['data' => $config->get('api_data')]);

  // Automatically adds config's cache tags
  $response->addCacheableDependency($config);

  return $response;
}
```

---

## Page Cache Kill Switch

**Prevent page caching** (but allow browser/CDN caching):
```php
public function dynamicPage() {
  // Disable Drupal's page cache
  \Drupal::service('page_cache_kill_switch')->trigger();

  return [
    '#markup' => 'Dynamic content: ' . time(),
  ];
}
```

**When to use**: For pages with per-request dynamic content that can't use cache contexts.

---

## Cache Bins

**Default bins**:
| Bin | Purpose |
|-----|---------|
| `default` | General cache data |
| `bootstrap` | Early bootstrap data |
| `render` | Rendered elements |
| `data` | Module-specific data |
| `discovery` | Plugin discovery |

**Use cache bins**:
```php
// Get cache bin
$cache = \Drupal::cache('render');

// Set cache item
$cache->set('my_cache_id', $data, time() + 3600, ['custom_tag']);

// Get cache item
$cached = $cache->get('my_cache_id');
if ($cached) {
  $data = $cached->data;
}

// Delete cache item
$cache->delete('my_cache_id');
```

**Custom cache bin** (my_module.services.yml):
```yaml
services:
  cache.voting:
    class: Drupal\Core\Cache\CacheBackendInterface
    tags:
      - { name: cache.bin }
    factory: cache_factory:get
    arguments: [voting]
```

```php
// Use custom bin
\Drupal::cache('voting')->set($id, $votes, Cache::PERMANENT, ['vote_list']);
```

---

## Cache-Friendly Architecture

**Pattern: Static page + dynamic API**:
```php
// Controller returns cacheable page
public function buildPage() {
  return [
    '#theme' => 'counter_page',
    '#attached' => [
      'library' => ['my_module/counter'],
    ],
    '#cache' => [
      'tags' => ['counter_page'],
      'contexts' => [],
      'max-age' => Cache::PERMANENT,
    ],
  ];
}

// Separate API endpoint for dynamic data
public function counterApi() {
  $count = $this->getCurrentCount();

  $response = new CacheableJsonResponse(['count' => $count]);
  $response->getCacheableMetadata()
    ->setCacheMaxAge(60); // 1 minute

  return $response;
}
```

**JavaScript fetches dynamic data**:
```javascript
fetch('/api/counter/endpoint')
  .then(response => response.json())
  .then(data => {
    document.querySelector('.count').textContent = data.count;
  });
```

---

## Cache Debugging

**Enable debug headers** (sites/development.services.yml):
```yaml
parameters:
  http.response.debug_cacheability_headers: true
```

**Inspect cache headers** (browser DevTools Network tab):
```
X-Drupal-Cache-Tags: node:5 node_list user:3
X-Drupal-Cache-Contexts: user.roles url.path
X-Drupal-Cache-Max-Age: 3600
```

**Disable render cache** (sites/default/settings.local.php):
```php
$settings['cache']['bins']['render'] = 'cache.backend.null';
$settings['cache']['bins']['page'] = 'cache.backend.null';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
```

---

## Cache Backends

**Memcached** (settings.php):
```php
$settings['memcache']['servers'] = ['memcached:11211' => 'default'];
$settings['cache']['default'] = 'cache.backend.memcache';
```

**Redis** (settings.php):
```php
$settings['redis.connection']['interface'] = 'PhpRedis';
$settings['redis.connection']['host'] = 'redis';
$settings['cache']['default'] = 'cache.backend.redis';
```

**APCu** (single server only):
```php
$settings['cache']['default'] = 'cache.backend.apcu';
```

---

---

## Key Guidelines

✅ **Always set cache metadata triplet** - tags, contexts, max-age together
✅ **Use getCacheTags()** - Don't hardcode entity tag format
✅ **Use cache contexts** - Instead of disabling caching
✅ **Use CacheableJsonResponse** - For API endpoints
✅ **Invalidate precisely** - Use specific cache tags
✅ **Use cache bins** - Separate different cache types
✅ **Enable debug headers** - During development
✅ **Use Cache::mergeTags()** - When combining tags

❌ **Don't skip cache metadata** - All three required
❌ **Don't use page_cache_kill_switch casually** - Use contexts instead
❌ **Don't hardcode entity cache tags** - Use getCacheTags()
❌ **Don't forget addCacheableDependency** - For config/entity deps
❌ **Don't use max-age 0 by default** - Architect for caching
❌ **Don't invalidate too broadly** - Be specific with tags
❌ **Don't cache per-request data** - Use appropriate max-age

---

**Full documentation**: https://drupalatyourfingertips.com/caching
