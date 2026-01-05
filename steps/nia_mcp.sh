#!/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════════"
echo "                    Nia MCP Server Setup"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Nia provides AI-powered tools via MCP (Model Context Protocol)."
echo "This step will configure Nia for both Claude Code and OpenCode."
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

# Configure Claude Code
echo ""
echo "Configuring Claude Code MCP..."
if command -v claude &> /dev/null; then
    # Remove existing if present
    claude mcp remove nia 2>/dev/null || true

    # Add with the API key (Claude reads from env var at runtime)
    claude mcp add --transport http nia "https://apigcp.trynia.ai/mcp" \
        --header "Authorization: Bearer $NIA_API_KEY"

    echo "Claude Code: Nia MCP configured"
else
    echo "Claude Code not installed, skipping..."
fi

# OpenCode config - ensure stow has run
echo ""
echo "Configuring OpenCode..."
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"

if [[ -L "$OPENCODE_CONFIG" ]]; then
    echo "OpenCode: Config already symlinked via stow"
    echo "  Uses \${NIA_API_KEY} from environment"
elif [[ -f "$OPENCODE_CONFIG" ]]; then
    echo "OpenCode: Config exists (not managed by stow)"
    echo "  You may need to manually add Nia MCP config"
else
    echo "OpenCode: Running stow to create config symlink..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cd "$SCRIPT_DIR" && stow -t ~ home
    echo "OpenCode: Config symlinked"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "                         Setup Complete"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Nia MCP has been configured for:"
echo "  - Claude Code (run 'claude mcp list' to verify)"
echo "  - OpenCode (uses \${NIA_API_KEY} from environment)"
echo ""
echo "API key stored in ~/.zshrc.local (not committed to git)"
echo "Config files are version controlled (use env var for secrets)"
echo ""
echo "Run 'source ~/.zshrc' to load the API key in your current shell."
