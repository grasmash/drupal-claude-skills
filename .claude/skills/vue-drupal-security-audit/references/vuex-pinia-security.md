# Vuex/Pinia State Management Security

**OWASP Reference**: A01:2021 - Broken Access Control
**Severity**: High
**Target**: Vuex 4.x / Pinia 2.x

## Overview

State management stores can expose sensitive data, allow unauthorized mutations, or leak information through poor design. Proper state management security is critical for Vue applications.

---

## Pinia Security Patterns

### ✅ SAFE: Secure Pinia Store

```javascript
// stores/user.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useUserStore = defineStore('user', () => {
  // Private state - not directly exposed
  const _userData = ref(null)
  const _permissions = ref([])
  const csrfToken = ref(null)
  
  // Public computed (read-only)
  const user = computed(() => {
    if (!_userData.value) return null
    
    // Return sanitized user data
    const { password, apiKey, ...safeData } = _userData.value
    return safeData
  })
  
  const permissions = computed(() => [..._permissions.value])
  
  const isAuthenticated = computed(() => !!_userData.value)
  
  // Validated actions
  const setUser = (userData) => {
    // Validate user data structure
    if (!userData || typeof userData !== 'object') {
      throw new Error('Invalid user data')
    }
    
    if (!userData.id || !userData.name) {
      throw new Error('User must have id and name')
    }
    
    // Remove sensitive fields if accidentally included
    const { password, password_hash, api_key, ...safeData } = userData
    
    _userData.value = safeData
  }
  
  const setPermissions = (perms) => {
    // Validate permissions array
    if (!Array.isArray(perms)) {
      throw new Error('Permissions must be an array')
    }
    
    // Only allow known permission strings
    const validPermissions = [
      'view_content',
      'create_content',
      'edit_own_content',
      'edit_any_content',
      'delete_own_content',
      'delete_any_content'
    ]
    
    _permissions.value = perms.filter(p => validPermissions.includes(p))
  }
  
  const hasPermission = (permission) => {
    return _permissions.value.includes(permission)
  }
  
  const logout = () => {
    _userData.value = null
    _permissions.value = []
    csrfToken.value = null
    
    // Clear any stored tokens
    sessionStorage.removeItem('auth_data')
  }
  
  return {
    // Expose only what's needed
    user,
    permissions,
    isAuthenticated,
    hasPermission,
    setUser,
    setPermissions,
    logout,
    csrfToken
  }
})
```

### ✅ SAFE: Pinia Plugin for Sensitive Data

```javascript
// plugins/pinia-security.js
export function securityPlugin({ store }) {
  // Monitor state changes
  store.$subscribe((mutation, state) => {
    // Check for sensitive data in state
    const sensitiveKeys = ['password', 'apiKey', 'token', 'secret']
    
    const checkForSensitiveData = (obj, path = '') => {
      if (!obj || typeof obj !== 'object') return
      
      Object.keys(obj).forEach(key => {
        const lowercaseKey = key.toLowerCase()
        
        if (sensitiveKeys.some(sk => lowercaseKey.includes(sk))) {
          console.warn(`⚠️ Potential sensitive data in store: ${path}.${key}`)
        }
        
        if (typeof obj[key] === 'object') {
          checkForSensitiveData(obj[key], `${path}.${key}`)
        }
      })
    }
    
    checkForSensitiveData(state, store.$id)
  })
}

// main.js
import { createPinia } from 'pinia'
import { securityPlugin } from './plugins/pinia-security'

const pinia = createPinia()
pinia.use(securityPlugin)
```

---

## Vuex Security Patterns

### ✅ SAFE: Secure Vuex Store

