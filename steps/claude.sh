#!/bin/bash
set -euo pipefail

echo "Installing Claude Code..."

# Ensure npm is available
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
fi

if ! command -v npm &> /dev/null; then
    echo "ERROR: npm not found. Run the Node.js step first."
    exit 1
fi

if ! command -v claude &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
fi

echo ""
echo "Claude Code installed"
echo ""
echo "Run 'claude' to start, or use within tmux for persistent sessions."
