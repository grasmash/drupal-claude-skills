# Drupal API Integration Security

**OWASP Reference**: A07:2021 - Identification and Authentication Failures
**Severity**: Critical
**Target**: Vue components communicating with Drupal REST/JSON:API

## Overview

Securing API communication between Vue components and Drupal backends requires proper authentication, authorization, CSRF protection, and secure data handling.

---

## Authentication Patterns

### ✅ SAFE: CSRF Token Management

```javascript
// composables/useDrupalApi.js
import { ref } from 'vue'

export function useDrupalApi() {
  const csrfToken = ref(null)
  const isAuthenticated = ref(false)
  
  // Fetch CSRF token on app init
  const initAuth = async () => {
    try {
      const response = await fetch('/session/token', {
        credentials: 'include' // Include cookies
      })
      csrfToken.value = await response.text()
      isAuthenticated.value = true
    } catch (error) {
      console.error('Failed to fetch CSRF token:', error)
      isAuthenticated.value = false
    }
  }
  
  // Secure API request wrapper
  const apiRequest = async (url, options = {}) => {
    if (!csrfToken.value) {
      await initAuth()
    }
    
    const headers = {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken.value,
      ...options.headers
    }
    
    return fetch(url, {
      ...options,
      headers,
      credentials: 'include' // Always include credentials
    })
  }
  
  return {
    apiRequest,
    initAuth,
    isAuthenticated
  }
}
```

### ✅ SAFE: Authenticated API Calls

```vue
<script setup>
import { ref, onMounted } from 'vue'
import { useDrupalApi } from '@/composables/useDrupalApi'

const { apiRequest, initAuth, isAuthenticated } = useDrupalApi()
const data = ref(null)
const error = ref(null)

onMounted(async () => {
  await initAuth()
})

const fetchProtectedData = async () => {
  if (!isAuthenticated.value) {
    error.value = 'Not authenticated'
    return
  }
  
  try {
    const response = await apiRequest('/jsonapi/node/article', {
      method: 'GET'
    })
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }
    
    data.value = await response.json()
  } catch (err) {
    error.value = err.message
  }
}

const createNode = async (nodeData) => {
  try {
    const response = await apiRequest('/jsonapi/node/article', {
      method: 'POST',
      body: JSON.stringify({
        data: {
          type: 'node--article',
          attributes: {
            title: nodeData.title,
            body: {
              value: nodeData.body,
              format: 'basic_html' // Specify format
            }
          }
        }
      })
    })
    
    if (!response.ok) {
      throw new Error('Failed to create node')
    }
    
    return await response.json()
  } catch (err) {
    console.error('Create failed:', err)
    throw err
  }
}
</script>
```

---

## Anti-Patterns (Vulnerabilities)

### ❌ DANGEROUS: Missing CSRF Protection

```javascript
// VULNERABLE: No CSRF token
const deleteNode = async (node_id) => {
  await fetch(`/node/${node_id}/delete`, {
    method: 'POST'
    // Missing CSRF token!
  })
}
```

### ❌ DANGEROUS: Credentials in Code

```javascript
// VULNERABLE: Hardcoded credentials
const api = {
  username: 'admin',
  password: 'secret123',
  apiKey: 'abc123def456'
}

fetch('/api/data', {
  headers: {
    'Authorization': `Basic ${btoa(api.username + ':' + api.password)}`
  }
})
```

### ❌ DANGEROUS: Exposing Sensitive Data

```vue
<script setup>
// VULNERABLE: Full user object in frontend
const user = ref({
  id: 1,
  name: 'admin',
  email: 'admin@example.com',
  password_hash: 'hash...', // Should never be in frontend!
  api_key: 'secret', // Should never be exposed!
  permissions: [...] // Trusting client-side
})
</script>
```

### ❌ DANGEROUS: No Request Validation

```javascript
// VULNERABLE: No input validation before API call
const updateProfile = async (data) => {
  // Sending unvalidated user input
  await apiRequest('/user/1', {
    method: 'PATCH',
    body: JSON.stringify(data) // Could contain malicious data
  })
}
```

---

## JSON:API Secure Patterns

### ✅ SAFE: JSON:API Client with Validation

```javascript
// services/drupal-jsonapi.js
import { ref } from 'vue'

export class DrupalJsonApi {
  constructor(baseUrl = '') {
    this.baseUrl = baseUrl
    this.csrfToken = null
  }
  
  async init() {
    const response = await fetch('/session/token')
    this.csrfToken = await response.text()
  }
  
  validateJsonApiResponse(data) {
    if (!data || typeof data !== 'object') {
      throw new Error('Invalid JSON:API response')
    }
    
    if (!data.data && !data.errors) {
      throw new Error('Malformed JSON:API response')
    }
    
    return true
  }
  
  async get(path, params = {}) {
    const url = new URL(`${this.baseUrl}${path}`)
    
    // Validate params
    Object.keys(params).forEach(key => {
      if (typeof params[key] === 'string' || typeof params[key] === 'number') {
        url.searchParams.append(key, params[key])
      }
    })
    
    const response = await fetch(url.toString(), {
      headers: {
        'Accept': 'application/vnd.api+json',
      },
      credentials: 'include'
    })
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    const data = await response.json()
    this.validateJsonApiResponse(data)
    
    return data
  }
  
  async post(path, payload) {
    if (!this.csrfToken) {
      await this.init()
    }
    
    // Validate payload structure
    if (!payload.data || !payload.data.type) {
      throw new Error('Invalid JSON:API payload')
    }
    
    const response = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/vnd.api+json',
        'Accept': 'application/vnd.api+json',
        'X-CSRF-Token': this.csrfToken
      },
      credentials: 'include',
      body: JSON.stringify(payload)
    })
    
    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(errorData.errors?.[0]?.detail || 'Request failed')
    }
    
    const data = await response.json()
    this.validateJsonApiResponse(data)
    
    return data
  }
}

export function useDrupalJsonApi() {
  const api = new DrupalJsonApi()
  return { api }
}
```

