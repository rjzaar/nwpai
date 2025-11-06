# Drupal Development with DDEV: A Guide for Non-PHP Developers

## Introduction

If you're coming from other languages and frameworks, Drupal might feel different. It's not a typical MVC framework—it's more of a Content Management Framework (CMF) with a powerful plugin architecture. This guide assumes you're comfortable with programming concepts but new to PHP and Drupal.

### What Makes Drupal Different

- **Configuration as data**: Site structure is stored in the database and exportable as YAML
- **Hook system**: Instead of inheritance, Drupal uses hooks (event-like callbacks) extensively
- **Entity system**: Everything is an entity (nodes, users, comments, taxonomy terms)
- **Plugin architecture**: Drupal 8+ uses modern OOP with annotations/attributes
- **Render arrays**: Instead of templates directly, you build nested arrays that Drupal renders
- **Dependency injection**: Services are available via DI container (similar to Spring/Angular)

---

## PHP Quick Primer for Experienced Developers

### Syntax Basics (5 Minute Version)

```php
<?php
// Variables start with $
$name = "John";
$count = 42;
$items = ['apple', 'banana', 'orange'];  // Arrays
$config = ['debug' => true, 'timeout' => 30];  // Associative arrays (like dicts/maps)

// Functions
function calculateTotal($price, $quantity) {
  return $price * $quantity;
}

// Arrow functions (PHP 7.4+)
$double = fn($x) => $x * 2;

// Classes
class UserService {
  private $database;
  
  public function __construct(DatabaseConnection $database) {
    $this->database = $database;  // $this is like 'self' in Python
  }
  
  public function getUser($id) {
    return $this->database->query("SELECT * FROM users WHERE id = :id", [':id' => $id]);
  }
}

// Namespaces (like packages in Java/Go)
namespace Drupal\mymodule\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\Response;

// Traits (like mixins)
trait LoggerTrait {
  protected function log($message) {
    \Drupal::logger('mymodule')->notice($message);
  }
}

// String concatenation with . (not +)
$greeting = "Hello " . $name . "!";
$greeting = "Hello {$name}!";  // Interpolation (double quotes only)

// Array operations
$filtered = array_filter($items, fn($item) => strlen($item) > 5);
$mapped = array_map(fn($item) => strtoupper($item), $items);

// Null coalescing
$value = $config['timeout'] ?? 60;  // Like || in JS, but doesn't trip on 0/false
```

### Key PHP Gotchas

