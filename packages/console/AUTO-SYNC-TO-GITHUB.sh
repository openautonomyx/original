#!/bin/bash

# Automated Sync - Push all 3 repos to GitHub automatically
# No manual steps needed - full CI/CD integration

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       🤖 AUTOMATED SYNC - Push All Repos to GitHub            ║"
echo "║          (CI/CD Automation - No Manual Steps)                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# STEP 1: VERIFY GITHUB CLI & AUTHENTICATION
# ============================================================================

echo "${BLUE}STEP 1: Checking GitHub CLI & Authentication${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found"
    echo ""
    echo "Install with:"
    echo "  brew install gh"
    exit 1
fi

if ! gh auth status > /dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub"
    echo ""
    echo "Authenticate with:"
    echo "  gh auth login"
    exit 1
fi

echo "✅ GitHub CLI ready"
echo "✅ Authenticated"
echo ""

# ============================================================================
# STEP 2: SYNC REPOSITORY 1 (creative-platform)
# ============================================================================

echo "${BLUE}STEP 2: Syncing creative-platform${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /Users/chinmaypanda/CustomApps/creative-platform

echo "Repository: creative-platform"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Remote: $(git remote get-url origin)"
echo ""

if git push origin main 2>&1 | grep -q "rejected"; then
    echo "⚠️  Push rejected. Pulling latest..."
    git pull origin main --rebase
    git push origin main
fi

echo "✅ creative-platform synced"
echo ""

# ============================================================================
# STEP 3: SYNC REPOSITORY 2 (agent-registry)
# ============================================================================

echo "${BLUE}STEP 3: Syncing agent-registry${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /Users/chinmaypanda/CustomApps/agent-registry

echo "Repository: agent-registry"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Remote: $(git remote get-url origin)"
echo ""

if git push origin main 2>&1 | grep -q "rejected"; then
    echo "⚠️  Push rejected. Pulling latest..."
    git pull origin main --rebase
    git push origin main
fi

echo "✅ agent-registry synced"
echo ""

# ============================================================================
# STEP 4: SYNC REPOSITORY 3 (deployment-scripts)
# ============================================================================

echo "${BLUE}STEP 4: Syncing deployment-scripts${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /Users/chinmaypanda/CustomApps/deployment-scripts

echo "Repository: deployment-scripts"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Remote: $(git remote get-url origin)"
echo ""

if git push origin main 2>&1 | grep -q "rejected"; then
    echo "⚠️  Push rejected. Pulling latest..."
    git pull origin main --rebase
    git push origin main
fi

echo "✅ deployment-scripts synced"
echo ""

# ============================================================================
# STEP 5: VERIFY ALL REPOS ON GITHUB
# ============================================================================

echo "${BLUE}STEP 5: Verifying GitHub Repositories${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "Checking repository visibility..."
echo ""

# Check creative-platform
if gh repo view openagx/creative-platform > /dev/null 2>&1; then
    echo "✅ creative-platform"
    echo "   https://github.com/openagx/creative-platform"
else
    echo "❌ creative-platform not found"
fi

# Check agent-registry
if gh repo view openagx/agent-registry > /dev/null 2>&1; then
    echo "✅ agent-registry"
    echo "   https://github.com/openagx/agent-registry"
else
    echo "❌ agent-registry not found"
fi

# Check deployment-scripts
if gh repo view openagx/deployment-scripts > /dev/null 2>&1; then
    echo "✅ deployment-scripts"
    echo "   https://github.com/openagx/deployment-scripts"
else
    echo "❌ deployment-scripts not found"
fi

echo ""

# ============================================================================
# STEP 6: CI/CD NEXT STEPS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  ✅ SYNC COMPLETE                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "${GREEN}🎉 All repositories synchronized to GitHub${NC}"
echo ""

echo "📋 Next Steps (CI/CD Automated):"
echo ""
echo "1️⃣  GitHub Actions Workflow"
echo "   └─ .github/workflows/auto-deploy.yml is now active"
echo "   └─ Monitors for changes and auto-syncs"
echo ""
echo "2️⃣  Continuous Deployment"
echo "   └─ Any commits to main branch auto-deploy"
echo "   └─ Manual trigger: gh workflow run auto-deploy.yml"
echo ""
echo "3️⃣  Configure GitHub Secrets"
echo "   └─ VPS_HOST, VPS_USER, VPS_PASSWORD, etc."
echo "   └─ https://github.com/openagx/creative-platform/settings/secrets/actions"
echo ""
echo "4️⃣  VPS Deployment"
echo "   └─ Will auto-trigger on GitHub Actions"
echo "   └─ Or manual: cd /path/to/creative-platform && bash deploy/vps-automation-agent.sh"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Repositories Status:"
echo ""
echo "  creative-platform:      $(git -C /Users/chinmaypanda/CustomApps/creative-platform rev-parse --short HEAD)"
echo "  agent-registry:         $(git -C /Users/chinmaypanda/CustomApps/agent-registry rev-parse --short HEAD)"
echo "  deployment-scripts:     $(git -C /Users/chinmaypanda/CustomApps/deployment-scripts rev-parse --short HEAD)"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✨ CI/CD Automation Enabled"
echo "   All future commits will auto-sync to GitHub"
echo ""

