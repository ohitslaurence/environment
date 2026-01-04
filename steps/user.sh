#!/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "                    User Setup"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Current user: $USER (EUID: $EUID)"
echo ""

if [[ $EUID -eq 0 ]]; then
    echo "⚠ Running as root - you should create a regular sudo user."
    echo ""
    echo "Running as root directly is not recommended because:"
    echo "  • No accident prevention (every command is privileged)"
    echo "  • Tailscale SSH works better with regular users"
    echo "  • Follows security best practices"
    echo ""

    if gum confirm "Create a new sudo user now?"; then
        echo ""
        USERNAME=$(gum input --placeholder "Enter username" --header "New username:")

        if [[ -z "$USERNAME" ]]; then
            echo "No username provided. Exiting."
            exit 1
        fi

        if id "$USERNAME" &>/dev/null; then
            echo "User '$USERNAME' already exists."
            if ! groups "$USERNAME" | grep -q sudo; then
                echo "Adding $USERNAME to sudo group..."
                usermod -aG sudo "$USERNAME"
            fi
        else
            echo ""
            echo "Creating user '$USERNAME'..."
            echo "You'll be prompted to set a password."
            echo ""
            adduser "$USERNAME"
            usermod -aG sudo "$USERNAME"
            echo ""
            echo "User '$USERNAME' created and added to sudo group."
        fi

        # Copy environment repo to new user
        if [[ -d "/root/dev/environment" ]]; then
            echo ""
            echo "Copying environment repo to /home/$USERNAME/dev..."
            mkdir -p "/home/$USERNAME/dev"
            cp -r /root/dev/environment "/home/$USERNAME/dev/"
            chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/dev"
            echo "Done."
        fi

        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "                    User Created!"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Now switch to the new user and re-run setup:"
        echo ""
        echo "  su - $USERNAME"
        echo "  cd ~/dev/environment"
        echo "  ./setup"
        echo ""
        echo "Exiting now. Run the commands above to continue."
        echo ""
        exit 1  # Exit with error so the step isn't marked complete
    else
        echo ""
        echo "Skipping user creation. Continuing as root..."
        echo ""
        echo "⚠ This is not recommended for production use."
        echo ""
    fi
else
    # Running as non-root user
    if sudo -n true 2>/dev/null; then
        echo "✓ Running as '$USER' with sudo privileges"
        echo ""
        echo "User setup looks good!"
    else
        echo "Running as: $USER"
        echo ""
        echo "⚠ WARNING: This user may not have sudo privileges."
        echo "Some steps may fail without sudo access."
        echo ""
        if ! gum confirm "Continue anyway?"; then
            exit 1
        fi
    fi
fi
