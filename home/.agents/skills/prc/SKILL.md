---
name: prc
description: Process automated PR review comments (Greptile, Strix security agent, and /prr skill), fix valid findings, react to train reviewers, and do a final pass on the diff.
disable-model-invocation: true
argument-hint: <pr-url-or-number>
allowed-tools: Bash(gh *), Bash(git *), Bash(gritty *), Read, Edit, Write, Grep, Glob
---

# PR Review Cleanup

You are processing automated code review comments on a pull request. Your job is to triage each finding, fix the valid ones, train the reviewers with reactions, and do a final quality pass.

## Important Context

This PR may have review comments from three automated sources:

### Greptile (`greptile-apps[bot]`)
Automated bug-finding reviewer. Does NOT have full codebase context. It frequently:
- Flags patterns that are intentional project conventions
- Misunderstands middleware/framework behavior
- Suggests changes that would break other parts of the system
- Raises valid points about real bugs or oversights

### Strix security agent (bot account, e.g. `strix-bot` / `strix-app[bot]`)
Autonomous AI security-testing agent. Present only on some PRs. It focuses on security concerns — injection, auth/authorization gaps, secret handling, unsafe deserialization, SSRF, and similar. Like Greptile it lacks full codebase context, so it can:
- Flag intentional, already-mitigated, or internal-only patterns as vulnerabilities
- Miss compensating controls elsewhere in the request chain
- Surface genuine, high-impact security bugs that the other reviewers don't

Treat Strix findings with extra care: a false negative on a real security issue is costlier than on a style nit. When a Strix finding is plausible but you can't confirm the control flow is safe, ask rather than dismiss.

### `/prr` skill (`<!-- automated-pr-review -->`)
Craft-focused review posted via the user's GitHub account. Comments contain `<!-- automated-pr-review -->` as the last line. These focus on architecture, readability, testing quality, and PR clarity — not correctness.

**Process comments from all three sources.** Ignore comments from humans or other bots that don't match these patterns.

**Your job is to use your full codebase understanding to judge each finding on its merits.**

## Step 1: Gather PR Context

Extract the owner, repo, and PR number from `$ARGUMENTS`. Supports both URLs (`https://github.com/owner/repo/pull/123`) and plain numbers (requires being in the repo).

```bash
# Get PR metadata
gh pr view <number> --repo <owner/repo> --json title,body,headRefName,baseRefName

# Get the diff
gh pr diff <number> --repo <owner/repo>

# Get top-level comments (the summary)
gh api repos/<owner>/<repo>/issues/<number>/comments

# Get inline review comments
gh api repos/<owner>/<repo>/pulls/<number>/comments
```

**Only process comments from `greptile-apps[bot]`, the Strix bot account (login containing `strix`), or those containing `<!-- automated-pr-review -->`.** Ignore all other comments.

Checkout the PR branch locally so you can read and edit the actual code:
```bash
gh pr checkout <number> --repo <owner/repo>
```

## Step 2: Understand the PR

**If you did not write the code in this PR**, you must build a thorough mental model before judging any findings:

1. Read the PR description and commit messages to understand the author's intent
2. Read the full diff carefully — understand what changed and why
3. Read the surrounding code that the diff touches — understand the broader context (conventions, patterns, framework usage)
4. Look at recent commits on the branch to understand the evolution of the changes

You need to understand the code as well as the person who wrote it before you can judge whether a finding is valid. Don't rush this step.

If you wrote the code in this PR, you already have this context — move on.

## Step 3: Ask Before Assuming

Some findings require domain knowledge or context you may not have. **If a finding is ambiguous and you can't determine validity from the code alone, ask the user.** Examples:

- "Greptile says X is a bug, but it looks intentional. Was this by design?"
- "This finding suggests adding validation, but I'm not sure if this endpoint is internal-only. Should I add it?"
- "The reviewer flagged missing tests — should I add them or is that out of scope for this cleanup?"

