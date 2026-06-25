#!/bin/bash
# setup-temporal-cloud.sh - Configure Temporal Cloud integration
# Usage: ./deploy/setup-temporal-cloud.sh

set -e

echo "=========================================="
echo "🚀 Temporal Cloud Setup Script"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required tools are installed
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    fi
    return 0
}

echo "📋 Checking prerequisites..."
check_command "tctl" || echo -e "${YELLOW}⚠️  Note: Install Temporal CLI for full functionality${NC}"
echo ""

# Input validation
validate_input() {
    local input=$1
    local pattern=$2
    if [[ ! $input =~ $pattern ]]; then
        return 1
    fi
    return 0
}

# Step 1: Get Temporal Cloud namespace
echo -e "${YELLOW}Step 1: Temporal Cloud Configuration${NC}"
echo "Visit: https://cloud.temporal.io/get-started/profile/platform"
echo ""

read -p "Enter your Temporal Cloud namespace (e.g., your-namespace.tmprl.cloud): " TEMPORAL_NAMESPACE
if [ -z "$TEMPORAL_NAMESPACE" ]; then
    echo -e "${RED}❌ Namespace cannot be empty${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Namespace: $TEMPORAL_NAMESPACE${NC}"
echo ""

# Step 2: Get API key
echo -e "${YELLOW}Step 2: Generate API Key${NC}"
echo "In Temporal Cloud dashboard:"
echo "  1. Go to Settings → API Keys"
echo "  2. Create new API key"
echo "  3. Copy the key"
echo ""

read -sp "Enter your Temporal Cloud API key: " TEMPORAL_API_KEY
echo ""

if [ -z "$TEMPORAL_API_KEY" ]; then
    echo -e "${RED}❌ API key cannot be empty${NC}"
    exit 1
fi

echo -e "${GREEN}✓ API key configured${NC}"
echo ""

# Step 3: Download certificates (optional for TLS)
echo -e "${YELLOW}Step 3: TLS Certificates (Optional)${NC}"
echo "For mTLS authentication:"
echo "  1. Download cert.pem and key.pem from Temporal Cloud"
echo "  2. Save to: deploy/temporal-certs/"
echo ""

read -p "Do you have TLS certificates? (y/n): " HAS_CERTS

if [ "$HAS_CERTS" = "y" ]; then
    mkdir -p deploy/temporal-certs
    echo "Place cert.pem and key.pem in: $(pwd)/deploy/temporal-certs/"
    read -p "Press Enter once files are in place..."
fi

echo ""

# Step 4: Create .env.temporal file
echo -e "${YELLOW}Step 4: Creating Configuration File${NC}"

cat > .env.temporal << EOF
# Temporal Cloud Configuration
# Generated: $(date)

# Connection
TEMPORAL_NAMESPACE=${TEMPORAL_NAMESPACE}
TEMPORAL_ADDRESS=${TEMPORAL_NAMESPACE}:7233
TEMPORAL_API_KEY=${TEMPORAL_API_KEY}

# TLS Configuration
TEMPORAL_TLS_ENABLED=true
TEMPORAL_TLS_CERT_PATH=deploy/temporal-certs/cert.pem
TEMPORAL_TLS_KEY_PATH=deploy/temporal-certs/key.pem

# Namespace for workflows
TEMPORAL_NAMESPACE_WORKFLOWS=creative-platform-prod
TEMPORAL_NAMESPACE_CLIENTS=client-management

# Workflow configuration
TEMPORAL_HEALTH_CHECK_INTERVAL=1h
TEMPORAL_HEALTH_CHECK_TIMEOUT=5m
TEMPORAL_BACKUP_SCHEDULE=03:00 UTC
TEMPORAL_BACKUP_RETENTION_DAYS=30

# Logging
TEMPORAL_LOG_LEVEL=info
TEMPORAL_LOG_FORMAT=json
EOF

echo -e "${GREEN}✓ Created .env.temporal${NC}"
echo ""

# Step 5: Update .gitignore
echo -e "${YELLOW}Step 5: Securing Sensitive Files${NC}"

if ! grep -q ".env.temporal" .gitignore; then
    echo ".env.temporal" >> .gitignore
    echo -e "${GREEN}✓ Added .env.temporal to .gitignore${NC}"
fi

if ! grep -q "deploy/temporal-certs/" .gitignore; then
    echo "deploy/temporal-certs/" >> .gitignore
    echo -e "${GREEN}✓ Added temporal-certs to .gitignore${NC}"
fi

echo ""

# Step 6: Update Go dependencies
echo -e "${YELLOW}Step 6: Updating Go Dependencies${NC}"

cd src/api

echo "Installing Temporal Go SDK..."
go get github.com/temporalio/sdk-go/v1@latest
go get github.com/temporalio/sdk-go/contrib/tctl@latest

echo "Running go mod tidy..."
go mod tidy

cd ../..

echo -e "${GREEN}✓ Dependencies updated${NC}"
echo ""

# Step 7: Create Temporal worker configuration
echo -e "${YELLOW}Step 7: Creating Worker Configuration${NC}"

