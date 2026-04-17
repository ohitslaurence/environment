#!/bin/bash
set -euo pipefail

echo "Installing gitleaks..."

if command -v gitleaks &> /dev/null; then
    echo "gitleaks already installed: $(gitleaks version 2>&1 | head -1)"
    exit 0
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ASSET_ARCH="x64" ;;
    aarch64|arm64) ASSET_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

LATEST=$(curl -fsSL https://api.github.com/repos/gitleaks/gitleaks/releases/latest \
    | grep -oP '"tag_name":\s*"\K[^"]+')
VERSION="${LATEST#v}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

URL="https://github.com/gitleaks/gitleaks/releases/download/${LATEST}/gitleaks_${VERSION}_linux_${ASSET_ARCH}.tar.gz"
echo "Downloading $URL"
curl -fsSL "$URL" | tar -xz -C "$TMP"

mkdir -p "$HOME/.local/bin"
install -m 0755 "$TMP/gitleaks" "$HOME/.local/bin/gitleaks"

echo ""
echo "gitleaks $("$HOME/.local/bin/gitleaks" version 2>&1 | head -1) installed to ~/.local/bin/gitleaks"
echo ""
echo "Quick scan example:"
echo "  gitleaks detect --source ~/dev/spritz --no-git    # working tree only"
echo "  gitleaks detect --source ~/dev/spritz/api-client  # include git history"
