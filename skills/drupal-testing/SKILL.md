---
name: drupal-testing
description: Test-driven development for Drupal with PHPUnit and Drupal Test Traits (DTT). Use when writing or fixing tests, deciding what is worth a test, reproducing a bug before fixing it, choosing a bootstrap level (Unit vs Kernel vs ExistingSite/functional), testing permission gates, adding Playwright visual verification, or debugging tests that silently run zero assertions. Covers the bug-fix RED-first discipline, the worth-a-test rubric, bootstrap cost tradeoffs, negative tests, the anonymous-403 permission trap, DTT gotchas, and the PHPUnit-version pin that makes Drupal tests pass vacuously.
---

# Drupal Testing (TDD)

Hard-won testing discipline for Drupal. Pairs with the `test-writer` and `test-runner` agents — this skill is the *how*, those agents are the *who*.

## What's worth a test (read FIRST)

Before writing ANY test, decide whether it earns its place. A test is worth committing ONLY if **BOTH** hold:

1. **A future change could PLAUSIBLY and SILENTLY break it.** (Not "could someone theoretically delete this" — a realistic code path that a normal edit could regress without noticing.)
2. **The breakage MATTERS:** user-facing behavior, data integrity, money, security, or an API/client contract.

If either fails, the test is pure cost with no protection — **skip it.** A committed assertion you have to maintain forever, that guards against a regression that can't realistically happen, is maintenance drag, not a safety net.

**Bug fixes are still mandatory TDD** (see the next section). The rubric here governs *new coverage you choose to add*, not the bug-fix discipline.

### HIGH value — always test
- Business / algorithm logic, data transforms, scoring, attribution.
- Money / subscriptions / entitlements.
- Security & permission gates — pin at the route level (see "The anonymous-403 permission trap" below).
- Cache invalidation & freshness — mutate via the real path, assert the surface updates.
- API / JSON response shapes an external client depends on (contract tests). Hard-won: on one production codebase, a stripped key in a device-facing response contract once wiped data on every connected device — response-shape contracts earn permanent tests.
- Any regression **with a history of recurring**.

### LOW value — do NOT write a committed assertion
- **Presence/absence of a one-off UI element that was a design correction.** Canonical example: a test asserting a removed button is absent from a modal. Removing it from one template is permanent — no realistic code path re-introduces it, so the assertion guards nothing.
- Exact copy / label text — unless the copy IS the contract (e.g. legal text).
- Pixel positions / spacing that visual regression already covers.
- Things Drupal core or contrib already test.
- Restating implementation detail — a test that just mirrors the code it tests (change the code, the test changes in lockstep; it never catches anything).

### The "would it actually regress?" gate
If you can't name a **plausible code change** that would silently bring the bug back, a test there is ~zero protection for nonzero upkeep. Sanity check: **delete the assertion line — does anything else fail?** If "it still passes," it wasn't testing anything.

### Cosmetic / copy / layout corrections → the proof is a screenshot, not an assertion
For a design tweak, the verification is a **visual check (screenshot, e.g. via Playwright)**, NOT a committed DOM-presence test. TDD's "failing test first" applies to **behavior** defects, not cosmetic ones — do NOT manufacture a failing `expect(locator).toBeHidden()` style assertion to satisfy TDD on a design fix. Look, confirm, move on.

### Cheapest test that proves it
Match test cost to value and regression-risk. Prefer in order: **Unit > Kernel > `renderInIsolation` > HTTP smoke > Playwright.** Don't reach for a multi-second HTTP `drupalGet` or a multi-minute Playwright run to assert a DOM element exists when a render test (or nothing at all) is the right call.

## Bug-fix TDD — the RED step is non-negotiable

Every bug fix follows this exact sequence. Skipping step 2 is what makes "fixed" bugs come back.

