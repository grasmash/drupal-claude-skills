---
name: design-review
description: Use when a UI change is about to be declared done, when reviewing a user-facing diff, or when asked for a design/QA pass on a screen. Also use before merging any change that alters rendered output. Covers live-environment interaction review, mockup parity, visual polish, accessibility, robustness, and a triage-matrix report format.
---

# Design Review

Adapted from [OneRedOak/claude-code-workflows](https://github.com/OneRedOak/claude-code-workflows)' `design-review` (MIT; the ecosystem-standard design-review methodology — Stripe/Airbnb/Linear-caliber standards, "Live Environment First" principle), re-adapted for a web stack: browser automation (e.g. Playwright or an agent-browser CLI) against a real browser.

**Who runs this:** an executor or QA subagent dispatched by the coordinator — with this skill loaded. The coordinator reads the report, not the pixels.

**Core principle — Live Environment First:** assess the interactive experience in a real browser BEFORE static analysis or code reading. Actual rendered experience over theoretical correctness. Static screenshots alone and green tests alone are NOT a design review — both together, plus interaction, are.

**Canon sources (the "design principles doc" slot)** — identify your project's equivalents before starting:
- Static mockups, if the project keeps them (e.g. `design/*.html` with a route/screen inventory) — binding canon for visuals.
- The requirements/design doc that sets the performance and theming bar (e.g. light + dark mode).
- Any binding frontend skills or standards docs (interaction rules, asset budgets).

## Phase 0: Preparation

- Read the task and the diff under review; understand intent and scope.
- Identify the canon mockup screen(s) for every changed route (both themes, if the project is theme-sensitive).
- Confirm the local environment is running (e.g. `ddev describe`); get the reachable `BASE_URL`.

## Phase 1: Interaction & user flow

- Execute the primary flow of the changed screen(s) with browser automation — real navigation, real clicks, not a static screenshot only.
- Test interactive states: hover, focus, disabled, loading. Destructive actions must confirm.
- **First-paint state**: cold-load the screen — the shell (topbar/sidenav) must render immediately even while content is still loading.
- **Scroll**: scroll to the very bottom — the whole page must scroll, content must not hide under any fixed nav.
- Assess perceived performance (layout shift, slow fetches) against the project's perf bar (e.g. server-rendered, cacheable anonymous pages, near-zero JS).

## Phase 2: Mockup parity

- Screenshot each changed state at the project's binding breakpoints (e.g. **1280px and 390px**). Both themes when the change is theme-sensitive (toggle via the class strategy, not a full reload).
- Compare side-by-side against the canon mockup. Inventory BOTH directions: elements in the mockup missing from the themed route, and themed-route elements absent from the mockup (report the latter as mockup-update candidates, not app bugs).
- **Capability preservation:** the goal is building a themed route that matches the mockup without silently dropping functionality. An app capability absent from the mockup is never a removal finding by default — flag it for a call (sometimes removal IS intended, but that's a decision, not a default). Never recommend ripping out functionality to match a mockup.
- Numeric method for style deltas: extract exact values (hex/px/radius/weight) from the mockups' CSS token source → element|mockup|route|verdict table → fix via design tokens (e.g. Tailwind `@theme`), never ad-hoc literals (see `mockup-parity`).

## Phase 3: Visual polish

- Layout alignment + spacing consistency (token spacing, no ad-hoc gaps).
- Typography hierarchy and legibility (stick to the project's type presets).
- Color palette consistency (design tokens only, both themes — no raw hex outside the token source).
- Visual hierarchy guides attention to the primary action.

## Phase 4: Accessibility (web)

- Every interactive element has an accessible name (label, `aria-label`, or visible text) — icon-only buttons especially.
- Touch/click targets are reasonably sized.
- Color contrast 4.5:1 minimum for text, both themes.
- Reduced-motion respected for animations (`prefers-reduced-motion`).
- Keyboard navigation works for the primary flow (tab order, focus visible).

## Phase 5: Robustness

- Loading, empty, and error states for every data surface (empty ≠ blank screen; errors are specific, not generic) — if the mockup set includes state screens (`*-loading.html`, `*-empty.html`, `*-error.html`), review against them.
- Long-content stress: long titles/usernames/comments — truncation, no overflow or wrap-breakage.
- Form validation with invalid input where applicable.
- No-JS fallback renders something usable (progressive enhancement).

## Phase 6: Code health

- Shared components reused, not re-implemented — check the project's component library before adding a new one-off lookalike.
- Design tokens over magic numbers (an asset guard should already catch raw hex, but review numeric spacing/radius too).
- Per-component CSS loaded only where rendered (anti-monolith asset splitting).

## Phase 7: Content & console

- Copy: grammar, clarity, and terminology correctness (check the project's terminology/standards doc if one exists).
- Browser console clean during the flows (no errors/warnings introduced).

## Communication principles

1. **Problems over prescriptions.** Describe the problem and impact, not the fix. "The spacing feels inconsistent with adjacent elements, creating visual clutter" — not "change margin to 16px." (Exception: token-value deltas — report the numbers; they ARE the evidence.)
2. **Triage matrix** — every finding gets exactly one:
   - **[Blocker]**: critical failure — broken flow, data loss, unusable state.
   - **[High-Priority]**: significant issue, fix before merge.
   - **[Medium-Priority]**: improvement for follow-up (note it in a plan/TODO).
   - **[Nitpick]**: minor aesthetic detail, prefix "Nit:".
3. **Evidence-based.** Screenshot per visual finding (path to the file); token-delta line per numeric finding. Open with what works well.

## Report structure

```markdown
### Design Review Summary
[Positive opening + overall assessment + ship/no-ship call]

### Findings
#### Blockers
- [Problem + screenshot path]
#### High-Priority
- [Problem + screenshot path]
#### Medium-Priority / Suggestions
- [Problem]
#### Nitpicks
- Nit: [Problem]

### Parity
[Token-delta count or "N/A for this screen"; mockup-update candidates found]
```

## Iterate loop (when fixing, not just reviewing)

Present the canon mockup image and the actual screenshot SEQUENTIALLY in the same turn (not composited), self-critique the differences, fix, re-screenshot. Expected convergence: **2-3 iterations**. If iteration 3 still has High-Priority deltas, STOP — report the residual deltas with both images instead of thrashing; the gap is probably data/architecture, not styling.

## Screenshot-baseline convention

If the project's Playwright suite has a baseline-approval workflow (or once one is established), keep it binding:
- Baselines live under Playwright's default `*-snapshots/` directories, committed to git.
- A failing snapshot diff is a FINDING, never a prompt to blindly `--update-snapshots`. Executors/reviewers don't silently overwrite a baseline.
- Baseline updates happen only after an approved visual change, in their own commit, so `git log` on the snapshots directory reads as the approval ledger.

Maintain objectivity, assume good intent from the implementer, balance perfectionism against delivery.

## Layout-topology gate

A design review is NOT passed by artifact existence, test greenness, or component-level screenshots. The reviewer (including the merging coordinator) MUST open the rendered page/composition and verify LAYOUT TOPOLOGY against the mockup: count columns at desktop width (stats 4-up? cards 3-up? two-col split?), check side-by-side elements are actually side by side. "Components render" is not "the page is laid out." Evidence = a full-page screenshot at desktop width with the column structure visibly matching the mockup, attached to the review.

## Tailwind verification trap

Class presence in the DOM proves nothing — Tailwind 4 only emits utilities it saw at build time. Verify COMPUTED styles (`getComputedStyle`: `gridTemplateColumns`/`display`/`flex`) not `classList`. Dynamic class construction and utilities used only in new files are the usual missing-CSS causes; a rule existing for `sm:grid-cols-2` does not imply the base or `lg` variant exists.
