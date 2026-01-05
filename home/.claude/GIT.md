# Git Workflow with Worktrees

Use Worktrunk (`wt`) for all git operations. Never use raw git commands for branching or merging.

## Mental Model

**One branch = one directory.** Each feature gets its own worktree - isolated files, no stashing, no context bleeding.

```
~/dev/project          ← main (always clean)
~/dev/project.feat-a   ← feat-a worktree
~/dev/project.feat-b   ← feat-b worktree
```

## Core Commands

| Task | Command |
|------|---------|
| Start new feature | `wt switch -c feat/name` |
| Switch to worktree | `wt switch feat/name` |
| List all worktrees | `wt list` |
| Remove worktree | `wt remove` |

## PR Workflow (Team Projects)

Always create PRs for team projects - never merge locally to main.

```bash
# 1. Create worktree
wt switch -c feat/auth

# 2. Work on feature...

# 3. Commit and push
wt step commit          # Commits with optional LLM message
git push -u origin feat/auth

# 4. Create PR with good description
gh pr create --title "feat(auth): Add JWT authentication" --body "$(cat <<'EOF'
## Summary
Brief description of what this PR does and why.

## Changes
- Added JWT token validation middleware
- Implemented refresh token rotation
- Added auth error handling

## Testing
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Edge cases covered

## Notes
Any context reviewers should know.
EOF
)"

# 5. After PR merged on GitHub, cleanup
wt remove
```

**PR descriptions should:**
- Summarize the what and why upfront
- List concrete changes made
- Include testing checklist
- Note any risks, migrations, or follow-up work

## Solo/Trusted Workflow

For personal projects or pre-approved changes, merge locally:

```bash
wt switch -c fix/typo
# ... fix ...
wt merge                # Squash + merge to main + cleanup
git push
```

## Parallel Features

When the user wants multiple features in parallel:

```bash
# Create worktrees for each
wt switch -c feat/auth
wt switch -c feat/billing
wt switch -c feat/dashboard

# Each can have its own Claude session
# wt list shows status of all
```

## Commit Best Practices

**Commit frequently.** Small, atomic commits that represent one logical change. Don't batch up hours of work into one commit.

**Write clear messages.** The message should explain *what* changed and *why* - someone reading the log should understand the intent.

Format: `type(scope): imperative description`

```
feat(auth): Add JWT refresh token rotation
fix(api): Handle null response in user endpoint
refactor(db): Extract connection pooling to separate module
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

## Pushing

**Branches: push freely.** Push to feature branches whenever you want - it's your workspace.

```bash
git push -u origin feat/auth    # First push sets upstream
git push                        # Subsequent pushes
```

**Main: never push without permission.** Even after `wt merge`, ask before pushing to main.

```
# After wt merge completes:
"Ready to push to main - want me to push?"
# Only push if user confirms
```

## When User Says...

| User Says | Action |
|-----------|--------|
| "Start a new feature" | `wt switch -c feat/name` |
| "Work on X in parallel" | Create multiple worktrees |
| "Create a PR" | `wt step commit && git push && gh pr create` |
| "Merge this" | Ask: PR or local merge? Use `wt merge` only for solo |
| "Clean up" | `wt remove` after PR merged |
| "What branches?" | `wt list` |

## Project Hooks

If `.config/wt.toml` exists in project root, hooks run automatically:

```toml
post-create = "pnpm install"
post-start = "pnpm dev --port {{ branch | hash_port }}"

[pre-merge]
test = "pnpm test"
typecheck = "pnpm tsc --noEmit"
```

## Don't

- Never `git checkout` to switch branches - use `wt switch`
- Never merge to main locally on team projects - create PR
- Never commit directly to main - always use feature worktree
- Never push to main without explicit permission in the session
- Never batch up large changes - commit frequently
- Never leave stale worktrees - `wt remove` after done
