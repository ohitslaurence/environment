#!/bin/bash
set -euo pipefail

SSH_KEY="$HOME/.ssh/id_ed25519"

echo "Setting up SSH key for GitHub..."

if [[ -f "$SSH_KEY" ]]; then
    echo ""
    echo "SSH key already exists at $SSH_KEY"
    if ! gum confirm "Generate a new key?"; then
        echo ""
        echo "Using existing key."
    else
        rm -f "$SSH_KEY" "$SSH_KEY.pub"
    fi
fi

if [[ ! -f "$SSH_KEY" ]]; then
    echo ""
    EMAIL=$(gum input --placeholder "GitHub email" --prompt "Email: ")

    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""

    echo ""
    echo "SSH key generated!"
fi

# Start ssh-agent and add key
eval "$(ssh-agent -s)" > /dev/null
ssh-add "$SSH_KEY" 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Your public SSH key:                                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
cat "$SSH_KEY.pub"
echo ""

# Check if gh is installed and authenticated
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        echo ""
        if gum confirm "Add this key to GitHub automatically via gh CLI?"; then
            HOSTNAME=$(hostname)
            gh ssh-key add "$SSH_KEY.pub" --title "VPS ($HOSTNAME)"
            echo ""
            echo "SSH key added to GitHub!"
            echo ""
            echo "Test with: ssh -T git@github.com"
            exit 0
        fi
    fi
fi

echo ""
echo "Add this key to GitHub manually:"
echo "  1. Go to https://github.com/settings/ssh/new"
echo "  2. Paste the key above"
echo "  3. Give it a name like 'VPS'"
echo ""
echo "Then test with: ssh -T git@github.com"
