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

    # Add with the API key
    claude mcp add --transport http nia "https://apigcp.trynia.ai/mcp" \
        --header "Authorization: Bearer $NIA_API_KEY"

    echo "Claude Code: Nia MCP configured"
else
    echo "Claude Code not installed, skipping..."
fi

# Configure OpenCode
echo ""
echo "Configuring OpenCode..."
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
mkdir -p "$(dirname "$OPENCODE_CONFIG")"

if [[ -f "$OPENCODE_CONFIG" ]]; then
    # Merge with existing config using jq if available
    if command -v jq &> /dev/null; then
        EXISTING=$(cat "$OPENCODE_CONFIG")
        echo "$EXISTING" | jq --arg key "$NIA_API_KEY" '.mcp.nia = {
            "type": "remote",
            "url": "https://apigcp.trynia.ai/mcp",
            "headers": {
                "Authorization": ("Bearer " + $key)
            },
            "enabled": true
        }' > "$OPENCODE_CONFIG"
    else
        echo "jq not installed - creating fresh config (existing settings may be lost)"
        cat > "$OPENCODE_CONFIG" << EOF
{
  "mcp": {
    "nia": {
      "type": "remote",
      "url": "https://apigcp.trynia.ai/mcp",
      "headers": {
        "Authorization": "Bearer $NIA_API_KEY"
      },
      "enabled": true
    }
  }
}
EOF
    fi
else
    cat > "$OPENCODE_CONFIG" << EOF
{
  "mcp": {
    "nia": {
      "type": "remote",
      "url": "https://apigcp.trynia.ai/mcp",
      "headers": {
        "Authorization": "Bearer $NIA_API_KEY"
      },
      "enabled": true
    }
  }
}
EOF
fi

echo "OpenCode: Nia MCP configured"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "                         Setup Complete"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Nia MCP has been configured for:"
echo "  - Claude Code (run 'claude mcp list' to verify)"
echo "  - OpenCode (config at $OPENCODE_CONFIG)"
echo ""
echo "API key stored in ~/.zshrc.local (not committed to git)"
echo ""
echo "Run 'source ~/.zshrc' to load the API key in your current shell."
