#!/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════════"
echo "                    Nia MCP Server Setup"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Nia provides AI-powered tools via MCP (Model Context Protocol)."
echo "This step configures Nia for both Claude Code and OpenCode."
echo ""
echo "You'll need a Nia API key from: https://trynia.ai"
echo ""

# Check if already configured
if grep -q "NIA_API_KEY" ~/.zshrc.local 2>/dev/null; then
    echo "NIA_API_KEY already exists in ~/.zshrc.local"
    if ! gum confirm "Reconfigure Nia MCP?"; then
        echo "Skipping Nia setup."
        exit 0
    fi
fi

# Prompt for API key
NIA_KEY=$(gum input --placeholder "Enter your Nia API key" --password)

if [[ -z "$NIA_KEY" ]]; then
    echo "No API key provided. Skipping Nia setup."
    exit 0
fi

# Save to .zshrc.local
echo ""
echo "Saving API key to ~/.zshrc.local..."
touch ~/.zshrc.local
if grep -q "NIA_API_KEY" ~/.zshrc.local 2>/dev/null; then
    # Update existing
    sed -i "s|export NIA_API_KEY=.*|export NIA_API_KEY=\"$NIA_KEY\"|" ~/.zshrc.local
else
    # Add new
    echo "" >> ~/.zshrc.local
    echo "# Nia API Key" >> ~/.zshrc.local
    echo "export NIA_API_KEY=\"$NIA_KEY\"" >> ~/.zshrc.local
fi

# Export for current session
export NIA_API_KEY="$NIA_KEY"

# Ensure stow has created the config symlinks
echo ""
echo "Setting up config files via stow..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Remove any non-symlink configs that would conflict
if [[ -f "$HOME/.mcp.json" ]] && [[ ! -L "$HOME/.mcp.json" ]]; then
    rm "$HOME/.mcp.json"
fi
if [[ -f "$HOME/.config/opencode/opencode.json" ]] && [[ ! -L "$HOME/.config/opencode/opencode.json" ]]; then
    rm "$HOME/.config/opencode/opencode.json"
fi

cd "$SCRIPT_DIR" && stow -t ~ home

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "                         Setup Complete"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Nia MCP configured for:"
echo "  - Claude Code (via ~/.mcp.json symlink)"
echo "  - OpenCode (via ~/.config/opencode/opencode.json symlink)"
echo ""
echo "Both configs use \${NIA_API_KEY} from your environment."
echo "API key stored in ~/.zshrc.local (not committed to git)"
echo ""
echo "Run 'source ~/.zshrc' to load the API key, then verify with:"
echo "  claude mcp list"
echo "  opencode"
