#!/bin/bash

# Quick frontend build with progress indicator
# This is a simpler, faster approach

set -e

echo "🚀 Quick Frontend Build"
echo "======================"

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

# Find the frontend directory
if [ -d "/opt/cyberrange/frontend" ]; then
    FRONTEND_PATH="/opt/cyberrange/frontend"
elif [ -d "frontend" ]; then
    FRONTEND_PATH="$(pwd)/frontend"
else
    echo "ERROR: Cannot find frontend directory"
    exit 1
fi

print_status "Frontend path: $FRONTEND_PATH"

# Check if node_modules already exists in the container or mounted volume
if [ -d "$FRONTEND_PATH/node_modules" ]; then
    print_status "node_modules already exists, skipping npm install"
    
    # Just build
    print_status "Building React app (this will be faster)..."
    docker run --rm \
      -v "$FRONTEND_PATH:/app/frontend" \
      -w /app/frontend \
      node:16-alpine \
      sh -c "npm run build"
else
    # Full install and build with progress
    print_status "Installing dependencies and building (this may take a few minutes)..."
    print_warning "Please be patient - installing React dependencies..."
    
    docker run --rm \
      -v "$FRONTEND_PATH:/app/frontend" \
      -w /app/frontend \
      node:16-alpine \
      sh -c "npm install --legacy-peer-deps && npm run build"
fi

# Verify build
if [ -d "$FRONTEND_PATH/build" ] && [ -f "$FRONTEND_PATH/build/index.html" ]; then
    print_status "✅ Build successful!"
    
    # Restart container
    print_status "Restarting web container..."
    docker restart deploy-web-1
    
    sleep 10
    
    # Test
    print_status "Testing application..."
    if curl -s http://127.0.0.1:3000 | grep -q "<!DOCTYPE html>" && ! curl -s http://127.0.0.1:3000 | grep -q "<pre>Not Found</pre>"; then
        print_status "✅ SUCCESS! Application is working!"
        echo ""
        echo "🎉 Your cyber range is accessible at:"
        echo "   http://$(curl -s ifconfig.me 2>/dev/null)"
        echo ""
        echo "🔑 Login: admin / admin123"
    else
        print_warning "Application may still have issues. Check logs:"
        echo "   docker logs deploy-web-1"
    fi
else
    echo "ERROR: Build failed"
    exit 1
fi
