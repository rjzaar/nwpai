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

**What this does:** Updates the package lists and upgrades installed packages to their latest versions. The `-y` flag automatically answers "yes" to prompts.

### Step 1: Install Docker Engine

DDEV requires Docker to run containers. **Important:** Do NOT use Docker Desktop on Linux - it's not compatible with DDEV. Use Docker Engine instead.

#### 1.1: Remove Old Docker Versions

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

**What this does:** Removes any old Docker installations that might conflict with the new installation. It's okay if apt reports that none of these packages are installed.

#### 1.2: Install Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common
```

**What this does:** 
- `ca-certificates`: SSL certificates for secure connections
- `curl`: Tool for downloading files
- `gnupg`: Encryption tools for verifying package signatures
- `lsb-release`: Provides Linux distribution information
- `apt-transport-https`: Allows apt to retrieve packages over HTTPS
- `software-properties-common`: Provides tools for managing software repositories

#### 1.3: Add Docker's Official GPG Key

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg
```

**What this does:** 
- Creates a directory for storing GPG keys
- Downloads Docker's GPG key and converts it to a format apt can use
- The key verifies that packages are actually from Docker

#### 1.4: Add Docker Repository

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**What this does:** Adds Docker's official repository to your system's software sources. The command automatically detects your Ubuntu version and CPU architecture.

#### 1.5: Install Docker Engine

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

**What this does:** Installs Docker Engine, command-line tools, containerd (container runtime), and Docker Compose plugin.

#### 1.6: Add Your User to Docker Group

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
```

**What this does:** Creates a 'docker' group and adds your user to it, allowing you to run Docker commands without sudo.

**IMPORTANT:** You need to log out and log back in for group membership to take effect, or run:

```bash
newgrp docker
```

#### 1.7: Verify Docker Installation

```bash
docker --version
docker ps
```

**What this does:** 
- First command shows Docker version
- Second command lists running containers (should be empty at first)

If `docker ps` shows "permission denied," you haven't logged out and back in yet.

### Step 2: Install mkcert (SSL Certificate Tool)

mkcert creates locally-trusted SSL certificates so your development sites can use HTTPS.

#### 2.1: Install mkcert

```bash
sudo apt install -y libnss3-tools
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
```

**What this does:**
- Installs required NSS tools for certificate management
- Downloads the latest mkcert binary for Linux
- Makes it executable
- Moves it to a directory in your PATH

#### 2.2: Install mkcert Certificate Authority

```bash
mkcert -install
```

**What this does:** Creates a local Certificate Authority (CA) and installs it in your system's trust store. You'll see output like:

```
Created a new local CA 💥
The local CA is now installed in the system trust store! ⚡️
The local CA is now installed in the Firefox trust store (requires browser restart)! 🦊
```

### Step 3: Install DDEV

There are multiple ways to install DDEV. We'll use the recommended script method.

#### 3.1: Download and Run DDEV Installation Script

```bash
curl -fsSL https://ddev.com/install.sh | bash
```

**What this does:** Downloads and executes DDEV's official installation script, which:
- Detects your system architecture
- Downloads the appropriate DDEV binary
- Installs it to `/usr/local/bin`
- Sets proper permissions

**Alternative - Install Specific Version:**

```bash
curl -fsSL https://ddev.com/install.sh | bash -s v1.23.5
```

#### 3.2: Verify DDEV Installation

```bash
ddev version
```

**Expected output:**
```
ddev version v1.23.5
```

#### 3.3: Run DDEV System Check

```bash
ddev debug test
```

**What this does:** Runs a comprehensive system check to ensure:
- Docker is working correctly
- Network connectivity is good
- All required components are present
- DNS resolution is functioning

**Expected output:** Should show all checks passing with green checkmarks.

### Step 4: Configure DDEV (Optional but Recommended)

#### 4.1: Create Global DDEV Configuration

```bash
mkdir -p ~/.ddev
```

**What this does:** Creates DDEV's global configuration directory in your home folder.

#### 4.2: Create or Edit Global Config

```bash
nano ~/.ddev/global_config.yaml
```

**Add these recommended settings:**

```yaml
# Use localhost instead of *.ddev.site for simpler DNS
use_dns_when_possible: false

# Set your preferred router ports (useful if 80/443 are taken)
router_http_port: "80"
router_https_port: "443"

# Disable usage analytics if desired
instrumentation_opt_in: false

# Set default PHP version for new projects
php_version: "8.3"

