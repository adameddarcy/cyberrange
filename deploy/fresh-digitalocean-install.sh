#!/bin/bash

# Complete Fresh DigitalOcean Deployment for W Corp Cyber Range
# This script does everything from scratch on a new droplet
# Run as root on a fresh Ubuntu 22.04+ droplet

set -e

echo "🚀 W Corp Cyber Range - Complete Fresh Installation"
echo "===================================================="
echo ""
echo "This will set up everything on your DigitalOcean droplet:"
echo "  ✓ System updates and dependencies"
echo "  ✓ Docker and Docker Compose"
echo "  ✓ Nginx reverse proxy with security"
echo "  ✓ Firewall configuration"
echo "  ✓ Application deployment"
echo "  ✓ Frontend build"
echo ""

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   echo "Run: sudo bash $0"
   exit 1
fi

print_status "Starting fresh installation..."
echo ""

# ============================================================
# STEP 1: System Setup
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1/8: System Updates and Dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "Updating system packages..."
apt update && apt upgrade -y

print_info "Installing required packages..."
apt install -y curl git ufw nginx net-tools

print_status "System setup complete"
echo ""

# ============================================================
# STEP 2: Docker Installation
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2/8: Docker Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v docker &> /dev/null; then
    print_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    print_status "Docker installed"
else
    print_status "Docker already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    print_info "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed"
else
    print_status "Docker Compose already installed"
fi

systemctl enable docker
systemctl start docker

print_status "Docker setup complete"
echo ""

# ============================================================
# STEP 3: Firewall Configuration
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3/8: Firewall Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "Configuring UFW firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS (for future SSL)
ufw deny 3000      # Block direct app access
ufw deny 3306      # Block direct database access

print_status "Firewall configured securely"
echo ""

# ============================================================
# STEP 4: Application Directory Setup
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4/8: Application Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

APP_DIR="/opt/cyberrange"

if [ -d "$APP_DIR" ]; then
    print_warning "Application directory already exists"
    read -p "Remove and reinstall? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing existing installation..."
        docker stop $(docker ps -aq) 2>/dev/null || true
        docker rm $(docker ps -aq) 2>/dev/null || true
        rm -rf "$APP_DIR"
    else
        print_error "Installation cancelled"
        exit 1
    fi
fi

print_info "Creating application directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

print_info "Cloning repository..."
read -p "Enter your GitHub repository URL (or press Enter to skip if files already present): " REPO_URL

if [ ! -z "$REPO_URL" ]; then
    git clone "$REPO_URL" .
    print_status "Repository cloned"
else
    print_warning "Skipping git clone - ensure files are uploaded manually"
fi

print_status "Application directory ready"
echo ""

# ============================================================
# STEP 5: Environment Configuration
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5/8: Environment Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "Creating production environment file..."
DB_PASS=$(openssl rand -base64 32 | tr -d '=+/')
JWT_SEC=$(openssl rand -base64 64 | tr -d '=+/')
MYSQL_ROOT_PASS=$(openssl rand -base64 32 | tr -d '=+/')

cat > "$APP_DIR/.env.prod" << EOF
NODE_ENV=production
DB_PASSWORD=${DB_PASS}
JWT_SECRET=${JWT_SEC}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASS}
EOF

print_status "Secure environment variables created"
print_warning "IMPORTANT: Passwords saved to $APP_DIR/.env.prod"
echo ""

# ============================================================
# STEP 6: Docker Compose Configuration
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6/8: Docker Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "Creating optimized docker-compose configuration..."
mkdir -p "$APP_DIR/deploy"

cat > "$APP_DIR/docker-compose.simple.yml" << 'EOFCOMPOSE'
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-root_password}
      - MYSQL_DATABASE=wcorp_db
      - MYSQL_USER=wcorp_user
      - MYSQL_PASSWORD=${DB_PASSWORD:-wcorp_pass}
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
      - DB_PASSWORD=${DB_PASSWORD:-wcorp_pass}
      - DB_NAME=wcorp_db
      - JWT_SECRET=${JWT_SECRET:-change_me}
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
        echo 'Installing backend dependencies...' &&
        cd /app/backend && npm install &&
        echo 'Starting backend server...' &&
        node server.js
      "

