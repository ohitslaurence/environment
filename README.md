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

## Setup from a fresh Ubuntu install

Tested on Ubuntu 24.04 (Server / Cloud / Desktop). Plan ~30 min: most of it is automated, but several steps open browser windows for auth.

### 0. Prerequisites (have these ready)

- **Tailscale account** — sign up at tailscale.com (free for personal). Decide what hostname you want this machine to be.
- **GitHub account** — you'll authenticate via browser
- **AWS SSO start URL + region** (only if you use AWS — `https://<org>.awsapps.com/start`)
- **Nia API key** (optional — only if you use Nia CLI; create at trynia.ai)

### 1. Bootstrap

```bash
# Set a system hostname (matches what you'll use in Tailscale)
sudo hostnamectl set-hostname my-machine

# Install git + clone
sudo apt update && sudo apt install -y git
mkdir -p ~/dev
git clone https://github.com/ohitslaurence/environment.git ~/dev/environment
cd ~/dev/environment

# Run the setup
./setup
```

If you're SSH'd in as `root` on a fresh cloud image, the setup will refuse to continue and walk you through creating a regular sudo user first. Switch to that user and re-run.

### 2. Choose "Run All Remaining"

The interactive menu (powered by [gum](https://github.com/charmbracelet/gum)) shows step status; pick **Run All Remaining**.

You'll hit these prompts in order — keep a browser handy:

| Step | What you'll do |
|---|---|
| `tailscale` | Confirm hostname → browser opens for Tailscale auth |
| `dotfiles` | Enter git email + name → GPG key auto-generates → public key printed (add to GitHub later) |
| `gh_auth` | Browser opens for GitHub CLI login (HTTPS, with `admin:public_key` scope) |
| `github_ssh` | Generates a new SSH key → offers to upload to GitHub via gh (say yes) |
| `aws_sso` | Enter SSO URL + region + profile name → run `aws sso login` after |
| `nia` | Installs CLI only — you'll run `nia auth login` separately if needed |

Progress is saved to `~/.config/vps-setup/state.json` — interrupt anytime and re-running picks up where you left off.

### 3. Post-setup (one-time)

```bash
# Re-login so docker group membership takes effect (or `newgrp docker`)
exit  # then SSH back in

# Authenticate AWS SSO (if you set it up)
aws sso login --profile <your-profile>

# Authenticate Nia CLI (if you use Nia)
nia auth login

# Add your GPG public key to GitHub for verified commits
# (printed during the dotfiles step; also: gpg --armor --export <KEY_ID>)
# Paste at: https://github.com/settings/gpg/new

# Verify everything looks right
bash scripts/analyze.sh
```

`analyze.sh` should show ✓ on Tailscale, UFW, OpenSSH disabled, Docker default-localhost binding, no exposed containers, and no state drift.

### 4. Things this script does NOT do (do these manually)

- **Cloud provider MFA** — enable on your VPS provider account
- **GitHub MFA** — enable hardware key or authenticator at github.com/settings/security
- **Tailscale ACLs** — by default everyone in your tailnet can reach this box; tighten in the Tailscale admin console if needed
- **Cloud provider firewall** — if your VPS provider has its own firewall (DigitalOcean, Hetzner Cloud, etc.), keep all inbound blocked there too as a second layer

### Re-running individual steps

```bash
./setup           # interactive menu, pick "Select Steps"
# or
bash steps/<name>.sh   # run one directly
```

## What Gets Installed

| Category | Tools |
|----------|-------|
| **Security** | Tailscale SSH, UFW, auto-updates |
| **Core** | git, curl, build-essential, jq, stow |
| **Modern CLI** | eza, bat, zoxide, fzf, direnv |
| **TUI** | lazygit, lazydocker, htop, neovim |
| **Runtime** | Docker, Node.js (fnm), Bun, pnpm |
| **AI** | Claude Code, OpenCode, Codex, Nia CLI |
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

# Detach anytime (Ctrl-w d — prefix is Ctrl-w)
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

Managed with GNU Stow. Tracked files in `home/`:

- `.zshrc` - vi-mode, modern CLI aliases, tool integrations
- `.tmux.conf` - Ctrl-w prefix (avoids Claude Code conflicts), vim navigation, tmux-resurrect + tmux-continuum (auto-save every 10 min, auto-restore on launch)
- `.gitconfig` - GPG signing, sensible defaults
- `.claude/settings.json.template` - seeds `~/.claude/settings.json` on first run
- `.config/opencode/opencode.json.template` - seeds `~/.config/opencode/opencode.json` on first run
- `.claude/hooks/`, `.agents/skills/` - Claude Code hooks and skill packages

## Environment Variables & Secrets

Configs are version controlled but **secrets stay local**. The pattern:

- Tracked configs in `home/` contain no secrets — stow symlinks them to `~`
- `~/.claude/settings.json` and `~/.config/opencode/opencode.json` are gitignored. They're seeded from `*.template` on first run, then you can add machine-specific MCP servers / API keys without leaking to the repo.
- Long-lived shell secrets go in `~/.zshrc.local` (sourced by `.zshrc`, not in git)
- AI CLIs handle their own auth: `claude` (browser), `nia auth login` (browser), `codex` (browser), `gh auth login` (browser)

## Credits

Inspired by [thdxr/environment](https://github.com/thdxr/environment) from Dax at SST.
