# Canvas Component Versioning and Drush Commands

How Canvas pins component instances to versions, how to migrate them, and the drush commands involved.

## Contents

- [Canvas Component Versioning (CRITICAL)](#canvas-component-versioning-critical)
- [Drush Commands](#drush-commands)

## Canvas Component Versioning (CRITICAL)

**Understanding component versioning is essential when modifying SDC components.**

### How Versioning Works

Canvas uses a **version-pinning system** for backward compatibility:

1. Each component has an `active_version` (an xxh64 hash)
2. Component instances are **pinned to the version they were created with**
3. When you add/change props, Canvas creates a new `active_version`
4. **Existing instances stay on their old version** - they won't show new fields

### The Problem

When you add a new prop to a component (e.g., adding `gap` to `section`):
- **New** component instances will have the new field
- **Existing** instances created before the change **will NOT show the new field**

This is intentional - Canvas preserves backward compatibility so existing pages don't break.

### Solution: Migrate Instances to Active Version

**IMPORTANT**: After modifying component props, always run the upgrade command to migrate existing instances.

**Not shipped by Canvas.** `canvas:upgrade-instances` and `canvas:component-info` are project-custom Drush commands; Canvas 1.7.1 ships no Drush commands at all. You would have to write them. Such an upgrade command compares `components_component_version` in `canvas_page__components` and `canvas_page_revision__components` with each `canvas.component.*` entity's `active_version`, lists the mismatches, and rewrites the pinned version hash to the active one (it does not change stored inputs). The info command prints a component's `active_version`, all its stored versions, and how many instances are pinned to each.

Example usage, assuming you have written such commands:

```bash
# List components with outdated instances
ddev drush canvas:upgrade-instances

# Preview what would be migrated (dry run)
ddev drush canvas:upgrade-instances sdc.mytheme.section --dry-run

# Migrate a specific component's instances
ddev drush canvas:upgrade-instances sdc.mytheme.section

# Migrate ALL outdated instances at once
ddev drush canvas:upgrade-instances --all

# Show detailed version info for a component
ddev drush canvas:component-info sdc.mytheme.section
```

### Development Workflow for Component Prop Changes

When modifying SDC component props during development:

1. **Modify the component** (`component.yml`, `.twig`, `.css`)
2. **Clear cache**: `ddev drush cr`
3. **Check for outdated instances**: `ddev drush canvas:upgrade-instances`
4. **Migrate if needed**: `ddev drush canvas:upgrade-instances <component_id>`

### canvas_styling_traits Schema Changes

When modifying `canvas_styling_traits/schema.json` (adding/removing/renaming enum values):

1. **Update schema.json** with new enum values
2. **Clear cache**: `ddev drush cr`
3. **Upgrade instances**: `ddev drush canvas:upgrade-instances --all -y`

**CRITICAL**: If you **remove** an enum value (e.g., removing "none" from spacing enums), existing component instances that have that value stored will fail validation at render time with `Does not have a value in the enumeration`. You must also clean the stored data. The `canvas:upgrade-instances` command migrates instances to the new component version but does NOT update stored field values that are no longer valid.

To fix invalid stored values, use a drush script or `hook_update_N()`:
```php
$database = \Drupal::database();
$tables = ['canvas_page__components', 'canvas_page_revision__components'];
foreach ($tables as $table) {
  $results = $database->select($table, 'c')
    ->fields('c')
    ->condition('c.components_component_id', 'sdc.mytheme.page-header')
    ->execute();
  foreach ($results as $row) {
    $inputs = json_decode($row->components_inputs, TRUE);
    $changed = FALSE;
    foreach (['margin_top', 'margin_bottom'] as $field) {
      if (isset($inputs[$field]) && $inputs[$field] === 'none') {
        unset($inputs[$field]); // Or set to a valid value
        $changed = TRUE;
      }
    }
    if ($changed) {
      $database->update($table)
        ->fields(['components_inputs' => json_encode($inputs)])
        ->condition('entity_id', $row->entity_id)
        ->condition('revision_id', $row->revision_id)
        ->condition('delta', $row->delta)
        ->execute();
    }
  }
}
\Drupal::cache('entity')->deleteAll();
\Drupal::cache('render')->deleteAll();
```

**Summary of enum semantics for styling traits:**
- **"- None -"** (Drupal's built-in for non-required `list_string`) = unset, no CSS class applied, element keeps its default styling
- **"zero"** (explicit enum value) = `margin: 0` / `padding: 0`, actively removes spacing via CSS class `cst-mt-zero` etc.

### Production Deployment Workflow

For production deployments where you change component props:
- Write a `hook_update_N()` to migrate instances
- Or run your custom `drush canvas:upgrade-instances --all` as part of deployment scripts

### Canvas Config Entity Structure

Component config entities store versions in `config/default/canvas.component.*.yml`:

```yaml
active_version: c533daa1ccfd0fba  # Current version hash
versioned_properties:
  active:
    settings:
      prop_field_definitions:
        gap:  # New prop - only in active version
          field_type: list_string
          # ...
  2076209c0228c2bb:  # Old version - no gap prop
    settings:
      prop_field_definitions:
        # ...
```

### Instance Storage

Component instances live in the `canvas_page__components` table:
- `components_component_id` - which component (e.g., `sdc.mytheme.section`)
- `components_component_version` - pinned version hash
- `components_inputs` - JSON blob of prop values
- `components_uuid` - unique instance identifier
- Revision data in `canvas_page_revision__components`

## Drush Commands

```bash
# Clear cache after component changes
ddev drush cr

# List all SDC components
ddev drush ev "print_r(array_keys(\Drupal::service('plugin.manager.sdc')->getDefinitions()));"

# Canvas component version management (project-custom commands, not shipped by Canvas; see above)
ddev drush canvas:upgrade-instances          # List outdated
ddev drush canvas:upgrade-instances --all    # Migrate all
ddev drush canvas:component-info             # Show all components
ddev drush canvas:component-info <id>        # Show specific component
```
