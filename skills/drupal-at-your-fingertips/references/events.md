# Events & Event Subscribers

**Source**: [Drupal at Your Fingertips - events](https://drupalatyourfingertips.com/events)
**Author**: Selwyn Polit

Quick reference for Drupal events and event subscribers with practical code examples.

---

## Core Concept

Events allow modules to react to actions without modifying code. Event subscribers listen for dispatched events and execute custom logic when events occur.

## Event Subscriber Structure

**Basic event subscriber**:
```php
namespace Drupal\my_module\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class MySubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents() {
    return [
      KernelEvents::REQUEST => ['onRequest', 100],
    ];
  }

  public function onRequest(RequestEvent $event) {
    // React to the request event
    \Drupal::logger('my_module')->notice('Request received');
  }
}
```

**Register in my_module.services.yml**:
```yaml
services:
  my_module.subscriber:
    class: Drupal\my_module\EventSubscriber\MySubscriber
    tags:
      - { name: event_subscriber }
```

---

## Event Subscriber with DI

**Inject services**:
```php
use Drupal\Core\Session\AccountProxyInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class MySubscriber implements EventSubscriberInterface {

  protected AccountProxyInterface $currentUser;

  public function __construct(AccountProxyInterface $current_user) {
    $this->currentUser = $current_user;
  }

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('current_user')
    );
  }

  public static function getSubscribedEvents() {
    return [
      KernelEvents::REQUEST => ['onRequest'],
    ];
  }

  public function onRequest(RequestEvent $event) {
    if ($this->currentUser->isAuthenticated()) {
      // Do something for logged-in users
    }
  }
}
```

**Service definition with DI**:
```yaml
services:
  my_module.subscriber:
    class: Drupal\my_module\EventSubscriber\MySubscriber
    arguments: ['@current_user']
    tags:
      - { name: event_subscriber }
```

---

## Event Priorities

**Priority order** (higher numbers run first):
```php
public static function getSubscribedEvents() {
  return [
    KernelEvents::REQUEST => [
      ['onRequestEarly', 100],    // Runs first
      ['onRequestLate', -100],    // Runs last
    ],
  ];
}
```

Default priority is 0 if not specified.

---

## Commonly Used Events

| Event | Constant | Use Case |
|-------|----------|----------|
| Request | `KernelEvents::REQUEST` | Early request processing |
| Response | `KernelEvents::RESPONSE` | Modify response before sending |
| Controller | `KernelEvents::CONTROLLER` | Before controller execution |
| View | `KernelEvents::VIEW` | Before rendering |
| Exception | `KernelEvents::EXCEPTION` | Error handling |
| Terminate | `KernelEvents::TERMINATE` | After response sent |
| Config Save | `ConfigEvents::SAVE` | Configuration changes |
| Config Delete | `ConfigEvents::DELETE` | Configuration removal |
| Entity Insert | `MyEvents::ENTITY_INSERT` | After entity creation |

---

## KernelEvents Examples

**Modify request**:
```php
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

public static function getSubscribedEvents() {
  return [KernelEvents::REQUEST => ['onRequest']];
}

public function onRequest(RequestEvent $event) {
  $request = $event->getRequest();

  // Add custom request attribute
  $request->attributes->set('custom_data', 'value');

  // Redirect based on condition
  if ($some_condition) {
    $response = new RedirectResponse('/custom-page');
    $event->setResponse($response);
  }
}
```

**Modify response**:
```php
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

public static function getSubscribedEvents() {
  return [KernelEvents::RESPONSE => ['onResponse']];
}

public function onResponse(ResponseEvent $event) {
  $response = $event->getResponse();

  // Add custom header
  $response->headers->set('X-Custom-Header', 'MyValue');

  // Modify content
  $content = $response->getContent();
  $content = str_replace('old', 'new', $content);
  $response->setContent($content);
}
```

---

## Custom Events

**Define custom event**:
```php
namespace Drupal\my_module\Event;

use Symfony\Contracts\EventDispatcher\Event;
use Drupal\node\NodeInterface;

class NodeSaveEvent extends Event {

  const EVENT_NAME = 'my_module.node_save';

  protected NodeInterface $node;

  public function __construct(NodeInterface $node) {
    $this->node = $node;
  }

  public function getNode() {
    return $this->node;
  }
}
```

**Dispatch custom event**:
```php
use Symfony\Component\EventDispatcher\EventDispatcherInterface;

class MyService {

  protected EventDispatcherInterface $eventDispatcher;

  public function __construct(EventDispatcherInterface $event_dispatcher) {
    $this->eventDispatcher = $event_dispatcher;
  }

  public function saveNode(NodeInterface $node) {
    $node->save();

    // Dispatch custom event
    $event = new NodeSaveEvent($node);
    $this->eventDispatcher->dispatch($event, NodeSaveEvent::EVENT_NAME);
  }
}
```

**Subscribe to custom event**:
```php
use Drupal\my_module\Event\NodeSaveEvent;

public static function getSubscribedEvents() {
  return [
    NodeSaveEvent::EVENT_NAME => ['onNodeSave'],
  ];
}

public function onNodeSave(NodeSaveEvent $event) {
  $node = $event->getNode();
  \Drupal::logger('my_module')->notice('Node @title saved', [
    '@title' => $node->getTitle(),
  ]);
}
```

---

## Stop Propagation

**Prevent other subscribers from executing**:
```php
public function onRequest(RequestEvent $event) {
  if ($some_condition) {
    // Stop other subscribers from running
    $event->stopPropagation();

    // Set custom response
    $response = new JsonResponse(['error' => 'Access denied'], 403);
    $event->setResponse($response);
  }
}
```

---

---

## Key Guidelines

✅ **Use high priorities** - For early intervention (100+)
✅ **Use low priorities** - For final modifications (-100)
✅ **Inject dependencies** - Use DI in subscribers
✅ **Tag services** - Always add `event_subscriber` tag
✅ **Stop propagation** - When needed to prevent later execution
✅ **Create custom events** - For module-specific actions
✅ **Use constants** - Define event names as class constants

❌ **Don't use static calls** - Inject services instead
❌ **Don't forget service tags** - Won't work without tag
❌ **Don't overuse high priorities** - Can break other modules
❌ **Don't modify immutable data** - Some event properties are read-only
❌ **Don't use events for hooks** - Use hooks when available

---

**Full documentation**: https://drupalatyourfingertips.com/events
