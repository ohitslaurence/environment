#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing dotfiles..."

if ! command -v stow &> /dev/null; then
    sudo apt install -y stow
fi

# Ensure gnupg is installed for commit signing
if ! command -v gpg &> /dev/null; then
    sudo apt install -y gnupg
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
echo "═══════════════════════════════════════════════════════════"
echo "                    Git Configuration"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Configure git user
if ! git config --global user.email &> /dev/null; then
    GIT_EMAIL=$(gum input --placeholder "Enter your git email")
    git config --global user.email "$GIT_EMAIL"
else
    GIT_EMAIL=$(git config --global user.email)
    echo "Git email: $GIT_EMAIL"
fi

if ! git config --global user.name &> /dev/null; then
    GIT_NAME=$(gum input --placeholder "Enter your git name")
    git config --global user.name "$GIT_NAME"
else
    GIT_NAME=$(git config --global user.name)
    echo "Git name: $GIT_NAME"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                  GPG Commit Signing"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check for existing GPG key
EXISTING_KEY=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -A 1 "sec" | grep -oP "(?<=/)[A-F0-9]{16}" | head -1 || true)

if [[ -n "$EXISTING_KEY" ]]; then
    echo "Found existing GPG key: $EXISTING_KEY"
    if gum confirm "Use this key for git commit signing?"; then
        GPG_KEY="$EXISTING_KEY"
    else
        EXISTING_KEY=""
    fi
fi

if [[ -z "$EXISTING_KEY" ]]; then
    echo ""
    echo "No GPG key found. Let's create one."
    echo ""

    # Generate GPG key
    GPG_EMAIL=$(git config --global user.email)
    GPG_NAME=$(git config --global user.name)

    echo "Generating GPG key for: $GPG_NAME <$GPG_EMAIL>"
    echo ""

    # Create key using batch mode for non-interactive generation
    gpg --batch --gen-key <<EOF
Key-Type: ed25519
Key-Usage: sign
Subkey-Type: cv25519
Subkey-Usage: encrypt
Name-Real: $GPG_NAME
Name-Email: $GPG_EMAIL
Expire-Date: 0
%commit
EOF

    # Get the new key ID
    GPG_KEY=$(gpg --list-secret-keys --keyid-format LONG "$GPG_EMAIL" 2>/dev/null | grep -A 1 "sec" | grep -oP "(?<=/)[A-F0-9]{16}" | head -1)

    echo ""
    echo "GPG key generated: $GPG_KEY"
fi

# Configure git to use GPG key
git config --global user.signingkey "$GPG_KEY"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

echo ""
echo "Git configured to sign commits with key: $GPG_KEY"

# Export public key for GitHub
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                Add to GitHub/GitLab"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Add this public key to your Git provider:"
echo ""
gpg --armor --export "$GPG_KEY"
echo ""
echo "GitHub: https://github.com/settings/keys → New GPG key"
echo ""

if gum confirm "Copy public key to clipboard? (requires xclip)"; then
    if command -v xclip &> /dev/null; then
        gpg --armor --export "$GPG_KEY" | xclip -selection clipboard
        echo "Copied to clipboard!"
    else
        echo "xclip not installed. Copy manually from above."
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                    Setup Complete"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Dotfiles installed:"
echo "  ~/.zshrc"
echo "  ~/.tmux.conf"
echo "  ~/.gitconfig"
echo "  ~/.ssh/config"
echo ""
echo "Git signing enabled with GPG key: $GPG_KEY"
echo ""
echo "Run 'source ~/.zshrc' or log out/in to apply shell changes."
