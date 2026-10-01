---
name: drupal-vite-theme
description: Patterns and pitfalls for a fast custom Drupal 10/11 theme built with Vite + Tailwind CSS v4 + Single Directory Components (SDC) via the drupal/vite module. Use when creating or changing a Vite-built theme, editing vite.config.js, *.libraries.yml with `vite:` keys, Tailwind v4 `@theme`/tokens/preflight, SDC component CSS, content-hashed dist assets or the Vite manifest; when a cold render is slow or 504s ("gateway timeout cold, fine after retries", "works for anonymous, hangs for logged-in"), assets 404 after a deploy, a JS/CSS fix "works locally but not in prod", styles silently vanish (tokens resolve to nothing, images cropped wrong, list bullets gone), or committed dist drifts from a fresh build. Covers the drupal/vite dev-server probe, `version:`/`preprocess:` rules, anti-monolith bundling, owning the markup, View Transitions + Speculation Rules instead of a JS framework.
---

# Drupal Vite Theme (Vite + Tailwind v4 + SDC)

A server-rendered Drupal theme where **Vite owns bundling**, the **drupal/vite**
module maps library source paths to content-hashed build output, **Tailwind v4**
supplies utilities and design tokens, and **SDC components** carry their own
CSS. The goal is a theme that stays fast as it grows: page-cacheable anonymous
pages, near-zero JS, per-route CSS that grows sublinearly.

This is a patterns-and-pitfalls skill, not a tutorial. Each lesson is
**rule → why → detect/fix**.

**Verified against:** drupal/vite **1.5.1**, Drupal core **11.4**, Vite **6.4**,
Tailwind CSS **4.3** (`@tailwindcss/vite` 4.3). Re-check version-bound claims
when you upgrade.

**Scope:** this skill covers the Drupal side of the build (library wiring,
hashed assets, SDC). If the theme also ships a JavaScript framework (React,
Vue, Angular, Svelte, Alpine, etc.), find and load a skill for that framework
too (`npx skills find <framework>`) and follow its current best practices,
including security guidance (XSS via `v-html`/`dangerouslySetInnerHTML`, build
config, dependency audit). For `drupalSettings` use `drupal-performance` for
cache contexts, and use `processed` rather than raw field values for markup.

## When This Skill Activates

- Building or restructuring a theme on Vite / Tailwind v4 / SDC
- Editing `vite.config.js`, `mytheme.libraries.yml` (`vite:` keys), `mytheme.info.yml` (`vite:` block), or `settings.php` `$settings['vite']`
- Cold-render slowness / 504s on a Vite-managed theme
- Asset 404s or stale assets after a deploy or rebuild
- Tailwind v4 surprises: tokens not applying, preflight side effects, unexpected dist churn
- Reviewing a theme change before commit

Related skills: `drupal-performance` (cold-render methodology; the dev-server
probe is also covered there as an `http.client` case), `drupal-canvas-sdc`
(component.yml / SDC authoring), `design-review` (visual QA).

---

## 1. The dev-server probe trap (highest value)

**Rule:** In every deployed environment, turn the drupal/vite dev-server
detection **off explicitly**. Do it in `settings.php`, not only in the theme's
info file.

```php
// settings.php (committed) — deployed default: always serve built dist.
$settings['vite'] = [
  'useDevServer' => FALSE,
];
```

```yaml
# mytheme.info.yml — belt and braces; documents intent next to the theme.
vite:
  useDevServer: false
```

**Why (drupal/vite 1.5.1, `src/AssetLibrary.php`):**

- `vite_library_info_alter()` → `Vite::processLibraries()` calls
  `AssetLibrary::shouldUseDevServer()` for **every Vite-managed library**.
- When the resolved `useDevServer` is `NULL` (unset) or `'auto'` — the default —
  it makes a live `GET` to the dev-server URL (`devServerUrl`, default
  `http://localhost:5173`) with Drupal's `http_client`, which core configures
  with `timeout => 30` (`Drupal\Core\Http\ClientFactory`). Any exception just
  returns FALSE, so the failure is silent.
