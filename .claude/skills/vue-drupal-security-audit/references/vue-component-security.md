# Vue Component Security Patterns

**OWASP Reference**: A04:2021 - Insecure Design
**Severity**: High
**Vue Version**: 3.x with Composition API

## Overview

Secure component design prevents vulnerabilities through proper validation, encapsulation, and defensive programming. This includes props validation, event handling, and component communication.

---

## Props Validation & Security

### ✅ SAFE: Comprehensive Props Validation

```vue
<script setup>
import { computed } from 'vue'

const props = defineProps({
  user_id: {
    type: Number,
    required: true,
    validator: (value) => value > 0 && Number.isInteger(value)
  },
  role: {
    type: String,
    required: true,
    validator: (value) => ['admin', 'editor', 'viewer'].includes(value)
  },
  content: {
    type: String,
    default: '',
    validator: (value) => value.length <= 10000 // Limit size
  },
  config: {
    type: Object,
    default: () => ({}),
    validator: (value) => {
      // Validate structure
      const allowedKeys = ['theme', 'language', 'timezone']
      return Object.keys(value).every(key => allowedKeys.includes(key))
    }
  }
})

// Additional runtime validation
const safeUserId = computed(() => {
  return Math.max(0, parseInt(props.user_id, 10))
})
</script>
```

### ✅ SAFE: Type Guards with TypeScript

```typescript
// types/component-props.ts
export interface UserData {
  id: number
  name: string
  email: string
  roles: readonly string[]
}

export interface SecureComponentProps {
  user: UserData
  permissions: readonly string[]
  csrfToken: string
}

// Component.vue
<script setup lang="ts">
import type { SecureComponentProps } from '@/types/component-props'

const props = defineProps<SecureComponentProps>()

// TypeScript ensures type safety
const hasPermission = (permission: string): boolean => {
  return props.permissions.includes(permission)
}
</script>
```

---

## Anti-Patterns (Vulnerabilities)

### ❌ DANGEROUS: No Props Validation

```vue
<script setup>
// VULNERABLE: No validation
const props = defineProps(['user_id', 'action', 'data'])

// Could receive anything
const deleteUser = () => {
  fetch(`/api/users/${props.user_id}`, { // Unvalidated
    method: 'DELETE'
  })
}
</script>
```

### ❌ DANGEROUS: Accepting Functions as Props

```vue
<script setup>
// VULNERABLE: Parent can inject arbitrary code
const props = defineProps({
  onSuccess: Function, // Could be malicious
  transformer: Function // Direct code execution
})

const processData = (data) => {
  // Executes parent-provided code
  return props.transformer(data)
}
</script>
```

### ❌ DANGEROUS: Uncontrolled Object Spreading

```vue
<script setup>
// VULNERABLE: Prototype pollution risk
const props = defineProps({
  attributes: Object
})

const element = {
  ...props.attributes // Could contain __proto__
}
</script>
```

---

## Event Handling Security

### ✅ SAFE: Validated Event Emission

```vue
<script setup>
const emit = defineEmits(['update:modelValue', 'delete', 'save'])

const allowedEvents = new Set(['update:modelValue', 'delete', 'save'])

const safeEmit = (eventName, payload) => {
  if (!allowedEvents.has(eventName)) {
    console.error(`Invalid event: ${eventName}`)
    return
  }
  
  // Validate payload
  if (payload && typeof payload === 'object') {
    const sanitized = sanitizePayload(payload)
    emit(eventName, sanitized)
  } else {
    emit(eventName, payload)
  }
}

const sanitizePayload = (payload) => {
  // Remove dangerous properties
  const { __proto__, constructor, prototype, ...safe } = payload
  return safe
}
</script>
```

### ✅ SAFE: Debounced User Input

```vue
<template>
  <input 
    :value="modelValue"
    @input="handleInput"
    :maxlength="maxLength"
  />
</template>

<script setup>
import { useDebounceFn } from '@vueuse/core'

const props = defineProps({
  modelValue: String,
  maxLength: {
    type: Number,
    default: 255
  }
})

const emit = defineEmits(['update:modelValue'])

const handleInput = useDebounceFn((event) => {
  const value = event.target.value
  
  // Validate before emitting
  if (value.length <= props.maxLength) {
    emit('update:modelValue', value)
  }
}, 300)
</script>
```

---

## Secure Component Communication

### ✅ SAFE: Using Provide/Inject with Validation

