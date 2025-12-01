# Vue Drupal Security Audit - Examples

This document provides examples of how the Vue Drupal Security Audit skill identifies and remediates security vulnerabilities.

## Example 1: XSS Vulnerability Detection

### Vulnerable Code

```vue
<template>
  <div>
    <h2>{{ article.title }}</h2>
    <!-- DANGEROUS: Unescaped HTML from API -->
    <div v-html="article.body"></div>
    
    <!-- DANGEROUS: User-provided URL -->
    <a :href="article.authorUrl">View Profile</a>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const article = ref({})

onMounted(async () => {
  const response = await fetch('/api/article/1')
  article.value = await response.json()
})
</script>
```

### Security Issues Identified

1. **Critical**: Unescaped `v-html` allows XSS attacks
2. **High**: URL binding without validation (javascript: protocol injection)
3. **Medium**: No API response validation

### Secure Version

```vue
<template>
  <div>
    <h2>{{ article.title }}</h2>
    <!-- SAFE: Sanitized HTML -->
    <div v-html="sanitizedBody"></div>
    
    <!-- SAFE: Validated URL -->
    <a :href="safeUrl">View Profile</a>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import DOMPurify from 'dompurify'

const article = ref({})

const sanitizedBody = computed(() => {
  if (!article.value.body) return ''
  return DOMPurify.sanitize(article.value.body, {
    ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'a'],
    ALLOWED_ATTR: ['href']
  })
})

const safeUrl = computed(() => {
  const url = article.value.authorUrl
  if (!url) return '#'
  
  // Only allow http/https protocols
  try {
    const parsed = new URL(url)
    if (parsed.protocol === 'http:' || parsed.protocol === 'https:') {
      return url
    }
  } catch (e) {
    // Invalid URL
  }
  return '#'
})

onMounted(async () => {
  const response = await fetch('/api/article/1')
  
  if (!response.ok) {
    throw new Error('Failed to load article')
  }
  
  const data = await response.json()
  
  // Validate response structure
  if (data && data.id && data.title) {
    article.value = data
  }
})
</script>
```

---

## Example 2: Insecure API Communication

### Vulnerable Code

```vue
<script setup>
import { ref } from 'vue'

const deleteNode = async (node_id) => {
  // DANGEROUS: No CSRF protection
  // DANGEROUS: No error handling
  await fetch(`/node/${node_id}/delete`, {
    method: 'POST'
  })

  alert('Node deleted!') // Information disclosure
}

const loadUserData = async () => {
  const response = await fetch('/api/user/me')
  const user = await response.json()
  
  // DANGEROUS: Storing sensitive data
  localStorage.setItem('user', JSON.stringify(user))
}
</script>
```

### Security Issues Identified

1. **Critical**: Missing CSRF token on mutating operation
2. **High**: No authentication check
3. **High**: Sensitive data in localStorage (XSS accessible)
4. **Medium**: No error handling or validation
5. **Low**: Information disclosure via alerts

### Secure Version

```vue
<script setup>
import { ref } from 'vue'
import { useDrupalApi } from '@/composables/useDrupalApi'

const { apiRequest, isAuthenticated } = useDrupalApi()
const error = ref(null)

const deleteNode = async (node_id) => {
  if (!isAuthenticated.value) {
    error.value = 'Not authenticated'
    return
  }

  // Validate node ID
  if (!Number.isInteger(node_id) || node_id < 1) {
    error.value = 'Invalid node ID'
    return
  }

  try {
    // SAFE: Includes CSRF token, credentials
    const response = await apiRequest(`/node/${node_id}/delete`, {
      method: 'POST'
    })
    
    if (!response.ok) {
      throw new Error('Delete failed')
    }
    
    // Success - don't expose details
    return true
  } catch (err) {
    error.value = 'Failed to delete content'
    console.error('Delete error:', err) // Log for debugging, not user
    return false
  }
}

const loadUserData = async () => {
  try {
    const response = await apiRequest('/api/user/me', {
      method: 'GET'
    })
    
    if (!response.ok) {
      throw new Error('Failed to load user')
    }
    
    const user = await response.json()
    
    // SAFE: Only store non-sensitive, public data in session
    sessionStorage.setItem('userPrefs', JSON.stringify({
      theme: user.preferences?.theme || 'light',
      language: user.language || 'en'
    }))
    
    // NEVER store: passwords, tokens, emails, private data
    return user
  } catch (err) {
    error.value = 'Failed to load user data'
    throw err
  }
}
</script>
```

