# Agent Guidelines

## Communication

- Terse. Sacrifice grammar for brevity. No preamble, no flattery.

## Rules

- After 3 consecutive failures on the same problem: stop, revert, ask.
- Never push to main.
- Long tasks: write PLANS.md (why, then exact steps).

## Git

- Many tiny commits beat a few large ones. Commit after each logical step.
- Suggest commits after finishing a task; never commit or open a PR unless asked.
- Use `gritty` for commits and PRs (`gritty --help`). Always pass `--accept` when non-interactive:

```bash
gritty commit --accept     # AI commit message
gritty compose --accept    # organize scattered changes into commits
gritty pr --accept         # create PR
```

## Shell gotchas (mined from agent transcripts)

- `pkill -f "foo"` kills your own shell (the pattern is in its argv; exit 144). Use `pkill -f "[f]oo"`.
- `git grep`: every flag goes before the pattern (`git grep -n -A20 PAT origin/main -- src`). A flag after the revision is read as a revision.
- No `sleep N; check` polling. Claude: `run_in_background` and wait for the notification, or Monitor with an until-loop.
- Commands that block for minutes (`ship --act --wait`, `orch wait`, `slack sync`): in Claude, set the Bash timeout to 600000 and don't pipe them through `tail`.
- A repo's `CLAUDE.md` is a symlink to `AGENTS.md`: edit `AGENTS.md`.
- `python` doesn't exist; use `python3`.
- Never read secret values (`ssm --with-decryption`, `secretsmanager get-secret-value`, `sst secret list`, bare `env`, `cat` of an env file), not even into a variable. A hook blocks them. Ask instead.
- Ask first: `gh pr merge --admin`, skipping hooks (`LEFTHOOK=0`, `--no-verify`), `git reset --hard`, prod writes (DynamoDB, lambda invoke).
- Worktree-isolated subagent: edit with Edit/Write, not `python3 - <<EOF` rewrites. Keep each Bash call to one simple command.
- Codex: `rm -f` and `rm -rf` are rejected; use `rm -r` or `rm`.
- Codex `apply_patch`: re-read the target lines right before patching; at most one operation per file in each patch.
- Codex: cap what you read: `sed -n` 200 lines or fewer, `rg … | head -100`, `gh pr diff --name-only` before the full diff.
