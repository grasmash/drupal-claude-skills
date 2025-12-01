# Quick Start Guide - Vue Drupal Security Audit

Get started with security auditing your Vue.js components in Drupal themes.

## Installation

The skill is already available at:
```
.claude/skills/vue-drupal-security-audit/
```

Claude will automatically activate it when you discuss Vue security topics.

## Quick Security Audit

### Step 1: Audit a Single Component

Ask Claude:
```
Audit this Vue component for security vulnerabilities:

<paste your component code here>
```

### Step 2: Review Findings

Claude will identify issues by severity:
- **Critical**: Immediate action required
- **High**: Fix soon
- **Medium**: Should be addressed
- **Low**: Best practice improvements

### Step 3: Apply Fixes

Claude will provide:
- Explanation of the vulnerability
- Secure code examples
- Testing recommendations

## Common Quick Checks

### Check 1: XSS Vulnerabilities

```bash
# Find all v-html usage
grep -r "v-html" src/components/

# Ask Claude to audit each occurrence
"Is this v-html usage secure?"
```

### Check 2: API Security

```bash
# Find API calls
grep -r "fetch\|axios" src/

# Review with Claude
"Review these API calls for CSRF protection and error handling"
```

### Check 3: State Management

```bash
# Find store files
find src/stores -name "*.js"

# Audit stores
"Check this Pinia store for sensitive data exposure"
```

### Check 4: Build Configuration

```bash
# Review build config
cat vite.config.js

# Ask Claude
"Review this Vite config for production security"
```

### Check 5: Dependencies

```bash
# Check for vulnerabilities
npm audit

# Review with Claude
"What are the security implications of these npm audit findings?"
```

## Priority Fixes

### Critical (Fix Immediately)

1. **Remove Hardcoded Secrets**
   ```bash
   # Search for common secret patterns
   grep -r "api_key\|password\|secret\|token" src/
   ```

2. **Add CSRF Protection**
   ```javascript
   // Add to all mutating API calls
   headers: {
     'X-CSRF-Token': csrfToken
   }
   ```

3. **Sanitize v-html**
   ```bash
   npm install dompurify
   ```

### High (Fix This Week)

4. **Validate Props**
   ```vue
   <script setup>
   defineProps({
     user_id: {
       type: Number,
       required: true,
       validator: (v) => v > 0
     }
   })
   </script>
   ```

5. **Remove Source Maps in Production**
   ```javascript
   // vite.config.js
   build: {
     sourcemap: mode === 'development'
   }
   ```

## Integration with Drupal

### Secure Data Passing

```php
<?php
// mytheme.theme
function mytheme_preprocess_page(&$variables) {
  $variables['#attached']['drupalSettings']['mytheme'] = [
    'apiEndpoint' => \Drupal::url('mytheme.api'),
    'csrfToken' => \Drupal::csrfToken()->get('rest'),
    // Only safe, public data!
  ];
}
```

### Server-Side Validation

```php
<?php
// Always validate on server
public function submitForm(Request $request) {
  // Verify CSRF
  if (!$this->csrfToken()->validate($token, 'rest')) {
    return new JsonResponse(['error' => 'Invalid token'], 403);
  }
  
  // Check permissions
  if (!$this->currentUser()->hasPermission('edit content')) {
    return new JsonResponse(['error' => 'Access denied'], 403);
  }
  
  // Validate input
  // Process request
}
```

## Testing Your Fixes

### Manual Testing

1. **Test XSS Prevention**
   ```javascript
   // Try to inject script
   const malicious = '<script>alert("XSS")</script>'
   // Should be escaped or sanitized
   ```

2. **Test CSRF Protection**
   ```bash
   # Try API call without token (should fail)
   curl -X POST http://localhost/api/endpoint
   ```

3. **Test Authorization**
   ```bash
   # Try to access as different user
   # Server should deny based on permissions
   ```

### Automated Testing

```javascript
// tests/security.test.js
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'

describe('XSS Prevention', () => {
  it('should escape malicious HTML', () => {
    const wrapper = mount(MyComponent, {
      props: { content: '<script>alert(1)</script>' }
    })
    expect(wrapper.html()).not.toContain('<script>')
  })
})
```

## Continuous Security

### Add to CI/CD

```yaml
# .github/workflows/security.yml
name: Security Audit
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm audit --audit-level=moderate
      - run: npm run build
      - run: test ! -f dist/js/*.map  # No source maps
```

### Regular Reviews

- **Weekly**: Check `npm audit`
- **Monthly**: Review new dependencies
- **Quarterly**: Full security audit with Claude
- **Before release**: Complete security checklist

## Getting Help

### Ask Claude

```
"What are the security best practices for Vue components in Drupal themes?"

"How should I handle user authentication in a Vue/Drupal app?"

"Review my build configuration for security issues"

"What's the safest way to pass data from Drupal to Vue?"
```

### Reference Documents

- `@references/vue-xss-prevention.md` - XSS security
- `@references/vue-drupal-api.md` - API integration
- `@references/vuex-pinia-security.md` - State management
- `@references/vue-build-security.md` - Build config
- `@references/drupal-theme-integration.md` - Drupal integration

## Quick Reference Commands

```bash
# Security audit
npm audit
npm audit fix

# Find security issues
grep -r "v-html" src/
grep -r "password" src/
grep -r "console.log" dist/

# Build securely
NODE_ENV=production npm run build

# Verify production build
ls dist/js/*.map  # Should be empty
grep -r "console.log" dist/  # Should be empty

# Update dependencies
npm outdated
npm update
```

## Success Checklist

✅ No hardcoded secrets in code  
✅ All `v-html` uses DOMPurify  
✅ CSRF tokens on all mutations  
✅ Props validated on components  
✅ Server validates all permissions  
✅ No source maps in production  
✅ Dependencies up to date  
✅ Build minified and obfuscated  
✅ Error messages generic  
✅ Sensitive data not in localStorage  

## Next Steps

1. Run initial audit: `npm audit`
2. Review one component with Claude
3. Fix critical issues first
4. Add automated checks to CI/CD
5. Schedule regular audits

---

**Need more help?** See `EXAMPLES.md` for detailed vulnerability examples and fixes.

