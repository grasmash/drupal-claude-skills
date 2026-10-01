---
name: ivangrynenko-cursorrules-drupal
description: "Drupal security and coding rules from Ivan Grynenko's cursorrules, organised by OWASP Top 10 (2021) category: authentication, access control, injection (SQL, XSS), cryptographic failures, security misconfiguration, vulnerable dependencies, SSRF, insecure design, integrity, and logging, plus database standards and file permissions. Use when writing or reviewing Drupal code for security, handling user input, building queries, handling file uploads, adding permission or access checks, making outbound HTTP requests, or preparing a security review."
---

# Ivan Grynenko - Drupal Cursor Rules

**Source**: [Ivan Grynenko - Cursor Rules](https://github.com/ivangrynenko/cursorrules)
**Author**: Ivan Grynenko
**License**: MIT

## When This Skill Activates

Activates when working with Drupal security topics including:
- Authentication and session management
- Access control and permissions
- SQL injection and XSS prevention
- Cryptography and data protection
- Security configuration
- Dependency management
- SSRF prevention
- Secure design patterns
- Software integrity
- Security logging and monitoring

---

## Available Topics

All topics are available as references in the `/references/` directory.

Each reference contains:
- OWASP classification and reference
- Security patterns and anti-patterns
- Enforcement checks
- Code examples
- Best practices

### OWASP Top 10 Coverage

- @references/authentication-security.md - Authentication failures (A07:2021)
- @references/access-control-security.md - Broken access control (A01:2021)
- @references/injection-prevention.md - Injection vulnerabilities (A03:2021)
- @references/data-security.md - Cryptographic failures (A02:2021)
- @references/security-configuration.md - Security misconfiguration (A05:2021)
- @references/dependency-security.md - Vulnerable components (A06:2021)
- @references/ssrf-prevention.md - Server-side request forgery (A10:2021)
- @references/secure-design.md - Insecure design (A04:2021)
- @references/integrity-validation.md - Software integrity failures (A08:2021)
- @references/logging-security.md - Logging and monitoring failures (A09:2021)

### Additional Security Topics

- @references/database-standards.md - Database best practices
- @references/file-permissions.md - File security and access control

See `/references/` directory for complete list.

---

---

**To update**: Run `.claude/scripts/sync-ivan-rules.sh`
