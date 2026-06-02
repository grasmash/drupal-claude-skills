# Terminus Drush - Safe Command Patterns

**Critical**: Terminus drush commands require special handling to avoid unintended actions.

---

## The Problem: Auto-Confirmation

**Terminus defaults to `--yes` for ALL prompts**, unlike running drush locally. This means destructive commands will execute without confirmation!

### Dangerous vs Safe Patterns

❌ **DANGEROUS** - Will auto-execute:
```bash
terminus drush site.env -- cim --diff
terminus drush site.env -- config:import
terminus drush site.env -- sql-drop
terminus drush site.env -- pm:uninstall module_name
```

✅ **SAFE** - Use `--no` flag for inspection:
```bash
terminus drush site.env -- cim --no --diff
terminus drush site.env -- config:status
terminus drush site.env -- pm:list
```

---

## Essential Safe Commands

### Cache Operations (Safe)

```bash
# Clear all caches
terminus drush site.env -- cr

# Rebuild cache
terminus drush site.env -- cache:rebuild
```

### Configuration Inspection (Use --no)

```bash
# View config status (safe)
terminus drush site.env -- config:status

# View import diff WITHOUT importing
terminus drush site.env -- cim --no --diff

# View export diff WITHOUT exporting
terminus drush site.env -- cex --no --diff

# Get specific config value (safe)
terminus drush site.env -- config:get system.site
terminus drush site.env -- config:get system.site name
terminus drush site.env -- config:get block.block.mytheme_hero --format=yaml
```

### Database Operations

```bash
# Run database updates
terminus drush site.env -- updb -y

# Check for pending updates (safe)
terminus drush site.env -- updb --no

# Execute SQL query (read-only example)
terminus drush site.env -- sqlq "SELECT COUNT(*) FROM node"

# Export database (creates backup)
terminus drush site.env -- sql:dump > backup.sql
```

### Module Management

```bash
# List modules (safe)
terminus drush site.env -- pm:list
terminus drush site.env -- pm:list --status=enabled

# Enable module (use with caution)
terminus drush site.env -- pm:enable module_name -y

# Uninstall module (DANGEROUS - use carefully)
terminus drush site.env -- pm:uninstall module_name -y
```

### User Operations

```bash
# List users (safe)
terminus drush site.env -- user:information admin

# Create one-time login link (safe)
terminus drush site.env -- user:login
terminus drush site.env -- uli

# Reset password (use with caution)
terminus drush site.env -- user:password admin "new_password"
```

### Content and Entity Queries

```bash
# Query content (safe, read-only)
terminus drush site.env -- eval "return \Drupal::entityQuery('node')->accessCheck(FALSE)->count()->execute();"

# Get entity info (safe)
terminus drush site.env -- eval "print_r(\Drupal\node\Entity\Node::load(1)->toArray());"
```

---

## Config Management Workflow

**Never use automated config import on Terminus!** Use manual workflow instead.

### Safe Inspection

```bash
# 1. Check what would be imported (NO changes)
terminus drush site.env -- cim --no --diff

# 2. Get specific config for comparison
terminus drush site.env -- config:get block.block.hero --format=yaml > remote.yml

# 3. Compare with local
diff -u config/default/block.block.hero.yml remote.yml
```

### Safe Import (Multi-Step)

```bash
# 1. Backup database first
terminus backup:create site.env --element=db

# 2. Export current config for safety
terminus drush site.env -- cex -y

# 3. View what will change
terminus drush site.env -- cim --no --diff

# 4. If safe, import
terminus drush site.env -- cim -y

# 5. Clear cache
terminus drush site.env -- cr
```

### Pull Active Config from Pantheon to Local

**Use case**: Pull the active database config from Pantheon to your local filesystem (not just the files in code/config/default).

```bash
# Step 1: Ensure Pantheon aliases are in project (DDEV compatibility)
# Copy from ~/.drush/sites/pantheon/ to project's drush/sites/
mkdir -p drush/sites
cp ~/.drush/sites/pantheon/sitename.site.yml drush/sites/

# Step 2: Export active config on Pantheon to /tmp
terminus drush site.env -- config:export --destination=/tmp/env-active-config -y

# Step 3: Rsync active config from Pantheon to local
# Get connection details from drush/sites/sitename.site.yml
# Format: user@host (from site alias)
rsync -rlvz -e 'ssh -p 2222 -o "AddressFamily inet"' \
  ENV.UUID@appserver.ENV.UUID.drush.in:/tmp/env-active-config/ \
  config/default/

# Step 4: Check what changed
git status config/default/

# Step 5: Review and commit changes
git diff config/default/
git add config/default/
git commit -m "Pull active config from Pantheon ENV"
```

**Important Notes:**
- This pulls **active config from database**, not filesystem config/default
- Dev environment filesystem is read-only, can't write to code/config/default
- Must export to /tmp on Pantheon, then rsync to local
- Some permission warnings are normal during export on Pantheon
- Remove incompatible modules (e.g., entity_limit for D11) from core.extension.yml after pull