- `==` is loose comparison, `===` is strict (always use `===`)
- Arrays are ordered maps (not separate types)
- `.` is concatenation, `+` is addition (won't auto-convert like JavaScript)
- Variable variables: `$$name` (usually avoid these)
- No implicit returns in arrow functions unless single expression

---

## Setting Up Your First Drupal Project with DDEV

### Initial Setup

```bash
# Install DDEV (if not already installed)
# See: https://ddev.readthedocs.io/en/stable/#installation

# Create a new directory for your project
mkdir my-drupal-site
cd my-drupal-site

# Initialize DDEV for Drupal 10
ddev config --project-type=drupal10 --docroot=web --create-docroot

# Start the environment
ddev start

# Install Drupal using Composer
ddev composer create drupal/recommended-project

# Install Drupal via Drush
ddev drush site:install standard --account-name=admin --account-pass=admin --site-name="My Drupal Site" -y

# Get your site URL
ddev describe
```

Your site is now running! Visit the URL shown by `ddev describe`.

### Alternative: Starting from Existing Project

```bash
# Clone your project
git clone https://github.com/yourorg/yourproject.git
cd yourproject

# If .ddev/config.yaml exists
ddev start

# Install dependencies
ddev composer install

# Import database (if you have a dump)
ddev import-db --file=database.sql.gz

# Import configuration
ddev drush config:import -y

# Clear cache
ddev drush cache:rebuild
```

---

## Essential DDEV Commands for Daily Development

### Basic Operations

```bash
ddev start              # Start your project
ddev stop               # Stop your project
ddev restart            # Restart (useful after config changes)
ddev poweroff           # Stop ALL DDEV projects

ddev ssh                # SSH into the web container (you'll use this A LOT)
ddev ssh -s db          # SSH into database container
```

### Composer (Dependency Management)

```bash
# Install a module
ddev composer require drupal/admin_toolbar

# Install a dev dependency
ddev composer require --dev drupal/devel

# Update all dependencies
ddev composer update

# Update specific package
ddev composer update drupal/core --with-dependencies

# Remove a package
ddev composer remove drupal/admin_toolbar
```

### Drush (Drupal CLI - Your Best Friend)

```bash
# Cache operations (you'll do this constantly)
ddev drush cr           # Clear cache (rebuild)
ddev drush cc           # Clear specific caches (interactive)

# Configuration management
ddev drush config:export -y     # Export config to sync directory (cex)
ddev drush config:import -y     # Import config from sync directory (cim)
ddev drush config:status        # Show config differences (cst)

# Database operations
ddev drush sql:dump > backup.sql    # Export database
ddev drush sql:query "SELECT * FROM users LIMIT 5"  # Run SQL

# User management
ddev drush user:login           # Generate one-time login link (uli)
ddev drush user:create testuser --mail="test@example.com" --password="test"
ddev drush user:role:add "administrator" testuser

# Module management
ddev drush pm:enable admin_toolbar -y   # Enable module (en)
ddev drush pm:uninstall admin_toolbar -y  # Uninstall module (pmu)
ddev drush pm:list                      # List all modules

# Entity operations
ddev drush entity:delete node 123       # Delete node with ID 123
ddev drush entity:updates -y            # Apply entity schema updates

# Generate code (very useful!)
ddev drush generate module              # Interactive module scaffolding
ddev drush generate controller
ddev drush generate form
ddev drush generate plugin:block

# Development helpers
ddev drush watchdog:show --extended     # View recent log entries (ws)
ddev drush state:get system.maintenance_mode  # Check maintenance mode
ddev drush state:set system.maintenance_mode 1  # Enable maintenance mode
```

### Database Snapshots (Save Your Bacon)

```bash
ddev snapshot           # Create named snapshot
ddev snapshot --name=before-big-change

ddev snapshot restore   # Interactive restore
ddev snapshot restore --name=before-big-change

ddev snapshot --list    # List all snapshots
ddev snapshot --cleanup # Remove old snapshots
```

### Logs and Debugging

```bash
ddev logs               # View container logs
ddev logs -f            # Follow logs (like tail -f)
ddev logs -s db         # Database container logs

# Drupal logs
ddev drush watchdog:show
ddev drush watchdog:show --severity=Error
ddev drush watchdog:tail  # Live log tail
```

---

## Understanding Drupal's Structure

### Directory Layout

```
my-drupal-site/
├── .ddev/                    # DDEV configuration
│   ├── config.yaml           # Project settings
│   ├── docker-compose.*.yaml # Custom services
│   └── commands/             # Custom DDEV commands
├── config/                   # Configuration YAML files
│   └── sync/                 # Exported configuration
├── vendor/                   # Composer dependencies (never edit)
├── web/                      # Document root (or 'docroot')
│   ├── core/                 # Drupal core (never edit)
│   ├── modules/
│   │   ├── contrib/          # Downloaded modules (via Composer)
│   │   └── custom/           # Your custom modules
│   ├── themes/
│   │   ├── contrib/          # Downloaded themes
│   │   └── custom/           # Your custom themes
│   ├── sites/
│   │   ├── default/
│   │   │   ├── settings.php  # Database connection, etc.
│   │   │   └── files/        # Uploaded files
│   │   └── development.services.yml  # Dev-only services
│   ├── .htaccess             # Apache config (or nginx conf)
│   └── index.php             # Entry point
└── composer.json             # PHP dependencies
```

### Key Concepts

#### 1. Entities and Bundles

Think of entities as base classes and bundles as specific implementations:

```
Entity Type: node (like a "Post" model)
  ├── Bundle: article (has fields: title, body, image, tags)
  ├── Bundle: page (has fields: title, body)
  └── Bundle: blog_post (has fields: title, body, author, date)

Entity Type: user
  └── Bundle: user (only one bundle - all users share same structure)

Entity Type: taxonomy_term
  ├── Bundle: tags
  └── Bundle: categories
```

Every content item is an entity. Entities have:
- **Fields**: Data storage (text, images, references)
- **View modes**: Different displays (full, teaser, card)
- **Form modes**: Different edit forms

#### 2. Configuration Management

Drupal stores configuration in YAML files that you can version control:

```bash
# Make changes in UI (add content type, change settings, etc.)

# Export to YAML files
ddev drush config:export -y

# Commit to git
git add config/sync
git commit -m "Added blog content type"

# On another environment, import
ddev drush config:import -y
```

Configuration files look like:
```yaml
# config/sync/node.type.article.yml
uuid: a1b2c3d4-...
langcode: en
status: true
dependencies: {  }
name: Article
type: article
description: 'Use articles for time-sensitive content like news, press releases or blog posts.'
help: ''
new_revision: true
preview_mode: 1
display_submitted: true
```

#### 3. The Hook System

Instead of extending classes, Drupal uses hooks (like WordPress filters/actions or Rails callbacks):

```php
// In your_module.module file

/**
 * Implements hook_form_alter().
 * Modify any form before it's displayed.
 */
function your_module_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  if ($form_id == 'node_article_form') {
    $form['title']['widget'][0]['value']['#description'] = 'Make it catchy!';
  }
}

/**
 * Implements hook_entity_presave().
 * Act before any entity is saved.
 */
function your_module_entity_presave(EntityInterface $entity) {
  if ($entity->getEntityTypeId() == 'node' && $entity->bundle() == 'article') {
    // Auto-generate summary if empty
    if (empty($entity->get('body')->summary)) {
      $body = $entity->get('body')->value;
      $entity->get('body')->summary = substr(strip_tags($body), 0, 200);
    }
  }
}

/**
 * Implements hook_cron().
 * Runs periodically (like cron jobs).
 */
function your_module_cron() {
  // Clean up old data
  \Drupal::database()->delete('your_table')
    ->condition('created', strtotime('-30 days'), '<')
    ->execute();
}
```

Common hooks:
- `hook_form_alter()`: Modify forms
- `hook_entity_presave()`: Before entity save
- `hook_entity_insert()`: After new entity created
- `hook_entity_update()`: After entity updated
- `hook_page_attachments()`: Add CSS/JS to pages
- `hook_preprocess_HOOK()`: Modify template variables

#### 4. Services and Dependency Injection

Drupal uses Symfony's service container (like Spring in Java, or Angular's DI):

