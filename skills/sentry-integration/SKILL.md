---
name: sentry-integration
description: Sentry error monitoring integration for a Drupal site. Use when analyzing Sentry issues, debugging production errors, investigating N+1 queries, adding comments to issues, documenting error analysis, or working with performance monitoring. Covers MCP tools, the comment API, common issue patterns, and the raven module's performance-tracing gotchas.
---

# Sentry Integration

## Overview

This skill covers using Sentry for error tracking and performance monitoring on a
Drupal site:
- Reading issues via Sentry MCP tools
- Adding comments via the REST API (MCP can't add comments)
- Common issue patterns and analysis

## Organization Details

- **Org**: `<your-sentry-org-slug>`
- **Region URL**: `https://us.sentry.io` (or your region)
- **Web URL**: https://\<your-sentry-org-slug\>.sentry.io

## Reading Issues (MCP Tools)

### Get Issue Details

```
mcp__sentry__get_issue_details
  organizationSlug: "<org-slug>"
  issueId: "<numeric-id>"  # numeric ID from URL
  regionUrl: "https://us.sentry.io"
```

### Search Issues

```
mcp__sentry__search_issues
  organizationSlug: "<org-slug>"
  query: "is:unresolved"
  regionUrl: "https://us.sentry.io"
```

### Update Issue Status

```
mcp__sentry__update_issue
  organizationSlug: "<org-slug>"
  issueId: "<PROJECT-123>"
  status: "ignored"  # or "resolved", "unresolved"
  regionUrl: "https://us.sentry.io"
```

## Adding Comments (REST API)

**MCP tools cannot add comments** — use the REST API directly (wrap it in a small
project script if you do this often):

```bash
curl -sS -X POST \
  "https://us.sentry.io/api/0/issues/<numeric_issue_id>/comments/" \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"text": "**Analysis**: N+1 query from Flag module.\n\nRoot cause: flaggings_current_user computed fields require per-entity lookups.\n\n**Impact**: Minimal (349ms total).\n\n**Verdict**: Safe to ignore - known pattern with Flag module + JSON:API."}'
```

### Getting the Numeric Issue ID

From URL: `https://<your-sentry-org-slug>.sentry.io/issues/<numeric-id>/`

### Authentication

Read the token from (in order):
1. `SENTRY_AUTH_TOKEN` environment variable
2. `~/.sentry/auth_token` file
3. Project `.env` file (never committed)

### Token Setup (One-Time)

1. Go to https://sentry.io/settings/account/api/auth-tokens/
2. Create token with scopes: `event:read`, `event:write`, `org:read`, `project:read`
3. Save: `mkdir -p ~/.sentry && echo 'your-token' > ~/.sentry/auth_token && chmod 600 ~/.sentry/auth_token`

## Common Issue Patterns

### N+1 Queries (Performance)

**Type**: `performance_n_plus_one_db_queries`
**Level**: info (not error)

**Common causes in Drupal apps**:
1. **Flag module** - COUNT queries for `flaggings_current_user`/`flag_counts_entity`
2. **Group module** - Relationship lookups by UUID
3. **JSON:API includes** - Related entity loading

**Analysis template**:
```
**Analysis**: N+1 query from [module] - [severity].

Query pattern: [describe the repeated query]

**Root cause**: [why it happens]

**Impact**: [response time, occurrences]

**Options if optimization needed**:
1. [option 1]
2. [option 2]

**Verdict**: [safe to ignore / needs attention / priority]
```

### PHP Errors

**Common types**:
- `TypeError` - Type mismatch
- `ArgumentCountError` - Wrong number of arguments
- `Deprecated` - PHP 8.x deprecations

### Database Errors

**Common types**:
- Connection timeouts
- Deadlocks
- Query timeouts

## Workflow: Analyzing a Sentry Issue

1. **Get issue details** via MCP tool
2. **Identify type**: error vs performance
3. **Check occurrences**: 1 vs many
4. **Analyze root cause**
5. **Document finding**: add comment via the REST API
6. **Update status**: ignore/resolve if appropriate

## Performance Tracing & Profiling (Raven config)

Backend tracing is provided by the `raven` module (Drupal Sentry SDK). Config in your exported `raven.settings.yml`; env-specific overrides in `settings.php`. Hard-won gotchas:

- **`trace` is NOT the performance switch — leave it `false`.** It is "Reflection tracing in stacktraces": `true` removes raven's `RemoveExceptionFrameVarsIntegration` scrubber (`Raven.php:103`) and sends **function-call arguments** (passwords/tokens/PII) to Sentry. Security review flags `trace: true` HIGH. Don't enable it in committed config.
- **Performance tracing is applied unconditionally** (`Raven.php:116`, `traces_sample_rate`), independent of `trace` — `database_tracing` / `twig_tracing` / `request_tracing` too. BUT it is **gated by the `send performance traces to sentry` permission** (form: "if user has the … permission, excluding page-cache hits"). If **no role grants it, ZERO requests are traced** despite the sample rate. To collect backend traces, grant that permission to a role (start with `administrator` for controlled, low-cost staff traces; widen to `authenticated` for representative real-user data — at the cost of Sentry quota + tracing real sessions). Anonymous page-cache hits are never traced.
- **Environment** is set per-env in `settings.php` (`$config['raven.settings']['environment'] = ...` → prod/stage/dev). Don't put it in committed config (leave it `''` there).
- **Release**: set in `settings.php` from `SENTRY_RELEASE` env var (e.g. a CI-set git SHA for suspect-commit linking) or an equivalent per-deploy identifier from your hosting platform. Blank `release` = no deploy correlation.
- **Profiling (function flamegraphs) needs the Excimer PECL extension** — `pecl install excimer`. Some managed hosting platforms (e.g. Pantheon) can't install custom PECL extensions, so Sentry Profiling is unavailable there (the raven form disables the profiles field when `!extension_loaded('excimer')`). Tracing **spans** (DB/Twig/render breakdown per transaction) are the substitute on those platforms; check whether your host offers a native deep-profiling APM as an alternative.

## Related Skills

- `drupal-performance` - Performance optimization patterns
