#!/bin/bash
set -euo pipefail

echo "Installing Docker..."

if command -v docker &> /dev/null; then
    echo "Docker already installed: $(docker --version)"
else
    # Install Docker using official script
    curl -fsSL https://get.docker.com | sh

    # Add current user to docker group (no sudo needed for docker commands)
    sudo usermod -aG docker "$USER"

    echo ""
    echo "Docker installed: $(docker --version)"
fi

# Install Docker Compose plugin if not present
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    sudo apt install -y docker-compose-plugin
fi

echo ""
echo "Docker Compose: $(docker compose version)"

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Docker installed!                                          ║"
echo "║                                                              ║"
echo "║  NOTE: Log out and back in for group changes to take effect ║"
echo "║  Then you can run docker without sudo                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
