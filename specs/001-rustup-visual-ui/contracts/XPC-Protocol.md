# XPC Protocol Contract: RustMateXPCProtocol

**Version**: 1.0.0
**Date**: 2025-12-31
**Purpose**: Define the XPC interface between RustMate app and RustMateXPC service

## Overview

The `RustMateXPCProtocol` defines all operations that the main app can request from the XPC Service. The service acts as an execution layer that:
1. Validates all incoming commands against a whitelist
2. Executes rustup/cargo commands serially (via Actor)
3. Parses output into structured models
4. Returns results or errors to the caller

All methods use async-style completion handlers compatible with Swift's modern concurrency.

## Protocol Definition

### Base Protocol

```swift
import Foundation

@objc protocol RustMateXPCProtocol {
    // MARK: - Environment & Validation

    /// Ping the service to verify connectivity
    /// - Parameter reply: Completion with success/error
    func ping(reply: @escaping (Bool) -> Void)

    /// Validate that rustup is accessible and executable
    /// - Parameter reply: Completion with validation result
    /// - Returns: ValidationResult encoded as Data (JSON)
    func validateEnvironment(
        rustupPath: String?,
        reply: @escaping (Data?, Error?) -> Void
    )

    // MARK: - Toolchain Operations

    /// List all installed toolchains
    /// - Parameter reply: Completion with toolchain list
    /// - Returns: [ToolchainInfo] encoded as Data (JSON)
    func listToolchains(reply: @escaping (Data?, Error?) -> Void)

    /// Install a toolchain (stable, beta, nightly, or custom)
    /// - Parameters:
    ///   - name: Toolchain name (validated against regex)
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func installToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    /// Uninstall a toolchain
    /// - Parameters:
    ///   - name: Toolchain name
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func uninstallToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    /// Set a toolchain as the default
    /// - Parameters:
    ///   - name: Toolchain name
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func setDefaultToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    /// Update all installed toolchains
    /// - Parameter reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func updateAllToolchains(reply: @escaping (Data) -> Void)

    /// Update a specific toolchain
    /// - Parameters:
    ///   - name: Toolchain name
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func updateToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Component Operations

    /// List all components for a toolchain
    /// - Parameters:
    ///   - toolchainName: Parent toolchain name
    ///   - reply: Completion with component list
    /// - Returns: [ComponentInfo] encoded as Data (JSON)
    func listComponents(
        toolchainName: String,
        reply: @escaping (Data?, Error?) -> Void
    )

    /// Add a component to a toolchain
    /// - Parameters:
    ///   - componentName: Component name (e.g., "clippy")
    ///   - toolchainName: Parent toolchain name
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func addComponent(
        componentName: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    /// Remove a component from a toolchain
    /// - Parameters:
    ///   - componentName: Component name
    ///   - toolchainName: Parent toolchain name
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func removeComponent(
        componentName: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Target Operations

    /// List all targets for a toolchain
    /// - Parameters:
    ///   - toolchainName: Parent toolchain name
    ///   - reply: Completion with target list
    /// - Returns: [TargetInfo] encoded as Data (JSON)
    func listTargets(
        toolchainName: String,
        reply: @escaping (Data?, Error?) -> Void
    )

    /// Add a target to a toolchain
    /// - Parameters:
    ///   - targetTriple: Target triple (e.g., "wasm32-unknown-unknown")
    ///   - toolchainName: Parent toolchain name
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func addTarget(
        targetTriple: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    /// Remove a target from a toolchain
    /// - Parameters:
    ///   - targetTriple: Target triple
    ///   - toolchainName: Parent toolchain name
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func removeTarget(
        targetTriple: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Project Context Operations

    /// Get project context (active toolchain and reason)
    /// - Parameters:
    ///   - projectPath: Absolute path to project directory
    ///   - reply: Completion with project context
    /// - Returns: ProjectContextInfo encoded as Data (JSON)
    func getProjectContext(
        projectPath: String,
        reply: @escaping (Data?, Error?) -> Void
    )

    /// Set project toolchain override
    /// - Parameters:
    ///   - projectPath: Absolute path to project directory
    ///   - toolchainName: Toolchain to set as override
    ///   - mode: "toolchainFile" or "rustupOverride"
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func setProjectOverride(
        projectPath: String,
        toolchainName: String,
        mode: String,
        reply: @escaping (Data) -> Void
    )

    /// Clear project toolchain override
    /// - Parameters:
    ///   - projectPath: Absolute path to project directory
    ///   - mode: "toolchainFile" or "rustupOverride"
    ///   - reply: Completion with task result
    /// - Returns: TaskResult encoded as Data (JSON)
    func clearProjectOverride(
        projectPath: String,
        mode: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Task Management

    /// Cancel a running task (best effort)
    /// - Parameters:
    ///   - taskID: UUID of the task to cancel
    ///   - reply: Completion indicating cancellation attempt
    func cancelTask(
        taskID: String,
        reply: @escaping (Bool) -> Void
    )
}
```

