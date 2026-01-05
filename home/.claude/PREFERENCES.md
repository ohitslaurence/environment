# Personal Development Preferences for Claude

## Communication Style

- Provide brief explanations, especially when deviating from initial concepts
- Focus on making incremental changes that are easy to review in git diffs
- After completing tasks, provide brief summary with key context and decision rationale
- Prioritize clear, reviewable code over lengthy explanations

## Code Comments

- Avoid inline comments - use clear function/variable naming instead
- Document high-level functions with purpose and context for future LLM understanding
- Comments should explain "why" not "what" when necessary

## Code Style and Standards

### TypeScript

- Always use modern TypeScript best practices
- Strict mode always enabled
- Avoid `any` at all costs, `unknown` is acceptable but narrow it
- Be explicit with types for LLM clarity
- Leverage TypeScript to maximum effect with runtime validation (Zod)

### Naming Conventions

- Files: kebab-case
- Variables and functions: camelCase
- Constants: UPPER_SNAKE_CASE
- Follow project-specific linting rules

### Code Organization

- Prefer logical file groupings over large files
- Named exports only
- No index export files - import directly from the file where functionality is defined
- Alphabetical imports (use VS Code organize imports)
- Match existing style when it follows best practices
- When in doubt about legacy code patterns, ask before refactoring

## Development Workflow

### Git Commits

- Descriptive commit messages with high-level header and short summary
- Suggest commits after completing tasks
- Small, frequent commits for easier review
- Example format:

  ```
  Add user authentication middleware

  - Implement JWT validation
  - Add error handling for expired tokens
  ```

### Incremental Development

- Break large tasks into smaller subtasks
- Work on maximum 4 files at a time
- Make changes reviewable through git diffs
- Handle edge cases (make them clear)
- Only implement what's asked - no scope creep

### Testing

- Write tests after implementation
- Prefer Vitest over Jest
- Suggest test implementation after feature completion

## Technology Preferences

### Package Management

- Monorepos/workspaces: npm
- Other projects: pnpm (for performance)
- Simple implementations preferred over packages when reasonable
- Preferred packages: neverthrow, zod, tiny-async-pool
- Avoid: axios

### AWS/Serverless

- Use middy for Lambda middleware
- Separate business logic from handlers
- Transitioning from Serverless Framework to SST v3
- Handle errors carefully for queue/retry contexts

### Code Quality

- Tools: prettier, eslint, husky
- Add lint + fix scripts if missing
- Fix issues immediately when found

## Error Handling

Use neverthrow for all error handling. See detailed guidelines below.

@NEVERTHROW.md

## Architecture and Design

### Making Suggestions

- Suggest architectural improvements but don't implement without approval
- Be specific about what should change and why
- Flag performance and security concerns proactively
- Document big decisions in README files in subfolders or inline

### Code Review Focus

- Watch for anti-patterns
- Check variable naming quality
- Ensure DRY principles
- Verify proper formatting
- Create project-level todos.md for future improvements

### Development Philosophy

- Prefer functional composition over OOP
- Prioritize readability and understandability
- Professional engineering approach - not "vibe coding"
- Incremental progress with continuous review

## Key Principles

1. **Small, reviewable changes** - I review everything through git diffs
2. **No assumptions** - Ask when uncertain, especially with legacy code
3. **Professional engineering** - Quality, tested, reviewable code
4. **Incremental progress** - Build features step by step
5. **Clear communication** - Brief but informative updates
6. **Respect scope** - Do what's asked, no more, no less

## Collaborative Verification

### When You Make Suggestions

- When you say "I think" or make recommendations, I should verify and challenge if needed
- I will double-check documentation, APIs, and requirements before automatically agreeing
- I'll acknowledge what you're suggesting, then confirm whether it's correct
- Examples of good responses:
  - "Let me verify that idempotency header... I checked and it's actually optional in the docs, but adding it would be a good practice for safety"
  - "I see you're suggesting X. Let me confirm... Actually, the docs show Y is required instead. Here's the reference: [link]"
  - "You're right about that header - I missed it in the implementation. Let me add it now"
- I should be 100% certain before challenging your suggestions
- The goal is collaborative accuracy - we both catch things the other might miss

## Additional Rules

_This section will be updated as we work together and discover new preferences_
