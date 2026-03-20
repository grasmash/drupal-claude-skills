---
name: drupal-simple-oauth
description: OAuth2 authentication patterns for Drupal using simple_oauth module. Covers TokenAuthUser permission logic, scope/role matching, mobile app token flows, field_permissions integration, CSRF bypass, and debugging token issues.
---

# Drupal Simple OAuth Patterns

Comprehensive patterns for working with the simple_oauth module for OAuth2 authentication in Drupal. Use when working with API authentication, mobile app tokens, or OAuth2 implementation.

## Version Information

- simple_oauth: 6.0.9
- Scope provider: dynamic (role-based granularity)
- Current Drupal: 10.x/11.x compatible

## Critical OAuth Token Concepts

### TokenAuthUser: The Core Authentication Wrapper

When a request is authenticated with an OAuth token, Drupal wraps the user in a `TokenAuthUser` decorator that enforces BOTH token AND user permissions.

**Location:** `/docroot/modules/contrib/simple_oauth/src/Authentication/TokenAuthUser.php`

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

#### Role Intersection Logic (Line 109)

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
# Or query scope entities
ddev drush sqlq "SELECT id FROM consumer_scopes"
```

### Pitfall 3: Authenticated Role Permissions

**Problem:** Assuming authenticated role permissions are always granted.

**Reality:** Only if the token includes the authenticated role in its scope intersection.

**From Role.php (line 94):**
```php
// Scopes automatically grant authenticated role
return $exclude_locked_roles ? [$role] : [AccountInterface::AUTHENTICATED_ROLE, $role];
```

This was fixed in issue #3451692 (included in 6.0.x).

## Debugging OAuth Permission Issues

### Step 1: Verify Scope Entity Exists

```bash
# List all OAuth2 scopes
ddev drush sqlq "SELECT id, description FROM consumer_scopes"

# Example scopes you might have:
# - authenticated
# - api_consumer
# - premium_user
# - administrator
```

### Step 2: Check User Roles

```bash
ddev drush user:role:list username@example.com
```

### Step 3: Verify Role Permissions

```bash
# Check if role has the permission
ddev drush role:perm:list api_consumer | grep "view field_premium_content"
```

### Step 4: Test Token Creation

```php
// Create test script: test_oauth_token.php
use Drupal\simple_oauth\Entity\Oauth2Token;

$username = 'test_user';
$scope = 'premium_user'; // Match user's role!

// Get user
$user = user_load_by_name($username);
$consumer = \Drupal::entityTypeManager()
  ->getStorage('consumer')
  ->loadByProperties(['label' => 'Mobile App']);
$consumer = reset($consumer);

// Create token
$token = Oauth2Token::create([
  'auth_user_id' => $user->id(),
  'client' => $consumer->id(),
  'bundle' => 'access_token',
  'scopes' => $scope,
  'value' => bin2hex(random_bytes(32)),
  'expire' => time() + 3600,
  'status' => TRUE,
]);
$token->save();

// Wrap user with token context
$token_user = new \Drupal\simple_oauth\Authentication\TokenAuthUser($token);

// Test permissions
$permission = 'view field_premium_content';
$token_has = $token->hasPermission($permission);
$user_has = $user->hasPermission($permission);
$token_user_has = $token_user->hasPermission($permission);

print "Token roles: " . implode(', ', $token->getRoles()) . "\n";
print "User roles: " . implode(', ', $user->getRoles()) . "\n";
print "Intersected roles: " . implode(', ', $token_user->getRoles()) . "\n";
print "Token has permission: " . ($token_has ? 'YES' : 'NO') . "\n";
print "User has permission: " . ($user_has ? 'YES' : 'NO') . "\n";
print "TokenAuthUser has permission: " . ($token_user_has ? 'YES' : 'NO') . "\n";
```

Run with: `ddev drush php:script test_oauth_token.php`

### Step 5: Test API Request

```bash
#!/bin/bash
# Get OAuth token
TOKEN_RESPONSE=$(curl -s -X POST "https://yoursite.ddev.site/oauth/token" \
  -d "grant_type=password" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "username=test@example.com" \
  -d "password=password123" \
  -d "scope=premium_user")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

# Test API request
curl -s -X GET "https://yoursite.ddev.site/jsonapi/node/article/2" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/vnd.api+json" | python3 -m json.tool
```

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
# Via Drush
ddev drush simple-oauth:create-client \
  --label="Mobile App" \
  --secret="your-secret" \
  --confidential \
  --user-id=1

# Or via UI: /admin/config/people/simple_oauth
```

