#!/bin/bash

# VPS Operator Agent - Intelligent VPS Management & Diagnostics
# Advanced operations, diagnostics, and incident response

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

VPS_HOST="${VPS_HOST:-agennext.com}"
VPS_USER="${VPS_USER:-almalinux}"
VPS_PASSWORD="${VPS_PASSWORD}"
OPERATOR_ID="op-$(date +%s)"
LOG_DIR="/tmp/vps-operator"
REPORT_DIR="${HOME}/.creative-platform/operator-reports"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

LOG_FILE="${LOG_DIR}/operator-${OPERATOR_ID}.log"
REPORT_FILE="${REPORT_DIR}/report-${OPERATOR_ID}.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# UTILITIES
# ============================================================================

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "%b[${timestamp}] [${level}] ${message}%b\n" "${BLUE}" "${NC}" | tee -a "${LOG_FILE}"
}

success() {
    printf "%b✅ %s%b\n" "${GREEN}" "$@" "${NC}" | tee -a "${LOG_FILE}"
}

warning() {
    printf "%b⚠️  %s%b\n" "${YELLOW}" "$@" "${NC}" | tee -a "${LOG_FILE}"
}

error() {
    printf "%b❌ %s%b\n" "${RED}" "$@" "${NC}" | tee -a "${LOG_FILE}"
}

header() {
    echo ""
    printf "%b╔════════════════════════════════════════════════════╗%b\n" "${CYAN}" "${NC}"
    printf "%b║ %s%b\n" "${CYAN}" "$@" "${NC}"
    printf "%b╚════════════════════════════════════════════════════╝%b\n" "${CYAN}" "${NC}"
    echo ""
}

run_on_vps() {
    local cmd=$1
    sshpass -p "${VPS_PASSWORD}" ssh -o StrictHostKeyChecking=no "${VPS_USER}@${VPS_HOST}" "$cmd" 2>&1
}

copy_from_vps() {
    local file=$1
    local dest=$2
    sshpass -p "${VPS_PASSWORD}" scp -o StrictHostKeyChecking=no "${VPS_USER}@${VPS_HOST}:${file}" "${dest}" 2>&1
}

# ============================================================================
# STATUS & DIAGNOSTICS
# ============================================================================

cmd_status() {
    header "VPS Status Report"

    log "INFO" "Gathering system information..."

    local uptime=$(run_on_vps "uptime" | awk -F'up' '{print $2}')
    local load=$(run_on_vps "uptime | awk -F'load average:' '{print \$2}'")
    local cpu=$(run_on_vps "nproc")
    local memory=$(run_on_vps "free -h | grep Mem | awk '{print \$2}'")
    local disk=$(run_on_vps "df -h / | tail -1 | awk '{print \$2}'")
    local disk_used=$(run_on_vps "df -h / | tail -1 | awk '{print \$3}'")
    local disk_percent=$(run_on_vps "df -h / | tail -1 | awk '{print \$5}'")

    echo ""
    printf "%b━━━ SYSTEM STATUS %b\n" "${BLUE}" "${NC}"
    echo "  Uptime: ${uptime}"
    echo "  Load Average: ${load}"
    echo "  CPU Cores: ${cpu}"
    echo "  Memory: ${memory}"
    echo "  Disk Space: ${disk_used}/${disk} (${disk_percent})"
    echo ""

    # Container status
    printf "%b━━━ DOCKER CONTAINERS %b\n" "${BLUE}" "${NC}"
    run_on_vps "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Size}}'" | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""

    # Service status
    printf "%b━━━ SYSTEM SERVICES %b\n" "${BLUE}" "${NC}"
    run_on_vps "sudo systemctl status docker --no-pager" | head -3 | sed 's/^/  /'
    run_on_vps "sudo systemctl status nginx --no-pager" | head -3 | sed 's/^/  /'
    echo ""

    # Network status
    printf "%b━━━ NETWORK STATUS %b\n" "${BLUE}" "${NC}"
    run_on_vps "netstat -tuln | grep LISTEN" | head -5 | sed 's/^/  /'
    echo ""

    success "Status report complete"
}

