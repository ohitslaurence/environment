# Personal Development Preferences

## Communication

- Extremely concise - sacrifice grammar for brevity
- Brief over verbose
- Incremental changes reviewable in git diffs
- Summarize completed work with decision rationale
- Suggest commits after completing tasks

## Code Style

### TypeScript

- Strict mode always
- Avoid `any` - use `unknown` and narrow it
- Explicit types for clarity
- Runtime validation with Zod
- Never use dynamic imports (`await import()`) - always static imports at top of file

### Naming

- Files: kebab-case
- Variables/functions: camelCase
- Constants: UPPER_SNAKE_CASE

### Organization

- Named exports only
- No barrel/index exports - import from source files directly
- Logical file groupings over large files
- Match existing style when it follows best practices

## Workflow

### Git

- Small, frequent commits
- Format: header + bullet summary
  ```
  Add user authentication middleware

  - Implement JWT validation
  - Add error handling for expired tokens
  ```

### Development

- Maximum 4 files at a time
- Only implement what's asked - no scope creep
- Ask before refactoring legacy code

### Testing

- Write tests after implementation
- Prefer Vitest over Jest

## Technology

### Packages

- Monorepos: npm
- Other projects: pnpm
- Simple implementations over packages when reasonable
- Preferred: zod, tiny-async-pool
- Avoid: axios

### AWS/Serverless

- middy for Lambda middleware
- Separate business logic from handlers
- SST v3 for infrastructure

## Research

If the Nia MCP server is available, use it heavily for research:
- Obscure framework configurations and setups
- Getting unfamiliar tooling working
- Best practices and modern patterns
- Problems where the answer isn't immediately clear

Use `nia_research` with `mode: "deep"` for complex questions - it's extremely effective at finding solutions that aren't obvious from basic searches.

## Error Handling

Check the project for which error handling approach is used:

@NEVERTHROW.md

## Architecture

- Suggest improvements but don't implement without approval
- Flag performance and security concerns proactively
- Prefer functional composition over OOP

## Collaboration

When I make suggestions or say "I think":
- Verify against documentation and actual code
- Challenge if something seems wrong
- Goal is collaborative accuracy - catch each other's mistakes
