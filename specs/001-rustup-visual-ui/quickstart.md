# Quickstart: RustMate Development

**Feature**: RustMate Visual Interface for Rustup Operations
**Date**: 2025-12-31
**Purpose**: Get developers up and running with RustMate development quickly

## Prerequisites

Before starting development, ensure you have:

- **macOS 13.0+** (Ventura or later)
- **Xcode 15+** with Swift 5.9+
- **Rustup installed** on your development machine (for testing)
  - Install via: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
  - Verify: `rustup --version`
- **Basic familiarity** with:
  - SwiftUI and Swift Concurrency (async/await, Actors)
  - XPC Services (helpful but not required - see research.md)
  - App Sandbox constraints

## Project Setup

### 1. Clone and Open Project

```bash
cd /Users/fineke/workspace/osx/RustMate
open RustMate.xcodeproj
```

### 2. Project Structure Overview

```
RustMate.xcodeproj/
├── RustMate/             # Main app target (UI layer)
├── RustMateXPC/          # XPC Service target (execution layer)
├── Shared/               # Shared models (Codable structs)
├── RustMateTests/        # Unit tests
└── RustMateUITests/      # UI integration tests
```

### 3. Build Targets

The project contains two primary targets:

1. **RustMate** (main app)
   - Product: RustMate.app
   - Bundle ID: `com.finefine.RustMate`
   - Entitlements: App Sandbox, User Selected Files (read/write)

2. **RustMateXPC** (XPC service)
   - Product: RustMateXPC.xpc (embedded in RustMate.app/Contents/XPCServices/)
   - Bundle ID: `com.finefine.RustMate.XPC`
   - Entitlements: App Sandbox (same constraints as main app)

### 4. Initial Build

```bash
# Build all targets
xcodebuild -scheme RustMate -configuration Debug

# Or build in Xcode: Cmd+B
```

**First build checklist**:
- ✅ RustMate.app builds successfully
- ✅ RustMateXPC.xpc embedded in app bundle
- ✅ No signing errors (use development team in Signing & Capabilities)

---

## Running the App

### Development Mode (with Xcode)

1. Select **RustMate** scheme in Xcode
2. Choose **My Mac** as destination
3. Press **Cmd+R** to run
4. On first launch:
   - App will prompt to grant access to `~/.cargo/bin`
   - Select the directory when prompted (NSOpenPanel)
   - App stores Security-Scoped Bookmark in Keychain

### Expected First Launch Flow

```
[App Launch]
    ↓
[Environment Validation] → Rustup not found?
    ↓                           ↓
[Show Setup Screen] ←───────────┘
    ↓
[User selects ~/.cargo/bin directory]
    ↓
[Create Security-Scoped Bookmark]
    ↓
[XPC Service validates rustup access]
    ↓
[Load Toolchains View] ✅
```

### Debugging XPC Connection

If XPC connection fails:

```swift
// Enable XPC debug logging in XPCClient.swift
connection.invalidationHandler = {
    print("❌ XPC connection invalidated")
}
connection.interruptionHandler = {
    print("⚠️ XPC connection interrupted")
}
```

Check Console.app for:
- `com.finefine.RustMate` logs (main app)
- `com.finefine.RustMate.XPC` logs (XPC service)

---

## Architecture Quick Reference

### Data Flow: User Action → Rustup Execution

```
[User taps "Install stable"]
    ↓
[ToolchainsViewModel.installToolchain()]
    ↓
[XPCToolchainService.installToolchain()] ← Protocol abstraction
    ↓
[NSXPCConnection → RustMateXPC service]
    ↓
[RustupExecutor.installToolchain()] ← Actor (serial execution)
    ↓
[CommandValidator.validate()] → Whitelist check
    ↓
[ProcessRunner.run()] → Execute `rustup toolchain install stable`
    ↓
[Collect stdout/stderr via Pipe]
    ↓
[Return TaskResult to ViewModel]
    ↓
[Update UI with success/error]
```

### Key Design Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| **Protocol-Driven** | All services are protocols with real + mock implementations | `RustToolchainServiceProtocol` → `XPCToolchainService` / `MockToolchainService` |
| **Actor Serialization** | Rustup operations serialized via Swift Actor | `actor RustupExecutor` |
| **Security-Scoped Bookmarks** | File access in sandbox | `BookmarkManager.createBookmark(for: URL)` |
| **Codable XPC Transfer** | Type-safe data transfer | `ToolchainInfo: Codable` → JSON over XPC |
| **@Observable ViewModels** | State management | `@Observable class ToolchainsViewModel` |

---

## Common Development Tasks

### Add a New ViewModel

```bash
# Create new ViewModel file
touch RustMate/ViewModels/MyNewViewModel.swift
```

```swift
import SwiftUI
import Observation

@MainActor
@Observable
final class MyNewViewModel {
    private let service: RustToolchainServiceProtocol

    var state: MyState = .idle

    init(service: RustToolchainServiceProtocol) {
        self.service = service
    }

    func performAction() async {
        state = .loading
        do {
            let result = try await service.someOperation()
            state = .success(result)
        } catch {
            state = .error(error)
        }
    }
}
```

