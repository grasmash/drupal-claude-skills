# DDEV Custom Commands

Project-specific `ddev` commands, moved from SKILL.md.

## Custom Commands

Create project-specific commands in `.ddev/commands/web/`:

**Example**: `.ddev/commands/web/fresh-install`
```bash
#!/bin/bash
## Description: Fresh Drupal install from scratch
## Usage: fresh-install
## Example: ddev fresh-install

set -e

echo "Installing fresh Drupal site..."

# Drop existing database
drush sql-drop -y

# Install Drupal. With an exported config directory, install FROM it:
# a `site:install standard` followed by `config:import` fails, because the new
# site's UUID never matches the exported system.site UUID
# (SystemConfigSubscriber rejects the import).
if [ -f /var/www/html/config/default/system.site.yml ]; then
  drush site:install --existing-config \
    --account-name=admin --account-pass=admin -y
else
  drush site:install standard \
    --site-name="My Site" \
    --account-name=admin \
    --account-pass=admin \
    -y
fi

# Clear cache
drush cr

echo "Fresh install complete!"
echo "Login: admin / admin"
```

Make it executable:
```bash
chmod +x .ddev/commands/web/fresh-install
ddev fresh-install
```
