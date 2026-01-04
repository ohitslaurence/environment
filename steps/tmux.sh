#!/bin/bash
set -euo pipefail

echo "Setting up tmux..."

if ! command -v tmux &> /dev/null; then
    sudo apt install -y tmux
fi

echo "Installing tmux plugin manager (TPM)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM already installed"
fi

echo ""
echo "tmux installed"
echo ""
echo "After dotfiles are installed, start tmux and press prefix + I to install plugins"
