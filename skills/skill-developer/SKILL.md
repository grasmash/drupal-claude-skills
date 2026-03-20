---
name: skill-developer
description: Create and manage Claude Code skills following Anthropic best practices and the agentskills.io specification. Use when creating new skills, understanding trigger patterns, debugging skill activation, or implementing progressive disclosure. Covers SKILL.md structure, YAML frontmatter schema, trigger types, enforcement levels, hook mechanisms, and progressive disclosure.
---

# Skill Developer Guide

## Purpose

Comprehensive guide for creating and managing skills in Claude Code, following the **[Agent Skills Specification](https://agentskills.io/specification)** and Anthropic's best practices including the 500-line rule and progressive disclosure pattern.

## Agent Skills Specification (agentskills.io)

Skills in this project follow the open **[Agent Skills Specification](https://agentskills.io/specification)**. Key requirements:

### Directory Structure

```
skills/{skill-name}/
├── SKILL.md           # Required - main skill file
├── references/        # Optional - detailed documentation
├── scripts/           # Optional - executable code (Python, Bash, JS)
└── assets/            # Optional - templates, images, data files
```

### SKILL.md Frontmatter Schema

**Required Fields:**
| Field | Requirements |
|-------|-------------|
| `name` | 1-64 chars, lowercase alphanumeric + hyphens, must match directory name |
| `description` | 1-1024 chars, include keywords for agent activation |

**Optional Fields:**
| Field | Purpose |
|-------|---------|
| `license` | License for sharing skills publicly |
| `compatibility` | Environment requirements (packages, network access) |
| `metadata` | Key-value pairs for custom properties |
| `allowed-tools` | Pre-approved tools list (experimental) |

### Progressive Disclosure Model

1. **Metadata** (~100 tokens) - loads at startup
2. **Full instructions** (<5000 tokens recommended) - loads on activation
3. **Supporting files** - loads as needed

### Validation

Use `skills-ref` tool or validate manually:
- File must be named `SKILL.md` (uppercase)
- Name in frontmatter must match parent directory
- Description should include trigger keywords

## When to Use This Skill

Automatically activates when you mention:
- Creating or adding skills
- Modifying skill triggers or rules
- Understanding how skill activation works
- Debugging skill activation issues
- Claude Code best practices
- Progressive disclosure
- YAML frontmatter
- 500-line rule

---

## System Overview

### Skill Activation Approaches

There are several approaches to skill activation, from simple to advanced:

**1. Description-Based Activation (Default)**
- Claude reads skill descriptions from frontmatter at session start
- Activates skills when user prompts match description keywords
- No additional configuration needed
- Works out of the box with the agentskills.io spec

**2. Example Implementation: Hook-Based Activation**

For more sophisticated activation, you can build a hook system. This is an advanced pattern:

**UserPromptSubmit Hook** (Proactive Suggestions)
- Trigger: BEFORE Claude sees user's prompt
- Purpose: Suggest relevant skills based on keywords + intent patterns
- Method: Injects formatted reminder as context (stdout to Claude's input)

**Stop Hook** (Gentle Reminders)
- Trigger: AFTER Claude finishes responding
- Purpose: Gentle reminder to self-assess patterns in code written
- Method: Analyzes edited files for patterns, displays reminder if needed

**Configuration for Hook Systems:**

A rules file (e.g., `skill-rules.json`) can define:
- All skills and their trigger conditions
- Enforcement levels (block, suggest, warn)
- File path patterns (glob)
- Content detection patterns (regex)
- Skip conditions (session tracking, file markers, env vars)

---

## Skill Types

### 1. Guardrail Skills

**Purpose:** Enforce critical best practices that prevent errors

**Characteristics:**
- Type: `"guardrail"`
- Enforcement: `"block"`
- Priority: `"critical"` or `"high"`
- Block file edits until skill used
- Prevent common mistakes
- Session-aware (don't repeat nag in same session)

**Examples:**
- `database-verification` - Verify table/column names before queries
- `frontend-dev-guidelines` - Enforce React/TypeScript patterns

**When to Use:**
- Mistakes that cause runtime errors
- Data integrity concerns
- Critical compatibility issues

### 2. Domain Skills

**Purpose:** Provide comprehensive guidance for specific areas

**Characteristics:**
- Type: `"domain"`
- Enforcement: `"suggest"`
- Priority: `"high"` or `"medium"`
- Advisory, not mandatory
- Topic or domain-specific
- Comprehensive documentation

**Examples:**
- `backend-dev-guidelines` - Node.js/Express/TypeScript patterns
- `frontend-dev-guidelines` - React/TypeScript best practices
- `drupal-search-api` - Search API configuration guidance

**When to Use:**
- Complex systems requiring deep knowledge
- Best practices documentation
- Architectural patterns
- How-to guides

---

## Quick Start: Creating a New Skill

### Step 1: Create Skill File

**Location:** `skills/{skill-name}/SKILL.md`

**Template:**
```markdown
---
name: my-new-skill
description: Brief description including keywords that trigger this skill. Mention topics, file types, and use cases. Be explicit about trigger terms.
---

# My New Skill

## Purpose
What this skill helps with

## When to Use
Specific scenarios and conditions

## Key Information
The actual guidance, documentation, patterns, examples
```

**Best Practices (per agentskills.io spec):**
- **Name**: 1-64 chars, lowercase alphanumeric + hyphens, must match directory name
- **Description**: 1-1024 chars, include ALL trigger keywords/phrases
- **Content**: Under 500 lines - use `references/` directory for details
- **Examples**: Real code examples
- **Structure**: Clear headings, lists, code blocks

### Step 2: (Optional) Add Trigger Rules

If using a hook-based activation system, add rules:

**Basic Template:**
```json
{
  "my-new-skill": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "medium",
    "promptTriggers": {
      "keywords": ["keyword1", "keyword2"],
      "intentPatterns": ["(create|add).*?something"]
    }
  }
}
```

### Step 3: Test Activation

Verify your skill activates correctly:
- Try prompts that should trigger it
- Try prompts that should NOT trigger it
- Refine description keywords based on results

### Step 4: Follow Anthropic Best Practices

- Keep SKILL.md under 500 lines
- Use progressive disclosure with reference files
- Add table of contents to reference files > 100 lines
- Write detailed description with trigger keywords
- Test with 3+ real scenarios before documenting
- Iterate based on actual usage

---

## Enforcement Levels

### BLOCK (Critical Guardrails)

- Physically prevents Edit/Write tool execution
- Claude sees message and must use skill to proceed
- **Use For**: Critical mistakes, data integrity, security issues

**Example:** Database column name verification

### SUGGEST (Recommended)

- Reminder injected before Claude sees prompt
- Claude is aware of relevant skills
- Not enforced, just advisory
- **Use For**: Domain guidance, best practices, how-to guides

**Example:** Frontend development guidelines

### WARN (Optional)

- Low priority suggestions
- Advisory only, minimal enforcement
- **Use For**: Nice-to-have suggestions, informational reminders

**Rarely used** - most skills are either BLOCK or SUGGEST.

---

## Skip Conditions & User Control

### 1. Session Tracking

**Purpose:** Don't nag repeatedly in same session

**How it works:**
- First edit: Hook blocks, updates session state
- Second edit (same session): Hook allows
- Different session: Blocks again

### 2. File Markers

**Purpose:** Permanent skip for verified files

**Marker:** `// @skip-validation`

**Usage:**
```typescript
// @skip-validation
import { PrismaService } from './prisma';
// This file has been manually verified
```

**NOTE:** Use sparingly - defeats the purpose if overused

### 3. Environment Variables

**Purpose:** Emergency disable, temporary override

**Global disable:**
```bash
export SKIP_SKILL_GUARDRAILS=true  # Disables ALL blocks
```

**Skill-specific:**
```bash
export SKIP_DB_VERIFICATION=true
```

---

## Testing Checklist

When creating a new skill, verify:

- [ ] Skill file created in `skills/{name}/SKILL.md`
- [ ] Proper frontmatter with name and description
- [ ] Keywords tested with real prompts
- [ ] No false positives in testing
- [ ] No false negatives in testing
- [ ] **SKILL.md under 500 lines**
- [ ] Reference files created if needed
- [ ] Table of contents added to files > 100 lines

---

## Advanced Topics

For teams building sophisticated activation systems, consider:

- **Trigger types**: Keywords, intent patterns, file path globs, content regex
- **Hook mechanisms**: UserPromptSubmit, PreToolUse, Stop event hooks
- **Session state management**: Tracking which skills have been acknowledged
- **Performance**: Keep hook execution under 200ms
- **Pattern libraries**: Reusable regex and glob patterns

These topics are documented in optional reference files:
- `TRIGGER_TYPES.md` - Complete trigger type guide
- `SKILL_RULES_REFERENCE.md` - Rules schema documentation
- `HOOK_MECHANISMS.md` - Hook internals deep dive
- `TROUBLESHOOTING.md` - Debugging activation issues
- `PATTERNS_LIBRARY.md` - Ready-to-use pattern collection

---

## Quick Reference Summary

### Create New Skill (4 Steps)

1. Create `skills/{name}/SKILL.md` with frontmatter
2. Test activation with real prompts
3. Refine description keywords based on testing
4. Keep SKILL.md under 500 lines

### Trigger Types

- **Keywords**: Explicit topic mentions (in description)
- **Intent**: Implicit action detection (advanced, via hooks)
- **File Paths**: Location-based activation (advanced, via hooks)
- **Content**: Technology-specific detection (advanced, via hooks)

### Enforcement

- **BLOCK**: Critical only, prevents tool execution
- **SUGGEST**: Most common, advisory context injection
- **WARN**: Advisory, rarely used

### Skip Conditions

- **Session tracking**: Automatic (prevents repeated nags)
- **File markers**: `// @skip-validation` (permanent skip)
- **Env vars**: `SKIP_SKILL_GUARDRAILS` (emergency disable)

### Anthropic Best Practices & agentskills.io Spec

- **500-line rule**: Keep SKILL.md under 500 lines
- **Progressive disclosure**: Use `references/` directory for detailed docs
- **Table of contents**: Add to reference files > 100 lines
- **One level deep**: Don't nest references deeply
- **Rich descriptions**: Include all trigger keywords (max 1024 chars per spec)
- **Name = Directory**: Skill name in frontmatter must match parent directory
- **Test first**: Build 3+ evaluations before extensive documentation
- **Spec URL**: https://agentskills.io/specification

### Troubleshoot

Test skill activation by trying prompts that should and should not trigger the skill. Refine description keywords iteratively.

---

## Related Files

**Configuration:**
- `skills/*/SKILL.md` - Skill content files

**Specification:**
- https://agentskills.io/specification - Agent Skills Spec