```php
// In a service class
namespace Drupal\mymodule\Services;

use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;

class MyCustomService {
  
  protected $entityTypeManager;
  protected $logger;
  
  // Dependencies injected via constructor
  public function __construct(
    EntityTypeManagerInterface $entity_type_manager,
    LoggerChannelFactoryInterface $logger_factory
  ) {
    $this->entityTypeManager = $entity_type_manager;
    $this->logger = $logger_factory->get('mymodule');
  }
  
  public function doSomething() {
    $nodes = $this->entityTypeManager
      ->getStorage('node')
      ->loadByProperties(['type' => 'article', 'status' => 1]);
    
    $this->logger->notice('Processed @count nodes', ['@count' => count($nodes)]);
    return $nodes;
  }
}
```

Define your service in `mymodule.services.yml`:
```yaml
services:
  mymodule.custom_service:
    class: Drupal\mymodule\Services\MyCustomService
    arguments: ['@entity_type.manager', '@logger.factory']
```

Use it:
```php
// In a controller or other service-aware class
$service = \Drupal::service('mymodule.custom_service');
$result = $service->doSomething();

// Better: inject it via constructor
public function __construct(MyCustomService $my_service) {
  $this->myService = $my_service;
}
```

---

## Creating Your First Custom Module

### Module Structure

```bash
# SSH into DDEV
ddev ssh

# Navigate to custom modules
cd web/modules/custom

# Use Drush to generate module scaffold
drush generate module

# Or create manually:
mkdir mymodule
cd mymodule
```

### Basic Module Files

**mymodule.info.yml** (Required)
```yaml
name: My Module
description: 'Does amazing things'
type: module
core_version_requirement: ^10 || ^11
package: Custom

dependencies:
  - drupal:node
  - drupal:user
  - views:views
```

**mymodule.module** (Optional but common)
```php
<?php

/**
 * @file
 * Custom module hooks and functions.
 */

use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Form\FormStateInterface;

/**
 * Implements hook_help().
 */
function mymodule_help($route_name, RouteMatchInterface $route_match) {
  if ($route_name == 'help.page.mymodule') {
    return '<p>' . t('This module does amazing things.') . '</p>';
  }
}

/**
 * Implements hook_form_alter().
 */
function mymodule_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  // Your form alterations
}
```

