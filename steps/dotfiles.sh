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

# Post-stow symlinks (stow doesn't handle nested dirs in existing directories well)
mkdir -p ~/.config/opencode
ln -sf ~/.claude/CLAUDE.md ~/.config/opencode/AGENTS.md
ln -sfn ~/dev/environment/home/.claude/hooks ~/.claude/hooks

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                    Git Configuration"
echo "═══════════════════════════════════════════════════════════"
echo ""

# User-specific git config goes in .gitconfig.local (not the symlinked .gitconfig)
LOCAL_GITCONFIG="$HOME/.gitconfig.local"

# Check existing config
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")

if [[ -z "$GIT_EMAIL" ]]; then
    GIT_EMAIL=$(gum input --placeholder "Enter your git email")
else
    echo "Git email: $GIT_EMAIL"
fi

if [[ -z "$GIT_NAME" ]]; then
    GIT_NAME=$(gum input --placeholder "Enter your git name")
else
    echo "Git name: $GIT_NAME"
fi

# Write to .gitconfig.local (separate from stowed .gitconfig)
cat > "$LOCAL_GITCONFIG" << EOF
[user]
    email = $GIT_EMAIL
    name = $GIT_NAME
EOF

echo "User config written to $LOCAL_GITCONFIG"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                  GPG Commit Signing"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check for existing GPG key
EXISTING_KEY=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | awk '/^sec/ {split($2, a, "/"); print a[2]}' | head -1 || true)

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

    # Use the values we already have (from earlier in script)
    if [[ -z "$GIT_EMAIL" ]] || [[ -z "$GIT_NAME" ]]; then
        echo "Error: Git email and name are required for GPG key generation"
        echo "Please run this step again and provide your details"
        exit 1
    fi

    echo "Generating GPG key for: $GIT_NAME <$GIT_EMAIL>"
    echo ""

    # Create key using batch mode for non-interactive generation
    # Using RSA for compatibility (ed25519 not supported in batch mode on older GPG)
    gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: encrypt
Name-Real: $GIT_NAME
Name-Email: $GIT_EMAIL
Expire-Date: 0
%commit
EOF

    # Get the new key ID
    GPG_KEY=$(gpg --list-secret-keys --keyid-format LONG "$GIT_EMAIL" 2>/dev/null | awk '/^sec/ {split($2, a, "/"); print a[2]}' | head -1)

    echo ""
    echo "GPG key generated: $GPG_KEY"
fi

# Add signing key to .gitconfig.local
cat >> "$LOCAL_GITCONFIG" << EOF
    signingkey = $GPG_KEY
EOF

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

# Skip clipboard on headless servers
if [[ -n "${DISPLAY:-}" ]]; then
    if gum confirm "Copy public key to clipboard?"; then
        if command -v xclip &> /dev/null; then
            gpg --armor --export "$GPG_KEY" | xclip -selection clipboard
            echo "Copied to clipboard!"
        else
            echo "xclip not installed. Copy manually from above."
        fi
    fi
else
    echo "(Copy the key above manually - no display available)"
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