---

## Example 3: Insecure State Management

### Vulnerable Code

```javascript
// stores/auth.js
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // DANGEROUS: Storing passwords
  const user = ref({
    id: 1,
    username: 'admin',
    password: 'secret123',
    apiKey: 'sk_live_abc123',
    permissions: ['delete', 'edit', 'create']
  })
  
  // DANGEROUS: Directly mutable
  return { user }
})
```

### Security Issues Identified

1. **Critical**: Password stored in frontend state
2. **Critical**: API key exposed in frontend
3. **High**: Permissions in client-side (trust boundary violation)
4. **High**: State directly mutable (no validation)

### Secure Version

```javascript
// stores/auth.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // Private state
  const _userData = ref(null)
  const _roles = ref([])
  
  // Public computed (read-only)
  const user = computed(() => {
    if (!_userData.value) return null
    
    // Return only safe data
    return {
      id: _userData.value.id,
      username: _userData.value.username,
      displayName: _userData.value.displayName
    }
  })
  
  const roles = computed(() => [..._roles.value])
  
  const isAuthenticated = computed(() => !!_userData.value)
  
  // Validated setters
  const setUser = (userData) => {
    if (!userData || !userData.id) {
      throw new Error('Invalid user data')
    }
    
    // Remove any sensitive fields
    const { password, password_hash, api_key, token, ...safeData } = userData
    
    _userData.value = safeData
  }
  
  const setRoles = (roles) => {
    if (!Array.isArray(roles)) {
      throw new Error('Roles must be an array')
    }
    
    _roles.value = roles.filter(r => typeof r === 'string')
  }
  
  const hasRole = (role) => {
    // Client-side check for UI only
    // Server MUST validate
    return _roles.value.includes(role)
  }
  
  const logout = () => {
    _userData.value = null
    _roles.value = []
    sessionStorage.clear()
  }
  
  return {
    // Only expose what's needed
    user,
    roles,
    isAuthenticated,
    hasRole,
    setUser,
    setRoles,
    logout
  }
})
```

---

## Example 4: Insecure Drupal Integration

### Vulnerable Code

```php
<?php
// mytheme.theme

function mytheme_preprocess_page(&$variables) {
  $user = \Drupal::currentUser();
  $full_user = User::load($user->id());
  
  // DANGEROUS: Exposing everything to JavaScript
  $variables['#attached']['drupalSettings']['currentUser'] = [
    'user_id' => $user->id(),
    'name' => $user->getAccountName(),
    'email' => $user->getEmail(), // SENSITIVE!
    'password' => $full_user->getPassword(), // NEVER!
    'api_key' => $full_user->get('field_api_key')->value, // SECRET!
    'roles' => $user->getRoles(),
    'permissions' => array_keys($user->getPermissions()), // DANGEROUS!
  ];
}
```

```vue
<template>
  <div>
    <p>Welcome {{ user.name }}</p>
    <p>Email: {{ user.email }}</p>
    <!-- Trusting client-side permissions -->
    <button v-if="canDelete" @click="deleteContent">Delete</button>
  </div>
</template>

<script setup>
const user = drupalSettings.currentUser
const canDelete = user.permissions.includes('delete content')
</script>
```

### Security Issues Identified

1. **Critical**: Password hash exposed to frontend
2. **Critical**: API key exposed to frontend
3. **High**: Email address in JavaScript (privacy issue)
4. **High**: Permissions in client-side (authorization bypass)
5. **Medium**: Trusting client-side permission checks

### Secure Version

```php
<?php
// mytheme.theme

function mytheme_preprocess_page(&$variables) {
  $current_user = \Drupal::currentUser();
  
  // Only expose necessary, safe data
  $variables['#attached']['drupalSettings']['mytheme'] = [
    'user_id' => (int) $current_user->id(),
    'userName' => $current_user->getAccountName(),
    'userRoles' => $current_user->getRoles(), // Role IDs only, not permissions
    'isAuthenticated' => $current_user->isAuthenticated(),
    'csrfToken' => \Drupal::csrfToken()->get('rest'),
    'apiEndpoint' => \Drupal::url('mytheme.api'),
  ];
  
  // Never expose:
  // - Passwords or password hashes
  // - Email addresses (unless necessary for specific feature)
  // - API keys or tokens
  // - Permissions (server validates)
  // - Private user fields
}
```

