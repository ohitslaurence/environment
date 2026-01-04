#!/bin/bash
set -euo pipefail

echo "Setting up AWS IAM Identity Center (SSO)..."
echo ""

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI v2..."

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
fi

echo "AWS CLI $(aws --version | cut -d' ' -f1 | cut -d'/' -f2) installed"
echo ""

gum style \
    --border normal \
    --padding "1 2" \
    --border-foreground 212 \
    "AWS IAM Identity Center Setup" \
    "" \
    "You'll need:" \
    "  • Your SSO start URL (e.g., https://mycompany.awsapps.com/start)" \
    "  • Your SSO region (e.g., us-east-1)" \
    "" \
    "Get these from your AWS admin or IAM Identity Center console"

echo ""

if gum confirm "Do you have your SSO details ready?"; then
    SSO_URL=$(gum input --placeholder "SSO Start URL (https://xxx.awsapps.com/start)")
    SSO_REGION=$(gum input --placeholder "SSO Region (e.g., us-east-1)" --value "us-east-1")
    PROFILE_NAME=$(gum input --placeholder "Profile name" --value "default")

    echo ""
    echo "Configuring AWS SSO..."

    # Configure SSO
    aws configure sso \
        --profile "$PROFILE_NAME" \
        --sso-session "sso-session" \
        --sso-start-url "$SSO_URL" \
        --sso-region "$SSO_REGION" \
        --sso-registration-scopes "sso:account:access"

    echo ""
    gum style --foreground 212 "AWS SSO configured!"
    echo ""
    echo "To login, run:"
    echo "  aws sso login --profile $PROFILE_NAME"
    echo ""
    echo "Credentials are temporary and will auto-expire."
    echo "Re-run 'aws sso login' when they expire."

else
    echo ""
    echo "Skipping SSO configuration."
    echo ""
    echo "When ready, run:"
    echo "  aws configure sso"
    echo ""
    echo "Or re-run this setup step."
    exit 1
fi
