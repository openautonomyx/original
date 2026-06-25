#!/bin/bash

# Create GitHub Gists for all deployment scripts
# Requires: GitHub CLI (gh) with authentication
# This makes scripts accessible via shareable URLs from anywhere

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Creating GitHub Gists for Deployment Scripts             ║"
echo "║  (Making them accessible from anywhere)                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found. Install with:"
    echo "   brew install gh"
    exit 1
fi

# Check authentication
if ! gh auth status > /dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub. Run:"
    echo "   gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated"
echo ""

# ============================================================================
# CREATE GIST 1: GITHUB-OAUTH-DEPLOY.sh
# ============================================================================

echo "📝 Creating Gist 1: GITHUB-OAUTH-DEPLOY.sh"
echo "   (Complete OAuth deployment script)"
echo ""

GIST_1=$(gh gist create GITHUB-OAUTH-DEPLOY.sh \
    --description "OpenAGX: Complete GitHub OAuth deployment - push both repos automatically" \
    --public 2>&1 | grep -o 'https://gist.github.com/[^ ]*' | head -1)

if [ -n "$GIST_1" ]; then
    echo "   ✅ Created: $GIST_1"
else
    echo "   ⚠️  Gist may already exist or creation failed"
fi

echo ""

# ============================================================================
# CREATE GIST 2: MASTER-DEPLOYMENT-GUIDE.md
# ============================================================================

echo "📝 Creating Gist 2: MASTER-DEPLOYMENT-GUIDE.md"
echo "   (Complete deployment instructions)"
echo ""

GIST_2=$(gh gist create MASTER-DEPLOYMENT-GUIDE.md \
    --description "OpenAGX: Complete deployment guide (55 min to live)" \
    --public 2>&1 | grep -o 'https://gist.github.com/[^ ]*' | head -1)

if [ -n "$GIST_2" ]; then
    echo "   ✅ Created: $GIST_2"
else
    echo "   ⚠️  Gist may already exist or creation failed"
fi

echo ""

# ============================================================================
# CREATE GIST 3: DEPLOYMENT-CHECKLIST.md
# ============================================================================

echo "📝 Creating Gist 3: DEPLOYMENT-CHECKLIST.md"
echo "   (Step-by-step verification checklist)"
echo ""

GIST_3=$(gh gist create DEPLOYMENT-CHECKLIST.md \
    --description "OpenAGX: 8-step deployment checklist" \
    --public 2>&1 | grep -o 'https://gist.github.com/[^ ]*' | head -1)

if [ -n "$GIST_3" ]; then
    echo "   ✅ Created: $GIST_3"
else
    echo "   ⚠️  Gist may already exist or creation failed"
fi

echo ""

# ============================================================================
# CREATE GIST 4: README.md
# ============================================================================

echo "📝 Creating Gist 4: README.md"
echo "   (Quick start guide)"
echo ""

GIST_4=$(gh gist create README.md \
    --description "OpenAGX Deployment Scripts - Quick Start" \
    --public 2>&1 | grep -o 'https://gist.github.com/[^ ]*' | head -1)

if [ -n "$GIST_4" ]; then
    echo "   ✅ Created: $GIST_4"
else
    echo "   ⚠️  Gist may already exist or creation failed"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    ✅ GISTS CREATED                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SAVE GIST URLS
# ============================================================================

echo "📝 Saving Gist URLs to file..."
echo ""

cat > gist-urls.txt << EOF
# OpenAGX Deployment Scripts - GitHub Gists
# Accessible from anywhere via these URLs

## 🚀 MAIN DEPLOYMENT SCRIPT
GitHub OAuth Deploy (START HERE):
$GIST_1/raw

## 📖 GUIDES & CHECKLISTS
Master Deployment Guide:
$GIST_2/raw

Deployment Checklist:
$GIST_3/raw

README:
$GIST_4/raw

## 🔗 HOW TO USE

### Option A: Run directly from web
curl -s $GIST_1/raw | bash

### Option B: Download and run
curl -s $GIST_1/raw > deploy.sh
bash deploy.sh

### Option C: View in browser
Visit: $GIST_1

EOF

echo "✅ Saved to: gist-urls.txt"
echo ""

# Display the URLs
echo "════════════════════════════════════════════════════════════"
echo "📋 GIST URLS (Accessible From Anywhere)"
echo "════════════════════════════════════════════════════════════"
echo ""
cat gist-urls.txt
echo ""

# ============================================================================
# CREATE QUICK SCRIPT SERVER (Optional)
# ============================================================================

echo "════════════════════════════════════════════════════════════"
echo "🌐 OPTIONAL: Run Local Script Server"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "To serve scripts locally on http://localhost:8000:"
echo ""
echo "  python3 -m http.server 8000"
echo ""
echo "Then access scripts at:"
echo "  http://localhost:8000/GITHUB-OAUTH-DEPLOY.sh"
echo "  http://localhost:8000/MASTER-DEPLOYMENT-GUIDE.md"
echo "  http://localhost:8000/DEPLOYMENT-CHECKLIST.md"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "════════════════════════════════════════════════════════════"
echo "🎉 GIST SERVER CREATED"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "✅ All scripts are now accessible via GitHub Gists"
echo "✅ URLs saved in: gist-urls.txt"
echo "✅ Public URLs - shareable with anyone"
echo "✅ Raw URLs - runnable directly: curl | bash"
echo ""
echo "Use cases:"
echo "  • Share with team members"
echo "  • Run from any machine"
echo "  • Version control via GitHub"
echo "  • Easy to update and maintain"
echo ""
echo "Quick start:"
echo "  curl -s <GIST_URL>/raw | bash"
echo ""
