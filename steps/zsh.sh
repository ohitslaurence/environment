#!/bin/bash
set -euo pipefail

echo "Setting up zsh..."

if ! command -v zsh &> /dev/null; then
    sudo apt install -y zsh
fi

if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    echo "Shell changed. Log out and back in for it to take effect."
else
    echo "zsh is already the default shell"
fi
