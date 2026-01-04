#!/bin/bash
set -euo pipefail

echo "Installing base packages..."

sudo apt update

sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    unzip \
    jq \
    ripgrep \
    fd-find \
    htop \
    neovim \
    stow \
    unattended-upgrades \
    apt-listchanges

echo ""
echo "Enabling automatic security updates..."
sudo dpkg-reconfigure -plow unattended-upgrades

echo ""
echo "Base packages installed."
