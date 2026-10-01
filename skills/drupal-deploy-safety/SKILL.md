---
name: drupal-deploy-safety
description: Things that pass locally and then break, or silently lose data, on a Drupal deploy. Use when planning or running a deploy, writing a hook_update_N / post-update / deploy hook, running drush updb / updatedb / config:import / drush deploy on a remote environment, a site is stuck in maintenance mode after a failed or killed update, adding a column to a custom_field field, an update hook talks to an external API (payment provider, cloud, SaaS), changing a service constructor or *.services.yml / drush.services.yml arguments, a Drush command is missing from drush list, or committing vendor/ for a host that deploys git state (ComposerAutoloaderInit not found). Covers deploy-path planning per change class, the updb → cr → cim → cr tail, maintenance-mode stranding, the custom_field addColumn() truncate trap, update hooks that re-fire on every environment, service arity, Drush command discovery, and committed-vendor autoloader skew.
---

# Drupal Deploy Safety

Most deploy failures are not bugs in the feature. The code works on the
developer's machine. It breaks during the trip to production: the order of
operations, a process that gets killed halfway, a hook that runs once per
database, or a file that never made it into the commit. Each section below
covers one way this happens, why it happens, how to detect it, and the guard.

Commands use `drush @<alias>`. For the Acquia / Terminus / Platform.sh / Upsun /
Lagoon equivalents, see the Remote CLI table in the `drupal-config-mgmt` skill.

Verified against: Drupal core 11.4, Drush 13.7, `drupal/custom_field` 4.0.8,
Composer 2.x.

## When This Skill Activates

- Planning how a change reaches production, or running a deploy tail
- Writing `hook_update_N()`, `hook_post_update_NAME()`, or a Drush deploy hook
- A site stays in maintenance mode after `updb` failed or was killed
- Adding a property/column to a `custom_field` field that already has data
- An update hook writes to something outside the Drupal database
- Changing a constructor that `*.services.yml` or `drush.services.yml` wires
- A custom Drush command is missing from `drush list`
- Committing `vendor/` for a host that deploys git state

---

## 1. Deploy is not a code push

Merging is not deploying. Pushing code to a host changes the PHP files, but on
most hosts it does not change the database or the active config. For every
change that alters DB state, config, or runtime behaviour, answer one question
before you write it: **how does this reach production?** The answer depends on
the change class:

| Change class | Mechanism | Notes |
|---|---|---|
| Config only (field, view, settings, new module) | Committed `config/sync/*.yml` + `core.extension.yml`, applied by config import | Usually no update hook. The config importer enables modules from `core.extension` before it imports their config entities, so a new module's config imports in the same run. |
| Data transformation (rewrite field values, backfill, migrate entities) | `hook_update_N()` (or a post-update / deploy hook, see §2) | Must be idempotent and safe to re-run. |
| Anything import and update hooks cannot express (external service state, secrets, cloud resources, one-off manual steps) | An explicit, ordered list of commands in the plan | Check every step: each code path must resolve via the old source or the new one, never neither. |

**Export config canonically.** Save the entity through its API (the UI, or
`$entity->save()`), then export that one item with
`drush config:get <name> --format=yaml`. If you write raw values through the
config factory, the exported YAML has no calculated `dependencies`. You then
get permanent `config:status` drift and weaker import ordering.

**"Run database updates" only counts as a deploy plan if you actually wrote
the update hook.** Otherwise write out the commands.

## 2. The deploy tail: order matters

The safe order on the target environment:

```bash
# 1. Database updates. LOOP until status is clean; one pass may not drain everything.
drush @<alias> updatedb -y
drush @<alias> updatedb:status        # repeat updatedb until "No database updates required"

# 2. Cache rebuild BEFORE import — the container/caches may still describe the old code.
drush @<alias> cache:rebuild

# 3. Config import (preview first with --no if unsure).
drush @<alias> config:import -y

# 4. Cache rebuild again.
drush @<alias> cache:rebuild

# 5. Verify. Do not trust the success messages.
drush @<alias> config:status          # expect "No differences"
drush @<alias> updatedb:status
drush @<alias> maint:get              # expect 0 (see §3)
```

