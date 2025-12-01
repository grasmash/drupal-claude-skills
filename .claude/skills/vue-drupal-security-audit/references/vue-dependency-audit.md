# Dependency Security Audit

**OWASP Reference**: A06:2021 - Vulnerable and Outdated Components
**Severity**: Critical
**Tools**: npm audit, Snyk, Dependabot

## Overview

Third-party dependencies are a major attack vector. Regular auditing and updates of npm packages are essential for Vue application security.

---

## Dependency Auditing Tools

### ✅ SAFE: NPM Audit Configuration

```json
// package.json
{
  "scripts": {
    "audit": "npm audit --audit-level=moderate",
    "audit:fix": "npm audit fix",
    "audit:report": "npm audit --json > audit-report.json",
    "deps:check": "npm outdated",
    "deps:update": "npm update",
    "preinstall": "npx npm-force-resolutions"
  },
  "resolutions": {
    // Force secure versions
    "lodash": "^4.17.21",
    "axios": "^1.6.0"
  }
}
```

### ✅ SAFE: Automated Security Scanning

```yaml
# .github/workflows/security.yml
name: Security Audit

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1' # Weekly

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run npm audit
        run: npm audit --audit-level=high
      
      - name: Check for outdated deps
        run: npm outdated || true
      
      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

## Vulnerable Package Patterns

### ❌ DANGEROUS: Known Vulnerable Packages

```json
// VULNERABLE package.json
{
  "dependencies": {
    "axios": "0.21.0", // CVE-2021-3749
    "lodash": "4.17.19", // CVE-2020-8203
    "vue": "2.6.11", // Outdated, use 3.x
    "marked": "0.3.9", // XSS vulnerabilities
    "serialize-javascript": "3.0.0" // RCE vulnerability
  }
}
```

### ✅ SAFE: Updated Dependencies

```json
// SECURE package.json
{
  "dependencies": {
    "vue": "^3.3.8",
    "axios": "^1.6.2",
    "lodash-es": "^4.17.21",
    "marked": "^11.0.0",
    "dompurify": "^3.0.6"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.5.0",
    "vite": "^5.0.0",
    "vitest": "^1.0.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
```

---

## Drupal-Specific Dependencies

### ✅ SAFE: Drupal-Compatible Package Selection

```json
{
  "dependencies": {
    // Core
    "vue": "^3.3.8",
    "pinia": "^2.1.7",
    "vue-router": "^4.2.5",
    
    // HTTP & API
    "axios": "^1.6.2",
    "@drupal/jsonapi-client": "^1.0.0",
    
    // Security
    "dompurify": "^3.0.6",
    "js-cookie": "^3.0.5",
    
    // Utilities
    "lodash-es": "^4.17.21",
    "date-fns": "^2.30.0",
    
    // Forms
    "vee-validate": "^4.12.2",
    "yup": "^1.3.3"
  }
}
```

---

## Package Integrity Verification

### ✅ SAFE: Using package-lock.json

```json
// package-lock.json (always commit this!)
{
  "name": "drupal-vue-theme",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "node_modules/vue": {
      "version": "3.3.8",
      "resolved": "https://registry.npmjs.org/vue/-/vue-3.3.8.tgz",
      "integrity": "sha512-5VSX/3DabBikOXMsxzlW8JyfeLKlG9mzqnWgLQLty88vdZL7ZJgrdgBOmrArwxiLtmS+lNNpPcBYqrhE6TQW5w=="
    }
  }
}
```

### ✅ SAFE: Verify Package Integrity

```bash
#!/bin/bash
# scripts/verify-integrity.sh

echo "🔍 Verifying package integrity..."

# Check for lock file
if [ ! -f "package-lock.json" ]; then
  echo "❌ package-lock.json not found!"
  exit 1
fi

# Verify integrity
npm ci --ignore-scripts

# Check for known vulnerabilities
npm audit --audit-level=high

echo "✅ Package integrity verified"
```

---

## Dependency Review

### ✅ SAFE: Manual Package Review Checklist

Before adding a new package, verify:

1. **Maintenance Status**
   - Last publish date (< 12 months)
   - Active issues and PRs
   - Number of maintainers

2. **Security History**
   - CVE database search
   - GitHub security advisories
   - npm advisory database

3. **Package Quality**
   - Download count
   - GitHub stars
   - Test coverage
   - TypeScript support

4. **License Compatibility**
   - MIT, Apache-2.0, BSD (preferred)
   - Avoid GPL if proprietary

```javascript
// scripts/check-package.js
const https = require('https')

async function checkPackage(packageName) {
  return new Promise((resolve, reject) => {
    https.get(`https://registry.npmjs.org/${packageName}`, (res) => {
      let data = ''
      res.on('data', chunk => data += chunk)
      res.on('end', () => {
        const pkg = JSON.parse(data)
        const latest = pkg['dist-tags'].latest
        const version = pkg.versions[latest]
        
        console.log(`📦 ${packageName}@${latest}`)
        console.log(`   License: ${version.license}`)
        console.log(`   Last updated: ${pkg.time[latest]}`)
        console.log(`   Homepage: ${version.homepage}`)
        
        resolve(pkg)
      })
    }).on('error', reject)
  })
}

// Usage: node scripts/check-package.js vue
checkPackage(process.argv[2])
```

---

## Automated Dependency Updates

### ✅ SAFE: Renovate Configuration

```json
// renovate.json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchPackagePatterns": ["^vue", "^@vue"],
      "groupName": "vue packages"
    },
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true,
      "schedule": ["before 3am on Monday"]
    }
  ],
  "vulnerabilityAlerts": {
    "labels": ["security"],
    "assignees": ["@security-team"]
  },
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 3am on Monday"]
  }
}
```

### ✅ SAFE: Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "03:00"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"
    
    # Version updates
    versioning-strategy: increase
    
    # Security updates
    allow:
      - dependency-type: "direct"
      - dependency-type: "indirect"
    
    # Ignore specific packages
    ignore:
      - dependency-name: "vue"
        update-types: ["version-update:semver-major"]
```

