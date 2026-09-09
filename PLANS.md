# PLANS.md — one agent config, every machine

**Status 2026-09-09: DONE on gondor + Mac.** Remaining manual items:
- Mac `~/dev -> ~/Development` symlink: Syncthing still watches `~/dev`. Remove the "dev" folder
  from Syncthing first, then `mv ~/dev ~/dev.dead && ln -s ~/Development ~/dev`.
- Mac shell config (`~/.zshrc`, oh-my-zsh/p10k) is NOT the repo's `home/.zshrc`; only mise
  activation + `envup` were added by hand. Unify later if wanted.
- Nia removed everywhere (CLI step, MCP registrations, tokens). `improve` = repo copy; the old
  `shadcn/improve` sits in `~/.agents.pre-apply` on the Mac, safe to delete.
- Backups left in place: `~/.claude/*.pre-apply`, `~/.agents.pre-apply` (Mac);
  `~/.config/opencode/opencode.json.pre-apply` was removed (gondor).

## Why

Two machines (gondor = Ubuntu/Tailscale, Mac = travel) must run the *same* agent
setup: Claude/Codex/OpenCode instructions, hooks, settings, global skills, tool
versions. Today they drift because the repo mixes three things with different
lifecycles and only gondor is fully wired:

| Layer | Lifecycle | Today |
|---|---|---|
| Box setup (tailscale, ufw, docker, apt) | once per Linux box | `steps/*.sh`, fine |
| Tools (node, bun, gh, codex, skills CLI) | upgraded often, same everywhere | fnm + ad-hoc; gondor has no `npx`/`mise` in non-interactive PATH |
| Agent config (CLAUDE.md, hooks, settings, skills) | edited daily, must match | stow on gondor, hand-symlinked on Mac |

### Findings (2026-09-09)

1. **gondor `~/.claude` IS the repo dir** (`~/.claude -> dev/environment/home/.claude`, stow folded it).
   900 MB of sessions/history/daemon/`.credentials.json` live inside the git checkout,
   held back only by a 30-line `.gitignore` allowlist. One bad `git add -f` leaks creds.
2. **`settings.json` is gitignored** (Nia token inside) so hooks config has drifted:
   gondor has SessionStart+Stop+UserPromptSubmit+PreToolUse; Mac has SessionStart only.
   Model, statusline, plugin list also differ.
3. **Two hooks are gitignored** (`block-secret-reads.py`, `herdr-agent-state.sh`) yet
   referenced by settings. They were scp'd to the Mac by hand.
4. **Skills are a vendored snapshot with no lock.** `.skill-lock.json` is gitignored.
   Vendored copies date from 2026-05-08; upstream `mattpocock/skills` has since renamed
   `to-issues→to-tickets`, `to-prd→to-spec`, `diagnose→diagnosing-bugs`, and every shared
   skill now differs from upstream. Impossible to tell "my edit" from "upstream drift".
   `prc`/`prl`/`prr`/`prod`/`staging`/`repo-eval` are yours. `caveman`/`write-a-skill`/
   `zoom-out` are not in mattpocock/skills today (source unknown).
5. **Codex never sees the shared skills.** gondor `~/.codex/skills/` has only `.system`;
   Mac has one hand-made symlink. Only `AGENTS.md -> CLAUDE.md` is linked.
6. **Mac is half-wired**: `~/.claude/CLAUDE.md` symlinked, nothing else. `~/.agents/skills`
   holds a separate `shadcn/improve` install. `~/dev` is a dead Syncthing mirror with
   dangling symlinks; `DEV_HOME` differs (`~/dev` vs `~/Development`) so `.zshrc` can't be shared verbatim.
7. gondor repo is **4 commits ahead of origin**, unpushed.

### Decision: keep git + stow, fix the model. Add mise. Don't switch to chezmoi.

