#!/bin/bash
set -euo pipefail

echo "Installing Claude Code (native)..."

if ! command -v claude &> /dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash

    # Ensure PATH is updated for current session
    export PATH="$HOME/.local/bin:$PATH"
fi

echo ""
echo "Claude Code installed"
echo ""
echo "Run 'claude' to start, or use within tmux for persistent sessions."
