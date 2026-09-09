#!/usr/bin/env bash
# Convert canonical clones to bare repositories so nothing can edit them.
# All work happens in <repo>-wt-<task> worktrees (see `dev`).
#
#   scripts/bare-canonicals.sh [--dry-run] <repo-path>...
#
# Refuses any repo that is dirty or not on its base branch; rescue those first
# (commit, or `git worktree add <repo>-wt-<branch> <branch>`), then re-run.
# Reversible: git -C <repo> config core.bare false && git -C <repo> checkout <base>
set -euo pipefail
dry=0; [[ "${1:-}" == "--dry-run" ]] && { dry=1; shift; }
for repo in "$@"; do
  repo="${repo%/}"
  name="$(basename "$repo")"
  if [[ ! -d "$repo/.git" ]]; then echo "skip  $name: no .git directory"; continue; fi
  if [[ "$(git -C "$repo" rev-parse --is-bare-repository)" == "true" ]]; then echo "ok    $name: already bare"; continue; fi
  base="$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"; base="${base:-main}"
  branch="$(git -C "$repo" branch --show-current)"
  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then echo "REFUSE $name: dirty"; continue; fi
  if [[ "$branch" != "$base" ]]; then echo "REFUSE $name: on '$branch', not '$base'"; continue; fi
  if (( dry )); then echo "would $name: make bare (base=$base)"; continue; fi
  # Remove every working file except .git, then flip the flag.
  find "$repo" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  git -C "$repo" config core.bare true
  # Sanity: worktrees still resolve and the base ref is intact.
  git -C "$repo" worktree list >/dev/null
  git -C "$repo" rev-parse --verify -q "refs/heads/$base" >/dev/null
  echo "bare  $name (base=$base, $(git -C "$repo" worktree list | grep -c -- '-wt-') worktrees)"
done
