# Local Execution

This directory contains the local (in-app) execution layer for running rustup commands directly within the main app process, using security-scoped bookmarks for authorized access.

## Purpose

Provides direct process execution for rustup commands in the sandboxed main app.

## Components

- `ProcessRunner.swift` - Async wrapper around `Process` for non-blocking execution
- `ProcessOutputLimiter.swift` - Enforces output truncation for summary-only results
- `RustupCommandResolver.swift` - Resolves rustup executable path from authorized directories
- `LocalRustupToolchainService.swift` - Implements `RustToolchainServiceProtocol` locally
- `LocalProjectContextService.swift` - Implements `ProjectContextServiceProtocol` locally
- `TaskResultFactory.swift` - Converts execution results to UI-friendly `TaskResult` models
- `ErrorPresentation.swift` - Translates errors into user-facing messages

## Architecture

All operations:
1. Validate authorization scope via `AuthorizationService`
2. Resolve rustup executable via `RustupCommandResolver`
3. Execute via `ProcessRunner` (async, non-blocking)
4. Parse output via parsers in `Services/Parsers/`
5. Return structured results (success/failure with error categories)

## Security

- Only accesses resources within security-scoped bookmarks
- No filesystem scanning outside authorized directories
- All file access wrapped in `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`
