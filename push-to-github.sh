#!/bin/bash

# GitHub CLI Push Script for openagx/creative-platform
# Usage: bash push-to-github.sh

set -e

echo "🚀 GitHub CLI Push Script"
echo "========================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found"
    echo ""
    echo "Install with:"
    echo "  macOS:  brew install gh"
    echo "  Linux:  apt install gh"
    echo "  Windows: choco install gh"
    exit 1
fi

echo "✅ GitHub CLI found: $(gh --version)"
echo ""

# Check if authenticated
echo "Checking GitHub authentication..."
if ! gh auth status > /dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub"
    echo ""
    echo "Please authenticate:"
    echo "  gh auth login"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Authenticated: $(gh auth status --show-token 2>/dev/null | head -1)"
echo ""

# Get current repo info
REPO_PATH=$(pwd)
REPO_NAME=$(basename "$REPO_PATH")
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "📍 Repository Info:"
echo "   Path: $REPO_PATH"
echo "   Name: $REPO_NAME"
echo "   Branch: $BRANCH"
echo ""

# Check git status
echo "📊 Git Status:"
echo "   Commits ahead: $(git rev-list --count origin/$BRANCH..HEAD 2>/dev/null || echo "unknown")"
UNCOMMITTED=$(git status --porcelain | wc -l)
echo "   Uncommitted changes: $UNCOMMITTED"
echo ""

if [ "$UNCOMMITTED" -gt 0 ]; then
    echo "⚠️  You have uncommitted changes:"
    git status --short
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

# Get target organization and repo
echo "🎯 Push Target:"
echo "   Organization: openagx"
echo "   Repository: creative-platform"
echo "   Full URL: github.com/openagx/creative-platform"
echo ""

# Confirm push
echo "📤 About to push:"
echo "   Repository: $REPO_NAME"
echo "   Branch: $BRANCH"
echo "   Target: openagx/creative-platform"
echo ""
read -p "Continue with push? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Set remote if needed
echo ""
echo "⚙️  Configuring remote..."
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

if [[ "$CURRENT_REMOTE" != *"openagx/creative-platform"* ]]; then
    echo "Setting remote to: git@github.com:openagx/creative-platform.git"
    git remote set-url origin git@github.com:openagx/creative-platform.git
else
    echo "Remote already set correctly"
fi

# Verify the repo exists and we have access
echo ""
echo "🔐 Verifying access to openagx/creative-platform..."
if ! gh repo view openagx/creative-platform > /dev/null 2>&1; then
    echo "⚠️  Repository might not exist or you don't have access"
    echo ""
    read -p "Create repository? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📝 Creating repository openagx/creative-platform..."
        gh repo create openagx/creative-platform \
            --source=. \
            --remote=origin \
            --push \
            --private \
            --description "Creative Content Publishing Platform - VPS Deployment"
        echo "✅ Repository created and code pushed!"
        exit 0
    fi
fi

# Push
echo ""
echo "📤 Pushing to GitHub..."
git push -u origin $BRANCH

# Verify push
echo ""
echo "✅ Push complete!"
echo ""
echo "🎉 Repository is now live at:"
echo "   https://github.com/openagx/creative-platform"
echo ""
echo "📊 View repository:"
gh repo view openagx/creative-platform --web || echo "Open in browser: https://github.com/openagx/creative-platform"
echo ""
echo "📋 Next steps:"
echo "   1. Verify code on GitHub"
echo "   2. Create agent-registry repository"
echo "   3. Configure GitHub secrets for CI/CD"
echo "   4. Trigger VPS deployment"
