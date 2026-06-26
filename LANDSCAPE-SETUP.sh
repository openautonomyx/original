#!/bin/bash

# Publishing Platform - Project Landscape Setup
# Creates complete directory structure and scaffolding

set -e

echo "🏗️ Creating Publishing Platform Landscape..."

# Root directories
mkdir -p services database config scripts logs

# ==================== INFRASTRUCTURE ====================
mkdir -p database/migrations database/seeds

# ==================== CORE SERVICES ====================

# API Gateway
mkdir -p services/api-gateway/{src,config,tests}
mkdir -p services/api-gateway/src/{api,middleware,utils}

# Event Bus
mkdir -p services/event-bus/{src,config,tests}
mkdir -p services/event-bus/src/{events,handlers,middleware}

# ==================== BUSINESS MODULES ====================

for service in content-management skills tools analytics optimization design features; do
  mkdir -p services/$service/{src,config,tests,database}
  mkdir -p services/$service/src/{api,services,models,events,utils}
  mkdir -p services/$service/database/migrations
done

# ==================== CONFIGURATION ====================
mkdir -p config/{local,development,production,kubernetes}

# ==================== SCRIPTS ====================
mkdir -p scripts/{db,deployment,monitoring}

# ==================== DOCUMENTATION ====================
mkdir -p docs/{architecture,guides,api}

echo "✅ Directory structure created!"
echo ""
echo "📂 Project Layout:"
tree -L 2 -d . || find . -type d -maxdepth 2 | sort
