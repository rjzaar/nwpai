#!/bin/bash

################################################################################
# DDEV + OpenSocial Installation Checker and Installer
# 
# This script checks if all components from the installation guide are properly
# installed and configured, and offers to install/fix any missing components.
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Status tracking
declare -A STATUS
declare -A NEEDS_INSTALL

# Project directory (can be customized)
PROJECT_DIR="$HOME/projects/opensocial"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" == "OK" ]; then
        echo -e "[${GREEN}✓${NC}] $message"
    elif [ "$status" == "WARN" ]; then
        echo -e "[${YELLOW}!${NC}] $message"
    elif [ "$status" == "FAIL" ]; then
        echo -e "[${RED}✗${NC}] $message"
    else
        echo -e "[${BLUE}i${NC}] $message"
    fi
}

ask_yes_no() {
    local prompt=$1
    local default=${2:-n}
    
    if [ "$default" == "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Check Functions
################################################################################

check_ubuntu_version() {
    print_status "INFO" "Checking Ubuntu version..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            local version=$(echo $VERSION_ID | cut -d. -f1)
            if [ "$version" -ge 20 ]; then
                print_status "OK" "Ubuntu $VERSION_ID detected"
                STATUS[ubuntu]="OK"
                return 0
            else
                print_status "WARN" "Ubuntu $VERSION_ID detected (recommended: 20.04+)"
                STATUS[ubuntu]="WARN"
                return 0
            fi
        else
            print_status "WARN" "Not Ubuntu, detected: $ID (script designed for Ubuntu)"
            STATUS[ubuntu]="WARN"
            return 0
        fi
    else
        print_status "FAIL" "Cannot determine OS version"
        STATUS[ubuntu]="FAIL"
        return 1
    fi
}

check_docker() {
    print_status "INFO" "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_status "OK" "Docker installed: version $docker_version"
        
        # Check if Docker is running
        if docker ps &> /dev/null; then
            print_status "OK" "Docker daemon is running"
            
            # Check if user is in docker group
            if groups | grep -q docker; then
                print_status "OK" "User is in docker group"
                STATUS[docker]="OK"
                return 0
            else
                print_status "WARN" "User not in docker group (will need sudo or relogin)"
                STATUS[docker]="PARTIAL"
                NEEDS_INSTALL[docker_group]=1
                return 0
            fi
        else
            print_status "FAIL" "Docker daemon not running"
            STATUS[docker]="PARTIAL"
            NEEDS_INSTALL[docker_start]=1
            return 0
        fi
    else
        print_status "FAIL" "Docker not installed"
        STATUS[docker]="FAIL"
        NEEDS_INSTALL[docker]=1
        return 1
    fi
}

check_docker_compose() {
    print_status "INFO" "Checking Docker Compose..."
    
    if docker compose version &> /dev/null; then
        local compose_version=$(docker compose version | grep -oP 'v\d+\.\d+\.\d+' | head -1)
        print_status "OK" "Docker Compose plugin installed: $compose_version"
        STATUS[docker_compose]="OK"
        return 0
    else
        print_status "FAIL" "Docker Compose plugin not installed"
        STATUS[docker_compose]="FAIL"
        NEEDS_INSTALL[docker_compose]=1
        return 1
    fi
}

check_mkcert() {
    print_status "INFO" "Checking mkcert installation..."
    
    if command -v mkcert &> /dev/null; then
        local mkcert_version=$(mkcert -version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")
        print_status "OK" "mkcert installed: $mkcert_version"
        
        # Check if CA is installed
        if mkcert -CAROOT &> /dev/null; then
            local ca_root=$(mkcert -CAROOT)
            if [ -f "$ca_root/rootCA.pem" ]; then
                print_status "OK" "mkcert CA is installed"
                STATUS[mkcert]="OK"
                return 0
            else
                print_status "WARN" "mkcert CA not installed"
                STATUS[mkcert]="PARTIAL"
                NEEDS_INSTALL[mkcert_ca]=1
                return 0
            fi
        fi
    else
        print_status "FAIL" "mkcert not installed"
        STATUS[mkcert]="FAIL"
        NEEDS_INSTALL[mkcert]=1
        return 1
    fi
}

check_ddev() {
    print_status "INFO" "Checking DDEV installation..."
    
    if command -v ddev &> /dev/null; then
        local ddev_version=$(ddev version | grep -oP 'v\d+\.\d+\.\d+' | head -1)
        print_status "OK" "DDEV installed: $ddev_version"
        
        # Check if DDEV is working
        if ddev version &> /dev/null; then
            print_status "OK" "DDEV is functional"
            STATUS[ddev]="OK"
            return 0
        else
            print_status "FAIL" "DDEV not functioning properly"
            STATUS[ddev]="PARTIAL"
            return 0
        fi
    else
        print_status "FAIL" "DDEV not installed"
        STATUS[ddev]="FAIL"
        NEEDS_INSTALL[ddev]=1
        return 1
    fi
}

check_ddev_config() {
    print_status "INFO" "Checking DDEV global configuration..."
    
    if [ -f "$HOME/.ddev/global_config.yaml" ]; then
        print_status "OK" "DDEV global config exists"
        STATUS[ddev_config]="OK"
        return 0
    else
        print_status "WARN" "DDEV global config not found (optional)"
        STATUS[ddev_config]="WARN"
        NEEDS_INSTALL[ddev_config]=1
        return 0
    fi
}

check_opensocial_project() {
    print_status "INFO" "Checking OpenSocial project at $PROJECT_DIR..."
    
    if [ -d "$PROJECT_DIR" ]; then
        cd "$PROJECT_DIR"
        
        # Check if DDEV is configured
        if [ -f ".ddev/config.yaml" ]; then
            print_status "OK" "DDEV configuration found"
            
            # Check docroot
            local docroot=$(grep "^docroot:" .ddev/config.yaml | awk '{print $2}')
            if [ "$docroot" == "html" ]; then
                print_status "OK" "Correct docroot (html) configured"
            else
                print_status "WARN" "Docroot is '$docroot' (should be 'html')"
            fi
            
            # Check if project is running
            if ddev describe &> /dev/null; then
                print_status "OK" "DDEV project is running"
                
                # Check database type
                local db_type=$(ddev describe 2>/dev/null | grep -A 5 "DATABASE" | grep "Type:" | awk '{print $2}')
                if [ -n "$db_type" ]; then
                    print_status "OK" "Database type: $db_type"
                fi
                
                STATUS[opensocial_ddev]="OK"
            else
                print_status "WARN" "DDEV project exists but not running"
                STATUS[opensocial_ddev]="PARTIAL"
                NEEDS_INSTALL[start_ddev]=1
            fi
            
            # Check if OpenSocial is installed
            if [ -d "html/profiles/contrib/social" ]; then
                print_status "OK" "OpenSocial profile found"
                STATUS[opensocial_installed]="OK"
                
                # Check if site is installed
                if [ -f "html/sites/default/settings.php" ]; then
                    if grep -q "^\$databases\['default'\]" html/sites/default/settings.php 2>/dev/null; then
                        print_status "OK" "Drupal appears to be installed"
                        STATUS[drupal_installed]="OK"
                    else
                        print_status "WARN" "Drupal may not be installed"
                        STATUS[drupal_installed]="PARTIAL"
                        NEEDS_INSTALL[install_drupal]=1
                    fi
                else
                    print_status "WARN" "settings.php not found"
                    STATUS[drupal_installed]="PARTIAL"
                    NEEDS_INSTALL[install_drupal]=1
                fi
            else
                print_status "FAIL" "OpenSocial profile not found"
                STATUS[opensocial_installed]="FAIL"
                NEEDS_INSTALL[install_opensocial]=1
            fi
        else
            print_status "FAIL" "DDEV not configured in project directory"
            STATUS[opensocial_ddev]="FAIL"
            NEEDS_INSTALL[configure_ddev]=1
        fi
    else
        print_status "FAIL" "OpenSocial project directory not found"
        STATUS[opensocial_project]="FAIL"
        NEEDS_INSTALL[create_project]=1
    fi
}

check_custom_module() {
    print_status "INFO" "Checking custom field_manager module..."
    
    if [ -d "$PROJECT_DIR/html/modules/custom/field_manager" ]; then
        print_status "OK" "field_manager module directory exists"
        
        # Check for key files
        if [ -f "$PROJECT_DIR/html/modules/custom/field_manager/field_manager.info.yml" ]; then
            print_status "OK" "Module info file exists"
        else
            print_status "WARN" "Module info file missing"
            STATUS[custom_module]="PARTIAL"
            return 0
        fi
        
        if [ -f "$PROJECT_DIR/html/modules/custom/field_manager/src/Form/AddFieldForm.php" ]; then
            print_status "OK" "AddFieldForm.php exists"
        else
            print_status "WARN" "AddFieldForm.php missing"
            STATUS[custom_module]="PARTIAL"
            return 0
        fi
        
        # Check if module is enabled (if DDEV is running)
        if [ "${STATUS[opensocial_ddev]}" == "OK" ]; then
            cd "$PROJECT_DIR"
            if ddev drush pm:list --status=enabled 2>/dev/null | grep -q "field_manager"; then
                print_status "OK" "field_manager module is enabled"
                STATUS[custom_module]="OK"
            else
                print_status "WARN" "field_manager module not enabled"
                STATUS[custom_module]="PARTIAL"
                NEEDS_INSTALL[enable_module]=1
            fi
        else
            STATUS[custom_module]="OK"
        fi
    else
        print_status "FAIL" "field_manager module not found"
        STATUS[custom_module]="FAIL"
        NEEDS_INSTALL[create_module]=1
    fi
}

################################################################################
# Installation Functions
################################################################################

install_docker() {
    print_header "Installing Docker Engine"
    
    echo "Removing old Docker versions..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    echo "Installing prerequisites..."
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common
    
    echo "Adding Docker's GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg
    
    echo "Adding Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    echo "Installing Docker Engine..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    echo "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_status "OK" "Docker installed successfully"
}

add_user_to_docker_group() {
    print_header "Adding User to Docker Group"
    
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker $USER
    
    print_status "OK" "User added to docker group"
    echo -e "${YELLOW}IMPORTANT: You need to log out and log back in for group membership to take effect!${NC}"
    echo -e "${YELLOW}Or run: newgrp docker${NC}"
}

install_mkcert() {
    print_header "Installing mkcert"
    
    echo "Installing NSS tools..."
    sudo apt install -y libnss3-tools
    
    echo "Downloading mkcert..."
    curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
    chmod +x mkcert-v*-linux-amd64
    sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
    
    print_status "OK" "mkcert installed successfully"
}

install_mkcert_ca() {
    print_header "Installing mkcert Certificate Authority"
    
    mkcert -install
    
    print_status "OK" "mkcert CA installed"
}

install_ddev() {
    print_header "Installing DDEV"
    
    echo "Downloading and installing DDEV..."
    curl -fsSL https://ddev.com/install.sh | bash
    
    echo "Running DDEV system check..."
    ddev debug test
    
    print_status "OK" "DDEV installed successfully"
}

create_ddev_config() {
    print_header "Creating DDEV Global Configuration"
    
    mkdir -p ~/.ddev
    
    cat > ~/.ddev/global_config.yaml << 'EOF'
# DDEV Global Configuration

# Use localhost instead of *.ddev.site for simpler DNS
use_dns_when_possible: false

# Router ports (default 80/443)
router_http_port: "80"
router_https_port: "443"

# Disable usage analytics
instrumentation_opt_in: false

# Default PHP version for new projects
php_version: "8.3"

# Database defaults to MariaDB 10.11
# Uncomment to explicitly set database type
# database:
#   type: mariadb
#   version: "10.11"
EOF
    
    print_status "OK" "DDEV global config created"
}

create_opensocial_project() {
    print_header "Creating OpenSocial Project"
    
    echo "Creating project directory at $PROJECT_DIR..."
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    echo "Initializing DDEV for Drupal 10..."
    ddev config --project-type=drupal10 --docroot=html --create-docroot
    
    print_status "OK" "Project directory created and DDEV configured"
}

start_ddev_project() {
    print_header "Starting DDEV Project"
    
    cd "$PROJECT_DIR"
    ddev start
    
    print_status "OK" "DDEV project started"
}

install_opensocial() {
    print_header "Installing OpenSocial via Composer"
    
    cd "$PROJECT_DIR"
    
    echo "This will take 10-15 minutes..."
    ddev composer create goalgorilla/social_template --no-interaction
    
    print_status "OK" "OpenSocial installed"
}

install_drupal_site() {
    print_header "Installing Drupal with OpenSocial Profile"
    
    cd "$PROJECT_DIR"
    
    echo "This will take 5-10 minutes..."
    ddev drush site:install social \
        --db-url=mysql://db:db@db:3306/db \
        --account-name=admin \
        --account-pass=admin \
        --site-name="My OpenSocial Site" \
        -y
    
    ddev drush cr
    
    print_status "OK" "Drupal site installed"
    echo -e "${GREEN}Login: admin / admin${NC}"
    echo -e "${GREEN}URL: https://opensocial.ddev.site${NC}"
}

create_field_manager_module() {
    print_header "Creating field_manager Module"
    
    cd "$PROJECT_DIR"
    
    echo "Creating module directory..."
    mkdir -p html/modules/custom/field_manager/src/Form
    
    echo "Creating field_manager.info.yml..."
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
    
    echo "Creating field_manager.module..."
    cat > html/modules/custom/field_manager/field_manager.module << 'EOF'
<?php

/**
 * @file
 * Contains field_manager.module.
 */

use Drupal\Core\Routing\RouteMatchInterface;

/**
 * Implements hook_help().
 */
function field_manager_help($route_name, RouteMatchInterface $route_match) {
  switch ($route_name) {
    case 'help.page.field_manager':
      return '<p>' . t('Provides an interface to add fields to content types.') . '</p>';
  }
}
EOF
    
    echo "Creating routing file..."
    cat > html/modules/custom/field_manager/field_manager.routing.yml << 'EOF'
field_manager.add_field:
  path: '/admin/structure/types/add-field'
  defaults:
    _form: '\Drupal\field_manager\Form\AddFieldForm'
    _title: 'Add Field to Content Type'
  requirements:
    _permission: 'administer content types'
EOF
    
    echo "Creating menu links..."
    cat > html/modules/custom/field_manager/field_manager.links.menu.yml << 'EOF'
field_manager.add_field:
  title: 'Add Field to Type'
  description: 'Add a field to any content type'
  parent: system.admin_structure
  route_name: field_manager.add_field
  weight: 10
EOF
    
    echo "Creating AddFieldForm.php..."
    # This would be the full form class - using a simplified version for script
    cat > html/modules/custom/field_manager/src/Form/AddFieldForm.php << 'PHPEOF'
<?php

namespace Drupal\field_manager\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Provides a form to add fields to content types.
 */
class AddFieldForm extends FormBase {

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
    $form['info'] = [
      '#markup' => '<p>This is a placeholder form. See the guide for complete implementation.</p>',
    ];
    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    // Placeholder.
  }

}
PHPEOF
    
    print_status "OK" "field_manager module created (basic structure)"
    echo -e "${YELLOW}Note: For full functionality, copy the complete AddFieldForm.php from the guide${NC}"
}

enable_field_manager() {
    print_header "Enabling field_manager Module"
    
    cd "$PROJECT_DIR"
    ddev drush cr
    ddev drush pm:enable field_manager -y
    
    print_status "OK" "field_manager module enabled"
}

################################################################################
# Main Installation Menu
################################################################################

show_installation_menu() {
    local -a options
    local -a keys
    
    print_header "Installation Menu"
    
    echo "The following components need attention:"
    echo ""
    
    local index=1
    
    # Build menu options based on what needs installation
    if [ -n "${NEEDS_INSTALL[docker]}" ]; then
        options+=("Install Docker Engine")
        keys+=("docker")
        echo "  $index) Install Docker Engine"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[docker_group]}" ]; then
        options+=("Add user to docker group")
        keys+=("docker_group")
        echo "  $index) Add user to docker group"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[docker_start]}" ]; then
        options+=("Start Docker daemon")
        keys+=("docker_start")
        echo "  $index) Start Docker daemon"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[mkcert]}" ]; then
        options+=("Install mkcert")
        keys+=("mkcert")
        echo "  $index) Install mkcert"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[mkcert_ca]}" ]; then
        options+=("Install mkcert CA")
        keys+=("mkcert_ca")
        echo "  $index) Install mkcert CA"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[ddev]}" ]; then
        options+=("Install DDEV")
        keys+=("ddev")
        echo "  $index) Install DDEV"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[ddev_config]}" ]; then
        options+=("Create DDEV global config")
        keys+=("ddev_config")
        echo "  $index) Create DDEV global config"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[create_project]}" ]; then
        options+=("Create OpenSocial project")
        keys+=("create_project")
        echo "  $index) Create OpenSocial project"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[configure_ddev]}" ]; then
        options+=("Configure DDEV for project")
        keys+=("configure_ddev")
        echo "  $index) Configure DDEV for project"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[start_ddev]}" ]; then
        options+=("Start DDEV project")
        keys+=("start_ddev")
        echo "  $index) Start DDEV project"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[install_opensocial]}" ]; then
        options+=("Install OpenSocial via Composer")
        keys+=("install_opensocial")
        echo "  $index) Install OpenSocial via Composer (10-15 min)"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[install_drupal]}" ]; then
        options+=("Install Drupal site")
        keys+=("install_drupal")
        echo "  $index) Install Drupal site (5-10 min)"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[create_module]}" ]; then
        options+=("Create field_manager module")
        keys+=("create_module")
        echo "  $index) Create field_manager module"
        ((index++))
    fi
    
    if [ -n "${NEEDS_INSTALL[enable_module]}" ]; then
        options+=("Enable field_manager module")
        keys+=("enable_module")
        echo "  $index) Enable field_manager module"
        ((index++))
    fi
    
    echo "  a) Install ALL missing components"
    echo "  s) Skip installation menu"
    echo "  q) Quit"
    echo ""
    
    read -p "Select option(s) (comma-separated or 'a' for all): " selection
    
    if [[ "$selection" =~ ^[Qq]$ ]]; then
        echo "Exiting..."
        exit 0
    elif [[ "$selection" =~ ^[Ss]$ ]]; then
        return
    elif [[ "$selection" =~ ^[Aa]$ ]]; then
        install_all_components
    else
        # Process individual selections
        IFS=',' read -ra SELECTIONS <<< "$selection"
        for sel in "${SELECTIONS[@]}"; do
            sel=$(echo "$sel" | xargs) # trim whitespace
            if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -lt "$index" ]; then
                local key_index=$((sel - 1))
                install_component "${keys[$key_index]}"
            fi
        done
    fi
}

