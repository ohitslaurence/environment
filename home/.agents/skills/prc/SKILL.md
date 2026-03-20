---
name: prc
description: Process automated PR review comments (Greptile), fix valid findings, react to train the reviewer, and do a final pass on the diff.
disable-model-invocation: true
argument-hint: <pr-url-or-number>
allowed-tools: Bash(gh *), Bash(git *), Bash(gritty *), Read, Edit, Write, Grep, Glob
---

# PR Review Cleanup

You are processing automated code review comments left by **Greptile** on a pull request. Your job is to triage each finding, fix the valid ones, train the reviewer with reactions, and do a final quality pass.

## Important Context

Greptile is an automated reviewer. It does NOT have full codebase context. It frequently:
- Flags patterns that are intentional project conventions
- Misunderstands middleware/framework behavior
- Suggests changes that would break other parts of the system
- Raises valid points about real bugs or oversights

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

**Only process comments from `greptile-apps[bot]`.** Ignore comments from humans or other bots.

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

For each Greptile comment (both inline and from the summary), classify it:

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

For top-level issue comments (the summary): do NOT react. It's just an aggregate.

### Writing thumbs-down replies

When you 👎 a finding, you MUST reply explaining why. Keep it brief and specific — this trains Greptile:
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
