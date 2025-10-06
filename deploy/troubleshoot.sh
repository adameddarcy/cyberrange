#!/bin/bash

# Troubleshooting script for DigitalOcean deployment
# Run this on your DigitalOcean server to diagnose issues

echo "🔍 W Corp Cyber Range - Deployment Troubleshooting"
echo "=================================================="

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
echo "1. Checking Docker status..."
if systemctl is-active --quiet docker; then
    print_status "Docker is running"
else
    print_error "Docker is not running"
    echo "   Fix: sudo systemctl start docker"
fi

echo ""
echo "2. Checking Docker containers..."
if command -v docker-compose &> /dev/null; then
    if [ -d "/opt/cyberrange" ]; then
        cd /opt/cyberrange/deploy 2>/dev/null || cd /opt/cyberrange
        echo "   Container status:"
        docker-compose ps 2>/dev/null || docker ps
    else
        print_error "Cyber range directory not found at /opt/cyberrange"
    fi
else
    print_error "Docker Compose not installed"
fi

echo ""
echo "3. Checking Nginx status..."
if systemctl is-active --quiet nginx; then
    print_status "Nginx is running"
else
    print_error "Nginx is not running"
    echo "   Fix: sudo systemctl start nginx"
fi

echo ""
echo "4. Checking Nginx configuration..."
if [ -f "/etc/nginx/sites-enabled/cyberrange" ]; then
    print_status "Cyber range Nginx config is enabled"
else
    print_error "Cyber range Nginx config is missing"
    echo "   Available configs:"
    ls -la /etc/nginx/sites-available/ 2>/dev/null || echo "   No configs found"
    echo "   Enabled configs:"
    ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "   No configs found"
fi

echo ""
echo "5. Checking application files..."
if [ -d "/opt/cyberrange" ]; then
    print_status "Application directory exists"
    echo "   Contents:"
    ls -la /opt/cyberrange/
    
    if [ -f "/opt/cyberrange/.env.prod" ]; then
        print_status "Production environment file exists"
    else
        print_warning "Production environment file missing"
    fi
else
    print_error "Application directory missing"
fi

echo ""
echo "6. Checking ports..."
echo "   Port 3000 (application):"
if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    print_status "Application is listening on port 3000"
    netstat -tlnp 2>/dev/null | grep ":3000 "
else
    print_error "Nothing listening on port 3000"
fi

echo "   Port 80 (nginx):"
if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    print_status "Nginx is listening on port 80"
else
    print_error "Nothing listening on port 80"
fi

echo ""
echo "7. Checking firewall..."
if command -v ufw &> /dev/null; then
    echo "   UFW status:"
    ufw status
else
    print_warning "UFW not installed"
fi

echo ""
echo "8. Recent logs..."
echo "   Nginx error log (last 10 lines):"
tail -n 10 /var/log/nginx/error.log 2>/dev/null || echo "   No nginx error log found"

echo ""
echo "   System log for nginx (last 5 lines):"
journalctl -u nginx --no-pager -n 5 2>/dev/null || echo "   No systemd logs found"

echo ""
echo "=================================================="
echo "🔧 Quick fixes to try:"
echo ""
echo "If containers aren't running:"
echo "   cd /opt/cyberrange/deploy"
echo "   docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d"
echo ""
echo "If Nginx config is missing:"
echo "   sudo ln -sf /etc/nginx/sites-available/cyberrange /etc/nginx/sites-enabled/"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "If application isn't responding:"
echo "   /opt/cyberrange/manage.sh restart"
echo ""
echo "Check application logs:"
echo "   /opt/cyberrange/manage.sh logs"
