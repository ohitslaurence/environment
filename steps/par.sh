#!/bin/bash
set -euo pipefail

echo "Installing Par (parallel worktree & session manager)..."

if command -v par &> /dev/null; then
    echo "Par already installed: $(par --version 2>/dev/null || echo 'installed')"
    exit 0
fi

if ! command -v uv &> /dev/null; then
    echo "uv not found. Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

uv tool install par-cli

if command -v par &> /dev/null; then
    echo ""
    echo "Par installed successfully!"
    echo ""
    echo "Commands:"
    echo "  par start <label>       Create worktree + tmux session"
    echo "  par checkout <ref>      Checkout branch/PR into worktree"
    echo "  par ls                  List all sessions & workspaces"
    echo "  par open <label>        Attach to session"
    echo "  par send <label> <cmd>  Send command to session"
    echo "  par rm <label>          Clean up session"
    echo "  par control-center      View all sessions"
else
    echo ""
    echo "Install completed but par not in PATH."
    echo "Ensure ~/.local/bin is in PATH or restart shell."
fi
