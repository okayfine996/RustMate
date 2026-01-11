# Contract: Cargo Configuration Service

**Feature**: 007-project-toolchain-management  
**Date**: 2025-01-27  
**Service**: `LocalCargoConfigService`

## Purpose

Service for reading and writing Cargo build configuration (.cargo/config.toml files).

## Interface

```swift
protocol CargoConfigService {
    /// Read Cargo configuration from project directory
    func readCargoConfig(projectPath: String) async throws -> ProjectCargoConfig
    
    /// Write Cargo configuration to project directory
    func writeCargoConfig(projectPath: String, config: ProjectCargoConfig) async throws
    
    /// Validate registry mirror URL
    func validateMirrorURL(_ url: String) -> Bool
    
    /// Validate alias name
    func validateAlias(_ alias: String) -> Bool
}
```

## Input/Output Contracts

### readCargoConfig

**Input**:
- `projectPath: String` - Validated project directory path (must be accessible via Security-Scoped Bookmark)

**Output**:
- Success: `ProjectCargoConfig` - Parsed configuration from .cargo/config.toml
- Error: `ConfigError` - Structured error (fileNotFound, parseError, permissionDenied)

**Behavior**:
- Reads `.cargo/config.toml` from project root
- Creates .cargo directory if it doesn't exist (for write operations)
- Returns default config if file doesn't exist
- Validates TOML structure before parsing
- Preserves all sections not managed by app (for merge on write)

**Error Cases**:
- `fileNotFound`: .cargo/config.toml doesn't exist (returns default config, not error)
- `parseError`: TOML file is malformed (includes error message)
- `permissionDenied`: Cannot access project directory

### writeCargoConfig

**Input**:
- `projectPath: String` - Validated project directory path
- `config: ProjectCargoConfig` - Configuration to write

**Output**:
- Success: `Void` - File written successfully
- Error: `ConfigError` - Structured error (validationError, writeError, permissionDenied)

**Behavior**:
- Validates configuration before writing (mirror URLs, alias names, proxy URLs)
- Reads existing TOML file to preserve user's custom sections
- Merges app-managed sections ([source], [alias], [build]) with preserved sections
- Creates .cargo directory if it doesn't exist
- Writes to temporary file (`.cargo/config.toml.tmp`)
- Validates TOML structure by parsing back
- Atomically moves temp file to replace original
- Creates file if it doesn't exist

**Error Cases**:
- `validationError`: Invalid mirror URL, alias name, or proxy URL (includes specific field and error)
- `writeError`: File system error during write (includes error message)
- `permissionDenied`: Cannot write to project directory

### validateMirrorURL

**Input**:
- `url: String` - Registry mirror URL to validate

**Output**:
- `Bool` - True if URL is in whitelist

**Validation Rules**:
- URLs MUST be from whitelist: Tsinghua, USTC, ByteDance
- URLs MUST be valid HTTP/HTTPS URLs
- Default (crates-io) returns true (no replacement needed)

### validateAlias

**Input**:
- `alias: String` - Alias name to validate

**Output**:
- `Bool` - True if alias format is valid

**Validation Rules**:
- Alias MUST match `[A-Za-z0-9_-]+` pattern
- Alias length MUST be <= 32 characters
- Alias MUST not conflict with cargo built-in commands

## Error Types

Same as `ToolchainConfigService` (see toolchain-config-service.md).

## Security Constraints

- All file paths MUST be validated against Security-Scoped Bookmarks before access
- Registry mirror URLs MUST be from whitelist (no arbitrary URLs)
- Alias names MUST match whitelist pattern (no command injection)

## TOML Format Examples

### Registry Mirror

```toml
[source.crates-io]
replace-with = "tsinghua"

[source.tsinghua]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
```

### Aliases

```toml
[alias]
b = "build"
t = "test"
r = "run"
```

### Linker Configuration

```toml
[build]
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
```

### Proxy Settings

```toml
[http]
proxy = "http://proxy.example.com:8080"

[https]
proxy = "https://proxy.example.com:8080"
```

## Testing

- Unit tests with fixtures: Valid/invalid TOML samples
- Integration tests: Read/write round-trip with real files
- Merge tests: Preserve user's custom sections
- Error handling tests: Permission denied, malformed TOML, invalid URLs/aliases