cmd_diagnostics() {
    header "VPS Diagnostics"

    log "INFO" "Running comprehensive diagnostics..."

    local issues=0

    # Check Docker daemon
    log "INFO" "Checking Docker daemon..."
    if ! run_on_vps "docker ps > /dev/null 2>&1"; then
        error "Docker daemon not responding"
        ((issues++))
    else
        success "Docker daemon healthy"
    fi

    # Check disk space
    log "INFO" "Checking disk space..."
    local disk_used=$(run_on_vps "df / | tail -1 | awk '{print \$5}' | sed 's/%//'")
    if [ "$disk_used" -gt 80 ]; then
        error "Disk space critical: ${disk_used}%"
        ((issues++))
    elif [ "$disk_used" -gt 60 ]; then
        warning "Disk space warning: ${disk_used}%"
    else
        success "Disk space OK: ${disk_used}%"
    fi

    # Check memory
    log "INFO" "Checking memory..."
    local mem_used=$(run_on_vps "free | grep Mem | awk '{printf(\"%.0f\", \$3/\$2 * 100)}'")
    if [ "$mem_used" -gt 85 ]; then
        error "Memory critical: ${mem_used}%"
        ((issues++))
    elif [ "$mem_used" -gt 70 ]; then
        warning "Memory warning: ${mem_used}%"
    else
        success "Memory OK: ${mem_used}%"
    fi

    # Check containers
    log "INFO" "Checking containers..."
    local container_count=$(run_on_vps "docker ps -q | wc -l")
    if [ "$container_count" -lt 5 ]; then
        error "Expected 5 containers, found $container_count"
        ((issues++))
    else
        success "All containers running ($container_count)"
    fi

    # Check API health
    log "INFO" "Checking API health..."
    local api_status=$(run_on_vps "curl -s -o /dev/null -w '%{http_code}' http://localhost:3001/health" 2>/dev/null || echo "000")
    if [ "$api_status" != "200" ]; then
        error "API unhealthy (HTTP $api_status)"
        ((issues++))
    else
        success "API healthy (HTTP 200)"
    fi

    # Check database
    log "INFO" "Checking database..."
    if ! run_on_vps "docker exec postgres pg_isready -U postgres" | grep -q "accepting"; then
        error "Database not accepting connections"
        ((issues++))
    else
        success "Database healthy"
    fi

    # Check Redis
    log "INFO" "Checking Redis..."
    if ! run_on_vps "docker exec redis redis-cli ping" | grep -q "PONG"; then
        error "Redis not responding"
        ((issues++))
    else
        success "Redis healthy"
    fi

    echo ""
    printf "%b━━━ DIAGNOSTICS SUMMARY %b\n" "${BLUE}" "${NC}"
    if [ $issues -eq 0 ]; then
        success "All systems operational!"
    else
        error "Found $issues issue(s)"
    fi
    echo ""
}

# ============================================================================
# PERFORMANCE ANALYSIS
# ============================================================================

cmd_performance() {
    header "Performance Analysis"

    log "INFO" "Analyzing system performance..."

    echo ""
    printf "%b━━━ CPU PERFORMANCE %b\n" "${BLUE}" "${NC}"
    run_on_vps "top -bn1 | head -10" | sed 's/^/  /'
    echo ""

    printf "%b━━━ MEMORY BREAKDOWN %b\n" "${BLUE}" "${NC}"
    run_on_vps "free -h" | sed 's/^/  /'
    echo ""

    printf "%b━━━ DISK I/O %b\n" "${BLUE}" "${NC}"
    run_on_vps "iostat -x 1 2 | tail -5" | sed 's/^/  /'
    echo ""

    printf "%b━━━ DOCKER STATS %b\n" "${BLUE}" "${NC}"
    run_on_vps "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}'" | sed 's/^/  /'
    echo ""

    printf "%b━━━ NETWORK STATS %b\n" "${BLUE}" "${NC}"
    run_on_vps "ss -s" | sed 's/^/  /'
    echo ""

    success "Performance analysis complete"
}

# ============================================================================
# LOG ANALYSIS
# ============================================================================

