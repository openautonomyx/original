#!/bin/bash

# VPS Monitoring Agent - Health Check & Auto-Recovery
# Monitors all services and automatically restarts failed ones

set -e

# Configuration
VPS_HOST="${VPS_HOST:-agennext.com}"
VPS_USER="${VPS_USER:-almalinux}"
VPS_PASSWORD="${VPS_PASSWORD}"
MONITOR_INTERVAL=60  # Check every 60 seconds
LOG_FILE="/var/log/creative-platform-monitor.log"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# LOGGING
# ============================================================================

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# ============================================================================
# VPS COMMANDS
# ============================================================================

run_on_vps() {
    local cmd=$1
    sshpass -p "${VPS_PASSWORD}" ssh -o StrictHostKeyChecking=no "${VPS_USER}@${VPS_HOST}" "$cmd" 2>&1
}

# ============================================================================
# HEALTH CHECKS
# ============================================================================

check_docker() {
    log "INFO" "Checking Docker daemon..."
    if ! run_on_vps "sudo systemctl is-active docker" | grep -q "active"; then
        log "ERROR" "Docker is not running"
        run_on_vps "sudo systemctl restart docker"
        log "INFO" "Docker restarted"
        return 1
    fi
    log "INFO" "Docker is healthy ✓"
    return 0
}

check_container() {
    local container=$1
    log "INFO" "Checking container: $container"

    if ! run_on_vps "docker ps --format '{{.Names}}' | grep -q '^${container}\$'" 2>/dev/null; then
        log "ERROR" "Container not running: $container"
        return 1
    fi

    log "INFO" "Container healthy: $container ✓"
    return 0
}

check_postgresql() {
    log "INFO" "Checking PostgreSQL..."

    if ! run_on_vps "docker exec postgres pg_isready -U postgres" | grep -q "accepting"; then
        log "ERROR" "PostgreSQL is not responding"
        run_on_vps "docker restart postgres"
        log "INFO" "PostgreSQL restarted"
        sleep 10
        return 1
    fi

    log "INFO" "PostgreSQL is healthy ✓"
    return 0
}

check_redis() {
    log "INFO" "Checking Redis..."

    if ! run_on_vps "docker exec redis redis-cli ping" | grep -q "PONG"; then
        log "ERROR" "Redis is not responding"
        run_on_vps "docker restart redis"
        log "INFO" "Redis restarted"
        sleep 5
        return 1
    fi

    log "INFO" "Redis is healthy ✓"
    return 0
}

check_api_health() {
    log "INFO" "Checking API health endpoint..."

    local response=$(run_on_vps "curl -s -o /dev/null -w '%{http_code}' http://localhost:3001/health" 2>/dev/null || echo "000")

    if [ "$response" != "200" ]; then
        log "ERROR" "API health check failed (HTTP $response)"
        run_on_vps "docker restart api"
        log "INFO" "API restarted"
        sleep 10
        return 1
    fi

    log "INFO" "API is healthy ✓"
    return 0
}

check_nginx() {
    log "INFO" "Checking Nginx..."

    if ! run_on_vps "sudo systemctl is-active nginx" | grep -q "active"; then
        log "ERROR" "Nginx is not running"
        run_on_vps "sudo systemctl restart nginx"
        log "INFO" "Nginx restarted"
        return 1
    fi

    log "INFO" "Nginx is healthy ✓"
    return 0
}

check_disk_space() {
    log "INFO" "Checking disk space..."

    local usage=$(run_on_vps "df / | tail -1 | awk '{print \$5}' | sed 's/%//'")

    if [ "$usage" -gt 80 ]; then
        log "WARN" "Disk usage is $usage% (>80% threshold)"
        send_alert "Disk space warning: $usage% used on $VPS_HOST"
        return 1
    fi

    log "INFO" "Disk space is healthy ($usage% used) ✓"
    return 0
}

check_memory() {
    log "INFO" "Checking memory usage..."

    local memory=$(run_on_vps "free | grep Mem | awk '{printf(\"%.0f\", \$3/\$2 * 100)}'")

    if [ "$memory" -gt 85 ]; then
        log "WARN" "Memory usage is $memory% (>85% threshold)"
        send_alert "Memory warning: $memory% used on $VPS_HOST"
        return 1
    fi

    log "INFO" "Memory usage is healthy ($memory% used) ✓"
    return 0
}

check_certificate() {
    log "INFO" "Checking SSL certificate expiry..."

    local expiry_date=$(run_on_vps "openssl x509 -enddate -noout -in /etc/letsencrypt/live/agennext.com/fullchain.pem 2>/dev/null | cut -d= -f2")
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local now_epoch=$(date +%s)
    local days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

    if [ "$days_left" -lt 7 ]; then
        log "WARN" "SSL certificate expires in $days_left days"
        send_alert "SSL certificate expiring in $days_left days on $VPS_HOST"
        run_on_vps "sudo certbot renew"
        return 1
    fi

    log "INFO" "SSL certificate is valid ($days_left days remaining) ✓"
    return 0
}

