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
# `si --existing-config` needs two things: $settings['config_sync_directory']
# set to an existing directory, and a core.extension.yml in it (Drush reads
# the install profile from that file).
# CONFIG_SYNC must match your project's config_sync_directory (container path).
CONFIG_SYNC=/var/www/html/config/default
if [ -f "$CONFIG_SYNC/core.extension.yml" ]; then
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
