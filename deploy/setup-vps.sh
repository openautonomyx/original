#!/bin/bash
# Universal Creative Platform - VPS Deployment Setup
# AlmaLinux 9.x

set -e

echo "🚀 Starting Creative Platform VPS Deployment..."

# ============================================================================
# System Updates
# ============================================================================

echo "📦 Updating system packages..."
sudo dnf update -y
sudo dnf install -y git curl wget htop

# ============================================================================
# Docker Installation
# ============================================================================

echo "🐳 Installing Docker..."
sudo dnf config-manager --add-repo=https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker almalinux

echo "✅ Docker installed and started"

# ============================================================================
# Docker Compose
# ============================================================================

echo "📦 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "✅ Docker Compose installed"

# ============================================================================
# Git Configuration
# ============================================================================

echo "🔧 Configuring Git..."
git config --global user.email "deploy@agennext.com"
git config --global user.name "Creative Platform Deploy"

# ============================================================================
# Create Application Directory
# ============================================================================

echo "📁 Creating application directory..."
mkdir -p /home/almalinux/creative-platform
cd /home/almalinux/creative-platform

echo "✅ Setup complete! Ready for deployment."
echo ""
echo "Next steps:"
echo "1. Clone repository: git clone <repo-url> ."
echo "2. Configure .env file"
echo "3. Start services: docker-compose up -d"
echo "4. Check status: docker-compose ps"