1. **Write a test that reproduces the bug** — exercise the *real* code path the user hits, not a paraphrase of the suspected logic.
2. **Run it and assert it FAILS, with the symptom matching the report.** If it doesn't fail, you haven't reproduced the bug — keep digging until it fails for the *right reason*. The red-to-green transition is your only proof the test actually exercises the bug; without it, you can't tell whether the test catches the bug or just happens to pass on green.
3. **Fix the production code.**
4. **Re-run the same test and assert it now passes.**

### Negative test cases (testing the bug path)

When fixing bugs, write tests that demonstrate BOTH the failure mode and the success mode:

1. **Proves the test catches the bug** — if your test passes before the fix, it's not testing the right thing.
2. **Documents the failure mode** — future developers understand WHY the code is written a certain way.
3. **Prevents regression** — if someone "simplifies" the code back to the broken approach, the test explains why.
4. **Validates root cause** — confirms the fix addresses the actual problem, not a symptom.

```php
public function testNestedVsFlatFormValues(): void {
  // NEGATIVE CASE: demonstrate how nested values FAIL.
  // The consumer's array_intersect_key expects flat keys like 'margin_top'.
  $nested_input = ['margin' => ['margin_top' => 'medium']];  // WRONG: nested
  $preserved_keys = ['margin_top', 'margin_bottom', 'padding_top'];
  $preserved_nested = array_intersect_key($nested_input, array_flip($preserved_keys));
  $this->assertEmpty($preserved_nested,
    'NEGATIVE CASE: nested values are NOT found — this is the bug.');

  // POSITIVE CASE: demonstrate how flat values WORK.
  $flat_input = ['margin_top' => 'medium'];  // CORRECT: flat
  $preserved_flat = array_intersect_key($flat_input, array_flip($preserved_keys));
  $this->assertEquals('medium', $preserved_flat['margin_top'],
    'POSITIVE CASE: flat values ARE correctly found — this is the fix.');
}
```

Use negative tests for: bug fixes, security fixes, edge cases (invalid input rejected), integration issues (incompatible approaches fail). Name them so the "this SHOULD fail because..." intent is obvious.

## Pick the lightest bootstrap that fits — it dominates cost

Drupal test base classes differ in bootstrap cost by orders of magnitude. Default to the cheapest one that can express the assertion.

| Base class | Bootstrap | Use for |
|---|---|---|
| `UnitTestCase` | none (pure PHP) | isolated logic, no Drupal services |
| `KernelTestBase` | minimal; declare deps in `protected static $modules` | services / business logic in isolation |
| ExistingSite (DTT `ExistingSiteBase`) | runs against the *served* site (real config, contrib, field storage) | flows that need the full installed site |
| Functional/`BrowserTestBase` | full reinstall per test class | last resort; very slow |

Prefer Unit and Kernel where the logic doesn't need the full site — they're far faster. A standard `BrowserTestBase` class pays a full site install (profile + config import) in `setUp()` — commonly 20-60+ seconds per test **class**; DTT's `ExistingSiteBase` pays that cost exactly once, at site-install/seed time, then every test is just an HTTP round trip. Prefer `ExistingSiteBase` over `BrowserTestBase` by default.

Within ExistingSite, the cost is **not** bootstrap; it's `drupalLogin()` + `drupalGet()` (real HTTP, seconds each). Before adding those, ask whether the assertion is about HTTP/auth/redirects or about rendered output:

- **Service logic** → call `\Drupal::service(...)->method()` directly. No HTTP.
- **Template render** → build the render array, call `\Drupal::service('renderer')->renderInIsolation($build)`. No HTTP.
- **Entity render** → DTT's `EntityCrawlerTrait::getRenderedEntityCrawler($entity, $view_mode)`. No HTTP.
- **Controller wiring, auth, redirects** → `drupalLogin` + `drupalGet`. Keep to one smoke test per feature.

### Fast matrix pattern (data providers)

Data providers multiply cost: an 11-row matrix × `drupalLogin + drupalGet` ≈ 5 minutes. When you have a `#[DataProvider]` with N rows, DO NOT put HTTP inside the test method. Split into a fast service/render matrix **plus** a single HTTP smoke test:

