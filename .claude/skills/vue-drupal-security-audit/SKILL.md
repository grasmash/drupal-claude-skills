---
name: vue-drupal-security-audit
description: Comprehensive security auditing for Vue.js components in Drupal 10/11 themes. Covers XSS prevention, component security, state management, API security, build configuration, CSP, and frontend-specific OWASP vulnerabilities.
---

# Vue Component Security Audit for Drupal Themes

**Version**: 1.0.0
**Target**: Drupal 10/11 themes with Vue.js components
**License**: MIT

## When This Skill Activates

Activates when performing security audits on:
- Vue.js components in Drupal themes
- Frontend JavaScript security
- Template security and XSS prevention
- Component props and data validation
- State management security
- API communication patterns
- Build and bundler configuration
- Third-party Vue library usage
- Content Security Policy (CSP)
- Frontend authentication and authorization

---

## Available Topics

All topics are available as references in the `/references/` directory.

Each reference contains:
- Security patterns and anti-patterns
- Audit checklists
- Code examples (vulnerable and secure)
- Drupal-specific integration considerations
- Testing strategies
- Remediation guidance

### Core Vue Security

- @references/vue-xss-prevention.md - XSS and template injection prevention
- @references/vue-component-security.md - Component design and props validation

### State Management & Data Flow

- @references/vuex-pinia-security.md - Vuex/Pinia state management security

### Integration & Communication

- @references/vue-drupal-api.md - Drupal API integration security

### Build & Configuration

- @references/vue-build-security.md - Vite/Webpack build security
- @references/vue-dependency-audit.md - npm/yarn dependency security

### Drupal Theme Integration

- @references/drupal-theme-integration.md - Vue in Drupal theme architecture

---

## Usage Examples

### Basic Security Audit

```
Please audit this Vue component for security vulnerabilities:
[paste component code]
```

### Comprehensive Theme Audit

```
Perform a complete security audit of the Vue components in my Drupal theme,
focusing on XSS prevention and API security.
```

### Specific Concern

```
Review this Vuex store for security issues related to user data handling.
```

---

## Audit Checklist

When performing a security audit, this skill will evaluate:

- [ ] XSS vulnerabilities in templates (v-html usage)
- [ ] Props validation and type checking
- [ ] User input sanitization
- [ ] API request authentication
- [ ] CSRF token implementation
- [ ] Sensitive data exposure
- [ ] Client-side authorization logic
- [ ] Third-party dependencies
- [ ] Build configuration security
- [ ] Content Security Policy compatibility
- [ ] Error handling and information disclosure
- [ ] Local storage security
- [ ] Event handler security
- [ ] Component lifecycle security
- [ ] Drupal integration patterns

---

## Related Skills

This skill complements:
- @ivangrynenko-cursorrules-drupal - Backend Drupal security
- @drupal-at-your-fingertips - General Drupal development

---

## Sources and Attribution

**Author**: Amit Goyal
**Created**: November 2025

**Based on**:
- [OWASP Top 10 2021](https://owasp.org/Top10/) - Web application security risks
- [Vue.js Security Best Practices](https://vuejs.org/guide/best-practices/security.html) - Official Vue.js security guide
- [Drupal Security Best Practices](https://www.drupal.org/security/best-practices) - Drupal security standards
- [DOMPurify Documentation](https://github.com/cure53/DOMPurify) - HTML sanitization library
- [CWE - Common Weakness Enumeration](https://cwe.mitre.org/) - Software security weaknesses

**License**: MIT

---

**Maintained by**: Drupal Claude Skills Community
**Last Updated**: December 2025

