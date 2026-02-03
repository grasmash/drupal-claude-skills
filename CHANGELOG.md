# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-02-04

### Added
- **Claude Code Plugin Support**: Converted repository to official Claude Code plugin format
  - Added `.claude-plugin/plugin.json` manifest
  - Added `.claude-plugin/marketplace.json` for self-hosted marketplace
  - Skills can now be installed via `claude plugin install drupal-skills@drupal-plugins`

### Changed
- **Directory Structure**: Reorganized for plugin compatibility
  - Moved `.claude/skills/` to `skills/` at repository root
  - Moved `.claude/scripts/` to `scripts/` at repository root
- **Documentation**: Updated README.md with plugin installation instructions

### Skills Included
- `drupal-at-your-fingertips` - Comprehensive Drupal patterns (50+ topics)
- `drupal-contrib-mgmt` - Composer-based module management
- `drupal-config-mgmt` - Safe configuration syncing patterns
- `drupal-ddev` - DDEV local development environment
- `ivangrynenko-cursorrules-drupal` - OWASP Top 10 security patterns

## [0.1.0] - Previous

### Added
- Initial release with 5 Drupal skills
- Manual installation via copying `.claude/skills/` directory
- Sync scripts for upstream content updates