chezmoi was considered. Its wins (per-OS templates, secret injection, archive externals
for skills) aren't needed once settings are secret-free and paths use `~`. Its cost is real:
default mode *copies* files, so agents editing `~/.claude/hooks/x` or a skill in place no
longer edit the repo (breaks the `gritty commit` workflow); symlink mode can't symlink
executables or templates. `mise` is the right tool for the *tools* layer only.

## Target state

```
~/.claude/                real dir, runtime state stays here
  CLAUDE.md            -> environment/home/.claude/CLAUDE.md
  settings.json        -> environment/home/.claude/settings.json   (tracked, no secrets, ~ paths)
  hooks                -> environment/home/.claude/hooks           (ALL hooks tracked)
  commands             -> environment/home/.claude/commands
  skills/<name>        -> ~/.agents/skills/<name>                  (per-skill links)
~/.agents/                real dir
  skills               -> environment/home/.agents/skills          (npx skills add -g writes into repo)
  .skill-lock.json     -> environment/home/.agents/.skill-lock.json (TRACKED)
~/.codex/                 real dir, runtime
  AGENTS.md            -> ~/.claude/CLAUDE.md
  skills/<name>        -> ~/.agents/skills/<name>                  (codex owns skills/.system)
  config.toml             machine-local; only model/effort worth copying by hand
~/.config/opencode/       real dir; AGENTS.md + opencode.json linked
~/.config/mise/config.toml -> environment/home/.config/mise/config.toml
~/.zshrc .tmux.conf .gitconfig .ssh/config -> repo (unchanged)
~/dev                     real dir on Linux; on Mac a symlink -> ~/Development
```

Secrets: never in tracked files. Nia MCP registered per machine with
`claude mcp add -s user --transport http nia <url> --header "Authorization: Bearer $NIA_API_KEY"`
(lands in `~/.claude.json`, unsynced). Token lives in `~/.zshrc.local`.

One command on every machine after pulling: `./apply` = stow --no-folding + link skills
+ `mise install`. One command to update: `env up` = git pull + ./apply.

## Steps

### 0. Safety
- [x] gondor: `git push origin main` (4 commits ahead).
- [x] gondor: `cp -a ~/dev/environment ~/dev/environment.bak-$(date +%F)` (900 MB; sessions matter).
- [x] Mac: `mv ~/dev ~/dev.dead-syncthing` (delete later), `ln -s ~/Development ~/dev`.

### 1. Un-fold `~/.claude` and `~/.agents` on gondor
- [x] `rm ~/.claude` (the symlink), `mkdir ~/.claude`.
- [x] Move runtime state out of repo into the new real dir:
      `git -C ~/dev/environment status --ignored --porcelain | grep '^!! home/.claude/'` lists exactly what to move.
      Everything not tracked goes to `~/.claude/`. Tracked files stay in repo.
- [x] Same for `~/.agents` (only `.skill-lock.json` if present).
- [x] Delete `home/.claude/hooks/hooks` self-symlink and `todo-enforcer.log`.
- [x] Collapse the `.gitignore` allowlist block: with `--no-folding` the repo dir is never a
      runtime target, so only `*.log`, `*.local`, secret patterns remain.

### 2. Make settings tracked and portable
- [x] Merge gondor + Mac `settings.json` into `home/.claude/settings.json`: all four hooks,
      `~/.claude/hooks/...` paths (no `/home/laurence`, no `/Users/laurence`), statusline via
      `claude-powerline` (installed by mise/npm, not `npx -y ... @latest`), union of
      `enabledPlugins` + `extraKnownMarketplaces` (drop the gitkraken `directory` source or
      make it `~`-relative). `model`: pick one.
- [x] Remove `mcpServers.nia` from settings; register with `claude mcp add` on each machine.
- [x] Delete `settings.json.template`; un-ignore `settings.json`.
- [x] Track `block-secret-reads.py` and `herdr-agent-state.sh` (they contain no secrets; verify).

