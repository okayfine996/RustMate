# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RustMate is a macOS SwiftUI application that provides visual management for Rust toolchains via rustup. The app is designed to run within macOS App Sandbox with plans for eventual App Store distribution.

**Key Design Constraints:**
- Must operate within App Sandbox (App Store requirement)
- Uses XPC Service for process isolation and execution layer decoupling
- Focuses on structured results rather than log streaming
- Requires Security-Scoped Bookmarks for file system access

**Core Capabilities:**
- Toolchain management (install/uninstall/update stable/beta/nightly)
- Component management (rustfmt, clippy, rust-src, etc.)
- Target platform management (wasm32, aarch64, etc.)
- Project context view (shows active toolchain and override source)

## Build & Development Commands

**Build and Run:**
```bash
xcodebuild -scheme RustMate -configuration Debug
```

**Run Tests:**
```bash
# Unit tests
xcodebuild test -scheme RustMate -destination 'platform=macOS'

# Specific test
xcodebuild test -scheme RustMate -destination 'platform=macOS' -only-testing:RustMateTests/TestClassName/testMethodName
```

**Open in Xcode:**
```bash
open RustMate.xcodeproj
```

## Architecture

### Layered Structure (MVVM + Service + XPC)

1. **SwiftUI Views** - UI presentation and user interaction
2. **ViewModels (@MainActor)** - Observable state management for toolchains/components/targets/projects/tasks
3. **Domain Models** - Pure data structures: `Toolchain`, `Component`, `Target`, `ProjectContext`, `TaskRecord`
4. **Service Layer (Protocol-based)** - `RustToolchainServiceProtocol`, `ProjectContextServiceProtocol`
5. **Execution Layer (XPC Service)** - Runs rustup/cargo commands, parses output, returns structured results

### XPC Communication Pattern

The execution layer runs in a separate XPC Service process (`RustMateXPC.xpc`) for:
- Process isolation (UI never blocks)
- Clear permission boundaries
- Testability and mockability
- Task serialization (rustup write operations must be serial)

**XPC Protocol Categories:**
- Environment validation (`ping`, `validateEnvironment`)
- Toolchain operations (`listToolchains`, `installToolchain`, `uninstallToolchain`, `setDefaultToolchain`, `updateAll`)
- Component operations (`listComponents`, `addComponent`, `removeComponent`)
- Target operations (`listTargets`, `addTarget`, `removeTarget`)
- Project context (`getProjectContext`, `setProjectOverride`, `clearProjectOverride`)

### Security-Scoped Bookmarks

Due to App Sandbox constraints:
- User must authorize access to `~/.cargo/bin` (for rustup/cargo executables)
- User must authorize project directories (for project context features)
- Bookmarks are persisted (likely in Keychain or encrypted UserDefaults)
- Access via `startAccessingSecurityScopedResource()` before use

### Serialization Strategy

The execution layer uses either:
- Swift Concurrency `actor RustupExecutor` (recommended), or
- Single serial `DispatchQueue`

This prevents rustup lock conflicts and state inconsistencies.

## Key Design Decisions

### No Log Streaming
- Tasks show status only: running/success/failed/cancelled
- Errors display truncated stderr snippets (max ~32KB)
- Focus on structured results, not terminal output

### Override Strategy (to be configured)
Two options for setting project toolchain overrides:
- **Option A:** Write `rust-toolchain.toml` (explicit, can commit to repo)
- **Option B:** Use `rustup override set/unset` (doesn't modify repo files)

Configuration should be selectable in Settings.

### Command Whitelist
XPC Service only accepts enumerated operations with validated parameters:
- Toolchain names: `[A-Za-z0-9._-]+` with length limits
- Target triples: Similar validation
- Project paths: Must be within authorized bookmark scope

No arbitrary command execution allowed.

## Important Implementation Patterns

### Dependency Injection
- All services use protocol abstractions (`*ServiceProtocol`)
- Real implementations use XPC (`XPC*Service`)
- Mock implementations for SwiftUI Previews and unit tests
- ViewModels depend only on protocols, never concrete XPC types

### Error Handling
Errors are categorized as:
- **User-actionable:** rustup not found, permission denied, network issues
  - Provide clear fix instructions
- **System/unknown:** Preserve `stderrSnippet`, offer "Copy Error" button

### Output Parsing (Resilient)
- Parse `rustup toolchain list` for `(default)` marker
- Parse `rustup show` for active toolchain and `overridden by` paths
- On parse failure: Return `unknown` reason + stdout snippet for UI fallback
- Maintain test sample library for rustup output variations

### State Refresh Strategy
Refresh toolchain/component/target state:
- On app launch
- On app return to foreground
- After any write operation completes
- (Future) File system monitoring of `~/.rustup/toolchains` if authorized

## Project Structure

```
RustMate/                    # Main app target (SwiftUI + ViewModels)
  RustMateApp.swift          # App entry point with SwiftData container
  ContentView.swift          # Main UI (currently template, to be replaced)
  Item.swift                 # SwiftData model (template, to be removed)
  Assets.xcassets/           # App icons and colors

RustMateTests/               # Unit tests
RustMateUITests/             # UI tests

DESIGN.md                    # Comprehensive Chinese design document
RESEARCH.md                  # Research notes (currently empty)

.specify/                    # Speckit templates for planning workflow
.claude/commands/            # Claude Code slash commands
.cursor/rules/               # Cursor IDE rules
```

## Development Workflow Milestones

The design document (`DESIGN.md`) outlines a phased approach:

**M0 - Architecture Foundation:**
- Establish MVVM skeleton
- Create XPC Service target
- Implement `ping/validateEnvironment`

**M1 - Toolchain MVP:**
- list/install/uninstall/setDefault/updateAll
- Task list UI (status + error summaries only)

**M2 - Components & Targets:**
- Component and target list/install/uninstall
- Polish failure messaging

**M3 - Project View:**
- Project bookmark management
- Active toolchain + override source explanation
- set/clear override operations

## Risks & Constraints

1. **App Store Sandbox:** User must authorize access to rustup executables and project directories via file picker. No automatic discovery.

2. **XPC Still Sandboxed:** XPC Service provides isolation and quality benefits but doesn't escape sandbox permissions.

3. **rustup Output Changes:** Output parsing requires ongoing maintenance. Always prepare fallback rendering for unrecognized formats.

## Reference Documents

- `DESIGN.md` - Full Chinese design specification (15KB, highly detailed)
- Project uses Speckit workflow for feature planning (`.specify/` templates)
- Bundle ID: `com.finefine.RustMate`

## Active Technologies
- Swift 5.9+ (Xcode 15+) + SwiftUI (macOS 13.0+), XPC (Foundation), Security framework (Security-Scoped Bookmarks) (001-rustup-visual-ui)
- UserDefaults for settings, Keychain for persistent Security-Scoped Bookmark data, in-memory state management via @Observable/@MainActor ViewModels (001-rustup-visual-ui)

## Recent Changes
- 001-rustup-visual-ui: Added Swift 5.9+ (Xcode 15+) + SwiftUI (macOS 13.0+), XPC (Foundation), Security framework (Security-Scoped Bookmarks)
