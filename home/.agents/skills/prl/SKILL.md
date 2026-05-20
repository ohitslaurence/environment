---
name: prl
description: Audit the system that produced the last week of PRs — agent guidance, lint, repo shape, test policy, CI gates — and propose changes that would steer future PRs toward better outcomes. Not delayed PR review. Not a bug hunt.
disable-model-invocation: true
argument-hint: [--days N]
allowed-tools: Bash(gh *), Bash(git *), Bash(date *), Bash(jq *), Read, Grep, Glob, Edit, Write
---

# PR Compound Review — Audit the System, Not the PRs

You are auditing **the system that produces PRs in this repo** — the agent guidance (`AGENTS.md`, scoped sub-files, `CLAUDE.md`), the lint and type config, the repo's structural shape (helpers, types, abstractions), the test policy, the CI gates. The last week of merged PRs is your evidence of how that system performed.

You are **not** reviewing the PRs. The PRs already shipped. The mistakes are already made or already fixed. The question is not "what's wrong with this code?" — it is:

> **"What was missing from the system that would have steered the agent or author away from these mistakes before they were written?"**

A bug is not a finding. A bug is *evidence*. The finding is the gap in guidance, tooling, or repo structure that the bug reveals. The proposal is the change to that system.

## The reward function

**Real systemic gaps found and meaningfully closed.** Not rules added. Not bugs reported. Not specific code patched.

If the window's PRs reveal no systemic gap worth addressing, the right output is:

> "No systemic gaps worth addressing in this window."

That is a success. **Do not manufacture findings to justify the run.** Do not grade on a curve.

## What you are NOT doing

- **Not reviewing the PRs.** Specific bugs in current code belong in an issue tracker. If a proposal reads "fix this code path" or "add a test for this function" — that is a bug fix, not a learning. File it separately and drop it from this report.
- **Not extending `/prr`.** This is not delayed code review. Per-PR observations are *inputs* — raw signal that you cluster and abstract from. The output lives one level up.
- **Not generating a feature-specific to-do list.** A list of fixes for one feature area is a backlog. This skill produces changes to guidance, tooling, or structure that affect **how the next PR gets written** — not patches to what last week's PRs did wrong.

## The litmus test

Before any proposal can move past draft, answer concretely:

> **"If this had been in place when these PRs were written, would the PRs themselves have come out differently — and would it generalise to PRs you haven't seen yet?"**

- ❌ "The bug would have been caught later" — that is reviewer tooling, not a system change. Drop.
- ❌ "This specific bug would not have happened" — too local. If the same intervention can't prevent the *class* of mistake elsewhere in the codebase, it's a bug fix masquerading as a learning. Drop.
- ✅ "The agent would have considered X by default / written test Y unprompted / used helper Z without thinking, across the whole class of work this affects." That is the right altitude.

If you cannot articulate a concrete system-level "yes" — drop the proposal. The underlying bug, if real, gets filed as an issue and is not part of this report.

## Why the bar is high (for written rules in particular)

Every line in `AGENTS.md`, `CLAUDE.md`, or scoped sub-`AGENTS.md` files costs context weight on every future agent invocation. Each addition dilutes the weight of everything already there. A rule that doesn't earn its line makes the ones that do less effective.

So the bar for proposing a written rule is: **the cost of repeating this class of mistake is greater than the cost of carrying this rule in agent context forever.** If you can't argue that confidently, drop it.

Mechanical enforcement (lint, type, structural) carries far less context cost than written rules. That doesn't make it always the right answer — it makes the cost-side of the calculation different. Weigh it honestly per finding.

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

- **Bug fixes for current code.** "Add a test for X", "fix this validation in Y", "the helper at Z is wrong." These are issues, not learnings. They belong in a tracker, not this report.
- **One-feature structural changes.** A "structural helper" that only addresses one feature area's bug is a code fix dressed up as a system change. Structural proposals must shape a *class* of future work — not patch one place.
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

The watermark is the **`🧠 prl`** label on the PR. PRs carrying this label have already been included in a previous compound review — skip them.

> The label name pairs the emoji with text because GitHub rejects label names that are *only* a native emoji. Always use the exact string `🧠 prl` — do not improvise a near-substitute if the label doesn't exist yet; create it.

Check existence:
```bash
gh pr view <n> --json labels --jq '[.labels[].name] | index("🧠 prl")'
```
A non-null result means already processed.

