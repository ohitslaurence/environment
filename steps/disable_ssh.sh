#!/bin/bash
set -euo pipefail

echo "Checking SSH daemon status..."

SSH_RUNNING=false
SOCKET_RUNNING=false

if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    SSH_RUNNING=true
fi

if systemctl is-active --quiet ssh.socket 2>/dev/null; then
    SOCKET_RUNNING=true
fi

if $SSH_RUNNING || $SOCKET_RUNNING; then
    echo ""
    echo "OpenSSH is currently active:"
    $SSH_RUNNING && echo "  - SSH service is running"
    $SOCKET_RUNNING && echo "  - SSH socket is listening on port 22"
    echo ""
    echo "With Tailscale SSH, OpenSSH is not needed and disabling it reduces attack surface."
    echo ""

    if gum confirm "Disable OpenSSH completely?"; then
        # Stop and disable the service
        sudo systemctl stop sshd 2>/dev/null || sudo systemctl stop ssh 2>/dev/null || true
        sudo systemctl disable sshd 2>/dev/null || sudo systemctl disable ssh 2>/dev/null || true

        # Also stop and disable the socket (systemd socket activation)
        sudo systemctl stop ssh.socket 2>/dev/null || true
        sudo systemctl disable ssh.socket 2>/dev/null || true

        echo ""
        echo "OpenSSH fully disabled (service + socket)."
        echo "All SSH access is now via Tailscale only."
    else
        echo "OpenSSH left running. You can disable later with:"
        echo "  sudo systemctl disable --now ssh ssh.socket"
        exit 1
    fi
else
    echo "OpenSSH is already disabled."
fi
