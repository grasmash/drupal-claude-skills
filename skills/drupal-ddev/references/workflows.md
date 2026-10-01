# DDEV Common Workflows

Step-by-step setup, import, sync and daily-routine workflows, plus multi-project management, moved from SKILL.md.

## Common Workflows

### New Drupal Project

```bash
# Create project directory
mkdir myproject && cd myproject

# Initialize DDEV
ddev config --project-type=drupal11 --docroot=web --php-version=8.3

# Install Drupal via Composer
ddev composer create drupal/recommended-project

# Install Drush
ddev composer require drush/drush

# Start DDEV
ddev start

# Install Drupal
ddev drush site:install standard --site-name="My Site" --account-name=admin

# Launch site
ddev launch
```

### Import Existing Project

```bash
# Clone repository
git clone repo-url myproject && cd myproject

# Start DDEV (reads .ddev/config.yaml)
ddev start

# Install dependencies
ddev composer install

# Import database
ddev import-db --file=path/to/backup.sql.gz

# Import files (if needed)
ddev import-files --source=/path/to/files

# Run updates
ddev drush updb -y
ddev drush cr

# Launch
ddev launch
```

### Database Sync from a Remote/Production Environment

```bash
# Get latest backup from your hosting platform, e.g.:
#   Pantheon: terminus backup:create/backup:get
#   Acquia:   acli pull:database
#   Generic:  drush @alias sql:dump

# Import to local
ddev import-db --file=backup.sql.gz

# Run updates
ddev drush updb -y
ddev drush cr

# Sanitize for local (optional)
ddev drush sql-sanitize -y
```

### Daily Development Workflow

```bash
# Morning: Start project
ddev start

# Pull latest code
git pull origin main

# Update dependencies if needed
ddev composer install

# Clear cache
ddev drush cr

# Work on features...

# Create database snapshot before testing
ddev snapshot --name=before-testing

# Test changes...

# If needed, restore snapshot
ddev snapshot restore --name=before-testing

# Evening: Stop project
ddev stop
```


## Multi-Project Management

```bash
# List all projects
ddev list

# Stop all projects
ddev poweroff

# Remove stopped projects
ddev delete <project-name>

# Remove all project containers (keep files)
ddev delete --omit-snapshot --yes <project-name>
```

### Agent Worktree Cleanup

Multi-agent workflows that dispatch via `git worktree` accumulate one
directory per agent under `.claude/worktrees/` and nothing removes them on
its own — left unmanaged this is unbounded disk growth (one project found
46GB of stale worktrees in a single session). A SessionStart "worktree
janitor" hook can sweep entries that are unlocked, old
enough, and either clean or dirty with only junk files; anything with real
tracked-file changes is left alone and logged, never bulldozed. Never `rm -rf`
a worktree by hand — use `git worktree remove` (it refuses on genuine dirty
state, which is the safety you want). Executors that spin up their own
worktree should clean it up themselves when done.
