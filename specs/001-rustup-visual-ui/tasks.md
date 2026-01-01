# Tasks: RustMate Visual Interface for Rustup Operations

**Input**: Design documents from `/specs/001-rustup-visual-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/XPC-Protocol.md

**Tests**: Test tasks are included per XCTest framework requirement from plan.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story (6 user stories + foundational work).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Per plan.md, this is a multi-target Xcode project:
- **RustMate/**: Main app target (UI layer)
- **RustMateXPC/**: XPC Service target (execution layer)
- **Shared/**: Shared models (Codable structs)
- **RustMateTests/**: Unit and integration tests
- **RustMateUITests/**: UI tests

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and XPC service structure

- [x] T001 Create Xcode project with RustMate target (macOS App) at RustMate.xcodeproj
- [x] T002 Add XPC Service target RustMateXPC to project with bundle ID com.finefine.RustMate.XPC
- [x] T003 Add Shared folder target for Codable models accessible to both app and XPC service
- [x] T004 [P] Configure App Sandbox entitlements for RustMate target: com.apple.security.app-sandbox, com.apple.security.files.user-selected.read-write
- [x] T005 [P] Configure App Sandbox entitlements for RustMateXPC target (same as main app)
- [x] T006 [P] Add SwiftLint configuration at .swiftlint.yml for code quality
- [x] T007 Create directory structure: RustMate/{Models,Services,ViewModels,Views,Utilities}
- [x] T008 [P] Create directory structure: RustMateXPC/{Executor,Parsers}
- [x] T009 [P] Create directory structure: RustMateTests/{ServiceTests,ParserTests,ViewModelTests,Fixtures}
- [x] T010 [P] Add Assets.xcassets to RustMate target with app icon placeholder

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core XPC infrastructure, shared models, and utilities that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Shared Models (Required by XPC Protocol)

- [x] T011 [P] Create ToolchainInfo model in Shared/Models/ToolchainInfo.swift with Codable, Identifiable, Sendable conformance
- [x] T012 [P] Create ComponentInfo model in Shared/Models/ComponentInfo.swift with Codable, Identifiable, Sendable conformance
- [x] T013 [P] Create TargetInfo model in Shared/Models/TargetInfo.swift with Codable, Identifiable, Sendable conformance
- [x] T014 [P] Create ProjectContextInfo model in Shared/Models/ProjectContextInfo.swift with ToolchainReason enum
- [x] T015 [P] Create TaskResult model in Shared/Models/TaskResult.swift with TaskStatus enum and suggestFix() method
- [x] T016 [P] Create AuthorizedDirectory model in RustMate/Models/AuthorizedDirectory.swift with DirectoryPurpose enum
- [x] T017 [P] Create AppSettings model in RustMate/Models/AppSettings.swift with OverrideStrategy enum

### XPC Protocol Definition

- [x] T018 Create RustMateXPCProtocol in RustMateXPC/RustMateXPCProtocol.swift with @objc protocol and all 20+ methods from contracts/XPC-Protocol.md
- [x] T019 Add protocol to RustMate target via bridging header or direct import for XPC client usage

### XPC Service Core Infrastructure

- [x] T020 Implement RustMateXPCService in RustMateXPC/RustMateXPCService.swift with NSXPCListener delegate
- [x] T021 Add connection validation in RustMateXPCService.listener(_:shouldAcceptNewConnection:) with code signature check
- [x] T022 Implement RustupExecutor actor in RustMateXPC/Executor/RustupExecutor.swift with serial execution queue
- [x] T023 Implement ProcessRunner in RustMateXPC/Executor/ProcessRunner.swift with Process + Pipe for stdout/stderr capture
- [x] T024 [P] Implement CommandValidator in RustMateXPC/Executor/CommandValidator.swift with regex validation for toolchain/target names
- [x] T025 Create XPC Service main.swift entry point in RustMateXPC/main.swift with NSXPCListener.service().run()

### Utilities & Managers

- [x] T026 Implement BookmarkManager in RustMate/Utilities/BookmarkManager.swift with createBookmark(), resolveBookmark(), Keychain persistence
- [x] T027 [P] Implement EnvironmentValidator in RustMate/Utilities/EnvironmentValidator.swift with rustup detection and version check

### Service Protocol Layer

- [x] T028 [P] Define RustToolchainServiceProtocol in RustMate/Services/Protocols/RustToolchainServiceProtocol.swift with async methods
- [x] T029 [P] Define ProjectContextServiceProtocol in RustMate/Services/Protocols/ProjectContextServiceProtocol.swift with async methods
- [x] T030 [P] Define BookmarkServiceProtocol in RustMate/Services/Protocols/BookmarkServiceProtocol.swift
- [x] T031 Implement XPCClient in RustMate/Services/XPC/XPCClient.swift with NSXPCConnection management and error handling
- [x] T032 Implement XPCToolchainService in RustMate/Services/XPC/XPCToolchainService.swift conforming to RustToolchainServiceProtocol
- [x] T033 [P] Implement XPCProjectContextService in RustMate/Services/XPC/XPCProjectContextService.swift conforming to ProjectContextServiceProtocol

### Mock Services (for Previews and Tests)

- [x] T034 [P] Implement MockToolchainService in RustMate/Services/Mock/MockToolchainService.swift with hardcoded test data
- [x] T035 [P] Implement MockProjectContextService in RustMate/Services/Mock/MockProjectContextService.swift with hardcoded test data
- [x] T036 [P] Implement MockBookmarkService in RustMate/Services/Mock/MockBookmarkService.swift with in-memory bookmark storage

### Base UI Components

- [x] T037 [P] Create ErrorView in RustMate/Views/Shared/ErrorView.swift for displaying user-actionable errors
- [x] T038 [P] Create LoadingView in RustMate/Views/Shared/LoadingView.swift with ProgressView wrapper

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 6 - Initial Setup and Environment Validation (Priority: P1) 🎯 MVP Foundation

**Goal**: Validate rustup installation and guide user through Security-Scoped Bookmark authorization

**Independent Test**: Launch app without rustup installed, verify error message with installation instructions. Then install rustup, relaunch, and authorize ~/.cargo/bin directory successfully.

### Tests for User Story 6

- [ ] T039 [P] [US6] Unit test for EnvironmentValidator in RustMateTests/ServiceTests/EnvironmentValidatorTests.swift covering rustup found/not found scenarios
- [ ] T040 [P] [US6] Unit test for BookmarkManager in RustMateTests/ServiceTests/BookmarkManagerTests.swift with mock Keychain
- [ ] T041 [US6] Integration test for XPC validateEnvironment in RustMateTests/ServiceTests/XPCIntegrationTests.swift (requires real rustup)

### Implementation for User Story 6

- [x] T042 [P] [US6] Implement XPC validateEnvironment() method in RustMateXPCService with rustup existence check and version parsing
- [x] T043 [P] [US6] Create ValidationResult model in Shared/Models/ValidationResult.swift with hasRustup, rustupPath, version, hints fields
- [x] T044 [US6] Implement SettingsViewModel in RustMate/ViewModels/SettingsViewModel.swift with @Observable, bookmark authorization flow
- [x] T045 [US6] Create SettingsView in RustMate/Views/Settings/SettingsView.swift with NSOpenPanel for directory selection
- [x] T046 [US6] Add first-launch detection in RustMateApp.swift with UserDefaults flag and automatic Settings navigation
- [x] T047 [US6] Create SetupView in RustMate/Views/Settings/SetupView.swift displayed on first launch with rustup detection and authorization instructions
- [x] T048 [US6] Add error handling in SettingsViewModel for bookmark creation failures with user-actionable messages

**Checkpoint**: User can now complete first-time setup and authorize rustup access. This blocks all other user stories.

---

## Phase 4: User Story 1 - Manage Rust Toolchains (Priority: P1) 🎯 MVP Core

**Goal**: Display installed toolchains, install new toolchains (stable/beta/nightly), set default, update, and uninstall

**Independent Test**: After completing US6 setup, view toolchains list showing installed toolchains with default marked. Install "stable" toolchain, verify it appears in list. Set as default, verify indicator updates. Uninstall a non-default toolchain successfully.

### Parsers for User Story 1

- [x] T049 [P] [US1] Implement ToolchainParser in RustMateXPC/Parsers/ToolchainParser.swift parsing `rustup toolchain list` output with regex for (default) marker
- [ ] T050 [P] [US1] Create parser test fixtures in RustMateTests/Fixtures/toolchain-list-samples.txt with various rustup output formats
- [ ] T051 [US1] Unit test for ToolchainParser in RustMateTests/ParserTests/ToolchainParserTests.swift with fixture samples

### XPC Methods for User Story 1

- [x] T052 [US1] Implement listToolchains() in RustMateXPCService calling rustup toolchain list and ToolchainParser
- [x] T053 [P] [US1] Implement installToolchain(name:) in RustMateXPCService with validation and rustup toolchain install command
- [x] T054 [P] [US1] Implement uninstallToolchain(name:) in RustMateXPCService with default toolchain prevention check
- [x] T055 [P] [US1] Implement setDefaultToolchain(name:) in RustMateXPCService calling rustup default
- [x] T056 [P] [US1] Implement updateAllToolchains() in RustMateXPCService calling rustup update
- [x] T057 [P] [US1] Implement updateToolchain(name:) in RustMateXPCService calling rustup update with toolchain name

### ViewModel and Views for User Story 1

- [x] T058 [US1] Implement ToolchainsViewModel in RustMate/ViewModels/ToolchainsViewModel.swift with @Observable, @MainActor, listToolchains/installToolchain/etc. methods
- [x] T059 [US1] Create ToolchainsListView in RustMate/Views/Toolchains/ToolchainsListView.swift displaying toolchains with default indicator and action buttons
- [x] T060 [P] [US1] Create ToolchainDetailView in RustMate/Views/Toolchains/ToolchainDetailView.swift showing toolchain metadata and operations
- [x] T061 [P] [US1] Create InstallToolchainSheet in RustMate/Views/Toolchains/InstallToolchainSheet.swift with Picker for stable/beta/nightly or TextField for custom
- [x] T062 [US1] Add state refresh logic in ToolchainsViewModel triggered on app launch, foreground, and after write operations per FR-208/FR-209
- [x] T063 [US1] Add uninstall confirmation dialog in ToolchainsListView with warning if attempting to uninstall default toolchain per FR-205

### Tests for User Story 1

- [ ] T064 [P] [US1] Unit test for ToolchainsViewModel in RustMateTests/ViewModelTests/ToolchainsViewModelTests.swift using MockToolchainService
- [ ] T065 [US1] UI test for toolchain installation flow in RustMateUITests/RustMateUITests.swift (end-to-end with real XPC)

**Checkpoint**: User Story 1 fully functional - users can manage toolchains completely. This is the core MVP.

---

## Phase 5: User Story 5 - Monitor and Control Operations (Priority: P2)

**Goal**: Display task status (running/success/failed/cancelled) for all rustup operations with error summaries

**Independent Test**: Initiate a toolchain installation from US1, immediately switch to Tasks view, verify "running" status displayed. Wait for completion, verify "success" or "failed" status with appropriate error message if failed. Test cancel button during long operation.

### Implementation for User Story 5

- [x] T066 [US5] Implement TasksViewModel in RustMate/ViewModels/TasksViewModel.swift with @Observable, @Published tasks: [TaskRecord]
- [x] T067 [US5] Add task tracking in ToolchainsViewModel: create TaskRecord when operation starts, update on completion
- [x] T068 [US5] Implement cancelTask() method in XPCToolchainService and RustMateXPCService calling Process.terminate()
- [x] T069 [US5] Add task cancellation support in RustupExecutor actor tracking runningProcesses: [UUID: Process]
- [x] T070 [US5] Create TasksListView in RustMate/Views/Tasks/TasksListView.swift displaying tasks with status icons and colors
- [x] T071 [P] [US5] Create TaskDetailView in RustMate/Views/Tasks/TaskDetailView.swift showing full error message, stderr snippet, and suggested fix
- [x] T072 [US5] Add "Copy Error" button in TaskDetailView copying stderr snippet to clipboard per FR-606
- [x] T073 [P] [US5] Add suggested fix logic in TaskResult.suggestFix(for:) pattern matching common errors (network, permission, already installed, not found)

### Tests for User Story 5

- [ ] T074 [P] [US5] Unit test for TasksViewModel in RustMateTests/ViewModelTests/TasksViewModelTests.swift verifying task state transitions
- [ ] T075 [US5] Integration test for task cancellation in RustMateTests/ServiceTests/XPCIntegrationTests.swift

**Checkpoint**: User Story 5 complete - users can monitor operations and troubleshoot errors independently.

---

## Phase 6: User Story 2 - Manage Components for Toolchains (Priority: P2)

**Goal**: View and manage components (rustfmt, clippy, rust-src, llvm-tools-preview) for specific toolchains

**Independent Test**: Select an installed toolchain from US1, navigate to Components view, see list of available components with installation status. Install "clippy", verify marked as installed. Switch to different toolchain, verify components list is toolchain-specific.

### Parsers for User Story 2

- [x] T076 [P] [US2] Implement ComponentParser in RustMateXPC/Parsers/ComponentParser.swift parsing `rustup component list --toolchain <name>` output
- [ ] T077 [P] [US2] Create parser test fixtures in RustMateTests/Fixtures/component-list-samples.txt
- [ ] T078 [US2] Unit test for ComponentParser in RustMateTests/ParserTests/ComponentParserTests.swift

### XPC Methods for User Story 2

- [x] T079 [US2] Implement listComponents(toolchainName:) in RustMateXPCService calling rustup component list and ComponentParser
- [x] T080 [P] [US2] Implement addComponent(componentName:toolchainName:) in RustMateXPCService with validation and rustup component add
- [x] T081 [P] [US2] Implement removeComponent(componentName:toolchainName:) in RustMateXPCService calling rustup component remove

### ViewModel and Views for User Story 2

- [x] T082 [US2] Implement ComponentsViewModel in RustMate/ViewModels/ComponentsViewModel.swift with @Observable, selectedToolchain binding
- [x] T083 [US2] Create ComponentsListView in RustMate/Views/Components/ComponentsListView.swift showing components for selected toolchain with install/uninstall buttons
- [x] T084 [US2] Add task tracking integration between ComponentsViewModel and TasksViewModel for component operations
- [x] T085 [US2] Add common components suggestion UI (rustfmt, clippy, rust-src, llvm-tools-preview) per ComponentInfo.commonComponents

### Tests for User Story 2

- [ ] T086 [P] [US2] Unit test for ComponentsViewModel in RustMateTests/ViewModelTests/ComponentsViewModelTests.swift with MockToolchainService
- [ ] T087 [US2] Integration test for component installation in RustMateTests/ServiceTests/XPCIntegrationTests.swift

**Checkpoint**: User Story 2 complete - users can manage components independently. Works alongside US1.

---

## Phase 7: User Story 4 - Understand Project Toolchain Context (Priority: P2)

**Goal**: Display active toolchain for a project directory and explain why (toolchain file, override, or default)

**Independent Test**: Select a project directory via file picker, authorize access, view active toolchain name and reason. Create a rust-toolchain.toml file in project with "nightly" content, refresh, verify reason changes to "Toolchain File". Clear override, verify reason becomes "Default".

### Parsers for User Story 4

- [x] T088 [P] [US4] Implement ShowParser in RustMateXPC/Parsers/ShowParser.swift parsing `rustup show` output to extract active toolchain and "overridden by" paths
- [x] T089 [P] [US4] Create parser test fixtures in RustMateTests/Fixtures/show-output-samples.txt with various override scenarios
- [ ] T090 [US4] Unit test for ShowParser in RustMateTests/ParserTests/ShowParserTests.swift

### XPC Methods for User Story 4

- [x] T091 [US4] Implement getProjectContext(projectPath:) in RustMateXPCService running rustup show in project directory and parsing with ShowParser
- [x] T092 [P] [US4] Implement setProjectOverride(projectPath:toolchainName:mode:) in RustMateXPCService with mode="toolchainFile" writing rust-toolchain.toml or mode="rustupOverride" calling rustup override set
- [x] T093 [P] [US4] Implement clearProjectOverride(projectPath:mode:) in RustMateXPCService deleting rust-toolchain.toml or calling rustup override unset

### ViewModel and Views for User Story 4

- [x] T094 [US4] Implement ProjectsViewModel in RustMate/ViewModels/ProjectsViewModel.swift with @Observable, recentProjects: [ProjectContextInfo], bookmark management
- [x] T095 [US4] Create ProjectsListView in RustMate/Views/Projects/ProjectsListView.swift showing recent projects with "Add Project" button using NSOpenPanel
- [x] T096 [P] [US4] Create ProjectContextView in RustMate/Views/Projects/ProjectContextView.swift displaying active toolchain, reason with color coding, source path, and override controls
- [x] T097 [US4] Add project bookmark persistence in ProjectsViewModel using BookmarkManager and recent projects list in UserDefaults
- [x] T098 [US4] Add override strategy selection in SettingsView binding to AppSettings.overrideStrategy per FR-703
- [x] T099 [US4] Implement setProjectOverride() in ProjectsViewModel checking AppSettings.overrideStrategy and calling appropriate XPC method

### Tests for User Story 4

- [ ] T100 [P] [US4] Unit test for ProjectsViewModel in RustMateTests/ViewModelTests/ProjectsViewModelTests.swift with MockProjectContextService
- [ ] T101 [US4] Integration test for project context detection in RustMateTests/ServiceTests/XPCIntegrationTests.swift with temporary project directory

**Checkpoint**: User Story 4 complete - users can understand and manage project-specific toolchain configuration.

---

## Phase 8: User Story 3 - Manage Target Platforms (Priority: P3)

**Goal**: View and manage compilation targets (wasm32, aarch64, etc.) for specific toolchains

**Independent Test**: Select an installed toolchain from US1, navigate to Targets view, see list of available targets with installation status. Install "wasm32-unknown-unknown", verify marked as installed. Switch toolchains, verify targets list is toolchain-specific.

### Parsers for User Story 3

- [x] T102 [P] [US3] Implement TargetParser in RustMateXPC/Parsers/TargetParser.swift parsing `rustup target list --toolchain <name>` output
- [x] T103 [P] [US3] Create parser test fixtures in RustMateTests/Fixtures/target-list-samples.txt
- [ ] T104 [US3] Unit test for TargetParser in RustMateTests/ParserTests/TargetParserTests.swift

### XPC Methods for User Story 3

- [x] T105 [US3] Implement listTargets(toolchainName:) in RustMateXPCService calling rustup target list and TargetParser
- [x] T106 [P] [US3] Implement addTarget(targetTriple:toolchainName:) in RustMateXPCService with validation and rustup target add
- [x] T107 [P] [US3] Implement removeTarget(targetTriple:toolchainName:) in RustMateXPCService calling rustup target remove

### ViewModel and Views for User Story 3

- [x] T108 [US3] Implement TargetsViewModel in RustMate/ViewModels/TargetsViewModel.swift with @Observable, selectedToolchain binding
- [x] T109 [US3] Create TargetsListView in RustMate/Views/Targets/TargetsListView.swift showing targets for selected toolchain with install/uninstall buttons
- [x] T110 [US3] Add task tracking integration between TargetsViewModel and TasksViewModel for target operations
- [x] T111 [US3] Add common targets suggestion UI per TargetInfo.commonTargets (wasm32-unknown-unknown, aarch64-apple-darwin, etc.)

### Tests for User Story 3

- [ ] T112 [P] [US3] Unit test for TargetsViewModel in RustMateTests/ViewModelTests/TargetsViewModelTests.swift with MockToolchainService
- [ ] T113 [US3] Integration test for target installation in RustMateTests/ServiceTests/XPCIntegrationTests.swift

**Checkpoint**: User Story 3 complete - users can manage compilation targets independently. All core features now functional.

---

## Phase 9: Main App Integration & Navigation

**Purpose**: Wire all user stories together into cohesive app with navigation

- [x] T114 Create ContentView in RustMate/ContentView.swift with NavigationSplitView: sidebar (Toolchains, Components, Targets, Projects, Tasks, Settings), detail pane
- [x] T115 Update RustMateApp.swift entry point with ContentView as root, @State for selected sidebar item, environment object for shared ViewModels
- [x] T116 Add app lifecycle hooks in RustMateApp: .onAppear calling environment validation (US6), .onReceive(NotificationCenter.publisher(for: NSApplication.didBecomeActiveNotification)) triggering state refresh (FR-209)
- [x] T117 Implement dependency injection in RustMateApp creating real services (XPCToolchainService, XPCProjectContextService) or mock services based on preprocessor flag
- [x] T118 Add SwiftUI Previews for all views using MockToolchainService and MockProjectContextService
- [x] T119 Test navigation between all views ensuring state preservation and proper ViewModel lifecycle

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Improvements, error handling polish, and documentation

- [ ] T120 [P] Add comprehensive error messages in EnvironmentValidator.validateEnvironment() covering all common failure scenarios (rustup not found, wrong version, permission denied)
- [ ] T121 [P] Implement logging framework using os.Logger in all ViewModels and XPC Service for debugging
- [ ] T122 Add retry logic in XPCClient for transient XPC connection failures with exponential backoff
- [ ] T123 [P] Add loading states with skeleton views in all list views (ToolchainsListView, ComponentsListView, TargetsListView, ProjectsListView)
- [ ] T124 [P] Polish SettingsView with sections: Rustup Configuration, Override Strategy, Authorized Directories (with revoke buttons per FR-705)
- [ ] T125 Add app icon and branding in Assets.xcassets with multiple resolutions for macOS
- [ ] T126 [P] Create README.md in repository root with project overview, build instructions, and links to DESIGN.md and specs/
- [ ] T127 [P] Add inline documentation comments (///) to all public APIs in service protocols and models
- [ ] T128 Run swiftlint and fix all warnings ensuring code quality standards
- [ ] T129 Validate quickstart.md instructions by following setup steps on clean machine
- [ ] T130 Create sample rust-toolchain.toml files in project for testing US4 with different toolchain specifications
- [ ] T131 [P] Add keyboard shortcuts for common operations: Cmd+R refresh, Cmd+N new toolchain, Cmd+, settings
- [ ] T132 Implement accessibility labels and hints on all interactive UI elements for VoiceOver support
- [ ] T133 Add Dark Mode support verification ensuring all colors adapt correctly in Views
- [ ] T134 Performance profiling with Instruments: check XPC message overhead <10ms per research.md targets
- [ ] T135 Security audit: verify all command parameters validated per FR-803/FR-804, bookmark scope checked per FR-805
- [ ] T136 Create release build configuration with code signing for Developer ID Application distribution
- [ ] T137 Test App Sandbox compliance with asctl sandbox check --bundle RustMate.app per quickstart.md checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 6 (Phase 3)**: Depends on Foundational (Phase 2) - BLOCKS all other user stories (must authorize rustup access)
- **User Stories 1-5 (Phase 4-8)**: All depend on US6 completion for rustup access
  - US1 (Toolchains): Can proceed after US6
  - US5 (Tasks): Can proceed after US6, integrates with US1
  - US2 (Components): Can proceed after US6, requires toolchain from US1 but independently testable
  - US4 (Projects): Can proceed after US6, references toolchains from US1 but independently testable
  - US3 (Targets): Can proceed after US6, requires toolchain from US1 but independently testable
- **Main App Integration (Phase 9)**: Depends on US1 minimum (MVP), ideally all user stories
- **Polish (Phase 10)**: Depends on Phase 9 (full app functional)

### User Story Dependencies

- **US6 (Setup)**: BLOCKS all others - must complete first
- **US1 (Toolchains)**: No dependencies after US6
- **US5 (Tasks)**: No dependencies after US6, but best implemented after US1 for testing
- **US2 (Components)**: Requires toolchain selection from US1, but independently testable with any toolchain
- **US4 (Projects)**: References toolchains from US1, but independently testable with default toolchain
- **US3 (Targets)**: Requires toolchain selection from US1, but independently testable with any toolchain

### Within Each User Story

- **Parsers before XPC methods** (parsers have no dependencies)
- **XPC methods before ViewModels** (ViewModels call XPC services)
- **ViewModels before Views** (Views bind to ViewModels)
- **Tests after implementation** (except TDD approach)

### Parallel Opportunities

**Setup Phase (Phase 1)**:
- T003-T010: All marked [P] can run in parallel (different files)

**Foundational Phase (Phase 2)**:
- T011-T017: All models can run in parallel (independent files)
- T024, T027: Validators can run in parallel
- T028-T030: Service protocols can run in parallel
- T034-T036: Mock services can run in parallel
- T037-T038: Shared views can run in parallel

**User Story 6**:
- T039-T040: Tests can run in parallel
- T042-T043: XPC method and model can run in parallel

**User Story 1**:
- T049-T050: Parser and fixtures can run in parallel
- T053-T057: All XPC methods can run in parallel (different operations)
- T060-T061: Detail view and install sheet can run in parallel

**User Story 5**:
- T071, T073: Detail view and suggested fix logic can run in parallel

**User Story 2**:
- T076-T077: Parser and fixtures can run in parallel
- T080-T081: Add/remove XPC methods can run in parallel

**User Story 4**:
- T088-T089: Parser and fixtures can run in parallel
- T092-T093: Set/clear override methods can run in parallel

**User Story 3**:
- T102-T103: Parser and fixtures can run in parallel
- T106-T107: Add/remove target methods can run in parallel

**Polish Phase (Phase 10)**:
- T120, T121, T123, T124, T125, T126, T127, T131, T132: All marked [P] can run in parallel

---

## Parallel Example: User Story 1 (Toolchains)

```bash
# After foundational phase completes, launch User Story 1 tasks in parallel:

# Parsers (independent):
Task T049: "Implement ToolchainParser in RustMateXPC/Parsers/ToolchainParser.swift"
Task T050: "Create parser test fixtures in RustMateTests/Fixtures/toolchain-list-samples.txt"

# XPC methods (after parser completes, all independent):
Task T053: "Implement installToolchain() in RustMateXPCService"
Task T054: "Implement uninstallToolchain() in RustMateXPCService"
Task T055: "Implement setDefaultToolchain() in RustMateXPCService"
Task T056: "Implement updateAllToolchains() in RustMateXPCService"
Task T057: "Implement updateToolchain() in RustMateXPCService"

# Views (after ViewModel T058 completes, independent):
Task T060: "Create ToolchainDetailView in RustMate/Views/Toolchains/ToolchainDetailView.swift"
Task T061: "Create InstallToolchainSheet in RustMate/Views/Toolchains/InstallToolchainSheet.swift"
```

---

## Parallel Example: Multiple User Stories (After US6 Complete)

```bash
# With a team of 3 developers, after US6 authorization complete:

Developer A: Phase 4 (User Story 1 - Toolchains)
  - Critical path: T049→T052→T058→T059 (parser→list XPC→ViewModel→ListView)
  - Parallel: T053-T057 (install/uninstall/update XPC methods)
  - Parallel: T060-T061 (detail view, install sheet)

