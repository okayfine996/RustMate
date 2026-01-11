# Data Model: Project Management with Toolchain Configuration

**Feature**: 007-project-toolchain-management  
**Date**: 2025-01-27  
**Purpose**: Define domain models for project toolchain and Cargo configuration management

## Overview

This feature extends the existing RustMate data model with new entities for managing project-specific toolchain configurations (rust-toolchain.toml) and Cargo build settings (.cargo/config.toml). All models are Codable Swift structs for persistence and XPC transfer (though this feature uses LocalExecution, not XPC).

## Core Entities

### 1. ProjectToolchainConfig

Represents toolchain configuration for a project, stored in rust-toolchain.toml.

```swift
struct ProjectToolchainConfig: Codable, Sendable {
    var channel: ToolchainChannel?      // stable, beta, nightly
    var version: String?                 // Optional: "1.75.0" or "nightly-2024-01-01"
    var components: [String]             // e.g., ["rustfmt", "clippy", "rust-src"]
    var targets: [String]                // e.g., ["wasm32-unknown-unknown", "aarch64-apple-ios"]
    var profile: ToolchainProfile?      // minimal or default
    
    enum ToolchainChannel: String, Codable, Sendable {
        case stable
        case beta
        case nightly
        
        var displayText: String {
            switch self {
            case .stable: return "Stable"
            case .beta: return "Beta"
            case .nightly: return "Nightly"
            }
        }
    }
    
    enum ToolchainProfile: String, Codable, Sendable {
        case minimal
        case `default`
        
        var displayText: String {
            switch self {
            case .minimal: return "Minimal"
            case .default: return "Default"
            }
        }
    }
    
    // Validation
    static func validateVersion(_ version: String) -> Bool {
        // Pattern: stable/beta/nightly, semver (1.75.0), or nightly-date (nightly-2024-01-01)
        let patterns = [
            "^stable$",
            "^beta$",
            "^nightly$",
            "^\\d+\\.\\d+\\.\\d+$",  // Semver
            "^nightly-\\d{4}-\\d{2}-\\d{2}$"  // Nightly date
        ]
        return patterns.contains { version.range(of: $0, options: .regularExpression) != nil }
    }
    
    static func validateComponent(_ component: String) -> Bool {
        // Common components: rustfmt, clippy, rust-src, rust-analyzer, llvm-tools-preview
        let validComponents = ["rustfmt", "clippy", "rust-src", "rust-analyzer", "llvm-tools-preview"]
        return validComponents.contains(component) || 
               component.range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil
    }
    
    static func validateTarget(_ target: String) -> Bool {
        // Target triple format: arch-vendor-os or arch-vendor-os-env
        return target.range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil &&
               target.count <= 128
    }
}
```

**Relationships**:
- Belongs to: `ProjectBookmark` (via project path)
- Stored in: `rust-toolchain.toml` file in project root

**Validation Rules** (from FR-211):
- Version string MUST match one of: channel name, semver pattern, or nightly-date pattern
- Component names MUST be valid rustup component names or match `[A-Za-z0-9._-]+`
- Target names MUST match target triple format and be <= 128 characters
- Empty version means "latest of selected channel"

**State Transitions**:
```
[Not Configured] --create--> [Configured]
[Configured] --update--> [Configured]
[Configured] --delete-file--> [Not Configured]
```

**TOML Format**:
```toml
[toolchain]
channel = "stable"
version = "1.75.0"
components = ["rustfmt", "clippy"]
targets = ["wasm32-unknown-unknown"]
profile = "default"
```

---

### 2. ProjectCargoConfig

Represents Cargo build configuration for a project, stored in .cargo/config.toml.

```swift
struct ProjectCargoConfig: Codable, Sendable {
    var registryMirror: RegistryMirror?  // Crates.io or Chinese mirror
    var aliases: [String: String]        // Map: alias -> command (e.g., "b" -> "build")
    var linker: LinkerOption?            // mold, zld, or none
    var rustflags: String?                // Environment variables string
    var proxySettings: ProxySettings?    // HTTP/HTTPS proxy configuration
    
    enum RegistryMirror: String, Codable, Sendable {
        case cratesIo = "crates-io"
        case tsinghua
        case ustc
        case byteDance
        
        var displayText: String {
            switch self {
            case .cratesIo: return "Crates.io (Default)"
            case .tsinghua: return "Tsinghua"
            case .ustc: return "USTC"
            case .byteDance: return "ByteDance"
            }
        }
        
        var registryURL: String? {
            switch self {
            case .cratesIo: return nil  // Default, no replacement needed
            case .tsinghua: return "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
            case .ustc: return "https://mirrors.ustc.edu.cn/crates.io-index.git"
            case .byteDance: return "https://rsproxy.cn/crates.io-index"
            }
        }
    }
    
    enum LinkerOption: String, Codable, Sendable {
        case mold
        case zld
        case none
        
        var displayText: String {
            switch self {
            case .mold: return "mold"
            case .zld: return "zld"
            case .none: return "None (Default)"
            }
        }
    }
    
    struct ProxySettings: Codable, Sendable {
        var httpProxy: String?
        var httpsProxy: String?
        
        // Validation: URLs must be valid HTTP/HTTPS URLs
        static func validateURL(_ url: String) -> Bool {
            guard let urlObj = URL(string: url) else { return false }
            return ["http", "https"].contains(urlObj.scheme?.lowercased())
        }
    }
    
    // Validation
    static func validateAlias(_ alias: String) -> Bool {
        // Alias must be valid identifier
        return alias.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil &&
               alias.count <= 32
    }
}
```