### Add a New XPC Method

1. **Define in protocol** (`RustMateXPCProtocol.swift`):
```swift
@objc protocol RustMateXPCProtocol {
    func myNewOperation(param: String, reply: @escaping (Data?, Error?) -> Void)
}
```

2. **Implement in XPC Service** (`RustMateXPCService.swift`):
```swift
func myNewOperation(param: String, reply: @escaping (Data?, Error?) -> Void) {
    Task {
        do {
            let result = try await executor.executeMyOperation(param: param)
            let data = try JSONEncoder().encode(result)
            reply(data, nil)
        } catch {
            reply(nil, error)
        }
    }
}
```

3. **Add to service protocol** (`RustToolchainServiceProtocol.swift`):
```swift
protocol RustToolchainServiceProtocol {
    func myNewOperation(param: String) async throws -> MyResult
}
```

4. **Implement in XPC service wrapper** (`XPCToolchainService.swift`):
```swift
func myNewOperation(param: String) async throws -> MyResult {
    try await withCheckedThrowingContinuation { continuation in
        proxy.myNewOperation(param: param) { data, error in
            // ... decode and return
        }
    }
}
```

5. **Implement mock** (`MockToolchainService.swift`):
```swift
func myNewOperation(param: String) async throws -> MyResult {
    return MyResult(/* mock data */)
}
```

### Add a New Parser

```bash
# Create parser file
touch RustMateXPC/Parsers/MyNewParser.swift
```

```swift
import Foundation

struct MyNewParser {
    static func parse(_ output: String) throws -> [MyModel] {
        var models: [MyModel] = []

        let pattern = #"^(\S+)\s+(.+)$"#
        let regex = try NSRegularExpression(pattern: pattern)

        for line in output.split(separator: "\n") {
            guard let match = regex.firstMatch(in: String(line), range: NSRange(line.startIndex..., in: line)) else {
                continue
            }
            // Extract and create model
            models.append(MyModel(/* ... */))
        }

        if models.isEmpty {
            throw ParseError.noDataFound(snippet: String(output.prefix(1024)))
        }

        return models
    }
}
```

### Add Unit Tests

```bash
# Create test file
touch RustMateTests/ParserTests/MyNewParserTests.swift
```

```swift
import XCTest
@testable import RustMateXPC

class MyNewParserTests: XCTestCase {
    func testParseValidOutput() throws {
        let fixtureOutput = """
        item1 description1
        item2 description2
        """

        let models = try MyNewParser.parse(fixtureOutput)

        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[0].name, "item1")
        XCTAssertEqual(models[1].name, "item2")
    }

    func testParseEmptyOutput() {
        XCTAssertThrowsError(try MyNewParser.parse("")) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
}
```

---

## Testing Strategy

### Unit Tests (Fast)

```bash
# Run all tests
xcodebuild test -scheme RustMate -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme RustMate -destination 'platform=macOS' \
  -only-testing:RustMateTests/ToolchainParserTests

# Or in Xcode: Cmd+U
```

**What to test**:
- ✅ Parsers (with fixture samples from `Fixtures/`)
- ✅ ViewModels (with mock services)
- ✅ Validators (CommandValidator, regex patterns)
- ✅ BookmarkManager (with mock keychain)

### Integration Tests (XPC + Real Rustup)

```swift
class IntegrationTests: XCTestCase {
    var service: XPCToolchainService!

    override func setUp() {
        // Connect to real XPC service
        service = XPCToolchainService()
    }

    func testListToolchainsRealRustup() async throws {
        let toolchains = try await service.listToolchains()
        XCTAssertFalse(toolchains.isEmpty, "At least one toolchain should be installed")
    }
}
```

**Requirements**:
- Rustup must be installed on test machine
- Tests modify real rustup state (use separate test toolchain)
- Slower than unit tests (run less frequently)

### UI Tests (SwiftUI)

```bash
# Run UI tests
xcodebuild test -scheme RustMate -destination 'platform=macOS' \
  -only-testing:RustMateUITests
```

**What to test**:
- ✅ First-launch setup flow (bookmark authorization)
- ✅ Toolchain list display and refresh
- ✅ Install/uninstall operations (end-to-end)
- ✅ Error state display

---

## Debugging Tips

### XPC Service Not Responding

**Symptom**: App hangs on XPC calls, timeout errors

**Solutions**:
1. Check XPC service is embedded: `ls RustMate.app/Contents/XPCServices/`
2. Verify signing: `codesign -dv --verbose=4 RustMate.app/Contents/XPCServices/RustMateXPC.xpc`
3. Check Console.app for XPC launch errors
4. Ensure both app and XPC service have matching signing team

### Bookmark Access Denied

**Symptom**: "Bookmark access denied" errors when accessing rustup

**Solutions**:
1. Delete bookmark and re-authorize: Settings → Revoke Access → Re-add
2. Check bookmark stale status: `BookmarkManager.isBookmarkStale()`
3. Verify `com.apple.security.files.user-selected.read-write` entitlement enabled
4. Test with Console.app logs filtered by "Security-Scoped"

