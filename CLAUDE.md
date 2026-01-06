# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

VPS environment setup tool using GNU Stow for dotfile management. Interactive menu-driven setup with progress tracking.

## Commands

```bash
./setup                      # Interactive setup menu (gum-powered)
scripts/upgrade.sh           # Upgrade Claude Code, OpenCode, Bun, Gritty, tmux plugins
scripts/analyze.sh           # Security analysis of the VPS
```

## Architecture

### Setup Flow
- `./setup` → interactive menu via gum
- State tracked in `~/.config/vps-setup/state.json`
- Individual steps in `steps/*.sh` (run independently or via menu)

### Dotfiles (GNU Stow)
- `home/` directory mirrors `~/` structure
- Running `stow home` from repo root symlinks files to `~`
- Files like `home/.zshrc` become `~/.zshrc`

### Secrets Pattern
- Configs in repo use env vars: `${NIA_API_KEY}`
- Actual secrets in `~/.zshrc.local` (not in git, sourced by `.zshrc`)
- Step scripts prompt for secrets and write to `.zshrc.local`

## Adding a New Step

1. Create `steps/<name>.sh` with the install logic
2. Add state key to `init_state()` in `setup`
3. Add to `build_menu()` for display
4. Add to `run_all_remaining()` array (or leave out if optional)
5. Add to `select_steps()` options array

## Key Files

| File | Purpose |
|------|---------|
| `setup` | Main entry point, menu logic, state management |
| `steps/*.sh` | Individual setup steps |
| `scripts/analyze.sh` | Security audit |
| `scripts/upgrade.sh` | Tool upgrades |
| `home/.zshrc` | Shell config with aliases (`cc`, `ta`, `tw`, etc.) |
| `home/.tmux.conf` | tmux config (Ctrl-w prefix) |
| `home/.claude/` | Claude Code global instructions and settings |
