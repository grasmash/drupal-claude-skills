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