## Scope Entity Management

### Creating Scope Entities

```yaml
# Via config: config/install/consumer.oauth2_scope.subscriber.yml
uuid: YOUR-UUID
langcode: en
status: true
id: subscriber
description: 'Subscriber role access'
grant_user_permissions: true
umbrella: false
granularity: role
parent: null
```

### Dynamic Scope Provider Configuration

```yaml
# simple_oauth.settings.yml
scope_provider: 'dynamic'
```

With dynamic scope provider, scopes map directly to roles.

### Listing Scopes

```bash
# Via SQL
ddev drush sqlq "SELECT id, description FROM consumer_scopes ORDER BY id"

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
  - `ddev drush sqlq "SELECT id FROM consumer_scopes WHERE id='SCOPE_NAME'"`
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

## Related Documentation

- **Drupal.org Issue #3451692:** "Dynamic scope with role granularity does not inherit authenticated permissions" (Fixed in 6.0.x)

## Common Commands

```bash
# List OAuth clients
ddev drush sqlq "SELECT label, uuid FROM consumer"

# List OAuth scopes
ddev drush sqlq "SELECT id, description FROM consumer_scopes"

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

## Bearer CSRF Bypass Module

### The Problem: CSRF Validation with Bearer Tokens

When a client (especially React Native apps) sends a request with BOTH a valid Bearer token AND a session cookie, Drupal's `CsrfRequestHeaderAccessCheck` incorrectly triggers CSRF validation. This happens because:

1. Drupal's `session_configuration` service detects a session based on cookies alone
2. It ignores the Bearer token completely
3. This causes 403 Forbidden errors even though the Bearer token is valid

**Drupal core issue:** [#3055260](https://www.drupal.org/project/drupal/issues/3055260)

### The Solution: Custom CSRF Bypass Module

Create a custom module (e.g., `oauth_csrf_bypass`) that decorates the `session_configuration` service to return `FALSE` for `hasSession()` when a valid Bearer token is present, preventing unnecessary CSRF checks.

**Location:** `docroot/modules/custom/{module_name}/`

### How It Works

```php
// src/Session/BearerSessionConfiguration.php
public function hasSession(Request $request): bool {
  $auth_header = $request->headers->get('Authorization', '');

  if (str_starts_with($auth_header, 'Bearer ')) {
    // Validate the token is actually legitimate
    if ($this->isValidBearerToken($request)) {
      return FALSE; // No session = no CSRF check
    }
  }

  return $this->inner->hasSession($request);
}
```

**Security:** The module validates the Bearer token using Simple OAuth's ResourceServer before bypassing CSRF, ensuring invalid tokens don't bypass security.

### Service Definition

```yaml
# {module_name}.services.yml
services:
  {module_name}.session_configuration:
    class: Drupal\{module_name}\Session\BearerSessionConfiguration
    decorates: session_configuration
    decoration_priority: 10
    arguments:
      - '@{module_name}.session_configuration.inner'
      - '@simple_oauth.server.resource_server.factory'
      - '@psr7.http_message_factory'
```

### When You Need This

Enable this module when:
- Mobile apps send Bearer tokens but browsers/webviews also set session cookies
- You get 403 CSRF errors despite having valid Bearer tokens
- React Native or similar hybrid apps have authentication issues

### Testing the Fix

```bash
# Test with Bearer token only - should succeed
curl -X GET "https://yoursite.ddev.site/jsonapi" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/vnd.api+json"

# Test with Bearer + session cookie (the bug scenario) - should also succeed
curl -X GET "https://yoursite.ddev.site/jsonapi" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Cookie: SESSxxxxxxxxxx=fake_session_value" \
  -H "Accept: application/vnd.api+json"
```

### Module Dependencies

- `simple_oauth:simple_oauth` - Required for ResourceServer token validation

## Key Files Reference

- `TokenAuthUser.php` - Core authentication wrapper with AND permission logic
- `Role.php` - Dynamic scope to role mapping (line 94: authenticated role grant)
- `field_permissions.module` - Field access hook (line 34)
- `CustomAccess.php` - Field permission type (line 36: hasPermission call)
- `src/Session/BearerSessionConfiguration.php` - CSRF bypass decorator for Bearer tokens (custom module)
