---
name: drupal-mail
description: Drupal mail system configuration for local testing (Mailpit) and production (Mailchimp Transactional). Covers HTML email rendering, Content-Type headers, sender/formatter plugins, and troubleshooting. Use when testing emails locally, debugging email issues, or configuring mail delivery.
---

# Drupal Mail System Configuration

## Quick Reference

### Local Testing (DDEV Mailpit)

**Working configuration for HTML emails in Mailpit:**
```yaml
# mailsystem.settings
defaults:
  sender: php_mail
  formatter: mailchimp_transactional_mail
```

**Enable/disable notifications:**
```bash
# Check if notifications are disabled
ddev drush state:get my_notifications.disabled

# Enable notifications (for local testing)
ddev drush state:set my_notifications.disabled 0

# Disable notifications (to stop local emails)
ddev drush state:set my_notifications.disabled 1
```

**View Mailpit:**
- URL: https://<project>.ddev.site:8026
- Or run: `ddev mailpit`

### Production Configuration

**Mailchimp Transactional (Mandrill) for sending:**
```yaml
# mailsystem.settings
defaults:
  sender: mailchimp_transactional_mail
  formatter: mailchimp_transactional_mail
```

## Mail System Architecture

### Key Concepts

1. **Sender**: The plugin that actually sends the email (SMTP, PHP mail(), API)
2. **Formatter**: The plugin that formats the email body (converts HTML, wraps content)
3. **Content-Type Header**: Must be set to `text/html` for HTML rendering

### Plugin Combinations

| Environment | Sender | Formatter | HTML Works? | Notes |
|------------|--------|-----------|-------------|-------|
| Local (Mailpit) | `php_mail` | `mailchimp_transactional_mail` | Yes | Recommended for local testing |
| Local (Mailpit) | `php_mail` | `php_mail` | No | Strips HTML to plain text |
| Production | `mailchimp_transactional_mail` | `mailchimp_transactional_mail` | Yes | Uses Mandrill API |
| Production | `symfony_mailer` | `symfony_mailer` | Yes | Requires SMTP config |

## HTML Email Requirements

### Content-Type Header

**Critical**: Module must set Content-Type header in `hook_mail_alter()`:

```php
/**
 * Implements hook_mail_alter().
 */
function my_notifications_mail_alter(&$message) {
  if ($message['module'] === 'my_notifications') {
    $message['headers']['Content-Type'] = 'text/html; charset=UTF-8';
  }
}
```

Without this, HTML renders as plain text even with correct formatter.

### Message Template Format

**Config entity format** (`message.template.*.yml`):
```yaml
text:
  -
    value: |-
      Subject line with [tokens]

      <p style="margin: 0 0 16px 0; color: #333;">HTML body content</p>
    format: full_html
```

**Key points:**
- First line = email subject (extracted, stripped of HTML)
- Rest = HTML email body
- Use inline styles (email clients strip `<style>` tags)
- `format: full_html` enables HTML rendering

## Configuration Commands

### Check Current Config

```bash
# View mail system settings
ddev drush cget mailsystem.settings

# View notification plugin settings
ddev drush cget my_notifications.settings

# Check global disable state
ddev drush state:get my_notifications.disabled
```

### Switch Between Local and Production

**For local testing:**
```bash
# Enable HTML email capture in Mailpit
ddev drush cset mailsystem.settings defaults.sender php_mail -y
ddev drush cset mailsystem.settings defaults.formatter mailchimp_transactional_mail -y
ddev drush state:set my_notifications.disabled 0
ddev drush cr
```

**Reset to production:**
```bash
ddev drush cset mailsystem.settings defaults.sender mailchimp_transactional_mail -y
ddev drush cset mailsystem.settings defaults.formatter mailchimp_transactional_mail -y
ddev drush state:set my_notifications.disabled 1
ddev drush cr
```

## Testing Notifications

### Test Commands

Give your notification module drush test commands so each template can be fired on demand, e.g.:

```bash
# Test entity deleted notification
ddev drush my-notifications:test-entity-deleted

# Test entity updated notification
ddev drush my-notifications:test-entity-updated

# Test comment notification
ddev drush my-notifications:test-comment

# Test group invitation
ddev drush my-notifications:test-invitation
```

### Verify Email in Mailpit

1. Open https://<project>.ddev.site:8026
2. Check **Headers** tab: `Content-Type: text/html; charset=UTF-8`
3. Check **HTML** tab: Proper styled rendering
4. Check **Text** tab: Plain text fallback

### Mailpit API

```bash
# List recent messages
curl -sk "https://<project>.ddev.site:8026/api/v1/messages" | jq '.messages[:3]'

# Get specific message with HTML
curl -sk "https://<project>.ddev.site:8026/api/v1/message/{ID}" | jq '{Subject, HTML}'

# Delete all messages
curl -sk -X DELETE "https://<project>.ddev.site:8026/api/v1/messages"
```

## Troubleshooting

### No Emails Appearing

1. **Check global disable state:**
   ```bash
   ddev drush state:get my_notifications.disabled
   # If TRUE, run: ddev drush state:set my_notifications.disabled 0
   ```

2. **Check sender plugin:**
   ```bash
   ddev drush cget mailsystem.settings defaults.sender
   # For Mailpit: should be php_mail
   ```

3. **Check DDEV is running:**
   ```bash
   ddev describe | grep -i mail
   ```

4. **Test raw PHP mail:**
   ```bash
   ddev exec "php -r \"mail('test@example.com', 'Test', 'Body');\""
   # Should appear in Mailpit immediately
   ```

### HTML Not Rendering (Shows Raw Tags)

1. **Check formatter plugin:**
   ```bash
   ddev drush cget mailsystem.settings defaults.formatter
   # Should be mailchimp_transactional_mail for HTML
   ```

2. **Check Content-Type header in hook_mail_alter():**
   ```bash
   grep -r "Content-Type.*text/html" web/modules/custom/
   ```

3. **Check template format:**
   ```bash
   grep "format:" config/default/message.template.*.yml
   # Should show: format: full_html
   ```

### Emails Sending to Production

1. **Check sender plugin:**
   ```bash
   ddev drush cget mailsystem.settings defaults.sender
   # If mailchimp_transactional_mail, emails go to real addresses!
   ```

2. **Switch to local capture:**
   ```bash
   ddev drush cset mailsystem.settings defaults.sender php_mail -y
   ```

## Module Dependencies

- **mailsystem**: Routes mail through configured plugins
- **mailchimp_transactional**: Provides Mandrill integration
- **message**: Provides template-based message entities
- **my_notifications**: Custom notification system

## File Locations

- Mail config: `config/default/mailsystem.settings.yml`
- Notification settings: `config/default/my_notifications.settings.yml`
- Message templates: `config/default/message.template.*.yml`
- Notification processor: `web/modules/custom/my_notifications/src/Plugin/QueueWorker/NotificationProcessor.php`
- Mail alter hook: `web/modules/custom/my_notifications/my_notifications.module`

## Apply to Files
- `config/default/mailsystem.settings.yml`
- `config/default/my_notifications.settings.yml`
- `config/default/message.template.*.yml`
- `web/modules/custom/my_notifications/**/*.php`
- `web/modules/custom/my_notifications/*.module`