**Example with your project site:**
```bash
# 1. Copy aliases
cp ~/.drush/sites/pantheon/mysite.site.yml drush/sites/

# 2. Export active config on dev
terminus drush mysite.dev -- config:export --destination=/tmp/dev-active-config -y

# 3. Rsync to local (using details from alias file)
rsync -rlvz -e 'ssh -p 2222 -o "AddressFamily inet"' \
  dev.06de5750-0d84-4ae9-978a-3a9b14bebbab@appserver.dev.06de5750-0d84-4ae9-978a-3a9b14bebbab.drush.in:/tmp/dev-active-config/ \
  config/default/

# 4. Review changes
git status config/default/
```

---

## Common Patterns

### Post-Deployment Commands

```bash
# After code deploy, run updates
terminus drush site.env -- updb -y
terminus drush site.env -- cr
terminus drush site.env -- cim -y  # Only if config in code
```

### Debugging

```bash
# Check status
terminus drush site.env -- status

# View recent watchdog errors
terminus drush site.env -- watchdog:show --severity=Error --count=20

# Check for errors
terminus drush site.env -- watchdog:show --severity=Error --since="10 minutes ago"
```

### Development Tools

```bash
# Generate one-time login
terminus drush site.env -- uli

# Clear specific cache bins
terminus drush site.env -- cache:clear render
terminus drush site.env -- cache:clear dynamic_page_cache

# Rebuild theme registry
terminus drush site.env -- cache:rebuild
```

---

## Advanced Patterns

### Conditional Execution

```bash
# Check environment before destructive command
ENV="test"
if [ "$ENV" != "live" ]; then
  terminus drush site.$ENV -- sql-sanitize -y
fi
```

### Scripted Workflows

```bash
#!/bin/bash
# Safe deployment script

SITE="mysite"
ENV="test"

echo "Deploying to $ENV..."

# Backup
terminus backup:create $SITE.$ENV --element=db

# Deploy code (if using multidev)
terminus env:deploy $SITE.$ENV --note="Deploy via script"

# Run updates
terminus drush $SITE.$ENV -- updb -y

# Import config
terminus drush $SITE.$ENV -- cim --no --diff
read -p "Import config? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  terminus drush $SITE.$ENV -- cim -y
fi

# Clear cache
terminus drush $SITE.$ENV -- cr

echo "Deployment complete!"
```

### Bulk Operations

```bash
# Clear cache on all environments
for env in dev test live; do
  echo "Clearing cache on $env..."
  terminus drush site.$env -- cr
done

# Run updates across environments
for env in dev test; do
  terminus drush site.$env -- updb -y
  terminus drush site.$env -- cr
done
```

---

## Comparison: Terminus vs Local Drush

| Command | Local Drush | Terminus Drush |
|---------|-------------|----------------|
| `drush cr` | Safe | Safe |
| `drush cim` | Prompts for confirmation | **Auto-confirms!** Use `--no` |
| `drush sql-drop` | Prompts | **Auto-confirms!** Dangerous! |
| `drush pm:uninstall` | Prompts | **Auto-confirms!** Use carefully |
| `drush config:status` | Safe | Safe |
| `drush updb` | Prompts | **Auto-confirms!** Review first |

---

## Best Practices

1. **Always use `--no` for inspection** - Never trust auto-confirmation
2. **Backup before destructive ops** - Use `terminus backup:create`
3. **Test on multidev first** - Never experiment on live
4. **Review diff output** - Read what will change
5. **Use scripting carefully** - Add confirmation prompts
6. **Log commands** - Keep audit trail of what was run
7. **Monitor logs** - Check `watchdog:show` after changes
8. **Clear cache after** - Run `cr` after updates/imports

---

## Common Mistakes to Avoid

❌ **Don't**: `terminus drush site.live -- cim`
✅ **Do**: `terminus drush site.test -- cim --no --diff` first

❌ **Don't**: Run destructive commands without backup
✅ **Do**: `terminus backup:create` first

❌ **Don't**: Import config on live without testing
✅ **Do**: Test on multidev → test → live

❌ **Don't**: Forget to clear cache after changes
✅ **Do**: Always run `cr` after updates

---

## Troubleshooting

### Command Fails Silently

```bash
# Check PHP errors
terminus drush site.env -- php-eval "phpinfo();"

# Check Drush status
terminus drush site.env -- status
```

### Config Import Fails

```bash
# Check config validation
terminus drush site.env -- config:status

# View errors
terminus drush site.env -- watchdog:show --severity=Error
```

### Permission Denied

```bash
# Verify you're authenticated
terminus auth:whoami

# Re-authenticate if needed
terminus auth:login --email=you@example.com
```

---

## Related Documentation

- @drupal-config-mgmt - Full config management workflow
- Terminus commands: https://pantheon.io/docs/terminus/commands
- Drush commands: https://www.drush.org/latest/commands/

---

**Last updated**: 2025-11-06
