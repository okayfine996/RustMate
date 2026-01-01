# Implementation Plan: RustMate Visual Interface for Rustup Operations

**Branch**: `001-rustup-visual-ui` | **Date**: 2025-12-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-rustup-visual-ui/spec.md`
**User Context**: Commands must be executed via XPC Service due to App Sandbox constraints

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

RustMate is a macOS SwiftUI application that provides visual management of Rust toolchains via rustup. The app operates within App Sandbox constraints and uses an XPC Service as an execution layer to run rustup commands, parse output, and return structured results. The primary technical challenge is bridging the sandboxed UI layer with rustup/cargo executables through Security-Scoped Bookmarks while maintaining serial execution to prevent rustup lock conflicts.

## Technical Context

**Language/Version**: Swift 5.9+ (Xcode 15+)
**Primary Dependencies**: SwiftUI (macOS 13.0+), XPC (Foundation), Security framework (Security-Scoped Bookmarks)
**Storage**: UserDefaults for settings, Keychain for persistent Security-Scoped Bookmark data, in-memory state management via @Observable/@MainActor ViewModels
**Testing**: XCTest for unit and integration tests, Mock service implementations for SwiftUI Previews
**Target Platform**: macOS 13.0+ (Ventura and later) - App Sandbox enabled, planned for App Store distribution
**Project Type**: macOS desktop application with XPC Service target (multi-target Xcode project)
**Performance Goals**: UI response time <100ms for state updates, toolchain list load <2 seconds, rustup command execution bounded by network/rustup (not app overhead)
**Constraints**:
- App Sandbox MUST be enabled (App Store requirement)
- NO direct file system access without Security-Scoped Bookmarks
- XPC Service MUST validate all commands against whitelist
- Rustup write operations MUST be serialized (Actor-based execution)
- UI MUST remain responsive during long-running operations (async/await, @MainActor isolation)
- Error messages MUST be actionable (structured error summaries, not raw stderr dumps)

**Scale/Scope**:
- 6 main views (Toolchains, Components, Targets, Projects, Tasks, Settings)
- 41 functional requirements across 8 domains
- ~15-20 SwiftUI view files, ~8-10 ViewModel classes, ~5-6 service protocol implementations
- XPC protocol with ~15-20 methods covering toolchain/component/target/project operations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Sandbox-First Design ✅

**Status**: PASS

- ✅ All features designed for App Sandbox (no escape mechanisms)
- ✅ XPC Service remains sandboxed (no system-wide helper daemons)
- ✅ Security-Scoped Bookmarks required for ~/.cargo/bin and project directories (FR-103, FR-104, FR-501)
- ✅ Command whitelist enforced in XPC layer (FR-803, FR-804)
- ✅ No arbitrary command execution (only enumerated rustup/cargo operations)

### Principle II: Protocol-Driven Architecture ✅

**Status**: PASS

- ✅ Service protocols defined: `RustToolchainServiceProtocol`, `ProjectContextServiceProtocol` (implied by spec FR requirements)
- ✅ ViewModels depend only on protocols (mentioned in DESIGN.md section 12)
- ✅ Mock implementations required for SwiftUI Previews and tests (FR-testability in DESIGN.md)
- ✅ Dependency injection pattern enabled by protocol abstraction

### Principle III: Structured Results Over Logs ✅

**Status**: PASS

- ✅ Typed result models: `ToolchainInfo`, `ComponentInfo`, `TargetInfo`, `ProjectContextInfo`, `TaskResult` (spec Key Entities)
- ✅ Task status only: running/success/failed/cancelled (FR-601)
- ✅ Error summaries with truncated stderr (max 32KB) (FR-603)
- ✅ NO terminal emulation or log streaming (explicit in spec Out of Scope section)
- ✅ Structured parsing with fallback to snippet on failure (resilience requirement)

### Principle IV: Security-Scoped Access ✅

**Status**: PASS

- ✅ User authorization for ~/.cargo/bin directory (FR-104)
- ✅ User authorization for each project directory (FR-501)
- ✅ Bookmark persistence in Keychain/secure storage (FR-105)
- ✅ startAccessingSecurityScopedResource() usage pattern (FR-106)
- ✅ Bookmark management UI in Settings (FR-704, FR-705)

### Principle V: Serial Execution ✅

**Status**: PASS

- ✅ Rustup write operations serialized (FR-605)
- ✅ Actor-based execution layer (mentioned in DESIGN.md section 8.2: "actor RustupExecutor")
- ✅ Prevents lock conflicts and state inconsistencies
- ✅ Read operations default to serial for simplicity (DESIGN.md)

### Security & Validation ✅

**Status**: PASS

- ✅ Command whitelist: rustup toolchain/component/target/show, rustc --version, cargo --version (FR-803)
- ✅ Toolchain/target name validation: regex `[A-Za-z0-9._-]+`, max 128 chars (FR-804)
- ✅ Project path validation: within authorized bookmark scope (FR-805)
- ✅ XPC connection validation: signature/TeamID/BundleID check (security design requirement)

### Testing & Quality ✅

**Status**: PASS

- ✅ Unit tests required for service implementations (XCTest framework)
- ✅ Integration tests for XPC communication and parsing
- ✅ Mock services for protocol implementations
- ✅ Output sample library for rustup parser tests (resilience requirement)

### Error Handling ✅

**Status**: PASS

- ✅ User-actionable errors: rustup not found (FR-102), permission denied (FR-104), network failure (FR-607)
- ✅ System/unknown errors: preserve stderr snippet (FR-603, FR-606)
- ✅ Clear next steps for actionable errors (FR-607)

### State Management ✅

**Status**: PASS

- ✅ Refresh on app launch (FR-101)
- ✅ Refresh on foreground activation (FR-209)
- ✅ Refresh after write operations (FR-208)
- ✅ Future: file system monitoring when authorized

### Phased Implementation ✅

**Status**: PASS

- ✅ M0: MVVM + XPC Service + environment validation (User Story 6)
- ✅ M1: Toolchain management + task UI (User Story 1, 5)
- ✅ M2: Component & target management (User Story 2, 3)
- ✅ M3: Project context + bookmarks (User Story 4)

**GATE RESULT**: ✅ **PASS** - All constitutional principles satisfied. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
RustMate/                           # Main app target (macOS)
├── RustMateApp.swift               # App entry point (@main)
├── Models/                         # Domain models (Codable structs)
│   ├── Toolchain.swift            # ToolchainInfo model
│   ├── Component.swift            # ComponentInfo model
│   ├── Target.swift               # TargetInfo model
│   ├── ProjectContext.swift       # ProjectContextInfo model
│   ├── TaskRecord.swift           # TaskResult model
│   └── AuthorizedDirectory.swift  # Bookmark wrapper
├── Services/                       # Service layer (protocol abstractions)
│   ├── Protocols/                 # Service protocol definitions
│   │   ├── RustToolchainServiceProtocol.swift
│   │   ├── ProjectContextServiceProtocol.swift
│   │   └── BookmarkServiceProtocol.swift
│   ├── XPC/                       # Real XPC-based implementations
│   │   ├── XPCToolchainService.swift
│   │   ├── XPCProjectContextService.swift
│   │   └── XPCClient.swift        # XPC connection manager
│   └── Mock/                      # Mock implementations for previews/tests
│       ├── MockToolchainService.swift
│       ├── MockProjectContextService.swift
│       └── MockBookmarkService.swift
├── ViewModels/                     # @Observable ViewModels (@MainActor)
│   ├── ToolchainsViewModel.swift
│   ├── ComponentsViewModel.swift
│   ├── TargetsViewModel.swift
│   ├── ProjectsViewModel.swift
│   ├── TasksViewModel.swift
│   └── SettingsViewModel.swift
├── Views/                          # SwiftUI views
│   ├── Toolchains/
│   │   ├── ToolchainsListView.swift
│   │   ├── ToolchainDetailView.swift
│   │   └── InstallToolchainSheet.swift
│   ├── Components/
│   │   └── ComponentsListView.swift
│   ├── Targets/
│   │   └── TargetsListView.swift
│   ├── Projects/
│   │   ├── ProjectsListView.swift
│   │   └── ProjectContextView.swift
│   ├── Tasks/
│   │   ├── TasksListView.swift
│   │   └── TaskDetailView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Shared/
│       ├── ErrorView.swift
│       └── LoadingView.swift
├── Utilities/                      # Helper utilities
│   ├── BookmarkManager.swift      # Security-Scoped Bookmark persistence
│   └── EnvironmentValidator.swift # Rustup detection
└── Assets.xcassets/

RustMateXPC/                        # XPC Service target
├── main.swift                      # XPC service entry point
├── RustMateXPCProtocol.swift      # Shared XPC protocol definition (@objc)
├── RustMateXPCService.swift       # NSXPCListener delegate
├── Executor/                       # Execution layer
│   ├── RustupExecutor.swift       # Actor-based serial executor
│   ├── ProcessRunner.swift        # Process wrapper (Pipe, output collection)
│   └── CommandValidator.swift     # Whitelist validation
├── Parsers/                        # Output parsers
│   ├── ToolchainParser.swift      # Parse `rustup toolchain list`
│   ├── ComponentParser.swift      # Parse `rustup component list`
│   ├── TargetParser.swift         # Parse `rustup target list`
│   └── ShowParser.swift           # Parse `rustup show` for project context
└── Info.plist                      # XPC service configuration

RustMateTests/                      # Unit tests
├── ServiceTests/
│   ├── XPCToolchainServiceTests.swift
│   └── MockServiceTests.swift
├── ParserTests/
│   ├── ToolchainParserTests.swift
│   ├── ComponentParserTests.swift
│   ├── TargetParserTests.swift
│   └── ShowParserTests.swift
│   └── Fixtures/                  # Sample rustup output for parser tests
│       ├── toolchain-list-samples.txt
│       ├── component-list-samples.txt
│       └── show-output-samples.txt
└── ViewModelTests/
    ├── ToolchainsViewModelTests.swift
    └── ProjectsViewModelTests.swift

RustMateUITests/                    # UI integration tests
└── RustMateUITests.swift

Shared/                             # Shared between app and XPC service
└── Models/                         # Codable models (for XPC transfer)
    ├── ToolchainInfo.swift
    ├── ComponentInfo.swift
    ├── TargetInfo.swift
    ├── ProjectContextInfo.swift
    └── TaskResult.swift
```