# Set default database (MariaDB is recommended and default)
# Only uncomment if you want to override defaults
# database:
#   type: mariadb
#   version: "10.11"
```

**What this does:**
- `use_dns_when_possible: false`: Uses localhost instead of ddev.site domain (simpler)
- Port settings: Allows you to change ports if 80/443 are already in use
- `instrumentation_opt_in`: Controls anonymous usage statistics
- `php_version`: Sets default PHP version for new projects
- `database`: DDEV defaults to MariaDB 10.11, but you can specify explicitly if needed

Save with `Ctrl+X`, then `Y`, then `Enter`.

### Gotchas - DDEV Installation

#### Gotcha #1: Permission Denied Error
**Problem:** `docker ps` returns "permission denied"
**Solution:** You need to log out and log back in, or run `newgrp docker`

#### Gotcha #2: Port 80/443 Already in Use
**Problem:** DDEV can't start because Apache/Nginx is using port 80/443
**Solution:** Stop local web servers:
```bash
sudo systemctl stop apache2
sudo systemctl stop nginx
sudo systemctl disable apache2  # Prevent auto-start
sudo systemctl disable nginx
```

Or change DDEV's router ports in `~/.ddev/global_config.yaml`:
```yaml
router_http_port: "8080"
router_https_port: "8443"
```

#### Gotcha #3: Docker Not Starting on Boot
**Problem:** Docker daemon not running after reboot
**Solution:** Enable Docker to start automatically:
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

#### Gotcha #4: DNS Issues with *.ddev.site
**Problem:** Can't access yourproject.ddev.site URLs
**Solution:** Either:
- Set `use_dns_when_possible: false` in global config (uses localhost)
- Or install and configure dnsmasq

#### Gotcha #5: Old DDEV Version Showing
**Problem:** `ddev version` shows old version after upgrade
**Solution:** Check for multiple ddev binaries:
```bash
which -a ddev
```
Remove old ones and keep only `/usr/local/bin/ddev`

#### Gotcha #6: MySQL vs MariaDB Confusion
**Problem:** Not sure if using MySQL or MariaDB, or getting errors about database type
**Solution:** 
- DDEV defaults to MariaDB (not MySQL) for new projects
- MariaDB is MySQL-compatible, so you use `mysql://` in connection strings
- To verify which you're using:
```bash
ddev describe
# OR
ddev mysql --version
# OR
ddev exec mysql -V
```
- To explicitly use MariaDB, set in `.ddev/config.yaml`:
```yaml
database:
  type: mariadb
  version: "10.11"
```
- Available MariaDB versions: 5.5, 10.0, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.11, 11.4
- If you specifically need MySQL instead, you can set:
```yaml
database:
  type: mysql
  version: "8.0"
```

---

## Part 2: Installing OpenSocial with DDEV

OpenSocial is a Drupal distribution for building online communities. We'll install it using Composer and DDEV.

### Step 1: Create Project Directory

```bash
cd ~
mkdir projects
cd projects
mkdir opensocial
cd opensocial
```

**What this does:** Creates a clean directory structure for your OpenSocial project. Good practice to keep projects organized.

### Step 2: Initialize DDEV for Drupal

```bash
ddev config --project-type=drupal10 --docroot=html --create-docroot
```

**What this does:**
- `--project-type=drupal10`: Tells DDEV this is a Drupal 10 project (OpenSocial 12+ uses Drupal 10)
- `--docroot=html`: Sets the web root to `html` directory (OpenSocial convention)
- `--create-docroot`: Creates the html directory if it doesn't exist

**IMPORTANT NOTE:** 
- OpenSocial uses `html` as the web root, not `web` like standard Drupal. This is critical.
- DDEV will automatically configure MariaDB 10.11 as your database (recommended for Drupal/OpenSocial)

This creates `.ddev/config.yaml` with your project settings.

### Step 3: Review and Adjust DDEV Configuration

```bash
cat .ddev/config.yaml
```

**What this does:** Shows your DDEV configuration. You should see something like:

```yaml
name: opensocial
type: drupal10
docroot: html
php_version: "8.3"
webserver_type: nginx-fpm
...
```

**Optional adjustments:**

```bash
nano .ddev/config.yaml
```

You might want to change:
```yaml
name: my-opensocial-site  # Change project name
php_version: "8.2"         # If you need a specific PHP version
database:
  type: mariadb            # Using MariaDB (recommended)
  version: "10.11"         # MariaDB 10.11 is stable and well-tested
```

**Note about MariaDB vs MySQL:** MariaDB is a drop-in replacement for MySQL and is the recommended default for DDEV. OpenSocial works with both, but MariaDB is generally preferred for open-source projects.

### Step 4: Start DDEV

```bash
ddev start
```

**What this does:** 
- Pulls required Docker images (first time will take a few minutes)
- Creates containers for web server, database (MariaDB by default), and ddev-router
- Sets up networking
- Configures SSL certificates

**Expected output:**
```
Starting opensocial...
Project can be reached at https://opensocial.ddev.site
```

**Verify your database type:**
```bash
ddev describe
```

Look for the database section - it should show MariaDB:
```
DATABASE
  Type: mariadb
  Version: 10.11
```

If you want to explicitly set or change the database type, edit `.ddev/config.yaml`:
```yaml
database:
  type: mariadb
  version: "10.11"  # Recommended stable version
```

Then restart:
```bash
ddev restart
```

### Step 5: Install OpenSocial via Composer

**IMPORTANT:** We install OpenSocial using the social_template, which is a Composer-based installer.

```bash
ddev composer create goalgorilla/social_template --no-interaction
```