---

## Supply Chain Security

### ✅ SAFE: npm Configuration

```ini
# .npmrc
# Only allow registry from npm
registry=https://registry.npmjs.org/

# Require package signatures
audit=true
audit-level=moderate

# Disable scripts from dependencies
ignore-scripts=true

# Use exact versions
save-exact=true

# Require package-lock
package-lock=true
```

### ✅ SAFE: CI/CD Security

```yaml
# .github/workflows/install.yml
- name: Install dependencies securely
  run: |
    # Verify package-lock exists
    if [ ! -f "package-lock.json" ]; then
      echo "Missing package-lock.json"
      exit 1
    fi
    
    # Use ci instead of install
    npm ci --ignore-scripts
    
    # Audit after install
    npm audit --audit-level=moderate
```

---

## Audit Checklist

- [ ] package-lock.json committed to repository
- [ ] npm audit runs in CI/CD
- [ ] Automated dependency updates configured
- [ ] No packages with high/critical vulnerabilities
- [ ] Dependencies reviewed in last 6 months
- [ ] No dependencies with suspicious licenses
- [ ] Package integrity verified (lock file)
- [ ] Scripts disabled during install
- [ ] Development dependencies separated
- [ ] Unused dependencies removed
- [ ] Dependency versions pinned or ranged appropriately
- [ ] Security scanning in pull requests

---

## Common Vulnerable Packages to Avoid/Update

| Package | Vulnerable | Safe Alternative | Reason |
|---------|-----------|------------------|--------|
| `moment` | All versions | `date-fns` or `dayjs` | No longer maintained |
| `request` | All versions | `axios` or `fetch` | Deprecated |
| `marked` | < 4.0.0 | `marked@^11.0.0` | XSS vulnerabilities |
| `lodash` | < 4.17.21 | `lodash-es@^4.17.21` | Prototype pollution |
| `axios` | < 1.6.0 | `axios@^1.6.2` | SSRF vulnerability |
| `vue` | 2.x | `vue@^3.3.8` | Security updates in v3 |

---

## Remediation Steps

1. **Run immediate audit**:
   ```bash
   npm audit
   npm audit fix
   ```

2. **Update critical packages**:
   ```bash
   npm update --save
   ```

3. **Install security tools**:
   ```bash
   npm install -g snyk
   snyk auth
   snyk test
   ```

4. **Setup automated scanning**:
   - Enable Dependabot in GitHub
   - Add security workflow to CI/CD
   - Configure Snyk monitoring

---

## References

- [npm Audit](https://docs.npmjs.com/cli/v8/commands/npm-audit)
- [Snyk Vulnerability Database](https://snyk.io/vuln/)
- [GitHub Security Advisories](https://github.com/advisories)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)