---

## Data Structures (Transferred as JSON-encoded Data)

All complex types are transferred as JSON-encoded `Data` over XPC for type safety and Codable compatibility.

### ValidationResult

```swift
struct ValidationResult: Codable, Sendable {
    let hasRustup: Bool              // True if rustup found and executable
    let rustupPath: String?          // Path to rustup executable
    let version: String?             // Rustup version (from `rustup --version`)
    let hints: [String]              // Suggested fixes if not found
}
```

**Returned by**: `validateEnvironment`

**Example**:
```json
{
  "hasRustup": false,
  "rustupPath": null,
  "version": null,
  "hints": [
    "Rustup not found at ~/.cargo/bin/rustup",
    "Grant access to ~/.cargo/bin in Settings",
    "Or specify custom rustup path in Settings"
  ]
}
```

---

### ToolchainInfo

```swift
struct ToolchainInfo: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let version: String?
    let isDefault: Bool
    let installDate: Date?
    let host: String?
}
```

**Returned by**: `listToolchains`

**Example**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "stable-aarch64-apple-darwin",
  "version": "1.75.0",
  "isDefault": true,
  "installDate": "2025-01-01T00:00:00Z",
  "host": "aarch64-apple-darwin"
}
```

---

### ComponentInfo

```swift
struct ComponentInfo: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let toolchainName: String
    let isInstalled: Bool
    let description: String?
}
```

**Returned by**: `listComponents`

**Example**:
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440001",
  "name": "clippy",
  "toolchainName": "stable-aarch64-apple-darwin",
  "isInstalled": true,
  "description": "Linting tool for Rust"
}
```

---

### TargetInfo

```swift
struct TargetInfo: Codable, Identifiable, Sendable {
    let id: UUID
    let triple: String
    let toolchainName: String
    let isInstalled: Bool
    let description: String?
}
```

**Returned by**: `listTargets`

**Example**:
```json
{
  "id": "750e8400-e29b-41d4-a716-446655440002",
  "triple": "wasm32-unknown-unknown",
  "toolchainName": "stable-aarch64-apple-darwin",
  "isInstalled": false,
  "description": "WebAssembly target"
}
```

---

### ProjectContextInfo

```swift
struct ProjectContextInfo: Codable, Identifiable, Sendable {
    let id: UUID
    let projectPath: String
    let activeToolchain: String
    let reason: String  // "environment" | "toolchainFile" | "override" | "default" | "unknown"
    let sourcePath: String?
    let lastAccessed: Date
}
```

**Returned by**: `getProjectContext`

**Example**:
```json
{
  "id": "850e8400-e29b-41d4-a716-446655440003",
  "projectPath": "/Users/dev/my-rust-project",
  "activeToolchain": "nightly-2024-01-15",
  "reason": "toolchainFile",
  "sourcePath": "/Users/dev/my-rust-project/rust-toolchain.toml",
  "lastAccessed": "2025-12-31T12:00:00Z"
}
```

---

### TaskResult

```swift
struct TaskResult: Codable, Sendable {
    let exitCode: Int
    let stdoutSnippet: String?
    let stderrSnippet: String?
    let errorMessage: String?
    let suggestedFix: String?
}
```

**Returned by**: All write operations (install, uninstall, update, add, remove, set/clear override)

**Success Example**:
```json
{
  "exitCode": 0,
  "stdoutSnippet": "info: installing component 'rustc'\ninfo: downloading component...",
  "stderrSnippet": null,
  "errorMessage": null,
  "suggestedFix": null
}
```

**Failure Example**:
```json
{
  "exitCode": 1,
  "stdoutSnippet": null,
  "stderrSnippet": "error: could not download file from 'https://...'",
  "errorMessage": "Network error during download",
  "suggestedFix": "Check your internet connection or try again later"
}
```

---

## Error Handling

### XPC Service Errors

The service may return `Error` in reply handlers for:

| Error | NSError Domain | Code | Description |
|-------|---------------|------|-------------|
| `ValidationError` | `com.finefine.RustMate.validation` | 1001 | Invalid toolchain/target name |
| `BookmarkError` | `com.finefine.RustMate.bookmark` | 2001 | Bookmark access denied/stale |
| `ExecutionError` | `com.finefine.RustMate.execution` | 3001 | Process execution failed |
| `ParseError` | `com.finefine.RustMate.parse` | 4001 | Output parsing failed (with snippet) |
| `RustupNotFoundError` | `com.finefine.RustMate.rustup` | 5001 | Rustup executable not found |

### Client-Side Error Handling Pattern

```swift
func listToolchains() async throws -> [ToolchainInfo] {
    try await withCheckedThrowingContinuation { continuation in
        xpcProxy.listToolchains { data, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let data = data {
                do {
                    let toolchains = try JSONDecoder().decode([ToolchainInfo].self, from: data)
                    continuation.resume(returning: toolchains)
                } catch {
                    continuation.resume(throwing: ParseError.decodingFailed(underlying: error))
                }
            } else {
                continuation.resume(throwing: XPCError.noDataReturned)
            }
        }
    }
}
```

