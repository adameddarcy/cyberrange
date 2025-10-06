#!/bin/bash

# Deep diagnostic script for cyber range deployment issues
# This script will find and fix the root cause

set -e

echo "🔍 Deep Diagnostic Analysis"
echo "==========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if we're in the right directory
if [ ! -d "/opt/cyberrange" ]; then
    print_error "Cyber range directory not found at /opt/cyberrange"
    exit 1
fi

cd /opt/cyberrange

echo ""
echo "1. 📁 Checking directory structure..."
print_info "Current directory: $(pwd)"
print_info "Directory contents:"
ls -la

if [ -d "frontend" ]; then
    print_status "Frontend directory exists"
    echo "   Frontend contents:"
    ls -la frontend/ | head -10
    
    if [ -d "frontend/build" ]; then
        print_status "Frontend build directory exists"
        echo "   Build contents:"
        ls -la frontend/build/ | head -5
    else
        print_error "Frontend build directory missing"
    fi
else
    print_error "Frontend directory missing"
fi

if [ -d "backend" ]; then
    print_status "Backend directory exists"
else
    print_error "Backend directory missing"
fi

echo ""
echo "2. 🐳 Checking Docker status..."
if systemctl is-active --quiet docker; then
    print_status "Docker service is running"
else
    print_error "Docker service is not running"
    print_info "Starting Docker..."
    sudo systemctl start docker
    sleep 5
fi

echo ""
echo "3. 📦 Checking current containers..."
print_info "All containers:"
docker ps -a

print_info "Running containers:"
docker ps

echo ""
echo "4. 🔌 Checking what's listening on ports..."
print_info "Port 3000 (application):"
netstat -tlnp 2>/dev/null | grep ":3000" || echo "   Nothing listening on port 3000"

print_info "Port 80 (nginx):"
netstat -tlnp 2>/dev/null | grep ":80" || echo "   Nothing listening on port 80"

print_info "Port 3306 (database):"
netstat -tlnp 2>/dev/null | grep ":3306" || echo "   Nothing listening on port 3306"

echo ""
echo "5. 📋 Checking environment and compose files..."
if [ -f ".env.prod" ]; then
    print_status "Production environment file exists"
    echo "   Environment variables:"
    grep -v PASSWORD .env.prod 2>/dev/null || echo "   (file exists but couldn't read safely)"
else
    print_warning "Production environment file missing"
fi

if [ -f "deploy/docker-compose.prod.yml" ]; then
    print_status "Production compose file exists"
elif [ -f "docker-compose.yml" ]; then
    print_status "Development compose file exists"
else
    print_error "No compose file found"
fi

echo ""
echo "6. 🔧 Attempting to start containers with detailed logging..."

# Stop everything first
print_info "Stopping all containers..."
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Try to start with the most basic configuration first
print_info "Starting with basic configuration..."

if [ -f "docker-compose.yml" ]; then
    print_info "Using docker-compose.yml"
    docker-compose up -d
    COMPOSE_FILE="docker-compose.yml"
    COMPOSE_CMD="docker-compose"
elif [ -f "deploy/docker-compose.prod.yml" ]; then
    print_info "Using production compose file"
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d
    COMPOSE_FILE="deploy/docker-compose.prod.yml"
    COMPOSE_CMD="docker-compose --env-file ../.env.prod -f docker-compose.prod.yml"
    cd ..
else
    print_error "No compose file available"
    exit 1
fi

echo ""
echo "7. ⏳ Waiting for containers to start..."
sleep 15

echo ""
echo "8. 📊 Container status after start attempt..."
if [ "$COMPOSE_FILE" = "docker-compose.yml" ]; then
    docker-compose ps
    docker-compose logs --tail=10
else
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml ps
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml logs --tail=10
    cd ..
fi

echo ""
echo "9. 🧪 Testing connectivity..."

# Test database first
print_info "Testing database connectivity..."
if docker ps | grep -q mysql; then
    DB_CONTAINER=$(docker ps --format "table {{.Names}}" | grep -E "(db|mysql)" | head -1)
    if [ ! -z "$DB_CONTAINER" ]; then
        print_info "Database container: $DB_CONTAINER"
        docker exec $DB_CONTAINER mysqladmin ping -h localhost 2>/dev/null && print_status "Database is responding" || print_error "Database not responding"
    fi
else
    print_error "No database container running"
fi

# Test web application
print_info "Testing web application..."
WEB_CONTAINER=$(docker ps --format "table {{.Names}}" | grep -E "(web|app|cyberrange)" | head -1)
if [ ! -z "$WEB_CONTAINER" ]; then
    print_info "Web container: $WEB_CONTAINER"
    
    # Check if the container is actually running
    if docker ps | grep -q "$WEB_CONTAINER"; then
        print_status "Web container is running"
        
        # Check container logs
        print_info "Recent container logs:"
        docker logs --tail=5 "$WEB_CONTAINER"
        
        # Test internal connectivity
        print_info "Testing internal port 3000..."
        docker exec "$WEB_CONTAINER" wget -q --spider http://localhost:3000 2>/dev/null && print_status "App responds internally" || print_error "App not responding internally"
        
    else
        print_error "Web container not running"
    fi
else
    print_error "No web container found"
fi

# Test external connectivity
print_info "Testing external connectivity..."
sleep 5
curl -I -s http://localhost:3000 2>/dev/null && print_status "Port 3000 accessible externally" || print_error "Port 3000 not accessible externally"

echo ""
echo "10. 🔍 Final diagnosis and recommendations..."

# Check if containers are running
RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}" | grep -v NAMES | wc -l)
if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    print_error "No containers are running!"
    echo ""
    echo "🔧 RECOMMENDED ACTIONS:"
    echo "1. Check Docker daemon: sudo systemctl status docker"
    echo "2. Check for port conflicts: sudo netstat -tlnp | grep -E ':(3000|3306|80)'"
    echo "3. Try manual container start: docker run -p 3000:3000 -it node:16-alpine sh"
    echo "4. Check disk space: df -h"
    echo "5. Check memory: free -h"
    
elif [ "$RUNNING_CONTAINERS" -eq 1 ]; then
    print_warning "Only 1 container running (need at least 2: web + db)"
    echo ""
    echo "🔧 RECOMMENDED ACTIONS:"
    echo "1. Check which container is missing"
    echo "2. Check container logs for startup errors"
    echo "3. Verify environment variables"
    echo "4. Check database connectivity"
    
else
    print_status "Multiple containers running"
    
    # If containers are running but app not responding, it's likely a configuration issue
    if ! curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_error "Containers running but application not responding"
        echo ""
        echo "🔧 RECOMMENDED ACTIONS:"
        echo "1. Check application logs: docker logs <web-container-name>"
        echo "2. Verify frontend build exists: docker exec <web-container> ls -la /app/frontend/build/"
        echo "3. Check backend server startup: docker exec <web-container> ps aux"
        echo "4. Verify database connection from app container"
        echo "5. Check if app is binding to correct interface (0.0.0.0 vs 127.0.0.1)"
    else
        print_status "Application appears to be working!"
        echo ""
        echo "🎉 Your cyber range should be accessible at:"
        echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
    fi
fi

echo ""
echo "=========================="
echo "📋 DIAGNOSTIC COMPLETE"
echo "=========================="
