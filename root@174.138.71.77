#!/bin/bash

# Fix frontend build issue for cyber range deployment
# This script builds the React frontend and restarts the containers

set -e

echo "🔧 Fixing Frontend Build Issue"
echo "==============================="

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
    docker-compose down
fi

print_status "Building React frontend locally first..."

# Check if frontend directory exists
if [ ! -d "frontend" ]; then
    print_error "Frontend directory not found!"
    exit 1
fi

cd frontend

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    print_status "Installing frontend dependencies..."
    npm install
fi

# Build the React app
print_status "Building React application..."
npm run build

if [ ! -d "build" ]; then
    print_error "Frontend build failed - build directory not created"
    exit 1
fi

print_status "✅ Frontend built successfully!"

# Go back to root
cd /opt/cyberrange

print_status "Rebuilding and starting containers..."

if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d --build
else
    docker-compose up -d --build
fi

print_status "Waiting for containers to start..."
sleep 15

print_status "Checking container status..."
if [ -d "deploy" ]; then
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml ps
else
    docker-compose ps
fi

print_status "Testing application..."
if curl -f -s http://localhost:3000 > /dev/null; then
    print_status "✅ Application is responding!"
    echo ""
    echo "🎉 SUCCESS! Your cyber range should now be accessible at:"
    echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
    echo ""
    echo "Default login credentials:"
    echo "   Admin: admin / admin123"
    echo "   User:  john.doe / password123"
else
    print_error "❌ Application still not responding"
    echo ""
    echo "Checking logs..."
    if [ -d "deploy" ]; then
        cd deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml logs --tail=10
    else
        docker-compose logs --tail=10
    fi
fi
