# ☁️ Cloud Services Setup Guide

**Complete setup for Temporal Cloud + ClickHouse Cloud**

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Setup Temporal Cloud

```bash
cd ~/CustomApps/creative-platform
./deploy/setup-temporal-cloud.sh
```

**What happens:**
- Prompts for Temporal Cloud namespace
- Generates API key configuration
- Updates Go dependencies
- Creates worker code

**Get credentials from:** https://cloud.temporal.io/get-started/profile/platform

### Step 2: Setup ClickHouse Cloud

```bash
./deploy/setup-clickhouse-cloud.sh
```

**What happens:**
- Guides through ClickHouse Cloud signup
- Configures connection details
- Creates database schema with TTL policies
- Generates Go client code

**Get credentials from:** https://console.clickhouse.cloud/signUp

### Step 3: Deploy

```bash
git push origin main
# GitHub Actions automatically deploys both configurations
```

---

## 📊 Side-by-Side Comparison

| Feature | Temporal Cloud | ClickHouse Cloud |
|---------|----------------|------------------|
| **Purpose** | Workflow orchestration | Analytics database |
| **Use Case** | Background jobs, retries | Metrics, logs, analytics |
| **Signup** | https://cloud.temporal.io | https://console.clickhouse.cloud |
| **Setup Time** | 2-3 minutes | 2-3 minutes |
| **Config File** | `.env.temporal` | `.env.clickhouse` |
| **Setup Script** | `./deploy/setup-temporal-cloud.sh` | `./deploy/setup-clickhouse-cloud.sh` |

---

## 🏗️ Architecture

```
┌─────────────────────────────────┐
│   Your Application (Go API)     │
└────────────┬────────────────────┘
             │
    ┌────────┴─────────┐
    ↓                  ↓
┌──────────────┐  ┌──────────────────┐
│ Temporal     │  │ ClickHouse       │
│ Cloud        │  │ Cloud            │
├──────────────┤  ├──────────────────┤
│ Workflows    │  │ Analytics DB     │
│ Jobs         │  │ Metrics Storage  │
│ Retries      │  │ Log Aggregation  │
│ Schedules    │  │ Audit Trail      │
└──────────────┘  └──────────────────┘
```

---

## 📋 Setup Checklist

### Temporal Cloud ☑️

- [ ] Visit https://cloud.temporal.io
- [ ] Create account and organization
- [ ] Create namespace (e.g., `creative-platform-prod`)
- [ ] Generate API key
- [ ] Run `./deploy/setup-temporal-cloud.sh`
- [ ] Verify: `source .env.temporal && echo $TEMPORAL_NAMESPACE`
- [ ] Deploy: `git push origin main`

### ClickHouse Cloud ☑️

- [ ] Visit https://console.clickhouse.cloud/signUp
- [ ] Create account
- [ ] Create service (e.g., `creative-platform-analytics`)
- [ ] Get connection details
- [ ] Run `./deploy/setup-clickhouse-cloud.sh`
- [ ] Initialize: `./deploy/init-clickhouse.sh`
- [ ] Verify: `SELECT 1` in ClickHouse console
- [ ] Deploy: `git push origin main`

---

## 🔐 Security Best Practices

### Temporal Cloud

```bash
# Credentials stored in .env.temporal
source .env.temporal

# Use TLS certificates for mTLS
export TEMPORAL_TLS_CERT_PATH="deploy/temporal-certs/cert.pem"
export TEMPORAL_TLS_KEY_PATH="deploy/temporal-certs/key.pem"

# Never commit credentials
cat .gitignore | grep .env.temporal
```

### ClickHouse Cloud

```bash
# Credentials stored in .env.clickhouse
source .env.clickhouse

# Whitelist VPS IP in ClickHouse Cloud console
# Settings → Network → IP Whitelist → Add VPS IP

# Never commit credentials
cat .gitignore | grep .env.clickhouse
```

---

## 💾 Configuration Files

### `.env.temporal`
```bash
TEMPORAL_NAMESPACE=your-namespace.tmprl.cloud
TEMPORAL_ADDRESS=your-namespace.tmprl.cloud:7233
TEMPORAL_API_KEY=xxxx-xxxx-xxxx-xxxx
TEMPORAL_NAMESPACE_WORKFLOWS=creative-platform-prod
TEMPORAL_HEALTH_CHECK_INTERVAL=1h
```

### `.env.clickhouse`
```bash
CLICKHOUSE_HOST=your-service.clickhouse.cloud
CLICKHOUSE_PORT=8443
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=xxxx
CLICKHOUSE_DATABASE=metrics
CLICKHOUSE_METRICS_RETENTION_DAYS=90
```

---

## 🎯 What Each Service Does

### Temporal Cloud

**Orchestrates background workflows:**

```
Health Check (Every 1 hour)
├── Check API endpoint
├── Check database connectivity
├── Check Redis cache
└── Send alert if any fails

Database Backup (Every night at 3 AM)
├── Create PostgreSQL backup
├── Upload to S3
├── Maintain 30-day retention
└── Alert on failure

Metrics Export (Every hour)
├── Collect from Prometheus
├── Transform data
├── Export to ClickHouse
└── Log activity
```

### ClickHouse Cloud

**Stores analytics data:**

