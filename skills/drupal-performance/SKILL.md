---
name: drupal-performance
description: Drupal performance optimization + REVIEW patterns/anti-patterns. Load WHENEVER reviewing, profiling, or changing performance — backend or frontend, before declaring perf work done. Core metric = cold-render DATABASE QUERY COUNT/VOLUME per route (networked production DBs cost ~10x+ local per query; local wall-time/Lighthouse hides real TTFB). Use for performance review/audit, slow pages/high TTFB, query count/N+1 reduction, entity loads in loops, caching/cache contexts, render cache metadata, CacheableJsonResponse endpoints.
---

# Drupal Performance Optimization

Beyond raw query count, two related levers matter: maximize **WARM** (Dynamic
Page Cache HIT) requests via render-cache keys + cache tags/contexts — the
cold path is still common because authenticated routes are typically per-user
DPC-cached — and watch for **VariationCache conflicts** (cache context
consistency and "nothing in common" cache redirect warnings; see
`references/jsonapi-cache-context-consistency.md`).

## Measure the right thing FIRST (hard-won — read before profiling)

On the codebase these lessons come from, a whole audit went into xhprof +
Lighthouse and moved the needle almost not at all. The single thing that did:
**cutting cold-render query count.** Here is why the usual tools missed it,
and what to measure instead.

**The local-vs-prod latency gap is the whole story.** Local DDEV runs the DB
in the same container (~0.1 ms/query). Production runs a networked DB (and
usually a networked cache backend like Redis) at ~1+ ms/query. A cold
authenticated render doing ~1,500 queries is **~0.15 s local but ~2 s prod.**
Local wall-clock (xhprof, local Lighthouse) amortizes the dominant cost to
nothing, so everything "looks optimal locally." It isn't.

So, in order:

1. **Primary backend metric = cold-render REAL-SQL query count per route, not
   local wall-clock.** Query count is environment-invariant; prod TTFB ≈
   `real_sql_count × per-query network latency + cache-backend reads +
   http.client time`. **Subtract the cache-backend reads first:** locally the
   cache backend is the DB, so a local query log is dominated by
   `cache_render` / `cache_config` / `cache_discovery` / `cache_default` /
   `cache_data` reads — on a production stack with Redis those never touch
   the networked MySQL. The number that maps to prod networked-SQL is the
   NON-cache queries: entity/field/config-source/`key_value` loads **plus
   `cachetags`** (which stays SQL in production via
   DatabaseCacheTagsChecksum). Example from the source codebase: a 678-query
   local dashboard render was ~489 cache-backend + ~39 cachetags + ~150 real
   → ~190 networked-SQL, NOT 678 slow queries. So: count real-SQL, budget per
   route, treat a count regression as the failure. The cache-backend reads
   aren't free either (each is a cache-backend round-trip, and a high
   `cache_render` count = many separately cached elements) — but they're a
   second-order concern.
2. **Measure the COLD path, and treat it as common — not "one-time."**
   The classic mistake is dismissing cold as "one-time per cache flush; prod
   serves warm." FALSE: authenticated Dynamic Page Cache is **per-user**, so
   every user's first hit to each route (and every hit after cache eviction)
   is cold. "It feels slow even warm" almost always means *cold hit often*.
   Profile after `drush cr` AND per-user-cold, not just warm.
3. **Production tracing (e.g. Sentry/APM transaction traces) is the prod
   source of truth.** On a real production transaction, read the DB-query
   span COUNT + total DB time, and the `http.client` spans (external calls in
   the render path). Segment warm (`x-drupal-dynamic-cache: HIT`) vs cold
   (MISS).
4. **Self-time / hotspot profiling will NOT find this.** The cost is hundreds
   of individually-cheap queries summed over a networked round-trip; no
   single function is slow. Don't hunt a hot function — count round-trips.
   "No custom hotspot" does not mean "fast."
5. **Lighthouse measures the FRONTEND layer (LCP / TBT / CLS / bytes). It is
   the wrong tool for a TTFB/backend problem.** Check **Server Response Time
   / TTFB first** to decide which layer you're in. If TTFB is the problem, no
   amount of CSS/JS/critical-CSS work fixes it — and a broken/missing asset
   can even inflate the Lighthouse score by rendering less. Two numbers, two
   layers: TTFB (backend: query count + http.client) vs LCP/TBT/CLS
   (frontend: bytes + render-blocking). Diagnose the layer before spending
   effort.
