#!/bin/bash
set -euo pipefail

echo "Installing OpenAI Codex CLI..."

if ! command -v bun &> /dev/null; then
    echo "Bun is required. Run the bun step first."
    exit 1
fi

if command -v codex &> /dev/null; then
    echo "codex already installed: $(codex --version 2>&1 | head -1)"
    exit 0
fi

bun install -g @openai/codex

if command -v codex &> /dev/null; then
    echo ""
    echo "codex installed: $(codex --version 2>&1 | head -1)"
else
    echo ""
    echo "Install completed but codex not in PATH. Ensure ~/.bun/bin is in PATH."
fi
