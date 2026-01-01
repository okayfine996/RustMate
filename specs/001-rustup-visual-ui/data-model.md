# Data Model: RustMate

**Feature**: RustMate Visual Interface for Rustup Operations
**Date**: 2025-12-31
**Purpose**: Define domain models and their relationships for rustup management

## Overview

RustMate's data model is structured around five core entities that map directly to rustup concepts: Toolchains, Components, Targets, Project Contexts, and Task Records. All models are designed as Codable Swift structs for XPC transfer and local persistence.

## Core Entities

### 1. ToolchainInfo

Represents an installed Rust toolchain (stable, beta, nightly, or custom).

```swift
struct ToolchainInfo: Codable, Identifiable, Sendable {
    let id: UUID           // Stable identifier for SwiftUI list tracking
    let name: String       // e.g., "stable-aarch64-apple-darwin", "nightly-2024-01-15"
    let version: String?   // e.g., "1.75.0", parsed from `rustc --version` if available
    let isDefault: Bool    // True if marked (default) in `rustup toolchain list`
    let installDate: Date? // Derived from file system metadata if available
    let host: String?      // e.g., "aarch64-apple-darwin", parsed from name or rustup show

    // Validation
    static func validateName(_ name: String) -> Bool {
        let pattern = "^[A-Za-z0-9._-]{1,128}$"
        return name.range(of: pattern, options: .regularExpression) != nil
    }
}
```

**Relationships**:
- Has many: `ComponentInfo` (components installed for this toolchain)
- Has many: `TargetInfo` (targets installed for this toolchain)
- Used by: `ProjectContextInfo` (as active toolchain)

**Validation Rules** (from FR-804):
- Name MUST match regex `[A-Za-z0-9._-]+`
- Name length MUST be between 1 and 128 characters
- Exactly one toolchain MUST have `isDefault = true` at any time

**State Transitions**:
```
[Not Installed] --install--> [Installed]
[Installed] --set-default--> [Default]
[Default] --set-another-default--> [Installed]
[Installed] --uninstall--> [Not Installed]
[Installed] --update--> [Installed] (version changes)
```

**Derivation**:
- Parsed from `rustup toolchain list` output
- Version populated by subsequent `rustc --version` call (optional)
- `id` generated client-side for SwiftUI identity

---

### 2. ComponentInfo

Represents a rustup component (clippy, rustfmt, rust-src, etc.) for a specific toolchain.

```swift
struct ComponentInfo: Codable, Identifiable, Sendable {
    let id: UUID               // Stable identifier
    let name: String           // e.g., "rustfmt", "clippy", "rust-src"
    let toolchainName: String  // Parent toolchain (foreign key)
    let isInstalled: Bool      // True if installed for this toolchain
    let description: String?   // Human-readable description (if available from rustup)

    // Common components (for UI suggestions)
    static let commonComponents = ["rustfmt", "clippy", "rust-src", "llvm-tools-preview"]
}
```

**Relationships**:
- Belongs to: `ToolchainInfo` (via `toolchainName`)

**Validation Rules** (from FR-305):
- Name MUST be one of the components available for the toolchain
- MUST support at minimum: rustfmt, clippy, rust-src, llvm-tools-preview

**State Transitions**:
```
[Available] --add--> [Installed]
[Installed] --remove--> [Available]
```

**Derivation**:
- Parsed from `rustup component list --toolchain <name>` output
- Status derived from "(installed)" suffix in output

---

### 3. TargetInfo

Represents a compilation target platform (wasm32, aarch64-linux-gnu, etc.).

