#!/bin/bash

# Check and start the cyber range application
# Run this on your DigitalOcean server to diagnose and fix app issues

echo "🔍 Checking Cyber Range Application Status"
echo "=========================================="

# Colors for output
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

echo ""
echo "1. Checking if application directory exists..."
if [ -d "/opt/cyberrange" ]; then
    print_status "Application directory found"
    cd /opt/cyberrange
    echo "   Contents:"
    ls -la
else
    print_error "Application directory not found at /opt/cyberrange"
    echo ""
    echo "🔧 You need to complete the deployment first:"
    echo "   1. Clone your repository to /opt/cyberrange"
    echo "   2. Run the deployment script"
    exit 1
fi

echo ""
echo "2. Checking Docker and Docker Compose..."
if command -v docker &> /dev/null; then
    print_status "Docker is installed"
    if systemctl is-active --quiet docker; then
        print_status "Docker service is running"
    else
        print_error "Docker service is not running"
        echo "   Starting Docker..."
        sudo systemctl start docker
    fi
else
    print_error "Docker is not installed"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    print_status "Docker Compose is installed"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

echo ""
echo "3. Checking for environment file..."
if [ -f ".env.prod" ]; then
    print_status "Production environment file found"
else
    print_warning "Production environment file missing"
    echo "   Creating basic .env.prod file..."
    cat > .env.prod << EOF
NODE_ENV=production
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
EOF
    print_status "Created .env.prod file"
fi

echo ""
echo "4. Checking current container status..."
if [ -d "deploy" ]; then
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml ps
else
    echo "   Using main directory..."
    docker-compose ps
fi

echo ""
echo "5. Checking if anything is listening on port 3000..."
if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    print_status "Something is listening on port 3000"
    netstat -tlnp 2>/dev/null | grep ":3000 "
else
    print_error "Nothing is listening on port 3000"
    echo "   This means the application is not running"
fi

echo ""
echo "6. Starting the application..."

# Try to start using the production compose file first
if [ -f "deploy/docker-compose.prod.yml" ]; then
    echo "   Using production configuration..."
    cd deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d --build
elif [ -f "docker-compose.yml" ]; then
    echo "   Using development configuration..."
    cd /opt/cyberrange
    docker-compose up -d --build
else
    print_error "No docker-compose file found!"
    exit 1
fi

echo ""
echo "7. Waiting for application to start..."
sleep 10

echo ""
echo "8. Checking application status after start..."
if [ -d "/opt/cyberrange/deploy" ]; then
    cd /opt/cyberrange/deploy
    docker-compose --env-file ../.env.prod -f docker-compose.prod.yml ps
else
    cd /opt/cyberrange
    docker-compose ps
fi

echo ""
echo "9. Testing application connectivity..."
echo "   Testing port 3000 directly..."
if curl -f -s http://localhost:3000 > /dev/null; then
    print_status "✅ Application is responding on port 3000!"
else
    print_error "❌ Application is not responding on port 3000"
    echo ""
    echo "   Checking application logs..."
    if [ -d "/opt/cyberrange/deploy" ]; then
        cd /opt/cyberrange/deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml logs --tail=20
    else
        cd /opt/cyberrange
        docker-compose logs --tail=20
    fi
fi

echo ""
echo "10. Testing through Nginx..."
if curl -f -s http://localhost > /dev/null; then
    print_status "✅ Application is accessible through Nginx!"
    echo ""
    echo "🎉 SUCCESS! Your cyber range should now be accessible at:"
    echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
else
    print_error "❌ Application is not accessible through Nginx"
    echo ""
    echo "   Checking Nginx status..."
    systemctl status nginx --no-pager -l
fi

echo ""
echo "=========================================="
echo "🔧 If the application still isn't working:"
echo ""
echo "View detailed logs:"
echo "   cd /opt/cyberrange && ./manage.sh logs"
echo ""
echo "Restart everything:"
echo "   cd /opt/cyberrange && ./manage.sh restart"
echo ""
echo "Check container status:"
echo "   cd /opt/cyberrange && ./manage.sh status"