- This runs while building library definitions, which are cached in the
  discovery cache. So it only costs anything on a **cold** library build (after
  a cache rebuild, a deploy, or cache eviction) and is invisible on warm
  requests and in warm local testing.
- Where nothing listens and the connection is *refused*, the probe is cheap.
  Where packets are *dropped* (typical of locked-down containers and PaaS app
  servers), each probe waits out the timeout. A cold render can then exceed the
  edge/gateway timeout, return 504 **before it finishes**, never populate the
  cache, and stay broken until something manages to warm it.

**Signature:** "gateway timeout when cold, fine after a few retries, fast once
warm"; or "anonymous pages fine, logged-in pages hang" (anonymous hits the page
cache; authenticated users render cold per user through Dynamic Page Cache).
Fine in drush, broken over HTTP.

**Why settings.php and not only info.yml:** `resolveViteSetting()` resolves in
this order, later wins:

1. `$settings['vite'][<key>]` — global default
2. the extension's `.info.yml` `vite:` block
3. the library's `vite:` block in `*.libraries.yml`
4. `$settings['vite']['overrides'][<extension>][<key>]` or
   `['overrides']['<extension>/<library>'][<key>]`

The global setting reads `Settings` only, with no dependency on the extension
list, so it covers every Vite-managed library from every module and theme.
`getViteSettingFromExtensionDefinition()` does read the info.yml `vite:` block,
but the info.yml key alone has been observed to still let the probe fire on
authenticated web requests while drush showed it disabled; the cause was not
identified. Do not trust either layer on faith: verify the effective behaviour
on the deployed environment with a cold render (`drush cr`, then time the
first authenticated request; see Detect below). Note that a library or info file explicitly
setting `useDevServer: auto`/`true` beats the global default. To force it off
regardless, use `$settings['vite']['overrides']['mytheme']['useDevServer'] = FALSE`.

**Detect:**

```bash
# Is anything leaving Drupal for the dev server on a cold build?
drush cr && time curl -s -o /dev/null -w '%{http_code}\n' https://{site}/{route}

# Time the probe itself from the app server:
drush php:eval '$t=microtime(TRUE); try { \Drupal::httpClient()->request("GET","http://localhost:5173"); } catch (\Throwable $e) { echo get_class($e), ": ", $e->getMessage(), "\n"; } echo round(microtime(TRUE)-$t,1), "s\n";'
```

PHP slow logs showing `curl_exec` under `AssetLibrary::shouldUseDevServer` are
conclusive. Pin the fix with a test that asserts `Settings::get('vite')['useDevServer'] === FALSE`.

**Local HMR without reopening the trap:** keep the committed value `FALSE` and
opt in only from a gitignored `settings.local.php`. Because info.yml
`useDevServer: false` outranks the global default, a local opt-in must use the
`overrides` key:

```php
// settings.local.php (gitignored, never deployed)
$settings['vite']['overrides']['mytheme']['useDevServer'] = TRUE;
```

Then `npm run dev` and `drush cr`. Remove the line and `drush cr` to go back to
dist.

---

## 2. Content-hashed filenames, never a `version:` pin

**Rule:** Let Vite emit content-hashed filenames (`assets/[name]-[hash].js`,
`build.manifest: true`) and let drupal/vite rewrite library source paths through
`dist/.vite/manifest.json`. Do **not** put a `version:` key on Vite-managed
libraries.

```yaml
# mytheme.libraries.yml
base:
  vite: true
  css:
    theme:
      src/css/base.css: { preprocess: false, minified: true }
  js:
    src/js/base.js: { preprocess: false, minified: true, attributes: { type: module } }
  dependencies:
    - core/drupal
```

**Why:** the hash changes exactly when content changes, so the URL is the cache
key and browsers/CDNs can cache forever. A pinned `version:` is the opposite
failure for unhashed files. In core 11.4, `JsCollectionRenderer` appends
`?v=<version>` to unaggregated JS when the library has a version, and the
cache-clear query string only when it does not. So a JS fix shipped under an
unchanged `version:` keeps the **same URL**: `drush cr` cannot bust browser or
CDN caches for it. (Unaggregated CSS always gets the cache-clear query string.)

