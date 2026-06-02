# Services & Dependency Injection

**Source**: [Drupal at Your Fingertips - services](https://drupalatyourfingertips.com/services)
**Author**: Selwyn Polit

Quick reference for Drupal services and dependency injection patterns.

---

## Core Concept

Services provide decoupled access to classes through the service container. Use dependency injection (DI) in classes for testable, pluggable code.

## Two Access Methods

**Static access** (for procedural code like `.module` files):
```php
$service = \Drupal::service('service.name');
```

**Dependency injection** (preferred for classes):
```php
// Services passed via constructor
public function __construct(AccountProxyInterface $account) {
  $this->account = $account;
}
```

---

## Controller Dependency Injection

Standard pattern with four parts:

```php
namespace Drupal\my_module\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Session\AccountProxyInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class ExampleController extends ControllerBase {

  // 1. Protected property
  protected AccountProxyInterface $account;

  // 2. create() method - gets services from container
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('current_user')
    );
  }

  // 3. Constructor - accepts and stores services
  public function __construct(AccountProxyInterface $account) {
    $this->account = $account;
  }

  // 4. Use the service
  public function build() {
    $username = $this->account->getAccountName();
    return ['#markup' => "Hello $username"];
  }
}
```

---

## Form Dependency Injection

Forms use `FormBase` and follow the same pattern:

```php
use Drupal\Core\Form\FormBase;
use Drupal\Core\Config\ConfigFactoryInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class MyForm extends FormBase {

  protected ConfigFactoryInterface $configFactory;

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('config.factory')
    );
  }

  public function __construct(ConfigFactoryInterface $config_factory) {
    $this->configFactory = $config_factory;
  }
}
```

---

## Custom Service Definition

Define services in `my_module.services.yml`:

```yaml
services:
  my_module.my_service:
    class: Drupal\my_module\MyService
    arguments:
      - '@entity_type.manager'
      - '@current_user'
      - '@config.factory'
```

Then inject your custom service:

```php
public static function create(ContainerInterface $container) {
  return new static(
    $container->get('my_module.my_service')
  );
}
```

---

## Block/Plugin Dependency Injection

Blocks require `ContainerFactoryPluginInterface` and extra parameters:

```php
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;

class MyBlock extends BlockBase implements ContainerFactoryPluginInterface {

  protected $currentUser;

  public static function create(
    ContainerInterface $container,
    array $configuration,
    $plugin_id,
    $plugin_definition
  ) {
    return new self(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('current_user')
    );
  }

  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    AccountProxyInterface $current_user
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
    $this->currentUser = $current_user;
  }
}
```

---

## Commonly Used Services

| Service | Purpose | Interface |
|---------|---------|-----------|
| `entity_type.manager` | Load/query entities | `EntityTypeManagerInterface` |
| `current_user` | Current user account | `AccountProxyInterface` |
| `config.factory` | Configuration values | `ConfigFactoryInterface` |
| `messenger` | User messages | `MessengerInterface` |
| `logger.factory` | Watchdog logging | `LoggerChannelFactoryInterface` |
| `database` | Database queries | `Connection` |
| `request_stack` | HTTP request | `RequestStack` |
| `path.validator` | Validate paths | `PathValidatorInterface` |
| `module_handler` | Module info | `ModuleHandlerInterface` |

---

---

## Key Benefits

✅ **Testable** - Mock services in PHPUnit tests
✅ **Pluggable** - Swap implementations via service container
✅ **Explicit dependencies** - Clear what each class needs
✅ **No global state** - Avoids static calls in class code

---

## When to Use Static vs DI

**Use `\Drupal::service()`**:
- `.module` files (procedural code)
- One-off procedural hooks
- Quick debugging

**Use dependency injection**:
- Controllers
- Forms
- Blocks
- Plugins
- Custom services
- Anything with automated tests

---

**Full documentation**: https://drupalatyourfingertips.com/services
