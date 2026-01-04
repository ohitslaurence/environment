#!/bin/bash
set -euo pipefail

echo "Installing base packages..."

sudo apt update

sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    unzip \
    jq \
    ripgrep \
    fd-find \
    htop \
    neovim \
    stow \
    fzf \
    direnv \
    bat \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    unattended-upgrades \
    apt-listchanges

# eza (modern ls replacement)
if ! command -v eza &> /dev/null; then
    echo ""
    echo "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
fi

# zoxide (smarter cd)
if ! command -v zoxide &> /dev/null; then
    echo ""
    echo "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# atuin (better shell history)
if ! command -v atuin &> /dev/null; then
    echo ""
    echo "Installing atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# GitHub CLI
if ! command -v gh &> /dev/null; then
    echo ""
    echo "Installing GitHub CLI..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
fi

# lazygit
if ! command -v lazygit &> /dev/null; then
    echo ""
    echo "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r '.tag_name' | sed 's/v//')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm /tmp/lazygit.tar.gz /tmp/lazygit
fi

# lazydocker
if ! command -v lazydocker &> /dev/null; then
    echo ""
    echo "Installing lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
fi

echo ""
echo "Enabling automatic security updates..."
sudo dpkg-reconfigure -plow unattended-upgrades

echo ""
echo "Base packages installed:"
echo "  Core: git, curl, wget, build-essential, unzip, jq, stow"
echo "  Search: ripgrep, fd-find, fzf"
echo "  Modern CLI: eza, bat, zoxide, atuin, direnv"
echo "  TUI: htop, neovim, lazygit, lazydocker"
echo "  GitHub: gh"