# ============================================================================
# ALERTS & NOTIFICATIONS
# ============================================================================

send_alert() {
    local message=$1

    log "ALERT" "$message"

    # Send to Slack if webhook is configured
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"⚠️ $message\",\"username\":\"VPS Monitor\",\"icon_emoji\":\":warning:\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# ============================================================================
# PERFORMANCE METRICS
# ============================================================================

collect_metrics() {
    log "INFO" "Collecting performance metrics..."

    run_on_vps "bash -c '
        echo \"=== System Metrics ===\"
        echo \"Time: \$(date)\"
        echo \"Load Average: \$(uptime | awk -F \"load average:\" '{print \$2}')\"
        echo \"Disk I/O:\"
        iostat -x 1 2 | tail -5
        echo \"Top Processes:\"
        ps aux --sort=-%cpu | head -5
    '" | tee -a "${LOG_FILE}"
}

# ============================================================================
# MAIN MONITORING LOOP
# ============================================================================

run_checks() {
    log "INFO" "==============================================="
    log "INFO" "Starting health check cycle at $(date)"
    log "INFO" "==============================================="

    local failed_checks=0

    # Check Docker first
    if ! check_docker; then
        ((failed_checks++))
    fi

    # Check core containers
    if ! check_container "postgres"; then
        ((failed_checks++))
    fi

    if ! check_container "redis"; then
        ((failed_checks++))
    fi

    if ! check_container "api"; then
        ((failed_checks++))
    fi

    if ! check_container "liferay"; then
        ((failed_checks++))
    fi

    # Check services
    if ! check_postgresql; then
        ((failed_checks++))
    fi

    if ! check_redis; then
        ((failed_checks++))
    fi

    if ! check_api_health; then
        ((failed_checks++))
    fi

    if ! check_nginx; then
        ((failed_checks++))
    fi

    # Check system resources
    if ! check_disk_space; then
        ((failed_checks++))
    fi

    if ! check_memory; then
        ((failed_checks++))
    fi

    if ! check_certificate; then
        ((failed_checks++))
    fi

    # Collect metrics
    collect_metrics

    # Summary
    log "INFO" "==============================================="
    if [ $failed_checks -eq 0 ]; then
        log "INFO" "✅ All checks passed"
    else
        log "WARN" "❌ $failed_checks check(s) failed"
        send_alert "$failed_checks health check(s) failed on $VPS_HOST"
    fi
    log "INFO" "==============================================="
    log "INFO" ""

    return $failed_checks
}

# ============================================================================
# SETUP (Run once)
# ============================================================================

setup_monitoring() {
    log "INFO" "Setting up VPS monitoring agent..."

    # Create log directory
    run_on_vps "sudo mkdir -p /var/log && sudo touch /var/log/creative-platform-monitor.log"

    # Create systemd service
    run_on_vps "sudo bash -c 'cat > /etc/systemd/system/creative-platform-monitor.service <<'SERVICE'
[Unit]
Description=Creative Platform VPS Monitor
After=network.target

[Service]
Type=simple
User=root
ExecStart=$(pwd)/deploy/vps-monitoring-agent.sh monitor-loop
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
SERVICE
'"

    run_on_vps "sudo systemctl daemon-reload"
    run_on_vps "sudo systemctl enable creative-platform-monitor"
    run_on_vps "sudo systemctl start creative-platform-monitor"

    log "INFO" "Monitoring agent installed and started"
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

case "${1:-check}" in
    check)
        # Single health check
        run_checks
        ;;
    monitor-loop)
        # Continuous monitoring loop
        log "INFO" "Starting continuous monitoring loop (interval: ${MONITOR_INTERVAL}s)"
        while true; do
            run_checks
            log "INFO" "Next check in ${MONITOR_INTERVAL} seconds..."
            sleep "$MONITOR_INTERVAL"
        done
        ;;
    setup)
        # Setup monitoring service
        setup_monitoring
        ;;
    status)
        # Show monitoring status
        log "INFO" "Checking monitoring service status..."
        run_on_vps "sudo systemctl status creative-platform-monitor"
        ;;
    logs)
        # Show monitoring logs
        log "INFO" "Last 50 monitoring log entries:"
        run_on_vps "sudo tail -50 /var/log/creative-platform-monitor.log"
        ;;
    *)
        cat <<EOF
VPS Monitoring Agent - Usage

Commands:
  check          Run a single health check cycle
  monitor-loop   Start continuous monitoring loop
  setup          Install monitoring service on VPS
  status         Show monitoring service status
  logs           Display monitoring logs

Examples:
  $0 check                    # Single health check
  $0 setup                    # Install monitoring service
  $0 status                   # Check service status
  $0 logs                     # View logs

Environment Variables:
  VPS_HOST       - VPS hostname (default: agennext.com)
  VPS_USER       - VPS username (default: almalinux)
  VPS_PASSWORD   - VPS password (required)
  SLACK_WEBHOOK  - Slack webhook for alerts (optional)
  MONITOR_INTERVAL - Check interval in seconds (default: 60)

EOF
        exit 1
        ;;
esac