install_component() {
    local component=$1
    
    case "$component" in
        docker)
            install_docker
            ;;
        docker_group)
            add_user_to_docker_group
            ;;
        docker_start)
            sudo systemctl start docker
            sudo systemctl enable docker
            print_status "OK" "Docker started"
            ;;
        mkcert)
            install_mkcert
            ;;
        mkcert_ca)
            install_mkcert_ca
            ;;
        ddev)
            install_ddev
            ;;
        ddev_config)
            create_ddev_config
            ;;
        create_project|configure_ddev)
            create_opensocial_project
            ;;
        start_ddev)
            start_ddev_project
            ;;
        install_opensocial)
            install_opensocial
            ;;
        install_drupal)
            install_drupal_site
            ;;
        create_module)
            create_field_manager_module
            ;;
        enable_module)
            enable_field_manager
            ;;
    esac
}

install_all_components() {
    print_header "Installing All Missing Components"
    
    # Install in dependency order
    [ -n "${NEEDS_INSTALL[docker]}" ] && install_docker
    [ -n "${NEEDS_INSTALL[docker_group]}" ] && add_user_to_docker_group
    [ -n "${NEEDS_INSTALL[docker_start]}" ] && sudo systemctl start docker && sudo systemctl enable docker
    [ -n "${NEEDS_INSTALL[mkcert]}" ] && install_mkcert
    [ -n "${NEEDS_INSTALL[mkcert_ca]}" ] && install_mkcert_ca
    [ -n "${NEEDS_INSTALL[ddev]}" ] && install_ddev
    [ -n "${NEEDS_INSTALL[ddev_config]}" ] && create_ddev_config
    [ -n "${NEEDS_INSTALL[create_project]}" ] && create_opensocial_project
    [ -n "${NEEDS_INSTALL[configure_ddev]}" ] && create_opensocial_project
    [ -n "${NEEDS_INSTALL[start_ddev]}" ] && start_ddev_project
    [ -n "${NEEDS_INSTALL[install_opensocial]}" ] && install_opensocial
    [ -n "${NEEDS_INSTALL[install_drupal]}" ] && install_drupal_site
    [ -n "${NEEDS_INSTALL[create_module]}" ] && create_field_manager_module
    [ -n "${NEEDS_INSTALL[enable_module]}" ] && enable_field_manager
    
    print_status "OK" "All components installed!"
}

