# RustMate Development Context for Agents

This document defines the build system, code style, and development workflows for the RustMate project. All agents must follow these guidelines.

## 1. Build & Test Commands

Use `xcodebuild` for all build and test operations.

### Build
```bash
# Build Debug configuration
xcodebuild -scheme RustMate -configuration Debug

# Build Release configuration
xcodebuild -scheme RustMate -configuration Release
```

### Test
```bash
# Run all unit tests
xcodebuild test -scheme RustMate -destination 'platform=macOS'

# Run a specific test case (ESSENTIAL for TDD)
# Format: TestTarget/TestClass/testMethod
xcodebuild test -scheme RustMate -destination 'platform=macOS' -only-testing:RustMateTests/TestClassName/testMethodName
```

### Local Sparkle Update Testing
```bash
# Start local update server
./start-test-server.sh
```
*Note: To test updates in Xcode, set the Environment Variable `SPARKLE_TEST_MODE=1` in the Scheme.*

## 2. Code Style & Conventions

### General Formatting
- **Indentation**: 4 spaces.
- **Line Length**: Soft limit 100-120 characters.
- **Imports**: Group system imports (`SwiftUI`, `Combine`, `Foundation`) first, then local modules.
- **Design Tokens**: Use `GlassTokens` for UI consistency (Colors, Spacing, Typography).
  - Example: `GlassTokens.Spacing.md`, `Color.glassBackground`.

### Naming
- **Types (Structs, Classes, Enums, Protocols)**: PascalCase (e.g., `ToolchainViewModel`, `RustupService`).
- **Properties & Functions**: camelCase (e.g., `fetchToolchains()`, `isInstalled`).
- **Files**: Match the primary type name (e.g., `ToolchainViewModel.swift`).
- **Test Methods**: `testFeature_Scenario()` (e.g., `testLoadToolchains_Success`).

### Architecture (MVVM + XPC)
- **Views**: SwiftUI Views. Passive. Delegate logic to ViewModels. Use `@ViewBuilder` for composition.
- **ViewModels**: `@MainActor` classes conforming to `ObservableObject`. Expose `@Published` properties.
- **Services**: Define capabilities via **Protocols** (e.g., `RustToolchainServiceProtocol`).
  - **Dependency Injection**: ViewModels depend on Protocols, not concrete classes.
- **XPC Layer**: Heavy lifting (rustup execution) runs in a separate XPC process for isolation.
  - **Sandbox**: Must handle Security-Scoped Bookmarks for file access (e.g., `~/.cargo/bin`).

### Concurrency & Error Handling
- **Concurrency**: Prefer `async/await` over callbacks or Combine for asynchronous tasks.
- **Main Thread**: UI updates MUST happen on the Main Actor (`@MainActor` or `DispatchQueue.main`).
- **Errors**:
  - Use enum-based error types conforming to `LocalizedError`.
  - Include `userFacingMessage` and `suggestedFix` properties.
  - Handle errors at the ViewModel level to update UI state (e.g., `errorMessage` property).

## 3. Critical Implementation Rules

### ⚠️ App Sandbox & XPC
- **Permissions**: The App is sandboxed. Access to directories (like `~/.cargo`) requires User Selected File permissions and Security-Scoped Bookmarks.
- **Bookmarks**: Persist bookmarks in Keychain. Pass them to XPC service explicitly. Resolve/Start Access before use, Stop Access after.

### ⚠️ Frontend Changes
- **Visuals**: For pure UI/UX changes (colors, layout, animations), delegate to the `frontend-ui-ux-engineer` agent.
- **Logic**: For state/logic changes in Views, you may proceed directly.
- **Glass UI**: Respect the "Glass" design language. Use `GlassCard`, `GlassButton`, etc.

### ⚠️ Common Pitfalls (from Code Review)
- **Blocking**: Do not block actor execution with synchronous file I/O or process waiting.
- **Paths**: `rustup` might not be in the default PATH. Use absolute paths resolved via `env` or user selection.
- **Updates**: Use `SPARKLE_TEST_MODE` for safe local testing of auto-updates.

## 4. Environment
- **Platform**: macOS 13.0+
- **Language**: Swift 5.9+
- **Frameworks**: SwiftUI, AppKit, Combine, XPC.

## 5. Reference: Cursor Rules (from .cursor/rules/specify-rules.mdc)

> **Note**: The following rules are auto-generated from feature plans.

**Active Technologies**:
- Swift 5.9+ (Xcode 15+) + SwiftUI (macOS), Foundation, Observation/@MainActor.
- Keychain (Bookmark Data) + UserDefaults (Settings).
- Sparkle 2 (Auto Update).
- XPC Service (Foundation, NSXPCConnection).

**Project Structure**:
- `src/` (Note: Actual project uses Xcode structure `RustMate/`, `RustMateXPC/`)
- `tests/` (Actual: `RustMateTests/`, `RustMateUITests/`)

**Recent Changes**:
- 005-sparkle-auto-update: Added Sparkle 2 support.
- 004-glass-ui-refresh: Refreshed UI with Glass design system.
- 003-menu-bar-toolchain: Added Menu Bar Extra support.
