#!/bin/bash
set -euo pipefail

echo "Installing Nia CLI..."

if ! command -v bun &> /dev/null; then
    echo "Bun is required. Run the bun step first."
    exit 1
fi

if command -v nia &> /dev/null; then
    echo "nia already installed: $(nia --version 2>&1 | head -1)"
else
    bun install -g @nozomioai/nia
fi

if command -v nia &> /dev/null; then
    echo ""
    echo "nia installed: $(nia --version 2>&1 | head -1)"
    echo ""
    echo "Authenticate with: nia auth login"
else
    echo ""
    echo "Install completed but nia not in PATH. Ensure ~/.bun/bin is in PATH."
fi
