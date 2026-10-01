
# Drupal Caching & Backend-Perf Lessons

Each rule below is a lesson from a real production bug on a large Drupal 11
codebase, generalized. Apply the matching one whenever a diff touches
caching, cache tags/contexts, Views result caching, Dynamic Page Cache, or
JSON:API normalization.

## The one principle behind all of these

**Test (and deploy) the *effective artifact*, not the source.** A caching
change is correct only if the thing that actually runs in production — the
committed config, the invalidation on the real write path, the warm hit-rate
on the real client URL — reflects it. A green test of the source method or a
warm number on a paraphrased request proves nothing.

---

## 1. Narrowing or removing a cache tag requires an invalidation-path proof

Removing a tag from a response / render array — especially a broad `*_list`
tag — silently changes the freshness contract: every write the removed tag
used to cover must now trip the narrower replacement tag, or cached data
goes stale (a new entity never appears, a deleted one lingers, a count never
updates). When a diff drops an `addCacheTags` entry, **confirm every write
path the old tag covered invalidates the replacement, and write a test that
mutates via the REAL path (the hook/service that runs in production) and
asserts the cache busts.**

Real-world case: dropping a broad `node_list:<type>` tag from a ranked feed
delayed new items from appearing, because the per-entity update path
(`ScoreUpdater`-style service) never invalidated the narrower replacement tag
— only a periodic batch job did. Code review caught it; the instinct of
swapping a broad tag for a narrow one, by itself, did not surface the gap.

## 2. A caching change ships a freshness test

For any surface users expect to update when its data changes — a feed
showing a new upload, a membership list reflecting a join, a stat after a
write — a caching change MUST include a test that mutates via the REAL path
and asserts the cached surface reflects it (the inverse of the cache-hit
test).

**Classify each cached surface by required freshness:**

| Bucket | Mechanism | Examples |
|---|---|---|
| **immediate** | tag-invalidate on the write path → freshness-tested | a feed showing a new item, a membership list, a stat after a write |
| **minutes** | a TTL is acceptable | a slow-refreshing external data set (e.g. 15 min) |
| **hours** | slow-changing → TTL fine, call it out explicitly | an all-time leaderboard/ranking (e.g. 6h) |

Deliberate staleness is fine ONLY for the **hours** bucket and must be called
out explicitly. The failure mode this prevents: stale feeds, week-late
stats, "I did the thing and don't see it reflected."

**The asymmetry:** switching a view's result cache to **time-based (a TTL)**
trades freshness for hit-rate and is only safe for the hours bucket.
**Tag-based** stays fresh-on-write and is the default for everything users
act on. Removing a per-*user* cache context (to collapse Dynamic Page Cache
cardinality) is NOT the same as adding a TTL — it keeps the freshness tags,
so content still busts on write.

## 3. Code that feeds baked config must be re-materialized AND tested as the deployed artifact

Some PHP computes values that Drupal **freezes into exported config at
entity-save time, not at `cim` time** — most notably a Views handler's
`getCacheContexts()` / `getCacheTags()` / `getCacheMaxAge()`, which are baked
into each display's `cache_metadata` when the view is saved. `drush cim`
imports that YAML verbatim (it runs with `isSyncing()`, so it does NOT
recompute the metadata). So editing such a method has **ZERO production
effect until the source entity is resaved and re-exported** — dead on
arrival via the normal `cim` deploy path even though the code is correct.

The done-gate for any such change MUST:
1. Resave the source entity (`$view->save()` or a UI save) so the metadata
   regenerates.
2. Export the single changed config (`ddev drush config:get views.view.<id>
   --format=yaml > config/default/views.view.<id>.yml` — never a blanket
   `cex` — export surgically) and commit
   it, verifying the diff actually reflects the change.
3. Write the regression test against the **exported config value** (e.g.
   assert `views.view.<id>` → `<display>` → `cache_metadata.contexts` lacks
   `user`), NOT just the source method — a test of the method alone goes
   green while the deployed artifact stays stale.

**Contrast — what DOES deploy via `cim` cleanly:** a raw display option like
`display_options.cache.type` (a tag→time cache-plugin switch) is read at
`cim` time, so it deploys fine. Only *computed/baked* metadata
(`cache_metadata.*`) needs the resave+export. Generalize: when a change's
effect lives in committed config, the test asserts the committed config and
the done-gate proves the committed config changed.

## 4. Perf changes need a real-client latency measurement, not a paraphrase