### 3. Skills with a lock
- [x] Un-ignore `home/.agents/.skill-lock.json`.
- [x] Decide keep-list from upstream (`npx skills add mattpocock/skills -l`). Likely:
      `tdd triage grill-with-docs grill-me improve-codebase-architecture setup-matt-pocock-skills
      diagnosing-bugs to-tickets to-spec`.
- [x] `rm -rf` the vendored upstream copies (`git rm`), keep own skills.
- [x] `npx skills add mattpocock/skills -g -a claude-code,codex -s <list> -y` from a shell where
      `~/.agents/skills` already points into the repo. Commit files + lock.
- [x] Find sources for `caveman`, `write-a-skill`, `zoom-out`; re-add via `skills` or move to own.
- [x] Resolve `improve`: repo copy vs Mac's `shadcn/improve`. Keep one.
- [x] Upgrade flow from now on: `npx skills update -g -y && gritty commit --accept && git push`;
      other machine: `env up`.

### 4. mise for tools
- [x] `home/.config/mise/config.toml`:
      ```toml
      [tools]
      node = "lts"
      bun = "latest"
      gh = "latest"
      uv = "latest"
      "npm:@openai/codex" = "latest"
      "npm:@owloops/claude-powerline" = "latest"
      "npm:skills" = "latest"
      ```
      Claude Code stays on the native installer (self-updates; mise would fight it).
- [x] `.zshrc`: replace fnm init with `eval "$(mise activate zsh)"` (block already exists on gondor's zshrc).
- [x] `scripts/upgrade.sh` → `mise upgrade` + `claude update` + gritty/personal CLI builds.
- [x] Retire `steps/node.sh`, `steps/bun.sh`, `steps/codex.sh` into `mise install`.

### 5. `apply` script (idempotent, both OSes)
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ~/.claude ~/.agents ~/.codex/skills ~/.config/opencode ~/.config/mise
stow -v -R --no-folding -t ~ home          # per-file links; runtime dirs stay real
ln -sfn ~/.claude/CLAUDE.md ~/.codex/AGENTS.md
ln -sfn ~/.claude/CLAUDE.md ~/.config/opencode/AGENTS.md
for s in home/.agents/skills/*/; do        # per-skill links for claude + codex
  n=$(basename "$s")
  ln -sfn ~/.agents/skills/"$n" ~/.claude/skills/"$n"
  ln -sfn ~/.agents/skills/"$n" ~/.codex/skills/"$n"
done
command -v mise >/dev/null && mise install
```
Note: `--no-folding` links files, but `~/.agents/skills` and `~/.claude/hooks` should be *dir*
links so `npx skills add` and agent edits land in the repo. Either exclude them from stow
(`--ignore`) and `ln -sfn` them explicitly, or accept per-file links and run `./apply` after
adding a skill. Prefer explicit dir links.
- [x] `.zshrc`: `env() { git -C "$DEV_HOME/environment" pull --ff-only && "$DEV_HOME/environment/apply"; }`
      (or fold into `steps/dotfiles.sh`; keep gum/GPG prompts out of `apply`).

### 6. bootstrap for a new machine (Mac or Linux)
```bash
git clone https://github.com/ohitslaurence/environment.git ~/dev/environment   # Mac: ~/dev -> ~/Development
cd ~/dev/environment && ./bootstrap   # installs stow+gum+mise (brew|apt), curl mise, ./apply
```
Linux-only steps (`tailscale ufw disable_ssh docker syncthing`) stay behind `./setup`.
README: two sections — "Any machine (agent config)" and "Ubuntu box".

### 7. Verify
- [x] Both machines: `claude` shows same hooks (`/hooks`), same skills (`/skills`), same model.
- [x] `codex` lists shared skills.
- [x] `git -C ~/dev/environment status --ignored` on gondor shows no runtime state inside repo.
- [x] `grep -r Bearer home/` returns nothing.
- [x] Update memory `local-dev-setup-mirror` (DEV_HOME now `~/dev` on both).
