# Deployment Guide - Universal Creative Platform

**Target:** AlmaLinux VPS (agennext.com)  
**Method:** Docker Compose with SSL/TLS  
**Estimated Time:** 30-45 minutes

---

## 📋 Prerequisites

- [ ] VPS with AlmaLinux 9.x
- [ ] SSH access: `almalinux@agennext.com`
- [ ] Domain pointing to VPS IP
- [ ] 2GB+ RAM, 20GB+ disk space

---

## 🚀 Deployment Steps

### Step 1: SSH into VPS

```bash
ssh almalinux@agennext.com
```

### Step 2: Run VPS Setup Script

```bash
# Download and run setup script
curl -fsSL https://raw.githubusercontent.com/fractional-pm/creative-platform/main/deploy/setup-vps.sh | bash

# Verify installations
docker --version
docker-compose --version
```

### Step 3: Clone Repository

```bash
cd /home/almalinux
git clone https://github.com/YOUR_USERNAME/creative-platform.git
cd creative-platform
```

### Step 4: Configure Environment

```bash
# Copy production environment file
cp deploy/.env.production .env

# Edit configuration (IMPORTANT!)
nano .env

# Change these values:
# - POSTGRES_PASSWORD (strong password)
# - JWT_SECRET (long random string)
# - REDIS_PASSWORD (strong password)
# - GRAFANA_ADMIN_PASSWORD (admin password)
# - API_DOMAIN (your domain)
```

### Step 5: Setup SSL Certificate

#### Option A: Using Certbot (Recommended)

```bash
# Install certbot
sudo dnf install -y certbot python3-certbot-nginx

# Request certificate
sudo certbot certonly --standalone \
  -d api.agennext.com \
  -d grafana.agennext.com \
  -d prometheus.agennext.com

# Note the certificate path from output
# Usually: /etc/letsencrypt/live/api.agennext.com/
```

#### Option B: Using Self-Signed (Dev Only)

```bash
mkdir -p deploy/ssl
cd deploy/ssl

openssl req -x509 -newkey rsa:4096 -keyout privkey.pem -out fullchain.pem -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Org/CN=api.agennext.com"

cd ../..
```

### Step 6: Start Services

```bash
# Use production compose file
docker-compose -f docker-compose.yml -f deploy/docker-compose.production.yml up -d

# Monitor startup
docker-compose logs -f api

# Wait for health check to pass (40+ seconds)
```

### Step 7: Verify Deployment

```bash
# Check all services running
docker-compose ps

# Test health endpoint
curl http://localhost:3001/health

# View logs
docker-compose logs api
docker-compose logs postgres
```

### Step 8: Setup Monitoring

```bash
# Access Grafana
# URL: http://agennext.com:3000 (or https://grafana.agennext.com after SSL)
# Username: admin
# Password: (from .env GRAFANA_ADMIN_PASSWORD)

# Add Prometheus as data source
# URL: http://prometheus:9090
```

### Step 9: Create Database Backups Directory

```bash
mkdir -p deploy/backups
chmod 755 deploy/backups

# Test backup
docker-compose exec postgres pg_dump -U creative_platform creative_platform > deploy/backups/backup-$(date +%Y%m%d).sql
```

### Step 10: Setup Cron for Automated Backups

```bash
# Edit crontab
crontab -e

# Add this line (backup daily at 2 AM)
0 2 * * * cd /home/almalinux/creative-platform && docker-compose exec -T postgres pg_dump -U creative_platform creative_platform > deploy/backups/backup-$(date +\%Y\%m\%d-\%H\%M\%S).sql
```

---

## 📊 Post-Deployment

### Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **API** | https://api.agennext.com | Bearer token (JWT) |
| **Grafana** | https://grafana.agennext.com | admin / (password from .env) |
| **Prometheus** | https://prometheus.agennext.com | N/A |
| **Health Check** | https://api.agennext.com/health | Public |

### Test API

```bash
# Health check
curl https://api.agennext.com/health

# List organizations (requires auth token)
curl -X GET https://api.agennext.com/api/v1/organizations \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Monitor Logs

```bash
# Real-time API logs
docker-compose logs -f api

# Database logs
docker-compose logs -f postgres

