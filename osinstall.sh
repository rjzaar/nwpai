#!/bin/bash

###############################################################################
# Open Social Docker Installation Script for Ubuntu (Interactive Version)
# This script allows users to select which installation steps to execute
# Uses actual verification instead of state files
###############################################################################

# Don't exit on errors during verification
# set -e  # Removed to allow verification functions to fail gracefully

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/Sites/social"
GIT_REPO="https://github.com/goalgorilla/drupal_social.git"

# Step selection array
declare -A STEP_SELECTED

# Functions
print_step() {
    echo -e "\n${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

check_root() {
    if [ "$EUID" -eq 0 ]; then 
        print_error "Please do not run this script as root or with sudo"
        exit 1
    fi
}

confirm_continue() {
    read -p "Do you want to continue? (Y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
}

###############################################################################
# Verification Functions - Check if steps are actually complete
###############################################################################

# Step 1: Check if system is updated (check if apt lists are recent)
verify_step_1() {
    # Check if apt lists are less than 24 hours old
    if [ -f "/var/lib/apt/periodic/update-success-stamp" ]; then
        local last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_update))
        # If updated within last 24 hours (86400 seconds)
        [ $time_diff -lt 86400 ]
        return $?
    fi
    return 1
}

# Step 2: Check if Docker is installed and user is in docker group
verify_step_2() {
    command -v docker > /dev/null 2>&1 && \
    docker --version > /dev/null 2>&1 && \
    groups 2>/dev/null | grep -q docker
    return $?
}

# Step 3: Check if Git is installed and configured
verify_step_3() {
    command -v git > /dev/null 2>&1 && \
    [ -n "$(git config --global user.name 2>/dev/null)" ] && \
    [ -n "$(git config --global user.email 2>/dev/null)" ]
    return $?
}

# Step 4: Check if Composer is installed
verify_step_4() {
    command -v composer > /dev/null 2>&1
    return $?
}

# Step 5: Check if repository is cloned
verify_step_5() {
    [ -d "$INSTALL_DIR/.git" ] && \
    [ -d "$INSTALL_DIR" ]
    return $?
}

# Step 6: Check if dependencies are installed
verify_step_6() {
    [ -d "$INSTALL_DIR/vendor" ] && \
    [ -f "$INSTALL_DIR/vendor/autoload.php" ]
    return $?
}

# Step 7: Check if proxy container is running
verify_step_7() {
    if ! command -v docker > /dev/null 2>&1; then
        return 1
    fi
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^proxy$' && \
    docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null | grep '^proxy' | grep -q 'Up'
    return $?
}

# Step 8: Check if .env file exists
verify_step_8() {
    [ -f "$INSTALL_DIR/.env" ]
    return $?
}

# Step 9: Check if containers are built and running
verify_step_9() {
    if [ ! -d "$INSTALL_DIR" ] || ! command -v docker > /dev/null 2>&1; then
        return 1
    fi
    cd "$INSTALL_DIR" 2>/dev/null || return 1
    # Check if docker-compose.yml exists and containers are running
    [ -f "docker-compose.yml" ] && \
    docker-compose ps 2>/dev/null | grep -q "Up"
    return $?
}

# Step 10: Check if hosts file is configured
verify_step_10() {
    grep -q "social.local" /etc/hosts 2>/dev/null
    return $?
}

# Step 11: Check if cron container is stopped (we want it stopped for installation)
verify_step_11() {
    if ! command -v docker > /dev/null 2>&1; then
        return 1
    fi
    # This step is transient - we check if it's NOT running or doesn't exist
    ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^social_cron$'
    return $?
}

# Step 12: Check if Open Social is installed (check for installed marker or database)
verify_step_12() {
    if ! command -v docker > /dev/null 2>&1; then
        return 1
    fi
    # Check if social_web container exists and Drupal is installed
    docker exec social_web drush status --field=bootstrap 2>/dev/null | grep -q "Successful" || \
    docker exec social_web test -f /var/www/html/sites/default/settings.php 2>/dev/null
    return $?
}

