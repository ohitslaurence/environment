#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}Upgrading core tools...${NC}"
echo ""

# Track results
declare -a results=()

upgrade_tool() {
    local name="$1"
    local cmd="$2"

    echo -e "${YELLOW}→${NC} Upgrading $name..."
    if eval "$cmd" 2>&1; then
        results+=("${GREEN}✓${NC} $name")
    else
        results+=("${RED}✗${NC} $name (failed)")
    fi
    echo ""
}

# Claude Code (native install)
if command -v claude &> /dev/null; then
    upgrade_tool "Claude Code" "claude update"
else
    results+=("${YELLOW}○${NC} Claude Code (not installed)")
fi

# OpenCode
if command -v opencode &> /dev/null; then
    upgrade_tool "OpenCode" "opencode upgrade"
else
    results+=("${YELLOW}○${NC} OpenCode (not installed)")
fi

# Bun
if command -v bun &> /dev/null; then
    upgrade_tool "Bun" "bun upgrade"
else
    results+=("${YELLOW}○${NC} Bun (not installed)")
fi

# tmux plugins (if TPM is installed)
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    upgrade_tool "tmux plugins" "$HOME/.tmux/plugins/tpm/bin/update_plugins all"
else
    results+=("${YELLOW}○${NC} tmux plugins (TPM not installed)")
fi

# Summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for result in "${results[@]}"; do
    echo -e "  $result"
done
echo ""