**mymodule.routing.yml** (Define routes/URLs)
```yaml
mymodule.hello:
  path: '/hello/{name}'
  defaults:
    _controller: '\Drupal\mymodule\Controller\HelloController::content'
    _title: 'Hello'
    name: 'World'
  requirements:
    _permission: 'access content'
    name: '[a-zA-Z ]+'
```

**src/Controller/HelloController.php**
```php
<?php

namespace Drupal\mymodule\Controller;

use Drupal\Core\Controller\ControllerBase;

/**
 * Returns responses for My Module routes.
 */
class HelloController extends ControllerBase {

  /**
   * Builds the response.
   */
  public function content($name = 'World') {
    // Return a render array
    $build['content'] = [
      '#type' => 'markup',
      '#markup' => $this->t('Hello @name!', ['@name' => $name]),
    ];
    
    return $build;
  }

}
```

### Enable and Test

```bash
# Clear cache after creating files
ddev drush cr

# Enable your module
ddev drush pm:enable mymodule -y

# Visit your route
# http://your-site.ddev.site/hello/Alice
```

---

## Common Development Tasks

### 1. Creating a Custom Content Type Programmatically

Better to create via UI and export config, but here's the code:

```php
use Drupal\node\Entity\NodeType;
use Drupal\field\Entity\FieldConfig;
use Drupal\field\Entity\FieldStorageConfig;

// Create content type
$type = NodeType::create([
  'type' => 'blog_post',
  'name' => 'Blog Post',
  'description' => 'A blog post',
]);
$type->save();

// Add a field
FieldStorageConfig::create([
  'field_name' => 'field_author',
  'entity_type' => 'node',
  'type' => 'string',
])->save();

FieldConfig::create([
  'field_name' => 'field_author',
  'entity_type' => 'node',
  'bundle' => 'blog_post',
  'label' => 'Author',
  'required' => TRUE,
])->save();
```

### 2. Loading and Manipulating Entities

```php
// Load a node
$node = \Drupal::entityTypeManager()->getStorage('node')->load(123);

// Better: inject the service
$node = $this->entityTypeManager->getStorage('node')->load(123);

// Load multiple nodes
$nodes = \Drupal::entityTypeManager()
  ->getStorage('node')
  ->loadByProperties([
    'type' => 'article',
    'status' => 1,
  ]);

// Create a node
$node = \Drupal::entityTypeManager()->getStorage('node')->create([
  'type' => 'article',
  'title' => 'My Article',
  'body' => [
    'value' => '<p>Article content goes here.</p>',
    'format' => 'full_html',
  ],
  'field_tags' => [['target_id' => 5], ['target_id' => 8]],
  'status' => 1,
]);
$node->save();

// Update a node
$node->set('title', 'Updated Title');
$node->set('field_custom', 'New value');
$node->save();

// Delete a node
$node->delete();

// Query entities
$query = \Drupal::entityQuery('node')
  ->condition('type', 'article')
  ->condition('status', 1)
  ->condition('created', strtotime('-30 days'), '>')
  ->sort('created', 'DESC')
  ->range(0, 10)
  ->accessCheck(TRUE);  // Always include access check
$nids = $query->execute();
```

### 3. Working with Fields

```php
// Get field value
$title = $node->get('title')->value;
$body = $node->get('body')->value;  // HTML content
$summary = $node->get('body')->summary;
$format = $node->get('body')->format;

// Reference fields (taxonomy, entity reference)
$tag_ids = [];
foreach ($node->get('field_tags') as $item) {
  $tag_ids[] = $item->target_id;
}

// Or more succinctly
$tag_ids = array_column($node->get('field_tags')->getValue(), 'target_id');

// Load referenced entities
$tags = $node->get('field_tags')->referencedEntities();
foreach ($tags as $tag) {
  echo $tag->label();
}

// Image fields
$image_url = $node->get('field_image')->entity->createFileUrl();
$alt_text = $node->get('field_image')->alt;

// Check if field has value
if (!$node->get('field_custom')->isEmpty()) {
  // Field has value
}

// Multiple value fields
foreach ($node->get('field_multiple') as $item) {
  echo $item->value;
}
```

