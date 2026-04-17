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
| **Modern CLI** | eza, bat, zoxide, fzf, direnv |
| **TUI** | lazygit, lazydocker, htop, neovim |
| **Runtime** | Docker, Node.js (fnm), Bun, pnpm |
| **AI** | Claude Code, OpenCode, Nia MCP (optional) |
| **Sync** | Syncthing (file sync to laptop) |
| **Shell** | zsh, tmux with persistence |
| **Git** | GPG commit signing, GitHub CLI |
| **Cloud** | AWS CLI with IAM Identity Center |

## The Workflow

On your **laptop**, add to `~/.ssh/config` for easy access:

```
Host <tailscale-hostname>
    User <username>
```

Then:

```bash
# SSH in via Tailscale MagicDNS
ssh <tailscale-hostname>

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
cc        # claude --dangerously-skip-permissions (unrestricted mode)
ccu       # ccusage - token usage and cost tracking
lg        # lazygit
lzd       # lazydocker
lt        # tree view (eza)
z <dir>   # smart cd (zoxide)
```

### ccusage Commands

```bash
ccu daily      # Daily token usage and costs
ccu monthly    # Monthly aggregated report
ccu session    # Usage by conversation session
ccu blocks     # 5-hour billing windows
ccu blocks --live  # Real-time usage dashboard
```

## Dotfiles

Managed with GNU Stow. Includes:

- `.zshrc` - vi-mode, modern CLI aliases, tool integrations
- `.tmux.conf` - Ctrl-w prefix (avoids Claude Code conflicts), vim navigation, session persistence
- `.gitconfig` - GPG signing, sensible defaults
- `.mcp.json` - Claude Code MCP servers (Nia)
- `.claude/settings.json` - Claude Code settings (powerline status)
- `.config/opencode/opencode.json` - OpenCode config

## Environment Variables & Secrets

Configs are version controlled but **secrets stay local**. The pattern:

- Tracked configs in `home/` contain no secrets — stow symlinks them to `~`
- `~/.claude/settings.json` and `~/.config/opencode/opencode.json` are gitignored. They're seeded from `*.template` on first run, then you can add machine-specific MCP servers / API keys without leaking to the repo.
- Long-lived shell secrets go in `~/.zshrc.local` (sourced by `.zshrc`, not in git)
- AI CLIs handle their own auth: `claude` (browser), `nia auth login` (browser), `codex` (browser), `gh auth login` (browser)

## Credits

Inspired by [thdxr/environment](https://github.com/thdxr/environment) from Dax at SST.
