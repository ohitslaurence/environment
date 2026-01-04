#!/bin/bash
set -euo pipefail

echo "Configuring UFW firewall..."

sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Only allow Tailscale
sudo ufw allow in on tailscale0

# Allow loopback
sudo ufw allow in on lo

echo ""
echo "UFW configured to allow only Tailscale traffic."
echo ""

# Check if Tailscale is working
if tailscale status &> /dev/null; then
    TAILSCALE_IP=$(tailscale ip -4)
    echo "Tailscale is connected: $TAILSCALE_IP"
    echo ""
    echo "WARNING: Enabling UFW will block all non-Tailscale connections."
    echo ""

    if gum confirm "Enable UFW now?"; then
        sudo ufw --force enable
        sudo ufw status verbose
    else
        echo "Skipping. Run 'sudo ufw enable' when ready."
        exit 1
    fi
else
    echo "ERROR: Tailscale not connected. Run Tailscale step first."
    exit 1
fi
