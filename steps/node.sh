#!/bin/bash
set -euo pipefail

echo "Installing fnm (Fast Node Manager)..."

if ! command -v fnm &> /dev/null; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

    export FNM_PATH="$HOME/.local/share/fnm"
    export PATH="$FNM_PATH:$PATH"
    eval "$(fnm env)"
else
    echo "fnm already installed"
    export FNM_PATH="$HOME/.local/share/fnm"
    export PATH="$FNM_PATH:$PATH"
    eval "$(fnm env)"
fi

echo ""
echo "Installing Node.js LTS..."
fnm install --lts
fnm use lts-latest
fnm default lts-latest

echo ""
echo "Node.js $(node --version) installed"

echo ""
echo "Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
else
    echo "pnpm already installed"
fi