```swift
struct TargetInfo: Codable, Identifiable, Sendable {
    let id: UUID               // Stable identifier
    let triple: String         // e.g., "wasm32-unknown-unknown", "aarch64-apple-darwin"
    let toolchainName: String  // Parent toolchain (foreign key)
    let isInstalled: Bool      // True if installed for this toolchain
    let description: String?   // Human-readable description (if available)

    // Common targets (for UI suggestions)
    static let commonTargets = [
        "wasm32-unknown-unknown",
        "aarch64-apple-darwin",
        "x86_64-apple-darwin",
        "aarch64-unknown-linux-gnu",
        "x86_64-unknown-linux-gnu",
        "x86_64-pc-windows-msvc"
    ]

    // Validation
    static func validateTriple(_ triple: String) -> Bool {
        let pattern = "^[A-Za-z0-9._-]{1,128}$"
        return triple.range(of: pattern, options: .regularExpression) != nil
    }
}
```

**Relationships**:
- Belongs to: `ToolchainInfo` (via `toolchainName`)

**Validation Rules** (from FR-804):
- Triple MUST match regex `[A-Za-z0-9._-]+`
- Triple length MUST be between 1 and 128 characters

**State Transitions**:
```
[Available] --add--> [Installed]
[Installed] --remove--> [Available]
```

**Derivation**:
- Parsed from `rustup target list --toolchain <name>` output
- Status derived from "(installed)" suffix in output

---

### 4. ProjectContextInfo

Represents a project directory and its active toolchain configuration.

```swift
struct ProjectContextInfo: Codable, Identifiable, Sendable {
    let id: UUID                   // Stable identifier
    let projectPath: String        // Absolute path to project directory
    let activeToolchain: String    // Name of active toolchain
    let reason: ToolchainReason    // Why this toolchain is active
    let sourcePath: String?        // Path to rust-toolchain.toml if applicable
    let lastAccessed: Date         // For sorting recent projects

    enum ToolchainReason: String, Codable {
        case environment           // RUSTUP_TOOLCHAIN env var
        case toolchainFile         // rust-toolchain.toml or rust-toolchain
        case override              // rustup override set
        case `default`             // Default toolchain
        case unknown               // Could not determine

        var displayText: String {
            switch self {
            case .environment: return "Environment Variable (RUSTUP_TOOLCHAIN)"
            case .toolchainFile: return "Toolchain File (rust-toolchain.toml)"
            case .override: return "Directory Override (rustup override)"
            case .default: return "Default Toolchain"
            case .unknown: return "Unknown"
            }
        }

        var priority: Int {
            switch self {
            case .environment: return 1
            case .toolchainFile: return 2
            case .override: return 3
            case .default: return 4
            case .unknown: return 5
            }
        }
    }
}
```

**Relationships**:
- References: `ToolchainInfo` (via `activeToolchain` name)
- Requires: `AuthorizedDirectory` (projectPath must be within authorized bookmark)

**Validation Rules** (from FR-503, FR-805):
- `projectPath` MUST be within authorized bookmark scope
- Priority order: environment > toolchainFile > override > default
- `sourcePath` MUST be populated when `reason = .toolchainFile`

**Derivation**:
- Parsed from `rustup show` output run in project directory
- `reason` determined by parsing "overridden by" or "default" lines
- `sourcePath` extracted from "overridden by <path>" line

---

### 5. TaskRecord

Represents the execution status of a rustup operation.

```swift
struct TaskRecord: Codable, Identifiable, Sendable {
    let id: UUID                      // Stable identifier (used for cancellation)
    let operation: String             // e.g., "Install stable", "Update all toolchains"
    let target: String?               // Target entity name (toolchain/component/target)
    let status: TaskStatus            // Current status
    let startTime: Date               // When operation started
    let endTime: Date?                // When operation completed (nil if running)
    let exitCode: Int?                // Process exit code (nil if running)
    let stdoutSnippet: String?        // Truncated stdout (max 32KB) for display
    let stderrSnippet: String?        // Truncated stderr (max 32KB) for errors
    let errorMessage: String?         // High-level error message (user-actionable)
    let suggestedFix: String?         // Suggested action for common errors

    enum TaskStatus: String, Codable {
        case running
        case success
        case failed
        case cancelled

        var icon: String {
            switch self {
            case .running: return "arrow.clockwise"
            case .success: return "checkmark.circle"
            case .failed: return "xmark.circle"
            case .cancelled: return "stop.circle"
            }
        }

        var color: Color {
            switch self {
            case .running: return .blue
            case .success: return .green
            case .failed: return .red
            case .cancelled: return .orange
            }
        }
    }

    // Computed property for display duration
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    // Common error patterns and suggested fixes
    static func suggestFix(for stderr: String) -> String? {
        if stderr.contains("could not download") || stderr.contains("network") {
            return "Check your internet connection or try again later"
        } else if stderr.contains("permission denied") {
            return "Grant access to ~/.cargo/bin in Settings"
        } else if stderr.contains("already installed") {
            return "Toolchain is already installed. Try updating instead."
        } else if stderr.contains("could not find") {
            return "Toolchain name may be incorrect. Check spelling."
        }
        return nil
    }
}
```