cmd_logs() {
    local container=${1:-api}

    header "Logs for Container: $container"

    log "INFO" "Fetching logs from $container (last 50 lines)..."

    echo ""
    printf "%b━━━ RECENT LOGS %b\n" "${BLUE}" "${NC}"
    run_on_vps "docker logs --tail 50 $container" | sed 's/^/  /'
    echo ""

    # Analyze for errors
    printf "%b━━━ ERROR ANALYSIS %b\n" "${BLUE}" "${NC}"
    local error_count=$(run_on_vps "docker logs $container | grep -i error | wc -l")
    if [ "$error_count" -gt 0 ]; then
        warning "Found $error_count error(s)"
        run_on_vps "docker logs $container | grep -i error | tail -5" | sed 's/^/  /'
    else
        success "No errors found"
    fi
    echo ""
}

# ============================================================================
# INCIDENT RESPONSE
# ============================================================================

cmd_restart_service() {
    local service=${1:-api}

    header "Restarting Service: $service"

    log "INFO" "Stopping $service..."
    run_on_vps "docker stop $service" > /dev/null
    success "Stopped"

    log "INFO" "Waiting..."
    sleep 3

    log "INFO" "Starting $service..."
    run_on_vps "docker start $service" > /dev/null
    success "Started"

    log "INFO" "Verifying..."
    sleep 5

    if run_on_vps "docker ps --format '{{.Names}}' | grep -q '^${service}\$'" 2>/dev/null; then
        success "$service is running"
    else
        error "$service failed to start"
    fi
    echo ""
}

cmd_restart_all() {
    header "Restarting All Services"

    for service in postgres redis liferay api; do
        log "INFO" "Restarting $service..."
        run_on_vps "docker restart $service" > /dev/null
        success "$service restarted"
    done

    log "INFO" "Waiting for services to initialize..."
    sleep 10

    log "INFO" "Verifying all services..."
    run_on_vps "docker ps --format 'table {{.Names}}\t{{.Status}}'" | while IFS= read -r line; do
        echo "  $line"
    done

    echo ""
    success "All services restarted"
}

cmd_clean_logs() {
    header "Cleaning Logs"

    log "INFO" "Cleaning Docker logs..."

    run_on_vps "
        for container in \$(docker ps -q); do
            docker exec \$container find /var/log -type f -name '*.log' -delete 2>/dev/null || true
        done
    "

    success "Logs cleaned"
    echo ""
}

cmd_cleanup_disk() {
    header "Disk Cleanup"

    log "INFO" "Removing unused Docker images..."
    run_on_vps "docker image prune -f" | sed 's/^/  /'

    log "INFO" "Removing unused Docker volumes..."
    run_on_vps "docker volume prune -f" | sed 's/^/  /'

    log "INFO" "Removing unused Docker networks..."
    run_on_vps "docker network prune -f" | sed 's/^/  /'

    log "INFO" "Removing dangling containers..."
    run_on_vps "docker container prune -f" | sed 's/^/  /'

    echo ""
    success "Disk cleanup complete"
}

# ============================================================================
# DEPLOYMENT OPERATIONS
# ============================================================================

cmd_deploy_api() {
    header "Deploy New API Version"

    log "INFO" "Pulling latest Docker image..."
    run_on_vps "docker pull ghcr.io/fractional-pm/creative-platform-api:latest"

    log "INFO" "Stopping old API..."
    run_on_vps "docker stop api 2>/dev/null || true"
    run_on_vps "docker rm api 2>/dev/null || true"

    log "INFO" "Starting new API..."
    run_on_vps "
        docker run -d \
          --name api \
          --network creative-network \
          -e DATABASE_URL='postgres://postgres:\$DB_PASSWORD@postgres:5432/creative_platform' \
          -e REDIS_URL='redis://redis:6379' \
          -e JWT_SECRET='\$JWT_SECRET' \
          -e API_LOG_LEVEL='info' \
          -e API_PORT='3001' \
          -p 3001:3001 \
          --restart unless-stopped \
          ghcr.io/fractional-pm/creative-platform-api:latest
    "

    log "INFO" "Waiting for API to start..."
    sleep 5

    log "INFO" "Verifying API..."
    if run_on_vps "curl -f http://localhost:3001/health > /dev/null 2>&1"; then
        success "API deployed and healthy"
    else
        error "API deployment failed"
    fi
    echo ""
}