**Relationships**:
- Belongs to: `ProjectBookmark` (via project path)
- Stored in: `.cargo/config.toml` file in project root

**Validation Rules** (from FR-301-312):
- Registry mirror URLs MUST be from whitelist (Tsinghua, USTC, ByteDance)
- Alias names MUST match `[A-Za-z0-9_-]+` and be <= 32 characters
- Proxy URLs MUST be valid HTTP/HTTPS URLs
- App MUST preserve existing .cargo/config.toml content not managed by UI

**State Transitions**:
```
[Not Configured] --create--> [Configured]
[Configured] --update--> [Configured]
[Configured] --delete-file--> [Not Configured]
```

**TOML Format**:
```toml
[source.crates-io]
replace-with = "tsinghua"

[source.tsinghua]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

[alias]
b = "build"
t = "test"

[build]
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
```

---

### 3. ProjectDiagnostics

Represents diagnostic information about a project's toolchain configuration.

```swift
struct ProjectDiagnostics: Codable, Sendable {
    let actualToolchainVersion: String?      // Version that would be used in shell
    let configuredVersion: String?            // From rust-toolchain.toml
    let overrideVersion: String?             // From rustup override
    let hasMismatch: Bool                    // True if versions don't match
    let msrvViolation: MSRVViolation?        // MSRV check result
    let conflictDetails: [ConflictDetail]    // List of detected conflicts
    let toolchainSource: ToolchainSource     // Priority source (env/toolchainFile/override/default)
    
    enum ToolchainSource: String, Codable, Sendable {
        case environment      // RUSTUP_TOOLCHAIN env var
        case toolchainFile    // rust-toolchain.toml
        case override         // rustup override
        case `default`        // Default toolchain
        
        var displayText: String {
            switch self {
            case .environment: return "Environment Variable"
            case .toolchainFile: return "Toolchain File"
            case .override: return "Directory Override"
            case .default: return "Default Toolchain"
            }
        }
        
        var priority: Int {
            switch self {
            case .environment: return 1
            case .toolchainFile: return 2
            case .override: return 3
            case .default: return 4
            }
        }
    }
    
    struct MSRVViolation: Codable, Sendable {
        let requiredVersion: String          // From Cargo.toml rust-version
        let configuredVersion: String       // From toolchain config
        let isViolation: Bool                // True if configured < required
        
        var message: String {
            if isViolation {
                return "MSRV violation: Project requires \(requiredVersion), but toolchain is \(configuredVersion)"
            }
            return "MSRV compliant: Toolchain \(configuredVersion) meets requirement \(requiredVersion)"
        }
    }
    
    struct ConflictDetail: Codable, Sendable {
        let type: ConflictType
        let message: String
        let suggestedFix: String?
        
        enum ConflictType: String, Codable, Sendable {
            case versionMismatch
            case overrideConflict
            case missingToolchain
            case missingComponents
        }
    }
}
```

**Relationships**:
- Belongs to: `ProjectBookmark` (via project path)
- Derived from: Reading configuration files and environment

**Validation Rules** (from FR-401-409):
- Diagnostics MUST be computed asynchronously (non-blocking)
- Version mismatches MUST be detected by comparing configured vs override vs actual
- MSRV violations MUST be detected by comparing Cargo.toml rust-version with toolchain version
- Toolchain source priority MUST follow: env → toolchainFile → override → default

**State Transitions**:
```
[Unknown] --calculate--> [Healthy]
[Unknown] --calculate--> [HasConflicts]
[HasConflicts] --fix--> [Healthy]
```

---

### 4. ProjectHealthStatus

Represents the health/status of a project's configuration.

