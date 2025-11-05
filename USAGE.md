# Quick Start Guide

## What You Have Now

A clean, open-source repository at `~/Sites/drupal-claude-skills` containing:

1. **Four Drupal Skills**:
   - `drupal-at-your-fingertips` - 50+ Drupal development patterns
   - `drupal-composer-updates` - Module update workflows
   - `drupal-config-mgmt` - Safe configuration management
   - `ivangrynenko-cursorrules-drupal` - OWASP security patterns

2. **Documentation**:
   - `README.md` - Comprehensive project overview
   - `LICENSE` - MIT license with third-party notices
   - `.gitignore` - Standard ignores

3. **Sync Script**:
   - `sync-from-private.sh` - Automated sync from your private repo

## Syncing Updates from Private Repo

When you make improvements to the Drupal skills in your private GuitarGate repository, sync them to this open-source repo:

```bash
cd ~/Sites/drupal-claude-skills

# Run sync script (defaults to ~/Sites/gg as source)
./sync-from-private.sh

# Or specify custom source path
./sync-from-private.sh /path/to/your/private/repo

# Review changes
git diff

# Commit if looks good
git add .claude/skills
git commit -m "Sync latest skill updates from private repo"
```

The script will:
- Create a backup branch automatically
- Copy only Drupal-specific skills (excludes GuitarGate skills)
- Show you what changed
- Let you review before committing

## Publishing to GitHub

When you're ready to open source this:

```bash
cd ~/Sites/drupal-claude-skills

# Create repository on GitHub first, then:
git remote add origin git@github.com:YOUR_USERNAME/drupal-claude-skills.git

# Push to GitHub
git push -u origin main
```

## Testing the Skills

To test these skills work with Claude Code:

```bash
# Option 1: Copy to a test Drupal project
cp -r ~/Sites/drupal-claude-skills/.claude /path/to/test/drupal/project/

# Option 2: Install globally for all projects
mkdir -p ~/.config/claude/skills
cp -r ~/Sites/drupal-claude-skills/.claude/skills/* ~/.config/claude/skills/
```

## Maintenance Workflow

**Regular Updates**:
1. Work on skills in your private GuitarGate repo
2. When you make general Drupal improvements (not GuitarGate-specific)
3. Run `./sync-from-private.sh`
4. Review and commit changes
5. Push to GitHub

**What Gets Synced**:
- ✅ drupal-at-your-fingertips
- ✅ drupal-composer-updates
- ✅ drupal-config-mgmt.md
- ✅ ivangrynenko-cursorrules-drupal
- ❌ guitargate-* (automatically excluded)

**GuitarGate References**:
All GuitarGate-specific content was removed during initial setup. Future syncs will preserve this clean state as long as you only modify the Drupal-specific skills.

## Repository Structure

```
drupal-claude-skills/
├── .claude/
│   └── skills/
│       ├── drupal-at-your-fingertips/
│       │   ├── SKILL.md
│       │   └── references/
│       ├── drupal-composer-updates/
│       │   ├── SKILL.md
│       │   ├── references/
│       │   └── examples/
│       ├── drupal-config-mgmt.md
│       └── ivangrynenko-cursorrules-drupal/
│           ├── SKILL.md
│           └── references/
├── README.md
├── LICENSE
├── USAGE.md (this file)
├── .gitignore
└── sync-from-private.sh
```

## Next Steps

1. **Test the sync script**:
   ```bash
   cd ~/Sites/drupal-claude-skills
   ./sync-from-private.sh
   # Should report "No changes detected"
   ```

2. **Create GitHub repository** and push when ready

3. **Optional**: Add GitHub Actions for automated testing/validation

4. **Share with community** on drupal.org, Reddit, etc.

## Support

For issues:
- Check sync script output for errors
- Verify source path is correct
- Ensure git working directory is clean before syncing
- Review git diff before committing

## Contributing Back

If others contribute improvements to the open-source version:

```bash
cd ~/Sites/drupal-claude-skills
git pull origin main

# Manually copy improvements back to private repo
cp -r .claude/skills/drupal-* ~/Sites/gg/.claude/skills/
cd ~/Sites/gg
git add .claude/skills
git commit -m "Sync community improvements from open-source repo"
```