`drush deploy` packages a simpler version: `updatedb` → `config:import` →
`cache:rebuild` → `deploy:hook`. That is a reasonable baseline. The steps it
leaves out are the ones above: looping `updatedb`, rebuilding between `updb`
and `cim`, and checking afterwards.

**Ordering trap: update hooks run before config import.** A `hook_update_N()`
in this deploy cannot depend on config, fields, or modules that only arrive
through this deploy's config import. They don't exist yet when the hook runs.
Options:

- If the hook needs a module, enable it inside the hook:
  `\Drupal::service('module_installer')->install(['my_dependency']);`
- If the work needs the imported config to exist, put it in a **Drush deploy
  hook** instead: `my_module_deploy_NAME()` in `my_module.deploy.php`. Drush
  runs it with `drush deploy:hook`, which comes after `config:import` in
  `drush deploy`. Deploy hooks are tracked in their own key-value collection
  (`deploy_hook`), apart from update hooks.

## 3. A killed `updb` strands maintenance mode

**What happens.** In `UpdateDBCommands::updateBatch()`, Drush reads
`system.maintenance_mode` from state. If maintenance mode is **off**, Drush
turns it on and appends `UpdateDBCommands::restoreMaintMode(false)` as the
**last operation of the update batch**. If maintenance mode was already on,
Drush neither sets it nor adds a restore step.

So:

- If the `updb` process is killed partway (OOM, timeout, SIGKILL, a dropped
  SSH session), the restore operation never runs. **The site stays in
  maintenance mode.**
- A plain `drush updb -y` retry now sees maintenance mode as already on. It
  adds no restore step, so the site **stays in maintenance mode even after
  the retry succeeds**. The "original value" Drush preserves is the stranded
  one.

**Detect.** After any `updb` that exited non-zero or got killed (for example
exit 137), check:

```bash
drush @<alias> maint:get          # 1 = still in maintenance mode
drush @<alias> updatedb:status
```

