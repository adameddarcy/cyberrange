#!/bin/bash

# W Corp Cyber Range - DigitalOcean Deployment Script
# This script sets up a secure deployment on a DigitalOcean droplet

set -e  # Exit on any error

echo "🚀 Starting W Corp Cyber Range deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "Docker installed successfully"
else
    print_status "Docker already installed"
fi

print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed successfully"
else
    print_status "Docker Compose already installed"
fi

print_status "Installing additional tools..."
sudo apt install -y ufw nginx git htop

print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80   # HTTP for nginx
sudo ufw allow 443  # HTTPS for nginx

# IMPORTANT: Only allow private network access to the application
print_warning "Configuring firewall to BLOCK public access to application ports"
sudo ufw deny 3000  # Block direct access to application
sudo ufw deny 3306  # Block direct access to database

print_status "Creating application directory..."
sudo mkdir -p /opt/cyberrange
sudo chown $USER:$USER /opt/cyberrange

# Check if repository already exists
if [ -d "/opt/cyberrange/.git" ]; then
    print_status "Updating existing repository..."
    cd /opt/cyberrange
    git pull
else
    print_status "Cloning repository..."
    # Note: Replace with your actual repository URL
    read -p "Enter your repository URL: " REPO_URL
    git clone "$REPO_URL" /opt/cyberrange
    cd /opt/cyberrange
fi

print_status "Setting up environment variables..."
if [ ! -f "/opt/cyberrange/.env.prod" ]; then
    cat > /opt/cyberrange/.env.prod << EOF
# Production Environment Variables
NODE_ENV=production
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
EOF
    print_status "Created .env.prod with secure random passwords"
    print_warning "IMPORTANT: Save these passwords securely!"
    cat /opt/cyberrange/.env.prod
else
    print_status "Using existing .env.prod file"
fi

print_status "Configuring Nginx reverse proxy..."
sudo tee /etc/nginx/sites-available/cyberrange > /dev/null << EOF
server {
    listen 80;
    server_name _;  # Replace with your domain
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;
    
    location / {
        # Apply rate limiting to login endpoints
        location ~* /(login|register) {
            limit_req zone=login burst=3 nodelay;
        }
        
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
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
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/cyberrange /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

print_status "Creating systemd service for auto-start..."
sudo tee /etc/systemd/system/cyberrange.service > /dev/null << EOF
[Unit]
Description=W Corp Cyber Range
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/cyberrange/deploy
ExecStart=/usr/local/bin/docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose --env-file ../.env.prod -f docker-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cyberrange

print_status "Building and starting the application..."
cd /opt/cyberrange/deploy
docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d --build

print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/cyberrange > /dev/null << EOF
/opt/cyberrange/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
EOF

print_status "Creating management scripts..."
cat > /opt/cyberrange/manage.sh << 'EOF'
#!/bin/bash
# Cyber Range Management Script

case "$1" in
    start)
        echo "Starting Cyber Range..."
        cd /opt/cyberrange/deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml up -d
        ;;
    stop)
        echo "Stopping Cyber Range..."
        cd /opt/cyberrange/deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml down
        ;;
    restart)
        echo "Restarting Cyber Range..."
        cd /opt/cyberrange/deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml restart
        ;;
    logs)
        cd /opt/cyberrange/deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml logs -f
        ;;
    status)
        cd /opt/cyberrange/deploy
        docker-compose --env-file ../.env.prod -f docker-compose.prod.yml ps
        ;;
    backup)
        echo "Creating database backup..."
        docker exec cyberrange-db-1 mysqldump -u root -p\$MYSQL_ROOT_PASSWORD wcorp_db > /opt/cyberrange/backup-$(date +%Y%m%d-%H%M%S).sql
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|backup}"
        exit 1
        ;;
esac
EOF

chmod +x /opt/cyberrange/manage.sh

print_status "Deployment completed successfully! 🎉"
echo ""
print_warning "IMPORTANT SECURITY NOTES:"
echo "1. The application is only accessible via Nginx reverse proxy (port 80)"
echo "2. Direct access to ports 3000 and 3306 is blocked by firewall"
echo "3. Secure passwords have been generated in .env.prod"
echo "4. Consider setting up SSL/TLS certificates for HTTPS"
echo ""
print_status "Management commands:"
echo "  Start:   /opt/cyberrange/manage.sh start"
echo "  Stop:    /opt/cyberrange/manage.sh stop"
echo "  Status:  /opt/cyberrange/manage.sh status"
echo "  Logs:    /opt/cyberrange/manage.sh logs"
echo "  Backup:  /opt/cyberrange/manage.sh backup"
echo ""
print_status "Application should be available at: http://$(curl -s ifconfig.me)"
echo ""
print_warning "Remember: This is for training purposes only. Never expose to untrusted networks!"
