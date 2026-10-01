# Authenticated cURL Request Examples

This document provides examples of making authenticated HTTP requests to custom Drupal API endpoints using cURL, including how to obtain and use session tokens.

## Getting a Session Token

To make authenticated requests, you first need to obtain a session token by logging in:

```bash
# Login and capture session cookie
curl -c /tmp/cookies.txt \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"username","pass":"password"}' \
  https://<project>.ddev.site/user/login?_format=json
```

Or extract just the session name and value:

```bash
# Get session token (returns session_name=session_value)
SESSION=$(curl -s -c - \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"username","pass":"password"}' \
  https://<project>.ddev.site/user/login?_format=json \
  | grep -oP 'SSESS\w+\t\K\w+')

SESSION_NAME=$(curl -s -c - \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"username","pass":"password"}' \
  https://<project>.ddev.site/user/login?_format=json \
  | grep -oP 'SSESS\w+')

echo "Cookie: $SESSION_NAME=$SESSION"
```

## Using Drush for One-Time Login

For testing, the easiest way to get an authenticated session is with drush:

```bash
# Generate a one-time login link
ddev drush uli

# Use the link in a browser to authenticate, then copy cookies from browser dev tools
```

## Authenticated GET Request

```bash
# Using cookie file
curl -b /tmp/cookies.txt \
  -H "Content-Type: application/json" \
  https://<project>.ddev.site/my-module-api/status

# Using explicit cookie
curl -H "Cookie: SSESS1234567890abcdef=xyz123abc456" \
  -H "Content-Type: application/json" \
  https://<project>.ddev.site/my-module-api/status
```

## Authenticated POST Request

```bash
# Example: trigger a POST action
curl -b /tmp/cookies.txt \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"entity_uuid":"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}' \
  https://<project>.ddev.site/my-module-api/join

# Example: trigger another POST action
curl -b /tmp/cookies.txt \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{}' \
  https://<project>.ddev.site/my-module-api/a1b2c3d4-e5f6-7890-abcd-ef1234567890/action

# Example: trigger a third POST action
curl -b /tmp/cookies.txt \
  -X POST \
  -H "Content-Type: application/json" \
  https://<project>.ddev.site/my-module-api/status/123/accept
```

## Using CSRF Token for POST/PUT/DELETE

Some endpoints may require a CSRF token for state-changing operations:

```bash
# Get CSRF token
CSRF_TOKEN=$(curl -b /tmp/cookies.txt \
  https://<project>.ddev.site/session/token)

# Use CSRF token in request
curl -b /tmp/cookies.txt \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: $CSRF_TOKEN" \
  -d '{"field":"value"}' \
  https://<project>.ddev.site/some-api/endpoint
```

## Testing with JSON:API

For JSON:API endpoints (under `/jsonapi/`), use similar patterns:

```bash
# Get current user
curl -b /tmp/cookies.txt \
  -H "Content-Type: application/vnd.api+json" \
  -H "Accept: application/vnd.api+json" \
  https://<project>.ddev.site/jsonapi/user/user?filter[drupal_internal__uid]=1

# PATCH a node
curl -b /tmp/cookies.txt \
  -X PATCH \
  -H "Content-Type: application/vnd.api+json" \
  -H "Accept: application/vnd.api+json" \
  -H "X-CSRF-Token: $CSRF_TOKEN" \
  -d '{"data":{"type":"node--article","id":"UUID","attributes":{"title":"New Title"}}}' \
  https://<project>.ddev.site/jsonapi/node/article/UUID
```

## Complete Workflow Example

```bash
#!/bin/bash

# Configuration
BASE_URL="https://<project>.ddev.site"
USERNAME="testuser"
PASSWORD="testpass"
COOKIES="/tmp/cookies.txt"

# Step 1: Login and save cookies
echo "Logging in..."
curl -s -c "$COOKIES" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$USERNAME\",\"pass\":\"$PASSWORD\"}" \
  "$BASE_URL/user/login?_format=json" > /dev/null

# Step 2: Get CSRF token
echo "Getting CSRF token..."
CSRF_TOKEN=$(curl -s -b "$COOKIES" "$BASE_URL/session/token")

# Step 3: Make authenticated request
echo "Making API request..."
RESPONSE=$(curl -s -b "$COOKIES" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: $CSRF_TOKEN" \
  -d '{"entity_uuid":"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}' \
  "$BASE_URL/my-module-api/join")

echo "Response: $RESPONSE"

# Step 4: Logout (optional)
curl -s -b "$COOKIES" \
  -X POST \
  "$BASE_URL/user/logout?_format=json" > /dev/null

# Clean up
rm -f "$COOKIES"
```

## Debugging Tips

### View Response Headers
```bash
curl -i -b /tmp/cookies.txt \
  https://<project>.ddev.site/api/endpoint
```

### Verbose Output
```bash
curl -v -b /tmp/cookies.txt \
  https://<project>.ddev.site/api/endpoint
```

### Check Cookie Contents
```bash
cat /tmp/cookies.txt
```

### Test if Authenticated
```bash
# Should return current user info if authenticated
curl -b /tmp/cookies.txt \
  https://<project>.ddev.site/user/login_status?_format=json
```

## Security Notes

- **Never commit cookies or credentials to version control**
- Use environment variables for sensitive data in scripts
- Session cookies expire after inactivity
- HTTPS should always be used in production
- Cookie files should be stored securely with appropriate permissions (`chmod 600`)

## Common Response Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `204 No Content` - Successful request with no response body
- `400 Bad Request` - Invalid request payload
- `401 Unauthorized` - Not authenticated
- `403 Forbidden` - Authenticated but lacking permissions
- `404 Not Found` - Resource doesn't exist
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server-side error

## See Also

- Main skill documentation: `../SKILL.md`
- Drupal REST authentication: https://www.drupal.org/docs/core-modules-and-themes/core-modules/rest/3-authentication