### 4. Creating a Custom Block (Plugin)

```php
<?php

namespace Drupal\mymodule\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Provides a 'Hello' Block.
 *
 * @Block(
 *   id = "hello_block",
 *   admin_label = @Translation("Hello block"),
 *   category = @Translation("Custom"),
 * )
 */
class HelloBlock extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function build() {
    return [
      '#markup' => $this->t('Hello from my custom block!'),
      '#cache' => [
        'max-age' => 60,  // Cache for 60 seconds
      ],
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function blockForm($form, FormStateInterface $form_state) {
    $config = $this->configuration;

    $form['greeting'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Greeting'),
      '#default_value' => $config['greeting'] ?? 'Hello',
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {
    $this->configuration['greeting'] = $form_state->getValue('greeting');
  }

}
```

### 5. Creating a Custom Form

```php
<?php

namespace Drupal\mymodule\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Provides a My Module form.
 */
class CustomForm extends FormBase {

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'mymodule_custom_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {
    
    $form['name'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Your name'),
      '#required' => TRUE,
    ];

    $form['email'] = [
      '#type' => 'email',
      '#title' => $this->t('Email'),
      '#required' => TRUE,
    ];

    $form['message'] = [
      '#type' => 'textarea',
      '#title' => $this->t('Message'),
      '#rows' => 5,
    ];

    $form['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Submit'),
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function validateForm(array &$form, FormStateInterface $form_state) {
    $email = $form_state->getValue('email');
    if (strpos($email, '@example.com') !== FALSE) {
      $form_state->setErrorByName('email', $this->t('Example.com emails not allowed.'));
    }
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $name = $form_state->getValue('name');
    $email = $form_state->getValue('email');
    $message = $form_state->getValue('message');
    
    // Do something with the data
    \Drupal::messenger()->addMessage($this->t('Thank you @name!', ['@name' => $name]));
    
    // Redirect somewhere
    $form_state->setRedirect('entity.node.canonical', ['node' => 1]);
  }

}
```

Add route for form:
```yaml
# mymodule.routing.yml
mymodule.custom_form:
  path: '/custom-form'
  defaults:
    _form: '\Drupal\mymodule\Form\CustomForm'
    _title: 'Custom Form'
  requirements:
    _permission: 'access content'
```

### 6. Working with Database (Non-Entity Data)

```php
// Get database connection
$database = \Drupal::database();

// Insert
$database->insert('mytable')
  ->fields([
    'name' => 'John',
    'email' => 'john@example.com',
    'created' => time(),
  ])
  ->execute();

// Select
$query = $database->select('mytable', 'm')
  ->fields('m', ['id', 'name', 'email'])
  ->condition('name', '%john%', 'LIKE')
  ->orderBy('created', 'DESC')
  ->range(0, 10);
$results = $query->execute()->fetchAll();

// Update
$database->update('mytable')
  ->fields(['name' => 'Jane'])
  ->condition('id', 5)
  ->execute();

// Delete
$database->delete('mytable')
  ->condition('created', strtotime('-1 year'), '<')
  ->execute();

// Raw query (use sparingly)
$result = $database->query("SELECT * FROM {mytable} WHERE name = :name", [
  ':name' => 'John',
])->fetchAll();
```

---

## Theming Basics

### Override Templates

Templates live in your theme directory:

```
mytheme/
├── mytheme.info.yml
├── mytheme.theme          # Preprocess functions
└── templates/
    ├── node--article.html.twig
    ├── page.html.twig
    └── block--system-branding-block.html.twig
```

**Example template (templates/node--article.html.twig):**
```twig
<article{{ attributes.addClass('article', 'article--full') }}>
  
  {% if label %}
    <h1{{ title_attributes.addClass('article__title') }}>
      {{ label }}
    </h1>
  {% endif %}
  
  {% if display_submitted %}
    <div class="article__meta">
      By {{ author_name }} on {{ date }}
    </div>
  {% endif %}
  
  <div{{ content_attributes.addClass('article__content') }}>
    {{ content }}
  </div>
  
</article>
```

