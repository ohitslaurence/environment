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

# Statusline dependency referenced in home/.claude/settings.json
if command -v npm &> /dev/null; then
    if ! npm list -g @owloops/claude-powerline &> /dev/null 2>&1; then
        echo ""
        echo "Installing claude-powerline (statusline used by .claude/settings.json)..."
        npm install -g @owloops/claude-powerline
    fi
fi

echo ""
echo "Run 'claude' to start, or use within tmux for persistent sessions."