################################################################################
# Summary Report
################################################################################

print_summary() {
    print_header "Installation Status Summary"
    
    echo -e "${BOLD}System Components:${NC}"
    [ -n "${STATUS[ubuntu]}" ] && print_status "${STATUS[ubuntu]}" "Ubuntu Version"
    [ -n "${STATUS[docker]}" ] && print_status "${STATUS[docker]}" "Docker Engine"
    [ -n "${STATUS[docker_compose]}" ] && print_status "${STATUS[docker_compose]}" "Docker Compose"
    [ -n "${STATUS[mkcert]}" ] && print_status "${STATUS[mkcert]}" "mkcert"
    [ -n "${STATUS[ddev]}" ] && print_status "${STATUS[ddev]}" "DDEV"
    [ -n "${STATUS[ddev_config]}" ] && print_status "${STATUS[ddev_config]}" "DDEV Global Config"
    
    echo ""
    echo -e "${BOLD}OpenSocial Project:${NC}"
    [ -n "${STATUS[opensocial_project]}" ] && print_status "${STATUS[opensocial_project]}" "Project Directory"
    [ -n "${STATUS[opensocial_ddev]}" ] && print_status "${STATUS[opensocial_ddev]}" "DDEV Configuration"
    [ -n "${STATUS[opensocial_installed]}" ] && print_status "${STATUS[opensocial_installed]}" "OpenSocial Files"
    [ -n "${STATUS[drupal_installed]}" ] && print_status "${STATUS[drupal_installed]}" "Drupal Installation"
    [ -n "${STATUS[custom_module]}" ] && print_status "${STATUS[custom_module]}" "field_manager Module"
    
    echo ""
    
    # Count issues
    local ok_count=0
    local warn_count=0
    local fail_count=0
    local partial_count=0
    
    for status in "${STATUS[@]}"; do
        case "$status" in
            OK) ((ok_count++)) ;;
            WARN) ((warn_count++)) ;;
            FAIL) ((fail_count++)) ;;
            PARTIAL) ((partial_count++)) ;;
        esac
    done
    
    echo -e "${BOLD}Summary:${NC}"
    echo -e "  ${GREEN}✓${NC} OK: $ok_count"
    [ $warn_count -gt 0 ] && echo -e "  ${YELLOW}!${NC} Warnings: $warn_count"
    [ $partial_count -gt 0 ] && echo -e "  ${YELLOW}!${NC} Partial: $partial_count"
    [ $fail_count -gt 0 ] && echo -e "  ${RED}✗${NC} Failed: $fail_count"
    
    if [ $fail_count -eq 0 ] && [ $partial_count -eq 0 ]; then
        echo ""
        echo -e "${GREEN}${BOLD}🎉 All components are properly installed!${NC}"
        
        if [ -d "$PROJECT_DIR" ] && [ "${STATUS[drupal_installed]}" == "OK" ]; then
            echo ""
            echo -e "${BLUE}${BOLD}Quick Start Commands:${NC}"
            echo -e "  cd $PROJECT_DIR"
            echo -e "  ddev launch          # Open site in browser"
            echo -e "  ddev drush uli       # Get one-time login link"
            echo -e "  ddev ssh             # SSH into container"
            echo ""
            echo -e "${GREEN}Admin credentials: admin / admin${NC}"
        fi
    fi
}

