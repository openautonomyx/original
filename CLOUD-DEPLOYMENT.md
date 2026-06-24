# Cloud Deployment Strategy

**Objective:** Use managed cloud services for reliability and multi-tenant client deployments.

**Status:** Ready for implementation  
**Architecture:** Hybrid (Self-hosted core + Cloud services)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────┐
│       Client Applications           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Your VPS (agennext.com)            │
├─────────────────────────────────────┤
│ • API Service (Go)                  │
│ • PostgreSQL (Multi-tenant RLS)     │
│ • Redis (Cache)                     │
│ • Nginx (Reverse Proxy)             │
│ • Prometheus (Metrics)              │
│ • Loki (Logs)                       │
│ • Grafana (Dashboards)              │
└─────────────────────────────────────┘
         ↓              ↓
┌──────────────┐  ┌──────────────────┐
│ Temporal     │  │ ClickHouse Cloud │
│ Cloud        │  │ (Analytics)      │
│ (Workflows)  │  │                  │
└──────────────┘  └──────────────────┘
         ↓              ↓
    [Managed Services - No Infrastructure to Manage]
```

---

## ☁️ Cloud Services

### 1. **Temporal Cloud** (Workflow Orchestration)

**Benefits:**
- ✅ No infrastructure management
- ✅ Multi-tenant ready
- ✅ Built-in disaster recovery
- ✅ 99.99% uptime SLA
- ✅ Automatic scaling

**Use Cases:**
- Background job orchestration
- Automated health checks (24/7)
- Scheduled backups
- Long-running workflows
- Retry logic with exponential backoff

**Pricing:** https://cloud.temporal.io/get-started/profile/platform

**Setup:**
```bash
# 1. Create account at https://cloud.temporal.io
# 2. Create namespace: creative-platform-prod
# 3. Generate API key for authentication
# 4. Update SDK configuration:

export TEMPORAL_CLOUD_ADDRESS="your-namespace.tmprl.cloud:7233"
export TEMPORAL_CLOUD_API_KEY="your-api-key"
```

### 2. **ClickHouse Cloud** (Analytics Database)

**Benefits:**
- ✅ Serverless SQL analytics
- ✅ Auto-scaling storage
- ✅ Pay-per-query pricing
- ✅ Built-in replication
- ✅ REST API access

**Use Cases:**
- Long-term metrics storage (90+ days)
- Log analysis and trends
- Customer usage analytics
- Performance reports
- Audit trails

**Pricing:** https://clickhouse.com/cloud/pricing

**Setup:**
```bash
# 1. Sign up at https://clickhouse.com/cloud
# 2. Create service: creative-platform-analytics
# 3. Get connection string
# 4. Configure in monitoring stack

export CLICKHOUSE_HOST="your-service.clickhouse.cloud"
export CLICKHOUSE_USER="default"
export CLICKHOUSE_PASSWORD="your-password"
```

### 3. **PostgreSQL Cloud (Optional)**

**Alternatives:**
- AWS RDS for PostgreSQL
- DigitalOcean Managed PostgreSQL
- Google Cloud SQL
- Azure Database for PostgreSQL

**Current Setup:** Self-hosted on VPS (good for MVP)  
**Scale Later:** Move to cloud when needed

---

## 🚀 Client Deployment Options

### Option 1: Shared Infrastructure (MVP)

**For:** Early customers, cost-sensitive clients

```
Your VPS (agennext.com)
├── Org 1 (Customer A)
├── Org 2 (Customer B)
├── Org 3 (Customer C)
└── Org N
```

**How:** PostgreSQL Row-Level Security (RLS) isolates customer data

**Setup:**
```sql
-- Customer A
INSERT INTO organizations (id, name) VALUES ('org-123', 'Acme Corp');
ALTER POLICY org_policy ON content USING (org_id = 'org-123');

-- Customer B
INSERT INTO organizations (id, name) VALUES ('org-456', 'TechCorp');
ALTER POLICY org_policy ON content USING (org_id = 'org-456');
```

**Pros:** ✅ Single infrastructure, lowest cost  
**Cons:** ❌ Limited customization, shared resources

---

### Option 2: Containerized Per-Client (Scaling)

**For:** Growing customers with custom needs

```
Each Client Gets:
├── Docker Container (API)
├── PostgreSQL Instance (Private)
├── Redis Instance (Private)
└── Monitoring (Separate)
```

**Deployment Script:**
```bash
#!/bin/bash
# deploy-client.sh

CLIENT_ID=$1
CLIENT_NAME=$2

# Create Docker containers
docker run -d \
  --name "api-${CLIENT_ID}" \
  --env CLIENT_ID="${CLIENT_ID}" \
  --env DB_NAME="db_${CLIENT_ID}" \
  -p "3001:3001" \
  ghcr.io/fractional-pm/creative-platform-api:latest

docker run -d \
  --name "postgres-${CLIENT_ID}" \
  --env POSTGRES_DB="db_${CLIENT_ID}" \
  -p "5432:5432" \
  postgres:15-alpine

