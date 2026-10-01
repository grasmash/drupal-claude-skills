---
name: drupal-simple-oauth
description: Explains OAuth2 authentication in Drupal with the simple_oauth module - TokenAuthUser AND-permission logic, scope/role intersection, OAuth2 scope entities and the dynamic scope provider, mobile app password-grant token requests, field_permissions and JSON:API field access under a token, Bearer-token CSRF 403s, consumer TTLs, and debugging token permission denials. Use when an OAuth/Bearer token is denied a permission the user has, configuring consumers, clients or scopes, requesting tokens from a mobile or decoupled app, or getting 403s on JSON:API requests made with a Bearer token.
---

# Drupal Simple OAuth Patterns

Comprehensive patterns for working with the simple_oauth module for OAuth2 authentication in Drupal. Use when working with API authentication, mobile app tokens, or OAuth2 implementation.

## Version Information

- Verified against simple_oauth 6.1.1 (consumers 8.x-1.24); line numbers below refer to that release
- Scope provider: dynamic (role-based granularity)
- Current Drupal: 10.x/11.x compatible

## Critical OAuth Token Concepts

### TokenAuthUser: The Core Authentication Wrapper

When a request is authenticated with an OAuth token, Drupal wraps the user in a `TokenAuthUser` decorator that enforces BOTH token AND user permissions.

**Location:** `<webroot>/modules/contrib/simple_oauth/src/Authentication/TokenAuthUser.php` (`<webroot>` is `web/` or `docroot/` depending on the project)

#### Permission Check Logic (Line 95)

```php
public function hasPermission($permission) {
  // User #1 has all permissions.
  if ((int) $this->id() === 1) {
    return TRUE;
  }

  return $this->token->hasPermission($permission) && $this->subject->hasPermission($permission);
}
```

**Critical Rule:** BOTH the token AND the user must have the permission (AND condition).

#### Role Intersection Logic (Line 107)

```php
public function getRoles($exclude_locked_roles = FALSE) {
  $default_roles = [];
  if (!$exclude_locked_roles) {
    $default_roles[] = $this->isAuthenticated() ? self::AUTHENTICATED_ROLE : self::ANONYMOUS_ROLE;
  }

  $token_roles = array_unique(array_merge($this->token->getRoles($exclude_locked_roles), $default_roles));
  $user_roles = $this->subject->getRoles($exclude_locked_roles);
  return array_intersect($token_roles, $user_roles);
}
```

**Critical Rule:** Only roles that exist in BOTH the token AND the user are granted (`array_intersect`).

### The Scope/Role Matching Requirement

For an OAuth token to grant a permission:

1. The user MUST have a role with that permission
2. The token request MUST include a scope matching that role
3. An OAuth2 scope entity MUST exist with that name

**If any condition fails, permission is DENIED.**

## Common Pitfalls

### Pitfall 1: Scope/Role Mismatch

**Problem:**
```php
// User has: administrator role
// Token requested with: scope=api_consumer
// Result: Only 'authenticated' role granted (intersection)
// Permissions from administrator: DENIED
```

**Why it fails:**
```php
$token_roles = ['authenticated', 'api_consumer'];  // From scope
$user_roles = ['authenticated', 'administrator']; // From user
$granted = array_intersect($token_roles, $user_roles);   // ['authenticated']
```

**Solution:** Request token with correct scope:
```javascript
formData.append('scope', 'administrator');
```

### Pitfall 2: Non-existent Scope Entity

**Problem:**
```javascript
// Mobile app requests: scope=subscriber
// But no "subscriber" OAuth2 scope entity exists
// Result: Token has NO scopes, NO roles, NO permissions
```

**Solution:** Create the OAuth2 scope entity or use existing scope name.

**Check existing scopes:**
```bash
ddev drush config:get simple_oauth.settings
# Or list scope entities (config entities named simple_oauth.oauth2_scope.<id>)
ddev drush sqlq "SELECT name FROM config WHERE name LIKE 'simple_oauth.oauth2_scope.%' ORDER BY name"
```

### Pitfall 3: Authenticated Role Permissions

**Problem:** Assuming authenticated role permissions are always granted.

**Reality:** Only if the token includes the authenticated role in its scope intersection.