```php
class MyMatrixTest extends SomeTestBase {

  #[DataProvider('cases')]
  public function testServiceOutput(...): void {
    // Assert the service directly — no login, no HTTP.
    $result = \Drupal::service('my_module.calculator')->score($input);
    $this->assertSame($expected, $result);
  }

  #[DataProvider('cases')]
  public function testTemplateRender(...): void {
    $build = [
      '#theme' => 'my_component',
      // ... same variables the controller would pass
    ];
    $html = (string) \Drupal::service('renderer')->renderInIsolation($build);
    $this->assertStringContainsString($expected_marker, $html);
  }

  public function testControllerSmoke(): void {
    // One HTTP test to prove controller → template wiring works end-to-end.
    $this->drupalGet('/my-page');
    $this->assertSession()->statusCodeEquals(200);
  }
}
```

### Speed levers

1. **Use Unit/Kernel** for logic that doesn't need the full installed site.
2. **Kill real external calls in `setUp()`** via config/debug flags so tests never hang on real remote services.
3. **Avoid `sleep()`** — it's almost always a sign of a missing assertion or wrong base class.
4. **Minimize `drupalLogin`/`drupalGet`**, especially per data-provider row.
5. **Run with `XDEBUG_MODE=off`** — 3-5x faster than leaving Xdebug loaded.
6. **Process-level levers**: a project-specific PHPUnit bootstrap that replaces core's recursive `*.info.yml` scan with explicit PSR-4 registration (see the `drupal-ddev` skill's "PHPUnit Test Performance"), and — under DDEV — an opcache file-cache ini persisting compiled opcodes to a native-filesystem cache mount (`validate_timestamps` stays on, so edited files still recompile; requires `ddev restart` after adding). If you change a custom bootstrap, gate it on `phpunit --list-tests` before/after being byte-for-byte identical.

## DTT ExistingSite patterns

- **Seed once, read shared fixtures.** The core speed lever: seed the site once (a drush php-script fixture seeder works well) and write ExistingSite tests that read that shared fixture, rather than creating entities per test. Reserve DTT's per-test entity creation/cleanup (`$this->createNode()`, `$this->createUser()` — auto-deleted after the test) for genuinely test-specific fixtures a shared seed can't represent.
- **Bound meta-refresh recursion.** DTT's vendor default for `maximumMetaRefreshCount` is `NULL` (unbounded) — a page carrying a `<meta http-equiv="Refresh">` loop (e.g. big_pipe's no-JS detection paired with a redirect target that keeps serving the tag) hangs the run. Set it to a small number (e.g. 3) in a shared project base class.
- **Guard `tearDown()` when `setUp()` skips.** If your ExistingSite base skips in `setUp()` when `DTT_BASE_URL` is unset (`$this->markTestSkipped(...)` BEFORE `parent::setUp()`), pair it with a `tearDown()` guard — `if (!\Drupal::hasContainer()) { return; }` before `parent::tearDown()`. PHPUnit calls `tearDown()` in a `finally` block even after a `setUp()`-time skip, and DTT's own `tearDown()` unconditionally touches `\Drupal::database()`, which fatals with `ContainerNotInitializedException` if `setupDrupal()` never ran. Without the guard, "Skipped: 9" silently becomes "Skipped: 9, Errors: 9".
- **Anonymous CSRF tokens may not validate across requests.** A route with `_csrf_token: TRUE` generates its token from the current session — and on sites that don't persist sessions for pure-anonymous requests (no `Set-Cookie` on anonymous GET), a token embedded in one anonymous response is not guaranteed to validate on a follow-up anonymous POST. Fix in tests: `$this->drupalLogin($this->createUser())` before exercising a `_csrf_token: TRUE` flow — the login exists solely to establish a stable, persisted session. Then exercise the *real* form (`$form->submit()` on the rendered page), not a hand-built URL.

## The anonymous-403 permission trap

