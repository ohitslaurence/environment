#!/bin/bash
set -euo pipefail

echo "Installing OpenCode..."

if ! command -v opencode &> /dev/null; then
    curl -fsSL https://opencode.ai/install | bash

    # Ensure PATH is updated for current session
    export PATH="$HOME/.local/bin:$PATH"
fi

echo ""
echo "OpenCode installed!"
echo ""
echo "Run 'source ~/.zshrc' or open a new terminal, then run 'opencode'"