**Relationships**:
- May reference: `ToolchainInfo`, `ComponentInfo`, or `TargetInfo` (via `target` name)

**Validation Rules** (from FR-601, FR-602, FR-603):
- `operation` MUST be descriptive (e.g., "Install stable-aarch64-apple-darwin")
- `stderrSnippet` MUST be truncated to max 32KB
- `status = .running` MUST have `endTime = nil`
- `status != .running` MUST have `endTime != nil`

**State Transitions**:
```
[Created] --> [Running] --> [Success]
                        --> [Failed]
                        --> [Cancelled]
```

**Derivation**:
- Created by ViewModel when operation initiated
- Updated by XPC Service when operation completes
- `suggestedFix` populated using pattern matching on stderr

---

### 6. AuthorizedDirectory

Represents a user-authorized directory with Security-Scoped Bookmark.

```swift
struct AuthorizedDirectory: Codable, Identifiable, Sendable {
    let id: UUID                    // Stable identifier
    let path: String                // Absolute path to directory
    let bookmarkData: Data          // Security-Scoped Bookmark data
    let purpose: DirectoryPurpose   // Why this directory was authorized
    let authorizedDate: Date        // When user granted authorization
    let lastValidated: Date?        // Last successful bookmark resolution

    enum DirectoryPurpose: String, Codable {
        case rustupAccess           // Access to ~/.cargo/bin for rustup/cargo
        case projectAccess          // Access to project directory
        case customToolchainPath    // Custom rustup installation path

        var displayText: String {
            switch self {
            case .rustupAccess: return "Rustup Executables"
            case .projectAccess: return "Project Directory"
            case .customToolchainPath: return "Custom Rustup Path"
            }
        }
    }

    // Check if bookmark is stale and needs refresh
    func isBookmarkStale() throws -> Bool {
        var isStale = false
        _ = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return isStale
    }
}
```

**Relationships**:
- Required by: `ProjectContextInfo` (for project path access)
- Required by: XPC Service (for rustup executable access)

**Validation Rules** (from FR-105, FR-106):
- `bookmarkData` MUST be valid Security-Scoped Bookmark
- Bookmark MUST be resolved before file system access
- MUST call `startAccessingSecurityScopedResource()` before use

**Persistence**:
- Stored in Keychain (SecItemAdd/SecItemCopyMatching)
- Key: `com.finefine.RustMate.bookmark.<id>`
- Value: `bookmarkData` (encrypted by Keychain)

---

## Settings Model

### AppSettings

User-configurable application settings.

```swift
struct AppSettings: Codable, Sendable {
    var rustupPath: String?                    // Custom rustup executable path
    var cargoPath: String?                     // Custom cargo executable path
    var rustupHome: String?                    // Custom RUSTUP_HOME env var
    var cargoHome: String?                     // Custom CARGO_HOME env var
    var overrideStrategy: OverrideStrategy     // How to set project overrides
    var authorizedDirectories: [UUID]          // IDs of authorized bookmarks

    enum OverrideStrategy: String, Codable {
        case toolchainFile                     // Write rust-toolchain.toml
        case rustupOverride                    // Use rustup override set

        var displayText: String {
            switch self {
            case .toolchainFile: return "Write rust-toolchain.toml (recommended)"
            case .rustupOverride: return "Use rustup override"
            }
        }

        var helpText: String {
            switch self {
            case .toolchainFile:
                return "Creates or updates rust-toolchain.toml in the project. Can be committed to version control."
            case .rustupOverride:
                return "Uses rustup's override database. Does not modify project files."
            }
        }
    }

    // Default settings
    static let `default` = AppSettings(
        rustupPath: nil,
        cargoPath: nil,
        rustupHome: nil,
        cargoHome: nil,
        overrideStrategy: .toolchainFile,
        authorizedDirectories: []
    )
}
```

