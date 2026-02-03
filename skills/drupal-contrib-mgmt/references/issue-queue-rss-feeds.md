# Drupal Issue Queue RSS Feeds

## Quick Access to Issue Information

Issue queues provide RSS feeds for automated monitoring and searching.

## RSS Feed URL Pattern

**Base Pattern**:
```
https://www.drupal.org/project/issues/rss/MODULE_NAME?params
```

**Examples**:
```
https://www.drupal.org/project/issues/rss/audiofield
https://www.drupal.org/project/issues/rss/entity_limit
https://www.drupal.org/project/issues/rss/views
```

## Query Parameters

### Complete Parameter Set

```
https://www.drupal.org/project/issues/rss/MODULE_NAME?text=SEARCH&status=STATUS&priorities=PRIORITY&categories=CATEGORY&version=VERSION&component=COMPONENT
```

### Parameter Options

**text**: Free-text search
- Example: `text=deprecated`
- Example: `text=Drupal+11`

**status**: Issue status filter
- `Open` - Active issues
- `Fixed` - Resolved issues
- `Closed` - Closed issues
- `Active` - Open or needs review
- `Needs+review` - Waiting for review
- `Needs+work` - Needs additional work
- `Reviewed+%26+tested+by+the+community` - RTBC (ready to commit)
- `All` - All statuses

**priorities**: Priority level
- `1` - Critical
- `2` - Major
- `3` - Normal
- `4` - Minor
- `All` - All priorities

**categories**: Issue type
- `1` - Bug report
- `2` - Task
- `3` - Feature request
- `4` - Support request
- `5` - Plan
- `All` - All categories

**version**: Module version
- Example: `8.x-1.x`
- Example: `2.0.x`
- `All` - All versions

**component**: Module component (if applicable)
- Varies by module
- `All` - All components

## Practical Examples

### Find Drupal 11 Compatibility Issues

```
https://www.drupal.org/project/issues/rss/audiofield?text=Drupal+11&status=All&priorities=All&categories=All&version=All&component=All
```

### Find Active Deprecation Issues

```
https://www.drupal.org/project/issues/rss/entity_limit?text=deprecated&status=Open&priorities=All&categories=1&version=All&component=All
```

### Find RTBC (Ready to Commit) Issues

```
https://www.drupal.org/project/issues/rss/licensing?text=&status=Reviewed+%26+tested+by+the+community&priorities=All&categories=All&version=All&component=All
```

### Find Recently Fixed Issues

```
https://www.drupal.org/project/issues/rss/social_auth?text=&status=Fixed&priorities=All&categories=All&version=All&component=All
```

## Using RSS Feeds Programmatically

### Fetch with curl

```bash
# Fetch issues as XML
curl "https://www.drupal.org/project/issues/rss/audiofield?text=deprecated&status=All" > audiofield-issues.xml

# Parse with grep for quick search
curl -s "https://www.drupal.org/project/issues/rss/audiofield?text=Drupal+11" | grep -o '<title>.*</title>' | sed 's/<[^>]*>//g'
```

### Fetch with WebFetch (Claude Code)

```javascript
// Use WebFetch tool to analyze RSS feed
const url = "https://www.drupal.org/project/issues/rss/audiofield?text=Drupal+11&status=All";
const prompt = "List all issues related to Drupal 11 compatibility with their status";
```

### Parse with xmllint

```bash
# Get issue titles and links
curl -s "https://www.drupal.org/project/issues/rss/audiofield?text=deprecated" | \
  xmllint --xpath "//item/title/text()" -

# Get issue descriptions
curl -s "https://www.drupal.org/project/issues/rss/audiofield" | \
  xmllint --xpath "//item/description/text()" -
```

## RSS Feed Structure

RSS feeds contain:

**item**: Each issue
- **title**: Issue title
- **link**: Issue URL (drupal.org/node/NODEID)
- **description**: Issue description/summary
- **pubDate**: Publication date
- **dc:creator**: Issue creator
- **guid**: Unique identifier

