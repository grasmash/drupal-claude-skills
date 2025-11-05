# Contributing to Drupal Claude Skills

Thank you for your interest in contributing to this project! This guide will help you get started.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest improvements
- Search existing issues first to avoid duplicates
- Include clear descriptions and examples
- For skill-specific content issues, consider reporting to upstream sources

### Suggesting New Skills

Before proposing a new skill:

1. Check if it fits the Drupal development scope
2. Ensure it's not too project-specific
3. Verify it doesn't duplicate existing skills
4. Consider if it could be a reference within an existing skill instead

Good candidates for new skills:
- Platform-specific patterns (Acquia, Platform.sh, etc.)
- Tool-specific workflows (Lando, Composer, etc.)
- Drupal subsystems (Layout Builder, Workflows, Media, etc.)
- Development methodologies (BDD, migrations, etc.)

### Improving Existing Skills

We welcome improvements to existing skills:

- Fix errors or outdated information
- Add missing examples or patterns
- Improve clarity and organization
- Update for new Drupal versions

## Skill Structure Requirements

Each skill must follow this structure:

### Directory-Based Skill

```
.claude/skills/skill-name/
├── SKILL.md              # Main skill file
└── references/           # Optional detailed docs
    ├── topic1.md
    └── topic2.md
```

### Single-File Skill

```
.claude/skills/skill-name.md
```

## SKILL.md Format

Every skill must have YAML frontmatter:

```yaml
---
name: skill-name
description: Complete description of what the skill does and when to use it. Should be detailed enough for semantic matching.
---
```

**Required sections:**
1. **Title** - Clear, descriptive heading
2. **When This Skill Activates** - Context that triggers this skill
3. **Content** - Patterns, examples, and best practices
4. **Sources/Credits** - Attribution for upstream content

**Optional sections:**
- Available Topics (for multi-file skills)
- Quick Reference
- Common Workflows
- Troubleshooting
- Related Skills

## Coding Standards

### Markdown Style

- Use ATX-style headers (`#` not `===`)
- Include blank lines before/after headers
- Use fenced code blocks with language tags
- Keep lines under 120 characters where practical
- Use `-` for unordered lists, `1.` for ordered

### Code Examples

```yaml
# Good: Generic, reusable
terminus drush {site}.{env} -- cr

# Bad: Project-specific
terminus drush mysite.dev -- cr
```

- Use `{placeholders}` for variable values
- Provide context with comments
- Show both correct and incorrect patterns when helpful
- Include expected output when relevant

### File Organization

- Keep related content together
- Use descriptive reference file names
- Avoid deeply nested directories
- Follow existing naming conventions

## Content Guidelines

### Accuracy

- Verify against official Drupal documentation
- Test code examples before submitting
- Note which Drupal versions apply
- Update deprecated patterns

### Clarity

- Write for intermediate Drupal developers
- Explain "why" not just "how"
- Use concrete examples
- Avoid jargon without explanation

### Completeness

- Cover common use cases
- Include troubleshooting tips
- Link to official documentation
- Provide related patterns

### Neutrality

- No project-specific references
- No personal credentials or tokens
- No hardcoded domain names
- Use generic placeholders

## Pull Request Process

1. **Fork and Branch**
   ```bash
   git checkout -b feature/improve-ddev-skill
   ```

2. **Make Changes**
   - Follow structure requirements
   - Test with Claude Code
   - Update relevant documentation

3. **Commit**
   ```bash
   git add .claude/skills/drupal-ddev/
   git commit -m "Add database snapshot workflow to DDEV skill"
   ```

4. **Test**
   - Install skill locally
   - Verify it activates correctly
   - Test examples work
   - Check for sensitive data

5. **Submit PR**
   - Clear description of changes
   - Reference any related issues
   - Explain testing performed

## Testing Your Changes

### Local Testing

```bash
# Copy to test project
cp -r .claude /path/to/test/drupal/project/

# Start Claude Code in test project
cd /path/to/test/drupal/project
claude
```

### Verification Checklist

- [ ] YAML frontmatter is valid
- [ ] Skill activates in relevant contexts
- [ ] Code examples are tested
- [ ] No sensitive/project-specific data
- [ ] Markdown renders correctly
- [ ] Links work
- [ ] Credits/sources are accurate

## Syncing Upstream Content

Skills with upstream sources should be updated periodically:

### Drupal at Your Fingertips

```bash
./.claude/scripts/sync-d9book.sh
```

Updates from: https://drupalatyourfingertips.com

### Ivan Grynenko Security Patterns

```bash
./.claude/scripts/sync-ivan-rules.sh
```

Updates from: https://github.com/ivangrynenko/cursorrules

**Note**: Don't modify auto-synced reference files directly - they'll be overwritten. Instead, update the sync scripts or contribute upstream.

## Attribution

### Upstream Sources

Always credit original sources:

```markdown
**Source**: [Source Name](https://example.com)
**Author**: Author Name
**License**: License Type
```

### Your Contributions

By contributing, you agree:
- Your work is licensed under MIT (matching this project)
- You have rights to contribute the content
- You credit any sources appropriately

## Community Standards

- Be respectful and constructive
- Focus on Drupal development best practices
- Help others learn and improve
- Follow Drupal community values

## Questions?

- Open a GitHub Discussion for general questions
- Use Issues for specific bugs/features
- Check existing documentation first
- Tag maintainers if urgent

## Recognition

Contributors will be:
- Listed in commit history
- Credited in release notes for significant contributions
- Recognized in community announcements

Thank you for helping make Drupal development with Claude Code better! 🚀
