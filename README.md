# Remote Development Environment

Automated setup for a secure Ubuntu 24 VPS development environment. **Tailscale is the only way in.**

## Security Model

```
Internet ──X──> VPS (all ports blocked)
                 │
Tailnet ────────> VPS (Tailscale SSH only)
```

- **No public SSH** - OpenSSH daemon disabled
- **No open ports** - UFW blocks everything except Tailscale
- **Tailscale SSH** - Authenticate with your identity provider (Google, GitHub, etc.)
- **Zero key management** - No SSH keys needed
- **AWS SSO** - Temporary credentials, no long-lived keys on disk

## Quick Start

```bash
# On your VPS (initial SSH access required)
git clone https://github.com/YOUR_USERNAME/environment.git ~/dev/environment
cd ~/dev/environment

# Run interactive setup
./setup
```

## Interactive CLI

The `./setup` command launches an interactive menu powered by [gum](https://github.com/charmbracelet/gum):

```
╔══════════════════════════════════════════════════════════════╗
║            🖥️  VPS Environment Setup                          ║
║                                                              ║
║  Select steps to run (space to select, enter to confirm)    ║
╚══════════════════════════════════════════════════════════════╝

Current Status:

  ✓ Tailscale SSH - Secure mesh VPN access
  ✓ UFW Firewall - Lock down to Tailscale only
  ○ Disable OpenSSH - Remove traditional SSH
  ○ Base Packages - git, curl, build tools
  ...

> Run All Remaining
  Select Steps
  Run Security Analysis
  Reset State
  Exit
```

**Features:**
- **Resumable** - Progress saved to `~/.config/vps-setup/state.json`
- **Checkboxes** - See what's done (✓) vs pending (○)
- **Selective** - Run individual steps or all remaining
- **Security analysis** - Check your lockdown status anytime

## Setup Steps

| Step | Description |
|------|-------------|
| Tailscale SSH | Install Tailscale, enable SSH access |
| UFW Firewall | Lock firewall to Tailscale interface only |
| Disable OpenSSH | Remove traditional SSH (Tailscale only) |
| Base Packages | git, curl, ripgrep, neovim, etc. |
| Node.js | fnm + Node LTS + pnpm |
| Bun | Fast JavaScript runtime |
| Claude Code | AI coding assistant |
| tmux | Terminal multiplexer + plugins |
| zsh | Shell configuration |
| Dotfiles | Symlink configs via stow |
| AWS SSO | IAM Identity Center setup |

## Legacy Scripts

The old non-interactive scripts still work:

```bash
./install.sh --all        # Complete setup
./install.sh --security   # Security only
./install.sh --dev        # Dev tools only
./install.sh --dotfiles   # Configs only
./install.sh --analyze    # Security analysis
```

## Connecting After Setup

From any device on your Tailnet:

```bash
ssh username@100.x.x.x          # By Tailscale IP
ssh username@vps-hostname       # By hostname (MagicDNS)
```

No SSH keys needed.

## Persistent Claude Sessions

```bash
# Create named session
tmux new -s claude

# Start Claude
claude

# Detach (keeps running): Ctrl-a d

# Reconnect later
tmux attach -t claude
```

## tmux Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl-a` | Prefix |
| `Ctrl-a c` | New window |
| `Ctrl-a \|` | Split vertical |
| `Ctrl-a -` | Split horizontal |
| `Ctrl-a h/j/k/l` | Navigate panes |
| `Ctrl-a d` | Detach |
| `Ctrl-a I` | Install plugins |

## AWS SSO Usage

After setup:

```bash
# Login (opens browser)
aws sso login

# Use AWS CLI normally
aws s3 ls

# Credentials auto-expire (typically 1-12 hours)
# Re-login when expired
aws sso login
```

## Security Checklist

Run `./setup` → "Run Security Analysis":

```
✓ Tailscale running with SSH enabled
✓ UFW active, only tailscale0 allowed
✓ OpenSSH daemon disabled
✓ Automatic security updates enabled
✓ No ports open to public internet

Score: 5 / 5
EXCELLENT - Server is fully locked down to Tailscale only
```

## Directory Structure

```
~/dev/environment/
├── setup                 # Interactive CLI (start here)
├── install.sh            # Legacy non-interactive script
├── steps/                # Individual setup steps
│   ├── tailscale.sh
│   ├── ufw.sh
│   ├── disable_ssh.sh
│   ├── base_packages.sh
│   ├── node.sh
│   ├── bun.sh
│   ├── claude.sh
│   ├── tmux.sh
│   ├── zsh.sh
│   ├── dotfiles.sh
│   └── aws_sso.sh
├── scripts/              # Utility scripts
│   └── analyze.sh
└── home/                 # Dotfiles (stow managed)
    ├── .tmux.conf
    ├── .zshrc
    ├── .gitconfig
    └── .ssh/config
```

## State File

Progress is saved to `~/.config/vps-setup/state.json`:

```json
{
  "tailscale": true,
  "ufw": true,
  "disable_ssh": false,
  "base_packages": true,
  ...
}
```

Reset with `./setup` → "Reset State" or delete the file.

## Emergency Access

If you lose Tailscale access:
1. Use VPS provider's console/VNC access
2. Run `sudo tailscale up --ssh` to reconnect
3. Or temporarily enable OpenSSH: `sudo systemctl start sshd`

## Managing Access

Control who can SSH via Tailscale admin:
https://login.tailscale.com/admin/machines