```javascript
// store/modules/auth.js
export default {
  namespaced: true,
  
  state: () => ({
    _user: null,
    _token: null,
    isAuthenticated: false
  }),
  
  getters: {
    user: (state) => {
      if (!state._user) return null
      
      // Return sanitized copy
      const { password, ...safeUser } = state._user
      return { ...safeUser }
    },
    
    isAuthenticated: (state) => state.isAuthenticated,
    
    hasRole: (state) => (role) => {
      return state._user?.roles?.includes(role) || false
    }
  },
  
  mutations: {
    SET_USER(state, user) {
      // Validate before setting
      if (user && typeof user === 'object' && user.id) {
        const { password, password_hash, ...safeUser } = user
        state._user = safeUser
        state.isAuthenticated = true
      } else {
        state._user = null
        state.isAuthenticated = false
      }
    },
    
    SET_TOKEN(state, token) {
      if (typeof token === 'string' && token.length > 0) {
        state._token = token
      } else {
        state._token = null
      }
    },
    
    LOGOUT(state) {
      state._user = null
      state._token = null
      state.isAuthenticated = false
    }
  },
  
  actions: {
    async login({ commit }, credentials) {
      // Validate credentials
      if (!credentials.username || !credentials.password) {
        throw new Error('Invalid credentials')
      }
      
      try {
        const response = await fetch('/user/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify(credentials)
        })
        
        if (!response.ok) {
          throw new Error('Login failed')
        }
        
        const data = await response.json()
        
        commit('SET_USER', data.user)
        commit('SET_TOKEN', data.csrf_token)
        
        return data
      } catch (error) {
        commit('LOGOUT')
        throw error
      }
    },
    
    logout({ commit }) {
      commit('LOGOUT')
      sessionStorage.clear()
    }
  }
}
```

---

## Anti-Patterns (Vulnerabilities)

### ❌ DANGEROUS: Sensitive Data in State

```javascript
// VULNERABLE: Storing passwords in state
export const useAuthStore = defineStore('auth', () => {
  const user = ref({
    id: 1,
    username: 'admin',
    password: 'secret123', // NEVER store passwords!
    apiKey: 'abc123', // NEVER store API keys!
    passwordHash: 'hash...' // Don't store hashes in frontend
  })
  
  return { user }
})
```

### ❌ DANGEROUS: No Mutation Validation

```javascript
// VULNERABLE: Direct state mutation without validation
const store = useStore()

// Anyone can set anything
store.user = { role: 'admin' } // Privilege escalation!
store.permissions = ['delete_all'] // Unauthorized access!
```

### ❌ DANGEROUS: Exposing Internal State

```javascript
// VULNERABLE: Exposing mutable state directly
export const useDataStore = defineStore('data', () => {
  const items = ref([])
  
  // Returns reference to internal array
  return { items } // Components can mutate directly!
})

// In component
const store = useDataStore()
store.items.push({ malicious: 'data' }) // Bypasses validation!
```

### ❌ DANGEROUS: Persisting Sensitive Data

```javascript
// VULNERABLE: Persisting sensitive data to localStorage
import { defineStore } from 'pinia'
import { persistPlugin } from 'pinia-plugin-persist'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: null, // Persisted to localStorage!
    user: null
  }),
  persist: {
    enabled: true,
    strategies: [
      {
        storage: localStorage // Accessible by XSS!
      }
    ]
  }
})
```

---

## Secure Persistence

### ✅ SAFE: Controlled Persistence

```javascript
// stores/session.js
import { defineStore } from 'pinia'

export const useSessionStore = defineStore('session', () => {
  const publicData = ref({
    theme: 'light',
    language: 'en'
  })
  
  // Private data - never persisted
  const privateData = ref({
    csrfToken: null,
    user_id: null
  })
  
  // Only persist non-sensitive data
  const persist = () => {
    try {
      sessionStorage.setItem('session_prefs', JSON.stringify({
        theme: publicData.value.theme,
        language: publicData.value.language
      }))
    } catch (e) {
      console.error('Failed to persist session')
    }
  }
  
  const restore = () => {
    try {
      const stored = sessionStorage.getItem('session_prefs')
      if (stored) {
        const data = JSON.parse(stored)
        publicData.value = { ...publicData.value, ...data }
      }
    } catch (e) {
      console.error('Failed to restore session')
    }
  }
  
  return {
    publicData,
    persist,
    restore
  }
})
```

