# Publication Checklist

This document guides you through publishing the Drupal Claude Skills to GitHub and the Claude Code marketplace.

## ✅ Pre-Publication Verification (COMPLETED)

- [x] All GuitarGate references removed
- [x] All project-specific code examples generalized
- [x] No sensitive information (credentials, tokens, domains)
- [x] All code examples use `{site}`, `{env}`, and generic placeholders
- [x] LICENSE file with proper attribution
- [x] CONTRIBUTING.md with clear guidelines
- [x] README.md with badges and marketplace pitch
- [x] USAGE.md rewritten for public audience
- [x] Git history clean (10 commits, no sensitive data)

**Verification performed**: Comprehensive grep for sensitive terms returned 0 results.

---

## Step 1: Create GitHub Repository

### On GitHub.com

1. Go to https://github.com/new
2. Repository name: `drupal-claude-skills`
3. Description: `Comprehensive Claude Code skills for Drupal 9/10/11 development - Best practices, security patterns, and platform workflows`
4. Public repository
5. **DO NOT** initialize with README (we already have one)
6. Create repository

### Locally

```bash
cd ~/Sites/drupal-claude-skills

# Add GitHub remote (replace YOUR_USERNAME)
git remote add origin git@github.com:YOUR_USERNAME/drupal-claude-skills.git

# Push to GitHub
git push -u origin main

# Verify
git remote -v
```

### Repository Settings

Configure these on GitHub:

1. **About** (top right):
   - Description: `Comprehensive Claude Code skills for Drupal development`
   - Website: Leave blank initially
   - Topics: `drupal`, `claude-code`, `claude-skills`, `drupal-10`, `drupal-11`, `ai-assisted-development`, `developer-tools`

2. **Features** (Settings → General):
   - ✅ Issues
   - ✅ Discussions (recommended)
   - ❌ Projects
   - ❌ Wiki

3. **Social Preview** (Settings → General):
   - Upload a social preview image (optional, 1280x640px)

---

## Step 2: Submit to awesome-claude-skills

### Create Pull Request

```bash
# Fork travisvn/awesome-claude-skills on GitHub
# Clone your fork
git clone git@github.com:YOUR_USERNAME/awesome-claude-skills.git
cd awesome-claude-skills

# Create branch
git checkout -b add-drupal-skills

# Edit README.md and add to appropriate section:
```

Add this entry:

```markdown
### Drupal Development

- [drupal-claude-skills](https://github.com/YOUR_USERNAME/drupal-claude-skills) - Comprehensive skills for Drupal 9/10/11 development including contrib management, configuration, DDEV, Pantheon, and OWASP security patterns
```

```bash
# Commit and push
git add README.md
git commit -m "Add Drupal Claude Skills collection"
git push origin add-drupal-skills

# Create PR on GitHub
```

---

## Step 3: Announce to Drupal Community

### drupal.org Blog Post

Create a blog post at https://www.drupal.org/user/YOUR_ID/blog

**Title**: Drupal Claude Skills: AI-Assisted Development for Drupal 9/10/11

