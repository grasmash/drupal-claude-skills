# Drupal Claude Skills

A public collection of Claude Code skills and agents for Drupal development.

## Repository Purpose

This repository distributes reusable skills and agents that any Drupal project can install. It is NOT a Drupal project itself — it's a skill distribution repo.

## Install Skills

### Via `npx skills` (recommended)

```bash
npx skills add grasmash/drupal-claude-skills
```

This copies skills from `skills/` into your project's `.claude/skills/` directory.

### Manual

```bash
cp -r skills/* /path/to/your/project/.claude/skills/
```

## Install Agents

Agents live in `.claude/agents/` and must be copied manually:

```bash
cp -r .claude/agents/* /path/to/your/project/.claude/agents/
```

## Install Settings

Copy the sample settings.json as a starting point:

```bash
cp .claude/settings.json /path/to/your/project/.claude/settings.json
```

Review and customize for your project's needs.

## Canvas Ecosystem

For Drupal Canvas Code Components, also install:

```bash
npx skills add drupal-canvas/skills
```

---

## Agent Workflow Guide

The following sections document how to use the included agents effectively in a Drupal project. Copy this guidance into your project's CLAUDE.md and adapt as needed.

### Parallelization

Maximize parallel work. Spawn multiple sub-agents in a single message when tasks are independent. Use agent teams for features spanning Drupal + frontend. Research areas concurrently before implementing.

### Quality Gate (mandatory before commit)

Before committing code changes, spawn the `quality-gate` agent to review the diff. It checks security, performance, testing, and regressions. Proactively run the review before reaching the commit step — don't wait for a reminder. For agent teams, the team lead should spawn quality-gate after all teammates finish, not each teammate individually.

### Done Gate (mandatory before declaring done)

After quality-gate passes and before telling the user work is complete, spawn the `done-gate` agent. It validates that the work actually **works** — builds succeed, tests pass, deliverables match the plan. Quality-gate checks code quality; done-gate checks functional correctness. Both must pass before declaring done.

### Local Execution Verification (mandatory)

For any fix or feature that changes runtime behavior (cron jobs, drush commands, data processing, API endpoints, service logic), you MUST execute the changed code path locally via DDEV and verify the results before declaring done. Unit tests passing is not sufficient — run the actual command/service and confirm the real-world outcome. This catches issues that tests miss: environment differences, data-dependent bugs, and integration failures.

### CI Test Fix Workflow

When CI fails with test errors, do NOT iterate by pushing commits and re-running the full suite. Instead:

1. **Identify the failing tests** from the CI logs
2. **Reproduce locally** — run the specific failing tests in your local environment
3. **Fix each failing test** and run it individually until it passes (e.g., `vendor/bin/phpunit --filter ClassName::testMethod`)
4. **Commit the fix** to the branch
5. **Only re-run the full CI suite** after all individual tests pass locally

This avoids wasting CI minutes on known-broken tests.

### Contrib/Core Patch Policy

NEVER directly edit files in `docroot/modules/contrib/` or `docroot/core/`. All changes to contributed modules and Drupal core MUST use patches:

1. Create a `.patch` file in `patches/`
2. Register it in `composer.json` under `extra.patches`
3. Run `composer install` to apply

Direct edits get overwritten by `composer install`/`composer update`. See the `drupal-contrib-mgmt` skill for full patch management workflows.

### Session Completion (Landing the Plane)

When ending a work session, complete these steps:

1. **File issues for remaining work** — Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) — Tests, linters, builds
3. **Update issue status** — Close finished work, update in-progress items
4. **Commit changes** — Ensure all work is committed locally
5. **Ask before pushing** — Ask the user if they want you to push to remote. Do NOT push automatically
6. **Hand off** — Provide context for next session

---

## Directory Structure

```
skills/                  # Skills (installed via `npx skills add`)
.claude/agents/          # Agent definitions (manual copy)
.claude/settings.json    # Sample settings (manual copy)
.claude/scripts/         # Sync scripts for upstream content
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Skill Format

Skills follow the [Agent Skills Specification](https://agentskills.io/specification):
- Each skill is a directory under `skills/` with a `SKILL.md` file
- SKILL.md has YAML frontmatter with `name` and `description`
- Keep SKILL.md under 500 lines; use `references/` for details
