# Debugging OAuth Permission Issues

Step-by-step token and permission debugging, moved from SKILL.md.

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