```vue
<!-- ParentComponent.vue -->
<script setup>
import { provide, readonly, ref } from 'vue'

const userPermissions = ref(['read', 'write'])

// Provide read-only to prevent tampering
provide('permissions', readonly(userPermissions))

// Provide validated methods only
provide('checkPermission', (permission) => {
  if (typeof permission !== 'string') return false
  return userPermissions.value.includes(permission)
})
</script>

<!-- ChildComponent.vue -->
<script setup>
import { inject } from 'vue'

const permissions = inject('permissions')
const checkPermission = inject('checkPermission')

// Cannot modify permissions (readonly)
// Can only check through validated method
const canDelete = checkPermission('delete')
</script>
```

---

## Drupal-Specific Patterns

### ✅ SAFE: Drupal Entity Component

```vue
<template>
  <article v-if="isValid" :data-drupal-id="entity.id">
    <h2>{{ entity.title }}</h2>
    <div v-html="sanitizedBody"></div>
  </article>
</template>

<script setup>
import { computed } from 'vue'
import DOMPurify from 'dompurify'

const props = defineProps({
  entity: {
    type: Object,
    required: true,
    validator: (value) => {
      // Validate Drupal entity structure
      return (
        value &&
        typeof value.id === 'string' &&
        typeof value.type === 'string' &&
        ['node', 'taxonomy_term', 'user'].includes(value.type) &&
        typeof value.title === 'string'
      )
    }
  }
})

const isValid = computed(() => {
  return props.entity && props.entity.id && props.entity.type
})

const sanitizedBody = computed(() => {
  if (!props.entity.body) return ''
  return DOMPurify.sanitize(props.entity.body.value || props.entity.body)
})
</script>
```

### ✅ SAFE: Drupal View Component

```vue
<script setup lang="ts">
interface DrupalViewRow {
  [key: string]: string | number | null
}

interface DrupalView {
  view_id: string
  display_id: string
  rows: DrupalViewRow[]
  pager?: {
    current_page: number
    total_pages: number
  }
}

const props = defineProps<{
  view: DrupalView
}>()

// Validate view structure
const isValidView = computed(() => {
  return (
    props.view &&
    typeof props.view.view_id === 'string' &&
    Array.isArray(props.view.rows)
  )
})

// Sanitize row data
const sanitizedRows = computed(() => {
  if (!isValidView.value) return []
  
  return props.view.rows.map(row => {
    // Remove any unexpected properties
    const { __proto__, constructor, ...safeRow } = row
    return safeRow
  })
})
</script>
```

---

## Audit Checklist

- [ ] All props have type definitions
- [ ] Props include validators for complex types
- [ ] Numeric props are validated for range
- [ ] String props have length limits
- [ ] Array/Object props validate structure
- [ ] No Function props accepted from untrusted sources
- [ ] Events are explicitly defined with `defineEmits`
- [ ] Event payloads are sanitized
- [ ] Provide/inject uses readonly where appropriate
- [ ] Component doesn't mutate props
- [ ] Object spreading is controlled
- [ ] Drupal entity structure is validated
- [ ] TypeScript types are used when available

---

## Testing Strategy

```javascript
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import SecureComponent from './SecureComponent.vue'

describe('Component Security', () => {
  it('should reject invalid props', () => {
    // Should warn/error on invalid prop
    expect(() => {
      mount(SecureComponent, {
        props: {
          user_id: -1 // Invalid
        }
      })
    }).toThrow()
  })
  
  it('should sanitize event payloads', async () => {
    const wrapper = mount(SecureComponent)
    
    const emitted = wrapper.emitted('save')
    const payload = emitted[0][0]
    
    // Should not contain dangerous properties
    expect(payload).not.toHaveProperty('__proto__')
    expect(payload).not.toHaveProperty('constructor')
  })
  
  it('should validate Drupal entity structure', () => {
    const invalidEntity = {
      id: 123, // Should be string
      type: 'invalid_type'
    }
    
    expect(() => {
      mount(SecureComponent, {
        props: { entity: invalidEntity }
      })
    }).toThrow()
  })
})
```

---

## Remediation Steps

1. **Add props validation to all components**
2. **Use TypeScript for type safety**
3. **Create validation utilities**:
   ```javascript
   // utils/validators.js
   export const isDrupalEntity = (value) => {
     return value &&
       typeof value.id === 'string' &&
       typeof value.type === 'string'
   }
   
   export const isValidRole = (role) => {
     return ['admin', 'editor', 'viewer'].includes(role)
   }
   ```
4. **Implement ESLint rules**:
   ```javascript
   rules: {
     'vue/require-prop-types': 'error',
     'vue/require-default-prop': 'warn',
     'vue/require-prop-type-constructor': 'error'
   }
   ```

---

## References

- [Vue Props Validation](https://vuejs.org/guide/components/props.html#prop-validation)
- [TypeScript with Vue](https://vuejs.org/guide/typescript/overview.html)
- [Prototype Pollution Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Prototype_Pollution_Prevention_Cheat_Sheet.html)

