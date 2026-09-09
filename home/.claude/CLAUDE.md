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
