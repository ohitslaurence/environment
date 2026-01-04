#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "══════════════════════════════════════════════════════════════"
echo "                    Security Setup"
echo "══════════════════════════════════════════════════════════════"

echo ""
echo "[1/5] Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo ""
echo "[2/5] Installing essential security packages..."
sudo apt install -y \
    unattended-upgrades \
    apt-listchanges \
    needrestart \
    libpam-tmpdir \
    apt-show-versions

echo ""
echo "[3/5] Installing and configuring Tailscale SSH..."
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

echo ""
echo "Starting Tailscale with SSH enabled..."
echo "This will open a browser for authentication."
echo ""
sudo tailscale up --ssh

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Tailscale SSH is now active!                               ║"
echo "║  Your Tailscale IP: $TAILSCALE_IP"
echo "╚══════════════════════════════════════════════════════════════╝"

echo ""
echo "[4/5] Configuring UFW (Uncomplicated Firewall)..."

sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow all traffic on Tailscale interface
sudo ufw allow in on tailscale0

# Allow loopback
sudo ufw allow in on lo

echo ""
echo "UFW configured to allow only Tailscale traffic."
echo ""
echo "WARNING: Enabling UFW will block all non-Tailscale connections."
echo "Make sure you can connect via Tailscale before proceeding!"
echo ""
echo "Test from another terminal: ssh $(whoami)@$TAILSCALE_IP"
echo ""
read -p "Have you verified Tailscale SSH works? Enable UFW now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo ufw --force enable
    sudo ufw status verbose
else
    echo "Skipping UFW enable. Run 'sudo ufw enable' after verifying Tailscale SSH."
fi

echo ""
echo "[5/5] Disabling OpenSSH (using Tailscale SSH instead)..."
echo ""
echo "Tailscale SSH replaces OpenSSH. Disabling sshd reduces attack surface."
read -p "Disable OpenSSH daemon? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo systemctl stop sshd
    sudo systemctl disable sshd
    echo "OpenSSH disabled. All SSH access is now via Tailscale only."
else
    echo "OpenSSH left running. You can disable later with:"
    echo "  sudo systemctl disable --now sshd"
fi

echo ""
echo "[+] Enabling automatic security updates..."
sudo dpkg-reconfigure -plow unattended-upgrades

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "                  Security Setup Complete"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Your server is now configured with:"
echo "  ✓ Tailscale SSH (no keys needed, uses your Tailscale identity)"
echo "  ✓ UFW firewall allowing only Tailscale traffic"
echo "  ✓ Automatic security updates"
echo ""
echo "Connect from any device on your Tailnet:"
echo "  ssh $(whoami)@$TAILSCALE_IP"
echo "  ssh $(whoami)@$(hostname)"
echo ""
echo "Manage access at: https://login.tailscale.com/admin/machines"
echo ""
