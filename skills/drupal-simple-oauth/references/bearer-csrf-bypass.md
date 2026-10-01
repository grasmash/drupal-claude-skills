# Bearer CSRF Bypass Module

Avoiding false CSRF 403s when a request carries both a Bearer token and a session cookie, moved from SKILL.md.

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
