#!/bin/bash
set -euo pipefail

echo "Installing Worktrunk (git worktree manager)..."

if command -v wt &> /dev/null; then
    echo "Worktrunk already installed: $(wt --version)"
    exit 0
fi

# Use official installer script
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh | sh

# Add to path for current session
export PATH="$HOME/.cargo/bin:$PATH"

# Install shell integration
if command -v wt &> /dev/null; then
    echo ""
    echo "Installing shell integration..."
    wt config shell install

    echo ""
    echo "Worktrunk installed successfully!"
    echo ""
    echo "Commands:"
    echo "  wt switch -c <branch>   Create worktree + branch"
    echo "  wt switch <branch>      Switch to existing worktree"
    echo "  wt list                 Show all worktrees"
    echo "  wt merge                Merge to main + cleanup"
    echo "  wt remove               Remove worktree"
    echo ""
    echo "Restart your shell or run: source ~/.zshrc"
else
    echo "Installation may have failed - 'wt' command not found"
    exit 1
fi