---

## Drupal Integration Patterns

### ✅ SAFE: Drupal User Store

```javascript
// stores/drupal-user.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useDrupalUserStore = defineStore('drupalUser', () => {
  const currentUser = ref(null)
  const roles = ref([])
  
  // Computed permissions based on Drupal roles
  const permissions = computed(() => {
    if (!currentUser.value) return []
    
    // Map Drupal roles to permissions
    const rolePermissions = {
      'administrator': ['administer', 'create', 'edit', 'delete'],
      'editor': ['create', 'edit_own', 'view'],
      'authenticated': ['view']
    }
    
    const perms = new Set()
    roles.value.forEach(role => {
      const rolePerms = rolePermissions[role] || []
      rolePerms.forEach(p => perms.add(p))
    })
    
    return Array.from(perms)
  })
  
  const canPerform = (action, entityType = 'node') => {
    // Client-side check for UI only
    // Server MUST validate
    return permissions.value.includes(`${action}_${entityType}`) ||
           permissions.value.includes('administer')
  }
  
  const loadCurrentUser = async () => {
    try {
      const response = await fetch('/user/current?_format=json', {
        credentials: 'include'
      })
      
      if (!response.ok) {
        throw new Error('Failed to load user')
      }
      
      const data = await response.json()
      
      // Validate Drupal user structure
      if (!data.user_id || !Array.isArray(data.roles)) {
        throw new Error('Invalid user data')
      }

      // Store only necessary data
      currentUser.value = {
        user_id: data.user_id[0].value,
        name: data.name[0].value,
        mail: data.mail?.[0]?.value,
        timezone: data.timezone?.[0]?.value
      }
      
      roles.value = data.roles.map(r => r.target_id)
      
    } catch (error) {
      console.error('Load user error:', error)
      currentUser.value = null
      roles.value = []
    }
  }
  
  return {
    currentUser,
    roles,
    permissions,
    canPerform,
    loadCurrentUser
  }
})
```

---

## Audit Checklist

- [ ] No passwords or secrets in store state
- [ ] No API keys or tokens in localStorage
- [ ] State mutations are validated
- [ ] Sensitive data is not persisted
- [ ] Getters return copies, not references
- [ ] Actions validate input parameters
- [ ] User permissions validated server-side
- [ ] Store doesn't expose internal state
- [ ] Session data cleared on logout
- [ ] No prototype pollution in state updates
- [ ] DevTools disabled in production
- [ ] State hydration validates data

---

## Testing Strategy

```javascript
import { setActivePinia, createPinia } from 'pinia'
import { describe, it, expect, beforeEach } from 'vitest'
import { useUserStore } from '@/stores/user'

describe('User Store Security', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })
  
  it('should not expose sensitive data', () => {
    const store = useUserStore()
    
    store.setUser({
      id: 1,
      name: 'test',
      password: 'secret',
      apiKey: 'key123'
    })
    
    // User getter should not include sensitive fields
    expect(store.user).not.toHaveProperty('password')
    expect(store.user).not.toHaveProperty('apiKey')
  })
  
  it('should validate permissions', () => {
    const store = useUserStore()
    
    // Should reject invalid permissions
    expect(() => {
      store.setPermissions(['invalid_permission'])
    }).not.toThrow()
    
    expect(store.permissions).not.toContain('invalid_permission')
  })
  
  it('should clear data on logout', () => {
    const store = useUserStore()
    
    store.setUser({ id: 1, name: 'test' })
    store.logout()
    
    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })
})
```

---

## References

- [Pinia Documentation](https://pinia.vuejs.org/)
- [Vuex Security Considerations](https://vuex.vuejs.org/guide/)
- [OWASP Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)