6. **`http.client` in the render/discovery path is the deadliest cold cost —
   a single one can dwarf all the SQL.** A blocking external request made
   during a *cached* layer (theme/library discovery, preprocess, a formatter)
   only fires COLD, so it is invisible warm-local AND warm-prod, and its
   default connect timeout is paid in full when the target is unreachable.
   Real case from the source codebase: a contrib module's dev-server
   auto-probe fired a `GET http://localhost:5173` per library inside
   `library_info_alter`; nothing listened on that port in production, so cURL
   hung its **30s connect timeout** on EVERY cold render. Cold routes then
   exceeded the host's edge gateway timeout → 504 before the render finished
   → the page could never cache via anonymous HTTP → **permanently broken
   cold** (the "504 cold, fast once warmed, works after retries" signature).
   The perf review missed it because it measured LOCAL wall-time (localhost
   refuses instantly on a dev box — no hang) and never measured a COLD render
   in the production environment. **Enforcement: for any route held to a perf
   bar, `drush cr` then time one cold HTTP hit in the production-like
   environment and assert it completes well under the edge timeout.**
   Diagnostic one-liner: `drush ev` timing one
   `\Drupal::httpClient()->request('GET', <suspect-url>)` →
   `cURL error 28: Connection timed out after 30001 ms` is the tell.
   (A theme that needs build-manifest data should read a local manifest
   file instead of probing a dev server.)

**Cache-backend sizing / eviction (diagnostic, not usually the root cause).**
A small production cache backend (e.g. an undersized Redis with
`allkeys-lru`) that holds a working set bigger than its memory runs FULL and
evicts as fast as it writes — `evicted_keys > 0` and a low hit rate → pages
keep re-rendering cold and never stay warm. Check it before blaming code
(`used_memory`, `evicted_keys`, `keyspace_hits`/`misses`, `maxmemory`). NOTE:
in **drush CLI** context the cache service can report a different backend
than web PHP-FPM uses — confirm via the backend itself, not the CLI service
class. Eviction makes cold pages *appear* unwarmable, but it is a red herring
for a true slower-than-timeout render bug — flush the cache backend entirely
and re-measure on a CLEAN cache to separate "evicted" from "genuinely too
slow" (clean cache still exceeding the timeout ⇒ the render itself is the
problem, e.g. an `http.client` hang).

**The lever that actually moved production:** render-cache keys on inline
blocks + `CacheableJsonResponse` on endpoints — both cut the *cold query
count* that gets recomputed per render. That is why query count, not
wall-clock, is the metric. See `references/caching-lessons.md` §6/§7.

## Performance Testing

**Target metrics** (priority order — see "Measure the right thing FIRST"):
- **Cold-render DB query count: <100 for standard pages, budgeted per route.**
  This is the PRIMARY metric — it predicts production TTFB.
- External `http.client` calls in the render path: 0 (any is a TTFB tax).
- Memory usage: <50MB.
- Local wall time: a WEAK signal only — the local DB is ~10x+ faster than a
  networked production DB, so local ms hides the real cost. Never conclude
  "fast" from local wall time. Use it only for *relative* before/after
  comparison on the SAME host.

### Testing Workflow

1. **Pick the layer first**: is TTFB slow (backend) or LCP/TBT/CLS slow
   (frontend)? Don't profile the wrong layer.
2. **Baseline COLD**: `ddev drush cr`, then profile the first hit per route
   (and a per-user-cold hit for authenticated routes) — not just warm.
   Record the **query count**. A quick local harness: wrap the route render
   in `\Drupal\Core\Database\Database::startLog()` /
   `getLog()` from a `drush php:script` and count non-cache queries.
3. **Estimate prod**: `prod_TTFB ≈ real_query_count × per-query network
   latency + http.client time`.
4. **Make changes**, then re-profile: did the **query count** drop? (Local
   ms may barely move even when production improves a lot.)
5. **Confirm in production** (once deployed): check APM transaction traces
   for the route, warm vs cold, before declaring a win.

## Common Anti-Patterns

### 1. Entity Loading in Templates

**PROBLEM**:
```twig
{# Loads entity on every render #}
{{ node.uid.entity.name.value }}
{{ node.field_reference.entity.title.value }}
```

**SOLUTION — preprocess function**:
```php
function mytheme_preprocess_node(&$variables) {
  $node = $variables['node'];
  $variables['author_name'] = $node->getOwner()->getDisplayName();

  if (!$node->field_reference->isEmpty()) {
    $variables['reference_title'] = $node->field_reference->entity->label();
  }
}
```

**Caveat: moving `node.uid.entity` to preprocess does NOT remove the cost if
the value is the author's display slice (name/avatar) for a LIST/feed/card.**
`$node->getOwner()` (or `->uid->entity`) loads the FULL User entity — one
query per `user__field_*` table per distinct author — whether it runs in Twig
or preprocess. For display-only author surfaces on lists, build a lean
**batched projection service**: one `loadIdentities($uids)` call returning
`{name, uuid, avatar_url, cache_tags}` for N authors in a CONSTANT handful of
batched `IN()` queries, never instantiating a User entity. Two hard
constraints when you do this: (a) raw-SQL projections do NOT auto-bubble
entity cache tags — the consumer MUST add `user:<uid>` tags to the render
array or renames/avatar swaps go stale; (b) the projection must self-filter
blocked accounts (`status = 1`) since it bypasses entity access. See
`drupal-views-patterns` "The lean author projection" for the full pattern.

**For Views card displays the author full-load is usually the VIEW's
eager-load (`Sql::loadEntities()`), not the template** — moving the template
read alone is a no-op. Prove with the probes in `drupal-views-patterns`
("The eager-entity-row trap") and fix at BOTH layers.

### 2. Queries in Loops