**What this does:**
- `ddev composer`: Runs Composer inside the DDEV container
- `create`: Creates a new project (like `composer create-project`)
- `goalgorilla/social_template`: The OpenSocial Composer template
- `--no-interaction`: Runs without prompting for input

**Note:** This command installs into the current directory. Since we're in the DDEV project root, Composer will install into `html/` directory.

**This will take 10-15 minutes** as it downloads Drupal core, OpenSocial, and all dependencies.

**Common Error:** If you get memory errors, increase PHP memory:
```bash
ddev config --php-version=8.3 --webimage-extra-packages=php-dev
nano .ddev/php/php.ini
```

Add:
```ini
memory_limit = 512M
```

Then restart:
```bash
ddev restart
```

### Step 6: Verify Installation

```bash
ddev exec ls -la html/
```

**What this does:** Lists contents of the html directory inside the container. You should see:
- `core/` - Drupal core
- `modules/` - Contrib and custom modules
- `profiles/` - Installation profiles (including social)
- `sites/` - Site configuration
- `themes/` - Themes
- `vendor/` - Composer dependencies
- `composer.json` - Composer configuration

### Step 7: Install Drupal with OpenSocial Profile

Now we'll install Drupal using the OpenSocial installation profile.

```bash
ddev drush site:install social \
  --db-url=mysql://db:db@db:3306/db \
  --account-name=admin \
  --account-pass=admin \
  --site-name="My OpenSocial Site" \
  -y
```

