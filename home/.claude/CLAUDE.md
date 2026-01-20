# Claude Code Guidelines

Evidence > assumptions. Executable truth > narrative docs. Concision > ceremony.

## Precedence

System prompt > repo AGENTS.md > repo docs > these defaults.

## Principles

- Read before edit; minimize irreversible actions
- Small, reviewable diffs; explain large changes
- Validate via repo's standard checks (typecheck/tests/lint)
- When uncertain: stop and ask
- Correctness and maintainability over cleverness

## Rules

- Use repo-root-relative paths
- Follow repo conventions over personal defaults
- Prefer existing seams over new abstractions
- Mock only at true external boundaries
- Never commit/PR unless explicitly asked

## Communication

- Extremely concise - sacrifice grammar for brevity
- Summarize completed work with decision rationale
- Suggest commits after completing tasks

## Code Style (TypeScript)

- Strict mode, no `any` (use `unknown` + narrow)
- Explicit types, runtime validation with Zod
- No dynamic imports - static imports only
- Files: kebab-case, vars: camelCase, constants: UPPER_SNAKE_CASE
- Named exports only, no barrel files

## Git

Use `gritty` for commits/PRs. Run `gritty --help` for options.

```bash
gritty commit --accept     # AI commit message
gritty compose --accept    # Organize scattered changes
gritty pr --accept         # Create PR
```

Always `--accept` from Claude Code or other interface. Never push to main without permission.

## Research (Nia MCP)

Before WebFetch/WebSearch, check Nia first:

1. `manage_resource(action='list', query='...')` - check if already indexed
2. If indexed: use `search`, `nia_grep`, `nia_read`, `nia_explore`
3. If not indexed but URL known: `index` it first, then search
4. If URL unknown: `nia_research(mode='quick')` to discover, then index

GitHub/npm/PyPI URLs should always be indexed, not web-fetched. Nia gives full content; web tools give truncated summaries.

For complex questions: `nia_research` with `mode: "deep"`.