**Persistence**:
- Stored in UserDefaults (key: `AppSettings`)
- Synced across app launches
- Does NOT store bookmark data (stored separately in Keychain)

---

## Model Relationships Diagram

```
┌─────────────────────┐
│   ToolchainInfo     │
│                     │
│  - name             │ 1
│  - version          ├──────┐
│  - isDefault        │      │
└─────────────────────┘      │
         △                   │
         │                   │
         │ references        │
         │                   │ has many
┌────────┴──────────┐   ┌────▼──────────────┐
│ ProjectContextInfo│   │  ComponentInfo    │
│                   │   │                   │
│  - projectPath    │   │  - name           │
│  - activeToolchain│   │  - toolchainName  │
│  - reason         │   │  - isInstalled    │
└───────────────────┘   └───────────────────┘
         │
         │ requires         has many
         │                   ┌───────────────┐
         ▼                   │               │
┌────────────────────┐  ┌────▼──────────────▼┐
│AuthorizedDirectory │  │    TargetInfo      │
│                    │  │                    │
│  - path            │  │  - triple          │
│  - bookmarkData    │  │  - toolchainName   │
│  - purpose         │  │  - isInstalled     │
└────────────────────┘  └────────────────────┘

┌─────────────────────┐
│    TaskRecord       │
│                     │
│  - operation        │ may reference
│  - target           ├────────────────> ToolchainInfo
│  - status           │                  ComponentInfo
│  - errorMessage     │                  TargetInfo
└─────────────────────┘
```

---

## Persistence Strategy

| Entity | Storage | Rationale |
|--------|---------|-----------|
| `ToolchainInfo` | In-memory (ViewModel) | Derived from rustup on each refresh, not persisted |
| `ComponentInfo` | In-memory (ViewModel) | Derived from rustup on each refresh, not persisted |
| `TargetInfo` | In-memory (ViewModel) | Derived from rustup on each refresh, not persisted |
| `ProjectContextInfo` | In-memory (ViewModel) | Derived from rustup show, recently accessed list persisted in UserDefaults |
| `TaskRecord` | In-memory (ViewModel) | Kept in memory for current session, optionally persist last 20 for history |
| `AuthorizedDirectory` | Keychain | Security-sensitive bookmark data, encrypted by system |
| `AppSettings` | UserDefaults | User preferences, low sensitivity |

**Refresh Strategy** (from FR-208, FR-209):
- Toolchains/Components/Targets: Refresh on app launch, foreground activation, after write operations
- Project Contexts: Refresh on project selection or manual refresh
- Task Records: Updated in real-time as operations complete

---

## Validation Summary

All models include validation logic aligned with functional requirements:

| Model | Validation Rule | FR Reference |
|-------|-----------------|--------------|
| `ToolchainInfo` | Name regex `[A-Za-z0-9._-]{1,128}` | FR-804 |
| `TargetInfo` | Triple regex `[A-Za-z0-9._-]{1,128}` | FR-804 |
| `ProjectContextInfo` | Path within authorized bookmark scope | FR-805 |
| `TaskRecord` | Stderr snippet max 32KB | FR-603 |
| `AuthorizedDirectory` | Bookmark data must be valid | FR-106 |

All validation enforced at XPC Service boundary (CommandValidator).

---

## Next Steps

1. Generate XPC protocol contracts (contracts/)
2. Generate quickstart.md for developer onboarding
3. Update agent context with Swift/XPC patterns