# All logs
docker-compose logs -f
```

---

## 🔒 Security Checklist

- [ ] Change all default passwords in `.env`
- [ ] SSL certificate installed and auto-renewing
- [ ] Firewall configured (allow only 80, 443, SSH)
- [ ] SSH key-based authentication enabled
- [ ] Regular backups scheduled
- [ ] Monitoring alerts configured
- [ ] Rate limiting enabled in nginx
- [ ] CORS properly configured
- [ ] Secrets not in version control

### Firewall Setup (firewalld)

```bash
# Enable firewall
sudo systemctl enable firewalld
sudo systemctl start firewalld

# Allow ports
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=5432/tcp  # If external DB access needed
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-all
```

---

## 🔄 Updating Deployment

### Pull Latest Code

```bash
cd /home/almalinux/creative-platform
git pull origin main
```

### Rebuild Docker Image

```bash
docker-compose build --no-cache api
docker-compose up -d api
```

### Rolling Update (Zero Downtime)

```bash
# Scale to 2 instances
docker-compose up -d --scale api=2

# Verify both running
docker-compose ps

# Remove old instance
docker-compose down
docker-compose up -d
```

---

## 🚨 Troubleshooting

### Database Connection Error

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Verify DATABASE_URL in .env
cat .env | grep DATABASE_URL

# Test connection
docker-compose exec postgres psql -U creative_platform -d creative_platform -c "SELECT 1"
```

### API Not Starting

```bash
# Check logs
docker-compose logs api

# Verify port not in use
sudo lsof -i :3001

# Rebuild
docker-compose build --no-cache api
docker-compose up -d api
```

### Certificate Issues

```bash
# Check certificate
sudo certbot certificates

# Renew certificate
sudo certbot renew --dry-run

# Update nginx
sudo nginx -t
sudo systemctl reload nginx
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Cleanup old logs
docker system prune -a

# Remove old backups
rm deploy/backups/backup-*.sql  # Keep recent ones!
```

---

## 📈 Performance Tuning

### Database Connection Pool

```bash
# In .env
DATABASE_POOL_SIZE=25
DATABASE_POOL_TIMEOUT=5000
```

### Redis Optimization

```bash
# Update docker-compose for better performance
redis-cli CONFIG SET maxmemory 512mb
redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### Prometheus Retention

```bash
# Keep metrics for 30 days
# Already configured in docker-compose.production.yml
```

---

## 🔍 Monitoring Commands

```bash
# Check CPU/Memory usage
docker stats

# View container processes
docker-compose top api

# Check disk usage
du -sh creative-platform/*

# Database size
docker-compose exec postgres psql -U creative_platform -d creative_platform -c "SELECT pg_size_pretty(pg_database_size('creative_platform'))"

# Backup size
du -sh deploy/backups/

# Connection count
docker-compose exec postgres psql -U creative_platform -d creative_platform -c "SELECT usename, count(*) FROM pg_stat_activity GROUP BY usename"
```

---

## 📞 Support & Debugging

### Enable Debug Logging

```bash
# In .env, set
API_LOG_LEVEL=debug

# Restart API
docker-compose restart api
```

### Access Database Directly

```bash
docker-compose exec postgres psql -U creative_platform -d creative_platform

# Once in psql
\dt                    # List tables
SELECT COUNT(*) FROM content;  # Count records
\q                     # Exit
```

### View Network

```bash
# Check container network
docker network inspect creative-platform_creative-platform

# Test DNS resolution inside containers
docker-compose exec api nslookup postgres
```

---

## ✅ Deployment Checklist

- [ ] VPS SSH access working
- [ ] Docker & Docker Compose installed
- [ ] Repository cloned
- [ ] `.env` configured with production values
- [ ] SSL certificate obtained
- [ ] Services started successfully
- [ ] Health check passing
- [ ] Database tables created
- [ ] Monitoring accessible
- [ ] Backups scheduled
- [ ] Firewall configured
- [ ] DNS pointing to VPS
- [ ] HTTPS working
- [ ] API responding to requests

---

## 🎉 Success!

Your API is now live on **https://api.agennext.com** 🚀

**Next:** 
- Week 2: Monitor for issues, hardening
- Week 3-4: Database optimization & backups
- Week 5+: Continue with roadmap

---

**Deployment Date:** [INSERT DATE]  
**Deployed By:** [INSERT PERSON]  
**Version:** 0.1.0
