# Authorization Helpers

This directory contains utilities for managing security-scoped bookmark authorization in the sandboxed app.

## Components

- `AuthorizationScope.swift` - Defines which authorization purposes are required for each operation family
- `AuthorizationError.swift` - Structured authorization errors with user-facing messages
- `AuthorizationService.swift` - Service for validating and resolving authorized resources

## Authorization Purposes

The app requires authorization for:
- `rustupExecutableDir` - Directory containing rustup executable (e.g., `~/.cargo/bin`)
- `cargoHome` - `.cargo` directory
- `rustupHome` - `.rustup` directory
- `projectAccess` - Project directories (optional, for project context features)

## Authorization Flow

1. Check if required bookmark exists in `AppSettings.authorizedDirectories`
2. Resolve bookmark via `BookmarkManager.resolveBookmark()`
3. Call `startAccessingSecurityScopedResource()` on resolved URL
4. Perform file operations within authorized scope
5. Call `stopAccessingSecurityScopedResource()` when done

## Error Handling

All authorization failures return structured `AuthorizationError` with:
- Error category (missing/stale/denied/invalid)
- User-facing message
- Suggested fix (e.g., "Open Settings > Permissions to authorize")

## Usage

```swift
let authService = AuthorizationService()
let authorizedResources = try authService.validateAndResolve(for: .toolchainOperations)
defer {
    authService.stopAccessing(authorizedResources)
}
// ... perform operations within authorized scope
```
