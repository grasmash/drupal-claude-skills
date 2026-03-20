---
name: drupal-search-api
description: Search API configuration, boosting strategies, and processor patterns for Drupal. Covers index configuration, field types, custom boost processors, number field boosting, engagement metrics, and reindexing workflows.
---

# Drupal Search API Patterns

This skill documents Search API configuration patterns, boosting strategies, and custom processor development for Drupal sites.

## Index Configuration

### Field Type Requirements

**Boolean Fields for Boosting**
- Boolean fields work best with custom boost processors
- Integer fields can cause issues with boolean-based boost logic
- Always configure boolean fields as `type: boolean` in index settings

```yaml
field_settings:
  field_featured:
    label: Featured
    datasource_id: 'entity:node'
    property_path: field_featured
    type: boolean  # NOT integer
    boost: 8.0
```

**Configuration Command**
```bash
ddev drush config:set search_api.index.{index_name} \
  field_settings.field_featured.type boolean
```

### Numeric Fields for Engagement Boosting

**Flag Count Fields**
- Use `type: integer` for count fields
- Managed by `flag_search_api` module
- Automatically indexed and updated

```yaml
field_settings:
  flag_bookmark_count:
    label: 'Bookmark count'
    property_path: flag_bookmark_count
    type: integer
  flag_favorite_count:
    label: 'Favorite count'
    property_path: flag_favorite_count
    type: integer
```

## Boost Processors

### Custom Boolean Boost Processor

**When to Use**
- Boolean field boosting (featured flags, promoted content)
- Needs 100% control over boost logic
- Complex conditional boosting

**Pattern: FeaturedContentBoost.php**

```php
<?php

namespace Drupal\custom_search\Plugin\search_api\processor;

use Drupal\search_api\Item\ItemInterface;
use Drupal\search_api\Processor\ProcessorPluginBase;

/**
 * @SearchApiProcessor(
 *   id = "featured_content_boost",
 *   label = @Translation("Featured content boost"),
 *   description = @Translation("Adds a boost to indexed items marked as featured."),
 *   stages = {
 *     "preprocess_index" = 0,
 *   },
 *   locked = false,
 *   hidden = false,
 * )
 */
class FeaturedContentBoost extends ProcessorPluginBase {

  /**
   * {@inheritdoc}
   */
  public function preprocessIndexItems(array $items) {
    /** @var \Drupal\search_api\Item\ItemInterface $item */
    foreach ($items as $item) {
      try {
        $entity = $item->getOriginalObject()->getValue();

        // Check if entity has featured field and it's set to TRUE.
        if ($entity->hasField('field_featured') &&
            !$entity->get('field_featured')->isEmpty() &&
            $entity->get('field_featured')->value == 1) {
          $old_boost = $item->getBoost();
          // Apply 2x boost to featured content.
          $item->setBoost($old_boost * 2.0);
        }
      }
      catch (\Exception $e) {
        // Skip items that can't be loaded.
        continue;
      }
    }
  }
}
```

**Key Points**
- Use multiplicative boost: `$item->setBoost($old_boost * boost_factor)`
- Pattern from `search_api_boolean_field_boost` module
- Boost at index time via `preprocess_index` stage
- Always get old boost first to preserve other boosts

**Recommended Boost Factors**
- Featured content: `2.0x` (modest but effective)
- Featured content: `1.5x - 3.0x`
- Premium content: `1.5x - 2.0x`

### Number Field Boost Processor

**When to Use**
- Engagement metrics (likes, bookmarks, views)
- Numeric quality scores
- Time-based decay factors

**Configuration Pattern**

```yaml
processor_settings:
  number_field_boost:
    weights:
      preprocess_index: 0
    boosts:
      flag_bookmark_count:
        boost_factor: 0.01
        aggregation: max
      flag_favorite_count:
        boost_factor: 0.1
        aggregation: max
```

**How It Works**
- Adds to boost based on field value
- Formula: `boost += (field_value * boost_factor)`
- Example: 138 bookmarks x 0.01 = +1.38 boost

**Configuration Commands**
```bash
# Set bookmark count boost (0.01 per bookmark)
ddev drush config:set search_api.index.{index_name} \
  processor_settings.number_field_boost.boosts.flag_bookmark_count.boost_factor 0.01

# Set favorite count boost (0.1 per favorite)
ddev drush config:set search_api.index.{index_name} \
  processor_settings.number_field_boost.boosts.flag_favorite_count.boost_factor 0.1
```

**Recommended Boost Factors**
- Bookmark count: `0.01 - 0.05` (for counts in 10-1000 range)
- Favorite count: `0.1 - 0.5` (for counts in 1-50 range)
- View count: `0.001 - 0.01` (for counts in 100-10000 range)

