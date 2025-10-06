#!/bin/bash

# Fix frontend serving issue inside the container
# The backend is running but can't find the built React files

set -e

echo "🔧 Fixing Frontend Serving in Container"
echo "======================================="

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

cd /opt/cyberrange

print_status "Step 1: Checking what's inside the web container..."

# Check if frontend build directory exists in container
print_status "Checking frontend build directory in container..."
if docker exec deploy-web-1 ls -la /app/frontend/build/ 2>/dev/null; then
    print_status "✅ Frontend build directory exists in container"
    docker exec deploy-web-1 ls -la /app/frontend/build/
else
    print_error "❌ Frontend build directory missing in container"
    
    print_status "Checking what's in the frontend directory..."
    docker exec deploy-web-1 ls -la /app/frontend/ || echo "Frontend directory not found"
    
    print_status "Building frontend inside the container..."
    
    # Build frontend inside the running container
    docker exec deploy-web-1 sh -c "
        cd /app/frontend && 
        echo 'Installing frontend dependencies...' &&
        npm install &&
        echo 'Building React application...' &&
        npm run build &&
        echo 'Build complete!' &&
        ls -la build/
    "
    
    if docker exec deploy-web-1 ls -la /app/frontend/build/index.html 2>/dev/null; then
        print_status "✅ Frontend built successfully in container!"
    else
        print_error "❌ Frontend build failed in container"
        
        print_status "Checking for build errors..."
        docker exec deploy-web-1 sh -c "cd /app/frontend && npm run build" || true
        exit 1
    fi
fi

print_status "Step 2: Checking backend server configuration..."

# Check what the backend server is trying to serve
print_status "Checking backend server.js configuration..."
docker exec deploy-web-1 cat /app/backend/server.js | grep -A 5 -B 5 "static\|build\|frontend" || echo "No static file serving found"

print_status "Step 3: Restarting the web container to pick up changes..."

# Restart the web container
docker restart deploy-web-1

print_status "Waiting for container to restart..."
sleep 10

print_status "Step 4: Testing the application..."

# Test the application
if curl -f -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
    
    # Get the actual response to see what we're getting
    print_status "Sample response:"
    curl -s http://127.0.0.1:3000 | head -10
    
    # Check if it's the React app or still an error
    if curl -s http://127.0.0.1:3000 | grep -q "W Corp\|React\|root"; then
        print_status "✅ SUCCESS! React frontend is being served!"
        echo ""
        echo "🎉 Your cyber range is now fully working!"
        echo "   Access it at: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
    else
        print_warning "Application responding but may not be serving React frontend correctly"
    fi
    
else
    print_error "❌ Application still not responding"
    
    print_status "Checking container logs..."
    docker logs --tail=10 deploy-web-1
fi

print_status "Step 5: Final verification..."

# Check container status
print_status "Container status:"
docker ps | grep deploy

# Check what's actually being served
print_status "Testing different endpoints..."
echo "Root (/):"
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/
echo ""

echo "Static files:"
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/static/
echo ""

echo "API endpoint:"
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/api/
echo ""

print_status "Frontend fix attempt complete!"

echo ""
echo "🔧 If still not working, try:"
echo "1. Rebuild container: docker-compose up -d --build"
echo "2. Check server.js: docker exec deploy-web-1 cat /app/backend/server.js"
echo "3. Manual build: docker exec deploy-web-1 sh -c 'cd /app/frontend && npm run build'"