When a change targets endpoint/query latency, measure the EXACT request the
client sends — same path, same query string (JSON:API `include`/`fields`),
same auth context — not a simplified URL. **Views' result-cache key folds in
`url.query_args`**, so a bare `/jsonapi/views/<view>/default` warms a
**different** result-cache key than a real client's
`?include=…&fields[…]=…` request. A "warm" number on the bare URL proves
nothing about the real client path — and a cache warmer built against the
bare view will not warm the client's actual cache entry.

**Measure QUERY COUNT, not local wall-clock — and the COLD path.** Local
DDEV's DB is same-container (sub-millisecond/query); a networked production
DB is roughly an order of magnitude slower per round trip. A cold
authenticated render doing hundreds of queries can look fast locally and be
slow in production purely from network latency — local ms hides the real
cost. The environment-invariant metric is **cold-render query count**. See
`drupal-performance`'s "Measure the right thing FIRST" section for the full
methodology this lesson feeds into.

---

## 5. High-write counters: keep the field, suppress the list churn

When a field is rewritten far more often than its entity's real data
changes — an engagement counter (view/download/vote count, a stats field)
updated by a bulk importer or cron job — a normal `$entity->save()` busts
the broad list tags (`node_list`/`user_list`/…) **and** `4xx-response` on
every tick, for a counter that changes no list membership.

Do **not** move the counter off the entity into a side table just to fix
this: if the counter is displayed per-entity, serialized to an API, and
sorted on in Views, moving it adds a JOIN to every view that sorts on it, a
query per API serialization, and a migration. Keep it a field; suppress only
the over-invalidation:

- Override `invalidateTagsOnSave()` on the entity (not
  `getListCacheTagsToInvalidate()` — the latter still leaves `4xx-response`
  busting) so a counter-only **UPDATE** busts only the entity's own tag
  (`node:N`/`user:N`) — so a user viewing that entity sees the fresh count —
  and skips the list tags. **Inserts fall through to normal invalidation**,
  so new entities still invalidate the list and appear correctly. Gate on
  `$update` so a genuinely new entity is never silently treated as
  counter-only.
- A one-shot flag set by the writer before `save()`, reset in `postSave()`,
  keeps this opt-in per write rather than blanket behaviour on the entity
  type.
- The trade-off: any listing/ranking display that shows the raw count
  lags until it otherwise rebuilds — acceptable when that listing is
  already in the "hours" freshness bucket (lesson 2).

## 6. A custom block embedded inline needs `#cache['keys']` or it recomputes every render

Dashboard/listing controllers that embed blocks inline
(`$build['x'] = $block->build()`) only get a render-cache entry when that
element declares `#cache['keys']`. Without keys, `build()` re-runs **every**
query on **every** page render, for **every** user. Dynamic Page Cache
hides this locally (same-container DB makes the extra queries cheap) but not
on a networked production DB.

Fix: set `#cache['keys']` in `build()` so the block is render-cached and
reused, with contexts scoped as **shared as correctness allows**:
- Global content that's identical for everyone (e.g. latest-of-each-type,
  access-checked but not personalized) → a context that resolves
  identically for all users (e.g. `user.node_grants:view` when node access
  is a no-op on the site) rather than the broader `user` — same effective
  sharing, narrower churn.
- Genuinely per-user (your stats, your next item) → `user`; still
  render-cached, just per user, which is a large win over uncached.
- Keys can be nested one level deep (`$build['widget']['#cache']`) — the
  renderer caches that element. Don't assume top-level is the only place a
  cache key can live.
- An inline block that fires an external HTTP call must cache the
  **failure** too (`if ($cache !== FALSE)`, negative-TTL) or it re-calls
  every render.

## 7. Custom JSON endpoints aren't Dynamic-Page-Cache-cached unless the response is a `CacheableResponseInterface`

A controller returning a bare `Symfony\...\JsonResponse` is **never**
cached: Dynamic Page Cache bails at
`if (!$response instanceof CacheableResponseInterface) return;`. So every
poll recomputes all queries. JSON:API/REST escape this only because their
`ResourceResponse implements CacheableResponseInterface` (via
`CacheableResponseTrait`) and bubble entity cacheability. Do the same with
core's **`CacheableJsonResponse`** + a `CacheableMetadata` on the **success**
return (leave 4xx/5xx bare — never cache errors):

```php
$response = new CacheableJsonResponse($data);
$response->addCacheableDependency(
  (new CacheableMetadata())->setCacheContexts(['user'])->setCacheTags(['node_list:article', 'my_module_progress:' . $uid])
);
```

