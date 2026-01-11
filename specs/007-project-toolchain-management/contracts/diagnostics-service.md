# Contract: Project Diagnostics Service

**Feature**: 007-project-toolchain-management  
**Date**: 2025-01-27  
**Service**: `ProjectDiagnosticsService`

## Purpose

Service for computing diagnostic information about a project's toolchain configuration, including version mismatches, override conflicts, and MSRV violations.

## Interface

```swift
protocol DiagnosticsService {
    /// Compute diagnostics for a project
    func computeDiagnostics(projectPath: String) async throws -> ProjectDiagnostics
    
    /// Clear rustup override for a project
    func clearOverride(projectPath: String) async throws
    
    /// Get actual Rust version that would be used in shell
    func getActualToolchainVersion(projectPath: String) async throws -> String?
}
```

## Input/Output Contracts

### computeDiagnostics

**Input**:
- `projectPath: String` - Validated project directory path

**Output**:
- Success: `ProjectDiagnostics` - Complete diagnostic information
- Error: `DiagnosticsError` - Structured error

**Behavior**:
1. Read rust-toolchain.toml to get configured version
2. Run `rustup show` in project directory to get override version
3. Run `rustc --version` to get actual version that would be used
4. Read Cargo.toml to get rust-version (MSRV)
5. Compare versions to detect mismatches
6. Check MSRV compliance
7. Return structured diagnostics

**Computation Steps**:
- **Configured Version**: From rust-toolchain.toml (if exists)
- **Override Version**: From `rustup show` output (if override exists)
- **Actual Version**: From `rustc --version` in project directory
- **Toolchain Source**: Determine priority (env → toolchainFile → override → default)
- **Mismatch Detection**: Compare configured vs override vs actual
- **MSRV Check**: Compare toolchain version vs Cargo.toml rust-version

**Error Cases**:
- `permissionDenied`: Cannot access project directory
- `commandError`: rustup/rustc command failed (includes stderr)
- `parseError`: Failed to parse rustup output

### clearOverride

**Input**:
- `projectPath: String` - Validated project directory path

**Output**:
- Success: `Void` - Override cleared successfully
- Error: `DiagnosticsError` - Command failed

**Behavior**:
- Runs `rustup override unset` in project directory
- Clears any directory-level override
- Does not modify rust-toolchain.toml file

**Error Cases**:
- `commandError`: rustup command failed (includes stderr)
- `permissionDenied`: Cannot access project directory

### getActualToolchainVersion

**Input**:
- `projectPath: String` - Validated project directory path

**Output**:
- Success: `String?` - Rust version string (e.g., "1.75.0") or nil if not available
- Error: `DiagnosticsError` - Command failed

**Behavior**:
- Changes to project directory
- Runs `rustc --version` with project directory as working directory
- Parses version from output (e.g., "rustc 1.75.0")
- Returns version string or nil if command fails

**Error Cases**:
- `commandError`: rustc command failed (includes stderr)
- `permissionDenied`: Cannot access project directory

## Error Types

```swift
enum DiagnosticsError: Error, LocalizedError {
    case permissionDenied
    case commandError(String)         // rustup/rustc command error (stderr)
    case parseError(String)           // Output parsing error
    case fileNotFound                 // Cargo.toml not found (for MSRV check)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied: Please re-authorize project directory access"
        case .commandError(let msg):
            return "Command failed: \(msg)"
        case .parseError(let msg):
            return "Failed to parse output: \(msg)"
        case .fileNotFound:
            return "Cargo.toml not found"
        }
    }
}
```

## Toolchain Source Priority

The service determines toolchain source priority (from highest to lowest):

1. **Environment Variable** (`RUSTUP_TOOLCHAIN`): Highest priority
2. **Toolchain File** (`rust-toolchain.toml` or `rust-toolchain`): Second priority
3. **Override** (`rustup override set`): Third priority
4. **Default** (default toolchain): Lowest priority

This matches rustup's actual behavior.

## MSRV Check

The service checks Minimum Supported Rust Version (MSRV) by:

1. Reading `Cargo.toml` from project root
2. Extracting `rust-version` field (e.g., `rust-version = "1.70.0"`)
3. Comparing with configured toolchain version
4. Reporting violation if toolchain version < rust-version

If `Cargo.toml` doesn't have `rust-version` field, MSRV check is skipped (no violation).

## Security Constraints

- All file paths MUST be validated against Security-Scoped Bookmarks before access
- Command execution MUST use validated rustup/rustc paths from settings
- Output parsing MUST handle malformed output gracefully (return unknown, not crash)

## Testing

- Unit tests with fixtures: Mock rustup show output, rustc --version output
- Integration tests: Real rustup commands in test project directory
- Error handling tests: Permission denied, command failures, malformed output
- MSRV tests: Various Cargo.toml rust-version scenarios
