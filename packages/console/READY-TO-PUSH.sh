#!/bin/bash

# FINAL PRE-PUSH VERIFICATION & EXECUTION
# Run this script to verify everything is ready, then push to GitHub

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  VPS OPERATOR AGENT - GITHUB PUSH READY CHECK              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_TOTAL=0

check_item() {
    local name=$1
    local result=$2

    ((CHECKS_TOTAL++))
    if [ "$result" = "pass" ]; then
        echo -e "${GREEN}✅${NC} $name"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌${NC} $name"
    fi
}

echo "🔍 PRE-PUSH VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Git Status
echo "📁 Git Repository:"
if git rev-parse --git-dir > /dev/null 2>&1; then
    check_item "Git repository initialized" "pass"
else
    check_item "Git repository initialized" "fail"
fi

# 2. Branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
    check_item "On main branch ($BRANCH)" "pass"
else
    check_item "On main branch ($BRANCH)" "fail"
fi

# 3. Uncommitted changes
UNCOMMITTED=$(git status --porcelain | wc -l)
if [ "$UNCOMMITTED" -eq 0 ]; then
    check_item "All changes committed (0 uncommitted)" "pass"
else
    check_item "All changes committed ($UNCOMMITTED uncommitted)" "fail"
fi

# 4. Agent documents
echo ""
echo "📚 Agent Documentation:"
for file in AGENT-CONSTITUTION.md AGENT-LANGUAGE.md AGENT-INSTRUCTIONS.md AGENT-HANDBOOK.md AGENT-MASTER-INDEX.md AGENT-COMPLETE-BINDING.md AGENT-REGISTRY-STRUCTURE.md; do
    if [ -f "$file" ]; then
        check_item "$file ($(wc -l < $file) lines)" "pass"
    else
        check_item "$file" "fail"
    fi
done

# 5. Push automation
echo ""
echo "🚀 Push Automation:"
if [ -f "push-to-github.sh" ]; then
    if [ -x "push-to-github.sh" ]; then
        check_item "push-to-github.sh (executable)" "pass"
    else
        check_item "push-to-github.sh (executable)" "fail"
    fi
else
    check_item "push-to-github.sh" "fail"
fi

if [ -f "GITHUB-PUSH-GUIDE.md" ]; then
    check_item "GITHUB-PUSH-GUIDE.md" "pass"
else
    check_item "GITHUB-PUSH-GUIDE.md" "fail"
fi

# 6. Tools
echo ""
echo "🔧 Operational Tools:"
if [ -f "deploy/vps-automation-agent.sh" ]; then
    check_item "VPS Automation Agent" "pass"
else
    check_item "VPS Automation Agent" "fail"
fi

if [ -f "deploy/vps-monitoring-agent.sh" ]; then
    check_item "VPS Monitoring Agent" "pass"
else
    check_item "VPS Monitoring Agent" "fail"
fi

if [ -f "deploy/vps-operator-agent.sh" ]; then
    check_item "VPS Operator Agent" "pass"
else
    check_item "VPS Operator Agent" "fail"
fi

if [ -f ".github/workflows/deploy-vps.yml" ]; then
    check_item "GitHub Actions CI/CD" "pass"
else
    check_item "GitHub Actions CI/CD" "fail"
fi

# 7. Remote
echo ""
echo "🔗 Git Remote:"
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "not set")
echo "   Remote: $REMOTE_URL"
if [[ "$REMOTE_URL" == *"openagx"* ]]; then
    check_item "Remote points to openagx" "pass"
else
    check_item "Remote points to openagx" "fail"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  VERIFICATION SUMMARY                                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "Checks passed: ${GREEN}$CHECKS_PASSED / $CHECKS_TOTAL${NC}"

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED - READY TO PUSH${NC}"
    echo ""

    # Show what will be pushed
    echo "📤 READY TO PUSH:"
    echo ""
    echo "Target:    github.com/openagx/creative-platform"
    echo "Branch:    main"
    echo "Commits:   $(git rev-list --count origin/main..HEAD 2>/dev/null || echo 'unknown')"
    echo "Files:     $(git status --porcelain | wc -l || echo 'checked')"
    echo ""

    # Show commits to be pushed
    echo "Commits to push:"
    git log --oneline -5
    echo ""

    # Ask to proceed
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  NEXT: GitHub CLI Push                                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Check if gh CLI exists
    if command -v gh &> /dev/null; then
        echo "✅ GitHub CLI found: $(gh --version | head -1)"
        echo ""

        # Check authentication
        if gh auth status > /dev/null 2>&1; then
            echo "✅ GitHub authenticated"
            echo ""
            echo "Ready to execute:"
            echo "  bash push-to-github.sh"
            echo ""

            read -p "Continue with push? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo ""
                echo "🚀 Executing push..."
                echo ""
                bash push-to-github.sh
            else
                echo "Cancelled."
                exit 0
            fi
        else
            echo "❌ GitHub CLI not authenticated"
            echo ""
            echo "Authenticate with:"
            echo "  gh auth login"
            echo ""
            echo "Then run:"
            echo "  bash push-to-github.sh"
            exit 1
        fi
    else
        echo "❌ GitHub CLI not installed"
        echo ""
        echo "Install with:"
        echo "  brew install gh    (macOS)"
        echo "  apt install gh     (Linux)"
        echo ""
        echo "Then authenticate:"
        echo "  gh auth login"
        echo ""
        echo "Then run:"
        echo "  bash push-to-github.sh"
        exit 1
    fi
else
    echo -e "${RED}❌ SOME CHECKS FAILED${NC}"
    echo ""
    echo "Fix issues above before pushing."
    exit 1
fi
