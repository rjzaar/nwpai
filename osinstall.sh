#!/bin/bash

###############################################################################
# Open Social Docker Installation Script for Ubuntu
# This script automates the complete installation of Open Social using Docker
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/Sites/social"
GIT_REPO="https://github.com/goalgorilla/drupal_social.git"

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

check_root() {
    if [ "$EUID" -eq 0 ]; then 
        print_error "Please do not run this script as root or with sudo"
        exit 1
    fi
}

confirm_continue() {
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
}

# Start installation
clear
echo "###############################################################################"
echo "#                                                                             #"
echo "#           Open Social Docker Installation Script for Ubuntu                #"
echo "#                                                                             #"
echo "###############################################################################"
echo ""
echo "This script will install:"
echo "  - Docker and Docker Compose"
echo "  - Git"
echo "  - Composer"
echo "  - Open Social with all dependencies"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""

check_root
confirm_continue

###############################################################################
# Step 1: Update System
###############################################################################
print_step "Step 1: Updating system packages..."
sudo apt update
sudo apt upgrade -y

###############################################################################
# Step 2: Install Docker
###############################################################################
print_step "Step 2: Installing Docker..."

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

# Add user to docker group
sudo usermod -aG docker $USER

# Verify Docker installation
docker --version
docker compose version

print_warning "You may need to log out and log back in for Docker group changes to take effect."
echo "Attempting to apply group changes..."
newgrp docker <<EONG

###############################################################################
# Step 3: Install Git
###############################################################################
print_step "Step 3: Installing Git..."
sudo apt install -y git

# Configure Git if not already configured
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter your Git name: " git_name
    git config --global user.name "$git_name"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Enter your Git email: " git_email
    git config --global user.email "$git_email"
fi

###############################################################################
# Step 4: Install Composer
###############################################################################
print_step "Step 4: Installing Composer..."
cd /tmp
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php
composer --version

###############################################################################
# Step 5: Clone Open Social Repository
###############################################################################
print_step "Step 5: Cloning Open Social repository..."

# Create parent directory if it doesn't exist
mkdir -p "$(dirname "$INSTALL_DIR")"

# Clone repository
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory $INSTALL_DIR already exists."
    read -p "Do you want to remove it and clone fresh? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        git clone "$GIT_REPO" "$INSTALL_DIR"
    else
        echo "Using existing directory..."
    fi
else
    git clone "$GIT_REPO" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

###############################################################################
# Step 6: Install Dependencies
###############################################################################
print_step "Step 6: Installing PHP dependencies with Composer..."
composer install

###############################################################################
# Step 7: Start Nginx Proxy
###############################################################################
print_step "Step 7: Starting Nginx proxy container..."

# Check if proxy container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^proxy$'; then
    print_warning "Proxy container already exists. Removing old container..."
    docker rm -f proxy
fi

docker run -d -p 80:80 --name=proxy \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    nginxproxy/nginx-proxy

echo "Waiting for proxy to start..."
sleep 5

###############################################################################
# Step 8: Build and Start Containers
###############################################################################
print_step "Step 8: Building and starting Docker containers..."
echo "This may take several minutes on first run..."

docker-compose up -d

echo "Waiting for containers to fully start..."
sleep 15

# Verify containers are running
echo -e "\nContainer status:"
docker ps --format "table {{.Names}}\t{{.Status}}"

###############################################################################
# Step 9: Configure Hosts File
###############################################################################
print_step "Step 9: Configuring /etc/hosts file..."

HOSTS_ENTRIES="127.0.0.1 social.local
127.0.0.1 mailcatcher.social.local
127.0.0.1 solr.social.local"

# Check if entries already exist
if grep -q "social.local" /etc/hosts; then
    print_warning "Entries already exist in /etc/hosts"
else
    echo "$HOSTS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
    echo "Added entries to /etc/hosts"
fi

###############################################################################
# Step 10: Stop Cron Container
###############################################################################
print_step "Step 10: Stopping cron container for installation..."
docker stop social_cron

###############################################################################
# Step 11: Run Installation Script
###############################################################################
print_step "Step 11: Running Open Social installation..."
echo "This will take 5-10 minutes. Please be patient..."

docker exec social_web bash /var/www/scripts/social/install/install_script.sh

###############################################################################
# Step 12: Start Cron Container
###############################################################################
print_step "Step 12: Starting all containers including cron..."
docker-compose up -d

###############################################################################
# Installation Complete
###############################################################################
echo ""
echo "###############################################################################"
echo -e "#${GREEN}                                                                             ${NC}#"
echo -e "#${GREEN}                    Installation Complete!                                  ${NC}#"
echo -e "#${GREEN}                                                                             ${NC}#"
echo "###############################################################################"
echo ""
echo "Your Open Social site is ready!"
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
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "###############################################################################"

EONG

# If newgrp didn't work, show a message
if [ $? -ne 0 ]; then
    print_warning "Could not apply Docker group changes automatically."
    echo "Please log out and log back in, then run:"
    echo "  cd $INSTALL_DIR"
    echo "  docker-compose up -d"
fi
