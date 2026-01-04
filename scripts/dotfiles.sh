#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "══════════════════════════════════════════════════════════════"
echo "                   Dotfiles Installation"
echo "══════════════════════════════════════════════════════════════"

if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    sudo apt install -y stow
fi

echo ""
echo "Creating symlinks with GNU Stow..."

cd "$REPO_DIR"

mkdir -p ~/.config
mkdir -p ~/.ssh
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh

if [[ -f ~/.zshrc ]] && [[ ! -L ~/.zshrc ]]; then
    echo "Backing up existing .zshrc to .zshrc.backup"
    mv ~/.zshrc ~/.zshrc.backup
fi

if [[ -f ~/.tmux.conf ]] && [[ ! -L ~/.tmux.conf ]]; then
    echo "Backing up existing .tmux.conf to .tmux.conf.backup"
    mv ~/.tmux.conf ~/.tmux.conf.backup
fi

stow -v -R -t ~ home

echo ""
echo "Configuring git user (if not set)..."
if ! git config --global user.email &> /dev/null; then
    read -p "Enter your git email: " git_email
    git config --global user.email "$git_email"
fi
if ! git config --global user.name &> /dev/null; then
    read -p "Enter your git name: " git_name
    git config --global user.name "$git_name"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "                 Dotfiles Installation Complete"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Symlinked configurations:"
echo "  ✓ ~/.zshrc"
echo "  ✓ ~/.tmux.conf"
echo "  ✓ ~/.gitconfig"
echo "  ✓ ~/.config/environment"
echo ""
echo "To apply changes: source ~/.zshrc"
echo ""
