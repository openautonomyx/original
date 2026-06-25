#!/bin/bash

# Simple HTTP Script Server
# Serves deployment scripts via HTTP for easy access from anywhere

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         OpenAGX Script Server (HTTP)                       ║"
echo "║         Serving Deployment Scripts                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Get local IP
IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')

if [ -z "$IP" ]; then
    IP="localhost"
fi

PORT=${1:-8000}

echo "📍 Server Location: /Users/chinmaypanda/CustomApps/deployment-scripts"
echo "🌐 URL: http://$IP:$PORT"
echo "📦 Port: $PORT"
echo ""

echo "Available Scripts:"
echo "  ✅ http://$IP:$PORT/GITHUB-OAUTH-DEPLOY.sh"
echo "  ✅ http://$IP:$PORT/READY-TO-PUSH.sh"
echo "  ✅ http://$IP:$PORT/SETUP-REGISTRY.sh"
echo "  ✅ http://$IP:$PORT/push-to-github.sh"
echo ""

echo "Available Guides:"
echo "  📖 http://$IP:$PORT/MASTER-DEPLOYMENT-GUIDE.md"
echo "  📖 http://$IP:$PORT/DEPLOYMENT-CHECKLIST.md"
echo "  📖 http://$IP:$PORT/README.md"
echo ""

echo "Quick Commands:"
echo "  # Download and run OAuth script:"
echo "  curl -s http://$IP:$PORT/GITHUB-OAUTH-DEPLOY.sh | bash"
echo ""
echo "  # Download guide:"
echo "  curl -s http://$IP:$PORT/MASTER-DEPLOYMENT-GUIDE.md | less"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "🚀 Starting Server (Press Ctrl+C to stop)"
echo "════════════════════════════════════════════════════════════"
echo ""

python3 -m http.server $PORT --bind 0.0.0.0

