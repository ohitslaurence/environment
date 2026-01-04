#!/bin/bash
set -euo pipefail

echo "Checking user setup..."

if [[ $EUID -eq 0 ]]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    Running as root"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "You should create a regular user with sudo privileges."
    echo "Running as root directly is not recommended."
    echo ""

    if gum confirm "Create a new sudo user now?"; then
        USERNAME=$(gum input --placeholder "Enter username")

        if id "$USERNAME" &>/dev/null; then
            echo "User '$USERNAME' already exists."
            if ! groups "$USERNAME" | grep -q sudo; then
                echo "Adding $USERNAME to sudo group..."
                usermod -aG sudo "$USERNAME"
            fi
        else
            echo "Creating user '$USERNAME'..."
            adduser "$USERNAME"
            usermod -aG sudo "$USERNAME"
            echo "User '$USERNAME' created and added to sudo group."
        fi

        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "                    User Created!"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Now do the following:"
        echo ""
        echo "1. Copy environment repo to new user's home:"
        echo "   cp -r ~/dev /home/$USERNAME/"
        echo "   chown -R $USERNAME:$USERNAME /home/$USERNAME/dev"
        echo ""
        echo "2. Switch to the new user:"
        echo "   su - $USERNAME"
        echo ""
        echo "3. Re-run setup:"
        echo "   cd ~/dev/environment"
        echo "   ./setup"
        echo ""
        exit 1
    else
        echo ""
        echo "Continuing as root (not recommended)..."
        echo ""
    fi
else
    # Running as non-root user
    if sudo -n true 2>/dev/null; then
        echo "Running as: $USER (with sudo privileges)"
        echo ""
        echo "✓ User setup looks good!"
    else
        echo "Running as: $USER"
        echo ""
        echo "WARNING: This user may not have sudo privileges."
        echo "Some steps may fail without sudo access."
        echo ""
        if ! gum confirm "Continue anyway?"; then
            exit 1
        fi
    fi
fi