### Processor Conflicts

**Problem: Multiple Processors on Same Field**

If multiple processors target the same field, they can conflict:
- One overrides the other
- Boosts don't combine as expected
- Unpredictable results

**Solution: Remove Conflicting Configuration**

```bash
# Remove field from number_field_boost if using custom processor
ddev drush config:set search_api.index.{index_name} \
  processor_settings.number_field_boost.boosts.field_featured null
```

**Best Practice**
- Use custom processor for boolean/complex logic
- Use number_field_boost for simple numeric boosts
- Don't configure same field in multiple processors

## Configuration Management

### Direct Config Updates with PHP

When `drush config:set` fails or produces unexpected results (e.g., side effects on unrelated config), use PHP to directly update active configuration:

```bash
ddev drush php:eval "
\$config = \Drupal::configFactory()->getEditable('search_api.index.{index_name}');

// Set field type
\$config->set('field_settings.field_featured.type', 'boolean');

// Remove from number_field_boost
\$boosts = \$config->get('processor_settings.number_field_boost.boosts');
unset(\$boosts['field_featured']);
\$config->set('processor_settings.number_field_boost.boosts', \$boosts);

// Set boost factors
\$config->set('processor_settings.number_field_boost.boosts.flag_bookmark_count.boost_factor', 0.01);
\$config->set('processor_settings.number_field_boost.boosts.flag_favorite_count.boost_factor', 0.1);

\$config->save();
echo \"Configuration updated\n\";
"
```

**When to Use PHP Instead of drush config:set:**
- When config:set creates unwanted side effects (e.g., changing `server: {server_name}` to `server: null`)
- When removing array keys (unset pattern works better than `null`)
- When making multiple related changes atomically
- When field type changes cause Drupal to fallback to generic types

**After PHP Config Updates:**
1. Verify changes: `ddev drush config:get search_api.index.{index_name} field_settings.field_featured`
2. Export to files: `ddev drush config:export -y`
3. Review exported changes: `git diff config/default/`
4. Revert any unintended changes (e.g., ngram fields changed to plain text)

### Field Type Preservation

**Problem:** When Solr server config is modified (e.g., pointing to a different backend), config export may downgrade custom field types to generic types:

```yaml
# BEFORE (correct)
field_display_name:
  type: 'solr_text_custom:ngramstring'

# AFTER export (incorrect)
field_display_name:
  type: text
```

**Solution:** After exporting, restore custom field types via PHP:

```bash
ddev drush php:eval "
\$config = \Drupal::configFactory()->getEditable('search_api.index.{index_name}');
\$config->set('field_settings.field_display_name.type', 'solr_text_custom:ngramstring');
\$config->set('field_settings.label.type', 'solr_text_custom:ngramstring');
\$config->set('field_settings.name.type', 'solr_text_custom:ngramstring');
\$config->set('field_settings.title.type', 'solr_text_custom:ngramstring');
\$config->save();
"
ddev drush config:export -y
```

**Fields Using ngram Tokenization:**
- `field_display_name` - Display names (partial matching for autocomplete)
- `label` - Entity labels/titles
- `name` - User account names
- `title` - Node titles

