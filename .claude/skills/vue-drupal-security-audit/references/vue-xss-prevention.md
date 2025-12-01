# XSS Prevention in Vue Components

**OWASP Reference**: A03:2021 - Injection
**Severity**: Critical
**Vue Version**: 3.x (compatible with 2.x patterns)

## Overview

Cross-Site Scripting (XSS) is the most common vulnerability in Vue applications. Vue provides automatic escaping by default, but developers can bypass this protection, leading to serious security issues.

---

## Security Patterns

### ✅ SAFE: Default Text Interpolation

```vue
<template>
  <!-- Vue automatically escapes HTML entities -->
  <div>{{ userInput }}</div>
  <div>{{ drupalContent }}</div>
</template>
```

### ✅ SAFE: Attribute Binding

```vue
<template>
  <!-- Automatically escaped -->
  <div :title="userProvidedTitle">Content</div>
  <a :href="sanitizedUrl">Link</a>
</template>

<script setup>
import { computed } from 'vue'

const sanitizedUrl = computed(() => {
  // Validate URL scheme
  const url = props.url
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url
  }
  return '#'
})
</script>
```

### ✅ SAFE: Sanitized HTML with DOMPurify

```vue
<template>
  <div v-html="sanitizedHtml"></div>
</template>

<script setup>
import { computed } from 'vue'
import DOMPurify from 'dompurify'

const props = defineProps({
  htmlContent: String
})

const sanitizedHtml = computed(() => {
  return DOMPurify.sanitize(props.htmlContent, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p'],
    ALLOWED_ATTR: ['href', 'title']
  })
})
</script>
```

---

## Anti-Patterns (Vulnerabilities)

### ❌ DANGEROUS: Direct v-html Usage

```vue
<!-- NEVER DO THIS -->
<template>
  <div v-html="userInput"></div>
  <div v-html="apiResponse.content"></div>
</template>
```

**Why Dangerous**: Allows arbitrary HTML/JavaScript execution.

### ❌ DANGEROUS: Dynamic Component Rendering from User Input

```vue
<!-- VULNERABLE -->
<template>
  <component :is="userSelectedComponent" />
</template>

<script setup>
// User controls which component renders
const props = defineProps({
  userSelectedComponent: String // Could be malicious
})
</script>
```

### ❌ DANGEROUS: Unvalidated URL Binding

```vue
<!-- VULNERABLE -->
<template>
  <a :href="userUrl">Click here</a>
  <iframe :src="externalSource"></iframe>
</template>
```

**Why Dangerous**: Can lead to `javascript:` protocol injection.

### ❌ DANGEROUS: Dynamic Event Handlers

```vue
<!-- VULNERABLE -->
<template>
  <button @click="eval(userCode)">Execute</button>
</template>
```

---

## Drupal-Specific Considerations

### Rendering Drupal Content

```vue
<template>
  <!-- SAFE: Drupal already sanitized content -->
  <div v-html="sanitizedDrupalContent"></div>
</template>

<script setup>
import DOMPurify from 'dompurify'

const props = defineProps({
  drupalContent: {
    type: String,
    required: true
  }
})

// Double-sanitize for defense in depth
const sanitizedDrupalContent = computed(() => {
  return DOMPurify.sanitize(props.drupalContent)
})
</script>
```

### Integrating with Drupal's Text Filters

```javascript
// composables/useDrupalContent.js
import { ref, computed } from 'vue'
import DOMPurify from 'dompurify'

export function useDrupalContent() {
  const sanitize = (html, textFormat = 'filtered_html') => {
    // Match Drupal's text format restrictions
    const configs = {
      filtered_html: {
        ALLOWED_TAGS: ['a', 'em', 'strong', 'cite', 'blockquote', 'code', 
                       'ul', 'ol', 'li', 'dl', 'dt', 'dd', 'p', 'br', 'span'],
        ALLOWED_ATTR: ['href', 'title', 'class']
      },
      basic_html: {
        ALLOWED_TAGS: ['a', 'em', 'strong', 'p', 'br'],
        ALLOWED_ATTR: ['href']
      }
    }
    
    return DOMPurify.sanitize(html, configs[textFormat] || configs.basic_html)
  }
  
  return { sanitize }
}
```

---

## Audit Checklist

- [ ] Search for all `v-html` directives
- [ ] Verify all `v-html` content is sanitized with DOMPurify
- [ ] Check dynamic component usage (`:is` directive)
- [ ] Validate all URL bindings (`:href`, `:src`)
- [ ] Review event handlers for eval/Function usage
- [ ] Check for innerHTML/outerHTML in lifecycle hooks
- [ ] Verify props containing HTML are validated
- [ ] Review third-party components that render HTML
- [ ] Check template compilation at runtime
- [ ] Validate data from Drupal APIs

---

## Testing Strategy

### Unit Tests with Vitest

```javascript
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import SafeComponent from './SafeComponent.vue'

describe('XSS Prevention', () => {
  it('should escape malicious HTML', () => {
    const wrapper = mount(SafeComponent, {
      props: {
        content: '<script>alert("XSS")</script>'
      }
    })
    
    // Should not contain actual script tag
    expect(wrapper.html()).not.toContain('<script>')
    // Should be escaped
    expect(wrapper.html()).toContain('&lt;script&gt;')
  })
  
  it('should sanitize v-html content', () => {
    const wrapper = mount(SafeComponent, {
      props: {
        htmlContent: '<img src=x onerror=alert(1)>'
      }
    })
    
    expect(wrapper.html()).not.toContain('onerror')
  })
})
```

---

## Remediation Steps

1. **Install DOMPurify**:
   ```bash
   npm install dompurify
   npm install -D @types/dompurify
   ```

2. **Create sanitization composable**:
   ```javascript
   // composables/useSanitize.js
   import DOMPurify from 'dompurify'
   
   export function useSanitize() {
     const sanitizeHtml = (dirty) => DOMPurify.sanitize(dirty)
     return { sanitizeHtml }
   }
   ```

3. **Replace vulnerable patterns**:
   - Find: `v-html="someVar"`
   - Replace with: `v-html="sanitizeHtml(someVar)"`

4. **Add ESLint rules**:
   ```javascript
   // .eslintrc.js
   rules: {
     'vue/no-v-html': 'warn'
   }
   ```

---

## References

- [Vue.js Security Best Practices](https://vuejs.org/guide/best-practices/security.html)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [DOMPurify Documentation](https://github.com/cure53/DOMPurify)
- [Drupal Text Formats](https://www.drupal.org/docs/user_guide/en/structure-text-formats.html)

