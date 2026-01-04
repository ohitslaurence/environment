#!/bin/bash
set -euo pipefail

echo "Installing Bun..."

if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash

    # Source for current session
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

echo ""
echo "Bun $(bun --version) installed"
