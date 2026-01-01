# Research: XPC Architecture & Sandbox Constraints for RustMate

**Feature**: RustMate Visual Interface for Rustup Operations
**Date**: 2025-12-31
**Purpose**: Resolve technical unknowns related to XPC-based command execution in App Sandbox

## Research Questions

Based on the user's requirement that "commands must be executed via XPC because the app runs in sandbox environment and cannot directly execute commands," the following areas required research:

1. How to structure XPC communication for rustup command execution
2. How to handle Security-Scoped Bookmarks for executable access
3. How to serialize command execution to prevent rustup lock conflicts
4. How to parse rustup output reliably with fallback mechanisms
5. How to handle long-running operations without blocking UI

## 1. XPC Service Architecture for Sandboxed Command Execution

### Decision: Embedded XPC Service with Actor-Based Executor

**Chosen Approach**:
- Create an embedded XPC Service target (`RustMateXPC.xpc`) packaged within the main app bundle
- XPC Service runs in separate process but remains sandboxed (no privilege escalation)
- Use Swift Concurrency `actor RustupExecutor` for serial command execution
- XPC protocol uses async/await completion handlers (modernized from legacy completion blocks)

**Rationale**:
1. **App Store compatible**: Embedded XPC services are allowed and don't require separate installation
2. **Process isolation**: Prevents long-running rustup operations from blocking the UI process
3. **Crash isolation**: If rustup execution crashes, only XPC service dies (not main app)
4. **Serial execution**: Actor guarantees single-threaded access to rustup, preventing lock conflicts
5. **Modern Swift**: async/await XPC protocol is cleaner than callback-based approaches

**Alternatives Considered**:
- **Direct execution in app process**: REJECTED - violates constitution (no direct command execution in sandbox without authorization), would block UI
- **System-wide daemon (SMAppService)**: REJECTED - not allowed for App Store, requires elevated privileges
- **NSTask/Process directly in app**: REJECTED - requires Security-Scoped Bookmark for every execution, harder to serialize

**Implementation Pattern**:
```swift
// XPC Protocol (Objective-C compatible for XPC)
@objc protocol RustMateXPCProtocol {
    func listToolchains(reply: @escaping ([ToolchainInfo]?, Error?) -> Void)
    func installToolchain(name: String, reply: @escaping (TaskResult) -> Void)
    // ... other methods
}

// XPC Service (separate process)
actor RustupExecutor {
    private let processRunner: ProcessRunner
    private let validator: CommandValidator

    func executeRustup(args: [String]) async throws -> TaskResult {
        // Serial execution guaranteed by actor
        // 1. Validate command
        // 2. Run Process with Pipe
        // 3. Collect output
        // 4. Parse or return snippet
    }
}
```