```
Tables:
├── metrics (90 days) - System metrics
├── logs (30 days) - Application logs
├── api_requests (90 days) - HTTP requests
├── db_queries (90 days) - Database queries
├── errors (90 days) - Error tracking
├── alerts (90 days) - Alert history
└── audit_log (90 days) - User actions

Queries:
├── Performance analysis (P50, P95, P99)
├── Error trends over time
├── User activity reports
└── System health metrics
```

---

## 🔗 Useful Links

### Temporal Cloud
- **Console:** https://cloud.temporal.io
- **Docs:** https://docs.temporal.io/cloud
- **API Reference:** https://docs.temporal.io/cloud/rest-api
- **Pricing:** https://cloud.temporal.io/get-started/profile/platform

### ClickHouse Cloud
- **Console:** https://console.clickhouse.cloud
- **Docs:** https://clickhouse.com/docs/
- **REST API:** https://clickhouse.com/docs/en/interfaces/http
- **Pricing:** https://clickhouse.com/cloud/pricing

---

## 📊 Monitoring Setup

### Dashboard Access

```
Temporal Cloud UI
└─ https://your-namespace.tmprl.cloud:7233/namespaces

ClickHouse Cloud Console
└─ https://console.clickhouse.cloud

Grafana (Local)
└─ http://agennext.com:3000
   - Connects to Prometheus for real-time
   - Displays ClickHouse data for analytics
```

### Health Checks

**Temporal Cloud:**
```bash
# Check namespace health
tctl --namespace creative-platform-prod namespace describe

# List active workflows
tctl --namespace creative-platform-prod workflow list

# Check latest execution
tctl --namespace creative-platform-prod workflow describe -w health-check-latest
```

**ClickHouse Cloud:**
```bash
# Test connection
curl -u default:password https://your-service.clickhouse.cloud:8443/ping

# Check table sizes
curl -s "https://your-service.clickhouse.cloud:8443/?query=SELECT%20table,%20sum(bytes)%20FROM%20system.tables%20WHERE%20database='metrics'%20GROUP%20BY%20table" \
  -u default:password
```

---

## 💡 Common Tasks

### Add New Workflow to Temporal Cloud

```go
// 1. Define workflow
func MyNewWorkflow(ctx workflow.Context) error {
    // Implementation
    return nil
}

// 2. Register in worker
w.RegisterWorkflow(MyNewWorkflow)

// 3. Start workflow
client.ExecuteWorkflow(ctx, options, MyNewWorkflow, arg1, arg2)
```

### Add New Metric to ClickHouse

```go
// 1. Insert metric
RecordMetric(ctx, "my_metric", 42.0, "my-service", map[string]string{
    "org_id": orgID,
    "env": "prod",
})

// 2. Query in ClickHouse
SELECT timestamp, metric_name, value
FROM metrics
WHERE metric_name = 'my_metric'
ORDER BY timestamp DESC
LIMIT 100
```

---

## 🚨 Troubleshooting

### Temporal Cloud Connection Failed

```bash
# Check credentials
source .env.temporal
echo "Namespace: $TEMPORAL_NAMESPACE"
echo "Address: $TEMPORAL_ADDRESS"

# Test connection
tctl --namespace creative-platform-prod namespace describe

# Common issues:
# - API key expired → Regenerate in console
# - Wrong namespace → Check spelling
# - Network issue → Check VPS firewall
```

### ClickHouse Cloud Connection Failed

```bash
# Check credentials
source .env.clickhouse
echo "Host: $CLICKHOUSE_HOST"
echo "User: $CLICKHOUSE_USER"

# Test connection
curl -u ${CLICKHOUSE_USER}:${CLICKHOUSE_PASSWORD} \
  https://${CLICKHOUSE_HOST}:${CLICKHOUSE_PORT}/ping

# Common issues:
# - IP not whitelisted → Add VPS IP in console
# - Wrong password → Verify in console
# - Database doesn't exist → Run init-clickhouse.sh
```

---

## 📈 Cost Estimates

### Temporal Cloud
- **Pricing:** Pay-per-workflow + API calls
- **Estimate:** $500-2,000/month for typical usage
- **Scaling:** Automatic, no infrastructure management

### ClickHouse Cloud
- **Pricing:** Per-compute unit + storage
- **Estimate:** $500-1,000/month for typical usage
- **Scaling:** Auto-scale based on queries

### Total Monthly Cost
**~$1,000-3,000/month** for full production setup

---

## ✅ Verification Checklist

### After Setup

- [ ] `.env.temporal` created and in `.gitignore`
- [ ] `.env.clickhouse` created and in `.gitignore`
- [ ] Temporal Cloud connection verified
- [ ] ClickHouse Cloud database schema initialized
- [ ] Go dependencies updated (`go mod tidy`)
- [ ] `src/api/temporal_worker.go` exists
- [ ] `src/api/clickhouse_client.go` exists
- [ ] Code deployed to VPS via GitHub Actions
- [ ] Health check workflow running
- [ ] Metrics flowing to ClickHouse

---

## 🎉 You're Ready!

Once both services are set up:

1. **Code changes** → `git push`
2. **GitHub Actions** → Auto-deploys
3. **Temporal Cloud** → Runs workflows
4. **ClickHouse Cloud** → Stores analytics
5. **Grafana** → Visualizes data
6. **Your VPS** → Runs the API

**System is now production-ready with 24/7 monitoring!** 🚀

---

**Status:** ✅ READY FOR CLOUD DEPLOYMENT  
**Last Updated:** 2026-06-25  
**Next:** Push to GitHub and watch it deploy automatically!