**Preprocess function (mytheme.theme):**
```php
<?php

/**
 * Implements template_preprocess_node().
 */
function mytheme_preprocess_node(&$variables) {
  $node = $variables['node'];
  
  // Add custom variables
  $variables['author_name'] = $node->getOwner()->getDisplayName();
  $variables['date'] = \Drupal::service('date.formatter')
    ->format($node->getCreatedTime(), 'custom', 'F j, Y');
    
  // Add custom class based on field
  if ($node->hasField('field_featured') && $node->get('field_featured')->value) {
    $variables['attributes']['class'][] = 'article--featured';
  }
}
```

### Adding CSS/JS

**mytheme.libraries.yml:**
```yaml
global-styling:
  css:
    theme:
      css/style.css: {}
  js:
    js/script.js: {}
  dependencies:
    - core/jquery
    - core/drupal

article-enhancements:
  js:
    js/article.js: {}
  dependencies:
    - mytheme/global-styling
```

**Attach library in template:**
```twig
{{ attach_library('mytheme/article-enhancements') }}
```

**Or in preprocess:**
```php
$variables['#attached']['library'][] = 'mytheme/article-enhancements';
```

---

## Debugging Tips

### 1. Enable Development Settings

**web/sites/development.services.yml:**
```yaml
parameters:
  http.response.debug_cacheability_headers: true
  twig.config:
    debug: true
    auto_reload: true
    cache: false
services:
  cache.backend.null:
    class: Drupal\Core\Cache\NullBackendFactory
```

**In web/sites/default/settings.php:**
```php
// Enable local development services.
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
```

**Create web/sites/default/settings.local.php:**
```php
<?php

// Disable CSS/JS aggregation
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

// Disable render cache
$settings['cache']['bins']['render'] = 'cache.backend.null';
$settings['cache']['bins']['page'] = 'cache.backend.null';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';

// Enable verbose error display
$config['system.logging']['error_level'] = 'verbose';

// Enable development services
$settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
```

### 2. Useful Debugging Functions

```php
// Dump and die (requires Devel module)
dpm($variable);  // Print to message area
kint($variable);  // Better formatted output
ksm($variable);  // Print to message area (safe for production)

// Standard PHP debugging
var_dump($variable);
print_r($variable);

// Drupal logger
\Drupal::logger('mymodule')->notice('Debug: @var', ['@var' => print_r($variable, TRUE)]);

// Watchdog (same as logger)
\Drupal::logger('mymodule')->error('Error: @message', ['@message' => $error_message]);
```

### 3. Twig Debugging

With twig debug enabled, you'll see HTML comments showing:
- Template file suggestions
- Which template is being used
- Where it's located

```twig
{# Dump all variables #}
{{ dump() }}

{# Dump specific variable #}
{{ dump(content) }}

{# Dump with kint (better formatting) #}
{{ kint(content) }}
```

### 4. Common Commands for Debugging

```bash
# View recent errors
ddev drush watchdog:show --severity=Error

# Tail error log
ddev drush watchdog:tail

# Show all routes
ddev drush route

# Show available plugins
ddev drush plugin:list

# Check system status
ddev drush status

# Review configuration
ddev drush config:get system.site
ddev drush config:edit system.site

# SQL queries
ddev drush sql:query "SELECT * FROM watchdog ORDER BY wid DESC LIMIT 10"
```

---

## Configuration Management Workflow

This is critical for team development:

### Initial Setup

```bash
# Set config sync directory (usually already set in settings.php)
# Check current setting:
ddev drush status | grep "Sync config"

# If not set, add to settings.php:
# $settings['config_sync_directory'] = '../config/sync';
```

### Development Workflow

```bash
# 1. Make changes in UI (create content types, views, etc.)

# 2. Export configuration to files
ddev drush config:export -y

# 3. Review what changed
git diff config/sync/

# 4. Commit configuration
git add config/sync
git commit -m "Added blog content type with custom fields"

# 5. Push to repository
git push origin feature/blog-content-type

# On another environment (staging, production, teammate's local):

# 6. Pull changes
git pull origin feature/blog-content-type

# 7. Import configuration
ddev drush config:import -y

# 8. Clear cache
ddev drush cr
```

### Handling Config Conflicts

```bash
# Show differences between active and sync config
ddev drush config:status

# Show specific differences
ddev drush config:diff system.site

# Import single configuration item
ddev drush config:import --partial --source=config/sync

# Export single configuration item
ddev drush config:export system.site --destination=/tmp
```

