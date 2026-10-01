---
name: drupal-views-patterns
description: Working with Drupal Views — both the build/optimize mechanics (cache plugins, exposed filters, pager, relationships, row plugins, REST/data_export displays, render caching, query cost) AND the decision of whether to use a View at all vs. a custom controller/query/JSON:API. Load when creating ANY listing/feed/table/grid/leaderboard/block-of-rows or REST/JSON listing endpoint; when a View is slow or loads full entities it does not render; when adding/editing exposed filters, sorts, pagers, relationships, or a view's cache settings; or when deciding "View vs custom vs JSON:API" for a new query surface.
---

# Drupal Views Patterns

Views is load-bearing on most mature Drupal sites — and it is routinely the
**#1 cold-render query-cost source**. This skill has two halves: **(A)
general Views best practices** and **(B) the "View vs custom" decision.**
The lessons here were empirically verified on a large production Drupal 11
codebase (59 views / ~250 displays); measure claims the way
`drupal-performance` says: **cold-render real-SQL query COUNT, not local
wall-clock.**

On some projects the primary listing surfaces (library, leaderboard, events,
profile) are hand-built SDC routes via custom controllers rather than Views;
apply part B before reaching for a View for any new listing.

---

## A. General Views best practices

### A1. Cache plugin: pick the freshness class deliberately (`Tag` vs `Time` vs `None`)
Every Views display has a **results cache** (the SQL result) and an
**output/render cache** (the themed markup), governed by its cache plugin:
- **`Tag`** (default for content views) — cached until a relevant entity/list
  cache tag is invalidated. Use for surfaces that must update **immediately**
  when content changes (a newly published item must appear). The "immediate"
  freshness bucket.
- **`Time`** — cached for a fixed TTL regardless of content changes. Use when
  bounded staleness is acceptable AND the entity tags churn too fast for
  `Tag` to help (e.g. a leaderboard over entities whose counter fields are
  bulk-updated every few minutes — `Tag` would re-render it cold for
  everyone constantly). The "hours" bucket.
- **`None`** — recomputed every request. Almost always wrong for a public
  list.

See `drupal-performance`'s `references/caching-lessons.md` for the freshness-bucket framework (immediate /
minutes / hours) and the tag-vs-TTL asymmetry.

### A2. Exposed filters add a `url.query_args` cache context — design around it
An exposed filter makes the result vary by query string, so Views adds
`url.query_args` (or `url.query_args:<key>`). Correct, but each distinct
filter/sort/page combination is a separate cache entry.
- Don't expose filters you don't need — each multiplies the cache keyspace.
- Query args are part of the result-cache key — so when measuring a
  view-backed endpoint, measure the EXACT request including query args
  (`drupal-performance` references/caching-lessons.md §4), and know that a warmer hitting the bare
  view does NOT warm the real client's keyed entry.
- Prefer a small fixed set of exposed options over free-text where possible.

### A3. Pager cost: the count query is not free
The full/mini pager runs a separate **COUNT** query per render; on large base
tables that COUNT can dominate. If you don't need a total/page-count, use the
**"some"** pager (fixed N, no count) or a mini pager. Typical split: fixed-N
dashboard blocks use `some`; an infinite-scroll feed keeps the count only
because its UX needs it.

### A4. Row plugin: `entity:<type>` vs `fields` — and the eager-load trap
- **`fields`** row — you pick exact columns; Views builds a lean SELECT.
  Cheapest; best for a few simple values.
