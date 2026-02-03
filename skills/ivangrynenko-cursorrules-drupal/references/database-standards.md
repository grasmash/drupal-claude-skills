# Drupal Database Standards

**Source**: [Ivan Grynenko - drupal-database-standards.mdc](https://github.com/ivangrynenko/cursorrules/blob/main/.cursor/rules/drupal-database-standards.mdc)
**Author**: Ivan Grynenko
**License**: MIT
**OWASP Reference**: 

---

## Full Documentation

**View online**: https://github.com/ivangrynenko/cursorrules/blob/main/.cursor/rules/drupal-database-standards.mdc

This security pattern covers:
- OWASP Top 10 classification
- Common vulnerabilities and anti-patterns
- Enforcement checks for code review
- Secure coding examples
- Best practices and remediation

---

## Raw Content

```markdown
---
description: Database schema changes, migrations, and query optimization
globs: *.php, *.install, *.module
---
# Drupal Database Standards

Ensures proper database handling in Drupal applications.

## Rule Details

- **Name:** drupal_database_standards

- **Description:** Enforce Drupal database best practices and standards

## Filters
- file extension pattern: `\\.(php|install|module)$`

## Enforcement Checks
- Conditions:
  - pattern `db_query` – Use Database API instead of db_query
  - pattern `hook_update_N.*\\{\\s*[^}]*\\}` – Ensure hook_update_N includes proper schema changes
  - pattern `\\$query->execute\\(\\)` – Consider using try-catch block for database operations

## Suggestions
- Guidance:
Database Best Practices:
- Use Schema API for table definitions
- Implement proper error handling
- Use update hooks for schema changes
- Follow Drupal's database abstraction layer
- Implement proper indexing strategies

## Metadata
- Priority: critical
- Version: 1.1

 
```

---

---

**Last verified**: 2025-10-31