cat > src/api/temporal_worker.go << 'GOFILE'
package main

import (
	"crypto/tls"
	"log"
	"os"

	"github.com/temporalio/sdk-go/v1/client"
	"github.com/temporalio/sdk-go/v1/worker"
)

// InitTemporalClient connects to Temporal Cloud
func InitTemporalClient() (client.Client, error) {
	namespace := os.Getenv("TEMPORAL_NAMESPACE_WORKFLOWS")
	if namespace == "" {
		namespace = "creative-platform-prod"
	}

	// Load TLS certificates if configured
	var tlsConfig *tls.Config
	if os.Getenv("TEMPORAL_TLS_ENABLED") == "true" {
		certPath := os.Getenv("TEMPORAL_TLS_CERT_PATH")
		keyPath := os.Getenv("TEMPORAL_TLS_KEY_PATH")

		if certPath != "" && keyPath != "" {
			cert, err := tls.LoadX509KeyPair(certPath, keyPath)
			if err != nil {
				return nil, err
			}
			tlsConfig = &tls.Config{
				Certificates: []tls.Certificate{cert},
			}
		}
	}

	return client.Dial(client.Options{
		HostPort:  os.Getenv("TEMPORAL_ADDRESS"),
		Namespace: namespace,
		TLSConfig: tlsConfig,
	})
}

// StartWorker starts a Temporal worker
func StartWorker() error {
	c, err := InitTemporalClient()
	if err != nil {
		log.Fatalf("unable to create Temporal client: %v", err)
	}
	defer c.Close()

	w := worker.New(c, "creative-platform-tasks", worker.Options{})

	// Register workflows
	w.RegisterWorkflow(MonitorSystemHealth)
	w.RegisterWorkflow(BackupDatabase)
	w.RegisterWorkflow(ExportMetrics)

	// Register activities
	w.RegisterActivity(CheckAPIHealth)
	w.RegisterActivity(CheckDatabase)
	w.RegisterActivity(SendAlert)
	w.RegisterActivity(ExportMetricsActivity)

	if err = w.Run(worker.InterruptCh()); err != nil {
		return err
	}

	return nil
}

// Example workflow definitions
func MonitorSystemHealth(ctx WorkflowContext) error {
	// Implement health monitoring workflow
	return nil
}

func BackupDatabase(ctx WorkflowContext) error {
	// Implement database backup workflow
	return nil
}

func ExportMetrics(ctx WorkflowContext) error {
	// Implement metrics export workflow
	return nil
}

// Example activity definitions
func CheckAPIHealth(ctx context.Context) error {
	// Implement API health check
	return nil
}

func CheckDatabase(ctx context.Context) error {
	// Implement database health check
	return nil
}

func SendAlert(ctx context.Context, alert string) error {
	// Implement alert sending
	return nil
}

func ExportMetricsActivity(ctx context.Context) error {
	// Export metrics to ClickHouse
	return nil
}
GOFILE

echo -e "${GREEN}✓ Created temporal_worker.go${NC}"
echo ""

# Step 8: Create deployment instructions
cat > deploy/TEMPORAL-DEPLOYMENT.md << 'EOF'
# Temporal Cloud Deployment

## Prerequisites
- Temporal Cloud account
- API key configured in `.env.temporal`
- TLS certificates (if using mTLS)

## Starting Workflow Worker

```bash
# Load environment
source .env.temporal

# Start worker
cd src/api
go run . --temporal-worker

# Or run as service
docker run -d \
  --name creative-temporal-worker \
  --env-file ../../.env.temporal \
  ghcr.io/fractional-pm/creative-platform-api:latest \
  --temporal-worker
```

## Verifying Connection

```bash
# Check connection
tctl --namespace creative-platform-prod namespace describe

# List workflows
tctl --namespace creative-platform-prod workflow list

# Start test workflow
tctl --namespace creative-platform-prod workflow start \
  --type MonitorSystemHealth \
  --task-queue creative-platform-tasks
```

## Monitoring

- **Temporal Cloud Dashboard:** https://cloud.temporal.io
- **Workflow History:** Check namespace → Workflows
- **Logs:** Check deployment logs in GitHub Actions

EOF

echo -e "${GREEN}✓ Created deployment documentation${NC}"
echo ""

# Final summary
echo "=========================================="
echo -e "${GREEN}✅ Temporal Cloud Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "📝 Configuration saved to: .env.temporal"
echo "🔐 Keep .env.temporal secure (added to .gitignore)"
echo ""
echo "🚀 Next steps:"
echo "  1. Review .env.temporal configuration"
echo "  2. (Optional) Add TLS certificates to deploy/temporal-certs/"
echo "  3. Test connection: cd src/api && go run . --temporal-check"
echo "  4. Deploy: git push origin main"
echo "  5. Monitor: https://cloud.temporal.io/namespaces"
echo ""
echo "📚 Documentation:"
echo "  - CLOUD-DEPLOYMENT.md - Architecture and setup guide"
echo "  - deploy/TEMPORAL-DEPLOYMENT.md - Deployment instructions"
echo ""
