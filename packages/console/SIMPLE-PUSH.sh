#!/bin/bash

# Simple Push to GitHub - No CLI Tools Needed
# Just uses git + OAuth (automatic browser login)

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       🚀 Simple Push to GitHub (OAuth Auto-Login)             ║"
echo "║          No CLI tools needed - Just git!                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# REPO 1: deployment-scripts
# ============================================================================

echo "${BLUE}📤 Pushing deployment-scripts${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /Users/chinmaypanda/CustomApps/deployment-scripts

echo "Repository: deployment-scripts"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Remote: $(git remote get-url origin)"
echo ""

echo "Pushing to GitHub..."
if git push -u origin main; then
    echo "${GREEN}✅ deployment-scripts pushed successfully${NC}"
    echo "   https://github.com/openagx/deployment-scripts"
else
    echo "⚠️  Push had issues. Retrying..."
    git push -u origin main --force-with-lease
    echo "${GREEN}✅ deployment-scripts pushed (force-with-lease)${NC}"
fi

echo ""
echo ""

# ============================================================================
# REPO 2: creative-platform
# ============================================================================

echo "${BLUE}📤 Pushing creative-platform${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /Users/chinmaypanda/CustomApps/creative-platform

echo "Repository: creative-platform"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Remote: $(git remote get-url origin)"
echo ""

echo "Pushing to GitHub..."
if git push -u origin main; then
    echo "${GREEN}✅ creative-platform pushed successfully${NC}"
    echo "   https://github.com/openagx/creative-platform"
else
    echo "⚠️  Push had issues. Retrying..."
    git push -u origin main --force-with-lease
    echo "${GREEN}✅ creative-platform pushed (force-with-lease)${NC}"
fi

echo ""
echo ""

# ============================================================================
# REPO 3: agent-registry
# ============================================================================

echo "${BLUE}📤 Pushing agent-registry${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /Users/chinmaypanda/CustomApps/agent-registry

echo "Repository: agent-registry"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Remote: $(git remote get-url origin)"
echo ""

echo "Pushing to GitHub..."
if git push -u origin main; then
    echo "${GREEN}✅ agent-registry pushed successfully${NC}"
    echo "   https://github.com/openagx/agent-registry"
else
    echo "⚠️  Push had issues. Retrying..."
    git push -u origin main --force-with-lease
    echo "${GREEN}✅ agent-registry pushed (force-with-lease)${NC}"
fi

echo ""
echo ""

# ============================================================================
# FINAL STATUS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  ✅ ALL REPOS PUSHED                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "${GREEN}🎉 All 3 repositories are now on GitHub!${NC}"
echo ""

echo "📋 Your GitHub Repositories:"
echo ""
echo "  1️⃣  creative-platform"
echo "      https://github.com/openagx/creative-platform"
echo ""
echo "  2️⃣  agent-registry"
echo "      https://github.com/openagx/agent-registry"
echo ""
echo "  3️⃣  deployment-scripts"
echo "      https://github.com/openagx/deployment-scripts"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "${YELLOW}📝 Next Steps:${NC}"
echo ""
echo "1. Configure GitHub Secrets (5 min)"
echo "   https://github.com/openagx/creative-platform/settings/secrets/actions"
echo ""
echo "   Add these secrets:"
echo "     • VPS_HOST=agennext.com"
echo "     • VPS_USER=almalinux"
echo "     • VPS_PASSWORD=<your-password>"
echo "     • VPS_SSH_KEY=<your-ssh-key>"
echo "     • DB_PASSWORD=<database-password>"
echo "     • JWT_SECRET=<jwt-secret>"
echo ""
echo "2. Deploy to VPS (20 min)"
echo "   cd /Users/chinmaypanda/CustomApps/creative-platform"
echo "   VPS_PASSWORD='pw' bash deploy/vps-automation-agent.sh"
echo ""
echo "3. Your platform goes LIVE! 🚀"
echo "   https://agennext.com"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "${GREEN}✨ CI/CD Automation is now active!${NC}"
echo "   Any future commits to main will auto-sync & deploy"
echo ""

