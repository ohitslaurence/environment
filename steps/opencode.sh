#!/bin/bash
set -euo pipefail

echo "Installing OpenCode..."

curl -fsSL https://opencode.ai/install | bash

echo ""
echo "OpenCode installed!"
echo ""
echo "Run 'opencode' to start."
