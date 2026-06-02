# Drupal Claude Skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-orange.svg)](https://claude.com/claude-code)
[![Drupal](https://img.shields.io/badge/Drupal-10%20%7C%2011-blue.svg)](https://www.drupal.org)
[![agentskills.io](https://img.shields.io/badge/spec-agentskills.io-purple.svg)](https://agentskills.io)

A comprehensive collection of Claude Code skills and agents for Drupal development. Install battle-tested patterns for configuration management, module updates, security, local development, OAuth, search, and more.

## Quick Install

### Option 1: Give this prompt to your AI agent

Copy-paste this into Claude Code (or any AI coding agent) from your Drupal project directory:

```
Install Drupal Claude Skills into this project from https://github.com/grasmash/drupal-claude-skills:

1. Clone the repo to a temp directory
2. Copy skills/ into .claude/skills/
3. Copy .claude/agents/ into .claude/agents/
4. Copy .claude/settings.json (if I don't already have one)
5. Read AGENTS.md from the repo and append the "Agent Workflow Guide" section to my CLAUDE.md (create CLAUDE.md if it doesn't exist)
6. Clean up the temp directory
```

### Option 2: Shell script

```bash
bash <(curl -s https://raw.githubusercontent.com/grasmash/drupal-claude-skills/main/install.sh)
```

Or from a cloned copy:

```bash
./install.sh /path/to/your/drupal/project
```

### Option 3: Skills CLI (skills only, no agents)

```bash
npx skills add grasmash/drupal-claude-skills
```

This copies skills into `.claude/skills/` but does **not** install agents, settings, or the workflow guide. Works with Claude Code, Cursor, Codex, Gemini CLI, and any tool supporting the [agentskills.io specification](https://agentskills.io).

### Option 4: Manual

```bash
git clone https://github.com/grasmash/drupal-claude-skills.git /tmp/drupal-skills

# Skills
cp -r /tmp/drupal-skills/skills/* .claude/skills/

# Agents
cp -r /tmp/drupal-skills/.claude/agents/* .claude/agents/

# Settings (review and customize)
cp /tmp/drupal-skills/.claude/settings.json .claude/settings.json

# Clean up
rm -rf /tmp/drupal-skills
```

Then add the agent workflow guide from [AGENTS.md](AGENTS.md) to your project's CLAUDE.md.

## What's Included

### Skills (`skills/`)

**Core Drupal**

| Skill | Description |
|-------|-------------|
| **[drupal-at-your-fingertips](skills/drupal-at-your-fingertips/)** | 50+ Drupal topics from [Selwyn Polit's book](https://drupalatyourfingertips.com) — services, hooks, entities, forms, theming, caching, testing |
| **[drupal-config-mgmt](skills/drupal-config-mgmt/)** | Configuration management — safe import/export, config splits (complete vs partial), environment syncing, merge workflows |
| **[drupal-config-reconcile](skills/drupal-config-reconcile/)** | Resolve config drift item-by-item against a deployed env — import vs export vs skip, verify with the import transformer, never write to prod |
| **[drupal-contrib-mgmt](skills/drupal-contrib-mgmt/)** | Contrib module management — Composer updates, composer-patches v2 (`patches.lock.json` + relock), Drupal 11 compatibility, drupal.org workflow |
| **[drupal-ddev](skills/drupal-ddev/)** | DDEV local development — setup, commands, database ops, Xdebug, performance (Mutagen), Docker/Mutagen troubleshooting |
| **[drupal-testing](skills/drupal-testing/)** | TDD with PHPUnit + DTT — bug-fix RED-first, bootstrap-level cost (Unit/Kernel/ExistingSite), the anonymous-403 permission trap, vacuous-pass pin |
| **[ivangrynenko-cursorrules-drupal](skills/ivangrynenko-cursorrules-drupal/)** | OWASP Top 10 security patterns from [Ivan Grynenko](https://github.com/ivangrynenko/cursorrules) — auth, access control, injection prevention, crypto |
| **[drupal-simple-oauth](skills/drupal-simple-oauth/)** | OAuth2 with simple_oauth — TokenAuthUser permissions, scope/role matching, field_permissions, CSRF bypass, debugging |
| **[drupal-search-api](skills/drupal-search-api/)** | Search API — index configuration, boost processors, custom processors, config management, reindexing |
| **[skill-developer](skills/skill-developer/)** | Meta-skill for creating new skills — agentskills.io spec, frontmatter schema, progressive disclosure, 500-line rule |

**Drupal Canvas** (page builder)

The React/JSX Code Component skills (component definition, metadata, composability, styling, data fetching, etc.) are maintained upstream — install them from the official suite rather than duplicating here (see [Canvas Ecosystem](#canvas-ecosystem)). This repo ships only the complements that suite doesn't cover:

| Skill | Description |
|-------|-------------|
| **[drupal-canvas](skills/drupal-canvas/)** | Canvas Code Components entry point — scaffolding, Nebula template, Acquia Source Site Builder integration |
| **[drupal-canvas-sdc](skills/drupal-canvas-sdc/)** | Twig-based Single Directory Components — `component.yml` schemas, preview, instance version management (the official suite is React/JSX only) |
| **[canvas-contribution](skills/canvas-contribution/)** | Contributing Canvas features/fixes upstream to drupal.org — issue forks, MRs, composer patches |
| **[acquia-source](skills/acquia-source/)** | Connect to an Acquia Source CMS — JSON:API (`/api`) + OAuth2, the MCP server (`claude mcp add`), the `@drupal-canvas` CLI, and Canvas Page API deploy pitfalls |

### 8 Agents (`.claude/agents/`)

| Agent | Description |
|-------|-------------|
| **quality-gate** | Pre-commit code review — security, performance, testing, regressions |
| **done-gate** | Completion validator — builds pass, tests run, deliverables exist |
| **drupal-specialist** | Drupal/PHP implementation — modules, hooks, services, Drush |
| **frontend-specialist** | Frontend — Twig, SCSS, JavaScript, responsive design, accessibility |
| **researcher** | Codebase exploration — architecture, patterns, execution paths |
| **reviewer** | Code review — bugs, security, quality, actionable feedback |
| **test-runner** | Test execution — PHP, JS, SCSS validation, build checks |
| **test-writer** | ExistingSite test writing — bug reproduction, DTT patterns |

### Settings (`.claude/settings.json`)

Sample Drupal-safe permission patterns. Prompts for confirmation before destructive operations like `drush cim`, `drush sql-drop`, and `drush site:install`.

## Canvas Ecosystem

The core Drupal Canvas Code Component skills (component definition, metadata, composability, utils, styling, data fetching, push, regions, page definition, …) are maintained in the official **[drupal-canvas/skills](https://github.com/drupal-canvas/skills)** repo. Install them directly rather than relying on a fork:

```bash
npx skills add drupal-canvas/skills
```

This repo intentionally does **not** duplicate those — it adds only the complements the official suite doesn't cover: `drupal-canvas-sdc` (Twig SDC) and `canvas-contribution` (contributing upstream to drupal.org). Use them alongside the official suite.

Scaffold a new Canvas project:

```bash
npx @drupal-canvas/create my-project
```

## Usage

Skills activate automatically based on context:

- Working with config splits → `drupal-config-mgmt` activates
- Updating a module → `drupal-contrib-mgmt` activates
- Security review → `ivangrynenko-cursorrules-drupal` activates
- OAuth debugging → `drupal-simple-oauth` activates
- Local dev issue → `drupal-ddev` activates

You can also invoke skills explicitly:
```
"Using the drupal-config-mgmt skill, help me set up partial config splits"
```

## Repository Structure

```
skills/                              # Skills (agentskills.io format)
├── drupal-at-your-fingertips/       #   50+ Drupal topics
│   ├── SKILL.md
│   └── references/
├── drupal-config-mgmt/              #   Config management
│   ├── SKILL.md
│   └── references/
├── drupal-contrib-mgmt/             #   Module management
│   ├── SKILL.md
│   ├── references/
│   └── examples/
├── drupal-ddev/                     #   DDEV local dev
│   ├── SKILL.md
│   └── references/
├── ivangrynenko-cursorrules-drupal/ #   Security patterns
│   ├── SKILL.md
│   └── references/
├── drupal-simple-oauth/             #   OAuth2 patterns
│   └── SKILL.md
├── drupal-search-api/               #   Search API patterns
│   └── SKILL.md
├── drupal-canvas/                   #   Canvas components
│   └── SKILL.md
└── skill-developer/                 #   Meta-skill for creating skills
    └── SKILL.md
.claude/
├── agents/                          # Agent definitions
│   ├── quality-gate.md
│   ├── done-gate.md
│   ├── drupal-specialist.md
│   ├── frontend-specialist.md
│   ├── researcher.md
│   ├── reviewer.md
│   ├── test-runner.md
│   └── test-writer.md
├── settings.json                    # Sample Drupal permissions
└── scripts/                         # Upstream sync scripts
    ├── sync-d9book.sh
    └── sync-ivan-rules.sh
```

## Updating Upstream Skills

Two skills sync from upstream sources:

```bash
# Sync Drupal at Your Fingertips references
./.claude/scripts/sync-d9book.sh

# Sync Ivan Grynenko security patterns
./.claude/scripts/sync-ivan-rules.sh
```

## Recommended Companion Tools

These aren't Drupal-specific, so they live outside this repo — but they pair well with these skills on real Drupal work. Install separately; they're optional.

- **[caveman](https://github.com/JuliusBrussee/caveman)** — a token-compression skill that has the agent reply in a terse, fragmented style, cutting output tokens ~65–75% while keeping technical accuracy. Useful for long Drupal sessions (config audits, multi-file refactors) where verbose narration burns tokens. Toggle with `/caveman`; stop with "normal mode."

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Adding new skills (follow [agentskills.io spec](https://agentskills.io/specification))
- Adding new agents
- Improving existing content
- Syncing upstream sources

## Credits

- **[Selwyn Polit](https://drupalatyourfingertips.com)** — Drupal at Your Fingertips
- **[Ivan Grynenko](https://github.com/ivangrynenko/cursorrules)** — Drupal security patterns
- **Drupal Community** — Ongoing contributions to documentation and best practices

## License

MIT — see [LICENSE](LICENSE)

## Related Resources

- [agentskills.io Specification](https://agentskills.io/specification)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Drupal Canvas Skills](https://github.com/drupal-canvas/skills)
- [Drupal.org](https://drupal.org)
- [DDEV Documentation](https://ddev.readthedocs.io)

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=grasmash/drupal-claude-skills&type=Date)](https://star-history.com/#grasmash/drupal-claude-skills&Date)