Developer B: Phase 5 (User Story 5 - Tasks)
  - Critical path: T066→T070 (ViewModel→ListView)
  - Parallel: T068-T069 (cancel XPC methods)
  - Parallel: T071, T073 (detail view, suggested fixes)

Developer C: Phase 6 (User Story 2 - Components)
  - Critical path: T076→T079→T082→T083 (parser→list XPC→ViewModel→ListView)
  - Parallel: T080-T081 (add/remove component XPC methods)
```

---

## Implementation Strategy

### MVP First (US6 + US1 Only - Minimal Viable Product)

1. ✅ Complete Phase 1: Setup (T001-T010)
2. ✅ Complete Phase 2: Foundational (T011-T038) - **CRITICAL BLOCKER**
3. ✅ Complete Phase 3: User Story 6 - Setup (T039-T048) - **AUTHORIZATION BLOCKER**
4. ✅ Complete Phase 4: User Story 1 - Toolchains (T049-T065)
5. ✅ Complete Phase 9: Main App Integration (T114-T119) - minimal navigation
6. **STOP and VALIDATE**: Test end-to-end toolchain management independently
7. Deploy/demo if ready - **USERS CAN NOW MANAGE TOOLCHAINS VISUALLY**

**MVP Scope**: 75 tasks (T001-T065 + T114-T119 subset)
**MVP Value**: Users can replace terminal commands for toolchain management

### Incremental Delivery (Add Features One by One)

1. **Foundation**: Phase 1 + Phase 2 + Phase 3 (US6) → Authorization working
2. **MVP**: Add Phase 4 (US1) → Toolchain management ✅ **SHIP**
3. **Iteration 2**: Add Phase 5 (US5) → Task monitoring ✅ **SHIP**
4. **Iteration 3**: Add Phase 6 (US2) → Component management ✅ **SHIP**
5. **Iteration 4**: Add Phase 7 (US4) → Project context ✅ **SHIP**
6. **Iteration 5**: Add Phase 8 (US3) → Target management ✅ **SHIP**
7. **Final**: Phase 9 (full integration) + Phase 10 (polish) ✅ **SHIP v1.0**

Each iteration adds value without breaking previous features.

### Parallel Team Strategy (3 Developers)

**Week 1: Foundation (All devs together)**
- Dev A: Phase 1 Setup + Shared Models (T001-T017)
- Dev B: XPC Infrastructure (T018-T025)
- Dev C: Utilities + Service Layer (T026-T033)
- All: Mock services and base UI (T034-T038)

**Week 2: Critical Path (US6 → US1)**
- Dev A: US6 Setup & Authorization (T039-T048)
- Dev B: US1 Parsers & XPC Methods (T049-T057)
- Dev C: US1 ViewModel & Views (T058-T063)
- **Milestone: MVP functional**

**Week 3: Parallel User Stories**
- Dev A: US5 Task Monitoring (T066-T075)
- Dev B: US2 Components (T076-T087)
- Dev C: US4 Projects (T088-T101)

**Week 4: Final Stories + Integration**
- Dev A: US3 Targets (T102-T113)
- Dev B: Main App Integration (T114-T119)
- Dev C: Polish (T120-T137 subset)

---

## Testing Strategy

### Unit Tests (Fast - Run Frequently)

**Parser Tests** (T051, T078, T090, T104):
- Use fixture samples from `RustMateTests/Fixtures/`
- Test regex patterns, edge cases, empty output, malformed output
- No XPC or rustup required

**ViewModel Tests** (T064, T074, T086, T100, T112):
- Use `MockToolchainService` and `MockProjectContextService`
- Test state transitions, error handling, task tracking
- No XPC or rustup required

**Validator Tests** (T039):
- Mock rustup executable presence
- Test regex validation for toolchain/target names

### Integration Tests (Slower - Run Before Commit)

**XPC Integration Tests** (T041, T075, T087, T101, T113):
- Connect to real XPC Service
- Require rustup installed on test machine
- Test end-to-end XPC communication, parsing, error handling
- May modify real rustup state (use test toolchains)

### UI Tests (Slowest - Run Before Release)

**End-to-End Tests** (T065):
- Test full user journeys through SwiftUI interface
- Require XPC Service running and rustup installed
- Test bookmark authorization flow (may require manual interaction)
- Verify all user stories independently

### Test Execution Order

1. **During development**: Run unit tests (parsers, ViewModels) continuously
2. **Before commit**: Run integration tests (XPC communication)
3. **Before PR**: Run UI tests (full end-to-end)
4. **Before release**: Run all tests + manual testing on clean macOS install

---

## Notes

- **[P] tasks** = different files, no dependencies, safe to parallelize
- **[Story] label** maps task to specific user story for traceability
- **Each user story should be independently completable and testable**
- **US6 is a hard blocker** - no other stories can function without rustup authorization
- **US1 is the MVP core** - toolchain management is the primary value proposition
- **Commit after each logical group** (e.g., after completing all XPC methods for a story)
- **Stop at any checkpoint** to validate story independently before proceeding
- **File paths are concrete** - no placeholders, ready for implementation
- **XPC architecture ensures** sandbox compliance and UI responsiveness per constitution

**Total Tasks**: 137 tasks
**MVP Tasks**: ~75 tasks (Setup + Foundational + US6 + US1 + basic integration)
**Parallelizable Tasks**: 60+ tasks marked [P]
**User Stories**: 6 (US6 setup, US1 toolchains, US5 tasks, US2 components, US4 projects, US3 targets)

**Suggested First Milestone**: T001-T065 + T114-T119 (MVP with toolchain management)