**From `src/Plugin/ScopeGranularity/Role.php` (line 95):**
```php
// Scopes automatically grant authenticated role
return $exclude_locked_roles ? [$role] : [AccountInterface::AUTHENTICATED_ROLE, $role];
```

This was fixed in issue #3451692 (included in 6.0.x).

## Integration with Other Modules

### field_permissions Module

**How it works:**
```php
// field_permissions.module (line 34)
function field_permissions_entity_field_access($operation, FieldDefinitionInterface $field_definition, $account, FieldItemListInterface $items = NULL) {
  // ...
  $access_field = \Drupal::service('field_permissions.permissions_service')
    ->getFieldAccess($operation, $items, $account, $field_definition);
  // ...
}

// CustomAccess.php (line 36)
public function hasFieldAccess($operation, EntityInterface $entity, AccountInterface $account) {
  // Calls $account->hasPermission()
  // If $account is TokenAuthUser, uses the AND logic!
  return $account->hasPermission($operation . ' ' . $field_name);
}
```

**Result:** field_permissions works correctly with simple_oauth when scopes match roles.

### JSON:API Module

JSON:API respects all field-level access checks, including field_permissions. When using OAuth tokens:

1. JSON:API calls `entity_field_access` hooks
2. field_permissions checks `$account->hasPermission()`
3. If `$account` is TokenAuthUser, both token AND user must have permission
4. If either fails, field is excluded from JSON:API response

**No special configuration needed** - it works automatically when scopes are correct.

## OAuth Client Configuration

### Mobile App Client Configuration

When configuring a mobile or decoupled app as an OAuth client, the token request follows this pattern:

```javascript
const formData = new FormData();
formData.append('client_id', clientId);
formData.append('client_secret', clientSecret);
formData.append('scope', scope); // MUST match user's role!
formData.append('grant_type', 'password');
formData.append('username', username);
formData.append('password', password);
```

Store `client_id` and `client_secret` securely in your app configuration (e.g., environment variables or a secure config context).

### Creating OAuth Clients

```bash
# simple_oauth ships no Drush command for creating clients (its only command is
# simple-oauth:generate-keys). Clients are `consumer` content entities:
# Via UI: /admin/config/services/consumer/add

# Or via the entity API
ddev drush php:eval '\Drupal::entityTypeManager()->getStorage("consumer")->create([
  "label" => "Mobile App",
  "client_id" => "mobile_app",
  "secret" => "your-secret",
  "confidential" => TRUE,
  "grant_types" => ["password", "refresh_token"],
  "scopes" => ["authenticated"],
])->save();'
```

### Consumer TTLs and Social Login Audiences

- **Consumer token TTLs are content-entity data, not config.** `cim` never deploys them; change them in a `hook_update_N()` that loads the consumer by `client_id`.
- **A social/Google token grant must check `aud` against an allow-list.** Mobile apps mint tokens under their own client ids, so a single expected `aud` fails every app login closed.

Details and code: [references/consumer-ttls-and-social-grant.md](references/consumer-ttls-and-social-grant.md).

## Scope Entity Management

### Creating Scope Entities

```yaml
# Via config: config/install/simple_oauth.oauth2_scope.subscriber.yml
langcode: en
status: true
id: subscriber
name: subscriber
description: 'Subscriber role access'
grant_types:
  refresh_token:
    status: true
    description: ''
  password:            # provided by the simple_oauth_password_grant submodule
    status: true
    description: ''
umbrella: false
parent: _none
granularity_id: role
granularity_configuration:
  role: subscriber
```

### Dynamic Scope Provider Configuration

```yaml
# simple_oauth.settings.yml
scope_provider: 'dynamic'
```

With dynamic scope provider, scopes map directly to roles.

### Listing Scopes

```bash
# Via SQL (scopes are config entities, stored in the config table)
ddev drush sqlq "SELECT name FROM config WHERE name LIKE 'simple_oauth.oauth2_scope.%' ORDER BY name"

# Via config
ddev drush config:get simple_oauth.oauth2_scope.subscriber
```

## Best Practices

### 1. Match Scopes to User Roles

**DO:**
```javascript
// Check user's roles, request matching scope
if (userHasRole('administrator')) {
  scope = 'administrator';
} else if (userHasRole('premium_user')) {
  scope = 'premium_user';
}
```

