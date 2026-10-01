# Troubleshooting: Component Version Mismatches (500 Errors)

Diagnosing and recovering from the "is not a prop on this version of the Component" 500 error. `canvas:upgrade-instances` and `canvas:component-info` below are project-custom Drush commands, not shipped by Canvas; see [component-versioning.md](component-versioning.md).

### Symptom

Canvas editor throws 500: `'propName' is not a prop on this version of the Component 'Code component: ComponentName'`

### Root Cause

The Canvas component entity's `active_version` was generated from an older build of the component that didn't include the prop. The source `component.yml` has the prop, but the deployed Canvas entity doesn't.

**Key distinction by component type:**
- **SDC components** (`sdc.*`): Canvas regenerates versions on `drush cr` from the source `component.yml`
- **JS code components** (`js.*`): Canvas versions are set when the component is **uploaded** via CLI. `drush cr` alone does NOT update them.

### Recovery Steps

#### For JS Code Components (`js.*`)

```bash
# 1. Re-upload the component to generate a new version from source component.yml
npx canvas upload --components container -y

# 2. Upgrade existing instances to the new active version
ddev drush canvas:upgrade-instances js.container -y

# 3. Verify
ddev drush canvas:component-info js.container
```

The upload command is configured via `.env` in the canvas-components project:
- `CANVAS_SITE_URL=http://example.ddev.site`
- `CANVAS_CLIENT_ID=canvas_cli`
- `CANVAS_CLIENT_SECRET=<your-client-secret>`

#### For SDC Components (`sdc.*`)

```bash
# 1. Clear cache to trigger re-discovery from source
ddev drush cr

# 2. Upgrade existing instances
ddev drush canvas:upgrade-instances sdc.mytheme.component-name -y

# 3. Export only the updated config entity (use your config sync directory)
ddev drush config:get canvas.component.sdc.mytheme.component-name --format=yaml \
  > config/sync/canvas.component.sdc.mytheme.component-name.yml
```

### Diagnosis Commands

```bash
# Check what props the active version has
ddev drush ev "\$c = \Drupal::entityTypeManager()->getStorage('component')->load('js.container'); echo implode(', ', array_keys(\$c->get('versioned_properties')['active']['settings']['prop_field_definitions'] ?? []));"

# Check what version/inputs an instance has on a specific page
ddev drush ev "\$p = \Drupal::entityTypeManager()->getStorage('canvas_page')->load(6); foreach (\$p->toArray()['components'] ?? [] as \$c) { if (\$c['component_id'] === 'js.container') echo \$c['component_version'] . ': ' . \$c['inputs']; }"

# Compare: does the instance version match the active version?
ddev drush canvas:upgrade-instances  # Lists all mismatches
```

### Stale Auto-Saves

Canvas auto-saves can reference old component versions. If a 500 persists after upgrading instances, check for and delete stale auto-saves:

```bash
# Check pending auto-saves
curl -s -b /tmp/cookies.txt "https://example.ddev.site/canvas/api/v0/auto-saves/pending"

# Delete a stale auto-save (need CSRF token)
CSRF=$(curl -s -b /tmp/cookies.txt "https://example.ddev.site/session/token")
curl -s -b /tmp/cookies.txt -X DELETE -H "X-CSRF-Token: $CSRF" \
  "https://example.ddev.site/canvas/api/v0/auto-saves/canvas_page/{PAGE_ID}"
```

### Prevention

After modifying any component's `component.yml` props:
1. **JS components**: `npx canvas upload --components <name> -y`
2. **SDC components**: `ddev drush cr`
3. **Always**: `ddev drush canvas:upgrade-instances` to check for stale instances
4. **Always**: Test the Canvas editor page before pushing