**Structure Decision**: Multi-target Xcode project with:
1. **RustMate** (main app): SwiftUI views, ViewModels, protocol abstractions, XPC client
2. **RustMateXPC** (XPC service): Serial executor, rustup command execution, output parsing
3. **Shared** folder: Codable models shared between app and XPC service (for IPC)
4. **Tests**: Unit tests for parsers, services, ViewModels; UI tests for end-to-end flows

This structure supports:
- Clear separation between UI and execution layers (sandbox boundary at XPC)
- Protocol-driven dependency injection (real vs mock services)
- Testability (parsers, services, ViewModels all independently testable)
- SwiftUI Preview support (mock services don't require XPC connection)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations detected.** All design decisions comply with the project constitution.

---

## Phase 0: Research Outcomes

✅ **Completed**: See [research.md](./research.md)

**Key Decisions**:
1. **XPC Architecture**: Embedded XPC Service with Actor-based executor
2. **File Access**: Security-Scoped Bookmarks for ~/.cargo/bin and project directories
3. **Serialization**: Swift Actor (RustupExecutor) for serial command execution
4. **Output Parsing**: Regex-based parsing with fallback to snippets
5. **Long Operations**: Async/await with status-only updates (no log streaming)
6. **Data Transfer**: Codable structs over XPC (JSON-encoded Data)

All decisions align with constitutional principles and App Store requirements.

---

## Phase 1: Design Artifacts

### Data Model

✅ **Completed**: See [data-model.md](./data-model.md)

**Core Entities**:
- `ToolchainInfo`: Installed Rust toolchains
- `ComponentInfo`: Rustup components (clippy, rustfmt, etc.)
- `TargetInfo`: Compilation targets
- `ProjectContextInfo`: Project directory + active toolchain
- `TaskRecord`: Operation execution status
- `AuthorizedDirectory`: Security-Scoped Bookmark wrapper
- `AppSettings`: User configuration

**Relationships**: Toolchain has-many Components/Targets, ProjectContext references Toolchain, all entities Codable for XPC transfer.

### API Contracts

✅ **Completed**: See [contracts/XPC-Protocol.md](./contracts/XPC-Protocol.md)

**XPC Protocol**: `RustMateXPCProtocol` with 20+ methods covering:
- Environment validation
- Toolchain operations (list, install, uninstall, set default, update)
- Component operations (list, add, remove)
- Target operations (list, add, remove)
- Project context (get, set override, clear override)
- Task management (cancel)

**Data Transfer**: All complex types transferred as JSON-encoded `Data` for type safety.

### Developer Onboarding

✅ **Completed**: See [quickstart.md](./quickstart.md)

**Contents**:
- Prerequisites and project setup
- Architecture quick reference
- Common development tasks (add ViewModel, XPC method, parser, tests)
- Testing strategy (unit, integration, UI tests)
- Debugging tips (XPC, bookmarks, parsing, actors)
- SwiftUI Previews setup
- Performance profiling guidance
- App Store preparation checklist

---

## Post-Design Constitution Check

*Re-validation after Phase 1 design completion*

### All Principles: ✅ PASS

No changes from initial check. All design artifacts (research, data-model, contracts, quickstart) maintain compliance with constitutional principles:

- **Sandbox-First**: Security-Scoped Bookmarks for all file access
- **Protocol-Driven**: Service protocols with real + mock implementations
- **Structured Results**: Typed models, no log streaming
- **Security-Scoped Access**: Bookmark-based authorization
- **Serial Execution**: Actor-based RustupExecutor
- **Command Whitelist**: Validation at XPC boundary
- **Testing**: Protocol abstraction enables comprehensive testing
- **Error Handling**: User-actionable vs system errors
- **State Management**: Refresh triggers defined
- **Phased Implementation**: M0-M3 milestones

**Final Result**: ✅ **READY FOR TASK GENERATION** (`/speckit.tasks`)

---

## Summary

**Planning Complete**: All Phase 0 and Phase 1 artifacts generated.

| Artifact | Status | Path |
|----------|--------|------|
| Technical Context | ✅ Complete | plan.md (this file) |
| Constitution Check | ✅ Pass | plan.md (this file) |
| Project Structure | ✅ Defined | plan.md (this file) |
| Research | ✅ Complete | [research.md](./research.md) |
| Data Model | ✅ Complete | [data-model.md](./data-model.md) |
| Contracts | ✅ Complete | [contracts/XPC-Protocol.md](./contracts/XPC-Protocol.md) |
| Quickstart | ✅ Complete | [quickstart.md](./quickstart.md) |
| Agent Context | ✅ Updated | CLAUDE.md (root) |

**Next Command**: `/speckit.tasks` - Generate implementation tasks.md from this plan
