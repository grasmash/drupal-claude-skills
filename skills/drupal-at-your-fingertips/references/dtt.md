# Drupal Test Traits (DTT)

**Source**: [Drupal at Your Fingertips - dtt](https://drupalatyourfingertips.com/dtt)
**Author**: Selwyn Polit

Quick reference for Drupal Test Traits (DTT) with practical code examples.

---

## Core Concept

DTT enables fast functional testing against existing Drupal sites without database recreation. Tests use real site data and run significantly faster than traditional PHPUnit tests.

## Installation

**Composer dependencies**:
```bash
composer require weitzman/drupal-test-traits:^2 --dev
composer require drupal/core-dev --dev --update-with-all-dependencies
composer require weitzman/logintrait --dev
```

---

## ExistingSite Test Structure

**Basic test** (tests/src/ExistingSite/ExampleTest.php):
```php
namespace Drupal\Tests\my_module\ExistingSite;

use weitzman\DrupalTestTraits\ExistingSiteBase;

class ExampleTest extends ExistingSiteBase {

  public function testBasicFunctionality() {
    // Test code here
    $this->assertTrue(TRUE);
  }
}
```

**Run tests**:
```bash
vendor/bin/phpunit docroot/modules/custom/my_module/tests/
```

---

## Entity Creation & Cleanup

**DTT automatically cleans up created entities**:
```php
public function testNodeCreation() {
  // Create node
  $node = $this->createNode([
    'type' => 'article',
    'title' => 'Test Article',
    'status' => 1,
  ]);

  $this->assertEquals('Test Article', $node->getTitle());

  // Node auto-deleted after test
}
```

**Create user**:
```php
public function testUserCreation() {
  $user = $this->createUser(
    ['access content'],  // Permissions
    'testuser'          // Username
  );

  $this->assertEquals('testuser', $user->getAccountName());
}
```

---

## User Authentication

**Login as existing user**:
```php
public function testAsAuthenticatedUser() {
  $user = User::load(1);
  $user->passRaw = 'admin';  // Required for login
  $this->drupalLogin($user);

  $this->drupalGet('/admin/config');
  $this->assertSession()->statusCodeEquals(200);
}
```

**Login as new user**:
```php
public function testAsNewUser() {
  $user = $this->createUser(['access content']);
  $this->drupalLogin($user);

  $this->drupalGet('/node/add/article');
  $this->assertSession()->statusCodeEquals(403);
}
```

---

## Page Navigation & Assertions

**Navigate and verify**:
```php
public function testPageAccess() {
  $this->drupalGet('/node/1');
  $this->assertSession()->statusCodeEquals(200);
  $this->assertSession()->pageTextContains('Expected text');
  $this->assertSession()->pageTextNotContains('Unexpected text');
}
```

**Form submission**:
```php
public function testFormSubmission() {
  $this->drupalGet('/user/login');

  $this->submitForm([
    'name' => 'admin',
    'pass' => 'password',
  ], 'Log in');

  $this->assertSession()->addressEquals('/user/1');
}
```

---

## JavaScript Tests

**ExistingSiteJavascript** (for AJAX, modals, dynamic content):
```php
use weitzman\DrupalTestTraits\ExistingSiteSelenium2DriverTestBase;

class JavascriptTest extends ExistingSiteSelenium2DriverTestBase {

  public function testAjaxInteraction() {
    $this->drupalGet('/my-ajax-page');

    $page = $this->getSession()->getPage();
    $page->clickLink('Load More');

    // Wait for AJAX
    $this->assertSession()->assertWaitOnAjaxRequest();

    $this->assertSession()->pageTextContains('New content');
  }
}
```

---

## Common Assertions

| Method | Purpose |
|--------|---------|
| `statusCodeEquals(200)` | Check HTTP status |
| `page TextContains('text')` | Verify text on page |
| `pageTextNotContains('text')` | Ensure text absent |
| `addressEquals('/path')` | Check current URL |
| `fieldValueEquals('name', 'value')` | Check form field |
| `buttonExists('label')` | Verify button presence |
| `linkExists('label')` | Verify link presence |

---

## Data Providers

**Run same test with multiple datasets**:
```php
public function providerTestData(): array {
  return [
    ['article', 200],
    ['page', 200],
    ['nonexistent', 404],
  ];
}

/**
 * @dataProvider providerTestData
 */
public function testContentTypes(string $type, int $expected_status) {
  $this->drupalGet("/node/add/$type");
  $this->assertSession()->statusCodeEquals($expected_status);
}
```

---

## Debugging

**Capture HTML output**:
```php
public function testWithDebug() {
  $this->drupalGet('/problematic-page');

  // Save HTML to browser_output directory
  $this->capturePageContent();

  $this->assertSession()->statusCodeEquals(200);
}
```

**Screenshot (JavaScript tests)**:
```php
use weitzman\DrupalTestTraits\ScreenShotTrait;

public function testWithScreenshot() {
  $this->drupalGet('/page');

  // Save screenshot
  $this->captureScreenshot();

  $this->assertSession()->statusCodeEquals(200);
}
```

**Configure output directory** (phpunit.xml):
```xml
<env name="DTT_HTML_OUTPUT_DIRECTORY" value="sites/simpletest/browser_output"/>
```

---

---

## phpunit.xml Configuration

**Required environment variables**:
```xml
<phpunit>
  <php>
    <env name="DTT_BASE_URL" value="https://example.ddev.site"/>
    <env name="DTT_MINK_DRIVER_ARGS" value='["chrome", {"browserName": "chrome"}, "http://chromedriver:4444/wd/hub"]'/>
    <env name="DTT_HTML_OUTPUT_DIRECTORY" value="sites/simpletest/browser_output"/>
  </php>

  <testsuites>
    <testsuite name="existing-site">
      <directory>./docroot/modules/custom/*/tests/src/ExistingSite</directory>
    </testsuite>
  </testsuites>
</phpunit>
```

---

## Key Guidelines

✅ **Use ExistingSite for API tests** - Faster, no JavaScript needed
✅ **Use ExistingSiteJavascript for AJAX** - Browser automation
✅ **Let DTT clean up** - Entities auto-deleted after tests
✅ **Test with real data** - Use actual site content
✅ **Use data providers** - Test multiple scenarios
✅ **Capture debugging output** - HTML/screenshots for failures
✅ **Test permissions** - Verify access control

❌ **Don't manually delete entities** - DTT handles cleanup
❌ **Don't recreate test database** - DTT uses existing site
❌ **Don't skip assertions** - Always verify expected behavior
❌ **Don't forget passRaw** - Required for existing user login
❌ **Don't use JavaScript tests unnecessarily** - Slower execution

---

**Full documentation**: https://drupalatyourfingertips.com/dtt
