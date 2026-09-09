---
name: orchestrate
description: Run and supervise several worker agents (Codex or Claude) in parallel on separate dev worktrees via herdr, using the `orch` CLI and a brief template. Use when the user asks to fan a task out across workers, run an investigation or fix per item with one agent driving the others, or supervise autonomous workers to completion. Requires HERDR_ENV=1.
---

# Orchestrate workers

You are the orchestrator. Workers are separate agents in their own herdr
panes and `dev` worktrees. You brief them, watch an append-only status log,
read their reports, decide, and report the outcome to the user in plain terms.

Mechanics live in `orch` (see `orch` with no args). Herdr internals are in the
`herdr` and `herdr-team` skills; you rarely need them directly.

## Loop

1. **Brief.** Copy `brief-template.md` from this skill's directory, fill
   `{{TASK}}`, `{{CONTEXT}}`, `{{DONE}}`. Leave `{{NAME}} {{STATUS}}
   {{REPORT}} {{WORKTREE}}` for `orch` to fill. The intent must be
   self-sufficient: paste the material the worker needs (a report body, an
   error, a spec) into the brief. Never link to something only you can see.
2. **Start.** `orch start <name> --repo <alias> --brief <file> [--kind codex|claude] [--effort xhigh]`.
   One worker per independent item. Names: `[a-z][a-z0-9_-]*`, unique. Inside herdr, each worker becomes a tab of your workspace; add `--workspace` for separate workspaces.
3. **Wait.** `orch wait --timeout 1800` (all) or `orch wait <name>`. It
   prints each new status line. Between waits do nothing else; the workers
   are the work.
4. **Read.** `orch report <name>`. If the state is `needs-decision` or
   `blocked`, read `orch log <name> 120`, decide, and answer with
   `orch prompt <name> "<one clear instruction>"`, then wait again.
5. **Decide.** Approve, reject, or send the worker back with a specific
   correction. Promote approved fixes to a second phase (commit, PR) with
   a new brief that says exactly what to ship.
6. **Close.** `orch done <name>` when a worker's work has landed or been
   rejected. Keep a running summary for the user: outcome per worker, what
   needs their decision, what you did on their behalf.

## Rules

- A herdr `idle` or `done` is not evidence the worker finished. Only a
  terminal line in the status log is (`done`, `failed`, `blocked`,
  `needs-decision`). Herdr shows idle while a harness sits in a long tool
  call.
- Do not re-send a brief or prompt because a worker looks quiet. Read the
  log first.
- Escalate to the user only for: a decision only they can make, a real
  blocker after one recovery attempt, anything destructive or
  security-sensitive, credentials. Batch everything else into your summary.
- Recovery for a stuck worker: read the log, send one corrective prompt,
  wait once more. If it fails again, mark it failed in your summary and move
  on; do not loop.
- Effort: `xhigh` for ambiguous investigation, `high` for well-specified
  fixes. Never `max` unless the user asked.
- Do not end your turn while workers are running unless you have told the
  user exactly which are still running and what you will do when they
  finish.

## Ready briefs

`briefs/sentinel-triage.md` in this skill's directory: Lighthouse Sentinel
report triage. Fill `{{REPORT_REF}}` and paste the stored report into
`{{REPORT_BODY}}` (fetch it with the `executor` tool `get_sentinel_report`).
Repo alias for workers: `lighthouse`.

## Phases for investigate-then-fix work

Phase 1, scout: workers investigate and write reports; no pushes. Phase 2,
ship: for each approved recommendation, a new brief whose intent is the
exact change, done = tests pass and `gritty pr --accept` opened.
