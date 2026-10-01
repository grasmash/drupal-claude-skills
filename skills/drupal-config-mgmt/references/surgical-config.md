# Surgical Config Changes

How to change configuration one named object at a time, so you only ever touch the config you meant to touch. Written for AI agents and for any tree that carries unrelated config drift.

## Contents

- [Why not blanket cex/cim](#why-not-blanket-cexcim)
- [The single-config toolkit](#the-single-config-toolkit)
- [The core.extension.yml exception](#the-coreextensionyml-exception)
- [Save through the entity API, not a raw config write](#save-through-the-entity-api-not-a-raw-config-write)
- [Baked config: PHP values frozen at save time](#baked-config-php-values-frozen-at-save-time)
- [Verify an import with config:status](#verify-an-import-with-configstatus)
- [Shipping a config-only change](#shipping-a-config-only-change)

## Why not blanket cex/cim

A full `drush cex` writes **every** active-vs-sync difference to disk, not just the one you changed. A full `drush cim` imports **every** difference, including deletions of config that exists only in the database. In a working tree with drift you don't know about (another developer's half-finished change, a module's settings tweaked through the UI, config that only exists on one environment) either command sweeps that drift into your commit or your database.

**Rule:** an agent never runs blanket `cex`/`cim` in a tree with unrelated drift. Operate on one named config object at a time. Leave the full import to the deploy pipeline, where it is expected and reviewed.

**Detect:** after an export, `git status config/` shows files you did not intend to change. After an import, content or settings you never touched have changed or disappeared.

## The single-config toolkit

The active database is the source of truth. Materialize only the object you changed:

```bash
# Export one object from the active DB into the sync directory
ddev drush config:get <name> --format=yaml > config/<dir>/<name>.yml

# Set one key (simple config; see the entity-API note below for config entities)
ddev drush config:set <name> <key> <value> -y

# Delete one object
ddev drush config:delete <name> -y

# Read / verify
ddev drush config:get <name>
ddev drush config:status
```

Never hand-author the YAML. Make the change through the UI, code that saves the config entity, or `config:set` for simple config, then export that one object with `config:get` and commit it.

To apply a single file in the other direction, use a partial import from a directory that holds only that file. Under DDEV, drush runs inside the container, which cannot see the host's `/tmp`. Create the directory inside the project root (mounted at `/var/www/html` in the container), pass the absolute container path, and delete it afterwards so it never reaches git:

```bash
mkdir -p .config-one && cp config/<dir>/<name>.yml .config-one/
ddev drush config:import --partial --source=/var/www/html/.config-one --no   # preview
ddev drush config:import --partial --source=/var/www/html/.config-one -y
rm -rf .config-one
```

Without DDEV, plain `drush` on the host can use any directory, such as one under `/tmp`:

```bash
mkdir -p /tmp/one && cp config/<dir>/<name>.yml /tmp/one/
drush config:import --partial --source=/tmp/one --no
```

## The core.extension.yml exception

Do **not** export `core.extension` with `config:get`. A real `cex` removes modules listed in `$settings['config_exclude_modules']` (typically development modules such as `devel` or `stage_file_proxy`) from the exported `core.extension.yml`. `config:get` reads the raw active config, so it re-adds every excluded module, and the next deploy would enable them everywhere.

**Fix:** when you enable a module, hand-add the single line to `core.extension.yml` under `module:` (keeping the existing sort: by weight, then name):

```yaml
module:
  my_module: 0
```

**Detect:** `git diff config/<dir>/core.extension.yml` shows more than the one module you enabled, usually development modules.

## Save through the entity API, not a raw config write

Config entities (fields, views, image styles, blocks, and so on) calculate their `dependencies` key when saved through the entity API (`$entity->save()` or the UI). A raw config-factory write (including `drush config:set`, which edits the config object directly) such as:

```php
\Drupal::configFactory()->getEditable('views.view.my_view')->set('display.default...', $value)->save();
```

stores the data but skips dependency calculation. The exported YAML is then missing or carrying stale `dependencies`, which shows up as:

- permanent `config:status` drift that comes back after every export, and
- weak import ordering: `cim` cannot tell it must import the object after the config or module it depends on.

**Fix:** load and save the config entity so dependencies are recalculated, then export that object:

```php
$view = \Drupal\views\Entity\View::load('my_view');
// ...modify...
$view->save();
```

Use raw config-factory writes only for simple config (no `dependencies` key), or where you deliberately need to bypass entity hooks and then re-save the entity afterwards.

## Baked config: PHP values frozen at save time

Some exported config holds values that PHP **computed** when the config entity was last saved. The common case is a View: each display's `cache_metadata` (contexts, tags, max-age) is collected from its handlers' `getCacheContexts()` / `getCacheTags()` / `getCacheMaxAge()` at save time and written into the exported YAML.

Changing that PHP has no effect on a deployed site until the config is regenerated. `cim` imports the YAML verbatim and never recomputes it.

**Fix (all three steps):**

1. Re-save the source entity after the code change (UI save, or load-and-save in code).
2. Re-export that one object with `config:get` and commit the changed YAML alongside the code.
3. Test the **exported config value** (parse the YAML and assert the computed key), not only the PHP method. A unit test of the handler passes while production still serves the old baked value.

**Detect:** the PHP method returns the new value, but `config:get views.view.<id>` (or the committed YAML) still shows the old `cache_metadata`.

## Verify an import with config:status

`cim` can report success while objects failed to import, were skipped, or drifted again immediately. After any import, local or remote:

```bash
ddev drush config:status
```

The expected result is "No differences between DB and sync directory" (or only differences you can explain, such as split-managed config). Treat the import's own success message as unverified until `config:status` agrees.

## Shipping a config-only change

For a change that is purely config (a field, a view, a settings form value), the committed YAML plus the matching `core.extension.yml` line is usually the whole deploy: the pipeline's `cim` applies it, and the config importer enables new modules before importing config entities, so a new module's config imports cleanly in the same run. No update hook is needed.

Use a `hook_update_N()` only for data changes (rewriting field values, backfills, state). Update hooks run during `updatedb`, **before** `cim`, so they cannot rely on config or modules that only arrive in that deploy's import.