**Detect (stale-asset check):** a JS fix on a `version:`-pinned library that
"works locally but not in prod", "works in incognito", or "keeps regressing" is
a frozen URL until proven otherwise. Only unaggregated (`preprocess: false`)
JS is exposed: core's aggregated assets get filenames hashed from file contents
(`AssetGroupSetHashTrait::generateHash()` replaces the version with a content
hash, used by `JsCollectionOptimizerLazy`), so they change when the file does:

```bash
curl -s https://{site}/{route} | grep -o '{asset-name}[^"]*'
```

If the server already serves the new file contents, the problem is client
caching. Fix: drop `version:` and serve hashed files.

**A rebuilt dist needs a cache rebuild.** The module rewrites paths while
building library definitions, and those are cached (its README says the same
about switching to the dev server). After deploying a dist with new hashes,
cached library info and render-cached fragments, BigPipe placeholder payloads
included, can still reference the **old** hashed URLs. With
`build.emptyOutDir: true` those files are gone, so they 404. A 404 on a CSS file
attached to a BigPipe placeholder can abort the placeholder replacement
entirely: the block never appears, and the console shows "Refused to apply
style … MIME type ('text/html')". Run `drush cr` on each environment after a
deploy that changes hashes. If the host clears caches automatically, confirm it
really covers discovery and render caches.

---

## 3. Anti-monolith asset rules

**Rules:**

- `preprocess: false` on every Vite-built file. Vite has already bundled and
  minified it; letting Drupal aggregation re-concatenate it into its own
  aggregate files throws away the hashed per-entry URLs and the per-route split
  Vite produced.
- No `version:` key (section 2).
- **Never `@import` a glob of everything into one entry.** That rebuilds the
  monolith you are trying to escape: every page downloads every route's CSS.
- Layering: **one shared Tailwind sheet** (utilities grow sublinearly with the
  site), **per-component SDC CSS** that loads only when the component renders,
  and **per-route entries only for genuinely bespoke layout**.
- Declare each Vite `rollupOptions.input` entry deliberately, one per usage
  boundary, and attach libraries per route (preprocess / `attach_library`),
  not globally from `info.yml` `libraries:`.

**Why it matters with Vite specifically:** CSS entries do not share chunks.
Anything a CSS entry `@import`s is inlined into **that entry's** output, so a
shared partial imported by N entries ships N times. That is fine for a small
token table. It is how a "shared" sheet quietly inflates every route bundle.
Prefer a separate small library that routes depend on.

**Detect:**

- Size budget per built CSS file (fail when any `dist/assets/*.css` exceeds a
  ceiling) plus a per-source-file cap. Raise a ceiling only with a measured,
  explained reason.
- Grep source for glob imports: `grep -rnE "@import ['\"][^'\"]*\*" src/`
- Count how many built files carry a shared rule:
  `grep -l -- '--color-bg:' dist/assets/*.css | wc -l`

---

## 4. Own the markup

**Rules:**

- `base theme: false` in `mytheme.info.yml`. You do not inherit Classy/Stable
  wrappers and classes you then have to fight.
- **Flat templates**: override only the templates your routes render, and keep
  them free of inherited page/block/form-element wrapper divs.
- Drop core and contrib CSS you do not want with `libraries-override`, at the
  library or single-file level:

```yaml
libraries-override:
  user/drupal.user: false
  my_module/widget:
    css:
      theme:
        css/widget.css: false   # keep the JS, replace the styling
libraries-extend:
  my_module/widget:
    - mytheme/widget-restyle    # ships wherever the contrib library ships
```

- `libraries-extend` is the reliable way to ship a restyle exactly where a
  contrib library loads. Attaching from a `#page_bottom` render element may not
  reach `<head>`.
