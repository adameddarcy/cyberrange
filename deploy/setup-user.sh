#!/bin/bash

# Script to create a regular user for deployment
# Run this as root first, then switch to the new user

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} This setup script must be run as root"
   exit 1
fi

print_status "Creating deployment user..."

# Create user
USERNAME="deploy"
useradd -m -s /bin/bash $USERNAME

# Add to sudo group
usermod -aG sudo $USERNAME

# Set up SSH key access (copy from root)
if [ -d "/root/.ssh" ]; then
    print_status "Copying SSH keys..."
    mkdir -p /home/$USERNAME/.ssh
    cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
    chmod 700 /home/$USERNAME/.ssh
    chmod 600 /home/$USERNAME/.ssh/authorized_keys
fi

print_status "User '$USERNAME' created successfully!"
print_warning "Now switch to the new user and run the deployment:"
echo ""
echo "  su - $USERNAME"
echo "  # Upload deploy-digitalocean.sh to /home/$USERNAME/"
echo "  chmod +x deploy-digitalocean.sh"
echo "  ./deploy-digitalocean.sh"
echo ""
print_status "Or if using SSH:"
echo "  ssh $USERNAME@your-server-ip"
echo "  # Then run the deployment script"
