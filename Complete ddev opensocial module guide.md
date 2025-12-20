# Complete Guide: DDEV, OpenSocial, and Custom Module Development

> **📊 Database Note:** This guide uses **MariaDB** (not MySQL) as the database system. MariaDB is the recommended default for DDEV and is fully compatible with Drupal/OpenSocial. While the connection protocol uses `mysql://`, the actual database server is MariaDB. This is intentional and correct.

## Table of Contents
1. [Installing DDEV on Ubuntu](#part-1-installing-ddev-on-ubuntu)
2. [Installing OpenSocial with DDEV](#part-2-installing-opensocial-with-ddev)
3. [Creating a Custom Module to Add Fields](#part-3-creating-a-custom-module-to-add-fields-to-content-types)
4. [Sources and Currency](#sources-and-currency)

---

## Part 1: Installing DDEV on Ubuntu

### Prerequisites Check

First, ensure your system is up to date:

```bash
sudo apt update
sudo apt upgrade -y
```

### Step 1: Install Docker Engine

DDEV requires Docker to run containers. **Important:** Do NOT use Docker Desktop on Linux - use Docker Engine instead.

#### 1.1: Remove Conflicting Packages

```bash
# Remove any conflicting packages (safe to run even if none are installed)
sudo apt remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null || true
```

#### 1.2: Install Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

#### 1.3: Add Docker's Official GPG Key (Modern Method)

```bash
# Create keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# Download and install Docker's GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set proper permissions
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

> **Note:** This method replaces the deprecated `apt-key add` approach.

#### 1.4: Add Docker Repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### 1.5: Install Docker Engine

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### 1.6: Configure Docker for Non-Root Access

```bash
# Create docker group (may already exist)
sudo groupadd docker 2>/dev/null || true

# Add your user to docker group
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker
```

**CRITICAL:** Log out and log back in for group membership to take effect, or run:

```bash
newgrp docker
```

#### 1.7: Verify Docker Installation

```bash
docker --version
docker ps
docker run hello-world
```

If `docker ps` returns "permission denied," you need to log out and back in.

### Step 2: Install mkcert (SSL Certificate Tool)

```bash
# Install dependencies
sudo apt install -y libnss3-tools

# Download latest mkcert
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/$(dpkg --print-architecture)"

# Make executable and install
chmod +x mkcert-v*-linux-*
sudo mv mkcert-v*-linux-* /usr/local/bin/mkcert

# Install local CA
mkcert -install
```

### Step 3: Install DDEV

```bash
# Install DDEV using the official script
curl -fsSL https://ddev.com/install.sh | bash
```

**Install specific version (optional):**

```bash
curl -fsSL https://ddev.com/install.sh | bash -s v1.24.10
```

#### 3.1: Verify DDEV Installation

```bash
ddev version
ddev debug test
```

### Step 4: Configure DDEV (Optional but Recommended)

```bash
mkdir -p ~/.ddev
cat > ~/.ddev/global_config.yaml << 'EOF'
# Use localhost instead of *.ddev.site for simpler DNS
use_dns_when_possible: false

# Set your preferred router ports (useful if 80/443 are taken)
router_http_port: "80"
router_https_port: "443"

# Disable usage analytics if desired
instrumentation_opt_in: false

# Set default PHP version for new projects
php_version: "8.3"
EOF
```

### Gotchas - DDEV Installation

| Problem | Solution |
|---------|----------|
| Permission Denied Error | Log out and back in, or run `newgrp docker` |
| Port 80/443 Already in Use | Stop local web servers: `sudo systemctl stop apache2 nginx` or change DDEV ports |
| Docker Not Starting on Boot | `sudo systemctl enable docker` |
| DNS Issues with *.ddev.site | Set `use_dns_when_possible: false` in global config |
| Old DDEV Version After Upgrade | Run `which -a ddev` and remove old binaries |

---

## Part 2: Installing OpenSocial with DDEV

OpenSocial is a Drupal distribution for building online communities. This section covers the correct workflow for installing it with DDEV.

### Understanding the Directory Structure

**Critical:** OpenSocial's `social_template` creates its own directory structure with `html/` as the webroot. The correct workflow is:

1. Create project using Composer **first** (outside DDEV)
2. Configure DDEV inside the created project directory
3. Start DDEV and run site installation

### Method 1: Recommended Installation (Composer First)

This is the most reliable method and avoids directory structure conflicts.

#### Step 1: Create Project with Composer

```bash
# Navigate to your projects directory
cd ~/projects

# Create OpenSocial project using Composer (this creates the directory)
composer create-project goalgorilla/social_template:dev-master opensocial --no-interaction

# Enter the project directory
cd opensocial
```

> **Note:** This creates a directory called `opensocial` with the correct structure including `html/` as the webroot.

**Alternative - Specify a version:**

```bash
# For a specific stable version
composer create-project goalgorilla/social_template:^12.0 opensocial --no-interaction
```

#### Step 2: Configure DDEV

```bash
# Configure DDEV for Drupal with html docroot
ddev config --project-type=drupal --docroot=html --php-version=8.3
```

This creates `.ddev/config.yaml`. Verify the configuration:

```bash
cat .ddev/config.yaml
```

You should see:

```yaml
name: opensocial
type: drupal
docroot: html
php_version: "8.3"
...
```

#### Step 3: Increase PHP Memory (Recommended)

OpenSocial installation can be memory-intensive:

```bash
mkdir -p .ddev/php
cat > .ddev/php/memory.ini << 'EOF'
memory_limit = 512M
max_execution_time = 600
EOF
```

#### Step 4: Start DDEV

```bash
ddev start
```

**Verify database type:**

```bash
ddev describe
```

Look for:
```
DATABASE
  Type: mariadb
  Version: 10.11
```

#### Step 5: Install Drupal with OpenSocial Profile

```bash
ddev drush site:install social \
  --db-url=mysql://db:db@db:3306/db \
  --account-name=admin \
  --account-pass=admin \
  --site-name="My OpenSocial Site" \
  -y
```

> **Note:** The `mysql://` protocol is used even though DDEV uses MariaDB, because MariaDB is MySQL-compatible.

**This installation takes 10-15 minutes.** Monitor progress in another terminal:

```bash
ddev logs -f
```

#### Step 6: Access Your Site

```bash
ddev launch
```

Or get a one-time login link:

```bash
ddev drush uli
```

---

### Method 2: Alternative Installation (DDEV First)

If you prefer to set up DDEV first, use this method. It requires careful handling of the directory structure.

#### Step 1: Create and Configure DDEV Project

```bash
cd ~/projects
mkdir opensocial && cd opensocial

# Configure DDEV WITHOUT creating docroot yet
ddev config --project-type=drupal --docroot=html --php-version=8.3
```

#### Step 2: Increase PHP Memory

```bash
mkdir -p .ddev/php
echo "memory_limit = 512M" > .ddev/php/memory.ini
```

#### Step 3: Start DDEV

```bash
ddev start
```

#### Step 4: Install OpenSocial Using ddev composer

**Important:** With DDEV, `ddev composer create` works differently than standard Composer. It installs to the project root (where `composer.json` will live), and the template includes `html/` as a subdirectory.

```bash
# This installs the social_template which includes the html/ directory
ddev composer create goalgorilla/social_template:dev-master
```

> **Note:** Unlike the host Composer command, `ddev composer create` doesn't take a directory argument - it installs to the current project root.

If you encounter memory errors:

```bash
ddev exec "COMPOSER_MEMORY_LIMIT=-1 composer create-project goalgorilla/social_template:dev-master /tmp/social_temp --no-interaction"
ddev exec "cp -r /tmp/social_temp/. /var/www/html/"
ddev exec "rm -rf /tmp/social_temp"
```

#### Step 5: Verify Installation

```bash
ddev exec ls -la html/
```

You should see:
- `core/` - Drupal core
- `modules/` - Contrib and custom modules
- `profiles/` - Installation profiles (including social)
- `sites/` - Site configuration
- `themes/` - Themes

#### Step 6: Run Site Installation

```bash
ddev drush site:install social \
  --db-url=mysql://db:db@db:3306/db \
  --account-name=admin \
  --account-pass=admin \
  --site-name="My OpenSocial Site" \
  -y
```

#### Step 7: Clear Cache and Launch

```bash
ddev drush cr
ddev launch
```

---

### Post-Installation Steps

#### Clear Cache

```bash
ddev drush cr
```

#### Check System Status

```bash
ddev drush status
```

#### Export Configuration for Version Control

```bash
ddev drush config:export -y
```

#### Working with MariaDB Database

**Access MariaDB command line:**

```bash
ddev mysql
```

**Check MariaDB version:**

```bash
ddev exec mysql -e "SELECT VERSION();"
```

**Export database:**

```bash
ddev export-db --file=database-backup.sql.gz
```

**Import database:**

```bash
ddev import-db --file=database-backup.sql.gz
```

### Version Control Setup

```bash
git init

cat > .gitignore << 'EOF'
# DDEV
.ddev/.gitignore
.ddev/db_snapshots/
.ddev/homeadditions/
.ddev/commands/web/
.ddev/commands/host/

# Drupal
html/sites/*/files/
html/sites/*/private/
html/core/
html/vendor/
html/modules/contrib/
html/themes/contrib/

# Keep custom work
!html/modules/custom/
!html/themes/custom/

# IDE
.idea/
.vscode/
EOF

git add .
git commit -m "Initial OpenSocial installation with DDEV"
```

### Gotchas - OpenSocial Installation

| Problem | Solution |
|---------|----------|
| Wrong Docroot | OpenSocial uses `html/` not `web/`. Ensure `.ddev/config.yaml` has `docroot: html` |
| Composer Memory Errors | Add `memory_limit = 512M` to `.ddev/php/memory.ini` and restart |
| Database Connection Errors | Use `mysql://db:db@db:3306/db` (DDEV's default credentials) |
| Site Install Hangs | Wait 10-15 minutes. Monitor with `ddev logs -f` |
| Permission Errors in Files | `ddev ssh` then `chmod -R 777 sites/default/files` |
| MariaDB Character Set Issues | Verify with `ddev exec mysql -e "SHOW VARIABLES LIKE 'character_set%';"` |
| Directory Structure Confusion | Use Method 1 (Composer first) to avoid conflicts |

---

## Part 3: Creating a Custom Module to Add Fields to Content Types

### Step 1: Generate Module Scaffold

```bash
ddev ssh
cd /var/www/html
mkdir -p modules/custom
cd modules/custom
drush generate module
```

Answer the prompts:

```
Module name: Field Manager
Module machine name: field_manager
Module description: Allows adding fields to content types via admin interface
Package: Custom
Dependencies: 
Would you like to create module file?: Yes
Would you like to create install file?: Yes
Would you like to create README.md?: Yes
```

Exit the container:

```bash
exit
```

### Step 2: Update Module Info File

```bash
cat > html/modules/custom/field_manager/field_manager.info.yml << 'EOF'
name: 'Field Manager'
type: module
description: 'Allows administrators to add fields to content types through a user interface.'
package: Custom
core_version_requirement: ^10 || ^11
dependencies:
  - drupal:field
  - drupal:node
  - drupal:field_ui
EOF
```

### Step 3: Create the Admin Form

```bash
ddev drush generate form
```

Answer prompts:

```
Module name: field_manager
Class: AddFieldForm
Form ID: field_manager_add_field
Create route?: Yes
Route path: /admin/structure/types/add-field
Route title: Add Field to Content Type
Route permission: administer content types
```

### Step 4: Implement the Add Field Form

```bash
cat > html/modules/custom/field_manager/src/Form/AddFieldForm.php << 'PHPEOF'
<?php

namespace Drupal\field_manager\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Entity\EntityDisplayRepositoryInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Provides a form to add fields to content types.
 */
class AddFieldForm extends FormBase {

  /**
   * The entity type manager.
   *
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface
   */
  protected $entityTypeManager;

  /**
   * The entity display repository.
   *
   * @var \Drupal\Core\Entity\EntityDisplayRepositoryInterface
   */
  protected $entityDisplayRepository;

  /**
   * Constructs a new AddFieldForm object.
   */
  public function __construct(
    EntityTypeManagerInterface $entity_type_manager,
    EntityDisplayRepositoryInterface $entity_display_repository
  ) {
    $this->entityTypeManager = $entity_type_manager;
    $this->entityDisplayRepository = $entity_display_repository;
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('entity_type.manager'),
      $container->get('entity_display.repository')
    );
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'field_manager_add_field';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {
    // Get all content types
    $content_types = $this->entityTypeManager
      ->getStorage('node_type')
      ->loadMultiple();

    $type_options = [];
    foreach ($content_types as $type) {
      $type_options[$type->id()] = $type->label();
    }

    $form['content_type'] = [
      '#type' => 'select',
      '#title' => $this->t('Content Type'),
      '#description' => $this->t('Select the content type to add a field to.'),
      '#options' => $type_options,
      '#required' => TRUE,
      '#empty_option' => $this->t('- Select a content type -'),
    ];

    $form['field_name'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Field Machine Name'),
      '#description' => $this->t('Enter the machine name for the field. Must start with "field_" and contain only lowercase letters, numbers, and underscores.'),
      '#required' => TRUE,
      '#maxlength' => 32,
      '#pattern' => 'field_[a-z0-9_]+',
      '#field_prefix' => '',
    ];

    $form['field_label'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Field Label'),
      '#description' => $this->t('Enter the human-readable label for the field.'),
      '#required' => TRUE,
    ];

    $form['field_type'] = [
      '#type' => 'select',
      '#title' => $this->t('Field Type'),
      '#description' => $this->t('Select the type of field to create.'),
      '#options' => [
        'string' => $this->t('Text (plain)'),
        'string_long' => $this->t('Text (plain, long)'),
        'text' => $this->t('Text (formatted)'),
        'text_long' => $this->t('Text (formatted, long)'),
        'text_with_summary' => $this->t('Text (formatted, long, with summary)'),
        'integer' => $this->t('Number (integer)'),
        'decimal' => $this->t('Number (decimal)'),
        'float' => $this->t('Number (float)'),
        'boolean' => $this->t('Boolean'),
        'email' => $this->t('Email'),
        'datetime' => $this->t('Date'),
        'link' => $this->t('Link'),
        'image' => $this->t('Image'),
        'file' => $this->t('File'),
        'list_string' => $this->t('List (text)'),
        'entity_reference' => $this->t('Entity reference'),
      ],
      '#required' => TRUE,
    ];

    $form['required'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Required field'),
      '#description' => $this->t('Check this box to make the field required.'),
    ];

    $form['cardinality'] = [
      '#type' => 'number',
      '#title' => $this->t('Number of values'),
      '#description' => $this->t('Enter -1 for unlimited values, or a specific number.'),
      '#default_value' => 1,
      '#required' => TRUE,
      '#min' => -1,
    ];

    $form['actions'] = ['#type' => 'actions'];
    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Add Field'),
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function validateForm(array &$form, FormStateInterface $form_state) {
    $field_name = $form_state->getValue('field_name');

    // Check if field name starts with 'field_'
    if (strpos($field_name, 'field_') !== 0) {
      $form_state->setErrorByName('field_name', $this->t('Field machine name must start with "field_".'));
      return;
    }

    // Check for valid characters
    if (!preg_match('/^field_[a-z0-9_]+$/', $field_name)) {
      $form_state->setErrorByName('field_name', $this->t('Field machine name can only contain lowercase letters, numbers, and underscores.'));
      return;
    }

    // Check if field already exists on this content type
    $content_type = $form_state->getValue('content_type');
    $field = FieldConfig::loadByName('node', $content_type, $field_name);
    if ($field) {
      $form_state->setErrorByName('field_name',
        $this->t('This field already exists on the selected content type.'));
    }
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $field_name = $form_state->getValue('field_name');
    $content_type = $form_state->getValue('content_type');
    $field_label = $form_state->getValue('field_label');
    $field_type = $form_state->getValue('field_type');
    $required = (bool) $form_state->getValue('required');
    $cardinality = (int) $form_state->getValue('cardinality');

    try {
      // Check if field storage already exists (may be used on other bundles)
      $field_storage = FieldStorageConfig::loadByName('node', $field_name);

      if (!$field_storage) {
        // Create field storage
        $field_storage = FieldStorageConfig::create([
          'field_name' => $field_name,
          'entity_type' => 'node',
          'type' => $field_type,
          'cardinality' => $cardinality,
        ]);
        $field_storage->save();

        $this->messenger()->addStatus(
          $this->t('Field storage @field created.', ['@field' => $field_name])
        );
      }

      // Create field instance
      $field = FieldConfig::create([
        'field_storage' => $field_storage,
        'bundle' => $content_type,
        'label' => $field_label,
        'required' => $required,
      ]);
      $field->save();

      // Configure form display
      $this->entityDisplayRepository->getFormDisplay('node', $content_type, 'default')
        ->setComponent($field_name, [
          'type' => $this->getDefaultWidget($field_type),
          'weight' => 10,
        ])
        ->save();

      // Configure view display
      $this->entityDisplayRepository->getViewDisplay('node', $content_type, 'default')
        ->setComponent($field_name, [
          'type' => $this->getDefaultFormatter($field_type),
          'label' => 'above',
          'weight' => 10,
        ])
        ->save();

      $this->messenger()->addStatus(
        $this->t('Field "@label" has been added to @type.', [
          '@label' => $field_label,
          '@type' => $content_type,
        ])
      );

      // Rebuild cache
      \Drupal::service('cache.discovery')->deleteAll();

    }
    catch (\Exception $e) {
      $this->messenger()->addError(
        $this->t('Error creating field: @message', ['@message' => $e->getMessage()])
      );
      $this->getLogger('field_manager')->error('Error creating field: @message', [
        '@message' => $e->getMessage(),
      ]);
    }
  }

  /**
   * Get default widget type for field type.
   */
  protected function getDefaultWidget($field_type) {
    $widgets = [
      'string' => 'string_textfield',
      'string_long' => 'string_textarea',
      'text' => 'text_textfield',
      'text_long' => 'text_textarea',
      'text_with_summary' => 'text_textarea_with_summary',
      'integer' => 'number',
      'decimal' => 'number',
      'float' => 'number',
      'boolean' => 'boolean_checkbox',
      'email' => 'email_default',
      'datetime' => 'datetime_default',
      'link' => 'link_default',
      'image' => 'image_image',
      'file' => 'file_generic',
      'list_string' => 'options_select',
      'entity_reference' => 'entity_reference_autocomplete',
    ];
    return $widgets[$field_type] ?? 'string_textfield';
  }

  /**
   * Get default formatter type for field type.
   */
  protected function getDefaultFormatter($field_type) {
    $formatters = [
      'string' => 'string',
      'string_long' => 'basic_string',
      'text' => 'text_default',
      'text_long' => 'text_default',
      'text_with_summary' => 'text_default',
      'integer' => 'number_integer',
      'decimal' => 'number_decimal',
      'float' => 'number_decimal',
      'boolean' => 'boolean',
      'email' => 'basic_string',
      'datetime' => 'datetime_default',
      'link' => 'link',
      'image' => 'image',
      'file' => 'file_default',
      'list_string' => 'list_default',
      'entity_reference' => 'entity_reference_label',
    ];
    return $formatters[$field_type] ?? 'string';
  }

}
PHPEOF
```

### Step 5: Create Menu Link

```bash
cat > html/modules/custom/field_manager/field_manager.links.menu.yml << 'EOF'
field_manager.add_field:
  title: 'Add Field to Type'
  description: 'Add a field to any content type'
  parent: system.admin_structure
  route_name: field_manager.add_field
  weight: 10
EOF
```

### Step 6: Enable the Module

```bash
ddev drush cr
ddev drush pm:enable field_manager -y
```

### Step 7: Test the Module

```bash
ddev launch /admin/structure/types/add-field
```

### Gotchas - Module Development

| Problem | Solution |
|---------|----------|
| Module Not Found | Always run `ddev drush cr` after creating modules |
| Permission Denied | Ensure user has "administer content types" permission |
| Field Name Error | All field names MUST start with `field_` |
| Class Not Found | Check namespace matches directory structure, then `ddev drush cr` |
| Changes Not Taking Effect | Run `ddev drush cr && ddev drush updb -y && ddev drush cr` |

---

## Part 4: Sources and Currency

### Version Compatibility

**This guide is tested for:**

| Component | Versions |
|-----------|----------|
| Ubuntu | 22.04, 24.04 LTS |
| DDEV | v1.23.x - v1.24.x |
| Docker Engine | 24.x, 25.x |
| Drupal | 10.x, 11.x |
| OpenSocial | 12.x (current stable: ~12.4.0) |
| Drush | 12.x, 13.x |
| PHP | 8.2, 8.3 |
| MariaDB | 10.6, 10.11, 11.4 |

### Primary Sources

1. **DDEV Documentation** - https://ddev.readthedocs.io/ (Current)
2. **Docker Installation for Ubuntu** - https://docs.docker.com/engine/install/ubuntu/ (Current)
3. **Open Social on Drupal.org** - https://www.drupal.org/project/social (Updated 2024)
4. **Drupal API Documentation** - https://api.drupal.org/ (Always current)
5. **social_template on Packagist** - https://packagist.org/packages/goalgorilla/social_template (Updated September 2025)

### Verification Commands

```bash
# System
lsb_release -a
uname -m

# Docker
docker --version
docker compose version

# DDEV
ddev version
ddev describe

# Inside DDEV
ddev exec php -v
ddev drush --version
ddev drush status
ddev exec mysql -e "SELECT VERSION();"
```

### Updates and Maintenance

```bash
# Update Ubuntu
sudo apt update && sudo apt upgrade -y

# Update Docker
sudo apt-get install --only-upgrade docker-ce docker-ce-cli

# Update DDEV
curl -fsSL https://ddev.com/install.sh | bash

# Update Drupal/OpenSocial
ddev composer update --with-all-dependencies
ddev drush updatedb -y
ddev drush cr
```

---

## Final Checklist

After following this guide, you should have:

- ✅ Docker Engine installed and configured for non-root access
- ✅ DDEV installed and verified
- ✅ mkcert certificates for local HTTPS
- ✅ MariaDB 10.11 as your database
- ✅ OpenSocial site running at https://opensocial.ddev.site
- ✅ Custom field_manager module created and enabled
- ✅ Ability to add fields to content types via UI

**Getting Help:**

- DDEV Discord: https://discord.gg/ddev
- Drupal Slack: #ddev and #opensocial channels
- OpenSocial Issue Queue: https://www.drupal.org/project/issues/social