**Body**:
```markdown
I'm excited to announce **Drupal Claude Skills** - a comprehensive collection of Claude Code skills specifically designed for Drupal development.

## What is it?

Claude Code is Anthropic's AI coding assistant. Skills extend Claude with specialized knowledge for specific frameworks and workflows. Until now, the Claude ecosystem had no CMS-specific skills.

Drupal Claude Skills fills this gap with 6 battle-tested skills:

1. **drupal-at-your-fingertips** - 50+ Drupal patterns from Selwyn Polit
2. **drupal-contrib-mgmt** - Composer, patches, Drupal 11 upgrades
3. **drupal-config-mgmt** - Safe config workflows with critical Terminus patterns
4. **drupal-ddev** - Complete DDEV local development reference
5. **drupal-pantheon** - Pantheon platform workflows
6. **ivangrynenko-cursorrules-drupal** - OWASP Top 10 security patterns

## Why use it?

- **Context-aware**: Skills activate automatically based on your task
- **Battle-tested**: From real production Drupal development
- **Expert knowledge**: Curated from industry experts
- **Modern**: Drupal 9, 10, and 11 support

## Get Started

GitHub: https://github.com/YOUR_USERNAME/drupal-claude-skills

```bash
# Install globally
mkdir -p ~/.config/claude/skills
git clone https://github.com/YOUR_USERNAME/drupal-claude-skills.git
cp -r drupal-claude-skills/.claude/skills/* ~/.config/claude/skills/
```

## Contributing

All contributions welcome! See CONTRIBUTING.md for guidelines.

This is open-source (MIT) and builds on excellent work by:
- Selwyn Polit (drupalatyourfingertips.com)
- Ivan Grynenko (Security patterns)
- The Drupal community

Let's make AI understand Drupal! 🚀
```

### Reddit Post

Post to r/drupal:

**Title**: [Tool] Drupal Claude Skills - Comprehensive AI skills for Drupal development

**Link**: https://github.com/YOUR_USERNAME/drupal-claude-skills

**Comment**:
> I've compiled 6 comprehensive Claude Code skills for Drupal 9/10/11 development. This is the first skill collection specifically for Drupal in the Claude ecosystem.
>
> Covers: contrib management, config workflows, DDEV, Pantheon, security (OWASP), and 50+ Drupal patterns from industry experts.
>
> All open-source (MIT). Feedback and contributions welcome!

### Twitter/X

```
🚀 Just released Drupal Claude Skills - comprehensive AI assistance for Drupal 9/10/11 dev

6 battle-tested skills covering:
✅ Contrib management
✅ Safe config workflows
✅ DDEV & Pantheon
✅ OWASP security
✅ 50+ expert patterns

First skill collection for Drupal + Claude Code!

https://github.com/YOUR_USERNAME/drupal-claude-skills

#Drupal #AI #DeveloperTools
```

---

## Step 4: Claude Code Marketplace Submission

### Prerequisites

Based on https://github.com/anthropics/skills:

1. Repository must be public on GitHub
2. Skills follow proper format (SKILL.md with frontmatter)
3. Clear documentation

### Submission Process

**Option A: Via Claude Code CLI** (when available)

```bash
# Register repository as marketplace
claude plugin marketplace add https://github.com/YOUR_USERNAME/drupal-claude-skills.git

# Test installation
claude plugin install drupal-at-your-fingertips@YOUR_USERNAME
```

**Option B: Contact Anthropic**

Email to Claude Code team or open GitHub discussion:
- Repository: https://github.com/YOUR_USERNAME/drupal-claude-skills
- Description: First comprehensive skill collection for Drupal CMS
- Request inclusion in official marketplace

### Marketplace Listing Details

When submitting, provide:

**Repository URL**: `https://github.com/YOUR_USERNAME/drupal-claude-skills`

**Short Description**:
> Comprehensive Claude Code skills for Drupal 9/10/11 development including contrib management, configuration workflows, DDEV local development, and OWASP security patterns.

**Tags**:
`drupal`, `cms`, `php`, `web-development`, `security`, `devops`, `configuration-management`

**Skills Included**:
- drupal-at-your-fingertips (50+ Drupal patterns)
- drupal-contrib-mgmt (Composer & module management)
- drupal-config-mgmt (Safe config workflows)
- drupal-ddev (Local development)
- ivangrynenko-cursorrules-drupal (OWASP security)

---

## Step 5: Monitor & Maintain

### GitHub Repository

- Enable GitHub Discussions for community Q&A
- Respond to issues within 48 hours
- Review PRs promptly
- Add GitHub Actions for validation (optional):
  ```yaml
  # .github/workflows/validate-skills.yml
  name: Validate Skills
  on: [push, pull_request]
  jobs:
    validate:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v2
        - name: Validate YAML frontmatter
          run: |
            # Add validation script
  ```

### Update Schedule

**Upstream syncs** (monthly):
```bash
cd ~/Sites/drupal-claude-skills
./.claude/scripts/sync-d9book.sh
./.claude/scripts/sync-ivan-rules.sh

git add .claude
git commit -m "Update upstream content from drupalatyourfingertips.com and Ivan's rules"
git push origin main
```

**Drupal version updates** (when new major version releases):
- Update skill descriptions
- Add new deprecation patterns
- Test compatibility

---

## Success Metrics

Track these to measure adoption:

- GitHub stars
- Forks
- Issues/discussions
- Downloads (if marketplace provides stats)
- Community mentions (drupal.org, reddit, twitter)

---

## Troubleshooting

### GitHub Push Issues

```bash
# If push rejected, check remote
git remote -v

# Re-add if needed
git remote set-url origin git@github.com:YOUR_USERNAME/drupal-claude-skills.git
```

### Sensitive Data Found

If you discover sensitive data AFTER publishing:

1. **DO NOT** just delete and recommit
2. Use git-filter-repo or BFG Repo-Cleaner to rewrite history
3. Force push (breaks forks, but necessary)
4. Inform anyone who cloned/forked

### Badge URLs Not Working

Replace `YOUR_USERNAME` in:
- README.md badges
- USAGE.md links
- Star History chart

---

## Post-Publication TODO

After publishing:

- [ ] Replace `YOUR_USERNAME` with actual GitHub username in all files
- [ ] Update USAGE.md with actual GitHub URL
- [ ] Test installation from GitHub
- [ ] Create GitHub Release v1.0.0
- [ ] Add CHANGELOG.md
- [ ] Share on social media
- [ ] Monitor for issues/questions

---

## Contact

For questions about this publication process:
- Open GitHub Discussion
- Email: [your-email if you want]
- Drupal.org: [your profile]

---

**Ready to publish!** 🚀

All preparation work is complete. Follow Steps 1-5 above to make this public.
