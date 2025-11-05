# Common Drupal 11 Deprecations and Fixes

## Deprecated Constants

### REQUEST_TIME

**Deprecated in**: Drupal 8.3.0
**Removed in**: Drupal 11.0.0

**OLD**:
```php
$timestamp = REQUEST_TIME;
$time_ago = REQUEST_TIME - $node->getCreatedTime();
```

**NEW**:
```php
// Inject TimeInterface service
use Drupal\Core\Datetime\TimeInterface;

class MyClass {
  protected $time;

  public function __construct(TimeInterface $time) {
    $this->time = $time;
  }

  public static function create(ContainerInterface $container) {
    return new static($container->get('datetime.time'));
  }

  public function myMethod() {
    $timestamp = $this->time->getRequestTime();
    $time_ago = $this->time->getRequestTime() - $node->getCreatedTime();
  }
}
```

## Deprecated Functions

### user_roles()

**Deprecated in**: Drupal 10.2.0
**Removed in**: Drupal 11.0.0

**OLD**:
```php
$roles = user_roles(TRUE); // Exclude anonymous
```

**NEW**:
```php
use Drupal\user\Entity\Role;

$roles = Role::loadMultiple();
$role_names = [];
foreach ($roles as $role_id => $role) {
  if ($role_id !== 'anonymous') {
    $role_names[$role_id] = $role->label();
  }
}
```

### user_role_names()

**Deprecated in**: Drupal 10.2.0
**Removed in**: Drupal 11.0.0

**OLD**:
```php
$role_options = user_role_names(TRUE);
```

**NEW**:
```php
use Drupal\user\Entity\Role;

$roles = Role::loadMultiple();
$role_options = [];
foreach ($roles as $role_id => $role) {
  if ($role_id !== 'anonymous') {
    $role_options[$role_id] = $role->label();
  }
}
```

### file_validate_extensions()

**Deprecated in**: Drupal 10.2.0
**Removed in**: Drupal 11.0.0

**OLD**:
```php
$errors = file_validate_extensions($file, 'mp3 wav ogg');
```

**NEW**:
```php
// Inject file.validator service
use Drupal\Core\File\FileSystemInterface;
use Drupal\file\Validation\FileValidatorInterface;

class MyClass {
  protected $fileValidator;

  public function __construct(FileValidatorInterface $file_validator) {
    $this->fileValidator = $file_validator;
  }

  public static function create(ContainerInterface $container) {
    return new static($container->get('file.validator'));
  }

  public function validateFile($file) {
    $validators = [
      'FileExtension' => [
        'extensions' => 'mp3 wav ogg',
      ],
    ];
    $violations = $this->fileValidator->validate($file, $validators);
    return $violations;
  }
}
```

### system_retrieve_file()

**Deprecated in**: Drupal 10.2.0
**Removed in**: Drupal 11.0.0
**Replacement**: None - must be refactored

**OLD**:
```php
$file = system_retrieve_file($url, $destination, FALSE, FILE_EXISTS_REPLACE);
```

**NEW**:
```php
// Use file_system service and http_client
use Drupal\Core\File\FileSystemInterface;
use GuzzleHttp\ClientInterface;

class MyClass {
  protected $fileSystem;
  protected $httpClient;

  public function __construct(FileSystemInterface $file_system, ClientInterface $http_client) {
    $this->fileSystem = $file_system;
    $this->httpClient = $http_client;
  }

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('file_system'),
      $container->get('http_client')
    );
  }

  public function retrieveFile($url, $destination) {
    try {
      $response = $this->httpClient->get($url);
      $data = $response->getBody()->getContents();

      $directory = dirname($destination);
      $this->fileSystem->prepareDirectory($directory, FileSystemInterface::CREATE_DIRECTORY);

      return $this->fileSystem->saveData($data, $destination, FileSystemInterface::EXISTS_REPLACE);
    }
    catch (\Exception $e) {
      \Drupal::logger('my_module')->error('Failed to retrieve file: @error', ['@error' => $e->getMessage()]);
      return FALSE;
    }
  }
}
```

### _drupal_flush_css_js()

**Deprecated in**: Drupal 10.2.0
**Removed in**: Drupal 11.0.0

**OLD**:
```php
_drupal_flush_css_js();
```

**NEW**:
```php
// Inject asset.query_string service
use Drupal\Core\Asset\AssetQueryStringInterface;

class MyClass {
  protected $assetQueryString;

  public function __construct(AssetQueryStringInterface $asset_query_string) {
    $this->assetQueryString = $asset_query_string;
  }

  public static function create(ContainerInterface $container) {
    return new static($container->get('asset.query_string'));
  }

  public function flushAssets() {
    $this->assetQueryString->reset();
  }
}
```

## Deprecated Class Constants

### FileSystemInterface::EXISTS_* Constants

**Deprecated in**: Drupal 10.3.0
**Removed in**: Drupal 12.0.0 (warning for D11)

**OLD**:
```php
use Drupal\Core\File\FileSystemInterface;

$file = $file_system->copy($source, $destination, FileSystemInterface::EXISTS_REPLACE);
```

**NEW**:
```php
use Drupal\Core\File\FileExists;

$file = $file_system->copy($source, $destination, FileExists::Replace);
```

## Twig Deprecations

### spaceless Filter

**Deprecated in**: Twig 3.12
**Removed in**: Drupal 11.0.0

**OLD**:
```twig
{% apply spaceless %}
  <div>
    <span>Content</span>
  </div>
{% endapply %}
```

**NEW**:
```twig
{# Remove spaceless - use CSS or HTML minification instead #}
<div>
  <span>Content</span>
</div>
```

## Module Info File Changes

### core_version_requirement

**Required for**: Drupal 11 compatibility

**OLD**:
```yaml
name: My Module
type: module
core_version_requirement: ^9 || ^10
```

**NEW**:
```yaml
name: My Module
type: module
core_version_requirement: ^9 || ^10 || ^11
```

**Create patch**:
```bash
cd docroot/modules/contrib/my_module
# Edit my_module.info.yml
git diff my_module.info.yml > ../../../patches/my_module-d11-info.patch
```

## Quick Reference: Service Names

| Old Function/Constant | Service Name | Interface |
|----------------------|--------------|-----------|
| REQUEST_TIME | `datetime.time` | `Drupal\Core\Datetime\TimeInterface` |
| user_roles() | N/A | `Drupal\user\Entity\Role::loadMultiple()` |
| file_validate_extensions() | `file.validator` | `Drupal\file\Validation\FileValidatorInterface` |
| system_retrieve_file() | `file_system` + `http_client` | `FileSystemInterface` + `ClientInterface` |
| _drupal_flush_css_js() | `asset.query_string` | `Drupal\Core\Asset\AssetQueryStringInterface` |

## Testing Your Fixes

After making changes, always:

1. **Clear cache**: `drush cr`
2. **Run upgrade_status**: `drush upgrade_status:analyze module_name`
3. **Check logs**: `drush watchdog:show --severity=Error`
4. **Visit pages**: Test actual functionality
5. **Run tests**: If module has tests, run them

## Finding More Information

- **Deprecation Policy**: https://www.drupal.org/about/core/policies/core-change-policies/drupal-deprecation-policy
- **Change Records**: https://www.drupal.org/list-changes/drupal
- **API Documentation**: https://api.drupal.org/api/drupal/11.x
- **Upgrade Status Module**: https://www.drupal.org/project/upgrade_status