**PROBLEM**:
```php
foreach ($nodes as $node) {
  // Query executed N times
  $comment_count = \Drupal::entityQuery('comment')
    ->condition('entity_id', $node->id())
    ->count()
    ->execute();
}
```

**SOLUTION — batch loading**: collect the IDs first, run ONE query with an
`IN` condition, and read from the keyed result inside the loop.

### 3. Loading All Entities Just to Count

**PROBLEM**:
```php
$nodes = \Drupal::entityTypeManager()->getStorage('node')
  ->loadByProperties(['type' => 'article']);
$count = count($nodes);
```

**SOLUTION — count query**:
```php
$count = \Drupal::entityQuery('node')
  ->condition('type', 'article')
  ->count()
  ->execute();
```

### 4. Missing Database Indexes

Slow queries on frequently-filtered fields → add an index via an update
hook (`$schema->addIndex(...)` guarded by `$schema->indexExists(...)`).
Check current indexes: `ddev drush sqlq "SHOW INDEX FROM node_field_data"`.

### 5. Entity Method Calls in Templates

Method calls like `{{ node.getOwner().getDisplayName() }}` or
`{{ node.toUrl().toString() }}` run on every render — move them to
preprocess. Note the same caveat as anti-pattern #1: `getOwner()` still
full-loads the User; fine for a SINGLE node (a detail page), wrong for a
list — batch the authors via a lean projection there.

## Static Caching Pattern

Use for repeated expensive operations within a single request:

```php
function my_module_get_expensive_data($param) {
  $cache = &drupal_static(__FUNCTION__, []);
  if (!isset($cache[$param])) {
    $cache[$param] = expensive_database_query($param);
  }
  return $cache[$param];
}
```

## Render Caching

**ALWAYS include cache metadata in render arrays**:

```php
$build = [
  '#markup' => $content,
  '#cache' => [
    'max-age' => Cache::PERMANENT,  // or seconds
    'contexts' => ['user', 'url.path'],
    'tags' => ['node:' . $node->id()],
  ],
];
```

**Common contexts**: `user` (vary by user), `user.permissions`, `url.path`,
`url.query_args`, `languages:language_interface`. Prefer the narrowest
context that is still correct — a bare `user` context on an inline element
bubbles up and makes the whole page per-user (see `references/caching-lessons.md`
§8).

**Cache tags**: `$entity->getCacheTags()` for entities; custom tags
(`my_module:custom_data`, `node_list:article`) invalidated via
`\Drupal::service('cache_tags.invalidator')->invalidateTags([...])`.

## Database Query Optimization

- **Use EntityQuery** over hand-written SQL for entity data (access
  checking, swappable storage).
- **Batch-load**: `Node::loadMultiple($nids)` — never `Node::load()` in a
  loop.
- **Always `range()` listings** — an unbounded listing query is a time bomb
  on production data volume.

## Finding Performance Issues

```bash
# Find entity loading in templates
grep -r "\.entity\.\|\.getOwner(\|\.referencedEntities(" \
  web/themes/custom/mytheme/templates/

# Find method calls in templates
grep -r "{{.*\\..*(" web/themes/custom/mytheme/templates/

# Find preprocess functions
grep -n "function.*preprocess" web/themes/custom/mytheme/mytheme.theme
```

## Optimization Checklist (before deployment)

- [ ] Cold-render query count measured (after `drush cr`), budgeted, <100
- [ ] Zero external `http.client` calls in the render path
- [ ] No entity loading in templates; no queries in loops
- [ ] Cache metadata present on custom render arrays
- [ ] Custom JSON endpoints use `CacheableJsonResponse`
      (`references/caching-lessons.md` §7)
- [ ] Inline-embedded blocks carry `#cache['keys']`
      (`references/caching-lessons.md` §6)
- [ ] Tested with caching enabled, on production-like data volume

## Apply to Files
- `web/themes/custom/mytheme/mytheme.theme`
- `web/themes/custom/mytheme/templates/**/*.html.twig`
- `web/modules/custom/my_module/src/**/*.php`
- `web/modules/custom/my_module/*.module`

## References
- `references/caching-lessons.md` — eight numbered caching/invalidation
  lessons from real production bugs: tag-narrowing invalidation proofs,
  freshness tests and buckets, baked Views `cache_metadata` re-export,
  real-client latency measurement, high-write counter churn suppression,
  inline-block `#cache['keys']` (§6), `CacheableJsonResponse` endpoint
  bucketing (§7), and diagnosing per-user page caching (§8). This skill's
  checklist points into it — load it whenever a diff touches cache
  tags/contexts, Views result caching, Dynamic Page Cache, or JSON:API
  normalization.
- `references/jsonapi-cache-context-consistency.md` — the VariationCache
  "nothing in common" warning: root cause (mismatched cache-context
  hierarchies between access hooks and the `consumers` module) and the
  linked-contexts solution pattern. Load when running JSON:API with the
  `consumers`/OAuth stack.
- `drupal-views-patterns` — the eager-entity-row trap (the #1 recurring
  Views perf bug) and the View-vs-custom decision.
