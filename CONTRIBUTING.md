# Contributing to Drupal Claude Skills

Thank you for your interest in contributing! This guide covers skills, agents, and content guidelines.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest improvements
- Search existing issues first to avoid duplicates
- For skill-specific content issues, consider reporting to upstream sources

### Suggesting New Skills

Before proposing a new skill:

1. Check if it fits the Drupal development scope
2. Ensure it's not too project-specific
3. Verify it doesn't duplicate existing skills
4. Consider if it could be a reference within an existing skill instead

Good candidates for new skills:
- Drupal subsystems (Layout Builder, Workflows, Media, Paragraphs)
- Platform-specific patterns (Acquia, Platform.sh, Pantheon)
- Tool-specific workflows (Lando, Composer, PHPStan)
- Development methodologies (BDD, migrations, API-first)
- Drupal Commerce patterns

### Suggesting New Agents

Agents are reusable AI workflows. Good candidates:
- Development lifecycle stages (review, test, deploy)
- Domain-specific specialists (accessibility, performance, migrations)
- Quality gates and validation workflows

### Improving Existing Content

We welcome improvements to existing skills and agents:
- Fix errors or outdated information
- Add missing examples or patterns
- Improve clarity and organization
- Update for new Drupal versions

## Skill Format

Skills follow the [Agent Skills Specification](https://agentskills.io/specification).

### Directory Structure

```
skills/skill-name/
├── SKILL.md              # Required — main skill file
├── references/           # Optional — detailed documentation
│   ├── topic1.md
│   └── topic2.md
├── examples/             # Optional — example scripts
└── scripts/              # Optional — executable code
```

### SKILL.md Requirements

Every skill must have YAML frontmatter:

```yaml
---
name: skill-name
description: Complete description including keywords for activation. Max 1024 chars.
---
```

**Required fields:**
- `name` — 1-64 chars, lowercase alphanumeric + hyphens, must match directory name
- `description` — 1-1024 chars, include keywords that trigger this skill

**Content guidelines:**
- Keep SKILL.md **under 500 lines** (agentskills.io best practice)
- Use `references/` directory for detailed documentation
- Add table of contents to reference files over 100 lines
- Include "When This Skill Activates" section
- Use progressive disclosure: summary in SKILL.md, details in references

### Example SKILL.md

```markdown
---
name: my-skill
description: Brief description including trigger keywords. Mention topics, file types, and use cases.
---

# My Skill

## When This Skill Activates

Describe the contexts that activate this skill.

## Quick Reference

Essential patterns and commands.

## Available Topics

- @references/topic1.md - Description
- @references/topic2.md - Description
```

## Agent Format

Agents live in `.claude/agents/` and use YAML frontmatter:

```markdown
---
name: agent-name
description: What the agent does and when to use it.
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
---

Agent instructions here...
```

**Frontmatter fields:**
- `name` — Agent identifier
- `description` — Purpose and trigger conditions
- `tools` — Comma-separated list of allowed tools
- `model` — `sonnet`, `haiku`, or `inherit`

**Content guidelines:**
- Include a clear process/checklist
- Define output format
- Keep instructions focused and actionable
- Make agents generic (no project-specific references)

## Content Guidelines

### Code Examples

```bash
# Good: Generic, reusable
ddev drush config:get {config.name}
ssh user@remote.server "cd /path/to/drupal && drush cr"

# Bad: Project-specific
ddev drush config:get block.block.my_custom_block
ssh admin@mysite.example.com "cd /var/www/html && drush cr"
```

- Use `{placeholders}` for variable values
- Provide context with comments
- Show both correct and incorrect patterns when helpful
- Include expected output when relevant

### Neutrality

- No project-specific references (company names, domains, custom modules)
- No personal credentials or tokens
- No hardcoded domain names
- Use generic placeholders

### Accuracy

- Verify against official Drupal documentation
- Test code examples before submitting
- Note which Drupal versions apply
- Update deprecated patterns

## Pull Request Process

1. **Fork and branch**
   ```bash
   git checkout -b feature/add-my-skill
   ```

2. **Make changes** following the format guidelines above

3. **Verify**
   - YAML frontmatter is valid
   - No project-specific data (`grep -ri "myproject\|mysite\|example\.com" skills/`)
   - SKILL.md files are under 500 lines
   - Skill `name` matches directory name
   - Code examples are tested

4. **Submit PR** with clear description and testing notes

## Syncing Upstream Content

Two skills sync from external sources:

```bash
# Drupal at Your Fingertips
./.claude/scripts/sync-d9book.sh

# Ivan Grynenko Security Patterns
./.claude/scripts/sync-ivan-rules.sh
```

Don't modify auto-synced reference files directly — they'll be overwritten. Instead, update the sync scripts or contribute upstream.

## Attribution

Always credit original sources:

```markdown
**Source**: [Source Name](https://example.com)
**Author**: Author Name
**License**: License Type
```

By contributing, you agree your work is licensed under MIT (matching this project).

## Questions?

- Open a GitHub Issue for bugs or feature requests
- Check existing documentation first
- Tag maintainers if urgent