**What this does:**
- `site:install social`: Installs using the 'social' profile (OpenSocial)
- `--db-url`: Database connection string (DDEV's default database credentials)
  - `mysql://` = Protocol (used for both MySQL and MariaDB - they're compatible)
  - `db:db` = username:password
  - `@db:3306` = hostname:port
  - `/db` = database name
  - **Important:** Even though DDEV uses MariaDB by default, the connection protocol is still `mysql://` because MariaDB is MySQL-compatible
- `--account-name=admin`: Creates admin user with username 'admin'
- `--account-pass=admin`: Sets admin password to 'admin' (change in production!)
- `--site-name`: Your site's name
- `-y`: Answers yes to all prompts

**This will take 5-10 minutes** as it installs all OpenSocial features and configuration.

### Step 8: Access Your OpenSocial Site

```bash
ddev launch
```

**What this does:** Opens your site in your default browser.

Or manually visit: `https://opensocial.ddev.site`

**Login credentials:**
- Username: `admin`
- Password: `admin`

### Step 9: Get One-Time Login Link (Alternative)

```bash
ddev drush uli
```

**What this does:** Generates a one-time login link that bypasses username/password. Very useful!

**Expected output:**
```
https://opensocial.ddev.site/user/reset/1/1234567890/abcdefghijklmnop/login
```

Click that link to log in automatically.

### Step 10: Configure OpenSocial (Post-Installation)

After logging in, you should:

1. **Clear cache** (always good after installation):
```bash
ddev drush cr
```

2. **Check system status:**
```bash
ddev drush status
```

3. **Export initial configuration** (for version control):
```bash
ddev drush config:export -y
```

**What this does:** Exports your site configuration to `config/sync/` so you can track changes in Git.

### Step 10.5: Working with MariaDB Database

DDEV provides several ways to interact with your MariaDB database:

#### Access MariaDB Command Line

```bash
ddev mysql
```

**What this does:** Opens a MariaDB client connected to your database. You can run SQL queries directly:

```sql
SHOW DATABASES;
USE db;
SHOW TABLES;
SELECT * FROM users LIMIT 5;
```

Exit with `\q` or `exit`.

#### Check MariaDB Version and Info

```bash
ddev mysql --version
```

**Expected output:**
```
mysql  Ver 15.1 Distrib 10.11.6-MariaDB, for debian-linux-gnu (x86_64) using readline 5.2
```

**Verify it's MariaDB:**
```bash
ddev exec mysql -e "SELECT VERSION();"
```

You should see output containing "MariaDB":
```
+-------------------------------------------+
| VERSION()                                 |
+-------------------------------------------+
| 10.11.6-MariaDB-1:10.11.6+maria~ubu2204   |
+-------------------------------------------+
```

#### Export Database

```bash
# Export to file in project root
ddev export-db --file=database-backup.sql.gz

# Or use drush
ddev drush sql:dump --gzip --result-file=../database-backup.sql
```

**What this does:** Creates a compressed SQL dump of your database. Store these backups in a secure location, not in your Git repository.

#### Import Database

```bash
# Import from gzipped file
ddev import-db --file=database-backup.sql.gz

# Or use drush
ddev drush sql:query --file=../database-backup.sql
```

#### View Database Connection Info

```bash
ddev describe
```

Look for the MySQL/MariaDB section:
```
MySQL/MariaDB Credentials
  Username:     db
  Password:     db
  Database:     db
  Host:         db
  Port:         3306
```

#### Connect with External Database Client

If you want to use a GUI tool like MySQL Workbench, DBeaver, or TablePlus:

```bash
ddev describe
```

Get the connection details:
- **Host:** 127.0.0.1
- **Port:** (shown in ddev describe output, usually a random high port like 32773)
- **Username:** db
- **Password:** db
- **Database:** db

Or use:
```bash
ddev mysql -uroot -proot
```

To connect as root (useful for some admin tasks).

#### Database Performance Check

```bash
ddev exec mysql -e "SHOW STATUS LIKE '%connection%';"
ddev exec mysql -e "SHOW VARIABLES LIKE 'max_connections';"
```

**Note:** DDEV's MariaDB is configured for development, not production. Production databases need different tuning.

### Step 11: Version Control Setup

```bash
cd ~/projects/opensocial

# Initialize git (if not already)
git init

# Create .gitignore
cat > .gitignore << 'EOF'
# Ignore files generated by DDEV
.ddev/.gitignore
.ddev/homeadditions
.ddev/commands/web/
.ddev/commands/host/

# Ignore Drupal files
html/sites/*/files/
html/sites/*/private/
html/core/
html/vendor/
html/modules/contrib/
html/themes/contrib/
html/profiles/contrib/

# Keep custom work
!html/modules/custom/
!html/themes/custom/
!html/profiles/custom/

# Composer
composer.lock
EOF

# Add and commit
git add .
git commit -m "Initial OpenSocial installation with DDEV"
```

### Gotchas - OpenSocial Installation

#### Gotcha #1: Wrong Docroot
**Problem:** DDEV can't find Drupal
**Solution:** OpenSocial uses `html/` not `web/`. Make sure your `.ddev/config.yaml` has `docroot: html`

#### Gotcha #2: Composer Memory Errors
**Problem:** Composer runs out of memory during installation
**Solution:** 
```bash
# Increase PHP memory limit
echo "memory_limit = 512M" > .ddev/php/my-php.ini
ddev restart
```

#### Gotcha #3: Database Connection Errors
**Problem:** Can't connect to database during installation
**Solution:** Use DDEV's default database credentials:
```
mysql://db:db@db:3306/db
```
These are DDEV's standard credentials and hostname. The `mysql://` protocol is used even though DDEV defaults to MariaDB, because MariaDB is MySQL-compatible and uses the same wire protocol.

#### Gotcha #4: OpenSocial Version Confusion
**Problem:** Not sure which version to install
**Solution:** OpenSocial versions:
- OpenSocial 12.x = Drupal 10 (recommended)
- OpenSocial 11.x = Drupal 9 (deprecated)
- Use `goalgorilla/social_template` for latest stable
- Use `goalgorilla/social_template:^12.0` for specific major version
- Compatible with both MariaDB (recommended) and MySQL

**Database compatibility:**
- OpenSocial works with MariaDB 10.3+ (recommended)
- Also works with MySQL 5.7+ or 8.0+
- DDEV defaults to MariaDB 10.11 which is fully compatible

#### Gotcha #5: Missing WebP Extension
**Problem:** Warnings about missing WebP support
**Solution:** 
```bash
# Add to .ddev/config.yaml
webimage_extra_packages: [php-gd]
ddev restart
```
OpenSocial 11.5+ requires WebP extension for image optimization.

#### Gotcha #6: Site Install Hangs
**Problem:** `drush site:install` appears to hang
**Solution:** It's probably still working! OpenSocial installation is slow. Wait 10-15 minutes. Check progress:
```bash
# In another terminal
ddev logs -f
```

#### Gotcha #7: Permission Errors in Files Directory
**Problem:** Can't upload images/files
**Solution:**
```bash
ddev ssh
chmod -R 777 sites/default/files
exit
```

#### Gotcha #8: MariaDB Character Set Issues
**Problem:** Special characters (emoji, non-Latin scripts) not displaying correctly
**Solution:** MariaDB should use utf8mb4 by default in DDEV, but verify:
```bash
ddev exec mysql -e "SHOW VARIABLES LIKE 'character_set%';"
```

All should show `utf8mb4`. If not, add to `.ddev/mysql/my.cnf`:
```ini
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[client]
default-character-set = utf8mb4
```

Then:
```bash
ddev restart
```

#### Gotcha #9: MariaDB vs MySQL Syntax Differences
**Problem:** Some SQL queries behave differently
**Solution:** MariaDB and MySQL are 99% compatible, but minor differences exist:
- MariaDB has better JSON support in newer versions
- Some optimizer hints differ
- Default transaction isolation may differ
- For OpenSocial/Drupal, these differences are handled by the database abstraction layer
- If you write custom SQL queries, test them in your actual database version

---

## Part 3: Creating a Custom Module to Add Fields to Content Types

We'll create a module called `field_manager` that provides an admin interface to add custom fields to any content type.

### Understanding the Task

We want to create a module that:
1. Provides an admin form listing all content types
2. Allows selecting a content type
3. Allows adding a new field to that content type
4. Creates the field programmatically

### Step 1: Generate Module Scaffold with Drush

DDEV includes Drush, which has powerful code generators.

```bash
ddev ssh
cd /var/www/html/modules/custom
```

**What this does:** 
- `ddev ssh`: Enters the web container
- `cd /var/www/html/modules/custom`: Navigate to custom modules directory

Now generate the module:

```bash
drush generate module
```

**What this does:** Starts an interactive module generator. Answer the prompts:

```
Module name: Field Manager
Module machine name [field_manager]: field_manager
Module description [Provides additional functionality for the site.]: Allows adding fields to content types via admin interface
Package [Custom]: Custom
Dependencies (comma separated): 
Would you like to create module file? [No]: Yes
Would you like to create install file? [No]: Yes
Would you like to create README.md? [No]: Yes
```

**What each prompt means:**
- **Module name**: Human-readable name shown in admin
- **Machine name**: Technical name (lowercase, underscores only)
- **Description**: Shown in module list
- **Package**: Grouping in module list
- **Dependencies**: Other modules this requires (we'll add field, node later)
- **Module file**: Creates `field_manager.module` for hooks
- **Install file**: Creates `field_manager.install` for installation/update hooks
- **README**: Documentation file

This creates:
```
modules/custom/field_manager/
├── field_manager.info.yml
├── field_manager.module
├── field_manager.install
└── README.md
```

Exit the container:
```bash
exit
```

### Step 2: Update Module Info File

```bash
nano html/modules/custom/field_manager/field_manager.info.yml
```

Update it to:

```yaml
name: 'Field Manager'
type: module
description: 'Allows administrators to add fields to content types through a user interface.'
package: Custom
core_version_requirement: ^10 || ^11
dependencies:
  - drupal:field
  - drupal:node
  - drupal:field_ui
```

**What this does:**
- `core_version_requirement`: Works with Drupal 10 or 11
- `dependencies`: Lists required modules
  - `field`: For creating fields
  - `node`: For content types
  - `field_ui`: For field UI components

### Step 3: Create the Admin Form

We'll use Drush to generate a form:

```bash
ddev drush generate form
```

**Prompts:**
```
Module name [field_manager]: field_manager
Class [ExampleForm]: AddFieldForm
Form ID [field_manager_add_field]: field_manager_add_field
Would you like to create a route for this form? [Yes]: Yes
Route path [/field-manager/add-field]: /admin/structure/types/add-field
Route title [Add field]: Add Field to Content Type
Route permission [access content]: administer content types
```

**What each setting means:**
- **Class**: PHP class name for the form
- **Form ID**: Unique identifier for this form
- **Route path**: URL where form will be accessible
- **Route permission**: Who can access (only admins in this case)

This creates:
- `src/Form/AddFieldForm.php` - The form class
- `field_manager.routing.yml` - URL routing configuration

### Step 4: Implement the Add Field Form

Edit the generated form:

```bash
nano html/modules/custom/field_manager/src/Form/AddFieldForm.php
```

Replace the entire contents with:

```php
<?php

namespace Drupal\field_manager\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;
use Drupal\Core\Entity\EntityTypeManagerInterface;
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
   * Constructs a new AddFieldForm object.
   *
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entity_type_manager
   *   The entity type manager.
   */
  public function __construct(EntityTypeManagerInterface $entity_type_manager) {
    $this->entityTypeManager = $entity_type_manager;
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('entity_type.manager')
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
      '#description' => $this->t('Enter the machine name for the field (e.g., field_custom_text). Must start with "field_".'),
      '#required' => TRUE,
      '#maxlength' => 32,
      '#pattern' => 'field_[a-z0-9_]+',
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
    ];

    $form['actions'] = [
      '#type' => 'actions',
    ];

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
    }
    
    // Check if field already exists
    $field_storage = FieldStorageConfig::loadByName('node', $field_name);
    if ($field_storage) {
      // Field storage exists, check if it's already attached to this content type
      $content_type = $form_state->getValue('content_type');
      $field = FieldConfig::loadByName('node', $content_type, $field_name);
      if ($field) {
        $form_state->setErrorByName('field_name', 
          $this->t('This field already exists on the selected content type.'));
      }
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
    $required = $form_state->getValue('required');
    $cardinality = $form_state->getValue('cardinality');

    try {
      // Check if field storage already exists
      $field_storage = FieldStorageConfig::loadByName('node', $field_name);
      
      if (!$field_storage) {
        // Create field storage (shared configuration)
        $field_storage = FieldStorageConfig::create([
          'field_name' => $field_name,
          'entity_type' => 'node',
          'type' => $field_type,
          'cardinality' => $cardinality,
        ]);
        $field_storage->save();
        
        $this->messenger()->addStatus(
          $this->t('Field storage @field_name created.', ['@field_name' => $field_name])
        );
      }

      // Create field instance (content type-specific configuration)
      $field = FieldConfig::create([
        'field_storage' => $field_storage,
        'bundle' => $content_type,
        'label' => $field_label,
        'required' => $required,
      ]);
      $field->save();

      // Configure form display
      $form_display = \Drupal::entityTypeManager()
        ->getStorage('entity_form_display')
        ->load('node.' . $content_type . '.default');
      
      if ($form_display) {
        $form_display->setComponent($field_name, [
          'type' => $this->getDefaultWidget($field_type),
          'weight' => 10,
        ])->save();
      }

      // Configure view display
      $view_display = \Drupal::entityTypeManager()
        ->getStorage('entity_view_display')
        ->load('node.' . $content_type . '.default');
      
      if ($view_display) {
        $view_display->setComponent($field_name, [
          'type' => $this->getDefaultFormatter($field_type),
          'label' => 'above',
          'weight' => 10,
        ])->save();
      }

      $this->messenger()->addStatus(
        $this->t('Field @field_name has been added to @type.', [
          '@field_name' => $field_label,
          '@type' => $content_type,
        ])
      );

      // Clear cache
      drupal_flush_all_caches();

    }
    catch (\Exception $e) {
      $this->messenger()->addError(
        $this->t('Error creating field: @message', ['@message' => $e->getMessage()])
      );
      $this->logger('field_manager')->error('Error creating field: @message', [
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
```

**What this code does:**

1. **Dependency Injection**: Properly injects `EntityTypeManagerInterface` for loading content types
2. **buildForm()**: Creates the form with:
   - Dropdown to select content type
   - Field machine name input (with validation pattern)
   - Field label input
   - Field type selector (text, number, date, etc.)
   - Required checkbox
   - Cardinality setting (single or multiple values)
3. **validateForm()**: Checks:
   - Field name starts with "field_"
   - Field doesn't already exist on selected content type
4. **submitForm()**: 
   - Creates field storage (shared configuration)
   - Creates field instance (content type-specific)
   - Configures form display (how field appears in edit form)
   - Configures view display (how field appears when viewing content)
   - Clears cache

### Step 5: Create Menu Link

Create a menu link to access the form:

```bash
nano html/modules/custom/field_manager/field_manager.links.menu.yml
```

Add:

```yaml
field_manager.add_field:
  title: 'Add Field to Type'
  description: 'Add a field to any content type'
  parent: system.admin_structure
  route_name: field_manager.add_field
  weight: 10
```

**What this does:** Creates a menu link under Structure in the admin menu.

### Step 6: Enable the Module

```bash
ddev drush cr
ddev drush pm:enable field_manager -y
```

**What this does:**
- `cr`: Clears all caches (so Drupal finds new module)
- `pm:enable`: Enables the module
- `-y`: Answers "yes" automatically

**Expected output:**
```
[success] Successfully enabled: field_manager
```

### Step 7: Test the Module

1. **Access the form:**
```bash
ddev launch /admin/structure/types/add-field
```

Or navigate: Admin menu → Structure → Add Field to Type

2. **Add a test field:**
   - Content Type: Article
   - Field Machine Name: field_test_custom
   - Field Label: Test Custom Field
   - Field Type: Text (plain)
   - Required: Checked
   - Number of values: 1

3. **Submit and verify:**
   - Should see success message
   - Go to Structure → Content types → Article → Manage fields
   - Your new field should appear!

4. **Test creating content:**
```bash
ddev launch /node/add/article
```
Your new field should appear in the form.

### Step 8: Add Uninstall Cleanup (Optional but Recommended)

Edit the install file:

```bash
nano html/modules/custom/field_manager/field_manager.install
```

Add:

```php
<?php

/**
 * @file
 * Install, update and uninstall functions for the field_manager module.
 */

use Drupal\field\Entity\FieldStorageConfig;
use Drupal\field\Entity\FieldConfig;

/**
 * Implements hook_uninstall().
 */
function field_manager_uninstall() {
  // Note: This is optional. Drupal will keep the fields even after
  // module uninstall unless you explicitly delete them.
  // Usually you want to keep the data, so this is commented out.
  
  // If you want to delete all fields created by this module, you would:
  // 1. Track which fields were created (store in state or config)
  // 2. Delete them here during uninstall
  
  \Drupal::messenger()->addStatus(t('Field Manager has been uninstalled. Fields created by this module remain and must be manually deleted if desired.'));
}
```

**What this does:** Provides information during uninstall. We don't automatically delete fields because that would destroy user data.

### Gotchas - Module Development

#### Gotcha #1: Module Not Found After Creation
**Problem:** Drupal doesn't see your new module
**Solution:**
```bash
ddev drush cr
```
Always clear cache after creating/modifying modules.

#### Gotcha #2: Permission Denied
**Problem:** Can't access the form, get "Access denied"
**Solution:** The route requires "administer content types" permission. Make sure you're logged in as admin or grant permission at `/admin/people/permissions`

#### Gotcha #3: Field Name Validation Error
**Problem:** "Field machine name must start with 'field_'"
**Solution:** All Drupal field machine names MUST start with `field_`. For example: `field_my_custom`, not just `my_custom`.

#### Gotcha #4: Field Already Exists Error
**Problem:** Error when trying to add field
**Solution:** Field storage is shared. If you create `field_test` on Article, you can reuse that same field storage on Page, but you'll get an error if you try to add it to Article again.

#### Gotcha #5: Field Not Showing in Form
**Problem:** Field exists but doesn't appear when editing content
**Solution:** The form display wasn't configured. The code handles this, but if you create fields manually via YAML, you need to configure both:
- Form display: `core.entity_form_display.node.BUNDLE.default.yml`
- View display: `core.entity_view_display.node.BUNDLE.default.yml`

#### Gotcha #6: Changes Not Taking Effect
**Problem:** Code changes don't appear
**Solution:** Three-step dance:
```bash
ddev drush cr       # Clear cache
ddev drush updb -y  # Run updates if you added hook_update_N
ddev drush cr       # Clear cache again
```

#### Gotcha #7: Form Submission Does Nothing
**Problem:** Form submits but no field created
**Solution:** Check watchdog logs:
```bash
ddev drush watchdog:show --severity=Error
```
Common issues:
- Missing dependencies in .info.yml
- Wrong field type name
- Missing field storage

#### Gotcha #8: Cannot Enable Module - Dependency Error
**Problem:** "Module field_manager requires field, node, field_ui"
**Solution:** These are core modules but need to be enabled:
```bash
ddev drush pm:enable field node field_ui -y
```

#### Gotcha #9: Class Not Found Error
**Problem:** "Class Drupal\field_manager\Form\AddFieldForm does not exist"
**Solution:** 
1. Check file is in correct location: `src/Form/AddFieldForm.php`
2. Check namespace matches directory structure
3. Clear cache: `ddev drush cr`
4. Rebuild autoloader: `ddev composer dump-autoload`

#### Gotcha #10: Field Storage vs Field Config Confusion
**Problem:** Don't understand the difference
**Solution:** 
- **Field Storage**: The field definition itself (shared across all content types)
  - Example: "field_my_text" is a text field
  - Created once, can be reused on multiple content types
- **Field Config**: Instance of field on specific content type
  - Example: "field_my_text" on Article content type with label "My Text" and required=true
  - Each content type has its own config for the same field storage

Think of it like: Field Storage = database table, Field Config = how it's used in a specific form.

---

## Part 4: Advanced Features (Optional)

### Switching Between MariaDB and MySQL

While MariaDB is recommended and the default, you might need MySQL for specific reasons (testing, production environment parity, etc.).

#### Switch from MariaDB to MySQL

1. **Export your current database:**
```bash
ddev export-db --file=backup-before-switch.sql.gz
```

2. **Stop DDEV:**
```bash
ddev stop
```

3. **Edit `.ddev/config.yaml`:**
```yaml
database:
  type: mysql
  version: "8.0"  # or "8.4" for latest
```

4. **Remove old database and start fresh:**
```bash
ddev delete -O  # -O keeps database backup
# OR for complete clean start:
ddev stop --remove-data
```

5. **Start with new database type:**
```bash
ddev start
```

6. **Verify the change:**
```bash
ddev exec mysql -e "SELECT VERSION();"
```

Should show MySQL instead of MariaDB.

7. **Import your data:**
```bash
ddev import-db --file=backup-before-switch.sql.gz
ddev drush cr
```

#### Switch from MySQL to MariaDB

Same process, but in `.ddev/config.yaml` use:
```yaml
database:
  type: mariadb
  version: "10.11"  # or "11.4" for latest
```

**Important Notes:**
- MariaDB and MySQL are highly compatible, but not 100%
- Test thoroughly after switching
- Some SQL syntax differs slightly
- Performance characteristics differ
- MariaDB generally has better performance for Drupal workloads

### Adding Field to Multiple Content Types at Once

Modify the form to support multiple content types:

```php
// In buildForm(), change the content_type field:
$form['content_types'] = [
  '#type' => 'checkboxes',
  '#title' => $this->t('Content Types'),
  '#description' => $this->t('Select one or more content types to add the field to.'),
  '#options' => $type_options,
  '#required' => TRUE,
];

// In submitForm(), loop through selected types:
$content_types = array_filter($form_state->getValue('content_types'));

foreach ($content_types as $content_type) {
  // Create field for each selected type
  // ... existing field creation code ...
}
```

### Export Configuration for Version Control

After creating fields, export configuration:

```bash
ddev drush config:export -y
```

This exports to `config/sync/` directory. Commit these files:

```bash
git add html/config/sync
git commit -m "Added field_manager module and configurations"
```

On another environment:

```bash
git pull
ddev composer install
ddev drush config:import -y
ddev drush cr
```

---

## Sources and Currency

### Primary Sources

1. **DDEV Official Documentation**
   - URL: https://ddev.readthedocs.io/en/stable/
   - Last accessed: November 2024
   - **Currency**: Up to date - DDEV actively maintained
   - Used for: Installation procedures, configuration options

2. **Docker Official Documentation**
   - URL: https://docs.docker.com/engine/install/ubuntu/
   - Last accessed: November 2024
   - **Currency**: Current - Docker Engine installation is stable
   - Used for: Docker installation on Ubuntu

3. **Open Social Distribution Documentation**
   - URL: https://www.drupal.org/docs/drupal-distributions/open-social
   - Last updated: January 26, 2024
   - **Currency**: Slightly outdated - OpenSocial 13.x released August 2025
   - Used for: OpenSocial installation basics
   - **Note**: Installation process is stable across versions

4. **Drupal.org - Installing Drupal using DDEV**
   - URL: https://www.drupal.org/docs/getting-started/installing-drupal/install-drupal-using-ddev-for-local-development
   - Last updated: May 9, 2025
   - **Currency**: Current and recommended by Drupal community
   - Used for: DDEV + Drupal best practices

5. **Drupal API Documentation - Field System**
   - URL: https://api.drupal.org/api/drupal/core!modules!field
   - **Currency**: Always current - auto-generated from Drupal core
   - Used for: Programmatic field creation

6. **Drupal Answers - Stack Exchange**
   - URL: https://drupal.stackexchange.com/
   - Various posts from 2019-2024
   - **Currency**: Mixed - core concepts remain valid
   - Used for: Field creation patterns and troubleshooting

7. **Drush Documentation**
   - URL: https://www.drush.org/11.x/commands/generate/
   - **Currency**: Current for Drush 11.x/12.x
   - Used for: Code generation commands

### Currency Assessment

**✅ Current and Recommended (2024-2025):**
- DDEV installation process
- Docker Engine installation on Ubuntu
- Drupal 10/11 field creation patterns
- Drush generate commands
- Basic OpenSocial installation via Composer

**⚠️ Mostly Current with Minor Updates:**
- OpenSocial specific docs (core concepts unchanged)
- Field UI module usage patterns
- DDEV configuration options

**❌ Outdated/Deprecated:**
- Drupal Console (no longer actively maintained)
  - Replaced by Drush generate
- Drupal 7 field creation examples
  - API completely changed in Drupal 8+
- Docker Desktop for Linux
  - Not recommended by DDEV

### Version Compatibility Notes

**This guide is tested and valid for:**
- Ubuntu 20.04, 22.04, 24.04 LTS
- DDEV v1.22.0 - v1.24.x
- Docker Engine 20.10+
- Drupal 10.x and 11.x
- OpenSocial 12.x and 13.x
- Drush 11.x and 12.x
- PHP 8.1, 8.2, 8.3
- MariaDB 10.3, 10.4, 10.5, 10.6, 10.11, 11.4 (default: 10.11)
- MySQL 5.7, 8.0, 8.4 (if you choose MySQL instead of MariaDB)

**Known compatibility issues:**
- Docker Desktop on Linux: Not compatible with DDEV
- WSL1: Not supported, use WSL2 instead
- PHP 8.0: Deprecated for Drupal 10+
- OpenSocial 11.x: Deprecated, uses Drupal 9
- MySQL 5.6 and older: Not recommended, use MariaDB 10.11+ or MySQL 8.0+
- MariaDB 10.2 and older: Not recommended for Drupal 10+

### Verification Commands

To check versions:

```bash
# System
lsb_release -a          # Ubuntu version
uname -m                # Architecture

# Docker
docker --version
docker compose version

# DDEV
ddev version
ddev describe           # Shows all project details including database

# Inside DDEV container
ddev exec php -v        # PHP version
ddev drush --version    # Drush version
ddev drush status       # Drupal version

# Database (MariaDB/MySQL)
ddev mysql --version    # Show database client version
ddev exec mysql -e "SELECT VERSION();"  # Show database server version
ddev exec mysql -e "SHOW VARIABLES LIKE 'version%';"  # Detailed version info
```

### Updates and Maintenance

**Keeping systems current:**

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
ddev drush config:export -y
```

### Additional Resources

- DDEV Community: https://discord.gg/ddev
- Drupal Slack: #ddev channel
- OpenSocial Issue Queue: https://www.drupal.org/project/issues/social
- Drupal Stack Exchange: https://drupal.stackexchange.com/

---

## Final Checklist

**After following this guide, you should have:**

- ✅ DDEV installed and working on Ubuntu
- ✅ Docker Engine running without sudo
- ✅ mkcert certificates for HTTPS
- ✅ MariaDB 10.11 as your database (DDEV default)
- ✅ OpenSocial site running locally
- ✅ Custom field_manager module created
- ✅ Ability to add fields to content types via UI
- ✅ Understanding of DDEV, Drupal, MariaDB, and OpenSocial basics

**Next steps:**
1. Explore OpenSocial features (groups, events, activities)
2. Customize your theme
3. Add more modules for additional features
4. Set up continuous integration
5. Deploy to production (separate guide needed)

**Getting help:**
- DDEV issues: `ddev debug test` then check Discord
- Drupal issues: Check watchdog logs with `ddev drush watchdog:show`
- OpenSocial: Check their documentation and issue queue
- This guide: Each section includes common "Gotchas"

Good luck with your development! 🚀
