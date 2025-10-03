#!/bin/bash

# Quick fix script to enable passwordless sudo for deploy user
# Run this as root to fix the sudo password issue

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Usage: sudo ./fix-sudo.sh"
   exit 1
fi

echo "Setting up passwordless sudo for deploy user..."

# Add deploy user to sudoers with no password requirement
echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/deploy
chmod 440 /etc/sudoers.d/deploy

echo "✅ Deploy user can now use sudo without password"
echo "You can now run the deployment script as the deploy user"
