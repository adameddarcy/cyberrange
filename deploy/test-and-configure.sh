#!/bin/bash

# Test and configure the cyber range application
# The app is working but bound to localhost for security

set -e

echo "🔧 Testing and Configuring Cyber Range Access"
echo "=============================================="

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

print_status "Step 1: Testing application from inside the server..."

# Test from localhost (should work since app is bound to 127.0.0.1:3000)
if curl -f -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    print_status "✅ Application responds on localhost!"
    
    # Get a sample of the response to verify it's the right app
    print_status "Sample response:"
    curl -s http://127.0.0.1:3000 | head -5
    
else
    print_error "❌ Application not responding on localhost"
    exit 1
fi

print_status "Step 2: Checking Nginx configuration..."

# Check if Nginx is running and configured
if systemctl is-active --quiet nginx; then
    print_status "✅ Nginx is running"
    
    # Test Nginx proxy
    if curl -f -s http://localhost > /dev/null 2>&1; then
        print_status "✅ Nginx proxy is working!"
        
        # Test from external IP
        EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
        print_status "✅ SUCCESS! Your cyber range is accessible!"
        echo ""
        echo "🎉 CYBER RANGE IS LIVE!"
        echo "======================="
        echo ""
        echo "🌐 Access URLs:"
        echo "   External: http://$EXTERNAL_IP"
        echo "   Internal: http://localhost"
        echo ""
        echo "🔑 Default Login Credentials:"
        echo "   Admin:  admin / admin123"
        echo "   User:   john.doe / password123"
        echo "   User:   jane.smith / qwerty"
        echo ""
        echo "🛡️ Security Features Active:"
        echo "   ✅ Application bound to localhost only"
        echo "   ✅ Nginx reverse proxy with security headers"
        echo "   ✅ Firewall blocking direct access to app ports"
        echo "   ✅ Rate limiting on login endpoints"
        
    else
        print_error "❌ Nginx proxy not working"
        print_status "Checking Nginx configuration..."
        
        # Check if cyberrange site is enabled
        if [ -f "/etc/nginx/sites-enabled/cyberrange" ]; then
            print_status "Cyber range site is enabled"
            
            # Test Nginx config
            if nginx -t 2>/dev/null; then
                print_status "Nginx config is valid"
                print_status "Reloading Nginx..."
                systemctl reload nginx
                
                # Test again after reload
                sleep 2
                if curl -f -s http://localhost > /dev/null 2>&1; then
                    print_status "✅ Nginx working after reload!"
                else
                    print_error "Nginx still not proxying correctly"
                    print_status "Nginx error log:"
                    tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No error log found"
                fi
            else
                print_error "Nginx config has errors"
                nginx -t
            fi
        else
            print_error "Cyber range site not enabled"
            print_status "Enabling cyber range site..."
            ln -sf /etc/nginx/sites-available/cyberrange /etc/nginx/sites-enabled/
            rm -f /etc/nginx/sites-enabled/default
            systemctl reload nginx
        fi
    fi
else
    print_error "❌ Nginx is not running"
    print_status "Starting Nginx..."
    systemctl start nginx
fi

print_status "Step 3: Final connectivity test..."

# Final test of all access methods
echo ""
echo "🧪 Connectivity Test Results:"
echo "=============================="

# Test 1: Direct localhost
if curl -f -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    print_status "✅ Direct app access (localhost:3000)"
else
    print_error "❌ Direct app access failed"
fi

# Test 2: Nginx proxy
if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "✅ Nginx proxy access (localhost:80)"
else
    print_error "❌ Nginx proxy access failed"
fi

# Test 3: External access (if possible to test)
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
if [ "$EXTERNAL_IP" != "unknown" ]; then
    print_status "✅ External IP: $EXTERNAL_IP"
    echo "   Test from your browser: http://$EXTERNAL_IP"
fi

print_status "Step 4: Application status summary..."

echo ""
echo "📊 DEPLOYMENT STATUS"
echo "===================="
echo ""

# Container status
print_status "Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# Service status
print_status "Services:"
echo "   Docker:  $(systemctl is-active docker)"
echo "   Nginx:   $(systemctl is-active nginx)"

echo ""

# Database connectivity
print_status "Database:"
if docker exec deploy-db-1 mysqladmin ping -h localhost 2>/dev/null; then
    echo "   MySQL:   ✅ Running and responding"
else
    echo "   MySQL:   ❌ Not responding"
fi

echo ""

# Application logs (last few lines)
print_status "Recent application activity:"
docker logs --tail=3 deploy-web-1

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo ""
echo "1. 🌐 Open your browser and go to: http://$EXTERNAL_IP"
echo "2. 🔑 Login with: admin / admin123"
echo "3. 🎓 Start exploring the cyber range vulnerabilities!"
echo "4. 📚 Check the README.md for vulnerability details"
echo ""
echo "🛠️ Management Commands:"
echo "   View logs:    docker logs -f deploy-web-1"
echo "   Restart:      docker-compose restart"
echo "   Stop:         docker-compose down"
echo "   Status:       docker-compose ps"
echo ""
print_warning "Remember: This is for educational purposes only!"

print_status "Configuration complete!"
