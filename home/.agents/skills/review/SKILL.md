---
name: review
description: Deep PR review focused on craft, architecture, testing, and clarity. Complements automated bug-finding tools like Greptile by focusing on maintainability and code quality.
disable-model-invocation: true
argument-hint: <pr-url-or-number>
allowed-tools: Agent, Bash(gh *), Bash(git *), Read, Grep, Glob
---

# PR Review — Craft & Quality

You are reviewing a pull request for **craft, clarity, and maintainability** — not correctness. Automated tools like Greptile handle bug detection. Your job is to catch everything else: the things that make a codebase degrade over time, or that a senior engineer would flag in a thorough code review.

Ask yourself: **"Will we regret this in 6 months?"**

## Context

- Comments you post will appear as the user's GitHub account (since `gh` CLI uses their auth).
- There may already be review comments from Greptile (`greptile-apps[bot]`) or other reviewers. Read them first. Do not duplicate findings.
- All inline comments MUST include `<!-- automated-pr-review -->` as the last line so they can be identified programmatically.

## Step 1: Gather PR Context

Extract the owner, repo, and PR number from `$ARGUMENTS`. Supports both URLs (`https://github.com/owner/repo/pull/123`) and plain numbers (requires being in the repo).

```bash
# PR metadata
gh pr view <number> --repo <owner/repo> --json title,body,headRefName,baseRefName,commits

# Full diff
gh pr diff <number> --repo <owner/repo>

# Existing review comments (Greptile, humans, previous review runs)
gh api repos/<owner>/<repo>/issues/<number>/comments
gh api repos/<owner>/<repo>/pulls/<number>/comments
```

Checkout the PR branch:
```bash
gh pr checkout <number> --repo <owner/repo>
```

## Step 2: Understand the PR

Read the PR description, the full diff, and the surrounding code that the diff touches. You need to understand:

- What was changed and why
- The repo's established patterns and conventions
- The domain and business context

## Step 3: Launch Review Agents

Spawn **four agents in parallel** using the Agent tool. Each agent receives:
- The PR owner, repo, and number (so they can use `gh` CLI)
- The PR description and branch name
- Their specific review focus (below)
- Instructions to read existing comments before posting to avoid duplication

Each agent should checkout the PR branch, read the diff, read the relevant source files for context, and then post inline comments for anything they find.

### Agent prompts

Use the detailed instructions in the sections below for each agent. Every agent must follow the **Comment Format** rules.

---

### Agent 1: Architectural Fit

You are reviewing PR #<number> in <owner>/<repo> for **architectural fit**.

Checkout the branch, read the diff, and read the surrounding source code. Look for:

- **Pattern adherence**: Does this PR follow the patterns already established in the codebase? If it introduces a new pattern, is the old one migrated or do they now coexist?
- **Code placement**: Is the code in the right module, layer, and file? Would someone looking for this logic find it where it lives?
- **Abstraction quality**: Do new abstractions earn their existence? Are they at the right level — not too granular, not too broad?
- **Dependency direction**: Do high-level modules depend on low-level details? Are there circular or surprising dependencies introduced?
- **Reuse**: Are there existing utilities, helpers, or patterns being reinvented instead of reused?

Before posting, read existing comments from `greptile-apps[bot]` and any containing `<!-- automated-pr-review -->` to avoid duplicating findings:
```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments
```

Post inline comments using the comment format below. Only post findings that are genuinely worth raising.

---

### Agent 2: Craft & Readability

You are reviewing PR #<number> in <owner>/<repo> for **craft and readability**.

Checkout the branch, read the diff, and read the surrounding source code. Look for:

- **Code smells**: God functions (doing too many things), primitive obsession, feature envy, unnecessary indirection, overly clever code
- **Naming**: Will someone understand these names in 6 months without context? Do they convey intent or describe implementation?
- **Complexity**: Is there a simpler way to express this? Could a conditional chain be a lookup? Could nested logic be flattened?
- **Consistency**: Does the style and approach match the surrounding code? Are conventions followed?
- **Dead weight**: Anything added but unused, commented-out code left behind, old code that should've been cleaned up as part of this change

Before posting, read existing comments from `greptile-apps[bot]` and any containing `<!-- automated-pr-review -->` to avoid duplicating findings:
```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments
```

