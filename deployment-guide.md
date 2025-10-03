# Secure Deployment Guide for W Corp Cyber Range

## 🔒 Security-First Deployment Strategy

### Option 1: VPN-Protected Deployment (Recommended)

#### Step 1: Set up VPN Server
```bash
# Install WireGuard or OpenVPN on your cloud server
# Example with WireGuard on Ubuntu:
sudo apt update
sudo apt install wireguard

# Generate server keys
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey

# Configure WireGuard server
sudo nano /etc/wireguard/wg0.conf
```

#### Step 2: Deploy Application Behind VPN
```bash
# Clone repository on server
git clone <your-repo> /opt/cyberrange
cd /opt/cyberrange

# Modify docker-compose for production
cp docker-compose.yml docker-compose.prod.yml

# Edit to bind only to localhost or VPN interface
# Change ports from "3000:3000" to "127.0.0.1:3000:3000"
```

#### Step 3: Nginx Reverse Proxy (Optional)
```nginx
# /etc/nginx/sites-available/cyberrange
server {
    listen 80;
    server_name cyberrange.internal;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Option 2: Isolated Cloud Environment

#### AWS Setup Example
```bash
# Create isolated VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Create private subnet
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.1.0/24

# Deploy using ECS with private networking
# Only accessible via VPN or bastion host
```

### Option 3: Temporary Training Sessions

#### Spin Up for Training Only
```bash
# Start for training session
docker-compose up -d

# Stop immediately after training
docker-compose down

# Use cloud instance scheduling to auto-start/stop
```

## 🚀 Quick Deployment Scripts

### DigitalOcean Droplet Setup
```bash
#!/bin/bash
# deploy-to-digitalocean.sh

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone and deploy
git clone <your-repo> /opt/cyberrange
cd /opt/cyberrange

# Configure firewall (IMPORTANT!)
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow from 10.0.0.0/8 to any port 3000  # Only allow private networks
sudo ufw deny 3000  # Deny public access

# Start application
docker-compose up -d
```

### AWS ECS Deployment
```yaml
# ecs-task-definition.json
{
  "family": "cyberrange",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "cyberrange-web",
      "image": "your-registry/cyberrange:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true
    }
  ]
}
```

## 🔧 Production Modifications Needed

### 1. Environment Variables
```bash
# Create production .env file
NODE_ENV=production
DB_HOST=your-db-host
DB_USER=secure_user
DB_PASSWORD=strong_password_here
JWT_SECRET=very_long_random_secret_key
```

### 2. Database Security
```sql
-- Create read-only training user
CREATE USER 'training_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT ON wcorp_db.* TO 'training_user'@'%';

-- Backup original data
mysqldump -u root -p wcorp_db > backup.sql
```

### 3. Network Security
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "127.0.0.1:3000:3000"  # Bind only to localhost
    networks:
      - internal
  db:
    image: mysql:8.0
    ports:
      - "127.0.0.1:3306:3306"  # Bind only to localhost
    networks:
      - internal

networks:
  internal:
    driver: bridge
    internal: true  # No external access
```

## 📋 Pre-Deployment Checklist

- [ ] VPN server configured and tested
- [ ] Firewall rules properly configured
- [ ] Database credentials changed from defaults
- [ ] Application bound to private interfaces only
- [ ] Monitoring and logging configured
- [ ] Backup and restore procedures tested
- [ ] Training participants have VPN access
- [ ] Emergency shutdown procedures documented

## 🚨 Emergency Procedures

### Immediate Shutdown
```bash
# Stop all services immediately
docker-compose down

# Remove all containers and data
docker-compose down -v
docker system prune -af
```

### Security Incident Response
1. Immediately stop all services
2. Preserve logs for analysis
3. Notify participants of incident
4. Review access logs
5. Rebuild environment from scratch

## 📞 Support and Monitoring

### Health Checks
```bash
# Check application status
curl -f http://localhost:3000/health || echo "Application down"

# Check database connectivity
docker exec cyberrange-db-1 mysqladmin ping -h localhost
```

### Log Monitoring
```bash
# Monitor application logs
docker-compose logs -f web

# Monitor database logs
docker-compose logs -f db
```

## 💡 Training Session Best Practices

1. **Pre-Session Setup**
   - Start services 15 minutes before training
   - Test all functionality
   - Verify VPN connectivity

2. **During Session**
   - Monitor resource usage
   - Watch for unusual activity
   - Keep emergency shutdown ready

3. **Post-Session Cleanup**
   - Stop all services
   - Clear any uploaded files
   - Reset database to clean state
   - Review logs for issues

## 🔗 Recommended Hosting Providers

### For Small Teams (5-20 users)
- **DigitalOcean**: $10-20/month
- **Linode**: $10-15/month
- **Vultr**: $6-12/month

### For Larger Organizations (20+ users)
- **AWS**: Variable pricing, better scaling
- **Google Cloud**: Good container support
- **Azure**: Enterprise features

### For Educational Institutions
- **AWS Educate**: Free credits available
- **Google Cloud for Education**: Educational discounts
- **Microsoft Azure for Students**: Free tier available

Remember: The key is isolation and controlled access. Never expose this directly to the public internet!