If the label doesn't yet exist in the repo, create it once before the first watermark of the run:
```bash
gh label create "🧠 prl" --description "Included in compound PR review (prl)" --color "C9A0DC" 2>/dev/null || true
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
- **Strix security agent** (bot login containing `strix`): which got 👍 (accepted) vs 👎 (rejected). Accepted = a real security gap worth tracking, and worth asking whether the class of issue can be prevented systemically (lint, type, framework default). **Repeatedly-rejected strix findings** point to a security pattern the tool keeps misreading — encode the mitigation so it stops flagging it.
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

## Step 5: For each candidate, choose the right system change

Run the **litmus test** first (re-stated):

> If this had been in place when these PRs were written, would the PRs themselves have come out differently — and does it generalise to PRs you haven't seen yet?

If you can't answer concretely yes to both halves, the candidate is a bug or a one-feature fix, not a system change. Move it to `Bugs surfaced` and stop processing it as a proposal.

If it passes — pick the mechanism from the toolbox that actually fits. The right mechanism is the one with the highest ratio of (problems prevented across future work) to (ongoing cost).

Think through, for each candidate:

- **Where does the failure mode actually live?** In how the agent thinks (→ guidance), in what the code allows (→ lint/types/structure), in what the tests cover (→ test policy), in what the process gates (→ CI/checks)? Choose accordingly.
- **What's catching it today, and why isn't that working?** If lint should have caught it but didn't — the fix is the lint config, not a new rule. If guidance covered it but agents ignored it — the fix is enforcement, not more guidance.
- **Is this consideration mechanical or judgmental?** "Don't import X from Y" is mechanical → lint. "Think about cache invalidation when touching user state" is judgmental → written rule. Don't conflate.
- **Is it specific?** "Be careful with caching" is useless. Either name the exact case ("when adding a route that reads from `users`, invalidate `user:{id}` keys") or don't propose it.
- **What does it displace?** Every written rule dilutes the others. Is this finding worth that dilution? If unsure, prefer mechanical enforcement or drop.
- **Does it generalise?** A structural helper that only the wallet kit will ever use is a refactor, not a system change. A helper that establishes a pattern other features will follow is a system change.

If no mechanism cleanly fits at the system level — the right answer may be "this is a real pattern but no system-level intervention is worth its cost." Say so. That is a legitimate verdict.

## Step 6: Output the report

Present a single report. Keep it terse. **Every proposal is a system change** — to guidance, lint, structure, test policy, CI, or process. Specific bugs go in `Bugs surfaced (filed separately)` — they are evidence, not findings.

```markdown
## Compound PR Review — <date range>

**Window**: <N> PRs reviewed (#X, #Y, #Z, ...)

### Systemic gaps
- <gap in the system> — what the system failed to do. PR refs as evidence.
- ...

### Proposals
1. **<short title>** — <chosen mechanism: lint / test policy / structural / scoped rule / root rule / CI / process>
   - What: <concrete change to the system — not to a code path>
   - Why: <which gap this closes; PR refs as evidence>
   - Counterfactual: "If this had been in place, [PR X / class of PRs] would have ___" — the litmus test, in writing.
   - Generalises to: <what other future work this affects, beyond the evidence PRs>

### Considered and rejected
- <theme>: <one-line reason — too local, taste, already covered, no credible mechanism, etc.>

### Bugs surfaced (filed separately)
- <one-line bug>: <PR ref, suggested action — issue / hotfix / follow-up PR>
```

If there are no proposals, the Proposals section reads:

> No systemic gaps worth addressing in this window.

That is a complete, valid report. Do not pad it. The `Bugs surfaced` list, if any, can still be present — surfacing a bug is not the same as proposing a system change.

**Do not auto-apply changes.** Propose, let the user accept.

## Step 7: Watermark every PR processed

After the report — including PRs that contributed nothing to it — apply the `🧠 prl` label:

```bash
gh pr edit <n> --add-label "🧠 prl"
```

If the label-add fails (e.g. label not yet created in this repo), run the `gh label create` from Step 2 once, then retry. **Do not silently substitute a different label name** — the watermark must be consistent across runs, or PRs will be re-processed.

The watermark means "considered in a compound review", not "had findings". Watermarking PRs that contributed nothing is correct: it prevents re-processing them next week.

## Anti-patterns

- **Treating bugs as findings.** A specific bug in current code is *evidence*, not a finding. The finding is what that bug reveals about the system. If your proposal patches a code path or names one file as the fix, you've produced a backlog item, not a learning.
- **One-feature structural proposals.** "Add a helper for the wallet kit address access" — if the helper only matters for one feature, it is a code fix. Structural proposals must shape a *class* of work.
- **Failing the litmus test silently.** Every proposal must answer "would the PRs have come out differently, and does it generalise?" If you can't answer concretely — drop it.
- **Manufacturing findings** to make the report feel substantive. The empty report is a valid report.
- **Rule inflation** — turning every minor preference into a line in `AGENTS.md`.
- **Vague rules** — "consider performance", "be careful with X". Specific or nothing.
- **Duplicating existing guidance** — read the current `AGENTS.md` / `CLAUDE.md` / scoped sub-files *before* proposing additions. If the rule exists and was ignored, the fix is enforcement, not repetition.
- **Nit aggregation** — bundling ten small style points into one "finding".
- **Re-reviewing each PR** — that's `/prr`'s job. You're looking at the body of work, not redoing line-by-line review. Per-PR observations are inputs to clustering, not the output.
- **Judging the trend** — this skill is not a quality scorecard. Don't claim things are "improving" or "getting worse"; you don't have the cross-run memory to back that up. Just report what you found in this window.
