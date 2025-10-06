#!/bin/bash

# Fix Nginx configuration for cyber range deployment
# This script fixes the limit_req_zone directive placement issue

set -e

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

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root or with sudo"
   exit 1
fi

print_status "Fixing Nginx configuration for cyber range..."

# 1. Add rate limiting to main nginx.conf
print_status "Adding rate limiting to main nginx configuration..."

# Check if rate limiting is already configured
if ! grep -q "limit_req_zone" /etc/nginx/nginx.conf; then
    # Add rate limiting to http block
    sed -i '/http {/a\\n\t# Rate limiting for cyber range\n\tlimit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;' /etc/nginx/nginx.conf
    print_status "Added rate limiting to nginx.conf"
else
    print_status "Rate limiting already configured in nginx.conf"
fi

# 2. Create corrected site configuration
print_status "Creating corrected site configuration..."

cat > /etc/nginx/sites-available/cyberrange << 'EOF'
server {
    listen 80;
    server_name _;  # Replace with your domain if you have one
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Main location block
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
    
    # Apply rate limiting to login endpoints
    location ~* /(login|register|api/auth) {
        limit_req zone=login burst=3 nodelay;
        
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Block access to sensitive files
    location ~ /\.(env|git) {
        deny all;
        return 404;
    }
    
    # Block access to sensitive paths
    location ~ /(\.git|node_modules|\.env) {
        deny all;
        return 404;
    }
    
    # Optional: Add basic logging
    access_log /var/log/nginx/cyberrange_access.log;
    error_log /var/log/nginx/cyberrange_error.log;
}
EOF

print_status "Created corrected site configuration"

# 3. Enable the site and disable default
print_status "Enabling cyber range site..."

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Enable cyber range site
ln -sf /etc/nginx/sites-available/cyberrange /etc/nginx/sites-enabled/

# 4. Test configuration
print_status "Testing Nginx configuration..."

if nginx -t; then
    print_status "✅ Nginx configuration is valid!"
    
    # Reload nginx
    systemctl reload nginx
    print_status "✅ Nginx reloaded successfully!"
    
    echo ""
    print_status "🎉 Nginx configuration fixed!"
    echo ""
    print_status "Your cyber range should now be accessible at:"
    echo "   http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
    echo ""
    print_warning "Make sure your application is running:"
    echo "   cd /opt/cyberrange && ./manage.sh status"
    echo "   cd /opt/cyberrange && ./manage.sh start  # if not running"
    
else
    print_error "❌ Nginx configuration test failed!"
    print_error "Please check the error messages above"
    exit 1
fi