**Never change these to `type: text`** - it breaks partial name matching (e.g., "mich" won't find "Michael").

### Config Export Side Effects

When modifying Search API server config (e.g., for local development), Drupal may update index configs to remove server dependencies:

```yaml
# Unintended change in search_api.index.{index_name}.yml
dependencies:
  config:
-    - search_api.server.{server_name}  # Removed
server: null  # Changed from {server_name}
```

**Prevention:**
1. Don't modify `search_api.server.{server_name}.yml` for local development
2. Use DDEV's built-in Solr service without changing server config
3. If server config changes are needed, use config splits for environment-specific settings
4. Always review `git diff config/default/` before committing

**Recovery:**
```bash
# Revert index files if server was set to null
git checkout HEAD -- config/default/search_api.index.*.yml
```

## Reindexing After Changes

### When Reindexing is Required

**Always reindex after:**
- Changing field type (integer -> boolean)
- Changing boost factors
- Adding/removing processors
- Modifying processor configuration

**Reindex Commands**

```bash
# Full reindex workflow
ddev drush cr
ddev drush search-api:clear {index_name}
ddev drush search-api:index {index_name}

# Check index status
ddev drush search-api:status {index_name}
```

### Partial Reindexing

```bash
# Index only remaining items (incremental)
ddev drush search-api:index {index_name}

# Clear and reindex specific items (not available in core)
# Use full reindex instead
```

## Testing Boosts

### Search API Drush Commands

```bash
# Test search via drush
ddev drush search-api:search {index_name} "search query"

# Check indexed values
ddev drush search-api:status {index_name}
```

### Web Endpoint Testing

```bash
# Test via web search endpoint
curl -H "Accept: application/vnd.api+json" \
  "https://example.com/search-api/web-search?query=test"

# Parse results with Python
curl -s "https://example.com/search-api/web-search?query=test" | \
  python3 -c "import sys, json; data = json.load(sys.stdin); \
  [print(f'{i+1}. {item[\"attributes\"][\"title\"]}') \
  for i, item in enumerate(data['data'][:10])]"
```

### Validation Queries

**Check Bookmark Counts**
```sql
SELECT u.uid, u.name, fcf.count AS bookmark_count
FROM users_field_data u
LEFT JOIN flag_counts fcf ON fcf.entity_type = 'user'
  AND fcf.entity_id = u.uid
  AND fcf.flag_id = 'bookmark'
ORDER BY fcf.count DESC
LIMIT 10;
```

**Check Favorite Counts**
```sql
SELECT n.nid, n.title, fcl.count AS favorite_count
FROM node_field_data n
INNER JOIN flag_counts fcl ON fcl.entity_type = 'node'
  AND fcl.entity_id = n.nid
  AND fcl.flag_id = 'favorite'
WHERE n.type = 'article'
ORDER BY fcl.count DESC
LIMIT 10;
```

## Performance Considerations

### Index-Time vs Query-Time Boosting

**Index-Time Boosting (Recommended)**
- Better performance (computed once during indexing)
- Scales with high query volume
- Requires reindex when boost logic changes
- Static boosts (can't adjust per-query)

**Query-Time Boosting**
- Dynamic (can adjust per-query)
- No reindex needed for changes
- Performance impact on every query
- Complex to implement with Search API

**Recommended Pattern: Index-Time Boosting**
- All boosts applied during `preprocess_index` stage
- Scales better for high-traffic search
- Acceptable reindex requirement

### Boost Stacking

**How Boosts Combine**
1. Base relevance score (from Solr)
2. Featured content boost: `score x 2.0`
3. Bookmark count boost: `score + (bookmarks x 0.01)`
4. Favorite count boost: `score + (favorites x 0.1)`

**Example Calculation**
```
Node: "Getting Started with Drupal" (featured, 138 bookmarks)
- Base score: 1.0
- Featured: 1.0 x 2.0 = 2.0
- 138 bookmarks: 2.0 + (138 x 0.01) = 3.38
- Final boost: 3.38

Node: "Advanced Drupal Techniques"
- Base score: 1.0
- 12 favorites: 1.0 + (12 x 0.1) = 2.2
- Final boost: 2.2
```

## Common Issues

### Issue: Boost Not Applied

**Symptoms**
- Results not ranking as expected
- No difference after reindex

**Checklist**
1. Processor enabled in index config
2. Field type correct (boolean/integer)
3. Full reindex completed
4. No conflicting processors
5. Cache cleared after config changes

**Debug Commands**
```bash
# Check processor configuration
ddev drush config:get search_api.index.{index_name} processor_settings

# Check field configuration
ddev drush config:get search_api.index.{index_name} field_settings

# Verify index status
ddev drush search-api:status {index_name}
```

### Issue: Boost Too Strong/Weak

**Symptoms**
- Irrelevant results ranking too high
- Important results not ranking high enough

**Solution: Adjust Boost Factors**

Too strong (dominating relevance):
- Reduce multiplicative boosts (2.0 -> 1.5)
- Reduce additive boost factors (0.1 -> 0.05)

Too weak (no visible effect):
- Increase boost factors gradually
- Test with extreme values to confirm working, then dial back

**Testing Pattern**
1. Start with conservative boost (1.5x or 0.01)
2. Test with known queries
3. Increase gradually until effect visible
4. Reduce to optimal level

## Module Dependencies

### Required Modules
- `search_api` - Core Search API module
- `search_api_solr` - Solr backend (if using Solr)

### Optional Modules
- `flag_search_api` - Index flag counts (bookmark, favorite)
- `search_api_boolean_field_boost` - Reference for boost patterns

## References

### Search API Processor Development
- [Search API Processors](https://www.drupal.org/docs/contributed-modules/search-api/developer-documentation/processors)
- [Drupal API: ProcessorPluginBase](https://api.drupal.org/api/drupal/search_api%21src%21Processor%21ProcessorPluginBase.php/class/ProcessorPluginBase)

### Boosting Strategies
- [Search API Boost Module](https://www.drupal.org/project/search_api_boost)
- [Solr Boosting](https://solr.apache.org/guide/solr/latest/query-guide/boosting.html)

### Flag Search API
- [Flag Search API Module](https://www.drupal.org/project/flag_search_api)
- Provides flag count indexing for engagement metrics
