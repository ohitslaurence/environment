# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Two layers: (1) portable agent config — Claude/Codex/OpenCode instructions, hooks, settings, global skills, mise tool versions — linked into `~` by `./apply` on any OS; (2) Ubuntu VPS setup (`./setup`, `steps/*.sh`) with shell dotfiles via GNU Stow.

## Commands

```bash
./bootstrap                  # New machine (any OS): mise + Claude Code + ./apply
./apply                      # Re-link agent layer into ~ (idempotent; run after git pull)
./setup                      # Ubuntu box: interactive setup menu (gum-powered)
scripts/upgrade.sh           # Upgrade Claude Code, mise tools, skills, Gritty, tmux plugins
scripts/analyze.sh           # Security analysis of the VPS
```

## Architecture

### Setup Flow
- `./setup` → interactive menu via gum
- State tracked in `~/.config/vps-setup/state.json`
- Individual steps in `steps/*.sh` (run independently or via menu)

### Agent layer (`./apply`)
- `~/.claude`, `~/.codex` are REAL dirs (runtime state never enters the repo). `apply` symlinks only `CLAUDE.md`, `settings.json`, `hooks/`, `commands/` into `home/.claude/`.
- `~/.agents` -> `home/.agents` wholesale: the `skills` CLI's canonical store, so `npx skills add -g` writes into the repo. Lock file is tracked.
- Per-skill symlinks into `~/.claude/skills/` and `~/.codex/skills/`.
- `~/.config/mise/config.toml` tracked: same node/bun/gh/uv/codex versions everywhere.
- Hooks must keep runtime state under `~/.claude/state/`, never beside their source.

### Shell layer (GNU Stow, Linux)
- `home/` mirrors `~/`; `stow home` links `.zshrc`, `.tmux.conf`, `.gitconfig`, `.ssh/config`, `.local/bin`
- `home/.stow-local-ignore` keeps stow away from the agent layer

### Secrets Pattern
- Tracked configs contain no secrets; `apply` refuses to run if a bearer token is found in the repo
- MCP servers needing keys are registered per machine with `claude mcp add -s user` (lands in `~/.claude.json`)
- Long-lived secrets go in `~/.zshrc.local` (not in git, sourced by `.zshrc`)

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
| `apply` / `bootstrap` | Agent-layer linking; new-machine entry point |
| `home/.claude/` | Claude Code global instructions, settings, hooks |
| `home/.agents/skills/` | Global skills (own + upstream via `skills` CLI) |
| `home/.config/mise/config.toml` | Tool versions |
