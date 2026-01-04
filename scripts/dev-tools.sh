#!/bin/bash
set -euo pipefail

echo "══════════════════════════════════════════════════════════════"
echo "              Development Tools Installation"
echo "══════════════════════════════════════════════════════════════"

echo ""
echo "[1/7] Installing base development packages..."
sudo apt update
sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    zsh \
    tmux \
    stow \
    unzip \
    jq \
    ripgrep \
    fd-find \
    htop \
    neovim

echo ""
echo "[2/7] Installing fnm (Fast Node Manager)..."
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
echo "[3/7] Installing Node.js LTS via fnm..."
fnm install --lts
fnm use lts-latest
fnm default lts-latest
echo "Node $(node --version) installed"

echo ""
echo "[4/7] Installing Bun..."
if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
else
    echo "Bun already installed: $(bun --version)"
fi

echo ""
echo "[5/7] Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
else
    echo "pnpm already installed: $(pnpm --version)"
fi

echo ""
echo "[6/7] Installing Claude Code..."
if ! command -v claude &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
    echo "Claude Code installed"
else
    echo "Claude Code already installed"
fi

echo ""
echo "[7/7] Installing tmux plugin manager (tpm)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "TPM installed. Press prefix + I in tmux to install plugins."
else
    echo "TPM already installed"
fi

echo ""
echo "[+] Setting zsh as default shell..."
if [[ "$SHELL" != *"zsh"* ]]; then
    chsh -s "$(which zsh)"
    echo "Default shell changed to zsh. Log out and back in for it to take effect."
else
    echo "zsh is already the default shell"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "             Development Tools Installation Complete"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Installed:"
echo "  ✓ fnm (Fast Node Manager)"
echo "  ✓ Node.js LTS"
echo "  ✓ Bun"
echo "  ✓ pnpm"
echo "  ✓ Claude Code"
echo "  ✓ tmux + TPM"
echo "  ✓ zsh"
echo "  ✓ neovim, ripgrep, fd, htop, jq"
echo ""
echo "After logging back in, run these in tmux:"
echo "  1. Press: prefix + I (to install tmux plugins)"
echo "  2. Run: claude (to start Claude Code)"
echo ""
