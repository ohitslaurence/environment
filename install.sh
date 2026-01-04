#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Remote Development Environment Setup - Ubuntu 24        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run this script as root. Run as your regular user."
    exit 1
fi

if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "Warning: This script is designed for Ubuntu. Proceed with caution."
fi

show_help() {
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all           Run complete setup (security + dev tools + dotfiles)"
    echo "  --security      Run security setup only (Tailscale, UFW, SSH hardening)"
    echo "  --dev           Install development tools only (Node, Bun, Claude Code)"
    echo "  --dotfiles      Install dotfiles only (tmux, zsh, git configs)"
    echo "  --analyze       Run security analysis only"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./install.sh --all        # Fresh server setup"
    echo "  ./install.sh --dotfiles   # Update configs only"
}

run_security() {
    echo "→ Running security setup..."
    bash "$SCRIPT_DIR/scripts/security.sh"
}

run_dev_tools() {
    echo "→ Installing development tools..."
    bash "$SCRIPT_DIR/scripts/dev-tools.sh"
}

run_dotfiles() {
    echo "→ Installing dotfiles..."
    bash "$SCRIPT_DIR/scripts/dotfiles.sh"
}

run_analyze() {
    echo "→ Running security analysis..."
    bash "$SCRIPT_DIR/scripts/analyze.sh"
}

if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

case "${1:-}" in
    --all)
        run_security
        run_dev_tools
        run_dotfiles
        run_analyze
        echo ""
        echo "✓ Complete setup finished!"
        echo ""
        echo "Next steps:"
        echo "  1. Log out and log back in (or run: source ~/.zshrc)"
        echo "  2. Start a tmux session: tmux new -s dev"
        echo "  3. Run 'claude' to start Claude Code"
        ;;
    --security)
        run_security
        ;;
    --dev)
        run_dev_tools
        ;;
    --dotfiles)
        run_dotfiles
        ;;
    --analyze)
        run_analyze
        ;;
    --help)
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
