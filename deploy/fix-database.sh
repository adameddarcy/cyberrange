#!/bin/bash

# Fix database connectivity issues
# This script addresses the database connection problems

set -e

echo "🔧 Fixing Database Connectivity Issues"
echo "======================================"

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

print_status "Step 1: Stopping all containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

print_status "Step 2: Checking database container specifically..."
docker ps -a | grep -E "(db|mysql)" || echo "No database containers found"

print_status "Step 3: Starting database container first and waiting..."
if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d db
    cd ..
else
    docker-compose up -d db
fi

print_status "Waiting 30 seconds for database to initialize..."
sleep 30

print_status "Step 4: Checking database status..."
DB_CONTAINER=$(docker ps --format "table {{.Names}}" | grep -E "(db|mysql)" | head -1)
if [ ! -z "$DB_CONTAINER" ]; then
    print_status "Database container found: $DB_CONTAINER"
    
    # Check if database is responding
    print_status "Testing database connectivity..."
    for i in {1..10}; do
        if docker exec "$DB_CONTAINER" mysqladmin ping -h localhost 2>/dev/null; then
            print_status "✅ Database is responding!"
            break
        else
            print_warning "Database not ready yet, attempt $i/10..."
            sleep 5
        fi
    done
    
    # Show database logs
    print_status "Recent database logs:"
    docker logs --tail=10 "$DB_CONTAINER"
    
else
    print_error "No database container running!"
    exit 1
fi

print_status "Step 5: Starting web application..."
if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d web
    cd ..
else
    docker-compose up -d web
fi

print_status "Step 6: Waiting for web application to connect to database..."
sleep 20

print_status "Step 7: Checking web application logs..."
WEB_CONTAINER=$(docker ps --format "table {{.Names}}" | grep -E "(web|app|cyberrange)" | head -1)
if [ ! -z "$WEB_CONTAINER" ]; then
    print_status "Web container: $WEB_CONTAINER"
    print_status "Recent web application logs:"
    docker logs --tail=15 "$WEB_CONTAINER"
else
    print_error "No web container found!"
fi

print_status "Step 8: Testing connectivity..."
sleep 10

# Test database connectivity from web container
if [ ! -z "$WEB_CONTAINER" ] && [ ! -z "$DB_CONTAINER" ]; then
    print_status "Testing database connection from web container..."
    if docker exec "$WEB_CONTAINER" nc -z db 3306 2>/dev/null; then
        print_status "✅ Web container can reach database!"
    else
        print_error "❌ Web container cannot reach database"
        
        # Show network information
        print_status "Network information:"
        docker network ls
        docker inspect $(docker ps -q) --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
    fi
fi

# Test application response
print_status "Testing application response..."
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ SUCCESS! Application is responding!"
    echo ""
    echo "🎉 Your cyber range is now accessible at:"
    echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
    echo ""
    echo "🔑 Default login credentials:"
    echo "   Admin: admin / admin123"
    echo "   User:  john.doe / password123"
else
    print_error "❌ Application still not responding"
    
    print_status "Final container status:"
    docker ps
    
    print_status "Port check:"
    netstat -tlnp | grep -E ":(3000|3306)" || echo "No services on ports 3000 or 3306"
    
    echo ""
    echo "🔧 Additional troubleshooting needed:"
    echo "1. Check if database is actually ready: docker exec $DB_CONTAINER mysql -u root -p -e 'SHOW DATABASES;'"
    echo "2. Check web container environment: docker exec $WEB_CONTAINER env | grep DB"
    echo "3. Check network connectivity: docker exec $WEB_CONTAINER ping db"
    echo "4. Manual database test: docker exec $WEB_CONTAINER mysql -h db -u wcorp_user -p"
fi

print_status "Database fix attempt complete!"
