# PLANS.md — `dev` v2: one primitive, self-cleaning

(The finished agent-config sync plan moved to docs-plans-agent-sync-done.md.)

## Why

Three gripes with the herdr + `dev` workflow on gondor, measured 2026-09-09:

| Symptom | Measured | Root cause |
|---|---|---|
| Spaces panel flooded | 59 workspaces; only 23 are live `dev` contexts. 31 are canonical checkouts opened by hand or no-repo scratch spaces; six are mislabelled "lighthouse" pointing at other repos. | Nothing ever closes a workspace except `dev done`, and non-`dev` workspaces have no owner at all. |
| Worktrees never cleaned up | 124 `-wt-` worktrees on disk, 97 stale (platform alone: 38). Branches are always kept. | Two lifecycles disagree: closing a workspace in the herdr UI, a reboot, or a server reset leaves the git worktree. `dev prune` exists but is manual and never runs. |
| Agents edit the main checkout | 27 canonical clones are off `main` and/or dirty (bridge on `bridge__uk-faster-payments`, compliance-ops 20 dirty files, unify-mirror 15). | Canonical clones are ordinary working trees. Anything can `cd` there and work: an agent, `gh pr checkout` (which `prr`/`prc` run in whatever cwd they're in), a stray `herdr` launch. There is no enforcement, only convention. |

Worktrees are the right primitive. The problems are enforcement and lifecycle, not the primitive.

## Decisions

### D1. Canonical clones become bare. Work exists only in worktrees.

`~/dev/spritz/<repo>/` keeps its `.git/` and loses its working files (`core.bare = true`). Result: nothing to edit, `git status` there errors, `gh pr checkout` there fails, a herdr workspace opened there is an empty folder. This is the only enforcement that covers Claude, Codex, OpenCode, and a human shell alike; agent hooks only ever cover one agent.

`dev` keeps working: it already branches from `origin/<base>` and never needs the canonical working tree. `git worktree add` works from a bare repo. Two adjustments: `dev refresh` becomes `git fetch origin <base>:<base>`, and PR checkout becomes a `dev` subcommand (`dev pr-checkout <number>` creates `<repo>-wt-pr-<n>` from the PR head) which `prr`/`prc` use instead of `gh pr checkout`.

Reversible per repo: `git config core.bare false && git checkout main`.

Softer alternative considered and rejected: a Claude `PreToolUse` hook refusing writes under canonical paths. Claude-only, and it wouldn't stop `gh pr checkout` or a shell.

### D2. `dev` owns the whole lifecycle and reconciles automatically.

- `dev done`: closes the workspace, removes the worktree, and deletes the branch when it is merged into `origin/<base>` or its PR is merged/closed (`--keep-branch` opts out). Today it always keeps the branch.
- `dev prune`: also (a) removes clean worktrees whose branch is merged or whose PR is closed, (b) deletes merged local branches, (c) closes herdr workspaces that point at a missing worktree or have no live agent and a merged branch. Dirty or unmerged worktrees are listed, never deleted.
- `dev prune` runs automatically: the fast clean+merged path on every `dev` dashboard start, and a nightly systemd user timer on gondor.
- `dev` names the agent pane after the context (`herdr pane rename <agent-tab-pane> <repo>__<task>`) so the agents panel reads the task without relying on Claude's conversation title.

### D3. Spaces panel: fewer workspaces plus config.

- One-off: close the 31 non-context workspaces (list below; the one with a live agent is kept).
- Prevention: D1 removes canonical workspaces as a thing; D2 closes dead ones.
- Config (`~/.config/herdr/config.toml`, both machines):
  ```toml
  [ui]
  agent_panel_sort = "priority"          # attention queue instead of grouped by space
  [ui.sidebar.agents]
  rows = [["state_icon", "workspace", "tab"], ["agent"]]   # drop Claude's title row
  [ui.sidebar.spaces]
  rows = [["state_icon", "workspace"], ["branch", "git_status"]]
  ```
  Track this file in the repo once `~/dev` exists on the Mac (only `new_cwd` differs today).

## Steps

### 0. One-off cleanup on gondor (needs go-ahead; touches live state)
- [ ] `dev prune --dry-run`, review, then `dev prune` (removes ~90 clean stale worktrees, branches kept for now).
- [ ] Close non-context workspaces without agents: wZ w1M w1V w1X w10 w22 w2E w2H w2S w2Z w32 w36 w3B w3D w3J w3N w3V w3Y w4B w4Q w4Z w5C w5M w5Q w6M w85 w94 w9F w9M wA5 (`herdr workspace close <id>`). Keep wBB (live agent).
- [ ] For each of the 27 off-main/dirty canonicals: dirty → commit WIP on its branch; non-main branch → `git worktree add <repo>-wt-<branch> <branch>` so nothing is lost; then `git switch main`.

### 1. `dev` changes (portable, in `home/.local/bin/dev`)
- [ ] `refreshCanonicalRepo` → bare-safe: `git fetch origin <base>:<base>` (fallback to old path if `core.bare` is false).
- [ ] `dev pr-checkout <number>` → worktree `<repo>-wt-pr-<n>` on the PR head branch, workspace label `pr-<n>`.
- [ ] `cmdDone`: merged-branch detection (`git branch --merged origin/<base>` or `gh pr view <branch> --json state`), delete branch unless `--keep-branch`.
- [ ] `cmdPrune`: merged/closed detection, branch deletion, workspace closing, `--all` for the slow gh-backed pass.
- [ ] Dashboard: run fast prune first; print a one-line summary.
- [ ] Name the agent pane after the context in `ensureTabs`.
- [ ] Guard: `dev <repo> <task>` refuses if `<repo>` canonical is not bare and is dirty (until D1 lands everywhere).

### 2. Skills
- [ ] `prr` and `prc`: replace `gh pr checkout` with `dev pr-checkout <n>`; run in that worktree.

### 3. Bare conversion (per repo, gondor first, Mac later)
- [ ] Script `scripts/bare-canonicals.sh <repo>...`: assert clean + on main, remove working files, `git config core.bare true`, verify `git worktree list` still resolves.
- [ ] Run on the 20 clean-and-on-main repos first, then the rest after step 0.

### 4. Automation
- [ ] `steps/dev-prune-timer.sh`: systemd user timer, nightly `dev prune`.
- [ ] herdr config changes on both machines; `herdr server reload-config`.

### 5. Verify
- [ ] `dev ls` shows 0 stale after prune; spaces panel ≈ live contexts only.
- [ ] In a bare canonical: `git status` errors; `dev <repo> test-task` still creates a worktree; `dev done` removes it and the branch.
- [ ] `prr` on a real PR lands in `<repo>-wt-pr-<n>`, canonical untouched.
