#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing dotfiles..."

if ! command -v stow &> /dev/null; then
    sudo apt install -y stow
fi

cd "$REPO_DIR"

mkdir -p ~/.config
mkdir -p ~/.ssh
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh

# Backup existing files
if [[ -f ~/.zshrc ]] && [[ ! -L ~/.zshrc ]]; then
    echo "Backing up ~/.zshrc to ~/.zshrc.backup"
    mv ~/.zshrc ~/.zshrc.backup
fi

if [[ -f ~/.tmux.conf ]] && [[ ! -L ~/.tmux.conf ]]; then
    echo "Backing up ~/.tmux.conf to ~/.tmux.conf.backup"
    mv ~/.tmux.conf ~/.tmux.conf.backup
fi

if [[ -f ~/.gitconfig ]] && [[ ! -L ~/.gitconfig ]]; then
    echo "Backing up ~/.gitconfig to ~/.gitconfig.backup"
    mv ~/.gitconfig ~/.gitconfig.backup
fi

# Stow dotfiles
stow -v -R -t ~ home

echo ""
echo "Configuring git user..."
if ! git config --global user.email &> /dev/null; then
    GIT_EMAIL=$(gum input --placeholder "Enter your git email")
    git config --global user.email "$GIT_EMAIL"
fi
if ! git config --global user.name &> /dev/null; then
    GIT_NAME=$(gum input --placeholder "Enter your git name")
    git config --global user.name "$GIT_NAME"
fi

echo ""
echo "Dotfiles installed:"
echo "  ~/.zshrc"
echo "  ~/.tmux.conf"
echo "  ~/.gitconfig"
echo "  ~/.ssh/config"
echo ""
echo "Run 'source ~/.zshrc' or log out/in to apply."
