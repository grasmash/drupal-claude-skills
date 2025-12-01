# Vue Drupal Security Audit Skill

A comprehensive Claude skill for security auditing Vue.js components in Drupal 10/11 themes.

## Overview

This skill provides detailed security patterns, anti-patterns, and audit guidelines for Vue.js applications integrated with Drupal. It covers frontend-specific vulnerabilities that complement backend security practices.

## What This Skill Covers

### Core Vue Security
- **XSS Prevention**: Template injection, v-html usage, HTML sanitization
- **Component Security**: Props validation, event handling, secure design
- **State Management**: Vuex/Pinia security patterns, data exposure prevention
- **Lifecycle Security**: Secure component lifecycle and side effects

### API & Integration
- **Drupal API Security**: CSRF protection, authentication, JSON:API patterns
- **Theme Integration**: Safe data passing, Twig/Vue interaction
- **Form Security**: Server-side validation, file uploads
- **Session Management**: Tokens, cookies, storage security

### Build & Dependencies
- **Build Security**: Vite/Webpack configuration, source maps, minification
- **Dependency Audit**: npm audit, vulnerable packages, supply chain
- **Environment Variables**: Safe configuration management
- **CSP Compliance**: Content Security Policy compatibility

## Installation

This skill is already available in the `.claude/skills/` directory. Claude will automatically use it when discussing Vue security topics in Drupal themes.

## Usage

### Basic Security Audit

```
Please audit this Vue component for security vulnerabilities:
[paste component code]
```

### Comprehensive Theme Audit

```
Perform a complete security audit of the Vue components in my Drupal theme.
Focus on XSS prevention, API security, and state management.
```

### Specific Issue Review

```
Review this Vuex store for security issues related to user data handling.
```

### Check Specific Pattern

```
Is this way of passing data from Drupal to Vue secure?
[paste code]
```

## Reference Documents

All detailed guidance is in the `references/` directory:

1. **vue-xss-prevention.md** - XSS and template security
2. **vue-component-security.md** - Component design patterns
3. **vuex-pinia-security.md** - State management security
4. **vue-drupal-api.md** - API integration patterns
5. **vue-build-security.md** - Build configuration
6. **vue-dependency-audit.md** - Package security
7. **drupal-theme-integration.md** - Drupal/Vue integration

## Key Features

### 🔍 Vulnerability Detection
- Identifies XSS vectors in templates
- Detects unsafe API patterns
- Finds exposed sensitive data
- Locates vulnerable dependencies

### ✅ Secure Patterns
- Provides safe code examples
- Shows proper validation techniques
- Demonstrates secure state management
- Includes Drupal-specific patterns

### 🛠️ Remediation Guidance
- Step-by-step fixes
- Testing strategies
- Automated checks
- CI/CD integration

### 📋 Audit Checklists
- Component-level checks
- Theme-wide audits
- Build security verification
- Dependency reviews

## Common Vulnerabilities Detected

1. **XSS in Templates**
   - Unescaped `v-html` usage
   - Dynamic component rendering
   - URL injection in attributes

2. **API Security**
   - Missing CSRF tokens
   - Hardcoded credentials
   - Exposed sensitive data
   - Unvalidated requests

3. **State Management**
   - Passwords in store
   - Mutable state exposure
   - Unsafe persistence
   - Client-side authorization

4. **Build Configuration**
   - Source maps in production
   - API keys in bundle
   - DevTools enabled
   - Missing minification

5. **Dependencies**
   - Known vulnerabilities
   - Outdated packages
   - Suspicious licenses
   - Supply chain risks

## Integration with Other Skills

Works alongside:
- **ivangrynenko-cursorrules-drupal**: Backend Drupal security
- **drupal-at-your-fingertips**: General Drupal development
- **drupal-config-mgmt**: Configuration security

## Best Practices Enforced

### Security-First Development
- Defense in depth
- Principle of least privilege
- Input validation
- Output encoding
- Secure defaults

### Drupal Integration
- Proper use of drupalSettings
- CSRF token handling
- Entity access checks
- Form API integration
- File upload security

### Modern Vue Patterns
- Composition API security
- TypeScript type safety
- Props validation
- Readonly state
- Computed properties

## Testing & Validation

The skill includes:
- Unit test examples
- Integration test patterns
- Security test cases
- Automated audit scripts
- CI/CD configurations

## Contributing

To add new patterns or update existing ones:

1. Add reference document to `references/`
2. Update SKILL.md with new reference
3. Include code examples (vulnerable and secure)
4. Add audit checklist items
5. Provide testing strategies

## Security Levels

The skill categorizes issues by severity:

- **Critical**: Immediate security risk (XSS, credential exposure)
- **High**: Significant vulnerability (CSRF, injection)
- **Medium**: Security weakness (info disclosure, weak validation)
- **Low**: Best practice violation (missing headers, outdated deps)

## Quick Reference

### Audit Commands

```bash
# Dependency audit
npm audit --audit-level=moderate

# Find v-html usage
grep -r "v-html" src/

# Check for console.log in production
grep -r "console.log" dist/

# Verify no source maps
find dist/ -name "*.map"
```

### Common Fixes

```bash
# Install sanitizer
npm install dompurify

# Update dependencies
npm audit fix

# Remove unused packages
npm prune
```

## License

MIT - Same as the repository

## Support

For issues or questions about this skill:
- Open an issue in the repository
- Refer to reference documents
- Check OWASP guidelines
- Review Vue security docs

---

**Version**: 1.0.0  
**Last Updated**: November 2025  
**Maintained by**: Drupal Claude Skills Community