A "returns 403 for anonymous" test does **not** prove a route's `_permission` is enforced. Two ways it lies:

1. A route gated with both `_user_is_logged_in: TRUE` and `_permission` rejects anonymous on the **login** gate first — so deleting `_permission` entirely still passes the anonymous test.
2. When the gating permission sits on the `authenticated` role, **no logged-in user can ever be denied**, so the gate is effectively open. (This is not theoretical — it has bitten an entire API surface on a production codebase, where the "logged-in but unprivileged → 403" test was literally unwritable.)

`_permission` syntax: `+` is **OR**, `,` is **AND**.

To actually test the gate, do one of:
- Log in a user who genuinely **lacks** the permission and assert 403, or
- Pin the gate at the route-definition level: assert `$route->getRequirement('_permission')` equals the expected string, so loosening the gate fails a test:

```php
public function testRoutePermissionGate(): void {
  $route = \Drupal::service('router.route_provider')
    ->getRouteByName('my_module.my_route');

  $this->assertSame('expected permission+administer something', $route->getRequirement('_permission'));
  $this->assertSame('TRUE', $route->getRequirement('_user_is_logged_in'));
}
```

For a whole family of routes, loop them against an explicit expected-permission map plus a set-equality check, so a NEW route can't ship ungated.

TDD the guard: strip the permission → confirm RED → restore. A guard you never watched fail proves nothing.

## Tests that pass vacuously (the silent-zero trap)

If a whole class of tests suddenly "passes" while running **0 assertions**, suspect a PHPUnit-version mismatch or a collection-time fatal, not green code.

- Drupal core supports a specific PHPUnit major. A wrong pin (e.g. PHPUnit 12 against a core that only supports 11) makes every test extending a Drupal base class (`UnitTestCase`/`KernelTestBase`) **collect zero tests and exit 0** — there's no compatibility shim, so collection fatals silently. Meanwhile plain `\PHPUnit\Framework\TestCase` + DTT ExistingSite tests still run, masking the breakage.
- **`setUp()` / `tearDown()` MUST match the parent's visibility.** Declaring them with the wrong visibility is a load-time fatal that `php -l` doesn't catch and PHPUnit can silently swallow → 0 tests, exit code 0.
- PHPUnit 10+ uses **PHP 8 attributes** (`#[Group('x')]`), not `@group` docblock annotations. `--exclude-group`/`--group` won't match legacy annotations — migrate to attributes.
- Sanity check: a passing test run should report a non-trivial assertion count. `OK (0 tests, 0 assertions)` for a suite you know has tests means the runner isn't collecting them.

## Useful smoke patterns

```php
// Service exists and exposes the expected method.
$service = \Drupal::service('my_module.some_service');
$this->assertNotNull($service);
$this->assertTrue(method_exists($service, 'methodName'));

// Route exists.
$route = \Drupal::service('router.route_provider')
  ->getRouteByName('my_module.my_page');
$this->assertNotNull($route);

// Plugin registered + instantiable.
$definitions = \Drupal::service('plugin.manager.my_type')->getDefinitions();
$this->assertArrayHasKey('plugin_id', $definitions);

// Idempotency / duplicate handling: same identifier twice returns the
// same entity, not a duplicate.
$a = $service->createEntity($key);
$b = $service->createEntity($key);
$this->assertEquals($a->id(), $b->id());
```

## Config validation testing

Config-based content (settings, exported templates) can be regression-tested at the YAML level — no need to trigger actual functionality:

```php
public function testConfigPattern() {
  $config_factory = \Drupal::configFactory();
  $issues = [];
  foreach ($config_factory->listAll('my_prefix.') as $config_name) {
    $value = $config_factory->get($config_name)->get('some.key');
    if (strpos((string) $value, 'bad_pattern') !== FALSE) {
      $issues[] = "$config_name: contains bad_pattern";
    }
  }
  $this->assertEmpty($issues, "Config issues:\n" . implode("\n", $issues));
}
```