```php
<?php
// src/Controller/ContentController.php

namespace Drupal\mytheme\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;

class ContentController extends ControllerBase {
  
  public function deleteContent(Request $request, $nid) {
    // Verify CSRF token
    $token = $request->headers->get('X-CSRF-Token');
    if (!$this->csrfToken()->validate($token, 'rest')) {
      return new JsonResponse(['error' => 'Invalid token'], 403);
    }

    // Load and check access (server-side)
    $node = \Drupal::entityTypeManager()
      ->getStorage('node')
      ->load($nid);
    
    if (!$node) {
      return new JsonResponse(['error' => 'Not found'], 404);
    }
    
    // Drupal handles permission checking
    if (!$node->access('delete')) {
      return new JsonResponse(['error' => 'Access denied'], 403);
    }
    
    $node->delete();
    
    return new JsonResponse(['success' => true]);
  }
}
```

```vue
<template>
  <div>
    <p>Welcome {{ userName }}</p>
    <!-- UI hint only, server validates -->
    <button v-if="isAuthenticated" @click="deleteContent">Delete</button>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDrupalApi } from '@/composables/useDrupalApi'

const { apiRequest, isAuthenticated } = useDrupalApi()

const config = drupalSettings.mytheme
const userName = config?.userName || 'Guest'

const deleteContent = async () => {
  if (!isAuthenticated.value) {
    alert('Please log in')
    return
  }
  
  try {
    // Server validates CSRF token and permissions
    const response = await apiRequest('/api/content/delete/{nid}', {
      method: 'POST'
    })
    
    if (!response.ok) {
      throw new Error('Delete failed')
    }
    
    // Success
  } catch (error) {
    console.error('Delete error:', error)
    alert('Failed to delete content')
  }
}
</script>
```

---

## Example 5: Build Security Issues

### Vulnerable Configuration

```javascript
// vite.config.js - INSECURE
export default defineConfig({
  build: {
    sourcemap: true, // Exposes source code!
    minify: false, // No obfuscation!
  },
  
  define: {
    API_KEY: JSON.stringify('sk_live_abc123'), // Hardcoded secret!
    BACKEND_URL: JSON.stringify('https://api.internal.company.com') // Internal URL exposed!
  }
})
```

### Security Issues Identified

1. **Critical**: API keys in build configuration
2. **High**: Source maps enabled in production
3. **High**: Internal URLs exposed
4. **Medium**: No minification (easier to reverse engineer)

### Secure Configuration

```javascript
// vite.config.js - SECURE
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ mode }) => {
  const isDev = mode === 'development'
  
  return {
    plugins: [vue()],
    
    build: {
      // No source maps in production
      sourcemap: isDev,
      
      // Minify in production
      minify: isDev ? false : 'terser',
      
      terserOptions: {
        compress: {
          drop_console: !isDev,
          drop_debugger: true
        }
      },
      
      rollupOptions: {
        output: {
          // Hash filenames
          entryFileNames: 'js/[name].[hash].js',
          chunkFileNames: 'js/[name].[hash].js',
        }
      }
    },
    
    // Only expose safe, public config
    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version)
      // Never expose secrets here!
    }
  }
})
```

```bash
# .env (not committed)
VITE_API_URL=https://api.example.com

# .env.example (committed as template)
VITE_API_URL=http://localhost:8080
```

```javascript
// Use environment variables safely
const apiUrl = import.meta.env.VITE_API_URL

if (!apiUrl) {
  throw new Error('VITE_API_URL not configured')
}
```

---

## Running Security Audits

### Automated Checks

```bash
# Check for vulnerabilities in dependencies
npm audit --audit-level=moderate

# Fix automatically when possible
npm audit fix

# Check build output
npm run build
ls -la dist/js/*.map  # Should be empty in production

# Search for common issues
grep -r "v-html" src/
grep -r "console.log" dist/
grep -r "password" src/
```

### Manual Review Checklist

- [ ] No `v-html` without sanitization
- [ ] All API calls include CSRF tokens
- [ ] No sensitive data in localStorage
- [ ] Props validated on all components
- [ ] Server validates all permissions
- [ ] Source maps disabled in production
- [ ] No secrets in code or config
- [ ] Dependencies up to date
- [ ] Error messages don't expose internals

---

These examples demonstrate the type of security issues the Vue Drupal Security Audit skill can identify and how to remediate them properly.

