# Drupal Claude Skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-orange.svg)](https://claude.com/claude-code)
[![Drupal](https://img.shields.io/badge/Drupal-10%20%7C%2011-blue.svg)](https://www.drupal.org)
[![agentskills.io](https://img.shields.io/badge/spec-agentskills.io-purple.svg)](https://agentskills.io)

A comprehensive collection of Claude Code skills and agents for Drupal development. Install battle-tested patterns for configuration management, module updates, security, local development, OAuth, search, and more.

## Quick Install

### Skills (via `npx skills`)

```bash
npx skills add grasmash/drupal-claude-skills
```

This copies all skills into your project's `.claude/skills/` directory. Works with Claude Code, Cursor, Codex, Gemini CLI, and any tool supporting the [agentskills.io specification](https://agentskills.io).

### Agents + Settings (manual)

```bash
# Copy agents
cp -r .claude/agents/ /path/to/your/project/.claude/agents/

# Copy sample settings
cp .claude/settings.json /path/to/your/project/.claude/settings.json
```

## What's Included

### 9 Skills (`skills/`)

| Skill | Description |
|-------|-------------|
| **[drupal-at-your-fingertips](skills/drupal-at-your-fingertips/)** | 50+ Drupal topics from [Selwyn Polit's book](https://drupalatyourfingertips.com) — services, hooks, entities, forms, theming, caching, testing |
| **[drupal-config-mgmt](skills/drupal-config-mgmt/)** | Configuration management — safe import/export, config splits (complete vs partial), environment syncing, merge workflows |
| **[drupal-contrib-mgmt](skills/drupal-contrib-mgmt/)** | Contrib module management — Composer updates, patch management, Drupal 11 compatibility, drupal.org contribution workflow |
| **[drupal-ddev](skills/drupal-ddev/)** | DDEV local development — setup, commands, database ops, Xdebug, performance (Mutagen), Docker/Mutagen troubleshooting |
| **[ivangrynenko-cursorrules-drupal](skills/ivangrynenko-cursorrules-drupal/)** | OWASP Top 10 security patterns from [Ivan Grynenko](https://github.com/ivangrynenko/cursorrules) — auth, access control, injection prevention, crypto |
| **[drupal-simple-oauth](skills/drupal-simple-oauth/)** | OAuth2 with simple_oauth — TokenAuthUser permissions, scope/role matching, field_permissions, CSRF bypass, debugging |
| **[drupal-search-api](skills/drupal-search-api/)** | Search API — index configuration, boost processors, custom processors, config management, reindexing |
| **[drupal-canvas](skills/drupal-canvas/)** | Drupal Canvas Code Components — scaffolding, Nebula template, Acquia Source Site Builder integration |
| **[skill-developer](skills/skill-developer/)** | Meta-skill for creating new skills — agentskills.io spec, frontmatter schema, progressive disclosure, 500-line rule |

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

For Drupal Canvas Code Components, this repo includes a lightweight `drupal-canvas` skill as an entry point. For the full 7-skill Canvas development suite:

```bash
npx skills add drupal-canvas/skills
```

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