# Create monitoring in Temporal Cloud
temporal workflow start \
  --namespace "client-${CLIENT_ID}" \
  --type "MonitorClientHealth" \
  --input "{\"client_id\": \"${CLIENT_ID}\", \"client_name\": \"${CLIENT_NAME}\"}"
```

**Pros:** ✅ Full isolation, custom configuration  
**Cons:** ❌ Higher infrastructure cost, more management

---

### Option 3: Kubernetes + Helm (Enterprise)

**For:** Large enterprises, complex requirements

```
Kubernetes Cluster
├── Namespace: client-1
├── Namespace: client-2
└── Namespace: client-n

Each Namespace:
├── API Deployment
├── PostgreSQL StatefulSet
├── Redis StatefulSet
├── Monitoring/Logging
└── Auto-scaling
```

**Helm Chart Example:**
```yaml
# helm/creative-platform/values.yaml
clients:
  acme:
    replicas: 3
    database:
      size: 100Gi
      backup: true
    monitoring:
      enabled: true
  techcorp:
    replicas: 2
    database:
      size: 50Gi
      backup: true
```

**Pros:** ✅ Enterprise-grade, auto-scaling, HA  
**Cons:** ❌ Complex infrastructure, expensive

---

## 📋 Implementation Plan

### Phase 1: Current (Production Ready)

**Architecture:** Shared VPS + Temporal Cloud

```bash
# 1. Deploy to VPS (existing)
git push origin main
# → GitHub Actions auto-deploys

# 2. Workflows run on Temporal Cloud
export TEMPORAL_CLOUD_ADDRESS="your-namespace.tmprl.cloud:7233"
cd src/agents
npm install @temporalio/client
# → SDK connects to Temporal Cloud
```

**Cost:** 
- VPS: $50-100/month
- Temporal Cloud: $500-2000/month
- ClickHouse Cloud: $500-1000/month
- **Total:** ~$1000-3000/month

### Phase 2: Next (Multi-Tenant)

**When:** 5-10 customers, need customization

**Migration:**
1. Keep shared VPS for core API
2. Add per-client Docker containers
3. Scale Temporal workflows per customer
4. Implement customer billing in API

### Phase 3: Future (Enterprise)

**When:** 20+ customers, complex deployments

**Migration:**
1. Kubernetes cluster (AWS EKS, GKE, AKS)
2. Helm charts for automated deployments
3. Per-customer namespaces
4. Auto-scaling based on usage

---

## 🔧 Temporal Cloud Setup

### Step 1: Create Account

1. Go to https://cloud.temporal.io
2. Sign up with email
3. Create organization

### Step 2: Create Namespace

```bash
# Via CLI
temporal operator namespace create \
  --namespace creative-platform-prod \
  --address your-namespace.tmprl.cloud:7233
```

### Step 3: Generate API Key

```bash
# Via dashboard
1. Go to Security → Certificates
2. Create new certificate
3. Save key.pem and ca.pem files
4. Create API key for programmatic access
```

### Step 4: Update Application

```go
// src/api/temporal.go
package main

import (
    "github.com/temporalio/sdk-go/client"
    "crypto/tls"
)

func initTemporalClient() (client.Client, error) {
    // TLS configuration for Temporal Cloud
    tlsCert, err := tls.LoadX509KeyPair("key.pem", "ca.pem")
    if err != nil {
        return nil, err
    }

    return client.Dial(client.Options{
        HostPort:   os.Getenv("TEMPORAL_CLOUD_ADDRESS"),
        Namespace:  "creative-platform-prod",
        TLSConfig:  &tls.Config{Certificates: []tls.Certificate{tlsCert}},
    })
}
```

### Step 5: Deploy Workflows

```bash
# Start workflow for health checks
temporal workflow start \
  --namespace creative-platform-prod \
  --type MonitorSystemHealth \
  --input '{"interval": "1h", "endpoints": ["/health", "/metrics"]}'

# Start workflow for nightly backups
temporal workflow start \
  --namespace creative-platform-prod \
  --type BackupDatabase \
  --input '{"schedule": "03:00 UTC", "retention_days": 30}'
```

---

## 💾 ClickHouse Cloud Setup

### Step 1: Create Account

1. Go to https://clickhouse.com/cloud
2. Sign up
3. Create new service: `creative-platform-analytics`

### Step 2: Get Connection Details

```bash
# From ClickHouse Cloud dashboard
export CLICKHOUSE_HOST="your-service.clickhouse.cloud"
export CLICKHOUSE_USER="default"
export CLICKHOUSE_PASSWORD="password"
export CLICKHOUSE_PORT="8443"
```

### Step 3: Create Tables

```sql
-- Connect to ClickHouse
clickhouse-client --host your-service.clickhouse.cloud \
                  --user default \
                  --password

