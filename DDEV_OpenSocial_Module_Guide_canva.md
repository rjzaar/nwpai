# DDEV OpenSocial Module Guide
**Complete Setup & Development Reference**

---

## Table of Contents
1. [Overview](#overview)
2. [Initial Setup](#initial-setup)
3. [Composer Configuration](#composer-configuration)
4. [Managing Patches](#managing-patches)
5. [Development Configuration](#development-configuration)
6. [Git Worktree Setup](#git-worktree-setup)
7. [Testing & Quality Assurance](#testing-quality-assurance)
8. [Contributing Code](#contributing-code)
9. [Common Issues](#common-issues)

---

## Overview

### Guide Overview
This comprehensive guide covers the complete setup and development workflow for the OpenSocial module within a DDEV environment. You'll learn how to configure your development environment, manage dependencies, and contribute to the project effectively.

### What You'll Learn
- Setting up DDEV for OpenSocial development
- Managing Composer dependencies and patches
- Configuring development settings
- Using Git worktrees for module development
- Contributing code with proper testing

### Prerequisites
- DDEV installed and configured
- Basic knowledge of Drupal and Composer
- Git fundamentals
- Command line familiarity

---

## Initial Setup

### Project Initialization
Start by creating your DDEV project directory and initializing the environment:

```bash
ddev config --project-type=drupal10 --docroot=web
ddev start

Expected Directory Structure
your-project/
├── web/                 # Docroot
│   ├── modules/
│   │   └── contrib/
│   ├── themes/
│   └── sites/
├── vendor/             # Composer dependencies
├── composer.json
└── .ddev/             # DDEV configuration

Verify Installation
Check that DDEV is running correctly:

ddev status
ddev describe

Composer Configuration
Why Configure Composer?
Proper Composer configuration ensures consistent dependency management, applies necessary patches, and sets up the correct repository sources for Drupal modules.

Add Required Repositories
Configure Composer to access the Drupal package repository:

ddev composer config repositories.drupal composer https://packages.drupal.org/8

Install Core Dependencies
Install OpenSocial and its dependencies. The --with-all-dependencies flag ensures all nested dependencies are resolved:

ddev composer require drupal/social:dev-12.x-dev --with-all-dependencies

Understanding Version Constraints
dev-12.x-dev: Latest development branch (use for contributing)
^12.0: Stable releases with compatible updates
12.0.x-dev: Specific minor version development branch
Best Practices
Always run ddev composer update within DDEV, not on host
Commit composer.lock to ensure consistent installs
Use --with-all-dependencies when updating major modules
Keep development and production dependencies separated
Managing Patches
Why Use Patches?
Patches allow you to apply community fixes or custom modifications to Drupal modules while maintaining clean version control and easy updates.

Install Composer Patches Plugin
ddev composer require cweagans/composer-patches

Configure Patch Settings
Add to your composer.json under the extra section:

{
  "extra": {
    "patches": {
      "drupal/social": {
        "Description of the fix": "https://www.drupal.org/files/issues/patch-file.patch"
      }
    },
    "enable-patching": true,
    "composer-exit-on-patch-failure": true
  }
}

Patch Workflow
Find the patch: Get patch URL from Drupal.org issue queue
Add to composer.json: Include descriptive comment
Apply patches: Run ddev composer update --lock
Verify application: Check for successful application messages
Test thoroughly: Ensure patch works as expected
Validating Patches
# Check if patches were applied
ddev composer show -P

# View patch details
cat web/modules/contrib/social/PATCHES.txt

Development Configuration
Disable CSS/JS Aggregation
During development, disable aggregation to see changes immediately without cache clearing:

ddev drush config:set system.performance css.preprocess 0 -y
ddev drush config:set system.performance js.preprocess 0 -y

Enable Development Services
Create or edit web/sites/development.services.yml:

parameters:
  http.response.debug_cacheability_headers: true
  twig.config:
    debug: true
    auto_reload: true
    cache: false
services:
  cache.backend.null:
    class: Drupal\Core\Cache\NullBackendFactory

Configure settings.local.php
Copy and customize the local settings file:

cp web/sites/example.settings.local.php web/sites/default/settings.local.php

Add to web/sites/default/settings.php:

if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}

Essential Development Settings
# Disable render cache
$settings['cache']['bins']['render'] = 'cache.backend.null';

# Disable dynamic page cache
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';

# Enable verbose error logging
$config['system.logging']['error_level'] = 'verbose';

Quick Cache Clear
ddev drush cr

Git Worktree Setup
Why Use Git Worktrees?
Git worktrees allow you to work on multiple branches simultaneously without switching contexts. This is especially useful when:

Developing features while maintaining stable code
Testing patches across different branches
Comparing implementations side-by-side
Contributing to multiple issues simultaneously
Setup Main Repository
Clone the OpenSocial repository to a separate location:

cd ~/projects
git clone --branch 12.x https://git.drupalcode.org/project/social.git social-worktree
cd social-worktree

Create Development Worktree
Create a worktree for your feature branch and link it to your DDEV project:

# Create new branch and worktree
git worktree add -b feature-branch ../social-feature-branch

# Link to DDEV
cd ~/your-ddev-project
rm -rf web/modules/contrib/social
ln -s ~/projects/social-feature-branch web/modules/contrib/social

Worktree Workflow
Create worktree: git worktree add -b branch-name ../path
Link to DDEV: Replace module with symlink
Develop: Make changes in the worktree
Commit: Normal git operations in worktree directory
Clean up: git worktree remove ../path when done
Managing Multiple Worktrees
# List all worktrees
git worktree list

# Remove a worktree
git worktree remove ../social-feature-branch

# Prune stale worktrees
git worktree prune

Testing & Quality Assurance
Pre-Commit Checklist
✅ All functionality works as expected
✅ No PHP errors or warnings
✅ Code follows Drupal coding standards
✅ No regression in existing features
✅ Accessible to keyboard and screen reader users
Running PHP CodeSniffer
# Check coding standards
ddev composer require --dev drupal/coder
ddev exec vendor/bin/phpcs --standard=Drupal,DrupalPractice web/modules/contrib/social

# Auto-fix issues
ddev exec vendor/bin/phpcbf --standard=Drupal web/modules/contrib/social

Manual Testing Steps
Clear cache: ddev drush cr
Test new features: Verify all functionality
Test edge cases: Try to break your changes
Check different roles: Test with various permissions
Verify UI/UX: Test responsive design and accessibility
Browser Testing
Access your DDEV site:

ddev launch

Test in multiple browsers and devices for compatibility.

Contributing Code
Commit Message Format
Follow Drupal's commit message standards:

Issue #1234567 by username: Brief description of the change

Detailed explanation of what changed and why. Include:
- What problem this solves
- How the solution works
- Any API changes or deprecations
- Testing steps performed

Creating a Patch
# Create patch against 12.x branch
git diff 12.x > 1234567-description-2.patch

# Include interdiff for subsequent versions
git diff 1234567-description-1.patch 1234567-description-2.patch > interdiff-1-2.txt

Merge Request Process
Fork the repository: On Drupal.org GitLab
Create feature branch: git checkout -b 1234567-feature-name
Make your changes: Commit with proper messages
Push to your fork: git push origin 1234567-feature-name
Create merge request: On GitLab, targeting 12.x branch
Respond to feedback: Update based on code review
Code Review Checklist
Follows coding standards
Includes tests (if applicable)
Updates documentation
No unrelated changes
Backward compatible (or noted as breaking)
Common Issues
Composer Memory Errors
Problem: "PHP Fatal error: Allowed memory size exhausted"

Solution:

ddev composer config --global process-timeout 2000
COMPOSER_MEMORY_LIMIT=-1 ddev composer update

Patches Won't Apply
Problem: Patch fails during composer update

Solutions:

Check patch is for correct version
Verify patch URL is accessible
Try re-rolling patch against current codebase
Check for conflicting patches
Symlink Not Working
Problem: Changes in worktree not reflecting in DDEV

Solution:

# Verify symlink
ls -la web/modules/contrib/ | grep social

# Recreate symlink
rm web/modules/contrib/social
ln -s ~/projects/social-worktree web/modules/contrib/social

Cache Issues
Problem: Changes not appearing after code modification

Solution:

# Nuclear option - clear everything
ddev drush cr
ddev drush sql-query "TRUNCATE cache_bootstrap"
ddev drush sql-query "TRUNCATE cache_render"

DDEV Won't Start
Problem: DDEV fails to start or reports port conflicts

Solutions:

Check Docker is running: docker ps
Stop conflicting services: sudo service apache2 stop
Restart DDEV: ddev restart
Clean DDEV: ddev delete -O && ddev start
Getting Help
OpenSocial issue queue: drupal.org/project/issues/social
DDEV documentation: ddev.readthedocs.io
Drupal Slack: drupal.org/slack
Stack Overflow: [drupal] tag
Quick Reference Commands
Essential DDEV Commands
ddev start              # Start the project
ddev stop               # Stop the project
ddev restart            # Restart the project
ddev ssh                # SSH into container
ddev launch             # Open site in browser
ddev drush cr           # Clear Drupal cache

Common Composer Commands
ddev composer require [package]           # Add package
ddev composer update --lock               # Update dependencies
ddev composer show -P                     # Show patches
ddev composer why [package]               # Show why package is installed

Git Worktree Commands
git worktree add -b [branch] [path]      # Create worktree
git worktree list                         # List worktrees
git worktree remove [path]                # Remove worktree
git worktree prune                        # Clean up worktrees
