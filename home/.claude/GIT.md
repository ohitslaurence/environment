# Git Workflow with Gritty

Use Gritty (`gritty`) for all git commit and PR operations. It provides AI-powered commit messages, intelligent change grouping, and PR generation.

## Core Commands

| Task | Command |
|------|---------|
| Commit with AI message | `gritty commit` |
| Organize multiple changes | `gritty compose` |
| Create PR | `gritty pr` |
| Review PR | `gritty review <number>` |
| Create/switch branch | `gritty branch feat/name` |

## PR Workflow (Team Projects)

Always create PRs for team projects - never merge locally to main.

```bash
# 1. Create branch
gritty branch feat/auth

# 2. Work on feature...

# 3. Commit (use --accept for non-interactive)
gritty commit --accept

# 4. Create PR with AI-generated description
gritty pr --accept

# 5. After PR merged on GitHub, switch back
gritty branch main
git pull
```

## Intelligent Compose

When you have many uncommitted changes across different concerns, use `compose` to organize them:

```bash
gritty compose --accept
```

**How it works:**
1. Analyzes all staged, unstaged, and untracked files
2. AI proposes logical commit groupings (e.g., "feature + tests", "refactor", "docs")
3. Creates separate commits for each grouping with appropriate messages

Great for end-of-day commits or when you've been working on multiple things.

## Speed Tiers

```bash
gritty commit --fast    # Haiku - quick, simple changes
gritty commit           # Sonnet - balanced (default)
gritty commit --slow    # Opus - highest quality
```

## Commit Best Practices

**Commit frequently.** Small, atomic commits that represent one logical change. Don't batch up hours of work into one commit.

**Use gritty for messages.** It analyzes diffs and generates conventional commit messages matching your repo's style.

**Add context when helpful:**
```bash
gritty commit --context "fixing the auth bug from issue #123"
```

## PR Creation

```bash
# Create PR with AI-generated title and description
gritty pr

# Preview without creating
gritty pr --dry-run

# Create as draft
gritty pr --draft

# Add context for better description
gritty pr --context "implements RFC-123"
```

## PR Review

```bash
# Review a specific PR
gritty review 123

# List open PRs and select one
gritty review

# Post review to GitHub
gritty review 123 --post
```

## Pushing

**Branches: push freely.** Push to feature branches whenever you want.

```bash
git push -u origin feat/auth    # First push sets upstream
git push                        # Subsequent pushes
```

**Main: never push without permission.** Ask before pushing to main.

## When User Says...

| User Says | Action |
|-----------|--------|
| "Commit this" | `gritty commit --accept` |
| "Organize my changes" | `gritty compose --accept` |
| "Create a PR" | `gritty pr --accept` |
| "Review this PR" | `gritty review <number>` |
| "Start a new feature" | `gritty branch feat/name` |

## Important: Non-Interactive Mode

**Always use `--accept` flag** when running gritty from Claude Code, since interactive prompts (y/n/e) cannot be answered.

```bash
gritty commit --accept     # Auto-accept generated message
gritty compose --accept    # Auto-accept all groupings
gritty pr --accept         # Auto-accept PR description
```

## Don't

- Never push to main without explicit permission in the session
- Never batch up large changes - commit frequently or use `compose`
- Never skip `--accept` flag when running from Claude Code
