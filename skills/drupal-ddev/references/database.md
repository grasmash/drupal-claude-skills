# DDEV Database Operations

Complete guide for database import, export, and management workflows in DDEV.

## Table of Contents

- [Import Methods](#import-methods)
- [Export Methods](#export-methods)
- [Snapshots](#snapshots)
- [Database Access](#database-access)
- [Sanitization](#sanitization)
- [Troubleshooting](#troubleshooting)

---

## Import Methods

### Method 1: DDEV Import Command (Recommended for Most Cases)

```bash
# Import compressed backup
ddev import-db --file=backup.sql.gz

# Import uncompressed SQL file
ddev import-db --file=backup.sql

# Import from URL
ddev import-db --src=https://example.com/backup.sql.gz
```

**Pros:**
- Automatic decompression (.sql.gz, .sql.zip, .tar.gz)
- Progress indicator
- Error handling
- Official DDEV command

**Cons:**
- Slightly slower than direct methods
- May have issues with very large files

### Method 2: Direct MySQL Import

```bash
# Simple and fast
ddev mysql < backup.sql

# With pipe from cat
cat backup.sql | ddev mysql

# Compressed file (decompress first)
gunzip -c backup.sql.gz | ddev mysql
```

**Pros:**
- Fast
- Simple
- Works with pipes
- Good for automation

**Cons:**
- No progress indicator
- Manual decompression needed
- Less error handling

### Method 3: Drush SQL Query

```bash
# Using Drush
ddev drush sql:query --file=backup.sql

# Short version
ddev drush sqlq --file=backup.sql
```

**Pros:**
- Drupal-native approach
- Good for Drush-based workflows
- Can be used in custom scripts

**Cons:**
- Requires Drush
- Slower than direct MySQL

### Method 4: Manual Import (Project-Specific Pattern)

**Use this when you need precise control over the import process using Drush connection parameters.**

```bash
# 1. Place SQL file in docroot so container can access it
cp /path/to/backup.sql docroot/backup.sql

# 2. Import using drush sql:connect
ddev exec "$(drush sql:connect) < docroot/backup.sql"

# 3. Clean up
rm docroot/backup.sql
```

**Why this works:**
- SQL file is placed in `docroot/` which is mounted in the container
- `$(drush sql:connect)` expands to the mysql connection command with all parameters
- `ddev exec` runs the command inside the container where it can access the file
- The `<` redirect happens inside the container context

**When to use:**
- You need to use Drush's database connection settings
- Working with project-specific database configurations
- Debugging connection issues
- Custom backup workflows

**Common variations:**
```bash
# Import and run specific queries after
ddev exec "$(drush sql:connect) < docroot/backup.sql && drush sqlq 'UPDATE system SET status=1'"

# Import with verbose output
ddev exec "bash -c '$(drush sql:connect) < docroot/backup.sql'"
```

---

## Export Methods

### DDEV Export Command

```bash
# Export to compressed file
ddev export-db --file=backup.sql.gz

# Export uncompressed
ddev export-db --file=backup.sql

# Export with gzip compression
ddev export-db --gzip=false --file=backup.sql
```

### Direct MySQL Export

```bash
# Export using mysqldump
ddev mysqldump > backup.sql

# Export compressed
ddev mysqldump | gzip > backup.sql.gz

# Export with Drush
ddev drush sql:dump --result-file=../backup.sql
ddev drush sql:dump --gzip --result-file=../backup.sql.gz
```

### Export Specific Tables

```bash
# Export only specific tables
ddev mysqldump database_name table1 table2 > backup.sql

# Export structure only (no data)
ddev mysqldump --no-data > structure.sql

# Export data only (no structure)
ddev mysqldump --no-create-info > data.sql
```

---

## Snapshots

Database snapshots are quick backups you can restore later.

### Create Snapshot

```bash
# Create named snapshot
ddev snapshot --name=before-testing

# Create snapshot with auto-generated name
ddev snapshot
```

### List Snapshots

```bash
# List all snapshots for current project
ddev snapshot --list

# Show with details
ddev snapshot --list --all
```

### Restore Snapshot

```bash
# Restore specific snapshot
ddev snapshot restore --name=before-testing

# Restore latest snapshot
ddev snapshot restore --latest
```

### Delete Snapshots

```bash
# Delete specific snapshot
ddev snapshot --cleanup --name=before-testing

# Delete all snapshots for current project
ddev snapshot --cleanup --all
```

### Snapshot Workflow Example

```bash
# Before making risky changes
ddev snapshot --name=before-module-update

# Make changes, test...
ddev composer require drupal/some_module
ddev drush updb -y

# If something breaks, restore
ddev snapshot restore --name=before-module-update

# If everything works, clean up old snapshot
ddev snapshot --cleanup --name=before-module-update
```

---

## Database Access

### MySQL CLI

```bash
# Open MySQL CLI
ddev mysql

# Run SQL query from command line
ddev mysql -e "SELECT COUNT(*) FROM users"

# Use Drush
ddev drush sqlc
```

### MySQL Connection Details

```bash
# Get connection string
ddev drush sql:connect

# Example output:
# mysql --database=db --host=db --user=db --password=db

# Get connection info as JSON
ddev describe
```

### Access from Host Machine

```bash
# Get connection details
ddev describe

# Connect from host using displayed port
mysql -h 127.0.0.1 -P 32768 -u db -pdb db
```

---

## Sanitization

Clean sensitive data for local development.

### Using Drush SQL Sanitize

```bash
# Sanitize all user emails and passwords
ddev drush sql:sanitize -y

# Custom sanitization
ddev drush sqlq "UPDATE users_field_data SET mail = CONCAT('user', uid, '@example.com') WHERE uid > 0"

# Reset all user passwords
ddev drush sqlq "UPDATE users_field_data SET pass = '\$S\$D7...' WHERE uid > 0"
```

### Sanitization Script Example

Create `.ddev/commands/web/sanitize-db`:

```bash
#!/bin/bash
## Description: Sanitize database for local development
## Usage: sanitize-db
## Example: ddev sanitize-db

set -e

echo "Sanitizing database..."

# Sanitize emails
drush sqlq "UPDATE users_field_data SET mail = CONCAT('user', uid, '@localhost.local') WHERE uid > 0"

# Reset all user passwords to 'admin'
drush sqlq "UPDATE users_field_data SET pass = '\$S\$D7p6QjHXHq6Qw6.N5Q5Q5Q5Q5Q5Q5Q5Q5Q' WHERE uid > 0"

# Clear sessions
drush sqlq "TRUNCATE sessions"

# Clear cache
drush cr

echo "Sanitization complete!"
echo "All user passwords reset to: admin"
```

Make executable:
```bash
chmod +x .ddev/commands/web/sanitize-db
ddev sanitize-db
```

---

## Troubleshooting

### Import Fails with "Access Denied"

```bash
# Check database credentials
ddev describe

# Verify settings.php or settings.ddev.php exists
ddev ssh
cat web/sites/default/settings.ddev.php

# Restart database
ddev restart
```

### Import is Very Slow

```bash
# Use direct MySQL import instead of ddev import-db
gunzip -c backup.sql.gz | ddev mysql

# Or use pv for progress
pv backup.sql.gz | gunzip | ddev mysql

# Increase database resources in .ddev/mysql/my.cnf
[mysqld]
innodb_buffer_pool_size = 1G
max_allowed_packet = 512M
```

### "Table doesn't exist" after import

```bash
# Verify import completed successfully
ddev mysql -e "SHOW TABLES"

# Check for errors during import
ddev logs | grep -i error

# Try re-importing
ddev mysql -e "DROP DATABASE db; CREATE DATABASE db"
ddev import-db --file=backup.sql.gz
```

### Database is too large

```bash
# Import only structure first
ddev mysqldump --no-data db > structure.sql
ddev mysql < structure.sql

# Then import data for specific tables
ddev mysqldump db important_table1 important_table2 > critical_data.sql
ddev mysql < critical_data.sql

# Skip large cache/log tables
ddev import-db --file=backup.sql.gz
ddev mysql -e "TRUNCATE cache_bootstrap"
ddev mysql -e "TRUNCATE cache_render"
ddev mysql -e "TRUNCATE watchdog"
```

### "Commands out of sync" error

```bash
# Usually caused by multiple queries in single transaction
# Split your SQL file or import in smaller chunks

# Or disable multi-query
ddev mysql --init-command="SET SESSION sql_mode=''" < backup.sql
```

---

## Best Practices

1. **Use snapshots before risky operations** - Quick rollback if needed
2. **Compress large backups** - Save disk space and transfer time
3. **Sanitize production data** - Never work with real user emails/passwords locally
4. **Regular backups** - Before major updates or deployments
5. **Clean up old snapshots** - They consume disk space
6. **Test imports** - Verify data integrity after import
7. **Document custom workflows** - Create project-specific commands
8. **Use .gitignore** - Never commit database dumps to git

---

## Related References

- [Drush Commands](drush.md) - Drush database commands
- [Config YAML](config-yaml.md) - Database configuration
- [Custom Commands](custom-commands.md) - Create custom database scripts

**Official DDEV Documentation:**
- https://ddev.readthedocs.io/en/stable/users/usage/database-management/
- https://ddev.readthedocs.io/en/stable/users/usage/snapshots/