Bucket every GET endpoint before caching — **misclassifying per-user as
shared is a cross-user data leak (security bug), not just a perf nit**:
- **Shared/global** (a static list, a config-derived widget, per-entity
  thumbnails) → context `[]` (or `user.permissions`/`url.query_args` if it
  truly varies that way). One entry for everyone — biggest win. Test:
  cross-user HIT (user B's *first* request is already HIT).
- **Per-user, low churn** (progress, profile, memberships) → context
  `['user']` + a **per-user tag** `<module>_<thing>:{uid}`, invalidated for
  just that uid in a save/flag hook. NEVER bust a high-cardinality per-user
  cache with a **global list tag** — that wipes every user's entry on any
  user's action, which is worse than uncached.
- **Per-user, high churn** (notifications, unread counts, live status) → do
  NOT response-cache (churn + eviction beat the hit rate); reduce queries
  instead.
- **Rendered entities / access-filtered content** → NOT shared: rendered
  output often carries per-user state (like/bookmark flags) or is
  membership-filtered. Either per-user or don't cache; never `[]`.
- **Never cache**: short-lived credentials, pre-signed URLs, side-effecting
  redirects — a cached copy outlives its validity or is unsafe.

Pin it with a test asserting repeat GETs return
`X-Drupal-Dynamic-Cache: HIT` (per-user or cross-user, depending on the
bucket) and that a per-user-tag bust produces a MISS.

## 8. Diagnosing WHY an authenticated page is cached per-user

Authenticated pages are Dynamic-Page-Cache-cached **per user** when a render
element with a bare `user` cache context renders inline and bubbles `user`
up to the page — wasteful, since the first cold cost is then paid by every
user instead of shared per-role. Two Drupal debug tools find the culprit
(both are **dev-only `services.yml` parameters — set, `drush cr`, inspect,
then REVERT**; never commit them, they leak cache metadata in production
headers and break tests):

- **`http.response.debug_cacheability_headers: true`** → response headers
  `X-Drupal-Cache-Contexts` / `-Tags` — the page-level TOTAL contexts. Curl
  an authenticated route; if the contexts include a bare `user` (not just
  `user.permissions`/`user.roles`), the page is per-user.
- **`renderer.config: { debug: true }`** → wraps every cached render element
  in HTML comments (`<!-- CACHE-HIT -->`, `CACHE CONTEXTS:`, `CACHE KEYS:`,
  …). Curl the page, then find the bubbling element: lines that are exactly
  `   * user` under a `CACHE CONTEXTS:` block, and read the adjacent
  `CACHE KEYS:` to identify it.

**Why inline `user`-context elements aren't always auto-deferred:** Drupal
normally auto-placeholders high-cardinality contexts via
`renderer.config.auto_placeholder_conditions.contexts` (default `['session',
'user']`) — a `user`-context element becomes a BigPipe placeholder, so it
does NOT bubble `user` to the page. If a site has removed `user` from that
list (sometimes done so a module's `cachePerUser()` doesn't make Dynamic
Page Cache refuse entirely with "UNCACHEABLE"), the trade-off is pages now
cache per-user instead of being uncacheable — worth knowing if a page you're
debugging is unexpectedly per-user despite no obvious per-user content.

## Generalizable stack facts behind these traps

- **A mass-update importer or cron job that saves many entities on a tight
  interval** is a common churn source — it busts broad list tags and
  per-entity normalization caches on every run, which is why tag-cached
  listings/feeds fed by that data can be perpetually cold. Fixing this
  properly means decoupling the importer from the broad list tag, which
  needs a freshness design first (lesson 2) — don't do it reactively.
- **The Views result cache** (`time`/`tag` plugin) caches result rows; the
  **JSON:API normalization cache** caches serialization, keyed per entity +
  fields and tagged `<entity_type>:N`. They invalidate independently — a
  Views cache bust does not imply a JSON:API normalization cache bust, and
  vice versa.
- **If node access is a no-op on a site** (only a default `all`/`all`
  grant, no per-grant rows), then `user.node_grants:view` resolves
  identically for every user — a view carrying it can still share one cache
  entry across users, which is a cheap freeness check when auditing a view's
  cache context.
- **Over-fetch is a payload problem, not just a latency problem.** A client
  request that pulls large fields (e.g. a raw waveform/blob field) or deep
  relationship includes for a card that only displays a summary bloats every
  response regardless of cache state. Trimming the client's requested
  fields/includes is the fix — server-side caching cannot shrink a payload
  the client asked for.

## Related

- The parent `drupal-performance` SKILL.md — the full "measure the right
  thing first" methodology (cold-render query count vs local wall-clock)
  that lesson 4 builds on.
- `drupal-views-patterns` — the eager-entity-row trap and the View-vs-custom
  decision, which interact heavily with cache-context choices here.
- `drupal-config-mgmt` — the `cim`/`cex` mechanics that lesson 3's carve-out
  builds on.
- `drupal-testing` — test-authoring patterns the freshness tests
  in lesson 2 follow.
