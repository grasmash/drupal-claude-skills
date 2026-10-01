# Config Splits: Overview and Complete vs Partial

What config splits are for and how to choose between Complete and Partial splits, moved from SKILL.md.

## Config Splits Overview

Config splits allow you to have **environment-specific configuration** that doesn't get deployed to all environments.

### Common Use Cases

- **Local development**: Enable devel, kint, stage_file_proxy
- **Staging/Test**: Enable similar modules but different API keys
- **Production**: Disable development modules, enable caching

### How Splits Work

1. **Base config** (`config/default/`) - Shared across all environments
2. **Split config** (`config/{split-name}/`) - Environment-specific overrides
3. **Split definition** (`config/default/config_split.config_split.{name}.yml`) - Defines which config goes in split

When a split is **active**, its config takes precedence over base config.

### Split Activation

Splits are activated based on conditions in their config:
- **Status**: `status: true` in split config
- **Environment variable**: Can use conditions based on env vars
- **Manual activation**: Via admin UI or drush

---

## Complete vs Partial Splits

**CRITICAL**: Understanding the difference between Complete and Partial splits is essential.

### Complete Splits (Recommended for most cases)

**How it works**:
- Config in the split is **ONLY active** when split is enabled
- When split is disabled, config is **completely removed** from active config
- Think: "This config exists ONLY in this environment"

**Use cases**:
- Development modules (devel, kint, webprofiler)
- Environment-specific modules (stage_file_proxy for local)
- Testing modules (simpletest, phpunit)

**Example**: Local split with devel module
```yaml
# config/default/config_split.config_split.local.yml
status: true
module:
  devel: 0
  kint: 0
complete_list:
  - 'core.extension'
```

When split is **active**: devel and kint are enabled
When split is **inactive**: devel and kint are completely removed

**Reference**: See admin form at `/admin/config/development/configuration/config-split/{split-name}`:
> "Complete Split: Remove the selected configuration entirely when the split is inactive. When this split is inactive, the configuration listed here will be removed from the system completely."

### Partial Splits (Conditional Overrides)

**How it works**:
- Base config exists in `config/default/`
- Split contains **overrides** in `config/{split-name}/`
- When split is active, overrides are merged with base config
- When split is inactive, base config is used
- Think: "This config exists everywhere, but with different values per environment"

**Use cases**:
- API keys that differ per environment
- Email settings (different SMTP per environment)
- Cache settings (aggressive in prod, disabled in local)
- Search server URLs (local Solr vs Pantheon Search)

**Example**: Different search servers per environment

Base config (`config/default/search_api.server.main.yml`):
```yaml
backend_config:
  connector: pantheon_search
  # Production settings
```

Local override (`config/local/config_split.patch.search_api.server.main.yml`):
```yaml
backend_config:
  connector: solr
  connector_config:
    host: solr
    # Local Solr settings
```

When local split is **active**: Uses local Solr
When local split is **inactive**: Uses Pantheon Search

**Reference**: See admin form at `/admin/config/development/configuration/config-split/{split-name}`:
> "Partial Split (Conditional Override): Keep the selected configuration, but override it when the split is active. The configuration will exist in the sync directory, but the version from this split will be used instead when the split is active."

### Choosing Complete vs Partial

**Use Complete when**:
- ✅ Config should NOT exist in other environments (modules, views, blocks)
- ✅ It's an on/off decision (enable/disable)
- ✅ Different environments need different features

**Use Partial when**:
- ✅ Config exists everywhere but with different VALUES
- ✅ Same feature, different settings (API URLs, credentials)
- ✅ You need the base config to be importable without the split active