- **`entity:<type>` + view mode** row — each result is rendered through the
  entity template/preprocess (reuses SDC cards). Convenient, but it **loads
  the full entity** and, via entity-base relationships, eager-loads related
  full entities through `Views\Sql::loadEntities()` (every field table) even
  if the template shows 3 fields. The biggest Views perf trap (see "The
  eager-entity-row trap" below).

### A5. Relationships: each is a JOIN + (for entity-base relationships) a full-entity eager-load
- A relationship adds a JOIN. A relationship whose base table is an **entity
  base table** (`users`, `node_field_data`, …) makes Views eager-load that
  related entity for **every** row, via `Sql::loadEntities()` →
  `getEntityTableInfo()`. This loads the FULL entity (all N field tables)
  even if the template reads 3 fields.
- **`required` does NOT control the eager-load — this is empirically
  proven.** `required: true|false` only chooses the JOIN type (INNER vs
  LEFT). The eager-load fires for ANY instantiated entity-base relationship
  regardless of `required`. Flipping `required: false` changes the cold
  related-entity field-table query count by **0**. Do not "fix" an
  eager-load by setting `required: false`.
- **What actually stops the eager-load: remove the relationship from the
  display, AND set the display's `defaults.relationships = false`.**
  Per-display config inheritance is the trap: most block displays DON'T
  override `relationships` — they INHERIT the `default` display's
  relationships. Writing `relationships: []` on the display is a NO-OP
  because an empty section is treated as "inherit"; you must mark the
  section as overridden:
  ```php
  $opts = $cfg->get("display.<disp>.display_options");
  $opts["defaults"]["relationships"] = false;   // override, do NOT inherit
  $opts["relationships"] = [];                   // own (empty) set
  $cfg->set("display.<disp>.display_options", $opts)->save();
  ```
  Verify with the probes below: `getEntityTableInfo()` must return ONLY the
  base entity.
- **Caveat — the relationship may be RE-INSTANTIATED by a filter/sort/argument
  that references it.** If a display's filter or sort handler runs through the
  relationship (e.g. a filter on a field of the related user), you cannot just
  drop it; you'd have to re-express that handler against a non-entity table
  (e.g. exclude on the node's own `node_field_data.uid` instead of the user
  relationship). That is real filter-semantics work — verify the result set
  is byte-identical before/after (a rushed re-expression of an exclusion
  filter once silently broke it and had to be reverted).
- **Audit rule:** if no filter/sort/argument/field handler references the
  relationship, it exists only to feed `node.uid.entity` in the template —
  remove it + `defaults.relationships=false`, and fetch the few needed fields
  with a lean projection (below).

### A6. Avoid unintended `DISTINCT` / `GROUP BY`
Aggregation/"distinct" toggles and one-to-many relationships can silently
turn a simple query into a grouped/temp-table query. If a view is slow, dump
the real SQL:
`ddev drush ev '$v=\Drupal\views\Views::getView("ID");$v->setDisplay("DISP");$v->build();print (string)$v->build_info["query"];'`

### A7. Render caching bubbles up — preserve it through wrappers
A view's tags/contexts/max-age bubble into whatever renders it. Wrapping a
view block in a lazy builder must preserve the inner cache metadata
(`CacheableMetadata::createFromRenderArray($block_content)`) or Dynamic Page
Cache can serve stale content. A view's `cache_metadata` is **baked into
exported config at entity-save time** — changing a handler's
`getCacheTags()`/`getCacheContexts()` requires resaving + re-exporting the
view, not just editing PHP (`drupal-performance` references/caching-lessons.md §3).

### A8. `rest_export` / `data_export` displays = a free listing endpoint
A `rest_export` display serializes the same filtered/sorted/access-controlled
result as JSON (etc.) with no controller or normalizer wiring. One view
definition can drive BOTH an HTML display and an endpoint — a strong reason
to keep a view when a listing needs both. (Distinct from JSON:API — see B.)

### A9. Config discipline
Views are config entities — materialize one at a time, never blanket
`cex`/`cim` (export surgically):
`ddev drush config:get views.view.<id> --format=yaml > config/default/views.view.<id>.yml`.
Export via a real save so `dependencies` + baked `cache_metadata` are
correct.

---

## B. View vs. custom vs. JSON:API — the decision

Don't ask "Views or custom?" in the abstract. Ask **"which Views benefits am
I actually using?"**

### The benefits a View buys (use a View when you're using ≥2)
1. **Exposed filters** = auto input UI + query-arg→WHERE parsing +
   validation + cache context (the admin-listing sweet spot — `watchdog`,
   `user_admin_people`, `content`, `media_library` are all views).
2. **Pager / infinite-scroll / multi-sort.**
3. **Access plugin** (per-display `_permission`/role as a cache context).
4. **Cache plugin tag/time split** (A1) — the freshness-class machinery.
5. **Free REST/data_export endpoint or feed** (A8).
6. **Entity-row rendering into existing templates/SDCs** (A4) — convenient;
   watch the trap.

### Lean toward CUSTOM (controller + `entityQuery`/`Select` + render array/SDC) when:
- The query is **fixed server-side** (constant filters, one sort, top-N) —
  no exposed inputs, so Benefit 1 is unused.
- It's a **per-user computed surface where you're fighting Views' cache
  contexts** — you keep adding `#lazy_builder`/placeholder hacks to stop a
  `user` context bubbling. (Real case: a per-user Views block ran ~169
  SQL/render and forced a `user` context onto the page; replaced by a cached
  endpoint + client render.)
- You need **only a few fields per row** and a view would eager-load full
  entities (the trap) — a projection query is leaner and trivially
  profilable.
- The "list" is really **bespoke layout/logic**, not rows-of-the-same-thing.

### Use JSON:API (NOT a Views REST export) when:
- It's a **shared data endpoint an external client also consumes** — keep
  one contract on the standard JSON:API surface. Views REST exports are for
  site-internal/feed cases, not a shared data layer.

### The agent-era adjustment
Historically a big reason to use Views was **authoring convenience** — a
human assembling a query visually instead of writing SQL, and getting
filter-input forms / query-arg parsing for free. **When an agent is building
it, weight the runtime/maintenance benefits (1–6), not authoring
convenience.** An agent can hand-write the `entityQuery`, the filter/sort
plumbing, and query-arg parsing directly, and a small custom controller is
then usually faster at runtime, easier to profile, and easier to keep off
the cache-context footguns. "It was easier to click together" is no longer,
by itself, a reason to choose a View.

---

## The eager-entity-row trap (the recurring Views perf bug)

`row: entity:node` + an entity-base relationship (e.g. `uid` → `users`) ⇒
Views eager-loads the FULL related entity per row via `Sql::loadEntities()`
(all N field tables), even to render 3 fields. Concrete measured case: card
displays inherited a `uid` relationship so the card template could reach
`node.uid.entity`; the template read only an avatar, a name, and a flag, yet
each row pulled a author User entity spanning ~36 field tables — five such
blocks on one dashboard = **216 cold `user__field_*` queries**. On some of
those displays nothing even used the relationship.

**PROVE the mechanism before touching anything (the relayed cause was right
but the "fix" everyone assumed was wrong).** The load is NOT the template's
`node.uid.entity` read — it's the view's eager-load. Two cheap empirical
probes settle it:
1. **Phase split** — render the display through `execute()` vs full render,
   count related-entity field-table queries per phase. If they all land in
   `execute()` and render-phase = 0, it's the view eager-load and a
   template/preprocess projection ALONE is a NO-OP.
   ```php
   $v=\Drupal\views\Views::getView("my_view"); $v->setDisplay("block_1");
   \Drupal\Core\Database\Database::startLog("x"); $v->execute("block_1");
   // count FROM user__field_* in getLog("x") → these load in execute(), not render
   ```
2. **getEntityTableInfo probe** — confirms WHICH entity tables the eager-load
   will hit:
   ```php
   $v->build("block_1");
   print_r($v->getQuery()->getEntityTableInfo()); // [node=>…, uid__node_field_data=>entity_type:user]
   ```
   A `…=>entity_type:user` entry ⇒ the eager-load will `loadMultiple()` those
   users. After the fix it must contain ONLY the base entity (`node`).
3. **Backtrace probe** (when you need the exact caller): a temporary
   `hook_user_load()` that dumps `debug_backtrace()` once — expect
   `Sql::loadEntities()` ← `ViewExecutable::execute()`, nailing it to the
   view, not the template.

**Fix (don't abandon the view — it's still doing filters/sorts/pager/access/
cache). TWO parts, BOTH required:**
- **(view) Stop the eager-load** by removing the relationship AND setting
  `defaults.relationships = false` on the display (see A5 — `required:
  false` is a NO-OP, and a bare `relationships: []` is treated as inherit).
  Only safe where no filter/sort/arg references the relationship; where one
  does, the eager-load stays unless you re-express that handler on a
  non-entity table.
- **(template/preprocess) Stop `node.uid.entity`** — render author
  avatar/name from a **lightweight batched projection** (below), built once
  per view-render in preprocess, instead of `node.uid.entity`. Bubble the
  `user:<uid>` cache tags it returns (a raw-SQL projection does NOT
  auto-bubble them).
- A larger entity static cache does NOT help — empirically proven: raising
  `entity.memory_cache.slots` 1000→50000 changed the count by 0. The loads
  are per-view inside `Sql::loadEntities()`, not cache eviction.

### The lean author projection
The reusable read-side for display-only author surfaces: a small service
whose `loadIdentities(array $uids)` returns
`[uid => {uid, name, uuid, avatar_url, cache_tags}]` in a **CONSTANT
handful of batched IN() queries regardless of N**, never instantiating a
User entity. Use it anywhere a surface shows only the public author slice.
Three non-obvious constraints:
1. **Cache tags don't auto-bubble.** A raw-SQL projection bypasses
   entity-load tag bubbling. The service returns `cache_tags` per row; the
   consumer MUST add `user:<uid>` to `$variables['#cache']['tags']` or a
   rename/avatar-swap goes stale.
2. **Access — exclude blocked accounts.** The projection filters
   `status = 1`; a deactivated author never surfaces. (The full-entity path
   relied on entity access; the projection must self-filter.)
3. **Entity-cache reuse (when NOT to use it).** Only project where the full
   entity isn't ALSO loaded elsewhere in the same render — if another block
   on the page full-loads the same user anyway, the lean path can be
   net-NEGATIVE (measured: 72→75 queries). Measure first.

### Per-display caveat: a view-level eager-load BATCHES; per-row preprocess does not
Removing the eager-load is only a win if the projection is ALSO batched at
the view-render level. Measured failure mode: a display's relationship was
removed but its per-node preprocess still called `$node->getOwner()` per row
— without a view-level batch point the route regressed **144 → 363
queries**. The win case ran the projection once per
`preprocess_views_view` with ALL rows. If the consumer renders per-row
(entity view mode + `preprocess_node`), you need a view-level pre-pass that
projects every row's author into a map the per-row preprocess reads —
otherwise keep the batched eager-load.

## Auditing an existing slow view — procedure
1. Dump config: `ddev drush ev` over
   `Views::getView(id)->storage->get('display')` — displays, filters, sorts,
   args, relationships, row plugin, cache plugin. Note
   `defaults.relationships` per display (absent/true ⇒ INHERITS the default
   display's relationships — the eager-load trap).
2. List which handlers actually USE each relationship. An entity-base
   relationship NO handler references ⇒ eager full-entity load to fix:
   remove it + `defaults.relationships=false` + a lean projection (A5; NOT
   `required:false`, which is a no-op). One that IS referenced ⇒ either keep
   the eager-load or re-express the handler on a non-entity table (verify
   result set unchanged).
3. Confirm cache plugin matches freshness class (A1;
   `drupal-performance`'s references/caching-lessons.md).
4. Check pager count cost (A3) and unintended DISTINCT/GROUP BY (A6).
5. Re-render cold, count `*__field_*` / non-cache SQL before/after
   (`drupal-performance`). The phase + getEntityTableInfo probes above
   pinpoint the eager-load.
6. **TDD the fix** — the eager-load is config (baked into the view), so a
   budget test must assert the EXPORTED config value
   (`defaults.relationships === false`) AND a render-time related-entity
   field-table query-count budget (RED→GREEN by reverting).
7. Only replace the whole view if it uses ~none of Benefits 1–6 — then it's
   pure overhead.

## Bottom line
Keep the View when you're using its machinery (exposed filters / pager /
REST endpoint / admin listings / tag-time cache split) and fix the row's
data access. Go custom when you're using ~none of it — especially per-user
surfaces fighting cache contexts, or few-field rows that a view would bloat
into full-entity loads. Use JSON:API for client-shared endpoints. And in
the agent era, judge on runtime cost, not authoring convenience.
