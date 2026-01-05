#!/bin/bash
set -euo pipefail

echo "Installing Syncthing..."

# Install Syncthing from official repo
if ! command -v syncthing &> /dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
    sudo apt update
    sudo apt install -y syncthing
fi

echo "Syncthing $(syncthing --version | head -1)"

# Enable and start Syncthing as user service
echo ""
echo "Enabling Syncthing service for user: $USER"

# Ensure XDG_RUNTIME_DIR is set for user services
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

systemctl --user enable syncthing.service
systemctl --user start syncthing.service || echo "Note: Service may need a re-login to start properly"

# Create dev directory if it doesn't exist
mkdir -p ~/dev

# Create default .stignore
STIGNORE_FILE="$HOME/dev/.stignore"
if [[ ! -f "$STIGNORE_FILE" ]]; then
    echo "Creating default .stignore in ~/dev..."
    cat > "$STIGNORE_FILE" << 'EOF'
// Syncthing ignore patterns
// https://docs.syncthing.net/users/ignoring.html

// Package managers
**/node_modules
**/.pnpm-store
**/vendor
**/__pycache__
**/.venv
**/venv

// Build outputs
**/dist
**/build
**/.next
**/.nuxt
**/.output
**/.turbo
**/target

// Caches
**/.cache
**/.parcel-cache
**/.eslintcache
**/.tsbuildinfo

// Version control (sync via git instead)
**/.git

// IDE
**/.idea
**/.vscode/settings.json
*.swp
*.swo

// OS
.DS_Store
Thumbs.db

// Logs
*.log
**/logs

// Environment (may contain secrets)
**/.env.local
**/.env*.local

// Large files
*.zip
*.tar.gz
*.tgz
*.rar
EOF
    echo "Created $STIGNORE_FILE"
else
    echo ".stignore already exists at $STIGNORE_FILE"
fi

# Get device ID (may take a moment on first run)
DEVICE_ID=$(syncthing --device-id 2>/dev/null || echo "Run 'syncthing --device-id' after service starts")

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "                    Syncthing Installed"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "This device's ID:"
echo ""
echo "  $DEVICE_ID"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "1. Access Syncthing GUI (via SSH tunnel):"
echo "   ssh -L 8384:localhost:8384 $(whoami)@<tailscale-ip>"
echo "   Then open: http://localhost:8384"
echo ""
echo "2. On your laptop, install Syncthing and add this device"
echo ""
echo "3. Share the ~/dev folder between devices"
echo ""
echo "4. The .stignore file excludes node_modules, .git, etc."
echo ""

if gum confirm "Copy device ID to show on screen for easy copying?"; then
    echo ""
    echo "$DEVICE_ID"
    echo ""
fi
