#!/bin/bash

# Fix frontend build issue using Docker (no local Node.js required)
# This script builds the React frontend inside a Docker container

set -e

echo "🔧 Fixing Frontend Build Issue (Docker Method)"
echo "==============================================="

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

print_status "Building React frontend using Docker..."

# Method 1: Use a temporary Node.js container to build the frontend
print_status "Creating temporary Node.js container to build frontend..."

# Create a temporary Dockerfile for building
cat > /tmp/build-frontend.dockerfile << 'EOF'
FROM node:16-alpine
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build
EOF

# Build the frontend using Docker
docker build -f /tmp/build-frontend.dockerfile -t temp-frontend-builder .

# Extract the built files from the container
print_status "Extracting built frontend files..."
docker run --rm -v "$(pwd)/frontend:/output" temp-frontend-builder sh -c "cp -r /app/build /output/"

# Clean up temporary image
docker rmi temp-frontend-builder
rm /tmp/build-frontend.dockerfile

# Verify the build was successful
if [ -d "frontend/build" ] && [ -f "frontend/build/index.html" ]; then
    print_status "✅ Frontend built successfully!"
    echo "   Build directory contents:"
    ls -la frontend/build/
else
    print_error "❌ Frontend build failed - build directory not found"
    exit 1
fi

print_status "Rebuilding and starting containers with built frontend..."

# Now rebuild the main containers
if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d --build
else
    docker-compose up -d --build
fi

print_status "Waiting for containers to start..."
sleep 20

print_status "Checking container status..."
if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml ps
else
    docker-compose ps
fi

print_status "Testing application..."
echo "   Testing port 3000 directly..."

# Wait a bit more for the app to fully start
sleep 10

if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Application is responding on port 3000!"
    
    # Test through nginx
    if curl -f -s http://localhost > /dev/null 2>&1; then
        print_status "✅ Application is accessible through Nginx!"
        echo ""
        echo "🎉 SUCCESS! Your cyber range is now accessible at:"
        echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
        echo ""
        echo "🔑 Default login credentials:"
        echo "   Admin: admin / admin123"
        echo "   User:  john.doe / password123"
        echo "   User:  jane.smith / qwerty"
    else
        print_warning "Application responds on port 3000 but not through Nginx"
        echo "   Check Nginx configuration"
    fi
else
    print_error "❌ Application still not responding"
    echo ""
    echo "📋 Checking logs for errors..."
    if [ -d "deploy" ]; then
        cd deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml logs --tail=20
    else
        docker-compose logs --tail=20
    fi
    
    echo ""
    echo "🔧 Additional troubleshooting:"
    echo "   Check container status: docker ps"
    echo "   Check specific logs: docker logs <container-name>"
    echo "   Restart containers: ./manage.sh restart"
fi

print_status "Cleanup completed!"
