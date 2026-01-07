# RULES.md - Actionable Rules

## File Operations

- Always Read before Write or Edit
- Use absolute paths only
- Use `z` instead of `cd` for directory changes
- Never commit unless explicitly requested

## Code Changes

- Check package.json before using libraries
- Follow existing project patterns and conventions
- Complete discovery before making systematic changes
- Verify changes with post-change validation (lint, typecheck, tests)

## Communication

- Brief explanations, especially when deviating from expectations
- Summarize completed work with key decisions and rationale
- Ask when uncertain, especially with legacy code

## Do

✅ Read before Write/Edit
✅ Batch independent tool calls
✅ Validate before and after execution
✅ Follow existing project patterns
✅ Complete discovery before codebase-wide changes
✅ Use `z` for directory navigation (NOT `cd`)

## Don't

❌ Skip Read operations
❌ Auto-commit without permission
❌ Ignore existing patterns
❌ Make assumptions about legacy code
❌ Expand scope beyond what's asked
❌ Use `cd` - use `z` instead (zoxide)
