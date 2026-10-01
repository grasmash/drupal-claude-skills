# Canvas SDC Registration, Config Entities and Deploys

Rules for getting a Twig SDC into Canvas's registry and keeping its
`canvas.component.*` config entity stable across environments. Class and
method names were checked against Canvas 1.7.1 source; re-check them after an
upgrade.

## Contents

1. [Registration rules checklist](#1-registration-rules-checklist)
2. [Export the auto-created config entity](#2-export-the-auto-created-config-entity)
3. [Canvas module upgrade: re-export drifting component config](#3-canvas-module-upgrade-re-export-drifting-component-config)
4. [`Different` after a config import: noise or drift?](#4-different-after-a-config-import-noise-or-drift)
5. [Content templates have no node-level in-context editor](#5-content-templates-have-no-node-level-in-context-editor)

---

## 1. Registration rules checklist

**Rule:** an SDC is only usable as a Canvas component if its metadata passes
Canvas's requirements check. On every cache rebuild Canvas's `hook_rebuild`
runs `ComponentSourceManager::generateComponents()`, which calls
`SingleDirectoryComponentDiscovery::checkRequirements()` and from there
`ComponentMetadataRequirementsChecker::check()` for each SDC. A component that
fails gets no `canvas.component.sdc.*` config entity, and an existing one is
disabled.

**What the source guarantees:** an ineligible SDC is disabled in Canvas. It
cannot be placed in the editor, and the reasons are recorded (see below). The
failure is silent: no error at build or cache-rebuild time.

**Unexplained observation (not a proven mechanism):** 5xx responses with
`ComponentNotFoundException` were seen on deployed environments on routes that
Twig-`include()` an SDC missing prop titles, while the same code rendered
locally with `canvas_dev_mode` enabled, and adding the titles was followed by
the errors stopping. The Canvas 1.7.1 source does not explain this:
`canvas_dev_mode` only removes the `Choice` constraint on the component
`source` key, Canvas's `ComponentPluginManager` does not filter SDCs by
eligibility, and core throws `ComponentNotFoundException` only when the SDC
plugin itself is missing. One plausible, unverified alternative is SDC
discovery cached by a cache rebuild that ran before the code sync finished. So
treat the checks below as cheap insurance, not as a proven fix for that
symptom.

Checklist for every `*.component.yml`, complete for
`ComponentMetadataRequirementsChecker::check()` in **Canvas 1.7.1**
(props whose type is a Drupal `Attribute` are skipped):

- [ ] The component's `group` is not `Elements` (reserved)
- [ ] Every slot has `title:`
- [ ] Every prop has `title:`
- [ ] No `enum` (or array `items.enum`) contains an empty string
- [ ] Every **required** prop has `examples:` with at least one value, except content-entity-reference props
- [ ] The first example validates against the prop's schema (Canvas uses it as the default value)
- [ ] The first example can actually be used as a default for the prop's storable shape ("example value ... cannot be used as a default" otherwise)
- [ ] Required array props declare `minItems: 1` (or higher)
- [ ] `minItems` appears only on required array props
- [ ] `maxItems`, if set on an array prop, is at least 2 (use a non-array type for single values)
- [ ] `x-formatting-context` on an HTML (`contentMediaType: text/html`) prop is `inline` or `block`
- [ ] Content-entity-reference props are optional, carry no `examples:`, and pass Canvas's content-entity-reference schema validation
- [ ] Every prop's shape maps to a field type/widget Canvas can store. Object-typed props are the usual failure: an unstorable shape produces "Drupal Canvas does not know of a field type/widget to allow populating the `<prop>` prop"

Separately, `SingleDirectoryComponentDiscovery::checkRequirements()` excludes
components with `status: obsolete` or flagged `noUi` on purpose.

**Where the reasons are recorded:** `ComponentIncompatibilityReasonRepository`,
backed by the key-value collection `canvas:component:reasons`. Read them
directly instead of guessing:

```bash
ddev drush php:eval 'print_r(\Drupal::service(\Drupal\canvas\ComponentIncompatibilityReasonRepository::class)->getReasons());'
```

An empty result for your component plus a `canvas.component.sdc.<ext>.<name>`
entity in `config:status` / `config:get` means it registered.

**Cheap insurance before shipping:** with `canvas_dev_mode` uninstalled and a
fresh cache rebuild, confirm the component has no recorded reasons and render
something that includes it. This matches how production runs; it is not a
proven fix for the observation above.

```bash
ddev drush pm:uninstall canvas_dev_mode -y && ddev drush cr
# load a page (or run a test) that includes the component; it must not throw
ddev drush en canvas_dev_mode -y   # only if you use it locally
```

A cheap durable guard is a kernel or functional test that loops over every
component in your theme and renders each one with dev mode off.

---

## 2. Export the auto-created config entity

**Rule:** every new eligible SDC causes Canvas to create a config entity
`canvas.component.sdc.<extension>.<component-name>` on the next cache rebuild
(the id is `sdc.` plus the SDC plugin id with `:` replaced by `.`). It exists
only in the database until you export it. Export it **in the same change** that
adds the component.

**Why:** if the YAML is not in the sync directory, `config:status` lists it as
"Only in DB", and the deploy's full config import **deletes** it. The component
then breaks on that environment even though its Twig/CSS/JS shipped.

**How:**

```bash
ddev drush cr
ddev drush config:get canvas.component.sdc.mytheme.my-component --format=yaml \
  > config/sync/canvas.component.sdc.mytheme.my-component.yml
```

Use your project's sync directory in place of `config/sync`. `config:get`
output can end with an extra blank line; trim it to a single trailing newline
if your linter (for example phpcs `EndFileNewline`) flags it. Export only the
named object; do not run a blanket `config:export` to pick it up.

**Detect:** `ddev drush config:status | grep canvas.component.sdc` showing
"Only in DB" for a component you just added.

---

## 3. Canvas module upgrade: re-export drifting component config

**Rule:** after updating the Canvas module, re-export every
`canvas.component.*` object whose state is `Different`, in the same change as
the upgrade.

**Why:** each component's `active_version` is a hash computed by
`ComponentSourceBase::generateVersionHash()` over the config-schema-cast
settings, slot definitions and prop schema. A Canvas release can change those
inputs (for example how values are cast) without your settings changing. On the
next `drush cr`, `hook_rebuild` recomputes the hash, sees it differ, archives
the old version under its old hash and saves a new `active_version`. If you do
not re-export, the committed YAML keeps the old hash: every config import
restores it and the next cache rebuild recomputes the new one. That loop never
converges and buries real drift under every component on each `config:status`.

**How:**

```bash
# after updating Canvas and running database updates
ddev drush cr
# list the drifting component objects (surgical, not a full export)
ddev drush config:status --format=json | python3 -c \
  "import json,sys; d=json.load(sys.stdin); [print(k) for k,v in d.items() if k.startswith('canvas.component') and v.get('state')=='Different']"
# re-export each name
ddev drush config:get <name> --format=yaml > config/sync/<name>.yml
```

Expected per-object diff: exactly two keys. `active_version` moves to the new
hash, and `versioned_properties` gains one archived entry keyed by the old hash
whose settings are identical to `active`.

**Confirm convergence before committing:** `config:status` shows zero
`canvas.component.*` as `Different`, and it **stays zero across two more
`drush cr` runs**. If anything re-drifts after a rebuild, the export did not
capture a stable hash; stop and investigate rather than committing.

**Do not prune** archived `versioned_properties` entries. Stored component
trees pin a component version, and removing a version they reference breaks
them.

---

## 4. `Different` after a config import: noise or drift?

**Rule:** a `canvas.component.*` object reported `Different` right after
`config:import` is often versioned-config recompute, not a real change. Check
the diff before acting on it.

**Why:** importing a component's YAML sets its `active_version` from the file;
the cache rebuild that follows can recompute a newer hash and archive the
imported one, as described in section 3. `config:status` then reports the
object `Different` even though its settings match the committed file.

**How to tell:**

```bash
diff <(ddev drush config:get canvas.component.<id> --format=yaml) \
  config/sync/canvas.component.<id>.yml
```

- **Recompute noise:** only `active_version` and one extra archived
  `versioned_properties` entry differ, with settings byte-identical. The
  committed YAML holds an older hash generation; re-export it (section 3) so it
  converges instead of recurring on every import.
- **Real drift:** settings, slot definitions or other keys differ, the object
  is "Only in DB" or "Only in sync dir", or a non-Canvas object is listed. Investigate
  those as normal config drift.

---

## 5. Content templates have no node-level in-context editor

*Verified on Canvas 1.7.1 through 1.9.0 (checked August 2026). Re-check on
newer releases.*

**Rule:** do not plan an editorial UX that relies on opening the Canvas editor
on a node rendered by a content template. Content templates render nodes
correctly (field-bound props, caching), but editors change the node's values
through the regular node edit form, not in Canvas.

**Why:** `/canvas/editor/node/{id}` on a templated node fails at every
permission level tested. A restricted editor gets 403 because the node has no
Canvas field; a template administrator or superuser gets the editor shell, but
its layout and entity-form API requests return 500.
`ComponentTreeLoader::getCanvasFieldName()` throws "For now Canvas only works
if the entity is a canvas_page!" for any other entity type or bundle. Editing a
templated entity's field values inside Canvas is tracked upstream in
[drupal.org/i/3498525](https://www.drupal.org/i/3498525) and had no fix as of
the versions above.

**Detect:** a 403 or 500 when opening the Canvas editor for a node whose bundle
uses a content template; the `LogicException` message above in the logs.
