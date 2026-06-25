#!/bin/bash

# Push using GitHub Personal Access Token
# Usage: GITHUB_TOKEN="ghp_xxxx" bash GITHUB-TOKEN-PUSH.sh

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       🚀 Push to GitHub (Token-based Auth)                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN not set"
    echo ""
    echo "Get a token:"
    echo "  1. Go to: https://github.com/settings/tokens"
    echo "  2. Click 'Generate new token (classic)'"
    echo "  3. Select 'repo' scope"
    echo "  4. Copy token (starts with ghp_)"
    echo ""
    echo "Then run:"
    echo "  GITHUB_TOKEN='ghp_xxxxx' bash GITHUB-TOKEN-PUSH.sh"
    exit 1
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# PUSH ALL 3 REPOS
# ============================================================================

push_repo() {
    local repo_path=$1
    local repo_name=$2
    local remote_url=$3
    
    echo "${BLUE}📤 Pushing $repo_name${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    cd "$repo_path"
    
    # Set remote with token
    git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${remote_url}.git"
    
    echo "Repository: $repo_name"
    echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
    echo ""
    
    if git push -u origin main; then
        echo "${GREEN}✅ $repo_name pushed${NC}"
    else
        echo "⚠️  Retrying with force-with-lease..."
        git push -u origin main --force-with-lease
        echo "${GREEN}✅ $repo_name pushed (force-with-lease)${NC}"
    fi
    
    echo ""
    echo ""
}

# Push openautonomyx (creative-platform)
push_repo "/Users/chinmaypanda/CustomApps/creative-platform" "openautonomyx" "AGenNext/openautonomyx"

# Push agent-registry
push_repo "/Users/chinmaypanda/CustomApps/agent-registry" "agent-registry" "AGenNext/agent-registry"

# Push agent-console (deployment-scripts)
push_repo "/Users/chinmaypanda/CustomApps/deployment-scripts" "agent-console" "AGenNext/agent-console"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  ✅ ALL REPOS PUSHED                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "${GREEN}🎉 All 3 repositories pushed to AGenNext!${NC}"
echo ""
echo "📋 Your Repositories:"
echo ""
echo "  1️⃣  openautonomyx (Creative Platform)"
echo "      https://github.com/AGenNext/openautonomyx"
echo ""
echo "  2️⃣  agent-registry"
echo "      https://github.com/AGenNext/agent-registry"
echo ""
echo "  3️⃣  agent-console"
echo "      https://github.com/AGenNext/agent-console"
echo ""

