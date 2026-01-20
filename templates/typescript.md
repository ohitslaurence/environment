# Project Guidelines

## Code Style

### TypeScript
- Strict mode always
- No `any` - use `unknown` and narrow
- Explicit return types on exported functions
- Runtime validation with Zod at boundaries

### Naming
- Files: kebab-case
- Variables/functions: camelCase
- Types/interfaces: PascalCase
- Constants: UPPER_SNAKE_CASE

### Imports
- Group: external → internal → relative
- Named exports only, no default exports
- No barrel/index files - import from source directly
- No circular dependencies

### Async
- Always handle promise rejections
- Use try/catch for async operations
- No floating promises

## Testing
- Use project's test runner
- Mock only at true external boundaries
- Test error paths, not just happy path