- Core's `form` theme hook does not suggest per-form templates. Add them:

```php
function mytheme_theme_suggestions_form_alter(array &$suggestions, array $variables): void {
  if (!empty($variables['element']['#form_id'])) {
    $suggestions[] = 'form__' . str_replace('-', '_', $variables['element']['#form_id']);
  }
}
```

- Every **view mode** a surface renders needs its own template. Otherwise a
  clean Views wrapper can still contain rows that fall through to core's bare
  `node.html.twig`.

---

## 5. Reuse rules

- **All colours through tokens.** Define them once in a tokens file
  (Tailwind v4 `@theme`, `light-dark()` for schemes) and use `var(--color-*)`
  or the generated utilities everywhere else. Enforce it with a check that fails
  on a raw hex outside the tokens file:

```bash
grep -rnE '#[0-9a-fA-F]{3,8}\b' src/css components --include='*.css' \
  | grep -v 'src/css/tokens.css' && exit 1 || true
```

- **Two or more uses ⇒ an SDC component**, never a second copy of bespoke
  per-page CSS. When core renders markup without the SDC template (for example
  form elements reusing a component's class), `@import` that component's CSS into
  the route entry explicitly and leave a comment saying why.

---

## 6. Near-zero JS

- **Cross-document View Transitions** give app-like page changes with no router:

```css
@view-transition { navigation: auto; }
```

  Same-origin navigations animate where supported. Elsewhere the browser
  navigates normally, so it is pure progressive enhancement.

- **Speculation Rules** prerender likely next pages. Attach them from
  `hook_page_attachments_alter()` / preprocess:

```php
$rules = json_encode(['prerender' => [[
  'where' => ['href_matches' => '/user/(login|register|password)'],
  'eagerness' => 'moderate',
]]]);
$attachments['#attached']['html_head'][] = [[
  '#type' => 'html_tag',
  '#tag' => 'script',
  '#attributes' => ['type' => 'speculationrules'],
  '#value' => \Drupal\Core\Render\Markup::create($rules),
], 'mytheme_speculation_rules'];
```

  Only prerender GET routes with no side effects (never logout, never
  "add to cart" links).

- **Keep anonymous routes page-cacheable.** No per-user output in anonymous
  markup. Per-user fragments go through lazy builders / placeholders.
- **Avoid per-user flashes without breaking caching.** A JS-readable, cosmetic
  cookie set on login and cleared on logout lets an inline `<head>` script add
  a class (e.g. `html.is-authed`) before first paint, so CSS can show
  skeletons instead of the wrong label. The server never reads that cookie and
  it is never a security signal. Give every skeleton a CSS timeout fallback for
  when JS fails to run.
- Use JS modules (`attributes: { type: module }`) and lazy `import()` for
  heavy, rarely used UI so it becomes a separate chunk.

---

## 7. Tailwind v4 pitfalls

Each was verified against Tailwind 4.3 `preflight.css` / build output.

**a) `@theme` tokens only become `:root` variables in an entry that imports
Tailwind.** An entry that does `@import "./tokens.css"` without
`@import "tailwindcss"` ships the raw `@theme { … }` text. Browsers ignore it,
every `var(--color-*)` is undefined, and declarations using them are dropped.
The breakage is partial and silent: sizes and fonts apply, colours/borders/
backgrounds fall back to initial values ("almost styled", white on white). It
often goes unnoticed because another Tailwind-importing bundle on the same page
defines the variables. Then a page without that bundle breaks.
- *Detect:* `grep -l '@theme' dist/assets/*.css` should list nothing.
- *Fix:* any entry that can be the only stylesheet on a route starts with
  `@import "tailwindcss";` before the tokens import. An entry that always loads
  next to a Tailwind bundle may rely on that bundle's `:root`, but say so in a
  comment.

**b) Preflight `img, video { max-width: 100%; height: auto }`.** It breaks
"crop window" patterns: an `overflow: hidden` box holding an image with a fixed
pixel width larger than the box, offset negatively. The image gets capped to the
box width and the crop shows the wrong region. Mockups built without Tailwind
look right, and the ported page does not.
*Fix:* `max-width: none` on the cropped image.