**DON'T:**
```javascript
// Hardcode scope that might not match user
scope = 'subscriber'; // What if user has different role?
```

### 2. Create Scope Entities for All API Roles

Ensure every role that needs API access has a corresponding scope entity.

### 3. Request Multiple Scopes (if needed)

OAuth2 supports space-separated scopes:
```javascript
formData.append('scope', 'premium_user api_consumer');
```

The token will include all scopes that match the user's roles.

### 4. Use Specific Permissions

Instead of broad permissions, use field-specific permissions:
```php
// Good: Granular field control
'view field_premium_content'
'edit field_premium_content'

// Less secure: Too broad
'administer nodes'
```

### 5. Test with Non-Admin Users

Admin users (uid=1) bypass all permission checks:
```php
if ((int) $this->id() === 1) {
  return TRUE; // Admin bypass!
}
```

Always test OAuth with regular users.

## Troubleshooting Checklist

When OAuth permissions fail:

- [ ] Does the OAuth2 scope entity exist?
  - `ddev drush config:get simple_oauth.oauth2_scope.SCOPE_NAME`
- [ ] Does the user have the required role?
  - `ddev drush user:role:list username@example.com`
- [ ] Does the role have the required permission?
  - `ddev drush role:perm:list ROLE_NAME | grep PERMISSION`
- [ ] Does the token request include the correct scope?
  - Check mobile app code or API client configuration
- [ ] Is the scope in the token request matching the user's role?
  - This is the most common issue!
- [ ] Are you testing with uid=1? (Don't - use regular user)
- [ ] Is simple_oauth scope provider set to "dynamic"?
  - `ddev drush config:get simple_oauth.settings scope_provider`

## References

| File | Read it when |
|---|---|
| [references/debugging-tokens.md](references/debugging-tokens.md) | A token is denied a permission and the Troubleshooting Checklist above did not explain it: step-by-step checks of scope entities, user roles and role permissions, a PHP script that mints a test token and prints token/user/intersected roles, and a curl script that exercises a real API request |
| [references/bearer-csrf-bypass.md](references/bearer-csrf-bypass.md) | Requests carrying a valid Bearer token get 403 CSRF errors because the client also sends a session cookie (React Native, webviews): the `session_configuration` decorator, its service definition and how to test it |
| [references/consumer-ttls-and-social-grant.md](references/consumer-ttls-and-social-grant.md) | Changing consumer access/refresh token TTLs (content entities, so `cim` never deploys them), or writing a social/Google token grant that must check `aud` against an allow-list |

## Related Documentation

- **Drupal.org Issue #3451692:** "Dynamic scope with role granularity does not inherit authenticated permissions" (Fixed in 6.0.x)

## Common Commands

```bash
# List OAuth clients
ddev drush sqlq "SELECT label, client_id FROM consumer_field_data"

# List OAuth scopes
ddev drush sqlq "SELECT name FROM config WHERE name LIKE 'simple_oauth.oauth2_scope.%' ORDER BY name"

# List each client's default scopes (multi-value consumer base field `scopes`)
ddev drush php:eval 'foreach (\Drupal::entityTypeManager()->getStorage("consumer")->loadMultiple() as $c) { print $c->label() . ": " . implode(", ", array_column($c->get("scopes")->getValue(), "scope_id")) . PHP_EOL; }'

# Check user roles
ddev drush user:role:list username@example.com

# Add role to user
ddev drush user:role:add ROLE_NAME username

# Check role permissions
ddev drush role:perm:list ROLE_NAME

# View OAuth settings
ddev drush config:get simple_oauth.settings

# Test token endpoint
curl -X POST "https://yoursite.ddev.site/oauth/token" \
  -d "grant_type=password" \
  -d "client_id=CLIENT_ID" \
  -d "client_secret=SECRET" \
  -d "username=user@example.com" \
  -d "password=pass123" \
  -d "scope=SCOPE_NAME"
```

## Key Files Reference

- `TokenAuthUser.php` - Core authentication wrapper with AND permission logic
- `Role.php` - Dynamic scope to role mapping (line 95: authenticated role grant)
- `field_permissions.module` - Field access hook (line 34)
- `CustomAccess.php` - Field permission type (line 36: hasPermission call)
- `src/Session/BearerSessionConfiguration.php` - CSRF bypass decorator for Bearer tokens (custom module)
