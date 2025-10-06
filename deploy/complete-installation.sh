#!/bin/bash

# Complete the installation from where it left off
# This script finishes what the fresh install started

set -e

echo "🔧 Completing Cyber Range Installation"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

APP_DIR="/opt/cyberrange"

if [ ! -d "$APP_DIR" ]; then
    print_error "Application directory not found at $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

echo ""
echo "Step 1: Stopping any existing containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo ""
echo "Step 2: Checking directory structure..."
print_status "App directory: $APP_DIR"

if [ -f "frontend/package.json" ]; then
    print_status "Frontend found"
else
    print_error "Frontend not found"
    exit 1
fi

if [ -f "backend/server.js" ]; then
    print_status "Backend found"
else
    print_error "Backend not found"
    exit 1
fi

if [ -f "database/init.sql" ]; then
    print_status "Database init found"
else
    print_warning "Database init.sql not found - will create empty"
    mkdir -p database
    touch database/init.sql
fi

echo ""
echo "Step 3: Creating simple environment file..."
cat > .env.prod << 'EOF'
NODE_ENV=production
DB_PASSWORD=wcorp_pass
JWT_SECRET=jwt_secret_key_for_training
MYSQL_ROOT_PASSWORD=root_password
EOF
print_status "Environment file created"

echo ""
echo "Step 4: Creating docker-compose configuration..."
cat > docker-compose.simple.yml << 'EOFCOMPOSE'
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - MYSQL_DATABASE=wcorp_db
      - MYSQL_USER=wcorp_user
      - MYSQL_PASSWORD=wcorp_pass
    ports:
      - "127.0.0.1:3306:3306"
    volumes:
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
      - mysql_data:/var/lib/mysql
    networks:
      - cyberrange-net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 10s
      start_period: 40s
    restart: unless-stopped

  web:
    image: node:16-alpine
    working_dir: /app
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_USER=wcorp_user
      - DB_PASSWORD=wcorp_pass
      - DB_NAME=wcorp_db
      - JWT_SECRET=jwt_secret_key_for_training
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - ./backend:/app/backend
      - ./frontend:/app/frontend
      - ./uploads:/app/uploads
    networks:
      - cyberrange-net
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    command: >
      sh -c "
        echo 'Starting backend server...' &&
        cd /app/backend &&
        npm install &&
        node server.js
      "

volumes:
  mysql_data:

networks:
  cyberrange-net:
    driver: bridge
EOFCOMPOSE
print_status "Docker compose file created"

echo ""
echo "Step 5: Building React frontend (this takes 5-10 minutes)..."
print_warning "Please be patient - installing React dependencies..."

if [ -d "frontend/build" ]; then
    print_status "Frontend already built, skipping..."
else
    docker run --rm \
      -v "$APP_DIR/frontend:/app" \
      -w /app \
      node:16-alpine \
      sh -c "npm install --legacy-peer-deps && npm run build" || {
        print_error "Frontend build failed"
        print_warning "Continuing anyway - you can build later"
      }
fi

if [ -d "frontend/build" ]; then
    print_status "Frontend build complete"
    ls -lh frontend/build/
else
    print_error "Frontend build not found - application may not work correctly"
fi

echo ""
echo "Step 6: Creating uploads directory..."
mkdir -p uploads
chmod 777 uploads
print_status "Uploads directory ready"

echo ""
echo "Step 7: Starting database..."
docker-compose -f docker-compose.simple.yml up -d db

echo "Waiting for database to be ready (30 seconds)..."
sleep 30

echo ""
echo "Step 8: Starting web application..."
docker-compose -f docker-compose.simple.yml up -d web

echo "Waiting for web app to start (20 seconds)..."
sleep 20

echo ""
echo "Step 9: Checking container status..."
docker ps

echo ""
echo "Step 10: Testing application..."
sleep 5

if curl -f -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
    
    RESPONSE=$(curl -s http://127.0.0.1:3000)
    if echo "$RESPONSE" | grep -q "<!DOCTYPE html>" && ! echo "$RESPONSE" | grep -q "<pre>Not Found</pre>"; then
        print_status "✅ Frontend is being served correctly!"
    else
        print_warning "Application responding but frontend may not be built"
        echo "You may need to build the frontend manually"
    fi
else
    print_error "Application not responding yet"
    echo ""
    echo "Checking logs..."
    docker logs $(docker ps --format '{{.Names}}' | grep web | head -1) --tail=20
fi

echo ""
echo "Step 11: Checking Nginx..."
systemctl reload nginx 2>/dev/null || true

if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "✅ Nginx proxy working!"
else
    print_warning "Nginx may need configuration check"
fi

EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Access your cyber range at:"
echo "   http://$EXTERNAL_IP"
echo ""
echo "🔑 Login credentials:"
echo "   admin / admin123"
echo "   john.doe / password123"
echo ""
echo "📋 Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}"
echo ""
echo "🛠️ Useful commands:"
echo "   Logs:    docker logs -f \$(docker ps --format '{{.Names}}' | grep web)"
echo "   Restart: docker-compose -f docker-compose.simple.yml restart"
echo "   Status:  docker ps"
echo ""

if [ ! -d "frontend/build" ]; then
    print_warning "Frontend is not built!"
    echo ""
    echo "To build the frontend manually:"
    echo "   docker run --rm -v $APP_DIR/frontend:/app -w /app node:16-alpine sh -c 'npm install && npm run build'"
    echo "   docker-compose -f docker-compose.simple.yml restart web"
fi

print_status "Setup complete!"