```swift
struct ProjectHealthStatus: Codable, Sendable {
    let status: HealthStatus
    let indicatorColor: IndicatorColor
    let lastChecked: Date
    let details: String?                  // Optional human-readable details
    
    enum HealthStatus: String, Codable, Sendable {
        case healthy
        case missingComponents
        case versionMismatch
        case overrideConflict
        case unknown
        
        var displayText: String {
            switch self {
            case .healthy: return "Healthy"
            case .missingComponents: return "Missing Components"
            case .versionMismatch: return "Version Mismatch"
            case .overrideConflict: return "Override Conflict"
            case .unknown: return "Unknown"
            }
        }
    }
    
    enum IndicatorColor: String, Codable, Sendable {
        case green
        case red
        case yellow
        
        var systemColor: Color {
            switch self {
            case .green: return .green
            case .red: return .red
            case .yellow: return .yellow
            }
        }
    }
    
    // Factory method to calculate status from diagnostics
    static func calculate(from diagnostics: ProjectDiagnostics, 
                         toolchainInstalled: Bool,
                         componentsAvailable: Bool) -> ProjectHealthStatus {
        if !toolchainInstalled {
            return ProjectHealthStatus(
                status: .missingComponents,
                indicatorColor: .red,
                lastChecked: Date(),
                details: "Toolchain version not installed"
            )
        }
        
        if !componentsAvailable {
            return ProjectHealthStatus(
                status: .missingComponents,
                indicatorColor: .red,
                lastChecked: Date(),
                details: "Required components not available"
            )
        }
        
        if diagnostics.hasMismatch {
            return ProjectHealthStatus(
                status: .versionMismatch,
                indicatorColor: .yellow,
                lastChecked: Date(),
                details: "Version mismatch detected"
            )
        }
        
        if diagnostics.conflictDetails.contains(where: { $0.type == .overrideConflict }) {
            return ProjectHealthStatus(
                status: .overrideConflict,
                indicatorColor: .yellow,
                lastChecked: Date(),
                details: "Override conflicts detected"
            )
        }
        
        if let msrv = diagnostics.msrvViolation, msrv.isViolation {
            return ProjectHealthStatus(
                status: .versionMismatch,
                indicatorColor: .red,
                lastChecked: Date(),
                details: msrv.message
            )
        }
        
        return ProjectHealthStatus(
            status: .healthy,
            indicatorColor: .green,
            lastChecked: Date(),
            details: "Configuration is healthy"
        )
    }
}
```

**Relationships**:
- Belongs to: `ProjectBookmark` (computed property or cached value)
- Calculated from: `ProjectDiagnostics`, toolchain installation status, component availability

**Validation Rules** (from FR-104-105):
- Status MUST be calculated by checking: toolchain installation, component availability, version matches, override conflicts
- Indicator color MUST be: green (healthy), red (missing components/version), yellow (override conflicts)
- Status MUST be cached and invalidated on configuration changes

**State Transitions**:
```
[Unknown] --check--> [Healthy]
[Unknown] --check--> [MissingComponents]
[Unknown] --check--> [VersionMismatch]
[Unknown] --check--> [OverrideConflict]
[Any] --recheck--> [Any] (status may change)
```

---

### 5. Extended ProjectBookmark

Extends existing `ProjectBookmark` model with health status.

```swift
// Existing model (from previous features)
struct ProjectBookmark: Identifiable, Codable, Hashable {
    let id: UUID
    let path: String
    let displayName: String
    var bookmarkData: Data
    let addedDate: Date
    var isFavorite: Bool
    
    // NEW: Health status (computed, not persisted)
    var healthStatus: ProjectHealthStatus?  // Computed on-demand, cached
}
```

**Relationships**:
- Has one: `ProjectToolchainConfig` (via rust-toolchain.toml)
- Has one: `ProjectCargoConfig` (via .cargo/config.toml)
- Has one: `ProjectDiagnostics` (computed from configs and environment)

**Validation Rules**:
- Path MUST be validated against Security-Scoped Bookmark before access
- Health status MUST be computed asynchronously (non-blocking UI)

---

## Data Flow

### Reading Configuration

1. User selects project from sidebar
2. Resolve Security-Scoped Bookmark to get project URL
3. Read `rust-toolchain.toml` → parse to `ProjectToolchainConfig`
4. Read `.cargo/config.toml` → parse to `ProjectCargoConfig`
5. Compute `ProjectDiagnostics` from configs + environment
6. Calculate `ProjectHealthStatus` from diagnostics
7. Update UI with configuration and status

### Writing Configuration

1. User modifies configuration in UI
2. Validate changes (version format, component names, etc.)
3. Merge with existing TOML (preserve user's custom sections)
4. Write to temporary file (`{filename}.tmp`)
5. Validate TOML structure (parse back)
6. Atomically move temp file to replace original
7. Invalidate health status cache
8. Recalculate diagnostics and health status

### Health Status Calculation

1. Check if toolchain version is installed (via rustup)
2. Check if required components are available
3. Compare configured version vs override vs actual
4. Check MSRV compliance (read Cargo.toml rust-version)
5. Calculate health status from all checks
6. Cache result for 30 seconds
7. Update UI indicator

---

## Persistence

- **ProjectBookmark**: Persisted in UserDefaults (existing)
- **ProjectToolchainConfig**: Stored in `rust-toolchain.toml` (file system)
- **ProjectCargoConfig**: Stored in `.cargo/config.toml` (file system)
- **ProjectDiagnostics**: Computed on-demand, not persisted
- **ProjectHealthStatus**: Cached in-memory (keyed by project path + last modified time)

---

## Error Handling

All file operations return structured results:

```swift
enum ConfigOperationResult<T> {
    case success(T)
    case fileNotFound
    case parseError(String)
    case validationError(String)
    case permissionDenied
    case writeError(String)
}
```

Errors are structured and user-actionable, not raw text output.
