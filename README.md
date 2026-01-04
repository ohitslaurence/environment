# Remote Development Environment

My personal setup for configuring a VPS as a secure remote development environment. The main goal: **persistent Claude Code sessions that survive disconnects**, enabling long-running AI agent workflows without tying up my laptop.

## Why?

- **Offload work from my laptop** - Let heavy AI tasks run on a VPS while I do other things
- **Persistent sessions** - SSH disconnects? No problem. tmux keeps Claude Code running
- **Decentralized project storage** - Code lives on the VPS, accessible from anywhere
- **Secure by default** - Tailscale-only access, no exposed ports, no SSH keys to manage

## Security Model

```
Internet ──X──> VPS (all ports blocked)
                 │
Tailnet ────────> VPS (Tailscale SSH only)
```

- **No public SSH** - OpenSSH disabled entirely
- **No open ports** - UFW blocks everything except Tailscale
- **Tailscale SSH** - Authenticate with your identity provider
- **AWS SSO** - Temporary credentials, nothing long-lived on disk

## Quick Start

```bash
# Optional: set a hostname (default is often "None" or random)
sudo hostnamectl set-hostname vps

git clone https://github.com/ohitslaurence/environment.git ~/dev/environment
cd ~/dev/environment
./setup
```

## Interactive Setup

The `./setup` command launches an interactive menu (powered by [gum](https://github.com/charmbracelet/gum)):

```
╔══════════════════════════════════════════════════════════════╗
║            🖥️  VPS Environment Setup                          ║
╚══════════════════════════════════════════════════════════════╝

  ✓ Tailscale SSH
  ✓ UFW Firewall
  ✓ Disable OpenSSH
  ○ Base Packages
  ○ Docker
  ...

> Run All Remaining
  Select Steps
  Run Security Analysis
```

Progress is saved - come back anytime and resume where you left off.

## What Gets Installed

| Category | Tools |
|----------|-------|
| **Security** | Tailscale SSH, UFW, auto-updates |
| **Core** | git, curl, build-essential, jq, stow |
| **Modern CLI** | eza, bat, zoxide, atuin, fzf, direnv |
| **TUI** | lazygit, lazydocker, htop, neovim |
| **Runtime** | Docker, Node.js (fnm), Bun, pnpm |
| **AI** | Claude Code (native install) |
| **Shell** | zsh, tmux with persistence |
| **Git** | GPG commit signing, GitHub CLI |
| **Cloud** | AWS CLI with IAM Identity Center |

## The Workflow

On your **laptop**, add to `~/.ssh/config` for easy access:

```
Host gondor
    User laurence
```

Then:

```bash
# SSH in via Tailscale MagicDNS
ssh gondor

# Start a persistent session
tmux new -s agent

# Run Claude Code
claude

# Detach anytime (Ctrl-a d)
# Reconnect later
tmux attach -t agent
```

Claude keeps working even when you disconnect. Check back hours later and see what it's done.

## Key Aliases

```bash
c         # claude
lg        # lazygit
lzd       # lazydocker
lt        # tree view (eza)
z <dir>   # smart cd (zoxide)
```

## Dotfiles

Managed with GNU Stow. Includes:

- `.zshrc` - vi-mode, modern CLI aliases, tool integrations
- `.tmux.conf` - Ctrl-a prefix, vim navigation, session persistence
- `.gitconfig` - GPG signing, sensible defaults

## Credits

Inspired by [thdxr/environment](https://github.com/thdxr/environment) from Dax at SST.
