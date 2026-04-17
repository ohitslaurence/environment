#!/bin/bash
set -euo pipefail

echo "Authenticating GitHub CLI..."

if ! command -v gh &> /dev/null; then
    echo "gh not installed. Run base_packages step first."
    exit 1
fi

if gh auth status &> /dev/null; then
    echo ""
    gh auth status
    echo ""
    if ! gum confirm "Already authenticated. Re-authenticate?"; then
        echo "Skipping."
        exit 0
    fi
fi

echo ""
echo "Opening browser flow. Pick HTTPS protocol and request 'admin:public_key' scope"
echo "so the github_ssh step can upload your key automatically."
echo ""

gh auth login --web --hostname github.com --git-protocol https --scopes "admin:public_key,gist,read:org,repo,workflow"

echo ""
gh auth status