**Example XML**:
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>audiofield issues</title>
    <item>
      <title>Replace deprecated file_validate_extensions()</title>
      <link>https://www.drupal.org/node/3432063</link>
      <description>The function file_validate_extensions() is deprecated...</description>
      <pubDate>Wed, 15 Jun 2024 14:23:00 +0000</pubDate>
      <dc:creator>username</dc:creator>
      <guid>https://www.drupal.org/node/3432063</guid>
    </item>
  </channel>
</rss>
```

## Common Search Patterns

### Finding Patches for Your Version

```bash
# Search for issues on specific version
MODULE="audiofield"
VERSION="8.x-1.x"
curl "https://www.drupal.org/project/issues/rss/${MODULE}?version=${VERSION}&status=Active"
```

### Monitor Critical Issues

```bash
# Get critical bugs
MODULE="entity_limit"
curl "https://www.drupal.org/project/issues/rss/${MODULE}?priorities=1&categories=1&status=Open"
```

### Find Deprecated Function Issues

```bash
# Search for specific deprecated function
FUNCTION="user_roles"
MODULE="licensing"
curl "https://www.drupal.org/project/issues/rss/${MODULE}?text=${FUNCTION}"
```

## Automated Monitoring Script

```bash
#!/bin/bash
# monitor-module-issues.sh
# Check for new Drupal 11 issues

MODULES=("audiofield" "entity_limit" "licensing" "social_auth")
SEARCH="Drupal+11"

for MODULE in "${MODULES[@]}"; do
  echo "Checking $MODULE for Drupal 11 issues..."

  RSS_URL="https://www.drupal.org/project/issues/rss/${MODULE}?text=${SEARCH}&status=Active"

  # Fetch and display issue titles
  curl -s "$RSS_URL" | \
    grep -o '<title>.*</title>' | \
    sed 's/<[^>]*>//g' | \
    tail -n +2  # Skip channel title

  echo "---"
done
```

## Tips for Effective RSS Usage

1. **Bookmark specific searches**: Save frequently used RSS URLs
2. **Use RSS readers**: Feedly, Inoreader for monitoring
3. **Automate checks**: Cron jobs to check for new issues
4. **Filter by date**: Add `&created=` parameter for recent issues
5. **Combine with curl**: Quick command-line checks

## Limitations

- RSS feeds show limited results (typically 25-50 latest)
- No advanced filtering (e.g., AND/OR logic)
- Some metadata not included in RSS
- For comprehensive search, use web interface

## Web Interface URLs

**Standard URL**:
```
https://www.drupal.org/project/issues/MODULE_NAME?text=&status=All&priorities=All&categories=All&version=All&component=All&page=1
```

**Parameters match RSS** but with pagination:
- `page=0` - First page
- `page=1` - Second page
- etc.

## Quick Reference Commands

```bash
# Get all open issues
curl "https://www.drupal.org/project/issues/rss/MODULE?status=Open"

# Get deprecated function issues
curl "https://www.drupal.org/project/issues/rss/MODULE?text=deprecated"

# Get D11 compatibility
curl "https://www.drupal.org/project/issues/rss/MODULE?text=Drupal+11"

# Get RTBC issues (ready for patches)
curl "https://www.drupal.org/project/issues/rss/MODULE?status=Reviewed+%26+tested"

# Count issues
curl -s "https://www.drupal.org/project/issues/rss/MODULE" | grep -c "<item>"
```

## Integration with Workflow

When searching for patches:

1. **Start with RSS feed** for quick overview
2. **Use text search** for specific deprecations
3. **Filter by status** to find RTBC patches
4. **Visit web interface** for detailed patch files
5. **Download patches** from individual issue nodes

Example workflow:
```bash
# 1. Find issues
curl "https://www.drupal.org/project/issues/rss/audiofield?text=file_validate_extensions" | \
  grep -o '<link>.*</link>' | sed 's/<[^>]*>//g'

# Output: https://www.drupal.org/node/3432063

# 2. Visit issue page to find patches
# 3. Apply patch via composer (see drupal-patches-workflow.md)
```
