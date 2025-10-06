#!/bin/bash

# Fix the .env.prod file with proper variable names
# Run this on your droplet to fix the environment file issue

set -e

echo "🔧 Fixing Environment File"
echo "=========================="

APP_DIR="/opt/cyberrange"

if [ ! -d "$APP_DIR" ]; then
    echo "Error: $APP_DIR not found"
    exit 1
fi

cd "$APP_DIR"

echo "Creating corrected environment file..."

# Generate passwords without special characters that cause issues
DB_PASS=$(openssl rand -base64 32 | tr -d '=+/')
JWT_SEC=$(openssl rand -base64 64 | tr -d '=+/')
MYSQL_ROOT_PASS=$(openssl rand -base64 32 | tr -d '=+/')

# Create the corrected .env.prod file
cat > .env.prod << EOF
NODE_ENV=production
DB_PASSWORD=${DB_PASS}
JWT_SECRET=${JWT_SEC}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASS}
EOF

echo "✅ Environment file fixed!"
echo ""
echo "New passwords generated (saved in .env.prod):"
cat .env.prod
echo ""

# Restart containers to pick up new environment
echo "Restarting containers..."
docker-compose --env-file .env.prod -f docker-compose.simple.yml restart

echo ""
echo "✅ Complete! Containers restarted with new environment."
echo ""
echo "Test your application at: http://$(curl -s ifconfig.me 2>/dev/null)"
