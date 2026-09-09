---
name: herdr-team
description: Orchestrate other coding agents (Claude, Codex, OpenCode) from inside a Herdr pane. Use when the user asks to spawn a worker or reviewer agent, fan work out across agents or worktrees, run something in another pane, or wait on another agent. Requires HERDR_ENV=1. Loads on top of the upstream `herdr` skill.
---

# Herdr team playbook

Mechanics (IDs, splitting, `agent start`, `prompt --wait`, `read`, safety rules) are in the upstream `herdr` skill. Read it first. This file holds our conventions and the gotchas we hit; it does not repeat the CLI reference.

## The loop

```bash
test "${HERDR_ENV:-}" = 1 || { echo "not inside herdr"; exit 1; }
P=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
herdr agent start reviewer --kind codex --pane "$P"          # kinds: claude | codex | opencode
herdr agent prompt reviewer "<task>" --wait --timeout 180000
herdr agent read reviewer --source recent-unwrapped --lines 120
```

Fan-out: one split + start per worker, prompt each without `--wait`, then `herdr agent wait <name>` on each. For isolated branches use `herdr worktree create --branch <name>` and start the worker in that workspace's root pane.

## Conventions

- Name every worker: `reviewer`, `tester`, `impl-<area>`. Names are the only stable handle and must be unique among live agents.
- Brief workers once, fully: goal, constraints, what "done" looks like, and how to report (see below). Don't drip-feed.
- Ask for the deliverable as a file when it's more than a screenful: "Write the result to `/tmp/<name>.md` and reply only with the path." Claude runs on the alternate screen (`tui: fullscreen`), so long replies scroll out of `agent read`; short replies are fine with `--lines 300`.
- Reviewer pattern: Claude implements, a Codex `reviewer` reads the diff and reports actionable findings only, Claude fixes. Different model, fresh context, cheap.

## Gotchas

- **Codex first launch after `herdr integration install codex`** shows "Hooks need review". Herdr reports it as `idle`, so `prompt --wait` returns `agent_prompt_stalled`. Fix once: `herdr agent send-keys <name> down enter` (Trust all and continue), then re-prompt.
- `agent_prompt_stalled` or `timeout` does not mean the prompt was lost. `agent read` first; never re-send blindly.
- `blocked` means an approval dialog. Read it and ask the user before answering it.
- Never run bare `herdr server`: it starts a headless server and blocks. Get help with `herdr <group>` (no subcommand) or `herdr --help`.
- Don't control the live session from outside a pane (over ssh, from a script). For experiments use an isolated session: `herdr --session test server &`, then `herdr --session test ...`, then `herdr session stop test && herdr session delete test`.
- Don't close panes or workspaces you didn't create.