### Configuration Split (Advanced)

For environment-specific config (dev modules, production caching):

```bash
ddev composer require drupal/config_split
ddev drush pm:enable config_split -y

# Configure splits via UI or config
# Then export/import as normal
```

---

## Module Development Best Practices

### 1. Code Standards

Install PHP CodeSniffer with Drupal standards:

```bash
ddev composer require --dev drupal/coder
ddev composer require --dev dealerdirect/phpcodesniffer-composer-installer

# Check your code
ddev exec phpcs --standard=Drupal web/modules/custom/mymodule

# Auto-fix issues
ddev exec phpcbf --standard=Drupal web/modules/custom/mymodule
```

### 2. Automated Testing

```bash
# Install PHPUnit
ddev composer require --dev phpunit/phpunit

# Run core tests (example)
ddev exec -d /var/www/html/web/core php ../../vendor/bin/phpunit

# Run your module tests
ddev exec php vendor/bin/phpunit web/modules/custom/mymodule/tests
```

**Example test (tests/src/Kernel/MyServiceTest.php):**
```php
<?php

namespace Drupal\Tests\mymodule\Kernel;

use Drupal\KernelTests\KernelTestBase;

class MyServiceTest extends KernelTestBase {

  protected static $modules = ['mymodule'];

  public function testServiceExists() {
    $service = \Drupal::service('mymodule.my_service');
    $this->assertNotNull($service);
  }

}
```

### 3. Documentation

Use PHPDoc comments extensively:

```php
/**
 * Service for managing custom data.
 */
class MyCustomService {

  /**
   * The entity type manager.
   *
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface
   */
  protected $entityTypeManager;

  /**
   * Constructs a MyCustomService object.
   *
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entity_type_manager
   *   The entity type manager service.
   */
  public function __construct(EntityTypeManagerInterface $entity_type_manager) {
    $this->entityTypeManager = $entity_type_manager;
  }

  /**
   * Retrieves recent articles.
   *
   * @param int $limit
   *   The maximum number of articles to return.
   *
   * @return \Drupal\node\NodeInterface[]
   *   An array of article nodes.
   */
  public function getRecentArticles($limit = 10) {
    // Implementation
  }

}
```

### 4. Update Hooks

When deploying changes to existing sites:

```php
/**
 * @file
 * Install, update and uninstall functions for My Module.
 */

/**
 * Implements hook_install().
 */
function mymodule_install() {
  // Run when module is first installed
  \Drupal::messenger()->addMessage(t('My Module has been installed.'));
}

/**
 * Implements hook_uninstall().
 */
function mymodule_uninstall() {
  // Clean up when module is uninstalled
  \Drupal::state()->delete('mymodule.settings');
}

/**
 * Implements hook_schema().
 */
function mymodule_schema() {
  $schema['mytable'] = [
    'description' => 'Stores custom data.',
    'fields' => [
      'id' => [
        'type' => 'serial',
        'not null' => TRUE,
      ],
      'name' => [
        'type' => 'varchar',
        'length' => 255,
        'not null' => TRUE,
      ],
      'created' => [
        'type' => 'int',
        'not null' => TRUE,
      ],
    ],
    'primary key' => ['id'],
  ];
  return $schema;
}

/**
 * Add new field to custom table.
 */
function mymodule_update_8001() {
  $schema = \Drupal::database()->schema();
  $schema->addField('mytable', 'email', [
    'type' => 'varchar',
    'length' => 255,
    'description' => 'Email address',
  ]);
}

/**
 * Import new configuration.
 */
function mymodule_update_8002() {
  \Drupal::service('config.installer')->installDefaultConfig('module', 'mymodule');
}
```

Run updates:
```bash
ddev drush updatedb -y
# or
ddev drush updb -y
```

---

## Common Gotchas and Solutions

### 1. Cache, Cache, Cache

Drupal caches EVERYTHING. When things don't update:

```bash
# Clear all caches (do this first)
ddev drush cr

# Specific cache bins
ddev drush cache:clear render
ddev drush cache:clear discovery  # For plugin changes
```

In development, disable caching (see Debugging section).

### 2. Permissions

Always check permissions:

```bash
# View permissions for a module
ddev drush role:list
ddev drush role:perm:list 'authenticated'

# Grant permission
ddev drush role:perm:add 'authenticated' 'access custom content'
```