cmd_rollback() {
    header "Rollback Deployment"

    log "INFO" "Rolling back to previous API version..."
    run_on_vps "docker stop api 2>/dev/null || true"
    run_on_vps "docker rm api 2>/dev/null || true"

    log "INFO" "Starting previous API version..."
    run_on_vps "
        docker run -d \
          --name api \
          --network creative-network \
          -p 3001:3001 \
          --restart unless-stopped \
          ghcr.io/fractional-pm/creative-platform-api:$(git rev-parse HEAD~1 | cut -c1-7) 2>/dev/null || \
        docker run -d \
          --name api \
          --network creative-network \
          -p 3001:3001 \
          --restart unless-stopped \
          ghcr.io/fractional-pm/creative-platform-api:latest
    "

    sleep 5

    if run_on_vps "curl -f http://localhost:3001/health > /dev/null 2>&1"; then
        success "Rollback successful"
    else
        error "Rollback failed"
    fi
    echo ""
}

# ============================================================================
# BACKUP & RECOVERY
# ============================================================================

cmd_backup_database() {
    header "Backup Database"

    local backup_file="${REPORT_DIR}/database-backup-${OPERATOR_ID}.sql"

    log "INFO" "Creating database backup..."
    run_on_vps "docker exec postgres pg_dump -U postgres creative_platform" > "$backup_file"

    local size=$(du -h "$backup_file" | awk '{print $1}')
    success "Database backed up ($size) to $backup_file"
    echo ""
}

cmd_restore_database() {
    local backup_file=${1:-}

    if [ -z "$backup_file" ]; then
        error "Usage: operator restore-database <backup-file>"
        return 1
    fi

    header "Restore Database"

    log "INFO" "Stopping API..."
    run_on_vps "docker stop api"

    log "INFO" "Restoring database from $backup_file..."
    cat "$backup_file" | run_on_vps "docker exec -i postgres psql -U postgres creative_platform"

    log "INFO" "Starting API..."
    run_on_vps "docker start api"

    success "Database restored"
    echo ""
}

# ============================================================================
# SECURITY & CERTIFICATES
# ============================================================================

cmd_check_ssl() {
    header "SSL Certificate Check"

    log "INFO" "Checking SSL certificate..."

    local expiry=$(run_on_vps "openssl x509 -enddate -noout -in /etc/letsencrypt/live/agennext.com/fullchain.pem 2>/dev/null | cut -d= -f2")
    local expiry_epoch=$(date -d "$expiry" +%s)
    local now_epoch=$(date +%s)
    local days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

    echo ""
    printf "%b━━━ CERTIFICATE INFO %b\n" "${BLUE}" "${NC}"
    echo "  Expiry Date: $expiry"
    echo "  Days Until Expiry: $days_left"
    echo ""

    if [ "$days_left" -lt 0 ]; then
        error "Certificate EXPIRED!"
    elif [ "$days_left" -lt 7 ]; then
        warning "Certificate expiring soon!"
        log "INFO" "Running renewal..."
        run_on_vps "sudo certbot renew"
    else
        success "Certificate valid ($days_left days remaining)"
    fi
    echo ""
}

cmd_renew_ssl() {
    header "Renew SSL Certificate"

    log "INFO" "Renewing SSL certificate..."
    run_on_vps "sudo certbot renew --force-renewal"

    log "INFO" "Reloading Nginx..."
    run_on_vps "sudo systemctl reload nginx"

    success "SSL certificate renewed"
    echo ""
}

# ============================================================================
# MONITORING SETUP
# ============================================================================

cmd_install_monitoring() {
    header "Install VPS Monitoring"

    log "INFO" "Copying monitoring agent to VPS..."
    sshpass -p "${VPS_PASSWORD}" scp -o StrictHostKeyChecking=no \
        deploy/vps-monitoring-agent.sh \
        "${VPS_USER}@${VPS_HOST}:~/vps-monitoring-agent.sh"

    log "INFO" "Installing monitoring service..."
    run_on_vps "chmod +x ~/vps-monitoring-agent.sh && bash ~/vps-monitoring-agent.sh setup"

    success "Monitoring installed and started"
    echo ""
}