**Do not guess. Do not silently skip. Ask.**

## Step 4: Triage Each Finding

For each automated review comment (Greptile, Strix, and `/prr` skill), classify it:

| Verdict | Action | Reaction |
|---------|--------|----------|
| **Valid bug/issue** | Fix it | 👍 (`+1`) on the inline comment |
| **Exceptional catch** | Fix it | 👍 (`+1`) AND 🚀 (`rocket`) on the inline comment |
| **Invalid / misunderstanding** | Don't fix | 👎 (`-1`) + reply explaining why |
| **Cosmetic / style nit** | Ignore | No reaction |
| **Valid but out of scope** | Ignore | No reaction |

### Reacting to comments

For inline review comments:
```bash
# React
gh api repos/<owner>/<repo>/pulls/comments/<comment_id>/reactions -f content="+1"
gh api repos/<owner>/<repo>/pulls/comments/<comment_id>/reactions -f content="-1"
gh api repos/<owner>/<repo>/pulls/comments/<comment_id>/reactions -f content="rocket"

# Reply (required when giving thumbs down, to train Greptile)
gh api repos/<owner>/<repo>/pulls/<number>/comments -f body="<explanation>" -f commit_id="<sha>" -f path="<path>" -f line=<line> -f side="RIGHT" -f in_reply_to=<comment_id>
```

For top-level issue/summary comments: do NOT react. They're just aggregates.

### Reacting by source

**Greptile comments** — react with 👍/👎/🚀 as described above. Thumbs-down replies train Greptile's learning system.

**Strix comments** — react with 👍/👎/🚀 as described above (it's a separate bot account, so emoji reactions are appropriate). When you 👎 a Strix finding, reply explaining why it's not a real security issue — be specific about the compensating control or why the path isn't reachable, so a reviewer reading later can verify your reasoning.

**`/prr` skill comments** — these were posted from the user's own GitHub account. Do NOT react with emojis (reacting to your own comments looks odd). Instead:
- **Valid**: Fix it, then reply with a brief note: `"Fixed — [what you did]"`
- **Invalid**: Reply explaining why it doesn't apply: `"Skipping — [reason]"`
- **Cosmetic/out of scope**: No reply needed

### Writing thumbs-down replies (Greptile only)

When you 👎 a Greptile finding, you MUST reply explaining why. Keep it brief and specific — this trains Greptile:
- ✅ `"This middleware intentionally catches all exceptions; HTTPException is re-thrown upstream in the error handler chain"`
- ✅ `"Admin endpoints don't support transaction lookup by design — documented in API spec"`
- ❌ `"Not applicable"` (too vague, doesn't help Greptile learn)

## Step 5: Fix Valid Issues

Make the code changes for all findings you classified as valid. Work through them methodically.

## Step 6: Commit and Push

Before committing, run the project's checks — lint, format, typecheck, and tests. Fix any issues your changes introduced. Then commit and push:
```bash
gritty commit --accept
git push
```

If there are no fixes to make, skip this step.

## Step 7: Final Pass

Review the full PR diff one more time with the context of what you learned from the findings. Look for:
- Anything the reviewer missed that follows the same pattern
- Related issues in nearby code
- Edge cases the fixes might have introduced

## Step 8: Summary

Present a table of all findings and your verdicts:

```
| # | Finding | File | Verdict | Action |
|---|---------|------|---------|--------|
| 1 | HTTPException swallowed | cursor.ts | ✅ Valid | Fixed — re-throw in middleware |
| 2 | No field validation | payments.ts | ✅ Valid | Fixed — added VALID_FIELDS check |
| 3 | Missing tests | payments.test.ts | ⏭️ Out of scope | Skipped |
| 4 | Transaction silent ignore | payments.ts | ❌ Invalid | By design — replied to Greptile |
```

Then a brief note on your final pass:
- "Final pass: found no additional issues" OR
- "Final pass: found and fixed X additional issue(s): [description]"
