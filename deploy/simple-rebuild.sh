#!/bin/bash

# Simple rebuild script - just rebuilds containers with updated Dockerfile
# The Dockerfile now includes the frontend build step

set -e

echo "🔧 Simple Container Rebuild (Frontend Build Included)"
echo "===================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -d "/opt/cyberrange" ]; then
    print_error "Cyber range directory not found at /opt/cyberrange"
    exit 1
fi

cd /opt/cyberrange

print_status "Stopping current containers..."
if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml down
    cd ..
else
    docker-compose down 2>/dev/null || true
fi

print_status "Removing old images to force rebuild..."
docker image prune -f
docker rmi cyberrange-web 2>/dev/null || true

print_status "Rebuilding containers (this will build the frontend inside Docker)..."
print_warning "This may take a few minutes as it builds the React app..."

if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d --build --force-recreate
else
    docker-compose up -d --build --force-recreate
fi

print_status "Waiting for containers to start..."
sleep 30

print_status "Checking container status..."
if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml ps
else
    docker-compose ps
fi

print_status "Testing application..."
sleep 10

if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
    echo ""
    echo "🎉 SUCCESS! Your cyber range should now be accessible at:"
    echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
    echo ""
    echo "🔑 Default login credentials:"
    echo "   Admin: admin / admin123"
    echo "   User:  john.doe / password123"
else
    print_error "❌ Application still not responding"
    echo ""
    echo "Checking recent logs..."
    if [ -d "deploy" ]; then
        cd deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml logs --tail=15
    else
        docker-compose logs --tail=15
    fi
fi