**c) Preflight `ol, ul, menu { list-style: none }` plus the universal
`margin: 0; padding: 0`.** Lists in authored body HTML render as flat,
unindented paragraphs. *Fix:* every prose/body class restores `list-style-type`
**and** `padding-left` for `ul`/`ol` (or use a typography plugin).

**d) Preflight `[hidden]:where(:not([hidden='until-found'])) { display: none !important; }`.**
You cannot restyle an element carrying `hidden` into a visible placeholder. Use
a dedicated skeleton element.

**e) Automatic source detection scans comments and plain text too.** A bare
utility word in a JS/CSS comment (e.g. "shrink", "hidden", "grow") can generate
that utility, and with one shared sheet that rehashes most of `dist/`.
*Detect:* a small source change that churns many dist files. *Fix:* reword the
comment, or exclude paths with `@source not "<path>";`.

**f) `display: contents` to reorder across containers.** To interleave a section
that sits outside a grid with that grid's children at a breakpoint, make the
shared parent the flex column and give the grid wrapper `display: contents`,
with no DOM moves. Only do this when the wrapper has no background, padding,
border or gap that matters there, is not a containing block (no position or
transform, no sticky children keyed to it), is not measured by JS, and is a
plain `<div>` (`display: contents` on elements with implicit ARIA roles hurts
accessibility).

---

## 8. Build and dist discipline

- **If deploys come from git with no Node build step, commit `dist/`.** It must
  then equal a fresh build of the committed source. Drift gate:

```bash
set -o pipefail
npm ci && npm run build          # must exit 0 — never pipe into tail/tee without pipefail
git status --porcelain dist/     # must be empty
```

  A gate that pipes the build through `tail` without `pipefail` reports
  "no drift" when the build **crashed**. Grade the build's exit code first.
- `emptyOutDir: true` regenerates hashes. Stage the whole `dist/`, deletions
  included (`git add -A dist/`), so no stale hashed files linger and no live
  reference points at a deleted one.
- **Build where you installed.** Vite's bundler (Rollup) ships platform-specific
  native binaries as optional dependencies, and `npm` installs only the current
  platform's. A `node_modules` installed on the host (e.g. macOS arm64) fails
  inside a Linux container with `Cannot find module @rollup/rollup-linux-…`,
  and vice versa. File-sync tools that mirror `node_modules` into a container
  cause exactly this. Pick one place to build (usually the host, pinned with
  `.nvmrc`) and run `npm ci` there.
- Concurrent builders working from different trees overwrite each other's
  `dist/`. When behaviour "disappears", grep the served/committed dist for the
  expected symbol before debugging source.
- After deploying a rehashed dist: `drush cr` (section 2).

---

## 9. Verification checklist (before calling a theme change done)

- [ ] `npm run build` exits 0; `git status --porcelain dist/` clean after commit
- [ ] Asset guard green: per-file size caps, built-CSS ceiling, no glob imports, no raw hex outside tokens
- [ ] `grep -l '@theme' dist/assets/*.css` returns nothing
- [ ] No `version:` on Vite-managed libraries; `preprocess: false` on their files
- [ ] `$settings['vite']['useDevServer']` is `FALSE` in committed settings
- [ ] **Cold-render check with the dev server off:** `drush cr`, then time the
      first anonymous **and** first authenticated request to each touched route
      on a deployed-like environment; no outbound request to the dev-server URL
- [ ] Browser E2E (e.g. Playwright) of the real user journey on each touched
      route, desktop + mobile, every auth state the route serves
- [ ] Lighthouse on touched routes (LCP/CLS/TBT). Check TTFB first: if TTFB is
      the problem, it is backend, not CSS (see `drupal-performance`)
- [ ] Visual comparison against the design by someone other than the implementer
- [ ] After deploy: `drush cr` if hashes changed; spot-check one asset URL returns 200 with the right MIME type