-- Create metrics table
CREATE TABLE metrics (
    timestamp DateTime,
    metric_name String,
    service String,
    value Float64,
    labels Map(String, String)
) ENGINE = MergeTree()
ORDER BY (timestamp, metric_name, service);

-- Create logs table
CREATE TABLE logs (
    timestamp DateTime,
    level String,
    service String,
    message String,
    metadata Map(String, String)
) ENGINE = MergeTree()
ORDER BY (timestamp, level, service);
```

### Step 4: Send Metrics

```go
// Send Prometheus metrics to ClickHouse
func exportMetricsToClickHouse() {
    query := `INSERT INTO metrics VALUES`
    // Collect from Prometheus
    // Transform and insert into ClickHouse
}
```

---

## 📊 Monitoring Workflow

### Health Check Workflow (Temporal Cloud)

```go
// workflows/monitor_health.go
package workflows

import (
    "go.temporal.io/sdk/workflow"
    "time"
)

func MonitorSystemHealth(ctx workflow.Context) error {
    options := workflow.ActivityOptions{
        StartToCloseTimeout: time.Minute,
    }
    ctx = workflow.WithActivityOptions(ctx, options)

    // Health check every hour
    ticker := workflow.NewTicker(ctx, time.Hour)
    defer ticker.Stop()

    for {
        select {
        case <-ticker.C():
            // Check API health
            var result HealthCheckResult
            err := workflow.ExecuteActivity(ctx, CheckAPIHealth).Get(ctx, &result)
            if err != nil {
                // Send alert
                workflow.ExecuteActivity(ctx, SendAlert, result)
            }

            // Check database
            err = workflow.ExecuteActivity(ctx, CheckDatabase).Get(ctx, &result)
            if err != nil {
                workflow.ExecuteActivity(ctx, SendAlert, result)
            }

            // Send metrics to ClickHouse
            workflow.ExecuteActivity(ctx, ExportMetrics, result)

        case <-ctx.Done():
            return ctx.Err()
        }
    }
}
```

---

## 🔒 Security

### Temporal Cloud API Keys

```bash
# Store in .env.production
export TEMPORAL_API_KEY="xxxx-xxxx-xxxx-xxxx"
export TEMPORAL_TLS_CERT_PATH="/path/to/cert.pem"
export TEMPORAL_TLS_KEY_PATH="/path/to/key.pem"
```

### ClickHouse Cloud Access

```bash
# Only allow from VPS IP
# Configure in ClickHouse Cloud dashboard:
# Security → IP Whitelist → Add VPS IP
```

### Client Isolation (Multi-tenant)

```sql
-- Separate Temporal namespaces per client
temporal operator namespace create \
  --namespace "client-acme" \
  --address your-namespace.tmprl.cloud:7233

temporal operator namespace create \
  --namespace "client-techcorp" \
  --address your-namespace.tmprl.cloud:7233
```

---

## 📈 Scaling Plan

### Current (MVP)
```
1 VPS + Temporal Cloud + ClickHouse Cloud
Supports: 1-5 customers
Cost: ~$1000-3000/month
```

### Growth (5-20 customers)
```
1 VPS + Container per client + Temporal Cloud
Supports: 5-20 customers
Cost: ~$2000-5000/month
```

### Enterprise (20+ customers)
```
Kubernetes + Temporal Cloud + ClickHouse Cloud
Supports: 100+ customers
Cost: ~$10000-50000/month
```

---

## 🚀 Migration Checklist

### To Temporal Cloud
- [ ] Create Temporal Cloud account
- [ ] Create namespace
- [ ] Generate API keys and certificates
- [ ] Update SDK configuration
- [ ] Deploy workflows
- [ ] Test health checks
- [ ] Verify alerts in Slack/PagerDuty
- [ ] Monitor cost

### To ClickHouse Cloud
- [ ] Create ClickHouse Cloud account
- [ ] Create service
- [ ] Create tables for metrics and logs
- [ ] Update metrics export configuration
- [ ] Verify data is flowing
- [ ] Create analytics queries
- [ ] Monitor query performance and cost

---

## 💡 Alternative Cloud Options

### Temporal Alternatives
- **Conductor** (Netflix) - Open source
- **Prefect** - Python-based workflow engine
- **Airflow** - DAG-based orchestration
- **Step Functions** (AWS) - Managed service

### ClickHouse Alternatives
- **Datadog** - Metrics + logs platform
- **New Relic** - Full observability platform
- **Splunk** - Log aggregation and analytics
- **Elasticsearch** - Log search and analytics

---

## 📞 Next Steps

1. **Sign up for Temporal Cloud:** https://cloud.temporal.io/get-started/profile/platform
2. **Sign up for ClickHouse Cloud:** https://clickhouse.com/cloud
3. **Create namespaces and API keys**
4. **Update SDK configuration**
5. **Deploy workflows**
6. **Test end-to-end**
7. **Plan client deployment strategy**

---

**Status:** ✅ READY FOR CLOUD DEPLOYMENT  
**Last Updated:** 2026-06-25