### Rustup Output Parsing Failed

**Symptom**: `ParseError` with snippet in logs

**Solutions**:
1. Add new rustup output sample to `Fixtures/` directory
2. Update parser regex to handle new format
3. Check rustup version: `rustup --version` (format may differ across versions)
4. Return fallback data when parsing fails (graceful degradation)

### Actor Serialization Deadlock

**Symptom**: Operations hang indefinitely, no completion

**Solutions**:
1. Ensure all actor methods are `async` (no blocking synchronous code)
2. Check for accidental `await` on same actor from within actor method
3. Use `Task.detached` if needing to break actor isolation
4. Review actor reentrancy rules (Swift 5.9+)

---

## SwiftUI Previews

All views should support SwiftUI Previews using mock services:

```swift
#Preview {
    ToolchainsListView(viewModel: ToolchainsViewModel(
        service: MockToolchainService()
    ))
}
```

**Preview advantages**:
- No XPC connection required
- Instant feedback (no build/run cycle)
- Test different states (loading, error, success)

**Example: Testing Error State**
```swift
#Preview("Error State") {
    let service = MockToolchainService()
    service.shouldFail = true
    service.error = RustupError.notFound

    return ToolchainsListView(viewModel: ToolchainsViewModel(service: service))
}
```

---

## Performance Profiling

### Profile XPC Communication Overhead

1. Open Instruments (Xcode → Product → Profile)
2. Choose **Time Profiler** template
3. Run app and perform operations
4. Filter by `com.fineke.RustMate.XPC` process
5. Look for bottlenecks in:
   - JSON encoding/decoding
   - XPC message serialization
   - Actor suspension points

**Optimization targets** (from Technical Context):
- XPC round-trip: <10ms (excluding rustup execution)
- UI state update: <100ms after XPC reply
- Toolchain list load: <2 seconds (total including rustup)

### Profile Rustup Command Execution

- Most time spent in rustup itself (network downloads, compilation)
- App overhead should be <5% of total operation time
- Use `ProcessRunner` timing logs to measure

---

## App Store Preparation Checklist

Before submitting to App Store:

- [ ] Enable App Sandbox in Release configuration
- [ ] Remove any hardcoded paths (use bookmarks only)
- [ ] Test on clean macOS install (no rustup pre-installed)
- [ ] Verify entitlements minimal (only user-selected files)
- [ ] Add privacy policy (data usage, bookmark purposes)
- [ ] Test signing with distribution certificate
- [ ] Validate archive with App Store Connect
- [ ] Test with App Sandbox Validator: `asctl sandbox check --bundle RustMate.app`

---

## Useful Resources

### Internal Docs

- [research.md](./research.md) - Architecture decisions and XPC patterns
- [data-model.md](./data-model.md) - Complete data model definitions
- [contracts/XPC-Protocol.md](./contracts/XPC-Protocol.md) - XPC interface specification
- [DESIGN.md](../../../DESIGN.md) - High-level design document (Chinese)
- [CLAUDE.md](../../../CLAUDE.md) - Project overview for Claude Code

### External References

- [App Sandbox Design Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/)
- [Creating XPC Services](https://developer.apple.com/documentation/xpc)
- [Security-Scoped Bookmarks](https://developer.apple.com/documentation/foundation/url/2143023-bookmarkdata)
- [Swift Actors (SE-0306)](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
- [SwiftUI Observation](https://developer.apple.com/documentation/observation)

---

## Getting Help

### Common Questions

**Q: Why XPC instead of direct Process execution in main app?**
A: XPC provides process isolation (UI doesn't freeze), crash isolation (rustup crash doesn't kill app), and cleaner serialization via Actor. See research.md section 1.

**Q: Why Actor instead of DispatchQueue?**
A: Actor provides compile-time enforcement of serial execution, automatic suspension/resumption with async/await, and clearer concurrency semantics. See research.md section 3.

**Q: Why JSON encoding over native NSCoding?**
A: Codable + JSON is type-safe, simpler to maintain (auto-synthesized), and aligns with modern Swift best practices. See research.md section 6.

**Q: Why no log streaming?**
A: Per project constitution, focus is on structured results (status, errors) rather than terminal output. This simplifies UI, improves performance, and avoids parsing brittle text output in real-time.

### Reporting Issues

When reporting bugs, include:
1. **Console logs** (filtered by `com.finefine.RustMate`)
2. **Xcode version** and macOS version
3. **Rustup version** (`rustup --version`)
4. **Steps to reproduce**
5. **Expected vs actual behavior**

---

## Next Steps

After completing quickstart:

1. ✅ Read [research.md](./research.md) for deep architectural understanding
2. ✅ Review [data-model.md](./data-model.md) for model relationships
3. ✅ Study [contracts/XPC-Protocol.md](./contracts/XPC-Protocol.md) for XPC interface details
4. ⏭️ Run `/speckit.tasks` to generate implementation task list
5. ⏭️ Start implementing M0 milestone (MVVM skeleton + XPC Service + environment validation)

**Happy coding! 🦀**
