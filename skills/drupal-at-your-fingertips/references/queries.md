# Database Queries

**Source**: [Drupal at Your Fingertips - queries](https://drupalatyourfingertips.com/queries)
**Author**: Selwyn Polit

Quick reference for Drupal database queries with practical code examples.

---

## Core Concept

Entity queries are the primary method for database operations in Drupal. They provide an abstraction layer over SQL, are database-agnostic, and integrate with Drupal's entity system. Always use `accessCheck()` to explicitly enable or disable access checks.

## Basic Entity Query

**Standard pattern**:
```php
$storage = \Drupal::entityTypeManager()->getStorage('node');

$query = $storage->getQuery()
  ->accessCheck(FALSE)  // REQUIRED in Drupal 9.3+
  ->condition('type', 'article')
  ->condition('status', 1)
  ->sort('created', 'DESC')
  ->range(0, 10);

$nids = $query->execute();
```

**Load results**:
```php
$nids = $query->execute();

if (!empty($nids)) {
  $nodes = $storage->loadMultiple($nids);
}
```

---

## Access Checks

**REQUIRED in Drupal 9.3+**:
```php
// Disable access checks (admin/system operations)
$query->accessCheck(FALSE);

// Enable access checks (user-facing operations)
$query->accessCheck(TRUE);

// Default behavior (fails in Drupal 9.3+)
$query;  // ❌ Must explicitly set accessCheck
```

---

## Query Conditions

**Condition operators**:
| Operator | Purpose | Example |
|----------|---------|---------|
| `=` | Equals (default) | `->condition('status', 1)` |
| `<>` | Not equals | `->condition('field_text', '', '<>')` |
| `>`, `>=`, `<`, `<=` | Comparison | `->condition('field_value', 10, '>')` |
| `IN` | In array | `->condition('type', ['article', 'page'], 'IN')` |
| `NOT IN` | Not in array | `->condition('type', ['test'], 'NOT IN')` |
| `BETWEEN` | Between values | `->condition('created', [$start, $end], 'BETWEEN')` |
| `IS NULL` | Is null | `->condition('field_ref', NULL, 'IS NULL')` |
| `IS NOT NULL` | Is not null | `->condition('field_ref', NULL, 'IS NOT NULL')` |
| `CONTAINS` | Contains string | `->condition('title', 'test', 'CONTAINS')` |
| `STARTS_WITH` | Starts with | `->condition('title', 'The', 'STARTS_WITH')` |
| `ENDS_WITH` | Ends with | `->condition('title', 'End', 'ENDS_WITH')` |

**Common patterns**:
```php
// Published nodes
->condition('status', 1)

// Specific content type
->condition('type', 'article')

// Non-empty field
->condition('field_description', '', '<>')

// Multiple types
->condition('type', ['article', 'page'], 'IN')

// Field exists
->exists('field_reference')

// Field doesn't exist
->notExists('field_reference')

// Range of dates
->condition('created', $start_timestamp, '>=')
->condition('created', $end_timestamp, '<=')
```

---

## Sorting and Limiting

**Sort results**:
```php
// Single sort
->sort('created', 'DESC')
->sort('title', 'ASC')

// Multiple sorts
->sort('field_featured', 'DESC')
->sort('created', 'DESC')
```

**Limit results**:
```php
// First 10 results
->range(0, 10)

// Pagination (offset, limit)
->range(20, 10)  // Skip 20, get 10
```

**Count results**:
```php
// Get count instead of IDs
$count = $query->count()->execute();

// Check if results exist
$exists = $query->range(0, 1)->count()->execute() > 0;
```

---

## AND/OR Conditions

**AND conditions** (default):
```php
// All conditions must match
$query = $storage->getQuery()
  ->accessCheck(FALSE)
  ->condition('type', 'article')
  ->condition('status', 1);  // AND status = 1
```

**OR conditions**:
```php
$or = $query->orConditionGroup()
  ->condition('type', 'article')
  ->condition('type', 'page');

$query->condition($or);
```

**Complex AND/OR**:
```php
// (type = article OR type = page) AND status = 1
$or = $query->orConditionGroup()
  ->condition('type', 'article')
  ->condition('type', 'page');

$query->condition($or)
  ->condition('status', 1);
```

**Nested groups**:
```php
// (status = 1 AND promoted = 1) OR (sticky = 1)
$and = $query->andConditionGroup()
  ->condition('status', 1)
  ->condition('promote', 1);

$query->orConditionGroup()
  ->condition($and)
  ->condition('sticky', 1);
```

---

## Entity Reference Queries

**Query by referenced entity ID**:
```php
// Nodes that reference term ID 5
->condition('field_tags', 5)

// Nodes that reference user ID 1
->condition('field_author', 1)
```

**Query by referenced entity field**:
```php
// Query through entity reference
->condition('field_author.entity:user.uid', $uid)
->condition('field_category.entity.name', 'Technology')
```

---

## Multi-Value Field Queries

**Query specific delta** (position in multi-value field):
```php
// First value
->condition('field_items.0.value', 'test')

// Any delta
->condition('field_items.%delta.value', 'test')

// Multiple values
->condition('field_items.%delta.value', ['a', 'b'], 'IN')
```

---

## Date Queries

**Query by timestamp**:
```php
// Created after date
$start_date = strtotime('2024-01-01');
->condition('created', $start_date, '>=')

// Created between dates
->condition('created', [$start, $end], 'BETWEEN')

// Changed in last 24 hours
$yesterday = \Drupal::time()->getRequestTime() - 86400;
->condition('changed', $yesterday, '>=')
```

**DrupalDateTime example**:
```php
use Drupal\Core\Datetime\DrupalDateTime;

$date = DrupalDateTime::createFromFormat('Y-m-d', '2024-01-01');
$timestamp = $date->getTimestamp();

->condition('field_date', $timestamp, '>=')
```

---

## User Queries

**Query users**:
```php
$query = \Drupal::entityTypeManager()
  ->getStorage('user')
  ->getQuery()
  ->accessCheck(FALSE)
  ->condition('status', 1)
  ->condition('roles', 'authenticated', 'CONTAINS')
  ->sort('name', 'ASC');

$uids = $query->execute();
```

---

## Database Queries (Static)

**Static query** (direct SQL):
```php
$database = \Drupal::database();

// Simple query
$query = $database->query("SELECT nid, title FROM {node_field_data} WHERE type = :type", [
  ':type' => 'article',
]);

$results = $query->fetchAll();

foreach ($results as $row) {
  echo $row->title;
}
```

**Placeholders** (required for security):
```php
// CORRECT - Use placeholders
$query = $database->query("SELECT * FROM {node_field_data} WHERE nid = :nid", [
  ':nid' => $node_id,
]);

// WRONG - SQL injection risk
$query = $database->query("SELECT * FROM {node_field_data} WHERE nid = $node_id");  // ❌
```

---

## Database Queries (Dynamic)

**Select query**:
```php
$database = \Drupal::database();

$query = $database->select('node_field_data', 'n')
  ->fields('n', ['nid', 'title', 'created'])
  ->condition('n.type', 'article')
  ->condition('n.status', 1)
  ->orderBy('n.created', 'DESC')
  ->range(0, 10);

$results = $query->execute()->fetchAll();
```

**Join tables**:
```php
$query = $database->select('node_field_data', 'n')
  ->fields('n', ['nid', 'title'])
  ->fields('u', ['name']);

// Inner join
$query->join('users_field_data', 'u', 'n.uid = u.uid');

// Left join
$query->leftJoin('node__field_tags', 't', 'n.nid = t.entity_id');

$results = $query->execute()->fetchAll();
```

**Aggregate queries**:
```php
$query = $database->select('node_field_data', 'n');
$query->addField('n', 'type');
$query->addExpression('COUNT(nid)', 'count');
$query->groupBy('n.type');

$results = $query->execute()->fetchAll();
```

---

## Insert/Update/Delete

**Insert**:
```php
$database = \Drupal::database();

// Single insert
$database->insert('mytable')
  ->fields([
    'name' => 'Example',
    'value' => 123,
  ])
  ->execute();

// Multiple insert
$query = $database->insert('mytable')
  ->fields(['name', 'value']);

foreach ($items as $item) {
  $query->values([$item['name'], $item['value']]);
}

$query->execute();
```

**Update**:
```php
$database->update('mytable')
  ->fields(['value' => 456])
  ->condition('name', 'Example')
  ->execute();
```

**Delete**:
```php
$database->delete('mytable')
  ->condition('id', 10, '<')
  ->execute();
```

**Merge** (upsert):
```php
$database->merge('mytable')
  ->keys(['id' => 123])  // Unique key to match
  ->fields([
    'name' => 'Updated',
    'value' => 789,
  ])
  ->execute();
```

---

## Batch Processing

**Process large result sets**:
```php
$query = $storage->getQuery()
  ->accessCheck(FALSE)
  ->condition('type', 'article');

$nids = $query->execute();

// Process in batches of 100
$batches = array_chunk($nids, 100);

foreach ($batches as $batch) {
  $nodes = $storage->loadMultiple($batch);

  foreach ($nodes as $node) {
    // Process node
    $node->set('field_updated', time());
    $node->save();
  }
}
```

---

## Query Debugging

**View generated SQL**:
```php
$sql = $query->__toString();
\Drupal::logger('my_module')->notice('Query: @sql', ['@sql' => $sql]);
```

**Enable query logging** (settings.php):
```php
$databases['default']['default']['pdo'][\PDO::ATTR_ERRMODE] = \PDO::ERRMODE_EXCEPTION;
```

**Log slow queries** (MySQL):
```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log';
```

---

---

## Key Guidelines

✅ **Use accessCheck()** - Always required in Drupal 9.3+
✅ **Use entity queries** - Primary method for database operations
✅ **Use placeholders** - For SQL injection prevention
✅ **Use batch processing** - For large datasets
✅ **Use count()** - To check existence efficiently
✅ **Use range()** - For pagination
✅ **Use condition groups** - For complex AND/OR logic
✅ **Use __toString()** - For debugging queries

❌ **Don't skip accessCheck()** - Required in Drupal 9.3+
❌ **Don't concatenate SQL** - Use placeholders
❌ **Don't load all results** - Use range for large sets
❌ **Don't use static queries** - Unless necessary
❌ **Don't forget {table} syntax** - In static queries
❌ **Don't query without conditions** - Limit results
❌ **Don't use get()->execute()** - Use getQuery()->execute()

---

**Full documentation**: https://drupalatyourfingertips.com/queries
