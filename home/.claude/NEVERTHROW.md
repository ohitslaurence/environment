### Error Handling Strategy

**Primary**: Effect TS is the preferred error handling approach. Check if the project uses Effect before implementing error handling.

**Fallback**: When Effect is not available in a project, use neverthrow. The guidelines below apply to neverthrow-based projects only.

---

### Neverthrow Usage Guidelines

When a project uses neverthrow for error handling, follow these patterns to maintain consistency and type safety.

#### Core Principles

1. **Always prefer neverthrow** for error handling over try/catch blocks (when Effect is not available)
2. **Use safeTry with async/await generator syntax** for composing multiple async operations
3. **Wrap promises with toAsyncResult** helper function
4. **Provide helpful error messages and context** in all error cases
5. **Use typed errors** (ApplicationError, TransactionError) for better error handling

#### Primary Pattern: safeTry with yield\*

For composing multiple async operations, use safeTry with async generator functions:

```typescript
import { safeTry, okAsync, ResultAsync } from "neverthrow";

export function myComplexOperation(
  input: MyInput
): ResultAsync<MyResult, ApplicationError | TransactionError> {
  return safeTry(async function* () {
    // Yield individual async operations
    const user = yield* getUser(input.userId);
    const validation = yield* validateInput(input);

    // Combine parallel operations
    const [account, client] = yield* ResultAsync.combine([
      createAccount(user),
      createClient(validation.network),
    ]);

    // Continue with sequential operations
    const result = yield* processTransaction(account, client);

    return okAsync(result);
  });
}
```

#### Wrapping Promises: toAsyncResult

When working with promises from external libraries, wrap them with toAsyncResult:

```typescript
import { toAsyncResult } from "./lib/error";

function fetchExternalData(id: string) {
  return toAsyncResult(externalApi.getData(id), {
    type: "EXTERNAL_API_ERROR",
    message: "Failed to fetch external data",
    metadata: { id },
    logErrorMessage: "fetchExternalData - failed", // Optional, for logging
  });
}
```

#### Immediate Error Returns: createApplicationErrorResult

For synchronous error conditions, use createApplicationErrorResult:

```typescript
import { createApplicationErrorResult } from "./lib/error";

function processData(data: Data): ResultAsync<ProcessedData, ApplicationError> {
  if (!data.isValid) {
    return createApplicationErrorResult(
      "VALIDATION_ERROR",
      "Data is not valid",
      { data } // Optional metadata
    );
  }

  // Continue processing...
}
```

#### Error Types and Structure

Always use typed errors with meaningful types and messages:

```typescript
// Error types should be SCREAMING_SNAKE_CASE
const ERROR_TYPES = {
  VALIDATION_ERROR: "VALIDATION_ERROR",
  SERVICE_ERROR: "SERVICE_ERROR",
  NETWORK_ERROR: "NETWORK_ERROR",
  UNAUTHORIZED_ERROR: "UNAUTHORIZED_ERROR",
  NOT_FOUND_ERROR: "NOT_FOUND_ERROR",
  TRANSACTION_ERROR: "TRANSACTION_ERROR",
};
```

#### Best Practices

1. **Never throw exceptions** - Always return Result types
2. **Be specific with error types** - Use domain-specific error types
3. **Include relevant metadata** - Add context to help debugging
4. **Log at appropriate levels** - Use logErrorMessage for critical errors
5. **Compose at high levels** - Use safeTry for orchestration, FP style for utilities
6. **Type your errors** - Always specify error types in function signatures