---

## Command Validation Rules

All incoming parameters are validated by `CommandValidator` before execution:

### Toolchain Name Validation

- **Regex**: `^[A-Za-z0-9._-]{1,128}$`
- **Max Length**: 128 characters
- **Examples**:
  - ✅ `stable`
  - ✅ `nightly-2024-01-15`
  - ✅ `1.75.0-x86_64-apple-darwin`
  - ❌ `stable; rm -rf /` (injection attempt)
  - ❌ `../../../etc/passwd` (path traversal)

### Target Triple Validation

- **Regex**: `^[A-Za-z0-9._-]{1,128}$`
- **Max Length**: 128 characters
- **Examples**:
  - ✅ `wasm32-unknown-unknown`
  - ✅ `aarch64-apple-darwin`
  - ❌ `invalid target; malicious` (injection attempt)

### Project Path Validation

- **Must be absolute path**: Starts with `/` (macOS)
- **Must be within authorized bookmark scope**: Checked via `BookmarkManager`
- **Examples**:
  - ✅ `/Users/dev/my-project` (if bookmarked)
  - ❌ `../../etc` (relative path)
  - ❌ `/System/Library` (not bookmarked)

### Override Mode Validation

- **Allowed values**: `"toolchainFile"`, `"rustupOverride"`
- **Examples**:
  - ✅ `toolchainFile`
  - ✅ `rustupOverride`
  - ❌ `arbitrary_value`

---

## Security Considerations

### Connection Validation

The XPC Service MUST validate incoming connections:

```swift
func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    // Verify connection comes from main app
    guard let auditToken = newConnection.auditToken else { return false }

    // Check code signature (TeamID, Bundle ID)
    let secCode = /* create SecCode from auditToken */
    let requirement = SecRequirementCreateWithString("identifier \"com.finefine.RustMate\" and anchor apple generic" as CFString, [], nil)

    // Verify signature matches
    guard SecCodeCheckValidity(secCode, [], requirement) == errSecSuccess else {
        return false
    }

    // Protocol version check
    newConnection.exportedInterface = NSXPCInterface(with: RustMateXPCProtocol.self)
    newConnection.exportedObject = self
    newConnection.resume()
    return true
}
```

### Sandbox Constraints

The XPC Service runs in the same sandbox as the main app:
- MUST use Security-Scoped Bookmarks for file access
- CANNOT escape sandbox permissions
- CANNOT access system-wide resources without authorization

---

## Protocol Versioning

**Current Version**: 1.0.0

### Version Handshake (Recommended)

```swift
extension RustMateXPCProtocol {
    func getProtocolVersion(reply: @escaping (String) -> Void) {
        reply("1.0.0")
    }
}

// Client checks version on connect
let serverVersion = try await service.getProtocolVersion()
guard serverVersion == "1.0.0" else {
    throw XPCError.versionMismatch(server: serverVersion, client: "1.0.0")
}
```

### Backward Compatibility Strategy

- **Minor version changes**: Add new methods (old clients ignore)
- **Major version changes**: Breaking changes (require app update)

---

## Testing Strategy

### XPC Integration Tests

```swift
class XPCProtocolTests: XCTestCase {
    var connection: NSXPCConnection!
    var service: RustMateXPCProtocol!

    override func setUp() {
        connection = NSXPCConnection(serviceName: "com.finefine.RustMate.XPC")
        connection.remoteObjectInterface = NSXPCInterface(with: RustMateXPCProtocol.self)
        connection.resume()
        service = connection.remoteObjectProxyWithErrorHandler { error in
            XCTFail("XPC connection failed: \(error)")
        } as? RustMateXPCProtocol
    }

    func testListToolchains() async throws {
        let data = try await withCheckedThrowingContinuation { continuation in
            service.listToolchains { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                }
            }
        }

        let toolchains = try JSONDecoder().decode([ToolchainInfo].self, from: data)
        XCTAssertFalse(toolchains.isEmpty)
    }
}
```

### Mock XPC Service (for UI Tests)

```swift
class MockXPCService: RustMateXPCProtocol {
    func listToolchains(reply: @escaping (Data?, Error?) -> Void) {
        let mockToolchains = [
            ToolchainInfo(id: UUID(), name: "stable", version: "1.75.0", isDefault: true, installDate: nil, host: nil)
        ]
        let data = try! JSONEncoder().encode(mockToolchains)
        reply(data, nil)
    }

    // ... other mock implementations
}
```

---

## Summary

This XPC protocol provides:
- ✅ Type-safe communication via Codable + JSON encoding
- ✅ Async/await compatibility for modern Swift concurrency
- ✅ Comprehensive validation at service boundary
- ✅ Structured error handling with user-actionable messages
- ✅ Security through connection validation and command whitelisting
- ✅ Testability via protocol abstraction and mock services

**Next**: Generate quickstart.md for developer onboarding.