volumes:
  mysql_data:

networks:
  cyberrange-net:
    driver: bridge
EOFCOMPOSE

print_status "Docker configuration created"
echo ""

# ============================================================
# STEP 7: Frontend Build
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 7/8: Building React Frontend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$APP_DIR/frontend/package.json" ]; then
    print_info "Building React frontend (this may take 5-10 minutes)..."
    print_warning "Please be patient - installing and building React application..."
    
    docker run --rm \
      -v "$APP_DIR/frontend:/app" \
      -w /app \
      node:16-alpine \
      sh -c "npm install --legacy-peer-deps && npm run build" || {
        print_error "Frontend build failed"
        print_warning "Continuing anyway - you can build it later"
      }
    
    if [ -d "$APP_DIR/frontend/build" ]; then
        print_status "Frontend built successfully"
    else
        print_warning "Frontend build directory not found - may need manual build"
    fi
else
    print_warning "Frontend package.json not found - skipping build"
fi

echo ""

# ============================================================
# STEP 8: Start Application
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 8/8: Starting Application"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "Starting database..."
cd "$APP_DIR"
docker-compose --env-file .env.prod -f docker-compose.simple.yml up -d db

print_info "Waiting for database to be ready (30 seconds)..."
sleep 30

print_info "Starting web application..."
docker-compose --env-file .env.prod -f docker-compose.simple.yml up -d web

print_info "Waiting for application to start (15 seconds)..."
sleep 15

print_status "Containers started"
echo ""

# ============================================================
# Nginx Configuration
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Configuring Nginx Reverse Proxy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_info "Creating Nginx configuration..."

# Add rate limiting to main nginx.conf
if ! grep -q "limit_req_zone" /etc/nginx/nginx.conf; then
    sed -i '/http {/a\\tlimit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;' /etc/nginx/nginx.conf
fi

cat > /etc/nginx/sites-available/cyberrange << 'EOFNGINX'
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location ~* /(login|register|api/auth) {
        limit_req zone=login burst=3 nodelay;
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location ~ /\.(env|git) {
        deny all;
        return 404;
    }
}
EOFNGINX

ln -sf /etc/nginx/sites-available/cyberrange /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx

print_status "Nginx configured"
echo ""

# ============================================================
# Final Tests
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running Final Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sleep 5

print_info "Testing application..."
if curl -f -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    print_status "Application responding on localhost"
else
    print_warning "Application not yet responding (may still be starting)"
fi

print_info "Testing Nginx proxy..."
if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "Nginx proxy working"
else
    print_warning "Nginx proxy may need troubleshooting"
fi

EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 INSTALLATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Access your cyber range at:"
echo "   http://$EXTERNAL_IP"
echo ""
echo "🔑 Default Login Credentials:"
echo "   Admin:  admin / admin123"
echo "   User:   john.doe / password123"
echo ""
echo "📋 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🛠️ Management Commands:"
echo "   View logs:    docker logs -f \$(docker ps --format '{{.Names}}' | grep web)"
echo "   Restart:      cd $APP_DIR && docker-compose -f docker-compose.simple.yml restart"
echo "   Stop:         cd $APP_DIR && docker-compose -f docker-compose.simple.yml down"
echo "   Status:       docker ps"
echo ""
echo "📁 Important Files:"
echo "   App directory:  $APP_DIR"
echo "   Environment:    $APP_DIR/.env.prod"
echo "   Nginx config:   /etc/nginx/sites-available/cyberrange"
echo ""
print_warning "SECURITY REMINDER:"
echo "   • This application contains intentional vulnerabilities"
echo "   • For educational purposes only"
echo "   • Direct access to ports 3000 and 3306 is blocked"
echo "   • Access only through Nginx on port 80"
echo ""
print_status "Setup complete! Enjoy your cyber range! 🚀"
