#!/bin/bash
set -euo pipefail

echo "Checking SSH daemon status..."

if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    echo ""
    echo "OpenSSH is currently running."
    echo "With Tailscale SSH, OpenSSH is not needed and disabling it reduces attack surface."
    echo ""

    if gum confirm "Disable OpenSSH daemon?"; then
        sudo systemctl stop sshd 2>/dev/null || sudo systemctl stop ssh 2>/dev/null || true
        sudo systemctl disable sshd 2>/dev/null || sudo systemctl disable ssh 2>/dev/null || true
        echo "OpenSSH disabled. All SSH access is now via Tailscale only."
    else
        echo "OpenSSH left running. You can disable later with:"
        echo "  sudo systemctl disable --now sshd"
        exit 1
    fi
else
    echo "OpenSSH is already disabled."
fi
