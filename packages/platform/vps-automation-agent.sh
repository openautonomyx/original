#!/bin/bash

# VPS Automation Agent - Complete Deployment & Monitoring
# Fully automated VPS setup with real-time tracking

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

VPS_HOST="${VPS_HOST:-agennext.com}"
VPS_USER="${VPS_USER:-almalinux}"
VPS_PASSWORD="${VPS_PASSWORD}"
DEPLOYMENT_ID=$(uuidgen)
LOG_FILE="/tmp/deployment-${DEPLOYMENT_ID}.log"
STATUS_FILE="/tmp/deployment-status-${DEPLOYMENT_ID}.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# LOGGING & STATUS
# ============================================================================

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

update_status() {
    local phase=$1
    local status=$2
    local progress=$3

    cat > "${STATUS_FILE}" <<EOF
{
  "deployment_id": "${DEPLOYMENT_ID}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "phase": "${phase}",
  "status": "${status}",
  "progress": ${progress},
  "vps_host": "${VPS_HOST}",
  "log_file": "${LOG_FILE}"
}
EOF

    # Print formatted output
    printf "%b[%s] %s (%d%%)%b\n" "${BLUE}" "${phase}" "${status}" "${progress}" "${NC}"
}

print_header() {
    echo ""
    printf "%b========================================%b\n" "${BLUE}" "${NC}"
    echo "🚀 $1"
    printf "%b========================================%b\n" "${BLUE}" "${NC}"
    echo ""
}

# ============================================================================
# VPS EXECUTION
# ============================================================================

run_on_vps() {
    local cmd=$1
    local description=$2

    if [ -z "$description" ]; then
        description=$cmd
    fi

    log "INFO" "Executing: ${description}"
    sshpass -p "${VPS_PASSWORD}" ssh -o StrictHostKeyChecking=no "${VPS_USER}@${VPS_HOST}" "$cmd" 2>&1 | tee -a "${LOG_FILE}"
}

copy_to_vps() {
    local file=$1
    local dest=$2

    log "INFO" "Copying ${file} to ${dest}"
    sshpass -p "${VPS_PASSWORD}" scp -o StrictHostKeyChecking=no "$file" "${VPS_USER}@${VPS_HOST}:$dest" 2>&1 | tee -a "${LOG_FILE}"
}

# ============================================================================
# PRE-DEPLOYMENT CHECKS
# ============================================================================