# Step 13: Check if all containers including cron are running
verify_step_13() {
    if [ ! -d "$INSTALL_DIR" ] || ! command -v docker > /dev/null 2>&1; then
        return 1
    fi
    cd "$INSTALL_DIR" 2>/dev/null || return 1
    # Check if all expected containers are up
    docker-compose ps 2>/dev/null | grep -q "Up" && \
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'social_cron'
    return $?
}

show_progress() {
    echo ""
    echo "Installation Progress:"
    echo "====================="
    
    if verify_step_1; then
        echo -e "  Step 1: ${GREEN}✓ Complete${NC} - System packages updated"
    else
        echo -e "  Step 1: ${YELLOW}⧗ Pending${NC} - System packages need updating"
    fi
    
    if verify_step_2; then
        echo -e "  Step 2: ${GREEN}✓ Complete${NC} - Docker installed"
    else
        echo -e "  Step 2: ${YELLOW}⧗ Pending${NC} - Docker needs installation"
    fi
    
    if verify_step_3; then
        echo -e "  Step 3: ${GREEN}✓ Complete${NC} - Git installed and configured"
    else
        echo -e "  Step 3: ${YELLOW}⧗ Pending${NC} - Git needs installation"
    fi
    
    if verify_step_4; then
        echo -e "  Step 4: ${GREEN}✓ Complete${NC} - Composer installed"
    else
        echo -e "  Step 4: ${YELLOW}⧗ Pending${NC} - Composer needs installation"
    fi
    
    if verify_step_5; then
        echo -e "  Step 5: ${GREEN}✓ Complete${NC} - Repository cloned"
    else
        echo -e "  Step 5: ${YELLOW}⧗ Pending${NC} - Repository needs cloning"
    fi
    
    if verify_step_6; then
        echo -e "  Step 6: ${GREEN}✓ Complete${NC} - Dependencies installed"
    else
        echo -e "  Step 6: ${YELLOW}⧗ Pending${NC} - Dependencies need installation"
    fi
    
    if verify_step_7; then
        echo -e "  Step 7: ${GREEN}✓ Complete${NC} - Nginx proxy running"
    else
        echo -e "  Step 7: ${YELLOW}⧗ Pending${NC} - Nginx proxy needs setup"
    fi
    
    if verify_step_8; then
        echo -e "  Step 8: ${GREEN}✓ Complete${NC} - Environment configured"
    else
        echo -e "  Step 8: ${YELLOW}⧗ Pending${NC} - Environment needs configuration"
    fi
    
    if verify_step_9; then
        echo -e "  Step 9: ${GREEN}✓ Complete${NC} - Containers built and running"
    else
        echo -e "  Step 9: ${YELLOW}⧗ Pending${NC} - Containers need building"
    fi
    
    if verify_step_10; then
        echo -e "  Step 10: ${GREEN}✓ Complete${NC} - Hosts file configured"
    else
        echo -e "  Step 10: ${YELLOW}⧗ Pending${NC} - Hosts file needs configuration"
    fi
    
    if verify_step_11; then
        echo -e "  Step 11: ${GREEN}✓ Complete${NC} - Cron container stopped"
    else
        echo -e "  Step 11: ${YELLOW}⧗ Pending${NC} - Cron container needs stopping"
    fi
    
    if verify_step_12; then
        echo -e "  Step 12: ${GREEN}✓ Complete${NC} - Open Social installed"
    else
        echo -e "  Step 12: ${YELLOW}⧗ Pending${NC} - Open Social needs installation"
    fi
    
    if verify_step_13; then
        echo -e "  Step 13: ${GREEN}✓ Complete${NC} - All containers running"
    else
        echo -e "  Step 13: ${YELLOW}⧗ Pending${NC} - All containers need starting"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Interactive step selection menu
show_step_menu() {
    clear
    echo "###############################################################################"
    echo "#                                                                             #"
    echo "#      Open Social Installation - Step Selection                             #"
    echo "#                                                                             #"
    echo "###############################################################################"
    echo ""
    echo "Select which steps to execute (Enter number to toggle, 'a' for all, 'n' for none):"
    echo ""
    
    local steps=(
        "1:Update System Packages"
        "2:Install Docker"
        "3:Install Git"
        "4:Install Composer"
        "5:Clone Open Social Repository"
        "6:Install PHP Dependencies"
        "7:Start Nginx Proxy"
        "8:Configure Environment Variables"
        "9:Build and Start Containers"
        "10:Configure Hosts File"
        "11:Stop Cron Container"
        "12:Run Installation Script"
        "13:Start All Containers"
    )
    
    local verify_funcs=(verify_step_1 verify_step_2 verify_step_3 verify_step_4 verify_step_5 verify_step_6 verify_step_7 verify_step_8 verify_step_9 verify_step_10 verify_step_11 verify_step_12 verify_step_13)
    
    local idx=0
    for step_info in "${steps[@]}"; do
        IFS=':' read -r num desc <<< "$step_info"
        local status="[ ]"
        local color="$NC"
        
        # Check if step is already complete via verification
        if ${verify_funcs[$idx]} 2>/dev/null; then
            status="[✓]"
            color="$GREEN"
        # Check if step is selected for execution (override complete status if selected)
        elif [ "${STEP_SELECTED[$num]}" = "true" ]; then
            status="[X]"
            color="$YELLOW"
        fi
        
        # Show selection status if not complete
        if [ "${STEP_SELECTED[$num]}" = "true" ] && [ "$status" != "[✓]" ]; then
            status="[X]"
            color="$YELLOW"
        fi
        
        echo -e "  ${color}${status}${NC} ${num}. ${desc}"
        ((idx++)) || true
    done
    
    echo ""
    echo "  [a] Select all steps"
    echo "  [n] Deselect all steps"
    echo "  [s] Show status of completed steps"
    echo "  [c] Continue with selected steps"
    echo "  [q] Quit"
    echo ""
}

toggle_step() {
    local step=$1
    if [ "${STEP_SELECTED[$step]}" = "true" ]; then
        STEP_SELECTED[$step]="false"
    else
        STEP_SELECTED[$step]="true"
    fi
}

select_all_steps() {
    for num in 1 2 3 4 5 6 7 8 9 10 11 12 13; do
        STEP_SELECTED[$num]="true"
    done
}

deselect_all_steps() {
    for num in 1 2 3 4 5 6 7 8 9 10 11 12 13; do
        STEP_SELECTED[$num]="false"
    done
}

interactive_menu() {
    while true; do
        show_step_menu
        read -p "Your choice: " choice
        
        case "$choice" in
            1|2|3|4|5|6|7|8|9|10|11|12|13)
                toggle_step "$choice"
                ;;
            a|A)
                select_all_steps
                ;;
            n|N)
                deselect_all_steps
                ;;
            s|S)
                show_progress
                ;;
            c|C)
                # Check if any steps are selected
                local has_selection=false
                for num in 1 2 3 4 5 6 7 8 9 10 11 12 13; do
                    if [ "${STEP_SELECTED[$num]}" = "true" ]; then
                        has_selection=true
                        break
                    fi
                done
                
                if [ "$has_selection" = "false" ]; then
                    echo ""
                    print_warning "No steps selected. Please select at least one step."
                    read -p "Press Enter to continue..."
                else
                    break
                fi
                ;;
            q|Q)
                echo "Installation cancelled."
                exit 0
                ;;
            *)
                ;;
        esac
    done
}

