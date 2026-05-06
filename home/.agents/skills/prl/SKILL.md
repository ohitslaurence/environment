---
name: prl
description: Compound PR review. Look across the last week of merged PRs (up to a watermark) and propose high-signal, load-bearing improvements. The goal is fewer, better problems solved — not more rules.
disable-model-invocation: true
argument-hint: [--days N]
allowed-tools: Bash(gh *), Bash(git *), Bash(date *), Bash(jq *), Read, Grep, Glob, Edit, Write
---

# PR Compound Review — Lessons, Not Rules

You are doing a retrospective across recent PRs to find issues worth acting on — recurring patterns *or* one-off problems important enough to address — and to propose the right fix for each.

## The reward function

**Real problems found and meaningfully solved.** Not rules added, not findings produced.

If the window contains nothing worth acting on, the right output is:

> "No issues worth acting on in this window."

That is a success, not a failure. **Do not manufacture findings to justify the run.** Do not grade on a curve.

## What you are looking for

Two kinds of finding deserve action:

- **A pattern** — the same class of mistake, blind spot, or correction showing up across multiple PRs. The recurrence is the signal.
- **A single important issue** — one occurrence, but the cost of repeating it (or having missed it longer) is high enough that it warrants a fix on its own. Security, data loss, irreversible operations, foot-guns that will fire again, gaps in awareness that meaningfully shaped a PR's outcome.

Both are valid. Don't filter out a serious one-off because it didn't recur. Don't promote a thin recurrence because it appeared twice.

## Why the bar is high

Every line in `AGENTS.md`, `CLAUDE.md`, or scoped sub-`AGENTS.md` files costs context weight on every future agent invocation. Each addition dilutes the weight of everything already there. A rule that doesn't earn its line makes the ones that do less effective.

So the bar for proposing a new rule is: **the cost of repeating this mistake is greater than the cost of carrying this rule in agent context forever.** If you can't argue that confidently, drop it.

Mechanical enforcement (lint, type, test) carries far less context cost than written rules. That doesn't make it always the right answer — it makes the cost-side of the calculation different. Weigh it honestly per finding.

## The toolbox

These are the mechanisms available. None is preferred a priori — pick the one that actually fits the problem. Each has different tradeoffs in cost, reach, and failure mode; think through which match the pattern you're trying to address.

- **Lint / formatter / type rule** — mechanical, near-zero context cost, runs every time. Strong fit for syntactic patterns. Useless for things requiring judgment.
- **Test or CI check** — automated, can encode behavior, not just shape. Right when the property is observable from a test boundary.
- **Structural change in the repo** — a helper, a type, an abstraction that makes the wrong thing harder to write than the right thing. Often the highest-leverage option when it applies, because no enforcement is needed once the shape changes. Costs design effort.
- **Scoped sub-`AGENTS.md`** — a rule that lives in the directory it applies to. Pays context cost only when an agent works there. Right for domain-specific considerations (e.g. caching rules for `/api/billing`).
- **Root `AGENTS.md` / `CLAUDE.md`** — global, paid on every invocation. Right when the consideration genuinely applies everywhere and cannot be encoded mechanically.
- **Other** — a CODEOWNERS rule, a PR template question, a runtime assertion, a migration. Don't constrain yourself to the list above.

Pick the mechanism that delivers the most leverage for the specific pattern. The questions to answer are: *what failure mode are you preventing, where does it actually occur, who or what is in the best position to catch it, and what is the ongoing cost of carrying this fix?* The answers point at the mechanism — not a default ordering.

## What does NOT count

- Style preferences. Taste ≠ quality.
- Nits. Ten nits do not aggregate into a real finding.
- Issues already covered by an existing rule, lint, or test policy. If an existing rule should have caught it, the fix is enforcement (a lint, a check), not another rule restating the first.
- Low-impact one-offs. A single occurrence only qualifies when the *cost* of repeating it is high — not just because it happened.
- Things you only noticed because you were looking hard. This is not a re-review of each PR — `/prr` already does that. You are looking at the body of work.
- Blind spots that are inherent to the agent / author's general skill, not specific to this codebase. The retro improves the *repo* — not the population of contributors at large.

## Step 1: Gather the window

Default window is 7 days. Override with `--days N` from `$ARGUMENTS`.

Determine repo from the current directory:
```bash
gh repo view --json nameWithOwner --jq .nameWithOwner
gh api user --jq .login   # current user, for watermark filtering
```

List candidate PRs (merged in window):
```bash
SINCE=$(date -d "${DAYS:-7} days ago" +%Y-%m-%d)
gh pr list --state merged --search "merged:>=$SINCE" \
  --json number,title,mergedAt,author,url --limit 100
```

Closed-without-merge PRs are usually noise; skip them unless the user asks otherwise.

## Step 2: Filter out already-watermarked PRs

The watermark is the **🧠 label** on the PR. PRs carrying this label have already been included in a previous compound review — skip them.

Check existence:
```bash
gh pr view <n> --json labels --jq '[.labels[].name] | index("🧠")'
```
A non-null result means already processed.

If the label doesn't yet exist in the repo, create it once:
```bash
gh label create "🧠" --description "Included in compound PR review (prl)" --color "C9A0DC" 2>/dev/null || true
```

## Step 3: Mine signal per remaining PR

Two sources matter most. **Lead with what actually changed** — words can mislead, code edits can't.

### 3a. Post-review code changes (primary signal)

Look at commits and diffs *after* the first review round landed. These are the things the author or agent had to go back and fix — the most honest record of what was wrong.

```bash
gh pr view <n> --json commits,reviews
gh api repos/<owner>/<repo>/pulls/<n>/commits
```

