# Configuration Management

**Source**: [Drupal at Your Fingertips - config](https://drupalatyourfingertips.com/config)
**Author**: Selwyn Polit

Quick reference for Drupal configuration management with practical code examples.

---

## Core Concept

Configuration in Drupal lives in YAML files (version control) and the database (active config). The Configuration API provides a standardized way to read, write, import, and export settings. Config files use the pattern `modulename.something.yml`.

## Reading Configuration

**In PHP code**:
```php
// Read config value
$config = \Drupal::config('system.site');
$site_name = $config->get('name');
$site_mail = $config->get('mail');

// Read nested value
$endpoint = \Drupal::config('my_module.settings')
  ->get('api.endpoint');
```

**Via Drush**:
```bash
# Get config value
drush cget system.site name
drush cget shield.settings credentials.shield.pass

# Include overridden values from settings.php
drush cget system.site name --include-overridden
```

---

## Writing Configuration

**In PHP code** (use getEditable):
```php
// Write config value
\Drupal::configFactory()
  ->getEditable('my_module.settings')
  ->set('api_key', 'abc123')
  ->save();

// Write multiple values
$config = \Drupal::configFactory()->getEditable('my_module.settings');
$config->set('api.endpoint', 'https://api.example.com')
  ->set('api.timeout', 30)
  ->save();

// Clear specific value
$config->clear('old_setting')->save();
```

**Via Drush**:
```bash
# Set config value
drush cset system.site name "My Site Name"
drush cset shield.settings credentials.shield.pass secretpass
```

---

## Configuration Forms

**Extend ConfigFormBase** for settings:
```php
use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

class SettingsForm extends ConfigFormBase {

  protected function getEditableConfigNames() {
    return ['my_module.settings'];
  }

  public function getFormId() {
    return 'my_module_settings_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state) {
    $config = $this->config('my_module.settings');

    $form['api_key'] = [
      '#type' => 'textfield',
      '#title' => $this->t('API Key'),
      '#default_value' => $config->get('api_key'),
      '#required' => TRUE,
    ];

    $form['api_endpoint'] = [
      '#type' => 'url',
      '#title' => $this->t('API Endpoint'),
      '#default_value' => $config->get('api_endpoint'),
    ];

    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state) {
    $this->config('my_module.settings')
      ->set('api_key', $form_state->getValue('api_key'))
      ->set('api_endpoint', $form_state->getValue('api_endpoint'))
      ->save();

    parent::submitForm($form, $form_state);
  }
}
```

---

## Altering Existing Config Forms

**Add fields to core forms**:
```php
function my_module_form_system_site_information_settings_alter(&$form, FormStateInterface $form_state) {
  $config = \Drupal::config('system.site');

  $form['site_phone'] = [
    '#type' => 'tel',
    '#title' => t('Site phone'),
    '#default_value' => $config->get('phone'),
  ];

  // Add custom submit handler
  $form['#submit'][] = 'my_module_system_site_phone_submit';
}

function my_module_system_site_phone_submit(array &$form, FormStateInterface $form_state) {
  \Drupal::configFactory()
    ->getEditable('system.site')
    ->set('phone', $form_state->getValue('site_phone'))
    ->save();
}
```

---

## Configuration Storage

**Config sync directory** (settings.php):
```php
// Default location
$settings['config_sync_directory'] = '../config/sync';

// Custom location
$settings['config_sync_directory'] = '/var/www/config';
```

**Module config directories**:
| Directory | Purpose | Behavior |
|-----------|---------|----------|
| `config/install` | Installed with module | Module install fails if config fails |
| `config/optional` | Installed if dependencies exist | Module installs regardless |
| `config/schema` | Defines config structure | Used for validation |

---

## Configuration Overrides

**Override in settings.php** (environment-specific):
```php
// Override site name
$config['system.site']['name'] = 'Dev Site';
$config['system.site']['mail'] = 'dev@example.com';

// Override performance settings
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

// Override shield credentials
$config['shield.settings']['credentials']['shield']['user'] = 'admin';
$config['shield.settings']['credentials']['shield']['pass'] = 'password';
```

**Environment-specific** (settings.local.php):
```php
// Disable CSS/JS aggregation for development
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

// Disable page caching
$config['system.performance']['cache']['page']['max_age'] = 0;
```

---

## Import/Export Configuration

**Export all config**:
```bash
# Export to sync directory
drush cex -y

# Check status before export
drush cst

# Export specific module
drush cex --destination=/tmp/config
```

**Import config**:
```bash
# Import all from sync directory
drush cim -y

# Import from specific directory
drush config-import --source=modules/custom/my_module/config/install/ --partial -y

# Check import status
drush cst
```

**Common workflow**:
```bash
# 1. Check what changed
drush cst

# 2. Export changes
drush cex -y

# 3. Commit to Git
git add config/
git commit -m "Export config changes"

# 4. On another environment
git pull
drush cim -y
```

---

## Post-Update Hooks

**Modify config during updates** (my_module.post_update.php):
```php
<?php

/**
 * Change site name.
 */
function my_module_post_update_change_site_name() {
  \Drupal::configFactory()
    ->getEditable('system.site')
    ->set('name', 'My New Site Name')
    ->save();
}

/**
 * Update API endpoint.
 */
function my_module_post_update_api_endpoint() {
  \Drupal::configFactory()
    ->getEditable('my_module.settings')
    ->set('api.endpoint', 'https://new-api.example.com')
    ->save();
}
```

**Run post-updates**:
```bash
drush updb -y
```

---

## Configuration Read-Only Mode

**Protect production config** (settings.php):
```php
// Enable read-only mode in production
if (isset($_ENV['AH_SITE_ENVIRONMENT']) && $_ENV['AH_SITE_ENVIRONMENT'] === 'prod') {
  $settings['config_readonly'] = TRUE;
}

// Whitelist specific config
$settings['config_readonly_whitelist_patterns'] = [
  'system.menu.main*',
  'webform.webform.*',
  'block.block.*',
];
```

---

## Site UUID Management

**View/set site UUID**:
```bash
# View UUID
drush cget system.site uuid

# Set UUID (for config sync)
drush cset system.site uuid 1234567890
```

**Override in settings.php**:
```php
$config['system.site']['uuid'] = '1234567890';
```

**Why important**: Config imports require matching UUIDs between files and active site.

---

## Dependency Injection for Config

**Inject config factory**:
```php
use Drupal\Core\Config\ConfigFactoryInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class MyService {

  protected ConfigFactoryInterface $configFactory;

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('config.factory')
    );
  }

  public function __construct(ConfigFactoryInterface $config_factory) {
    $this->configFactory = $config_factory;
  }

  public function getApiKey() {
    return $this->configFactory
      ->get('my_module.settings')
      ->get('api_key');
  }
}
```

---

## Config Entities vs Simple Config

**Simple config** - Settings, key-value pairs:
```yaml
# my_module.settings.yml
api_key: 'abc123'
api_endpoint: 'https://api.example.com'
timeout: 30
```

**Config entities** - Exportable content types, views, blocks:
```yaml
# views.view.my_view.yml
id: my_view
label: 'My View'
module: views
display:
  default:
    # ...
```

---

## Debugging Configuration

**List all config**:
```bash
# List all config names
drush config:status --state=Identical

# Search config
drush config:status | grep shield
```

**View raw config**:
```bash
# View entire config object
drush config:get system.site

# View as YAML
drush config:get system.site --format=yaml
```

**Check config sync status**:
```bash
# Compare database vs files
drush config:status

# Show differences
drush config:status --state=Different
```

---

---

## Key Guidelines

✅ **Use ConfigFormBase** - For settings forms
✅ **Use getEditable()** - For writing config
✅ **Use get() only** - For reading config (immutable)
✅ **Export config to Git** - Always version control
✅ **Use post-update hooks** - For config changes during updates
✅ **Override in settings.php** - For environment-specific values
✅ **Use config:status** - Check before import/export
✅ **Inject config.factory** - Use DI in services
✅ **Backup database** - Before config imports

❌ **Don't use get()->set()** - Use getEditable() instead
❌ **Don't edit config/install** - Export/import instead
❌ **Don't hardcode settings** - Use config API
❌ **Don't skip exports** - Keep files in sync
❌ **Don't modify database directly** - Use config API
❌ **Don't forget UUID** - Must match for imports
❌ **Don't use static calls in classes** - Inject dependencies

---

**Full documentation**: https://drupalatyourfingertips.com/config
