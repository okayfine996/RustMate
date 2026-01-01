# Execution Errors

This directory contains error types specific to local rustup execution.

## Error Types

- `RustupExecutionError.swift` - Structured errors for execution failures with categories and suggested fixes
- `AuthorizationError.swift` - Errors related to missing/stale/invalid authorization scopes

## Error Categories

### RustupExecutionError
- `missingAuthorization` - Required security-scoped bookmark not available
- `rustupNotFound` - Cannot locate rustup executable in authorized paths
- `executionFailed` - Process execution failed (non-zero exit, killed, etc.)
- `parseFailed` - Output parsing failed (unknown format)
- `unknown` - Unexpected error with stderr snippet

### AuthorizationError
- `missingScope` - Required authorization purpose not granted
- `staleBookmark` - Bookmark data is stale and needs refresh
- `accessDenied` - `startAccessingSecurityScopedResource()` returned false
- `invalidSelection` - User selected wrong directory for purpose

## Design Principles

All errors include:
- User-understandable message (not raw stderr)
- Suggested fix action (e.g., "Re-authorize ~/.cargo/bin")
- Error category for UI routing (show re-auth prompt, settings link, etc.)