################################################################################
# Main Script
################################################################################

main() {
    print_header "DDEV + OpenSocial Installation Checker"
    
    echo "This script will check your DDEV and OpenSocial installation"
    echo "and offer to install any missing components."
    echo ""
    
    # Allow customization of project directory
    read -p "OpenSocial project directory [$PROJECT_DIR]: " input_dir
    if [ -n "$input_dir" ]; then
        PROJECT_DIR="$input_dir"
    fi
    
    echo ""
    print_header "Running System Checks"
    
    # Run all checks
    check_ubuntu_version
    check_docker
    check_docker_compose
    check_mkcert
    check_ddev
    check_ddev_config
    check_opensocial_project
    check_custom_module
    
    # Show summary
    print_summary
    
    # Show installation menu if needed
    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        echo ""
        if ask_yes_no "Would you like to install missing components?" "y"; then
            show_installation_menu
            
            # Re-run checks after installation
            echo ""
            print_header "Re-checking After Installation"
            
            # Clear previous status
            unset STATUS
            unset NEEDS_INSTALL
            declare -gA STATUS
            declare -gA NEEDS_INSTALL
            
            # Re-run checks
            check_ubuntu_version
            check_docker
            check_docker_compose
            check_mkcert
            check_ddev
            check_ddev_config
            check_opensocial_project
            check_custom_module
            
            print_summary
        fi
    fi
    
    echo ""
    print_header "Installation Check Complete"
    
    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        echo -e "${YELLOW}Some components still need attention.${NC}"
        echo "Run this script again or refer to the installation guide for manual steps."
    else
        echo -e "${GREEN}Your DDEV + OpenSocial environment is ready to use!${NC}"
    fi
}

# Run main function
main "$@"
