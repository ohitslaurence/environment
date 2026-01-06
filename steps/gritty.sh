#!/bin/bash
set -euo pipefail

echo "Installing Gritty (AI-powered Git CLI)..."

GRITTY_DIR="$HOME/dev/personal/gritty"

if command -v gritty &> /dev/null; then
    echo "Gritty already installed: $(gritty --version 2>/dev/null || echo 'installed')"
    exit 0
fi

# Check if repo exists
if [[ ! -d "$GRITTY_DIR" ]]; then
    echo "Cloning gritty repo..."
    mkdir -p "$HOME/dev/personal"
    git clone https://github.com/ohitslaurence/gritty.git "$GRITTY_DIR"
fi

# Install
cd "$GRITTY_DIR"
echo "Running install script..."
./install.sh

# Verify
if command -v gritty &> /dev/null; then
    echo ""
    echo "Gritty installed successfully!"
    echo ""
    echo "Commands:"
    echo "  gritty commit     Generate AI commit message"
    echo "  gritty compose    Organize changes into logical commits"
    echo "  gritty pr         Create PR with AI description"
    echo "  gritty review     AI code review"
    echo "  gritty branch     Quick branch creation/switching"
    echo ""
    echo "Run 'gritty auth login' to authenticate with Anthropic API"
else
    echo ""
    echo "Install completed but gritty not in PATH."
    echo "Add ~/.local/bin to PATH or restart shell."
fi
