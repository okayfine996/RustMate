# Contract: Toolchain Configuration Service

**Feature**: 007-project-toolchain-management  
**Date**: 2025-01-27  
**Service**: `LocalToolchainConfigService`

## Purpose

Service for reading and writing project toolchain configuration (rust-toolchain.toml files).

## Interface

```swift
protocol ToolchainConfigService {
    /// Read toolchain configuration from project directory
    func readToolchainConfig(projectPath: String) async throws -> ProjectToolchainConfig
    
    /// Write toolchain configuration to project directory
    func writeToolchainConfig(projectPath: String, config: ProjectToolchainConfig) async throws
    
    /// Validate toolchain version string
    func validateVersion(_ version: String) -> Bool
    
    /// Check if toolchain version is installed
    func isToolchainInstalled(_ version: String) async throws -> Bool
}
```

## Input/Output Contracts

### readToolchainConfig

**Input**:
- `projectPath: String` - Validated project directory path (must be accessible via Security-Scoped Bookmark)

**Output**:
- Success: `ProjectToolchainConfig` - Parsed configuration from rust-toolchain.toml
- Error: `ConfigError` - Structured error (fileNotFound, parseError, permissionDenied)

**Behavior**:
- Reads `rust-toolchain.toml` from project root
- Falls back to legacy `rust-toolchain` file if TOML not found
- Returns default config if neither file exists
- Validates TOML structure before parsing
- Preserves unknown sections (for future merge)

**Error Cases**:
- `fileNotFound`: Neither rust-toolchain.toml nor rust-toolchain exists (returns default config, not error)
- `parseError`: TOML file is malformed (includes error message)
- `permissionDenied`: Cannot access project directory (Security-Scoped Bookmark invalid)

### writeToolchainConfig

**Input**:
- `projectPath: String` - Validated project directory path
- `config: ProjectToolchainConfig` - Configuration to write

**Output**:
- Success: `Void` - File written successfully
- Error: `ConfigError` - Structured error (validationError, writeError, permissionDenied)

**Behavior**:
- Validates configuration before writing (version format, component names, target names)
- Reads existing TOML file to preserve user's custom sections
- Merges app-managed sections with preserved sections
- Writes to temporary file (`rust-toolchain.toml.tmp`)
- Validates TOML structure by parsing back
- Atomically moves temp file to replace original
- Creates file if it doesn't exist

**Error Cases**:
- `validationError`: Invalid version/component/target format (includes specific field and error)
- `writeError`: File system error during write (includes error message)
- `permissionDenied`: Cannot write to project directory

### validateVersion

**Input**:
- `version: String` - Toolchain version string to validate

**Output**:
- `Bool` - True if version format is valid

**Validation Rules**:
- Channel names: `stable`, `beta`, `nightly` (exact match)
- Version numbers: `\d+\.\d+\.\d+` (semver pattern)
- Nightly dates: `nightly-\d{4}-\d{2}-\d{2}` (ISO date format)
- Custom toolchains: `[A-Za-z0-9._-]+` (alphanumeric, dots, dashes, underscores)

### isToolchainInstalled

**Input**:
- `version: String` - Toolchain version to check

**Output**:
- Success: `Bool` - True if toolchain is installed
- Error: `ConfigError` - rustup command failed

**Behavior**:
- Runs `rustup toolchain list` to get installed toolchains
- Checks if version matches any installed toolchain
- Returns false if not found (not an error)

**Error Cases**:
- `commandError`: rustup command failed (includes stderr)

## Error Types

```swift
enum ConfigError: Error, LocalizedError {
    case fileNotFound
    case parseError(String)           // TOML parsing error message
    case validationError(String)      // Field validation error message
    case writeError(String)           // File write error message
    case permissionDenied             // Security-Scoped Bookmark invalid
    case commandError(String)         // rustup command error (stderr)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Configuration file not found"
        case .parseError(let msg):
            return "Failed to parse TOML: \(msg)"
        case .validationError(let msg):
            return "Validation failed: \(msg)"
        case .writeError(let msg):
            return "Failed to write file: \(msg)"
        case .permissionDenied:
            return "Permission denied: Please re-authorize project directory access"
        case .commandError(let msg):
            return "Command failed: \(msg)"
        }
    }
}
```

## Security Constraints

- All file paths MUST be validated against Security-Scoped Bookmarks before access
- TOML content MUST be validated before writing to prevent injection
- Version strings MUST match whitelist patterns (no arbitrary command execution)

## Testing

- Unit tests with fixtures: Valid/invalid TOML samples
- Integration tests: Read/write round-trip with real files
- Error handling tests: Permission denied, malformed TOML, invalid versions