Scan ALL matching configs with `listAll()` so a new config object can't ship with the anti-pattern.

## Visual testing (Playwright)

**Required for**: CSS, theme, UI changes. **Not required for**: backend-only work with no visible surface (state the exemption explicitly).

House conventions that work well: desktop (~1280px) + mobile (~390px) viewports, light + dark themes (force the theme class via `addInitScript` before first paint), screenshot per state, and asserting the built (hashed) assets are attached rather than raw source paths.

### Visual test checklist
- Clear cache before testing (skip if caching disabled)
- Test at mobile (~390px) and desktop (~1280px) widths
- Test logged-in and anonymous users where relevant
- Verify text contrast in light and dark themes
- Check responsive behavior (drawer/hamburger states)

## Verify the real code path locally — passing unit tests aren't enough

For any change to runtime behavior (cron jobs, drush commands, data processing, API endpoints, service logic), **execute the changed code path locally and confirm the real-world outcome** before declaring it done — don't stop at green unit tests. Run the actual command/service (e.g. via DDEV: `ddev drush <command>`), then check the resulting state (DB rows, updated field values, emitted output). This catches what tests miss: environment differences, data-dependent bugs, and integration failures across the real installed site. Unit/Kernel tests prove the logic in isolation; only running it proves the wiring.

## CI: fix failing tests locally, not by re-pushing

When CI fails on test errors, don't iterate by pushing commits and re-running the full suite (often ~20 min/run):

1. Identify the failing tests from CI logs.
2. Reproduce locally (`vendor/bin/phpunit --filter Class::method path/to/Test.php`).
3. Fix and run each test individually until green.
4. Commit.
5. Only then re-run the full CI suite.

## Gotchas (hard-won)

### Running under DDEV
- Always run phpunit inside `ddev exec` (it needs the DB connection) with `XDEBUG_MODE=off`, and filter output to preserve context:
  ```bash
  ddev exec "XDEBUG_MODE=off phpunit path/to/module/tests/ --testdox 2>&1" | grep -E '(✔|✘|OK|FAIL|Tests:|Assertions:)'
  ```
- **`ddev exec` swallows stdout of long commands.** Redirect to a file and tail it in the SAME invocation, e.g. `ddev exec "phpunit ... > /tmp/out.txt 2>&1; tail -n 40 /tmp/out.txt"`.
- **Mutagen mount is async** (when enabled). After editing a file on the host, run `ddev mutagen sync` before phpunit or it reads stale content.
- **`set -u` + host variable / `$(...)` expansion breaks inline `ddev exec` bash.** Write a script file and run `ddev exec bash /path/script.sh`.

### `drupalLogin()` flake (session-dependent cache contexts)
- `drupalLogin()` can intermittently fail at the post-login page-render check (login succeeds; the assertion that the page rendered as logged-in fails) when a module's cache context depends on session metadata that the test session bag doesn't provide (seen with the `masquerade` module). It's intermittent (cache-state dependent) and unrelated to whatever you're testing.
- **Fix:** if the test asserts controller/service OUTPUT (not the HTTP auth layer), don't use `drupalLogin`. Invoke the controller directly under an `AccountSwitcher`: `\Drupal::service('account_switcher')->switchTo($user)` → call the method → `switchBack()` in a `finally`. Cover the access gate separately at the route-definition level (see "The anonymous-403 permission trap").

### Debugging test failures
```bash
# Recent errors during a test run
ddev drush watchdog:show --severity=3 --count=10

# Service not found? Check registration:
ddev drush ev "print_r(\Drupal::getContainer()->getServiceIds());"

# Route not found? Rebuild the router:
ddev drush cr
```

## phpcs in test files

- Section-divider comments (`// ---`) before a docblock violate both `CommentEmptyLine.SpacingAfter` and `FunctionSpacing.Before`. Don't use them in test files.
- Run `vendor/bin/phpcbf <file>` to auto-fix before recommitting.