---

## Secure Data Fetching

### ✅ SAFE: Rate-Limited Requests

```javascript
// composables/useRateLimitedApi.js
import { ref } from 'vue'

export function useRateLimitedApi(maxRequests = 10, timeWindow = 60000) {
  const requests = ref([])
  
  const canMakeRequest = () => {
    const now = Date.now()
    // Remove old requests outside time window
    requests.value = requests.value.filter(time => now - time < timeWindow)
    
    return requests.value.length < maxRequests
  }
  
  const rateLimitedFetch = async (url, options) => {
    if (!canMakeRequest()) {
      throw new Error('Rate limit exceeded')
    }
    
    requests.value.push(Date.now())
    return fetch(url, options)
  }
  
  return { rateLimitedFetch, canMakeRequest }
}
```

### ✅ SAFE: Request Timeout

```javascript
// utils/fetch-with-timeout.js
export async function fetchWithTimeout(url, options = {}, timeout = 10000) {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), timeout)
  
  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal
    })
    clearTimeout(timeoutId)
    return response
  } catch (error) {
    clearTimeout(timeoutId)
    if (error.name === 'AbortError') {
      throw new Error('Request timeout')
    }
    throw error
  }
}
```

---

## Drupal-Specific API Security

### ✅ SAFE: Entity Access Validation

```vue
<script setup>
import { ref, computed } from 'vue'
import { useDrupalJsonApi } from '@/services/drupal-jsonapi'

const { api } = useDrupalJsonApi()

const loadNode = async (node_id) => {
  try {
    const response = await api.get(`/jsonapi/node/article/${node_id}`)
    
    // Check if we have access to entity
    if (!response.data) {
      throw new Error('Access denied or not found')
    }
    
    // Validate response structure
    if (!response.data.attributes) {
      throw new Error('Invalid entity structure')
    }
    
    return response.data
  } catch (error) {
    // Don't expose internal errors
    console.error('Load error:', error)
    throw new Error('Failed to load content')
  }
}

// Never trust client-side permission checks
const canEdit = computed(() => {
  // This is for UI only, server validates
  return node.value?.meta?.can_edit === true
})
</script>
```

### ✅ SAFE: File Upload Security

```vue
<script setup>
import { ref } from 'vue'
import { useDrupalApi } from '@/composables/useDrupalApi'

const { apiRequest } = useDrupalApi()

const uploadFile = async (file) => {
  // Validate file on client (server must also validate)
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
  const maxSize = 5 * 1024 * 1024 // 5MB
  
  if (!allowedTypes.includes(file.type)) {
    throw new Error('Invalid file type')
  }
  
  if (file.size > maxSize) {
    throw new Error('File too large')
  }
  
  // Create form data
  const formData = new FormData()
  formData.append('file', file)
  
  try {
    const response = await apiRequest('/file/upload/node/article/field_image', {
      method: 'POST',
      body: formData,
      headers: {
        // Don't set Content-Type, browser will set it with boundary
        'Accept': 'application/vnd.api+json'
      }
    })
    
    if (!response.ok) {
      throw new Error('Upload failed')
    }
    
    return await response.json()
  } catch (error) {
    console.error('Upload error:', error)
    throw error
  }
}
</script>
```

---

## Audit Checklist

- [ ] CSRF token fetched and included in mutating requests
- [ ] All API requests use credentials: 'include'
- [ ] No credentials hardcoded in frontend code
- [ ] Sensitive data not stored in localStorage/sessionStorage
- [ ] API responses validated before use
- [ ] Error messages don't expose system details
- [ ] Request timeouts implemented
- [ ] Rate limiting on client side
- [ ] File uploads validate type and size
- [ ] Authorization checked on server (not just client)
- [ ] TLS/HTTPS enforced
- [ ] API endpoints use correct HTTP methods
- [ ] No sensitive data in URL parameters

---

## Testing Strategy

```javascript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useDrupalApi } from '@/composables/useDrupalApi'

describe('Drupal API Security', () => {
  beforeEach(() => {
    global.fetch = vi.fn()
  })
  
  it('should include CSRF token in POST requests', async () => {
    global.fetch.mockResolvedValueOnce({
      text: () => Promise.resolve('test-token')
    })
    
    const { apiRequest, initAuth } = useDrupalApi()
    await initAuth()
    
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({})
    })
    
    await apiRequest('/api/test', { method: 'POST' })
    
    expect(global.fetch).toHaveBeenCalledWith(
      '/api/test',
      expect.objectContaining({
        headers: expect.objectContaining({
          'X-CSRF-Token': 'test-token'
        })
      })
    )
  })
  
  it('should not expose sensitive data', async () => {
    const userData = {
      id: 1,
      name: 'test',
      email: 'test@example.com',
      password_hash: 'should-not-exist'
    }
    
    // Ensure password hash is never in frontend code
    expect(userData).not.toHaveProperty('password_hash')
  })
})
```

---

## References

- [Drupal JSON:API](https://www.drupal.org/docs/core-modules-and-themes/core-modules/jsonapi-module)
- [Drupal CSRF Protection](https://www.drupal.org/docs/security-in-drupal/understanding-csrf-attacks)
- [OWASP API Security](https://owasp.org/www-project-api-security/)

