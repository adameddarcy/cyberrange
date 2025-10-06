#!/bin/bash

# Check the actual directory structure and fix the build issue

set -e

echo "🔍 Checking Directory Structure and Fixing Build"
echo "================================================"

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

print_status "Step 1: Checking current directory and structure..."
echo "Current directory: $(pwd)"
echo ""
echo "Directory contents:"
ls -la

echo ""
print_status "Step 2: Looking for frontend directory..."

if [ -d "frontend" ]; then
    print_status "✅ Frontend directory found"
    echo "Frontend contents:"
    ls -la frontend/
    
    if [ -f "frontend/package.json" ]; then
        print_status "✅ Frontend package.json found"
    else
        print_error "❌ Frontend package.json missing"
    fi
else
    print_error "❌ Frontend directory not found"
    echo ""
    echo "Available directories:"
    ls -la | grep "^d"
fi

echo ""
print_status "Step 3: Checking if we're in the right location..."

# Check if we have the expected cyberrange structure
if [ -f "docker-compose.yml" ] || [ -f "deploy/docker-compose.prod.yml" ]; then
    print_status "✅ Found docker-compose files - we're in the right place"
else
    print_error "❌ No docker-compose files found"
    echo "Are we in the right directory?"
fi

echo ""
print_status "Step 4: Checking what the containers are actually mounting..."

# Check the actual volume mounts
print_status "Current container volume mounts:"
docker inspect deploy-web-1 --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null || echo "Container not found or not running"

echo ""
print_status "Step 5: Finding the correct frontend path..."

# Let's find where the frontend actually is
FRONTEND_PATH=""

if [ -d "/opt/cyberrange/frontend" ]; then
    FRONTEND_PATH="/opt/cyberrange/frontend"
    print_status "✅ Found frontend at: $FRONTEND_PATH"
elif [ -d "frontend" ]; then
    FRONTEND_PATH="$(pwd)/frontend"
    print_status "✅ Found frontend at: $FRONTEND_PATH"
else
    print_error "❌ Cannot find frontend directory"
    echo ""
    echo "Let's check what's actually in /opt/cyberrange:"
    ls -la /opt/cyberrange/ 2>/dev/null || echo "Directory doesn't exist"
    exit 1
fi

echo ""
print_status "Step 6: Checking frontend structure..."
if [ -f "$FRONTEND_PATH/package.json" ]; then
    print_status "✅ package.json found"
    echo "Frontend package.json preview:"
    head -10 "$FRONTEND_PATH/package.json"
else
    print_error "❌ package.json not found at $FRONTEND_PATH"
    echo "Contents of $FRONTEND_PATH:"
    ls -la "$FRONTEND_PATH/"
    exit 1
fi

echo ""
print_status "Step 7: Building frontend with correct path..."

# Build using the correct path
docker run --rm \
  -v "$FRONTEND_PATH:/app/frontend" \
  -w /app/frontend \
  node:16-alpine \
  sh -c "
    echo 'Installing dependencies...' &&
    npm install &&
    echo 'Building React application...' &&
    npm run build &&
    echo 'Build complete!' &&
    ls -la build/
  "

echo ""
print_status "Step 8: Verifying build..."
if [ -d "$FRONTEND_PATH/build" ] && [ -f "$FRONTEND_PATH/build/index.html" ]; then
    print_status "✅ Frontend built successfully!"
    echo "Build directory contents:"
    ls -la "$FRONTEND_PATH/build/"
    
    echo ""
    echo "Sample of built index.html:"
    head -5 "$FRONTEND_PATH/build/index.html"
else
    print_error "❌ Frontend build failed"
    exit 1
fi

echo ""
print_status "Step 9: Restarting web container..."
docker restart deploy-web-1

print_status "Waiting for container to start..."
sleep 15

echo ""
print_status "Step 10: Testing the application..."
if curl -f -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
    
    # Get the response and check if it's the React app
    RESPONSE=$(curl -s http://127.0.0.1:3000)
    if echo "$RESPONSE" | grep -q "<!DOCTYPE html>" && ! echo "$RESPONSE" | grep -q "<pre>Not Found</pre>"; then
        print_status "✅ SUCCESS! React frontend is being served!"
        
        echo ""
        echo "🎉 CYBER RANGE IS FULLY OPERATIONAL!"
        echo "===================================="
        echo ""
        echo "🌐 Access your cyber range at:"
        echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
        echo ""
        echo "🔑 Login with: admin / admin123"
        
    else
        print_warning "Application responding but may still have issues"
        echo "Response preview:"
        echo "$RESPONSE" | head -5
    fi
else
    print_error "❌ Application still not responding"
    
    echo ""
    print_status "Container logs:"
    docker logs --tail=10 deploy-web-1
fi

print_status "Directory structure check and fix complete!"