# ============================================================================
# REPORTING
# ============================================================================

cmd_generate_report() {
    header "Generate VPS Report"

    log "INFO" "Generating comprehensive VPS report..."

    cat > "$REPORT_FILE" <<EOF
{
  "operator_id": "${OPERATOR_ID}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "vps_host": "${VPS_HOST}",
  "report_type": "comprehensive",
  "diagnostics": {
    "uptime": "$(run_on_vps 'uptime')",
    "load_average": "$(run_on_vps "uptime | awk -F'load average:' '{print \$2}'")",
    "disk_usage": "$(run_on_vps "df -h / | tail -1 | awk '{print \$5}'")",
    "memory_usage": "$(run_on_vps "free | grep Mem | awk '{printf(\"%.0f%%\", \$3/\$2 * 100)}')"
  },
  "containers": $(run_on_vps "docker ps --format json"),
  "services": {
    "docker": "$(run_on_vps 'sudo systemctl is-active docker' || echo 'error')",
    "nginx": "$(run_on_vps 'sudo systemctl is-active nginx' || echo 'error')"
  }
}
EOF

    success "Report generated: $REPORT_FILE"
    echo ""
}

# ============================================================================
# HELP & USAGE
# ============================================================================

show_help() {
    cat <<EOF

${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}
${CYAN}║           VPS OPERATOR AGENT - Management & Diagnostics            ║${NC}
${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}

${BLUE}OPERATIONS:${NC}

  Status & Diagnostics:
    status              Show current VPS status
    diagnostics         Run comprehensive diagnostics
    performance         Analyze performance metrics
    logs [container]    View container logs (default: api)

  Service Management:
    restart [service]   Restart a service (api, postgres, redis, liferay)
    restart-all         Restart all services
    deploy-api          Deploy new API version
    rollback            Rollback to previous version

  Maintenance:
    clean-logs          Clean container logs
    cleanup-disk        Remove unused Docker objects
    install-monitoring  Install monitoring agent

  SSL/TLS:
    check-ssl           Check SSL certificate status
    renew-ssl           Force SSL certificate renewal

  Backup & Recovery:
    backup-database     Backup PostgreSQL database
    restore-database    Restore from backup

  Reporting:
    report              Generate comprehensive report
    help                Show this help message

${BLUE}EXAMPLES:${NC}

  # Check system status
  $0 status

  # Run full diagnostics
  $0 diagnostics

  # Restart API service
  $0 restart api

  # View API logs
  $0 logs api

  # Backup database
  $0 backup-database

  # Generate report
  $0 report

${BLUE}ENVIRONMENT VARIABLES:${NC}

  VPS_HOST            VPS hostname (default: agennext.com)
  VPS_USER            VPS username (default: almalinux)
  VPS_PASSWORD        VPS password (required)
  SLACK_WEBHOOK       Slack webhook for alerts (optional)

EOF
}

# ============================================================================
# MAIN CLI
# ============================================================================

main() {
    if [ -z "$VPS_PASSWORD" ]; then
        error "VPS_PASSWORD not set"
        exit 1
    fi

    case "${1:-help}" in
        status)              cmd_status ;;
        diagnostics)         cmd_diagnostics ;;
        performance)         cmd_performance ;;
        logs)                cmd_logs "$2" ;;
        restart)             cmd_restart_service "$2" ;;
        restart-all)         cmd_restart_all ;;
        deploy-api)          cmd_deploy_api ;;
        rollback)            cmd_rollback ;;
        clean-logs)          cmd_clean_logs ;;
        cleanup-disk)        cmd_cleanup_disk ;;
        check-ssl)           cmd_check_ssl ;;
        renew-ssl)           cmd_renew_ssl ;;
        backup-database)     cmd_backup_database ;;
        restore-database)    cmd_restore_database "$2" ;;
        install-monitoring)  cmd_install_monitoring ;;
        report)              cmd_generate_report ;;
        help)                show_help ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
