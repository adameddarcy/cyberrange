# Deployment Options for W Corp Cyber Range

This directory contains deployment configurations and scripts for securely deploying the W Corp Cyber Range to various cloud platforms.

## 🔒 Security First

**CRITICAL:** This application contains intentional vulnerabilities for educational purposes. Never deploy directly to the public internet without proper security measures.

## 📁 Files in this Directory

- `docker-compose.prod.yml` - Production Docker Compose configuration
- `deploy-digitalocean.sh` - Automated DigitalOcean deployment script
- `aws-ecs-task-definition.json` - AWS ECS Fargate task definition
- `deployment-guide.md` - Comprehensive deployment guide (in parent directory)

## 🚀 Quick Start Options

### Option 1: DigitalOcean Droplet (Recommended for Small Teams)

1. Create a new DigitalOcean droplet (Ubuntu 22.04, minimum 2GB RAM)
2. SSH into your droplet
3. Upload and run the deployment script:

```bash
# Upload the script
scp deploy-digitalocean.sh root@your-droplet-ip:~/

# SSH into droplet and run
ssh root@your-droplet-ip
chmod +x deploy-digitalocean.sh
./deploy-digitalocean.sh
```

**Cost:** ~$12-24/month  
**Setup Time:** ~15 minutes  
**Supports:** 5-20 concurrent users

### Option 2: AWS ECS Fargate (Scalable)

1. Build and push Docker image to ECR
2. Create RDS MySQL instance (in private subnet)
3. Update task definition with your values
4. Deploy using ECS service

**Cost:** Variable (~$20-100/month)  
**Setup Time:** ~45 minutes  
**Supports:** 20+ concurrent users

### Option 3: Local Network Deployment

For internal training within your organization:

```bash
# Use production compose file
cd deploy/
docker-compose -f docker-compose.prod.yml up -d
```

Then configure your firewall to only allow access from your internal network.

## 🛡️ Security Features Included

### Network Security
- Application bound to localhost only
- Firewall rules block direct access
- Nginx reverse proxy with rate limiting
- Private Docker networks

### Application Security
- Secure random passwords generated
- Environment variables for secrets
- Security headers configured
- Log rotation enabled

### Monitoring & Management
- Health checks configured
- Systemd service for auto-restart
- Management scripts included
- Backup procedures documented

## 🔧 Post-Deployment Configuration

### 1. SSL/TLS Setup (Recommended)

```bash
# Install Certbot for Let's Encrypt
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. VPN Setup for Maximum Security

For the most secure deployment, set up a VPN server:

```bash
# Install WireGuard
sudo apt install wireguard

# Generate server configuration
# (See deployment-guide.md for complete setup)
```

### 3. Monitoring Setup

```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor application
/opt/cyberrange/manage.sh logs
/opt/cyberrange/manage.sh status
```

## 📊 Resource Requirements

### Minimum Requirements
- **CPU:** 2 cores
- **RAM:** 2GB
- **Storage:** 20GB SSD
- **Network:** 1Gbps

### Recommended for 20+ Users
- **CPU:** 4 cores
- **RAM:** 4GB
- **Storage:** 40GB SSD
- **Network:** 1Gbps

## 🚨 Emergency Procedures

### Immediate Shutdown
```bash
# Stop all services
/opt/cyberrange/manage.sh stop

# Or via systemd
sudo systemctl stop cyberrange
```

### Complete Removal
```bash
# Stop and remove everything
cd /opt/cyberrange/deploy
docker-compose -f docker-compose.prod.yml down -v
docker system prune -af

# Remove application
sudo rm -rf /opt/cyberrange
sudo systemctl disable cyberrange
sudo rm /etc/systemd/system/cyberrange.service
```

## 📞 Support

### Health Checks
```bash
# Check application status
curl -f http://localhost/health

# Check container status
/opt/cyberrange/manage.sh status

# View logs
/opt/cyberrange/manage.sh logs
```

### Common Issues

1. **Application won't start**
   - Check Docker service: `sudo systemctl status docker`
   - Check logs: `/opt/cyberrange/manage.sh logs`

2. **Database connection failed**
   - Verify environment variables in `.env.prod`
   - Check database container: `docker ps`

3. **Can't access from browser**
   - Check Nginx status: `sudo systemctl status nginx`
   - Verify firewall: `sudo ufw status`

## 🎯 Training Session Management

### Before Training
```bash
# Start services
/opt/cyberrange/manage.sh start

# Verify everything is working
curl -f http://your-server-ip/
```

### During Training
```bash
# Monitor resource usage
htop

# Watch logs for issues
/opt/cyberrange/manage.sh logs
```

### After Training
```bash
# Create backup
/opt/cyberrange/manage.sh backup

# Optional: Stop services to save resources
/opt/cyberrange/manage.sh stop
```

## 💡 Best Practices

1. **Always use HTTPS in production**
2. **Set up automated backups**
3. **Monitor resource usage**
4. **Keep Docker images updated**
5. **Review logs regularly**
6. **Test disaster recovery procedures**

## 🔗 Additional Resources

- [DigitalOcean Docker Droplet Guide](https://docs.digitalocean.com/products/droplets/how-to/create/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Docker Compose Production Guide](https://docs.docker.com/compose/production/)
- [Nginx Security Configuration](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)

Remember: This is for educational purposes only. Always prioritize security!
