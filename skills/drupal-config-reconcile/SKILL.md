---
name: drupal-config-reconcile
description: Reconcile Drupal configuration drift between a working tree and a deployed environment one item at a time, deciding import (disk wins) vs export (DB wins) vs skip for each difference. Use when `drush config:status` shows drift, after pulling a fresh DB, before a deploy, or when local config and a remote/prod environment disagree. Pantheon/Terminus-aware but works with any remote alias; never writes to production.
---

# Drupal Config Reconcile

A guided workflow for resolving the gap between your tracked config (`config/default`, plus any split dirs) and a deployed environment's active configuration. Most teams have the mechanics (`config:status`, `cim`, `cex`) but no disciplined way to walk drift item-by-item and decide which side wins. This is that discipline.

## The core decision: import vs export vs skip

For every divergent config item, exactly one of three things is true, and you pick a direction:

- **Import = disk → DB.** The tracked file is the source of truth; it deploys to the environment on the next code deploy + config import. No file change — you keep what's in git.
- **Export = DB → disk.** The environment's value wins; you write its config into your tracked files (or `git rm` the file if the environment doesn't have it).
- **Skip.** Leave the divergence unresolved and move on (the right call for benign `uuid`/`_core`-only diffs).

> **Never run config write operations against production.** This workflow only *reads* from a reference environment and only *writes* to local files. It never writes to any remote database.

### Remote CLI — host-neutral

Examples below use Pantheon's **Terminus**. The workflow is the same on any host — substitute your platform's remote-drush command. If your platform provides Drush site aliases, the generic `drush @<alias> <cmd>` form works everywhere and is the simplest baseline.

| Task | Generic (Drush aliases) | Pantheon (Terminus) | Acquia (`acli`) | Platform.sh / Upsun | Lagoon (amazee.io) |
|---|---|---|---|---|---|
| Remote drush | `drush @<alias> <cmd>` | `terminus drush <site>.<env> -- <cmd>` | `acli remote:drush -- <cmd>` | `platform drush -e <env> -- <cmd>` (Upsun: `upsun drush …`) | `lagoon ssh -p <project> -e <env> -C "drush <cmd>"` |
| Refresh non-prod DB from prod | `drush sql:sync @<prod> @<env>` | `terminus env:clone-content <site>.live <env> --db-only` | Cloud UI **Copy database** / `acli api:environments:database-copy` | `platform sync data` (Upsun: `upsun sync data`) | drush `sql:sync` or a Lagoon post-rollout task |
| Pull DB to local | `drush sql:sync @<env> @self` | (drush `sql:sync`) | `acli pull:db` | `platform db:dump` | `lagoon ssh … -C "drush sql:dump"` |
| Get Drush aliases | aliases in `drush/sites/` | `terminus aliases` | `acli remote:aliases:download` | `platform`-provided `@platform.<env>` | `drush sa` (Lagoon-provided) |

> **Auth/link once per platform:** Pantheon `terminus auth:login`; Acquia `acli auth:login` + `acli link`; Platform.sh/Upsun `platform login` / `upsun login`; Lagoon `lagoon login`. Never run write/clone operations *into* production on any of them.

## Workflow

### 1. Pick a reference environment (never `live`/`prod`)

Use a non-production environment as the prod stand-in (e.g. Pantheon `dev`/`test`, or a CI/staging alias). Refuse to target the live environment — config writes against live are how teams nuke production config.

### 2. Make the reference DB fresh

The diff is only meaningful if the reference env reflects current production. If the env's DB is stale (commonly >24h), refresh it from live first. On Pantheon:

```bash
terminus env:clone-content <site>.live <env> --db-only -y   # Pantheon; see the table above for acli / platform / upsun / lagoon
```