**Fix.** Finish the updates first (loop `updatedb` until status is clean, and
check §4's forensics if the run touched data-bearing schema), then clear the
flag explicitly:

```bash
drush @<alias> maint:set 0
drush @<alias> cache:rebuild
```

**Guard.** Put the `maint:get` check in your deploy script after every `updb`
pass. If maintenance mode was off before the deploy and is on afterwards, the
deploy should fail loudly. Wrap the tail in a script so nobody types it by
hand; hand-typed tails are the ones that skip the post-run check.

## 4. `custom_field` `addColumn()` can wipe a field's data

Applies to `drupal/custom_field` (verified on 4.0.8,
`src/Service/UpdateManager.php`).

**What happens.** `UpdateManager::addColumn()` adds a new property to an
existing custom_field field. For each dedicated field table (data and
revision), it:

1. adds the new column,
2. `SELECT`s **every row into PHP memory**,
3. **`TRUNCATE`s the table** (that gets it past
   `FieldStorageConfig::preSave()`'s has-data guard when it saves the new
   `columns` setting),
4. updates the installed field schema in key-value and the field storage
   config, then
5. calls `restoreData()`, which re-inserts the rows through **`batch_set()`**
   in chunks of 50.

`addExtraColumns()` and `removeColumn()` use the same
truncate-then-batch-restore pattern.

Inside `drush updb`, the update functions run as operations of one batch set.
When `batch_set()` is called during a running batch, core's
`_batch_append_set()` inserts the new set **after the current set**. So the
restore only runs after **every remaining update operation** in the run.
Meanwhile `UpdateDBCommands::updateDoOne()` records the schema version
(`setInstalledVersion()`) as soon as the hook function returns.

If the process dies between the hook returning and the restore batch
finishing:

- the truncate has already been committed (TRUNCATE is not transactional on
  MySQL),
- the buffered rows lived only in that PHP process and are gone,
- the hook is already recorded as applied, so the standard "loop `updb` until
  clean" retry **never runs it again**. Nothing re-fires the restore.

The empty field usually throws no error. Empty values are valid, so pages and
APIs just render blank. Users notice before monitoring does.

**Guard (pick one) for any field that has data:**

- **Snapshot in the same hook, before calling `addColumn()`:**

  ```php
  function my_module_update_10001(): void {
    $db = \Drupal::database();
    foreach (['node__field_example', 'node_revision__field_example'] as $table) {
      $backup = '_backup_' . $table . '_10001';
      if ($db->schema()->tableExists($table) && !$db->schema()->tableExists($backup)) {
        $db->query("CREATE TABLE {{$backup}} AS SELECT * FROM {{$table}}");
      }
    }
    \Drupal::service('custom_field.update_manager')
      ->addColumn('node', 'field_example', 'new_property', 'string');
  }
  ```

  Drop the backup tables in a later update, after you've confirmed the row
  counts match. (Check the service id and signature against your installed
  version.)

- **Do the non-destructive equivalent by hand:** add the column with
  `$schema->addField()` on each dedicated table, update the installed schema
  under the `entity.storage_schema.sql` key-value collection
  (`<entity_type>.field_schema_data.<field>`), and write the new `columns`
  setting onto the field storage config. That's everything `addColumn()` does
  except the truncate.

Also rehearse the **interrupted** case on a copy of production data. A
rehearsal where `updb` survives will pass; data is only lost when the run is
interrupted.

**Forensics after a suspect run:**

- An orphaned row in the `batch` table that was never cleaned up.
- Unconsumed items in the `queue` table with names like
  `drupal_batch:<batch id>:<set>`. That's the leftover work of an interrupted
  batch.
- No "Restored N rows for table …" log entries from custom_field for that run.
  `restoreDataBatchFinished()` writes those at info level.
- Row counts on the dedicated field tables compared with a pre-deploy backup.

Before you trust that a deploy's `updb` finished, check both the `batch` and
`queue` tables.

## 5. Update hooks that write a shared external store re-fire

**What happens.** "Run once" for `hook_update_N()` is tracked **per Drupal
database** (the installed schema version). If the hook writes to one shared
external resource (a payment provider, a cloud resource, a SaaS account,
anything not inside the Drupal DB), it runs once for every database that
passes that schema number: production, staging, dev, each local copy, each
clone. Every one of those runs hits the same external store.

A common failure: someone reverts the external change by hand in production.
Weeks later a stale environment or fresh clone runs `updb`, and the hook
quietly re-applies the change.

**Detect.** In the external store's audit trail, look for create/update bursts
that line up with deploys or DB refreshes of non-production environments, or
that happen faster than a human could click.

**Guard.**

- Prefer a one-off Drush command or script run deliberately against one
  environment, and record somewhere durable that it ran.
- If it must be a hook, **don't gate idempotency on the external store's
  current state**. An out-of-band revert leaves nothing the hook can see.
  Gate on durable per-item "already provisioned" state that you control, and
  make non-production environments skip external writes (check an
  environment setting).
- After the one-time event has happened, **neuter the hook at the same
  number**:

  ```php
  function my_module_update_10002(): void {
    // One-time external provisioning already executed in production.
    // Kept as a no-op so databases behind this schema version advance cleanly.
    return;
  }
  ```

  Don't delete or renumber it. Databases behind this schema version still need
  to pass the number cleanly.

## 6. Service definition arity

**What happens.** Drupal builds a service from its **definition**, not from
the class's `create()`. `Drupal\Component\DependencyInjection\Container`
instantiates with `new $class(...$arguments)`, positionally. If you add or
remove a constructor parameter without updating the `arguments:` list in
`*.services.yml`, nothing fails at lint, at commit, or in most unit tests
(they construct the class by hand). You get an `ArgumentCountError` the first
time the service is instantiated after the container rebuilds on the target.
For an event subscriber, access checker, or anything else on the request path,
that means every request fails.

There's a second window as well. The compiled container definition is cached
in the `cache.container` bin. Even a correct constructor + YAML change throws
on the target until `drush cr` rebuilds it, because the cached definition
still has the old argument list. That's one reason the tail in §2 rebuilds
caches early.

Drush has the same failure. A `drush.command`-tagged service in
`drush.services.yml` is built by Drush's `LegacyServiceInstantiator` with
`ReflectionClass::newInstanceArgs()` from the definition's `arguments:`.
`create()` is never called, and the exception isn't caught, so **every Drush
command that bootstraps Drupal fails**. That includes the `drush cr` you'd use
to recover.

**Guard: a static arity test.** Write a Unit test (no bootstrap; booting the
container is exactly what hides the problem) that:

1. Parses every `*.services.yml` (including `drush.services.yml`) in your
   custom modules with `Symfony\Component\Yaml\Yaml::parse(...,
   Yaml::PARSE_CUSTOM_TAGS)`.
2. For each service with a `class:` in your own code, reads the constructor
   (via `ReflectionMethod`, or by tokenizing the source if you want no
   autoloading at all) and counts **required** and **total** parameters.
3. Asserts `required <= count(arguments) <= total`. Use a range, not
   equality: optional parameters may be supplied. A trailing variadic removes
   the upper bound.
4. Handles the shapes it can't check by **name and count**, so a skip can't
   grow silently: `parent:` with no `class:`, `parent:` + own `arguments:`
   (Symfony merges by index), `factory:` (the contract is the factory method,
   not `__construct`), `abstract:`, `autowire:`, and classes outside your
   code. For `parent:` + `class:` with no own arguments, inherit the parent's
   argument count and check that.
5. Includes RED-proof fixtures: a definition one argument short and one
   argument over, each of which must fail.

It runs in about a second. Put it in the pre-push checks.

## 7. Drush command discovery: two load paths

Verified against Drush 13.7 (`Boot/DrupalBoot8.php`,
`Runtime/ServiceManager.php`, `Runtime/LegacyServiceFinder.php`,
`Runtime/LegacyServiceInstantiator.php`).

A module's command class is loaded **only** by one of these:

1. **Autodiscovery.** Files under `<module>/src/Drush/Commands/` whose names
   match `*Command.php` / `*Commands.php`, in namespace
   `Drupal\<module>\Drush\Commands`. `ServiceManager::instantiateServices()`
   calls the class's static `create()` if it has one. Otherwise it calls a
   bare `new $class()`. This is the current, recommended mechanism.
2. **`drush.services.yml`.** A service tagged `drush.command` in the module's
   `drush.services.yml` (or a file named in the module's `composer.json`
   `extra.drush.services`). Drush marks this mechanism legacy/deprecated. It
   is built from the definition's arguments (see §6).

Failure modes:

- **Dead command.** A `drush.command` tag in an ordinary
  `<module>.services.yml`, with the class outside `src/Drush/Commands/`. Drush
  reads neither, so the command is just missing from `drush list` with no
  error.
- **Silent instantiation failure.** A class under `src/Drush/Commands/` with a
  required constructor parameter and no static `create()`. The fallback
  `new $class()` throws `ArgumentCountError`, and `instantiateServices()`
  catches it and logs it **only at debug level**
  ("Could not instantiate …"). The command just doesn't exist. Add
  `public static function create(ContainerInterface $container): static`.
- **Shadowed logger.** A `DrushCommands` subclass that declares its own
  `$logger` property, including a constructor-promoted
  `protected LoggerInterface $logger`. `DrushCommands::logger()` asserts that
  the property is null or a `DrushLoggerManager`, and
  `ServiceManager::inflect()` calls `logger()` while it wires every
  instance. Put a plain PSR logger in that slot and the assertion fires during
  Drush bootstrap. With assertions enabled (`zend.assertions=1`, typical on
  dev), that takes down **every** Drush command. Name the property something
  else (`$channelLogger`), or use `$this->logger()`.

Watch out when fixing a "dead command" by moving it into a reachable path:
that's the first time anything constructs the class. A latent shadowed-logger
or arity bug that never mattered while the class was unreachable now breaks
for real. Run `drush list` and `drush core:status` after the move.

**Guard.** A static test, like §6: every `drush.command` service must live in
`drush.services.yml`; every class under `src/Drush/Commands/` with a required
constructor parameter must declare `create()`; no `DrushCommands` subclass may
declare `$logger`. Include a mutation fixture for each rule. In CI, compare
`drush list --format=json` against the commands you expect.

## 8. Committed-vendor deploys: autoloader skew

Applies to hosts that deploy committed git state and run no `composer install`
on the server.

**What happens.** The Composer autoloader class name carries a suffix
(`ComposerAutoloaderInit<suffix>`, `ComposerStaticInit<suffix>`) that appears
in **three** files:

- `vendor/autoload.php`, at the vendor root (it's **not** inside
  `vendor/composer/`)
- `vendor/composer/autoload_real.php`
- `vendor/composer/autoload_static.php`

Composer picks the suffix from the `config.autoloader-suffix` setting if one
is set. Otherwise it reuses the suffix it finds in the existing
`vendor/autoload.php`. Failing that, it generates one (recent Composer 2.x
uses the lock file's content-hash, else random bytes). If the suffix rotates
and you stage only `vendor/composer/`, the entry point and the class it loads
disagree. Drupal's `autoload.php` requires `vendor/autoload.php` on every
request, so the result is a site-wide fatal:
`Class "ComposerAutoloaderInit<old>" not found`.

**Guards.**

- Pin the suffix so it never rotates:

  ```json
  "config": { "autoloader-suffix": "my_project" }
  ```

- When you actually add or remove a package, stage `vendor/autoload.php`,
  `vendor/composer/`, any added or removed package directories, and
  `vendor/drupal/DrupalInstalled.php` (generated by
  `drupal/core-composer-scaffold`), all together.
- Add a pre-commit or pre-push check: extract the suffix from all three files
  in the **staged/committed** tree (`git show :vendor/autoload.php`, or
  `HEAD:` for a push) and fail if they differ.
- **Never commit a dev-dependency autoloader.** Build the committed vendor with
  `composer install --no-dev --optimize-autoloader`. You can check it:
  `vendor/composer/installed.php` has `'dev' => false` under `root` for a
  `--no-dev` build. Fail the check if it's `true`, or if dev-only packages
  (phpunit, etc.) show up in the committed classmap.
- Don't "prepare a push" by running `composer install --no-dev` in your
  working copy: `git push` ships commits, not the working tree. Build the
  production vendor in a separate checkout, or in CI.
- Don't fix a skew by regenerating in a throwaway checkout and copying files
  back. The optimized classmap comes from scanning files **on disk**, so a
  checkout that lacks untracked package files produces a smaller classmap.
  Reconcile forward: commit the entry point to match the already-committed
  pair, then diff against a clean `--no-dev` build.

---

## Pre-deploy checklist

- [ ] Every change has a stated deploy path: config import, update/deploy hook, or a written command list with no breakage window.
- [ ] Config was exported per item from a real entity save, and `dependencies` are present.
- [ ] No update hook relies on config/modules that arrive in the same import. Modules are enabled in the hook, or the work is in a deploy hook.
- [ ] The tail is scripted: loop `updatedb` until status is clean → `cr` → `config:import` → `cr` → `config:status` clean.
- [ ] `maint:get` is checked after every `updb` pass, and the flag is cleared explicitly after a killed run.
- [ ] No `custom_field` `addColumn()` / `addExtraColumns()` / `removeColumn()` on a data-bearing field without a same-hook snapshot. The interrupted case has been rehearsed.
- [ ] After a suspect run, the `batch` and `queue` tables are checked for orphans and field table row counts compared.
- [ ] No update hook writes an external store unless it's gated on durable per-item state and skipped off production. One-time hooks are neutered in place.
- [ ] Static service-arity test passes (`*.services.yml` and `drush.services.yml`).
- [ ] Drush discovery test passes. Custom commands appear in `drush list` on the target.
- [ ] Committed vendor: suffix pinned, all three autoloader files agree, `--no-dev` build, package files staged.
