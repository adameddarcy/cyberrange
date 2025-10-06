#!/bin/bash

# Fix the volume mount build issue
# Build frontend on host so it persists through container restarts

set -e

echo "🔧 Fixing Volume Mount Build Issue"
echo "=================================="

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

print_status "Step 1: Understanding the volume mount issue..."
print_warning "The problem: Volume mounts override container builds"
echo "   Host: /opt/cyberrange/frontend -> Container: /app/frontend"
echo "   When we build inside container and restart, host files override it"

print_status "Step 2: Building frontend on the host using a temporary container..."

# Create a temporary container just for building
print_status "Creating temporary Node.js container for building..."

# Stop the current web container temporarily
docker stop deploy-web-1

# Create a temporary container with the same setup to build the frontend
docker run --rm \
  -v "$(pwd)/frontend:/app/frontend" \
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

print_status "Step 3: Verifying build on host..."
if [ -d "frontend/build" ] && [ -f "frontend/build/index.html" ]; then
    print_status "✅ Frontend built successfully on host!"
    echo "   Build directory contents:"
    ls -la frontend/build/
    
    echo "   Sample of index.html:"
    head -5 frontend/build/index.html
else
    print_error "❌ Frontend build failed on host"
    exit 1
fi

print_status "Step 4: Starting the web container..."
docker start deploy-web-1

print_status "Waiting for container to start..."
sleep 10

print_status "Step 5: Verifying the build is accessible in container..."
if docker exec deploy-web-1 ls -la /app/frontend/build/index.html 2>/dev/null; then
    print_status "✅ Build files accessible in container!"
else
    print_error "❌ Build files not accessible in container"
    exit 1
fi

print_status "Step 6: Testing the application..."

# Test the application
sleep 5
if curl -f -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
    
    # Check if we're getting the React app
    RESPONSE=$(curl -s http://127.0.0.1:3000)
    if echo "$RESPONSE" | grep -q "<!DOCTYPE html>.*<title>.*</title>" && ! echo "$RESPONSE" | grep -q "Error"; then
        print_status "✅ SUCCESS! React frontend is being served!"
        
        echo ""
        echo "🎉 CYBER RANGE IS FULLY OPERATIONAL!"
        echo "===================================="
        echo ""
        echo "🌐 Access your cyber range at:"
        echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
        echo ""
        echo "🔑 Default Login Credentials:"
        echo "   Admin:  admin / admin123"
        echo "   User:   john.doe / password123"
        echo "   User:   jane.smith / qwerty"
        echo ""
        echo "🎯 What you can do:"
        echo "   • Practice SQL injection attacks"
        echo "   • Test broken access control (IDOR)"
        echo "   • Explore file upload vulnerabilities"
        echo "   • Learn about security misconfigurations"
        echo "   • And much more!"
        echo ""
        print_warning "Remember: This is for educational purposes only!"
        
    else
        print_warning "Application responding but may still be serving error page"
        echo "Response preview:"
        echo "$RESPONSE" | head -10
    fi
    
else
    print_error "❌ Application still not responding"
    
    print_status "Checking container logs..."
    docker logs --tail=10 deploy-web-1
    
    print_status "Checking container status..."
    docker ps | grep deploy
fi

print_status "Step 7: Final verification..."

# Test Nginx proxy as well
print_status "Testing Nginx proxy..."
if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "✅ Nginx proxy also working!"
else
    print_warning "Nginx proxy may need configuration"
    echo "   Try: systemctl reload nginx"
fi

print_status "Volume mount build fix complete!"

echo ""
echo "🔧 If you need to rebuild the frontend again:"
echo "   1. cd /opt/cyberrange"
echo "   2. docker run --rm -v \$(pwd)/frontend:/app/frontend -w /app/frontend node:16-alpine sh -c 'npm run build'"
echo "   3. docker restart deploy-web-1"