# Check for command line arguments
if [ "$1" = "--status" ]; then
    show_progress
    exit 0
elif [ "$1" = "--help" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --status    Show current installation progress"
    echo "  --help      Show this help message"
    echo ""
    exit 0
fi

check_root

###############################################################################
# Check current installation status
###############################################################################
clear
echo "###############################################################################"
echo "#                                                                             #"
echo "#      Checking Installation Status...                                       #"
echo "#                                                                             #"
echo "###############################################################################"
echo ""

print_step "Checking which steps have been completed..."
echo ""

echo "Step Status:"
echo "------------"

if verify_step_1; then
    echo -e "  ${GREEN}✓${NC} Step 1: System packages updated"
else
    echo -e "  ${YELLOW}⧗${NC} Step 1: System packages need updating"
fi

if verify_step_2; then
    echo -e "  ${GREEN}✓${NC} Step 2: Docker installed"
else
    echo -e "  ${YELLOW}⧗${NC} Step 2: Docker needs installation"
fi

if verify_step_3; then
    echo -e "  ${GREEN}✓${NC} Step 3: Git installed and configured"
else
    echo -e "  ${YELLOW}⧗${NC} Step 3: Git needs installation"
fi

if verify_step_4; then
    echo -e "  ${GREEN}✓${NC} Step 4: Composer installed"
else
    echo -e "  ${YELLOW}⧗${NC} Step 4: Composer needs installation"
fi

if verify_step_5; then
    echo -e "  ${GREEN}✓${NC} Step 5: Repository cloned"
else
    echo -e "  ${YELLOW}⧗${NC} Step 5: Repository needs cloning"
fi

if verify_step_6; then
    echo -e "  ${GREEN}✓${NC} Step 6: PHP dependencies installed"
else
    echo -e "  ${YELLOW}⧗${NC} Step 6: Dependencies need installation"
fi

if verify_step_7; then
    echo -e "  ${GREEN}✓${NC} Step 7: Nginx proxy running"
else
    echo -e "  ${YELLOW}⧗${NC} Step 7: Nginx proxy needs setup"
fi

if verify_step_8; then
    echo -e "  ${GREEN}✓${NC} Step 8: Environment variables configured"
else
    echo -e "  ${YELLOW}⧗${NC} Step 8: Environment needs configuration"
fi

if verify_step_9; then
    echo -e "  ${GREEN}✓${NC} Step 9: Docker containers built and started"
else
    echo -e "  ${YELLOW}⧗${NC} Step 9: Containers need building"
fi

if verify_step_10; then
    echo -e "  ${GREEN}✓${NC} Step 10: Hosts file configured"
else
    echo -e "  ${YELLOW}⧗${NC} Step 10: Hosts file needs configuration"
fi

if verify_step_11; then
    echo -e "  ${GREEN}✓${NC} Step 11: Cron container stopped for installation"
else
    echo -e "  ${YELLOW}⧗${NC} Step 11: Cron container needs stopping"
fi

if verify_step_12; then
    echo -e "  ${GREEN}✓${NC} Step 12: Open Social installed"
else
    echo -e "  ${YELLOW}⧗${NC} Step 12: Open Social needs installation"
fi

if verify_step_13; then
    echo -e "  ${GREEN}✓${NC} Step 13: All containers started"
else
    echo -e "  ${YELLOW}⧗${NC} Step 13: All containers need starting"
fi

echo ""
echo "Legend: ${GREEN}✓${NC} Complete  ${YELLOW}⧗${NC} Pending"
echo ""
read -p "Press Enter to continue to step selection menu..."

# Initialize step selection with smart defaults
for num in 1 2 3 4 5 6 7 8 9 10 11 12 13; do
    # By default, select steps that are not yet complete
    verify_func="verify_step_${num}"
    if $verify_func 2>/dev/null; then
        STEP_SELECTED[$num]="false"
    else
        STEP_SELECTED[$num]="true"
    fi
done

# Show interactive menu
interactive_menu

# Confirmation before proceeding
clear
echo "###############################################################################"
echo "#                                                                             #"
echo "#      Ready to Execute Selected Steps                                       #"
echo "#                                                                             #"
echo "###############################################################################"
echo ""
echo "The following steps will be executed:"
echo ""

for num in 1 2 3 4 5 6 7 8 9 10 11 12 13; do
    if [ "${STEP_SELECTED[$num]}" = "true" ]; then
        echo -e "  ${GREEN}✓${NC} Step $num"
    fi
done

echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
read -p "Continue with installation? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

###############################################################################
# Execute selected steps
###############################################################################

###############################################################################
# Step 1: Update System
###############################################################################
if [ "${STEP_SELECTED[1]}" = "true" ]; then
    if ! verify_step_1; then
        print_step "Step 1: Updating system packages..."
        sudo apt update
        sudo apt upgrade -y
        print_info "Step 1 complete"
    else
        print_info "Step 1: Already complete (System updated) - Skipping"
    fi
fi

###############################################################################
# Step 2: Install Docker
###############################################################################
if [ "${STEP_SELECTED[2]}" = "true" ]; then
    if ! verify_step_2; then
        print_step "Step 2: Installing Docker..."
        
        if ! command -v docker > /dev/null 2>&1; then
            # Remove old versions
            sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

            # Install dependencies
            sudo apt install -y ca-certificates curl gnupg lsb-release

            # Add Docker's GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
                sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            # Add Docker repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Install Docker
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io \
                docker-buildx-plugin docker-compose-plugin
        else
            print_info "Docker is already installed."
        fi
        
        # Create the docker group
        sudo groupadd docker 2>/dev/null || true
        
        # Add user to docker group (idempotent)
        sudo usermod -aG docker $USER
        
        # Verify Docker installation
        docker --version
        docker compose version
        
        print_warning "Docker group changes may require logout/login to take effect."
        print_info "Step 2 complete"
    else
        print_info "Step 2: Already complete (Docker installed) - Skipping"
    fi
fi

###############################################################################
# Step 3: Install Git
###############################################################################
if [ "${STEP_SELECTED[3]}" = "true" ]; then
    if ! verify_step_3; then
        print_step "Step 3: Installing Git..."
        
        if ! command -v git > /dev/null 2>&1; then
            sudo apt install -y git
        else
            print_info "Git is already installed."
        fi

        # Configure Git if not already configured
        if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
            read -p "Enter your Git name: " git_name
            git config --global user.name "$git_name"
        fi

        if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
            read -p "Enter your Git email: " git_email
            git config --global user.email "$git_email"
        fi
        
        print_info "Step 3 complete"
    else
        print_info "Step 3: Already complete (Git installed) - Skipping"
    fi
fi

###############################################################################
# Step 4: Install Composer
###############################################################################
if [ "${STEP_SELECTED[4]}" = "true" ]; then
    if ! verify_step_4; then
        print_step "Step 4: Installing Composer..."
        
        if command -v composer > /dev/null 2>&1; then
            print_info "Composer is already installed."
            composer --version
        else
            cd /tmp
            curl -sS https://getcomposer.org/installer -o composer-setup.php
            sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
            rm composer-setup.php
            composer --version
        fi
        
        print_info "Step 4 complete"
    else
        print_info "Step 4: Already complete (Composer installed) - Skipping"
    fi
fi

###############################################################################
# Step 5: Clone Open Social Repository
###############################################################################
if [ "${STEP_SELECTED[5]}" = "true" ]; then
    if ! verify_step_5; then
        print_step "Step 5: Cloning Open Social repository..."

        # Create parent directory if it doesn't exist
        mkdir -p "$(dirname "$INSTALL_DIR")"

        # Clone repository
        if [ -d "$INSTALL_DIR/.git" ]; then
            print_info "Repository already cloned at $INSTALL_DIR"
        elif [ -d "$INSTALL_DIR" ]; then
            print_warning "Directory $INSTALL_DIR already exists but is not a git repository."
            read -p "Do you want to remove it and clone fresh? (Y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                print_error "Cannot proceed without a clean directory. Exiting."
                exit 1
            else
                rm -rf "$INSTALL_DIR"
                git clone "$GIT_REPO" "$INSTALL_DIR"
            fi
        else
            git clone "$GIT_REPO" "$INSTALL_DIR"
        fi
        
        print_info "Step 5 complete"
    else
        print_info "Step 5: Already complete (Repository cloned) - Skipping"
    fi
fi

###############################################################################
# Step 6: Install Dependencies
###############################################################################
if [ "${STEP_SELECTED[6]}" = "true" ]; then
    if ! verify_step_6; then
        cd "$INSTALL_DIR"
        print_step "Step 6: Installing PHP dependencies with Composer..."
        
        if [ -d "$INSTALL_DIR/vendor" ]; then
            print_info "Dependencies appear to be already installed."
            read -p "Do you want to reinstall? (Y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                composer install
            fi
        else
            composer install
        fi
        
        print_info "Step 6 complete"
    else
        print_info "Step 6: Already complete (Dependencies installed) - Skipping"
    fi
fi

###############################################################################
# Step 7: Start Nginx Proxy
###############################################################################
if [ "${STEP_SELECTED[7]}" = "true" ]; then
    if ! verify_step_7; then
        print_step "Step 7: Starting Nginx proxy container..."

        # Check if proxy container already exists
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^proxy$'; then
            if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^proxy$'; then
                print_info "Proxy container is already running."
            else
                print_info "Proxy container exists but is not running. Starting it..."
                docker start proxy
            fi
        else
            docker run -d -p 80:80 --name=proxy \
                -v /var/run/docker.sock:/tmp/docker.sock:ro \
                nginxproxy/nginx-proxy
        fi

        echo "Waiting for proxy to start..."
        sleep 5
        
        print_info "Step 7 complete"
    else
        print_info "Step 7: Already complete (Nginx proxy running) - Skipping"
    fi
fi

###############################################################################
# Step 8: Configure Environment Variables
###############################################################################
if [ "${STEP_SELECTED[8]}" = "true" ]; then
    if ! verify_step_8; then
        cd "$INSTALL_DIR"
        print_step "Step 8: Configuring environment variables..."
        
        ENV_FILE="$INSTALL_DIR/.env"
        
        if [ -f "$ENV_FILE" ]; then
            print_info "Environment file already exists at $ENV_FILE"
            read -p "Do you want to recreate it? (Y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                print_info "Step 8: Using existing .env file - Skipping recreation"
            else
                rm "$ENV_FILE"
            fi
        fi
        
        if [ ! -f "$ENV_FILE" ]; then
            cat > "$ENV_FILE" << 'EOF'
# Project Configuration
PROJECT_NAME=social
PROJECT_BASE_URL=social.local

# Database Configuration
DRUPAL_DB_NAME=social
DRUPAL_DB_USER=root
DRUPAL_DB_PASS=root

# PHP Configuration
PHP_VERSION=8.1

# Solr Configuration
SOLR_CORE_NAME=drupal
EOF
            
            print_info "Created .env file with default configuration"
            echo "Contents:"
            cat "$ENV_FILE"
        fi
        
        print_info "Step 8 complete"
    else
        print_info "Step 8: Already complete (Environment configured) - Skipping"
    fi
fi

###############################################################################
# Step 9: Build and Start Containers
###############################################################################
if [ "${STEP_SELECTED[9]}" = "true" ]; then
    if ! verify_step_9; then
        cd "$INSTALL_DIR"
        print_step "Step 9: Building and starting Docker containers..."
        echo "This may take several minutes on first run..."

        docker-compose up -d

        echo "Waiting for containers to fully start..."
        sleep 15

        # Verify containers are running
        echo -e "\nContainer status:"
        docker ps --format "table {{.Names}}\t{{.Status}}"
        
        print_info "Step 9 complete"
    else
        print_info "Step 9: Already complete (Containers running) - Skipping"
    fi
fi

###############################################################################
# Step 10: Configure Hosts File
###############################################################################
if [ "${STEP_SELECTED[10]}" = "true" ]; then
    if ! verify_step_10; then
        print_step "Step 10: Configuring /etc/hosts file..."

        HOSTS_ENTRIES="127.0.0.1 social.local
127.0.0.1 mailcatcher.social.local
127.0.0.1 solr.social.local"

        # Check if entries already exist
        if grep -q "social.local" /etc/hosts 2>/dev/null; then
            print_info "Entries already exist in /etc/hosts"
        else
            echo "$HOSTS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
            echo "Added entries to /etc/hosts"
        fi
        
        print_info "Step 10 complete"
    else
        print_info "Step 10: Already complete (Hosts configured) - Skipping"
    fi
fi

###############################################################################
# Step 11: Stop Cron Container
###############################################################################
if [ "${STEP_SELECTED[11]}" = "true" ]; then
    if ! verify_step_11; then
        print_step "Step 11: Stopping cron container for installation..."
        
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^social_cron'; then
            docker stop social_cron
        else
            print_info "Cron container not running or doesn't exist yet."
        fi
        
        print_info "Step 11 complete"
    else
        print_info "Step 11: Already complete (Cron stopped) - Skipping"
    fi
fi

###############################################################################
# Step 12: Run Installation Script
###############################################################################
if [ "${STEP_SELECTED[12]}" = "true" ]; then
    if ! verify_step_12; then
        print_step "Step 12: Running Open Social installation..."
        echo "This will take 5-10 minutes. Please be patient..."

        docker exec social_web bash /var/www/scripts/social/install/install_script.sh -s -d
        
        print_info "Step 12 complete"
    else
        print_info "Step 12: Already complete (Open Social installed) - Skipping"
    fi
fi

###############################################################################
# Step 13: Start All Containers
###############################################################################
if [ "${STEP_SELECTED[13]}" = "true" ]; then
    if ! verify_step_13; then
        cd "$INSTALL_DIR"
        print_step "Step 13: Starting all containers including cron..."
        docker-compose up -d
        
        print_info "Step 13 complete"
    else
        print_info "Step 13: Already complete (All containers running) - Skipping"
    fi
fi

###############################################################################
# Completion Summary
###############################################################################
echo ""
echo "###############################################################################"
echo -e "#${GREEN}                                                                             ${NC}#"
echo -e "#${GREEN}                    Selected Steps Completed!                                ${NC}#"
echo -e "#${GREEN}                                                                             ${NC}#"
echo "###############################################################################"
echo ""

# Show which steps were executed
echo "Executed steps:"
for num in 1 2 3 4 5 6 7 8 9 10 11 12 13; do
    if [ "${STEP_SELECTED[$num]}" = "true" ]; then
        echo -e "  ${GREEN}✓${NC} Step $num"
    fi
done

echo ""
echo "Access your site at:"
echo "  Main site:    http://social.local"
echo "  Mailcatcher:  http://mailcatcher.social.local"
echo "  Solr admin:   http://solr.social.local"
echo ""
echo "Important next steps:"
echo "  1. Visit http://social.local/admin/reports/status"
echo "  2. Click 'Rebuild permissions' link"
echo "  3. Change your admin password"
echo ""
echo "Useful commands:"
echo "  View logs:           cd $INSTALL_DIR && docker-compose logs -f"
echo "  Stop containers:     cd $INSTALL_DIR && docker-compose stop"
echo "  Start containers:    cd $INSTALL_DIR && docker-compose start"
echo "  Restart containers:  cd $INSTALL_DIR && docker-compose restart"
echo "  Access web shell:    docker exec -it social_web bash"
echo "  Run drush:           docker exec social_web drush status"
echo ""
echo "Script commands:"
echo "  Check status:        $0 --status"
echo "  Run again:           $0"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "###############################################################################"
