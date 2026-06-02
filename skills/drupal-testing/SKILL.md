---
name: drupal-testing
description: Test-driven development for Drupal with PHPUnit and Drupal Test Traits (DTT). Use when writing or fixing tests, reproducing a bug before fixing it, choosing a bootstrap level (Unit vs Kernel vs ExistingSite/functional), testing permission gates, or debugging tests that silently run zero assertions. Covers the bug-fix RED-first discipline, bootstrap cost tradeoffs, the anonymous-403 permission trap, and the PHPUnit-version pin that makes Drupal tests pass vacuously.
---

# Drupal Testing (TDD)

Hard-won testing discipline for Drupal. Pairs with the `test-writer` and `test-runner` agents — this skill is the *how*, those agents are the *who*.

## Bug-fix TDD — the RED step is non-negotiable

Every bug fix follows this exact sequence. Skipping step 2 is what makes "fixed" bugs come back.

1. **Write a test that reproduces the bug** — exercise the *real* code path the user hits, not a paraphrase of the suspected logic.
2. **Run it and assert it FAILS, with the symptom matching the report.** If it doesn't fail, you haven't reproduced the bug — keep digging until it fails for the *right reason*. The red-to-green transition is your only proof the test actually exercises the bug; without it, you can't tell whether the test catches the bug or just happens to pass on green.
3. **Fix the production code.**
4. **Re-run the same test and assert it now passes.**

## Pick the lightest bootstrap that fits — it dominates cost

Drupal test base classes differ in bootstrap cost by orders of magnitude. Default to the cheapest one that can express the assertion.

| Base class | Bootstrap | Use for |
|---|---|---|
| `UnitTestCase` | none (pure PHP) | isolated logic, no Drupal services |
| `KernelTestBase` | minimal; declare deps in `protected static $modules` | services / business logic in isolation |
| ExistingSite (DTT `ExistingSiteBase`) | runs against the *served* site (real config, contrib, field storage) | flows that need the full installed site |
| Functional/`BrowserTestBase` | full reinstall per test | last resort; very slow |

Prefer Unit and Kernel where the logic doesn't need the full site — they're far faster. Within ExistingSite, the cost is **not** bootstrap; it's `drupalLogin()` + `drupalGet()` (real HTTP, ~25s each). Before adding those, ask whether the assertion is about HTTP/auth/redirects or about rendered output:

- **Service logic** → call `\Drupal::service(...)->method()` directly. No HTTP.
- **Template render** → build the render array, call `\Drupal::service('renderer')->renderInIsolation($build)`. No HTTP.
- **Entity render** → DTT's `EntityCrawlerTrait::getRenderedEntityCrawler($entity, $view_mode)`. No HTTP.
- **Controller wiring, auth, redirects** → `drupalLogin` + `drupalGet`. Keep to one smoke test per feature.

Data providers multiply cost: an 11-row matrix × `drupalLogin + drupalGet` ≈ 5 minutes. Split into a fast service/render matrix **plus** a single HTTP smoke test.

## The anonymous-403 permission trap

A "returns 403 for anonymous" test does **not** prove a route's `_permission` is enforced. Two ways it lies:

1. A route gated with both `_user_is_logged_in: TRUE` and `_permission` rejects anonymous on the **login** gate first — so deleting `_permission` entirely still passes the anonymous test.
2. When the gating permission sits on the `authenticated` role, **no logged-in user can ever be denied**, so the gate is effectively open.

`_permission` syntax: `+` is **OR**, `,` is **AND**.

To actually test the gate, do one of:
- Log in a user who genuinely **lacks** the permission and assert 403, or
- Pin the gate at the route-definition level: assert `$route->getRequirement('_permission')` equals the expected string, so loosening the gate fails a test.

TDD the guard: strip the permission → confirm RED → restore.

## Tests that pass vacuously (the silent-zero trap)

If a whole class of tests suddenly "passes" while running **0 assertions**, suspect a PHPUnit-version mismatch, not green code.

- Drupal core supports a specific PHPUnit major. A wrong pin (e.g. PHPUnit 12 against a core that only supports 11) makes every test extending a Drupal base class (`UnitTestCase`/`KernelTestBase`) **collect zero tests and exit 0** — there's no compatibility shim, so collection fatals silently. Meanwhile plain `\PHPUnit\Framework\TestCase` + DTT ExistingSite tests still run, masking the breakage.
- PHPUnit 10+ uses **PHP 8 attributes** (`#[Group('x')]`), not `@group` docblock annotations. `--exclude-group`/`--group` won't match legacy annotations — migrate to attributes.
- Sanity check: a passing test run should report a non-trivial assertion count. `OK (0 tests, 0 assertions)` for a suite you know has tests means the runner isn't collecting them.

## CI: fix failing tests locally, not by re-pushing

When CI fails on test errors, don't iterate by pushing commits and re-running the full suite (often ~20 min/run):

1. Identify the failing tests from CI logs.
2. Reproduce locally (`vendor/bin/phpunit --filter Class::method path/to/Test.php`).
3. Fix and run each test individually until green.
4. Commit.
5. Only then re-run the full CI suite.

## phpcs in test files

- Section-divider comments (`// ---`) before a docblock violate both `CommentEmptyLine.SpacingAfter` and `FunctionSpacing.Before`. Don't use them in test files.
- Run `vendor/bin/phpcbf <file>` to auto-fix before recommitting.