**References**:
- Apple Documentation: "Creating an XPC Service" (https://developer.apple.com/documentation/xpc)
- WWDC 2020: "XPC in Swift" (modern async/await patterns)
- Swift Evolution: SE-0296 Async/await (supports XPC integration)

---

## 2. Security-Scoped Bookmarks for Rustup Executable Access

### Decision: User-Authorized Directory Bookmark for ~/.cargo/bin

**Chosen Approach**:
- On first launch, prompt user to select `~/.cargo/bin` directory via NSOpenPanel
- Create Security-Scoped Bookmark using `URL.bookmarkData(options: .withSecurityScope)`
- Persist bookmark data to Keychain (more secure than UserDefaults for security-sensitive data)
- Before each rustup execution, resolve bookmark and call `startAccessingSecurityScopedResource()`
- Call `stopAccessingSecurityScopedResource()` after command completes (or use defer)

**Rationale**:
1. **Sandbox requirement**: App Sandbox prevents direct access to `~/.cargo/bin` without user authorization
2. **Persistent authorization**: Bookmark survives app restarts (no re-authorization required)
3. **Keychain security**: Protects bookmark data from tampering or extraction
4. **User control**: User explicitly grants access, making security model transparent

**Alternatives Considered**:
- **Request executable file directly**: REJECTED - would require selecting `rustup` file specifically, poor UX (users expect directory selection)
- **UserDefaults for storage**: REJECTED - less secure, bookmark data should be protected
- **com.apple.security.files.user-selected.read-write entitlement only**: REJECTED - still need to create and persist bookmarks programmatically

**Implementation Pattern**:
```swift
class BookmarkManager {
    func createBookmark(for url: URL) throws -> Data {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        try saveToKeychain(bookmarkData, for: url.path)
        return bookmarkData
    }

    func resolveBookmark(for path: String) throws -> URL {
        let bookmarkData = try loadFromKeychain(for: path)
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        if isStale {
            // Re-create bookmark
        }
        return url
    }
}

// Usage in XPC Service
func executeCommand() async throws {
    let cargoURL = try bookmarkManager.resolveBookmark(for: "~/.cargo/bin")
    guard cargoURL.startAccessingSecurityScopedResource() else {
        throw BookmarkError.accessDenied
    }
    defer { cargoURL.stopAccessingSecurityScopedResource() }

    let rustupPath = cargoURL.appendingPathComponent("rustup").path
    // Execute rustup...
}
```

**References**:
- Apple Documentation: "Security-Scoped Bookmarks" (https://developer.apple.com/documentation/foundation/url/2143023-bookmarkdata)
- "App Sandbox in Depth" (WWDC 2012, still relevant)
- "Accessing Files from the macOS App Sandbox" (https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/)

---

## 3. Serial Execution with Swift Actor

### Decision: Actor-Based RustupExecutor for Queue Management

**Chosen Approach**:
- Define `actor RustupExecutor` to wrap all rustup command execution
- Actor's serial execution queue automatically serializes all operations
- Use async/await for caller-side concurrency (multiple requests can await, but execute serially)
- XPC Service owns single instance of `RustupExecutor` shared across all client requests

**Rationale**:
1. **Rustup safety**: Rustup's internal state management (e.g., toolchain installation) is not thread-safe; concurrent operations cause lock file conflicts
2. **Simplicity**: Actor provides built-in serialization without manual queue management
3. **Compiler guarantees**: Swift compiler enforces actor isolation, preventing accidental concurrent access
4. **Backpressure handling**: async/await naturally handles backpressure (callers suspend until executor is ready)

**Alternatives Considered**:
- **DispatchQueue.serial**: REJECTED - more boilerplate, no compiler enforcement, easy to bypass accidentally
- **NSOperationQueue (maxConcurrentOperationCount = 1)**: REJECTED - older API, more complex than actor
- **Semaphore-based locking**: REJECTED - easy to deadlock, requires manual lock management

**Implementation Pattern**:
```swift
actor RustupExecutor {
    private let validator: CommandValidator
    private let processRunner: ProcessRunner

    // Automatically serialized by actor
    func listToolchains() async throws -> [ToolchainInfo] {
        let result = try await processRunner.run(command: "rustup", args: ["toolchain", "list"])
        return try ToolchainParser.parse(result.stdout)
    }

    func installToolchain(name: String) async throws -> TaskResult {
        // This will wait if another install is running
        try validator.validateToolchainName(name)
        let result = try await processRunner.run(command: "rustup", args: ["toolchain", "install", name])
        return TaskResult(exitCode: result.exitCode, stderr: result.stderr)
    }
}

// Usage from XPC Service
class RustMateXPCService: NSObject, RustMateXPCProtocol {
    private let executor = RustupExecutor()

    func installToolchain(name: String, reply: @escaping (TaskResult) -> Void) {
        Task {
            do {
                let result = try await executor.installToolchain(name: name)
                reply(result)
            } catch {
                reply(TaskResult(error: error))
            }
        }
    }
}
```

**References**:
- Swift Evolution: SE-0306 Actors (https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
- "Protect mutable state with Swift actors" (WWDC 2021)
- "Swift Concurrency: Behind the Scenes" (WWDC 2021)

---

## 4. Rustup Output Parsing with Fallback Strategy

### Decision: Regex-Based Parsing with Structured Fallback

**Chosen Approach**:
- Each rustup command has dedicated parser (e.g., `ToolchainParser`, `ComponentParser`)
- Parsers use regex or line-by-line pattern matching to extract structured data
- If parsing fails, return `ParseError` with original stdout/stderr snippet (max 32KB)
- Maintain test fixture library of real rustup output samples (current and historical versions)
- UI displays fallback text if structured data unavailable (graceful degradation)

**Rationale**:
1. **Output instability**: Rustup's CLI output is not a stable API; format changes between versions
2. **Graceful degradation**: Parsing failure doesn't crash app; users see raw output instead
3. **Future-proofing**: Test fixtures help detect breaking changes in rustup output early
4. **No external dependencies**: Avoid heavy parsing libraries (ANTLR, SwiftParsec) for simple CLI output

**Alternatives Considered**:
- **JSON output from rustup**: REJECTED - not all rustup commands support `--format json` (e.g., `rustup show`)
- **Scraping HTML help text**: REJECTED - even more brittle than stdout parsing
- **Direct rustup library integration**: REJECTED - rustup is Rust, would require FFI bindings and non-sandboxed compilation

**Parsing Strategy by Command**:

| Command | Parsing Strategy | Fallback |
|---------|------------------|----------|
| `rustup toolchain list` | Regex: `^(\S+)( \(default\))?$` per line | Return lines as-is with `isDefault: false` |
| `rustup component list` | Regex: `^(\S+)(?: \((installed|not installed)\))?$` | Return component names only, status unknown |
| `rustup target list` | Regex: `^(\S+)(?: \((installed|not installed)\))?$` | Same as component |
| `rustup show` | Multi-line parser: find "active toolchain" section, parse "overridden by" | Return first line containing "toolchain" |

**Implementation Pattern**:
```swift
struct ToolchainParser {
    static func parse(_ output: String) throws -> [ToolchainInfo] {
        var toolchains: [ToolchainInfo] = []
        let lines = output.split(separator: "\n")

        let pattern = #"^(\S+)( \(default\))?$"#
        let regex = try NSRegularExpression(pattern: pattern)

        for line in lines {
            let nsLine = line as NSString
            guard let match = regex.firstMatch(in: String(line), range: NSRange(location: 0, length: nsLine.length)) else {
                // Skip unparseable lines (warnings, blank lines, etc.)
                continue
            }

            let name = nsLine.substring(with: match.range(at: 1))
            let isDefault = match.range(at: 2).location != NSNotFound
            toolchains.append(ToolchainInfo(name: name, isDefault: isDefault))
        }

        if toolchains.isEmpty {
            throw ParseError.noToolchainsFound(snippet: String(output.prefix(1024)))
        }

        return toolchains
    }
}

// Test fixture example
class ToolchainParserTests: XCTestCase {
    func testParseStableOutput() throws {
        let fixtureOutput = """
        stable-aarch64-apple-darwin (default)
        nightly-2024-01-15-aarch64-apple-darwin
        """
        let toolchains = try ToolchainParser.parse(fixtureOutput)
        XCTAssertEqual(toolchains.count, 2)
        XCTAssertTrue(toolchains[0].isDefault)
    }
}
```

**References**:
- Rustup User Guide: CLI output (https://rust-lang.github.io/rustup/) - documents current format but no stability guarantees
- Swift NSRegularExpression documentation
- "Testing Edge Cases with Fixtures" (best practice)

---

## 5. Long-Running Operation Handling

### Decision: Async/Await with Progress Observation (Status-Only)

**Chosen Approach**:
- XPC methods return immediately with async reply handler
- UI shows task in "running" state while awaiting completion
- NO real-time progress streaming (per constitution: structured results only)
- Task status updates: running → success/failed (with result/error)
- Best-effort cancellation: Process.terminate() when user cancels, but may not be immediate

**Rationale**:
1. **Constitution compliance**: No log streaming, only structured status updates
2. **UI responsiveness**: async/await allows UI to remain interactive during long operations
3. **Simplicity**: Avoid complex progress reporting infrastructure (progress bars, percentage, etc.)
4. **Rustup limitations**: Rustup doesn't provide machine-readable progress; would require stdout scraping (brittle)

**Alternatives Considered**:
- **Real-time progress bars**: REJECTED - rustup output not machine-readable for progress, would require fragile parsing
- **Streaming stdout to UI**: REJECTED - violates constitution (structured results only), poor UX for multi-line output
- **Synchronous blocking calls**: REJECTED - would freeze UI during 100MB+ toolchain downloads

**Implementation Pattern**:
```swift
// ViewModel tracks task status
@MainActor
@Observable
class ToolchainsViewModel {
    var tasks: [TaskRecord] = []

    func installToolchain(name: String) async {
        let taskID = UUID()
        let task = TaskRecord(id: taskID, operation: "Install \(name)", status: .running)
        tasks.append(task)

        do {
            let result = try await service.installToolchain(name: name)
            updateTask(taskID, status: .success, result: result)
        } catch {
            updateTask(taskID, status: .failed, error: error)
        }
    }

    func cancelTask(_ taskID: UUID) async {
        await service.cancelTask(taskID) // Best effort
        updateTask(taskID, status: .cancelled)
    }
}

// XPC Service tracks running processes for cancellation
actor RustupExecutor {
    private var runningProcesses: [UUID: Process] = [:]

    func installToolchain(taskID: UUID, name: String) async throws -> TaskResult {
        let process = Process()
        runningProcesses[taskID] = process
        defer { runningProcesses.removeValue(forKey: taskID) }

        // ... configure and run process
        let result = try await processRunner.run(process)
        return result
    }

    func cancelTask(taskID: UUID) {
        runningProcesses[taskID]?.terminate()
    }
}
```

**UI Pattern**:
- Show spinning indicator + "Installing stable-aarch64-apple-darwin..." during operation
- On success: show checkmark + "Installed successfully" for 3 seconds, then remove from active tasks
- On failure: show error icon + "Installation failed: [error summary]" with "Show Details" button
- "Cancel" button sends terminate signal (may take seconds to take effect)

**References**:
- Apple Documentation: Process.terminate() (https://developer.apple.com/documentation/foundation/process/1414221-terminate)
- "Modern Concurrency in Swift: async/await" (WWDC 2021)
- SwiftUI Observation framework (@Observable, @MainActor)

---

## 6. XPC Protocol Design Best Practices

### Decision: Typed Protocol with Codable Structs (No NSCoding)

**Chosen Approach**:
- Define XPC protocol as `@objc protocol` for XPC compatibility
- Use Codable structs for data transfer (auto-serialized by XPC runtime in modern Swift)
- Avoid NSCoding and NSObject inheritance (prefer value types)
- All methods async with completion handlers (modernized XPC pattern)

**Rationale**:
1. **Type safety**: Codable provides compile-time type checking
2. **Modern Swift**: Value types (structs) preferred over NSObject classes
3. **Simplicity**: Codable auto-synthesizes serialization (no manual NSCoding implementation)
4. **Future-proof**: Swift 6+ encourages Codable over NSCoding

**Implementation Pattern**:
```swift
// Shared Codable models (in Shared target)
struct ToolchainInfo: Codable, Sendable {
    let name: String
    let version: String?
    let isDefault: Bool
}

struct TaskResult: Codable, Sendable {
    let exitCode: Int
    let stdoutSnippet: String?
    let stderrSnippet: String?
    let errorMessage: String?
}

// XPC Protocol
@objc protocol RustMateXPCProtocol {
    func listToolchains(reply: @escaping (Data?, Error?) -> Void) // Data = JSON-encoded [ToolchainInfo]
    func installToolchain(name: String, reply: @escaping (Data) -> Void) // Data = JSON-encoded TaskResult
}

// Client-side wrapper
class XPCToolchainService: RustToolchainServiceProtocol {
    private let connection: NSXPCConnection

    func listToolchains() async throws -> [ToolchainInfo] {
        try await withCheckedThrowingContinuation { continuation in
            proxy.listToolchains { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    let toolchains = try! JSONDecoder().decode([ToolchainInfo].self, from: data)
                    continuation.resume(returning: toolchains)
                }
            }
        }
    }
}
```

**References**:
- Apple Documentation: "Using Codable with XPC" (https://developer.apple.com/documentation/foundation/archives_and_serialization/using_json_with_custom_types)
- Swift Evolution: SE-0166 Swift Encoders (Codable)

---

## Summary of Key Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Architecture** | Embedded XPC Service with Actor-based executor | App Store compatible, process isolation, serial execution |
| **File Access** | Security-Scoped Bookmarks for ~/.cargo/bin | Sandbox requirement, persistent authorization |
| **Serialization** | Swift Actor (RustupExecutor) | Prevents rustup lock conflicts, compiler-enforced safety |
| **Output Parsing** | Regex with fallback to snippets | Handles rustup output instability gracefully |
| **Long Operations** | Async/await with status-only updates | UI responsive, no log streaming (constitution) |
| **Data Transfer** | Codable structs over XPC | Type-safe, modern Swift, simpler than NSCoding |

All decisions align with the project constitution and App Store requirements. No exceptions or violations required.

**Next Phase**: Proceed to Phase 1 (data-model.md, contracts, quickstart.md).
