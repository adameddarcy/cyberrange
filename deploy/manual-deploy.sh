#!/bin/bash

# Manual deployment script - starts completely from scratch
# Use this when automated scripts aren't working

set -e

echo "🚀 Manual Cyber Range Deployment"
echo "================================="

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

print_status "Step 1: Clean slate - removing all containers and images..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker rmi $(docker images -q) 2>/dev/null || true
docker system prune -af

print_status "Step 2: Creating basic environment file..."
cat > .env << 'EOF'
NODE_ENV=development
DB_HOST=db
DB_USER=wcorp_user
DB_PASSWORD=wcorp_pass
DB_NAME=wcorp_db
JWT_SECRET=predictable_secret_key_123
MYSQL_ROOT_PASSWORD=root_password
MYSQL_DATABASE=wcorp_db
MYSQL_USER=wcorp_user
MYSQL_PASSWORD=wcorp_pass
EOF

print_status "Step 3: Creating simple docker-compose.yml..."
cat > docker-compose.simple.yml << 'EOF'
version: '3.8'

services:
  # Database first
  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - MYSQL_DATABASE=wcorp_db
      - MYSQL_USER=wcorp_user
      - MYSQL_PASSWORD=wcorp_pass
    ports:
      - "3306:3306"
    volumes:
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - cyberrange-net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  # Simple web service
  web:
    image: node:16-alpine
    working_dir: /app
    environment:
      - NODE_ENV=development
      - DB_HOST=db
      - DB_USER=wcorp_user
      - DB_PASSWORD=wcorp_pass
      - DB_NAME=wcorp_db
      - JWT_SECRET=predictable_secret_key_123
    ports:
      - "3000:3000"
    volumes:
      - ./backend:/app/backend
      - ./frontend:/app/frontend
      - ./uploads:/app/uploads
    networks:
      - cyberrange-net
    depends_on:
      db:
        condition: service_healthy
    command: >
      sh -c "
        echo 'Installing backend dependencies...' &&
        cd /app/backend && npm install &&
        echo 'Installing frontend dependencies...' &&
        cd /app/frontend && npm install &&
        echo 'Building frontend...' &&
        npm run build &&
        echo 'Starting backend server...' &&
        cd /app/backend && node server.js
      "

networks:
  cyberrange-net:
    driver: bridge
EOF

print_status "Step 4: Starting database first..."
docker-compose -f docker-compose.simple.yml up -d db

print_status "Step 5: Waiting for database to be ready..."
sleep 30

print_status "Step 6: Starting web application..."
docker-compose -f docker-compose.simple.yml up -d web

print_status "Step 7: Waiting for application to start..."
sleep 60

print_status "Step 8: Checking status..."
docker-compose -f docker-compose.simple.yml ps

print_status "Step 9: Testing application..."
if curl -f -s http://localhost:3000 > /dev/null; then
    print_status "✅ SUCCESS! Application is responding!"
    echo ""
    echo "🎉 Your cyber range is accessible at:"
    echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
    echo ""
    echo "🔑 Default credentials:"
    echo "   admin / admin123"
    echo "   john.doe / password123"
else
    print_error "❌ Application still not responding"
    echo ""
    echo "Container logs:"
    docker-compose -f docker-compose.simple.yml logs --tail=20
fi

print_status "Manual deployment complete!"
echo ""
echo "To manage the application:"
echo "  Start:   docker-compose -f docker-compose.simple.yml up -d"
echo "  Stop:    docker-compose -f docker-compose.simple.yml down"
echo "  Logs:    docker-compose -f docker-compose.simple.yml logs -f"
echo "  Status:  docker-compose -f docker-compose.simple.yml ps"