In code:
```php
// Check permission
if (\Drupal::currentUser()->hasPermission('access custom content')) {
  // Do something
}
```

### 3. Render Arrays vs Strings

Always return render arrays from controllers, not HTML strings:

```php
// Wrong
public function build() {
  return '<p>Hello World</p>';
}

// Right
public function build() {
  return [
    '#markup' => '<p>Hello World</p>',
  ];
}

// Even better (with caching)
public function build() {
  return [
    '#markup' => $this->t('Hello World'),
    '#cache' => [
      'max-age' => 3600,
    ],
  ];
}
```

### 4. Always Use Dependency Injection

```php
// Bad (static calls)
$database = \Drupal::database();
$config = \Drupal::config('mymodule.settings');

// Good (dependency injection)
class MyService {
  protected $database;
  protected $config;
  
  public function __construct(Connection $database, ConfigFactoryInterface $config_factory) {
    $this->database = $database;
    $this->config = $config_factory->get('mymodule.settings');
  }
  
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('database'),
      $container->get('config.factory')
    );
  }
}
```

### 5. Field Access

Always check field existence before accessing:

```php
// Wrong
$value = $node->field_custom->value;  // Fatal error if field doesn't exist

// Right
if ($node->hasField('field_custom') && !$node->get('field_custom')->isEmpty()) {
  $value = $node->get('field_custom')->value;
}
```

---

## Essential Contributed Modules

Install these for better development experience:

```bash
# Development tools
ddev composer require --dev drupal/devel
ddev composer require --dev drupal/devel_php  # PHP execution page
ddev drush pm:enable devel devel_generate -y

# Better admin UI
ddev composer require drupal/admin_toolbar
ddev drush pm:enable admin_toolbar admin_toolbar_tools -y

# Configuration management helpers
ddev composer require drupal/config_split  # Environment-specific config
ddev composer require drupal/config_ignore  # Ignore specific config

# Entity operations
ddev composer require drupal/entity  # Enhanced entity operations
ddev composer require drupal/entity_browser  # Better entity selection

# Field enhancements
ddev composer require drupal/field_group  # Group fields in forms/displays
ddev composer require drupal/link_attributes  # Add classes/target to links

# Site building
ddev composer require drupal/pathauto  # Auto-generate URLs
ddev composer require drupal/token  # Token system for patterns
ddev composer require drupal/metatag  # SEO meta tags

# Performance
ddev composer require drupal/redis  # Redis caching
ddev composer require drupal/memcache  # Memcache support
```

---

## Next Steps

1. **Read the Official Docs**: https://www.drupal.org/docs/develop
2. **API Reference**: https://api.drupal.org/api/drupal/10
3. **Drupal Code Examples**: Install the `examples` module for annotated code
4. **Join the Community**: 
   - Drupal Slack: https://www.drupal.org/slack
   - Stack Exchange: https://drupal.stackexchange.com/
5. **Build Something**: The best way to learn is by doing

### Project Ideas to Practice

1. **Custom content type with workflow**: Blog with draft/published states
2. **Custom block showing dynamic content**: "Recent Posts" block
3. **Form with email sending**: Contact form with email notifications
4. **Custom admin page**: Dashboard with statistics
5. **API endpoint**: JSON endpoint for external consumption
6. **Custom field type**: Special field with custom storage/display
7. **Configuration form**: Module settings page

---

## Quick Reference Card

```bash
# Start/stop
ddev start
ddev stop
ddev restart

# Access
ddev ssh
ddev drush uli  # Get login link

# Cache
ddev drush cr

# Config
ddev drush cex -y  # Export
ddev drush cim -y  # Import

# Modules
ddev composer require drupal/module_name
ddev drush en module_name -y
ddev drush pmu module_name -y

# Database
ddev snapshot
ddev snapshot restore
ddev import-db --file=dump.sql

# Debugging
ddev drush ws --extended
ddev logs -f

# Code generation
ddev drush generate

# Updates
ddev composer update drupal/core --with-dependencies
ddev drush updb -y
```

---

Good luck with your Drupal development journey! Remember: when in doubt, clear the cache (`ddev drush cr`), and don't hesitate to use `ddev drush generate` to scaffold code rather than starting from scratch.
