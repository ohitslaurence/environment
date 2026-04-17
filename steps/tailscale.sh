#!/bin/bash
set -euo pipefail

echo "Installing Tailscale..."

if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

CURRENT_HOSTNAME=$(hostname)
echo ""
TAILSCALE_HOSTNAME=$(gum input \
    --prompt "Tailscale hostname: " \
    --value "$CURRENT_HOSTNAME" \
    --placeholder "Name this node will appear as in your tailnet")
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-$CURRENT_HOSTNAME}"

echo ""
echo "Starting Tailscale with SSH enabled (hostname: $TAILSCALE_HOSTNAME)..."
echo "This will open a browser for authentication."
echo ""

sudo tailscale up --ssh --hostname="$TAILSCALE_HOSTNAME"

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Tailscale SSH is now active!                               ║"
echo "║  Your Tailscale IP: $TAILSCALE_IP"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Test from another device: ssh $(whoami)@$TAILSCALE_IP"
