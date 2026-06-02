# AJAX

**Source**: [Drupal at Your Fingertips - ajax](https://drupalatyourfingertips.com/ajax)
**Author**: Selwyn Polit

Quick reference for AJAX in Drupal with practical code examples.

---

## Core Concept

AJAX in Drupal enables partial page updates without full page refreshes. Use the `#ajax` property on form elements to trigger callbacks that return AJAX commands (replace, append, remove, etc.) to manipulate the page.

## AJAX in Forms

**Basic pattern**:
```php
$form['category'] = [
  '#type' => 'select',
  '#title' => $this->t('Category'),
  '#options' => ['tech' => 'Tech', 'news' => 'News'],
  '#ajax' => [
    'callback' => '::updateItems',  // Method name
    'wrapper' => 'items-wrapper',   // HTML ID to replace
    'event' => 'change',            // Trigger event (default: change)
  ],
];

$form['items'] = [
  '#type' => 'select',
  '#title' => $this->t('Items'),
  '#prefix' => '<div id="items-wrapper">',
  '#suffix' => '</div>',
];
```

**AJAX callback**:
```php
public function updateItems(array &$form, FormStateInterface $form_state) {
  // Return the element to replace
  return $form['items'];
}
```

---

## AJAX Properties

**Common #ajax properties**:
| Property | Purpose | Default |
|----------|---------|---------|
| `callback` | Method to call | Required |
| `wrapper` | HTML ID to replace | Required |
| `event` | JavaScript event | 'change' |
| `method` | HTTP method | 'POST' |
| `progress` | Progress indicator | `['type' => 'throbber']` |
| `effect` | jQuery effect | 'fade' |
| `speed` | Effect speed | 'slow' |

**Progress indicators**:
```php
'#ajax' => [
  'callback' => '::myCallback',
  'wrapper' => 'my-wrapper',

  // Throbber (default)
  'progress' => ['type' => 'throbber'],

  // Full page progress bar
  'progress' => ['type' => 'fullscreen'],

  // Custom message
  'progress' => [
    'type' => 'throbber',
    'message' => $this->t('Loading...'),
  ],

  // No progress indicator
  'progress' => ['type' => 'none'],
],
```

---

## AJAX Responses

**Return render array** (most common):
```php
public function callback(array &$form, FormStateInterface $form_state) {
  // Return element to replace
  return $form['subcategory'];
}
```

**Return AjaxResponse with commands**:
```php
use Drupal\Core\Ajax\AjaxResponse;
use Drupal\Core\Ajax\ReplaceCommand;
use Drupal\Core\Ajax\AppendCommand;

public function callback(array &$form, FormStateInterface $form_state) {
  $response = new AjaxResponse();

  // Replace element
  $response->addCommand(new ReplaceCommand('#items-wrapper', $form['items']));

  // Append content
  $response->addCommand(new AppendCommand('#messages', '<div>New message</div>'));

  return $response;
}
```

---

## AJAX Commands

**Common AJAX commands**:

**ReplaceCommand** - Replace element:
```php
use Drupal\Core\Ajax\ReplaceCommand;

$response->addCommand(new ReplaceCommand('#selector', $content));
```

**AppendCommand** - Append to element:
```php
use Drupal\Core\Ajax\AppendCommand;

$response->addCommand(new AppendCommand('#selector', $content));
```

**PrependCommand** - Prepend to element:
```php
use Drupal\Core\Ajax\PrependCommand;

$response->addCommand(new PrependCommand('#selector', $content));
```

**RemoveCommand** - Remove element:
```php
use Drupal\Core\Ajax\RemoveCommand;

$response->addCommand(new RemoveCommand('#selector'));
```

**InvokeCommand** - Call jQuery method:
```php
use Drupal\Core\Ajax\InvokeCommand;

// Call .hide()
$response->addCommand(new InvokeCommand('#selector', 'hide'));

// Call .addClass('active')
$response->addCommand(new InvokeCommand('#selector', 'addClass', ['active']));

// Call .val('new value')
$response->addCommand(new InvokeCommand('#selector', 'val', ['new value']));
```

**HtmlCommand** - Set HTML content:
```php
use Drupal\Core\Ajax\HtmlCommand;

$response->addCommand(new HtmlCommand('#selector', '<p>New content</p>'));
```

**CssCommand** - Change CSS:
```php
use Drupal\Core\Ajax\CssCommand;

$response->addCommand(new CssCommand('#selector', ['background' => 'red']));
```

**AlertCommand** - Show alert:
```php
use Drupal\Core\Ajax\AlertCommand;

$response->addCommand(new AlertCommand('Alert message'));
```

**RedirectCommand** - Redirect:
```php
use Drupal\Core\Ajax\RedirectCommand;

$url = Url::fromRoute('my_module.page')->toString();
$response->addCommand(new RedirectCommand($url));
```

---

## Modal Dialogs

**Open modal dialog**:
```php
use Drupal\Core\Ajax\OpenModalDialogCommand;

$title = $this->t('Modal Title');
$content = ['#markup' => '<p>Modal content</p>'];

$response->addCommand(new OpenModalDialogCommand($title, $content));
```

**Open dialog with options**:
```php
use Drupal\Core\Ajax\OpenDialogCommand;

$options = [
  'width' => '50%',
  'height' => 400,
  'dialogClass' => 'my-custom-dialog',
];

$response->addCommand(new OpenDialogCommand('#dialog-selector', $title, $content, $options));
```

**Close dialog**:
```php
use Drupal\Core\Ajax\CloseDialogCommand;

$response->addCommand(new CloseDialogCommand());
```

---

## Custom AJAX Commands

**Create custom command** (PHP):
```php
namespace Drupal\my_module\Ajax;

use Drupal\Core\Ajax\CommandInterface;

class ScrollToCommand implements CommandInterface {

  protected $selector;

  public function __construct($selector) {
    $this->selector = $selector;
  }

  public function render() {
    return [
      'command' => 'scrollTo',
      'selector' => $this->selector,
    ];
  }
}
```

**JavaScript handler** (my_module.ajax.js):
```javascript
(function (Drupal, $) {
  Drupal.AjaxCommands.prototype.scrollTo = function (ajax, response, status) {
    var $element = $(response.selector);
    if ($element.length) {
      $('html, body').animate({
        scrollTop: $element.offset().top
      }, 500);
    }
  };
})(Drupal, jQuery);
```

**Attach library** (my_module.libraries.yml):
```yaml
ajax:
  js:
    js/my_module.ajax.js: {}
  dependencies:
    - core/drupal
    - core/jquery
```

**Use custom command**:
```php
use Drupal\my_module\Ajax\ScrollToCommand;

$response->addCommand(new ScrollToCommand('#target-element'));
$form['#attached']['library'][] = 'my_module/ajax';
```

---

## AJAX Links

**Create AJAX-enabled link**:
```php
use Drupal\Core\Url;

$link = Link::createFromRoute(
  $this->t('Load More'),
  'my_module.load_more',
  [],
  [
    'attributes' => [
      'class' => ['use-ajax'],
    ],
  ]
);
```

**Route for AJAX link**:
```yaml
my_module.load_more:
  path: '/load-more'
  defaults:
    _controller: '\Drupal\my_module\Controller\AjaxController::loadMore'
  requirements:
    _permission: 'access content'
```

**Controller**:
```php
use Drupal\Core\Ajax\AjaxResponse;
use Drupal\Core\Ajax\AppendCommand;

public function loadMore(Request $request) {
  if (!$request->isXmlHttpRequest()) {
    throw new HttpException(400, 'This is only for AJAX requests');
  }

  $response = new AjaxResponse();

  $content = [
    '#theme' => 'item_list',
    '#items' => $this->getMoreItems(),
  ];

  $response->addCommand(new AppendCommand('#items-container', $content));

  return $response;
}
```

---

## AJAX Validation

**Validate before callback**:
```php
public function ajaxCallback(array &$form, FormStateInterface $form_state) {
  // Check for errors
  if ($form_state->hasAnyErrors()) {
    // Return form to show validation errors
    return $form;
  }

  // Proceed with AJAX logic
  $value = $form_state->getValue('field_name');

  // Build response
  $response = new AjaxResponse();
  $response->addCommand(new HtmlCommand('#result', "Value: $value"));

  return $response;
}
```

---

## Multiple AJAX Commands

**Chain multiple commands**:
```php
public function complexCallback(array &$form, FormStateInterface $form_state) {
  $response = new AjaxResponse();

  // 1. Replace content
  $response->addCommand(new ReplaceCommand('#items', $form['items']));

  // 2. Show message
  $message = [
    '#theme' => 'status_messages',
    '#message_list' => ['status' => [$this->t('Updated successfully')]],
  ];
  $response->addCommand(new PrependCommand('#content', $message));

  // 3. Scroll to top
  $response->addCommand(new InvokeCommand('html, body', 'animate', [
    ['scrollTop' => 0],
    300,
  ]));

  // 4. Add CSS class
  $response->addCommand(new InvokeCommand('#items', 'addClass', ['updated']));

  return $response;
}
```

---

## Debugging AJAX

**Enable AJAX debugging**:
```javascript
// In browser console
Drupal.ajax.instances.forEach(function(instance) {
  console.log(instance);
});
```

**Check AJAX requests** in browser DevTools Network tab.

**Add logging to callback**:
```php
public function ajaxCallback(array &$form, FormStateInterface $form_state) {
  \Drupal::logger('my_module')->notice('AJAX callback triggered');

  $values = $form_state->getValues();
  \Drupal::logger('my_module')->notice('Values: @values', [
    '@values' => print_r($values, TRUE),
  ]);

  return $form['field'];
}
```

---

---

## Key Guidelines

✅ **Use #ajax property** - On form elements for callbacks
✅ **Return render arrays** - Simplest AJAX response
✅ **Use AjaxResponse** - For multiple commands
✅ **Validate requests** - Check isXmlHttpRequest()
✅ **Add progress indicators** - Improve UX
✅ **Use wrapper IDs** - Unique HTML IDs for targets
✅ **Attach libraries** - For custom JavaScript
✅ **Test without JavaScript** - Ensure graceful degradation

❌ **Don't forget wrapper** - Must have HTML ID
❌ **Don't skip validation** - Check request type
❌ **Don't hardcode IDs** - Use Html::getUniqueId()
❌ **Don't forget #prefix/#suffix** - For wrapper divs
❌ **Don't mix AJAX types** - Use consistent pattern
❌ **Don't skip progress indicators** - Show loading state
❌ **Don't return NULL** - Return valid render array or AjaxResponse

---

**Full documentation**: https://drupalatyourfingertips.com/ajax