Identify the first review timestamp (any review or review-comment), then diff the head of that point against the merge commit:
```bash
gh api repos/<owner>/<repo>/pulls/<n>/commits --jq '.[].sha'
# pick the SHA at first-review-time and the merge SHA, then:
git diff <pre-review-sha>..<merge-sha>
```

For each post-review change, ask: *what category of mistake did this fix?* Test gap, missing edge case, naming, validation, cache/state, error handling, etc. Categorise — these categories are the raw material for clustering.

Reverts and follow-up PRs that touch the same code are even stronger signal — record them.

### 3b. Review comments (secondary signal)

```bash
gh api repos/<owner>/<repo>/pulls/<n>/comments        # inline
gh api repos/<owner>/<repo>/issues/<n>/comments       # top-level
```

- **Greptile** (`greptile-apps[bot]`): which got 👍 (accepted) vs 👎 (rejected). Accepted = real bug worth tracking. **Repeatedly-rejected greptile findings are themselves a finding** — they reveal a codebase idiom that external tools don't understand. Often the right action is a lint that encodes the idiom so greptile (and other tools) stop flagging it.
- **`/prr` skill** comments (containing `<!-- automated-pr-review -->`): which got `"Fixed — ..."` replies vs `"Skipping — ..."`.
- **Human comments**: read for context; humans surface things tools miss.

### 3c. Build a per-PR record

Compact, structured: PR number, scope of change, categorised post-review fixups, accepted findings, rejected findings. This record is what you cluster from in Step 4 — not the raw comment text.

## Step 4: Identify candidates for action

Look at the per-PR records together. Two questions to ask:

1. **Are there themes that recur?** Group findings by category. The unit of a recurring finding is the *concrete mistake*, not a vague label — "missed pagination on list endpoint" is a category; "test issue" is not. If the only thing two findings share is a coarse label, they aren't a real cluster.
2. **Is there any single finding important enough to act on alone?** Severity, blast radius, or high recurrence cost can promote a one-off.

For each candidate, classify:

| Verdict | Meaning | Action |
|---|---|---|
| **Worth acting on** | Recurs meaningfully OR is severe / high-cost on its own. | Continue to Step 5. |
| **Real but not worth acting on** | Genuine but low-impact, isolated, or unlikely to repeat. | Note in the report's "considered and rejected" section. No proposal. |
| **Style / taste** | Preference, not quality. | Drop. |
| **Already covered** | An existing rule, lint, or test policy should catch it. | The proposal — if any — is about enforcement of the existing rule, not adding a new one. |

## Step 5: For each candidate, choose the right fix

Look at the toolbox honestly. Don't reach for the first thing — reach for the thing that actually addresses *this* failure mode at *this* place in the codebase. The right mechanism is the one with the highest ratio of (problems prevented) to (ongoing cost).

Think through, for each candidate:

- **Where does the failure actually happen?** A pattern that only matters in `/api/billing` shouldn't be enforced globally. A pattern that's truly universal shouldn't be hidden in a sub-directory.
- **What's catching it today, and why isn't that working?** If lint should have caught it but didn't — the fix is the lint config, not a new rule.
- **Is this consideration mechanical or judgmental?** "Don't import X from Y" is mechanical. "Think about cache invalidation when touching user state" is judgmental — a lint can't carry that, a written rule can.
- **Is it load-bearing, or restating something obvious?** Drop the obvious.
- **What does it displace?** Every addition has a cost, and rules in particular dilute the weight of the rules already there. Is this finding worth that dilution?
- **Is it specific?** "Be careful with caching" is useless. Either name the exact case ("when adding a route that reads from `users`, invalidate `user:{id}` keys") or don't propose it.

If no mechanism cleanly fits, the right answer may be "this is a real pattern but no enforcement is worth its cost." Say so. That is a legitimate verdict.

## Step 6: Output the report

Present a single report. Keep it terse.

```markdown
## Compound PR Review — <date range>

**Window**: <N> PRs reviewed (#X, #Y, #Z, ...)

### Observations
- <theme or single notable finding> — PR refs. Brief description.
- ...

### Proposals
1. **<short title>** — <chosen mechanism>
   - What: <concrete change, including file path>
   - Why: <PR refs and the cost of leaving it>
   - Why this mechanism: <one line — why this tool fits this problem>

### Considered and rejected
- <theme>: <one-line reason — taste, low-impact, already covered, etc.>
```

If there are no proposals, the Proposals section reads:

> No issues worth acting on in this window.

That is a complete, valid report. Do not pad it.

**Do not auto-apply changes.** Propose, let the user accept. If accepted, the user runs the edits or asks you to.

## Step 7: Watermark every PR processed

After the report — including PRs that contributed nothing to it — apply the 🧠 label:

```bash
gh pr edit <n> --add-label "🧠"
```

The watermark means "considered in a compound review", not "had findings". Watermarking PRs that contributed nothing is correct: it prevents re-processing them next week.

## Anti-patterns

- **Manufacturing findings** to make the report feel substantive. The empty report is a valid report.
- **Rule inflation** — turning every minor preference into a line in `AGENTS.md`.
- **Vague rules** — "consider performance", "be careful with X". Specific or nothing.
- **Duplicating existing guidance** — read the current `AGENTS.md` / `CLAUDE.md` / scoped sub-files *before* proposing additions. If the rule exists and was ignored, the fix is enforcement, not repetition.
- **Nit aggregation** — bundling ten small style points into one "finding".
- **Re-reviewing each PR** — that's `/prr`'s job. You're looking at the body of work, not redoing line-by-line review. Per-PR observations are inputs to clustering, not the output.
- **Judging the trend** — this skill is not a quality scorecard. Don't claim things are "improving" or "getting worse"; you don't have the cross-run memory to back that up. Just report what you found in this window.
