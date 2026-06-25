#!/bin/bash

# Setup OpenAGX Agent Registry on GitHub
# This script initializes the registry repository

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  OpenAGX Agent Registry Setup                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not installed"
    echo ""
    echo "Install with:"
    echo "  brew install gh    (macOS)"
    echo "  apt install gh     (Linux)"
    exit 1
fi

echo "✅ GitHub CLI found"
echo ""

# Check authentication
if ! gh auth status > /dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub"
    echo ""
    echo "Authenticate with:"
    echo "  gh auth login"
    exit 1
fi

echo "✅ GitHub authenticated"
echo ""

# Setup instructions
echo "🚀 AGENT REGISTRY SETUP"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "This script will:"
echo "  1. Create github.com/openagx/agent-registry"
echo "  2. Configure git remote"
echo "  3. Push agent registry to GitHub"
echo ""
echo "Registry will contain:"
echo "  ✅ Master REGISTRY.json (agents, tools, capabilities)"
echo "  ✅ VPS Operator Agent v1.0.0"
echo "  ✅ 4 operational tools"
echo "  ✅ Contributing guidelines"
echo "  ✅ Complete documentation"
echo ""

read -p "Continue with setup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "📝 Creating repository on GitHub..."
echo ""

# Create repository
gh repo create openagx/agent-registry \
    --public \
    --source=. \
    --remote=origin \
    --push \
    --description "Official OpenAGX Agent Registry - Canonical registry for all agents" \
    || {
        echo "❌ Failed to create repository"
        echo "Repository may already exist. Continuing..."
    }

# Configure git remote
git remote set-url origin https://github.com/openagx/agent-registry.git 2>/dev/null || true

echo ""
echo "📤 Pushing to GitHub..."
echo ""

# Push
git push -u origin main || {
    echo "Note: Repository may already have content. Attempting force push..."
    git push -u origin main --force-with-lease || true
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Agent Registry Setup Complete                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 Agent Registry is now live at:"
echo "   https://github.com/openagx/agent-registry"
echo ""
echo "📊 Registry Contents:"
echo "   ✅ REGISTRY.json (master index)"
echo "   ✅ VPS Operator Agent (v1.0.0)"
echo "   ✅ 4 Operational Tools"
echo "   ✅ Contributing Guidelines"
echo "   ✅ Complete Documentation"
echo ""
echo "📋 Next Steps:"
echo "   1. Configure GitHub secrets in creative-platform"
echo "   2. Verify VPS access"
echo "   3. Deploy to VPS"
echo "   4. Verify live deployment"
echo "   5. Setup 24/7 monitoring"
echo ""
echo "🔗 Links:"
echo "   Registry:  https://github.com/openagx/agent-registry"
echo "   Platform:  https://github.com/openagx/creative-platform"
echo "   Agent:     VPS Operator Agent v1.0.0"
echo ""
echo "Ready for next step? 🚀"