Post inline comments using the comment format below. Only post findings that are genuinely worth raising.

---

### Agent 3: Testing Integrity

You are reviewing PR #<number> in <owner>/<repo> for **testing integrity**.

Checkout the branch, read the diff, and read the test files and the code they test. Look for:

- **Behavior vs implementation**: Are tests asserting outcomes, or are they tightly coupled to internal implementation details (mocking internals, asserting call counts)?
- **Boundary correctness**: Are unit tests where they should be unit, integration where they should be integration? Is the testing level appropriate for what's being tested?
- **Assertion quality**: Are assertions meaningful? "It didn't throw" is not a test. "It returns the expected shape with the expected values" is.
- **Edge cases & failure modes**: Is only the happy path tested? Are error conditions, empty inputs, boundary values covered?
- **Test changes**: If existing tests were modified, was it to accommodate new behavior or to paper over a problem? Weakened assertions are a red flag.

Before posting, read existing comments from `greptile-apps[bot]` and any containing `<!-- automated-pr-review -->` to avoid duplicating findings:
```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments
```

Post inline comments using the comment format below. Only post findings that are genuinely worth raising.

---

### Agent 4: PR Clarity & Completeness

You are reviewing PR #<number> in <owner>/<repo> for **PR clarity and completeness**.

Read the PR description, commit messages, and the full diff. Look for:

- **Description accuracy**: Does the PR description match what was actually done? Are there undocumented changes?
- **Scope**: Is this one logical change, or several bundled together? Are there drive-by changes that should be separate PRs?
- **Intent clarity**: Could a reviewer with no context understand the *why* from the diff and description alone?
- **Loose ends**: Are there TODO/FIXME/HACK markers introduced without corresponding issues? Are there incomplete implementations?
- **Changelog-worthy omissions**: Are there breaking changes, API changes, or migration requirements not called out?

Before posting, read existing comments from `greptile-apps[bot]` and any containing `<!-- automated-pr-review -->` to avoid duplicating findings:
```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments
```

For this agent, some findings may be better as a top-level PR comment rather than inline. Use your judgement — if it's about a specific line, post inline. If it's about the PR as a whole (scope, description accuracy), post as a top-level comment using:
```bash
gh api repos/<owner>/<repo>/issues/<number>/comments -f body="<comment>"
```

Post using the comment format below. Only post findings that are genuinely worth raising.

---

## Comment Format

Every inline comment MUST follow this format:

```
**[<Dimension> · <Severity>]** <One-line summary>

<Explanation — 2-4 sentences. Be specific. Reference the code, the pattern, or the
convention being violated. If suggesting an alternative, show it briefly.>

<!-- automated-pr-review -->
```

**Dimensions**: `Arch`, `Craft`, `Test`, `Clarity`

**Severities**:
| Severity | When to use |
|----------|-------------|
| `Concern` | Will cause real problems — structural issue, misleading code, tests that prove nothing |
| `Suggestion` | Genuine improvement worth making — cleaner abstraction, better naming, missing edge case |
| `Nit` | Take it or leave it — style preference, minor inconsistency |

**Posting inline comments**:
```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments \
  -f body="<comment>" \
  -f commit_id="$(gh pr view <number> --repo <owner/repo> --json commits --jq '.commits[-1].oid')" \
  -f path="<file-path>" \
  -f line=<line-number> \
  -f side="RIGHT"
```

**Calibration**: Only post if you'd actually say it in a real code review. If in doubt, don't post. A review with 2 strong findings is better than 10 marginal ones.

## Step 4: Post Summary

After all four agents complete, collect the results. Read all comments posted during this review:

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments | jq '[.[] | select(.body | contains("automated-pr-review"))]'
```

Post a summary as a top-level PR comment:

```markdown
## PR Review

| Dimension | Concerns | Suggestions | Nits |
|-----------|----------|-------------|------|
| Architectural Fit | X | X | X |
| Craft & Readability | X | X | X |
| Testing Integrity | X | X | X |
| PR Clarity | X | X | X |

[1-2 paragraph overall assessment. Is this PR in good shape? What are the most
important things to address before merging? If it's clean, say so.]

<!-- automated-pr-review-summary -->
```

## Step 5: Report to User

Present the summary table and a brief note on key findings. Don't repeat everything — the inline comments are on the PR. Just highlight the most important items.
