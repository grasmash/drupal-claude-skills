---
name: mockup-parity
description: Use when porting a static HTML mockup screen into a themed Twig/SDC route, conforming an existing route to its mockup, or executing any parity/reskin work item. Load alongside design-review for any parity work.
---

# Mockup Parity (Twig/SDC)

The reskin goal: build a themed route that is as true to the approved static mockup as possible, without dropping any working capability. Judgment is required — the mockup is binding canon for *visuals*, not license to remove functionality it happens not to show.

This skill assumes a canon of static HTML mockups plus a single CSS token source (e.g. Tailwind `@theme` tokens emitted by the mockup generator), with Playwright as the verification tool. It was distilled from parity workflows originally built for other stacks (a mobile app with a Jest parity-manifest harness, a two-human-gate port process); the two-gate discipline survives here as a lightweight process rather than tooling.

## Order of operations (per screen)

1. **Read the canon.** The route/screen inventory → the screen's mockup HTML (BOTH themes, via the class-toggle strategy the mockups use) → the mockups' CSS token source for exact values (hex, px, radius, weight) — read it for numbers, don't eyeball a screenshot.
2. **🚦 GATE 1 — reconciliation sheet.** Before implementing, write a discrepancy sheet: one row per difference between the mockup and the current themed route (if one already exists) or per element to build (if new). For each, a call (`match mockup` / `keep existing` / `hybrid`) + reason. Do a **visual-element inventory, not just a capability inventory** — walk the mockup HTML and the current route top-to-bottom and list every visible element; for each, diff **presence** (in both / extra / missing), **size** (read exact px from the token source), **surface fill** (background/border colors — token names, not raw hex), **icon** (glyph family + name), and **position**. This is what catches missing empty-state icons, wrong logo scale, and missing surface fills that a holistic glance misses. Present the sheet; get the operator's approval before implementing (queue it through your project's async decision channel if the operator isn't available synchronously). Surface any app-wide design-system decisions (font, palette) separately — they set rules for all screens, not just this one.
3. **Classify every delta before fixing:**
   - **style** (font/color/spacing/radius) → conform to the mockup, via design tokens and existing shared components ONLY. A mockup value with no matching token is a decision (raise it), not a license for a raw literal — an asset guard should catch bypassed tokens.
   - **structural/capability** (element on one side only) → NEVER delete a working capability to match a mockup. Mockup-missing elements are mockup-update candidates (flag for the mockup, not the app); app-missing elements need explicit approval before adding (no speculative affordances — the mockup is canon for what a screen currently must show).
   - **conflict with a prior decision** (a documented plan/ADR ruling) → HOLD, list it, don't average the two. Mockups usually win — but not against an explicit prior decision (check decision history before "fixing" something a prior ruling made deliberate).
4. **Fix through primitives.** If the delta is in a shared component (SDC), fix the primitive and enumerate ALL its call sites in your report. Never fork a local one-off lookalike.
5. **Verify.** Run the `design-review` skill's Phase 1-7 pass for anything user-visible beyond a pure token swap: browser screenshots at the project's binding breakpoints (e.g. 1280 and 390), both themes. Build a **visual diff ledger**, not a glance: go element-by-element top-to-bottom and note, for each, screenshot-vs-mockup on **presence, size, surface fill, icon, position, shadow, and spacing** — pull the COMPLETE style set from the token source for each element, not just the headline property. Only "match / acceptable delta / FIX" per row. **Measure the visual gap in the screenshot vs. the mockup** — don't assume a token value reproduces the mock's look by inspection alone; some HTML elements have intrinsic spacing that makes a nominally-correct token render differently than expected. Scroll the full screen.
6. **Tests.** Add/update a Playwright spec per route (mandatory for any visually-verifiable change). Dark mode toggled in-spec via the class strategy. Empty/error state specs assert headings/CTAs render.
7. **🚦 GATE 2 — review packet.** Before declaring the screen done, present: before/after screenshots per theme, the reconciliation recap from Gate 1, any capability/behavior-change flags, Playwright status, and **recommendations (a11y / performance / UX)** noticed but NOT silently applied — the operator accepts or defers them explicitly. This is the `design-review` report structure, reused as the Gate 2 packet.

## Test rule (behavior-preserving → characterization)

When a change is meant to be purely visual (a reskin, not a feature change), the proof no capability was dropped is a test that passes BEFORE and AFTER the change — not a new test that only goes green after (that's evidence you changed behavior, not preserved it). Write/confirm the test passes on current code before starting; re-run it after. An intentional behavior change approved at Gate 1 uses normal red → green TDD instead and gets marked intentional in the commit.

## Hard rules

- Both themes, always, every step.
- Worktree discipline: never write outside the current worktree; confirm `git rev-parse --show-toplevel` before mutating if working across multiple worktrees in one session.
- No baseline/snapshot updates to HIDE deltas — snapshots shrink because something was fixed, or grow only with an explicit decision citation (see `design-review`'s screenshot-baseline convention).
- Cross-breakpoint: match at the binding widths (e.g. 1280 and 390); don't chase pixel equality at other widths — flex/relative elsewhere.
- Report format: delta table before/after per theme + held-conflict list + shared-component call-sites-swept list + Playwright results. Machine numbers, not adjectives.