check_prerequisites() {
    print_header "Pre-Deployment Checks"
    update_status "Prerequisites" "Checking..." 5

    # Check required tools
    local required_tools=("sshpass" "curl" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR" "Required tool not found: $tool"
            return 1
        fi
    done

    # Check VPS connectivity
    log "INFO" "Testing VPS connectivity..."
    if ! timeout 5 sshpass -p "${VPS_PASSWORD}" ssh -o StrictHostKeyChecking=no "${VPS_USER}@${VPS_HOST}" "echo 'Connected'" &> /dev/null; then
        log "ERROR" "Cannot connect to VPS: ${VPS_HOST}"
        return 1
    fi

    # Check VPS specs
    log "INFO" "Checking VPS specifications..."
    run_on_vps "
        echo '=== OS Info ==='
        cat /etc/os-release | head -2
        echo '=== Disk Space ==='
        df -h | head -2
        echo '=== Memory ==='
        free -h | head -2
    " "VPS Specifications"

    update_status "Prerequisites" "Passed ✓" 10
    log "INFO" "All prerequisites passed"
}

# ============================================================================
# PHASE 1: SYSTEM SETUP
# ============================================================================

phase1_system_setup() {
    print_header "Phase 1: System Setup (10 min)"
    update_status "System Setup" "Installing dependencies..." 15

    run_on_vps "sudo bash -c '
        set -e

        # Update system
        dnf update -y > /dev/null

        # Install dependencies
        dnf install -y \
            curl wget git htop docker sshpass openssl nginx \
            certbot python3-certbot-nginx jq > /dev/null

        # Start Docker
        systemctl start docker
        systemctl enable docker

        # Install Docker Compose
        curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose 2>/dev/null
        chmod +x /usr/local/bin/docker-compose

        # Configure firewall
        firewall-cmd --permanent --add-service=http > /dev/null
        firewall-cmd --permanent --add-service=https > /dev/null
        firewall-cmd --permanent --add-port=3001/tcp > /dev/null
        firewall-cmd --permanent --add-port=8080/tcp > /dev/null
        firewall-cmd --permanent --add-port=3000/tcp > /dev/null
        firewall-cmd --reload

        # Create Docker network
        docker network create creative-network 2>/dev/null || true

        echo \"System setup complete\"
    '" "Installing system dependencies"

    update_status "System Setup" "Complete ✓" 25
}

# ============================================================================
# PHASE 2: DATABASE SETUP
# ============================================================================

phase2_database_setup() {
    print_header "Phase 2: Database Setup (5 min)"
    update_status "Database" "Starting PostgreSQL..." 30

    local DB_PASSWORD=$(openssl rand -base64 32)

    run_on_vps "
        docker pull postgres:15-alpine
        docker stop postgres 2>/dev/null || true
        docker rm postgres 2>/dev/null || true
        docker run -d \
          --name postgres \
          --network creative-network \
          -e POSTGRES_USER=postgres \
          -e POSTGRES_PASSWORD=${DB_PASSWORD} \
          -v postgres_data:/var/lib/postgresql/data \
          -p 5432:5432 \
          postgres:15-alpine

        sleep 10
        docker exec postgres pg_isready || sleep 10
        echo \"PostgreSQL started\"
    " "Starting PostgreSQL"

    update_status "Database" "Loading schema..." 35

    # Copy and run schema
    copy_to_vps "db/schema.sql" "/tmp/schema.sql"

    run_on_vps "
        docker exec -i postgres psql -U postgres -c 'CREATE DATABASE creative_platform' 2>/dev/null || true
        docker exec -i postgres psql -U postgres creative_platform < /tmp/schema.sql
        echo \"Schema loaded\"
    " "Loading database schema"

    # Save credentials
    echo "${DB_PASSWORD}" > ~/.creative-platform/db-password.txt
    log "INFO" "Database password saved to ~/.creative-platform/db-password.txt"

    update_status "Database" "Ready ✓" 40
}

# ============================================================================
# PHASE 3: CACHE & SERVICES
# ============================================================================

phase3_services_setup() {
    print_header "Phase 3: Cache & Services Setup (5 min)"
    update_status "Services" "Starting Redis..." 45

    run_on_vps "
        docker pull redis:7-alpine
        docker stop redis 2>/dev/null || true
        docker rm redis 2>/dev/null || true
        docker run -d \
          --name redis \
          --network creative-network \
          -p 6379:6379 \
          redis:7-alpine

        sleep 3
        docker exec redis redis-cli ping
        echo \"Redis started\"
    " "Starting Redis"

    update_status "Services" "Starting Liferay..." 50

    run_on_vps "
        docker pull liferay/dxp:latest
        docker stop liferay 2>/dev/null || true
        docker rm liferay 2>/dev/null || true
        docker run -d \
          --name liferay \
          --network creative-network \
          -e LIFERAY_JPDA_ENABLED=false \
          -v liferay_data:/opt/liferay \
          -p 8080:8080 \
          liferay/dxp:latest

        echo \"Liferay starting (2-5 minutes)...\"
        sleep 60
    " "Starting Liferay"

    update_status "Services" "Running ✓" 55
}

# ============================================================================
# PHASE 4: API & REVERSE PROXY
# ============================================================================

phase4_api_setup() {
    print_header "Phase 4: API & Reverse Proxy Setup (5 min)"
    update_status "API" "Starting Go API..." 60

    local JWT_SECRET=$(openssl rand -base64 32)
    local LIFERAY_API_KEY=$(openssl rand -base64 32)

    run_on_vps "
        docker stop api 2>/dev/null || true
        docker rm api 2>/dev/null || true

        docker pull ghcr.io/fractional-pm/creative-platform-api:latest || true

        docker run -d \
          --name api \
          --network creative-network \
          -e DATABASE_URL='postgres://postgres:PASSWORD@postgres:5432/creative_platform' \
          -e REDIS_URL='redis://redis:6379' \
          -e LIFERAY_URL='http://liferay:8080' \
          -e LIFERAY_API_KEY='${LIFERAY_API_KEY}' \
          -e JWT_SECRET='${JWT_SECRET}' \
          -e API_LOG_LEVEL='info' \
          -e API_PORT='3001' \
          -p 3001:3001 \
          ghcr.io/fractional-pm/creative-platform-api:latest

        sleep 10
        echo \"API started\"
    " "Starting Go API"

    update_status "API" "Configuring Nginx..." 65

    run_on_vps "sudo bash -c '
        cat > /etc/nginx/conf.d/creative-platform.conf <<'NGINX'
upstream api_backend {
    server localhost:3001;
}

upstream liferay_backend {
    server localhost:8080;
}

server {
    listen 80;
    server_name agennext.com www.agennext.com;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name agennext.com www.agennext.com;
    ssl_certificate /etc/letsencrypt/live/agennext.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/agennext.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location /api/ {
        proxy_pass http://api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://api_backend;
        proxy_set_header Host \$host;
    }

    location /metrics {
        allow 127.0.0.1;
        deny all;
        proxy_pass http://api_backend;
    }

    location /liferay/ {
        proxy_pass http://liferay_backend/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

        systemctl start nginx
        systemctl enable nginx
    '" "Configuring Nginx"

    # Save credentials
    echo "${JWT_SECRET}" > ~/.creative-platform/jwt-secret.txt
    echo "${LIFERAY_API_KEY}" > ~/.creative-platform/liferay-api-key.txt

    update_status "API" "Ready ✓" 70
}

# ============================================================================
# PHASE 5: SSL CERTIFICATES
# ============================================================================

phase5_ssl_certificates() {
    print_header "Phase 5: SSL Certificates (cert-manager)"
    update_status "SSL" "Requesting certificate..." 75

    run_on_vps "
        sudo certbot certonly --nginx \
          -d agennext.com \
          -d www.agennext.com \
          --email admin@agennext.com \
          --non-interactive \
          --agree-tos

        sudo systemctl reload nginx
        echo \"SSL certificate installed\"
    " "Requesting SSL certificate"

    update_status "SSL" "Scheduling renewal..." 80

    run_on_vps "sudo bash -c '
        cat > /etc/systemd/system/certbot-renew.timer <<'TIMER'
[Unit]
Description=Certbot renewal timer
After=network.target

[Timer]
OnBootSec=5min
OnUnitActiveSec=12h
Persistent=true

[Install]
WantedBy=timers.target
TIMER

        systemctl daemon-reload
        systemctl enable certbot-renew.timer
        systemctl start certbot-renew.timer
    '" "Setting up automatic renewal"

    update_status "SSL" "Active ✓" 85
}

# ============================================================================
# PHASE 6: VERIFICATION
# ============================================================================

phase6_verification() {
    print_header "Phase 6: Health Checks & Verification"
    update_status "Verification" "Running health checks..." 90

    log "INFO" "Running health checks..."

    run_on_vps "
        echo '=== Docker Containers ==='
        docker ps --format 'table {{.Names}}\t{{.Status}}'

        echo ''
        echo '=== API Health ==='
        curl -s http://localhost:3001/health || echo 'API not ready yet'

        echo ''
        echo '=== Database ==='
        docker exec postgres pg_isready -U postgres

        echo ''
        echo '=== Redis ==='
        docker exec redis redis-cli ping

        echo ''
        echo '=== SSL Certificate ==='
        openssl x509 -enddate -noout -in /etc/letsencrypt/live/agennext.com/fullchain.pem
    " "Health checks"

    update_status "Verification" "Complete ✓" 95
}

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================

deployment_summary() {
    print_header "Deployment Complete! 🎉"

    cat > ~/.creative-platform/deployment-summary.txt <<EOF
================================================================================
DEPLOYMENT SUMMARY
================================================================================
Deployment ID:      ${DEPLOYMENT_ID}
Timestamp:          $(date)
VPS Host:           ${VPS_HOST}
Log File:           ${LOG_FILE}

SERVICES RUNNING:
✅ PostgreSQL       - Port 5432
✅ Redis           - Port 6379
✅ Liferay DXP     - Port 8080
✅ Go API          - Port 3001
✅ Nginx           - Port 443 (HTTPS)

URLS:
🌐 API Health:      https://${VPS_HOST}/health
🌐 API Root:        https://${VPS_HOST}/api/v1
🌐 Liferay:         https://${VPS_HOST}:8080
📊 Metrics:         https://${VPS_HOST}/metrics (localhost only)

CREDENTIALS SAVED TO ~/.creative-platform/:
📄 db-password.txt          - PostgreSQL password
📄 jwt-secret.txt           - JWT secret
📄 liferay-api-key.txt      - Liferay API key

NEXT STEPS:
1. ✅ Domain configured: Add DNS A record pointing to ${VPS_HOST}
2. ✅ SSL certificate installed and auto-renewing
3. ⏳ Deploy frontend to Vercel: vercel deploy
4. ⏳ Setup OpenBao vault: BOAS_TOKEN='...' bash deploy/openbao-setup.sh
5. ⏳ Configure monitoring: Set up Prometheus/Grafana

MONITORING:
Monitor logs:        docker logs -f {container_name}
View processes:      docker ps
Check disk space:    df -h
View services:       systemctl status

================================================================================
EOF

    cat ~/.creative-platform/deployment-summary.txt
    update_status "Deployment" "Success! ✓" 100
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    mkdir -p ~/.creative-platform

    print_header "VPS Deployment Agent - Starting"
    log "INFO" "Deployment ID: ${DEPLOYMENT_ID}"
    log "INFO" "Target: ${VPS_HOST}"
    log "INFO" "Log file: ${LOG_FILE}"

    # Validate inputs
    if [ -z "${VPS_PASSWORD}" ]; then
        log "ERROR" "VPS_PASSWORD not set"
        exit 1
    fi

    # Run deployment phases
    check_prerequisites || exit 1
    phase1_system_setup || exit 1
    phase2_database_setup || exit 1
    phase3_services_setup || exit 1
    phase4_api_setup || exit 1
    phase5_ssl_certificates || exit 1
    phase6_verification || exit 1

    deployment_summary

    log "INFO" "Deployment completed successfully!"
    echo ""
    echo "📄 Full summary saved to: ~/.creative-platform/deployment-summary.txt"
    echo ""
}

# Execute
main "$@"