Cloning modifies a shared environment and takes minutes — **confirm with the user first; never do it silently.** (Note: most platforms can't reliably tell you when an env was last refreshed — `terminus backup:list` reports *backup* recency, not clone-from-live recency. Treat it as a weak hint and ask.)

### 3. Get the diff on the reference env (not locally)

Run `config:status` **on the reference env** so Drupal applies config splits and `config_exclude_modules` correctly — a local run produces false positives from dev-only modules (devel, views_ui, a prod split, etc.):

```bash
terminus drush <site>.<env> -- config:status --format=json   # or your platform's remote-drush form (see table)
```

States you'll see:
- **`Only in DB`** — exists in the env's database, not in tracked config.
- **`Only in sync`** — exists in tracked config, not in the env's database.
- **`Different`** — present in both, content differs.

Empty list → "in sync, nothing to reconcile" → stop.

### 4. Fetch the env's value per item with `config:get` (not a full export)

Do **not** reach for `config:export --destination` + scp — config_split commonly fails trying to create its relative split dir under a temp destination, and SSH-command discovery is brittle across Terminus versions. Fetch each item on demand:

```bash
terminus drush <site>.<env> -- config:get <name> --format=yaml > /tmp/ref-<name>.yml   # or your platform's remote-drush form
```

`config:get --format=yaml` emits the exact file format Drupal exports (no `_core` key) — byte-identical to tracked sibling files.

**Caveat:** `config:get` appends an extra trailing newline. Drupal's phpcs (`Drupal.Files.EndFileNewline.TooMany`) rejects two newlines at EOF and a pre-commit hook will block the commit. Normalize to exactly one trailing newline when you write the file:

```bash
printf '%s\n' "$(cat /tmp/ref-<name>.yml)" > config/default/<name>.yml
```

### 5. Walk each item, one at a time

Create a todo list (one entry per config name) so progress is visible. Process in this order — `Only in DB`, then `Different`, then `Only in sync` — and for each:

1. **Locate the local file.** Usually `config/default/<name>.yml`. If absent there, check split dirs (`config/prod/`, `config/local/`, `config/envs/…`) before concluding it's missing — split-managed items live outside `config/default` and must be written back to the same split dir.
2. **Show the content diff** (label left = local/disk, right = env/DB):
   - `Different`: `diff -u config/default/<name>.yml /tmp/ref-<name>.yml`
   - `Only in DB`: local absent → show the env's full content.
   - `Only in sync`: env absent → show the local file's full content.
3. **Recommend a direction, and say why:**
   - `Only in DB` → **Export.** Config created in the environment (UI or update hook) that should be captured into git (message templates, view displays, etc.).
   - `Only in sync` → **Import.** New config added in code, not yet deployed; keep it and let it deploy.
   - `Different`:
     - Only `uuid` and/or `_core` differ → **Skip** (benign environment artifact; don't churn files).
     - Env has real intentional-looking value changes → **Export.**
     - Local file has intentional code changes → **Import.**
     - Genuinely unclear → present both sides plainly, default to **Skip**, let the user decide.
4. **Ask** Import / Export / Skip.
5. **Perform it — local files only:**
   - **Export** (`Different`/`Only in DB`): write the env's file with the trailing newline normalized (split-managed items → split dir). `Only in sync` + Export means the env doesn't have it → confirm, then `git rm` the local file.
   - **Import**: keep the local file; no change. ⚠️ **`Only in DB` + Import is destructive** — the env has config absent from git, so a full `drush cim` on deploy will **delete it from the environment**. Warn explicitly and require a second confirmation.
   - **Skip**: nothing.

### 6. Verify with the import transformer — NOT `config:status`

After writing exported files, do **not** re-run `config:status` to confirm — it can keep reporting a freshly-written item as `Only in DB` even though the file is present and valid (a stale display artifact). Verify against the storage layer `cim` actually uses, the import transformer (which applies config_split exactly as a deploy does):

```bash
drush ev '
$t = \Drupal::service("config.import_transformer")->transform(\Drupal::service("config.storage.sync"));
foreach (["<name1>","<name2>"] as $n) {
  print "$n => " . ($t->exists($n) && in_array($n, $t->listAll(), true) ? "RECONCILED (deploy-safe)" : "MISSING — would be deleted on cim") . "\n";
}'
```

`exists() && in listAll()` = YES means a real deploy keeps the config. Use this — not the `config:status` table — as the source of truth for "did my export take?"

### 7. Summarize and hand off

- **Exported (env → git):** files created/overwritten/removed.
- **Kept for deploy (import):** items whose local version reaches the env on next deploy.
- **Skipped:** unresolved divergences and why.

Then show `git status` + `git diff --stat config/`, and **do not auto-commit or push** — ask first. Remember that Import items only take effect after the code deploys and a config import runs on the environment.

## Gotchas

- `config:status` on the reference env compares *that env's* sync dir vs its DB — it won't see your **uncommitted** local edits. Commit/deploy your edits first, then reconcile remaining drift.
- Config splits: `prod`/`local` split items live in `config/prod` / `config/local`, not `config/default`. Always write Export results back to the file's real location.
- `uuid`-only or `_core`-only diffs are almost always benign — don't churn files over them.
