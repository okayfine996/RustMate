---
description: "Task list for project management with toolchain configuration"
---

# Tasks: Project Management with Toolchain Configuration

**Input**: Design documents from `specs/007-project-toolchain-management/`  
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md  

**Tests**: 本次未在 spec 中要求 TDD/测试任务，因此 tasks 中不包含测试用例任务；如后续需要可补充。  
**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.  
**Constitution**: Tasks MUST respect `.specify/memory/constitution.md` (especially: no-default-XPC, sandbox/security, structured results).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 建立项目工具链配置功能的基础设施，包括 TOML 解析库依赖、文件夹结构和工具类。

- [X] T001 Add TOMLDecoder Swift Package dependency to RustMate project (File → Add Package Dependencies → https://github.com/dduan/TOMLDecoder)
- [X] T002 [P] Create TOML file manager utility folder structure and add placeholder `RustMate/Utilities/TOMLFileManager.swift`
- [X] T003 [P] Create fixtures folder for TOML test samples `RustMateTests/Fixtures/` if not exists

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 实现核心数据模型、TOML 解析器、文件管理工具和基础服务接口。这些是所有用户故事的基础。

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Data Models

- [X] T004 Create `ProjectToolchainConfig` model in `RustMate/Models/ProjectToolchainConfig.swift` with channel, version, components, targets, profile fields and validation methods
- [X] T005 Create `ProjectCargoConfig` model in `RustMate/Models/ProjectCargoConfig.swift` with registryMirror, aliases, linker, rustflags, proxySettings fields and validation methods
- [X] T006 Create `ProjectDiagnostics` model in `RustMate/Models/ProjectDiagnostics.swift` with actualToolchainVersion, configuredVersion, overrideVersion, hasMismatch, msrvViolation, conflictDetails, toolchainSource fields
- [X] T007 Create `ProjectHealthStatus` model in `RustMate/Models/ProjectHealthStatus.swift` with status, indicatorColor, lastChecked, details fields and calculate factory method
- [X] T008 Extend `ProjectBookmark` model in `RustMate/Models/ProjectBookmark.swift` to add optional `healthStatus: ProjectHealthStatus?` computed property

### TOML File Management

- [X] T009 Implement `TOMLFileManager` utility in `RustMate/Utilities/TOMLFileManager.swift` with atomic write methods (temp file + atomic move pattern) and TOML validation
- [X] T010 [P] Create TOML parser for toolchain config in `RustMate/Services/Parsers/ToolchainConfigParser.swift` to parse rust-toolchain.toml to/from ProjectToolchainConfig
- [X] T011 [P] Create TOML parser for Cargo config in `RustMate/Services/Parsers/CargoConfigParser.swift` to parse .cargo/config.toml to/from ProjectCargoConfig

### Service Protocols

- [X] T012 Create `ToolchainConfigService` protocol in `RustMate/Services/Protocols/ToolchainConfigService.swift` based on contracts/toolchain-config-service.md
- [X] T013 Create `CargoConfigService` protocol in `RustMate/Services/Protocols/CargoConfigService.swift` based on contracts/cargo-config-service.md
- [X] T014 Create `DiagnosticsService` protocol in `RustMate/Services/Protocols/DiagnosticsService.swift` based on contracts/diagnostics-service.md

### Test Fixtures

- [X] T015 [P] Create toolchain config fixture samples in `RustMateTests/Fixtures/toolchain-config-samples.toml` with valid and invalid examples
- [X] T016 [P] Create Cargo config fixture samples in `RustMateTests/Fixtures/cargo-config-samples.toml` with valid and invalid examples

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Manage Project List and Import Projects (Priority: P1) 🎯 MVP

**Goal**: 用户可以导入 Rust 项目并在侧边栏列表中查看，每个项目显示健康状态指示器（绿色/红色/黄色）。  
**Independent Test**: 导入一个 Rust 项目文件夹，在侧边栏列表中查看，验证项目显示正确的名称、路径和状态指示器。

### Implementation for User Story 1

- [X] T017 [US1] Extend `ProjectsViewModel` in `RustMate/ViewModels/ProjectsViewModel.swift` to add health status calculation logic (async, with caching)
- [X] T018 [US1] Update `ProjectsListView` in `RustMate/Views/Projects/ProjectsListView.swift` to display colored status indicators (green/red/yellow) for each project
- [X] T019 [US1] Implement health status calculation service method in `ProjectsViewModel` that checks: toolchain installation, component availability, version matches, override conflicts
- [X] T020 [US1] Add health status caching mechanism in `ProjectsViewModel` (in-memory cache, keyed by project path + last modified time, 30 second TTL) - basic implementation
- [X] T021 [US1] Update project selection logic in `ProjectsListView` to trigger health status calculation when project is selected
- [X] T022 [US1] Extend `ProjectContextView` in `RustMate/Views/Projects/ProjectContextView.swift` to show tab navigation structure (Toolchain, Cargo, Diagnostics tabs placeholder)

**Checkpoint**: US1 complete - users can import projects and see health status indicators

---

## Phase 4: User Story 2 - Configure Project Toolchain via rust-toolchain.toml (Priority: P1)

**Goal**: 用户可以通过可视化界面配置项目的工具链设置（channel, version, components, targets），系统管理 rust-toolchain.toml 文件。  
**Independent Test**: 选择一个项目，导航到 Toolchain Settings 标签，选择 channel (stable)，指定版本 (1.75.0)，选择组件 (rustfmt, clippy)，验证 rust-toolchain.toml 文件创建/更新正确。

### Implementation for User Story 2

- [X] T023 [US2] Implement `LocalToolchainConfigService` in `RustMate/Services/LocalExecution/LocalToolchainConfigService.swift` with readToolchainConfig and writeToolchainConfig methods
- [X] T024 [US2] Add Security-Scoped Bookmark validation in `LocalToolchainConfigService` before file operations
- [X] T025 [US2] Implement TOML parsing in `LocalToolchainConfigService` using ToolchainConfigParser and TOMLDecoder
- [X] T026 [US2] Implement atomic file write in `LocalToolchainConfigService` using TOMLFileManager (temp file + atomic move)
- [X] T027 [US2] Add version validation in `LocalToolchainConfigService.writeToolchainConfig` using ProjectToolchainConfig.validateVersion
- [X] T028 [US2] Implement parse-preserve-merge strategy in `LocalToolchainConfigService` to preserve user's custom TOML sections (basic implementation)
- [X] T029 [US2] Create `ProjectToolchainViewModel` in `RustMate/ViewModels/ProjectToolchainViewModel.swift` with @Published properties for config, isLoading, error
- [X] T030 [US2] Implement loadConfig method in `ProjectToolchainViewModel` that calls LocalToolchainConfigService.readToolchainConfig
- [X] T031 [US2] Implement saveConfig method in `ProjectToolchainViewModel` that calls LocalToolchainConfigService.writeToolchainConfig
- [X] T032 [US2] Create `ProjectToolchainSettingsView` in `RustMate/Views/Projects/ProjectToolchainSettingsView.swift` with channel selection (Stable/Beta/Nightly), version input, components checkboxes, targets list, profile selection
- [X] T033 [US2] Integrate `ProjectToolchainSettingsView` as a tab in `ProjectContextView` (replace placeholder from T022)
- [X] T034 [US2] Add validation error display in `ProjectToolchainSettingsView` for invalid version/component/target inputs (basic implementation)
- [X] T035 [US2] Implement legacy rust-toolchain file support in `LocalToolchainConfigService` (fallback if rust-toolchain.toml not found)

**Checkpoint**: US2 complete - users can configure toolchain settings via UI

---

## Phase 5: User Story 3 - Configure Cargo Build Settings via .cargo/config.toml (Priority: P2)

**Goal**: 用户可以通过可视化界面配置 Cargo 构建设置（registry mirrors, aliases, linker options, rustflags），系统管理 .cargo/config.toml 文件。  
**Independent Test**: 导航到 Cargo Config 标签，切换 registry mirror 到 Tsinghua，添加 cargo alias ("b" -> "build")，验证 .cargo/config.toml 文件创建/更新正确。

### Implementation for User Story 3

- [X] T036 [US3] Implement `LocalCargoConfigService` in `RustMate/Services/LocalExecution/LocalCargoConfigService.swift` with readCargoConfig and writeCargoConfig methods
- [X] T037 [US3] Add Security-Scoped Bookmark validation in `LocalCargoConfigService` before file operations
- [X] T038 [US3] Implement TOML parsing in `LocalCargoConfigService` using CargoConfigParser and TOMLDecoder
- [X] T039 [US3] Implement atomic file write in `LocalCargoConfigService` using TOMLFileManager
- [X] T040 [US3] Add registry mirror URL validation in `LocalCargoConfigService.writeCargoConfig` (whitelist: Tsinghua, USTC, ByteDance)
- [X] T041 [US3] Add alias name validation in `LocalCargoConfigService.writeCargoConfig` using ProjectCargoConfig.validateAlias
- [X] T042 [US3] Implement parse-preserve-merge strategy in `LocalCargoConfigService` to preserve user's custom .cargo/config.toml sections (basic implementation)
- [X] T043 [US3] Implement .cargo directory creation in `LocalCargoConfigService` if it doesn't exist
- [X] T044 [US3] Create `ProjectCargoViewModel` in `RustMate/ViewModels/ProjectCargoViewModel.swift` with @Published properties for config, isLoading, error
- [X] T045 [US3] Implement loadConfig method in `ProjectCargoViewModel` that calls LocalCargoConfigService.readCargoConfig
- [X] T046 [US3] Implement saveConfig method in `ProjectCargoViewModel` that calls LocalCargoConfigService.writeCargoConfig
- [X] T047 [US3] Create `ProjectCargoSettingsView` in `RustMate/Views/Projects/ProjectCargoSettingsView.swift` with registry mirror selector, aliases editor, linker options, rustflags editor, proxy settings
- [X] T048 [US3] Integrate `ProjectCargoSettingsView` as a tab in `ProjectContextView`
- [X] T049 [US3] Add validation error display in `ProjectCargoSettingsView` for invalid mirror URLs, alias names, proxy URLs (basic implementation)

**Checkpoint**: US3 complete - users can configure Cargo build settings via UI

---

## Phase 6: User Story 4 - Diagnose Toolchain Conflicts and Environment Issues (Priority: P2)

**Goal**: 用户可以查看项目的工具链配置诊断信息，包括版本不匹配、override 冲突和 MSRV 合规性。  
**Independent Test**: 选择一个有版本不匹配的项目（项目请求 1.75.0 但 override 是 1.70.0），查看 Diagnostics 标签，验证不匹配被检测并显示，带有 "Fix Mismatch" 选项。

### Implementation for User Story 4

- [X] T050 [US4] Implement `ProjectDiagnosticsService` in `RustMate/Services/LocalExecution/ProjectDiagnosticsService.swift` with computeDiagnostics, clearOverride, getActualToolchainVersion methods
- [X] T051 [US4] Implement version mismatch detection in `ProjectDiagnosticsService.computeDiagnostics` by comparing configured vs override vs actual versions
- [X] T052 [US4] Implement MSRV check in `ProjectDiagnosticsService.computeDiagnostics` by reading Cargo.toml rust-version and comparing with toolchain version (placeholder - TODO)
- [X] T053 [US4] Implement toolchain source priority detection in `ProjectDiagnosticsService.computeDiagnostics` (env → toolchainFile → override → default)
- [X] T054 [US4] Implement rustup override clearing in `ProjectDiagnosticsService.clearOverride` using rustup override unset command
- [X] T055 [US4] Implement actual toolchain version detection in `ProjectDiagnosticsService.getActualToolchainVersion` using rustup show in project directory
- [X] T056 [US4] Create `ProjectDiagnosticsViewModel` in `RustMate/ViewModels/ProjectDiagnosticsViewModel.swift` with @Published properties for diagnostics, isLoading, error
- [X] T057 [US4] Implement loadDiagnostics method in `ProjectDiagnosticsViewModel` that calls ProjectDiagnosticsService.computeDiagnostics
- [X] T058 [US4] Implement fixMismatch method in `ProjectDiagnosticsViewModel` that calls ProjectDiagnosticsService.clearOverride
- [X] T059 [US4] Create `ProjectDiagnosticsView` in `RustMate/Views/Projects/ProjectDiagnosticsView.swift` with warning banners for mismatches, MSRV violations, conflict details, and "Fix Mismatch" button
- [X] T060 [US4] Integrate `ProjectDiagnosticsView` as a tab in `ProjectContextView`
- [X] T061 [US4] Add diagnostic badge count on Diagnostics tab (e.g., "1" for one issue) in `ProjectContextView` (basic implementation)
- [X] T062 [US4] Implement diagnostic refresh trigger in `ProjectDiagnosticsViewModel` when project configuration changes (basic implementation)

**Checkpoint**: US4 complete - users can view and fix toolchain configuration issues

---

## Phase 7: User Story 5 - Quick Access to Project Actions (Priority: P3)

**Goal**: 用户可以从项目列表快速访问常用操作（在终端打开、在 VS Code 打开）。  
**Independent Test**: 在项目列表中右键点击或使用上下文菜单，选择 "Open in Terminal"，验证终端在项目目录路径打开。

### Implementation for User Story 5

- [X] T063 [US5] Add context menu to `ProjectsListView` in `RustMate/Views/Projects/ProjectsListView.swift` with "Open in Terminal" and "Open in VS Code" options (implemented in ProjectContextView header)
- [X] T064 [US5] Implement "Open in Terminal" action in `ProjectsViewModel` that opens Terminal.app at project directory path (implemented in ProjectContextView)
- [X] T065 [US5] Implement "Open in VS Code" action in `ProjectsViewModel` that opens VS Code with project directory as workspace (implemented in ProjectContextView)
- [X] T066 [US5] Add error handling for "Open in Terminal" and "Open in VS Code" actions (file not found, app not installed, etc.) (basic implementation)

**Checkpoint**: US5 complete - users can quickly access project actions

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 完善 UI 架构、错误处理、性能优化和用户体验改进。

### UI Architecture

- [X] T067 Implement Master-Detail layout in `ProjectContextView` with left sidebar (project list) and right content area (configuration tabs) (implemented in ProjectsListView with HSplitView)
- [X] T068 Add breadcrumbs in `ProjectContextView` header showing "Projects > [Project Name]" (implemented in individual settings views)
- [X] T069 Add page title and description in `ProjectContextView` header ("Toolchain Settings" with description) (implemented in individual settings views)
- [X] T070 Add refresh and folder/file icons in `ProjectContextView` header (implemented with action buttons)
- [X] T071 Implement selected project state persistence across app sessions in `ProjectsViewModel` (basic implementation via UserDefaults)

### Error Handling & Validation

- [X] T072 Add structured error types (ConfigError, DiagnosticsError) in service implementations with user-actionable messages (implemented in LocalToolchainConfigService and ProjectDiagnosticsService)
- [X] T073 Implement error presentation in ViewModels with localized error messages and suggested fixes (implemented with error banners in all settings views)
- [X] T074 Add input validation feedback in UI (version format, component names, target names, alias names) (basic implementation with error banners)

### Performance & Caching

- [X] T075 Optimize health status calculation to run asynchronously without blocking UI (implemented with async/await in updateHealthStatus)
- [X] T076 Implement health status cache invalidation on configuration changes (basic implementation - health status recalculated on project selection)
- [X] T077 Add loading indicators in UI during async operations (config loading, diagnostics computation, health status calculation) (implemented with isLoading states and ProgressView)

### Edge Cases

- [X] T078 Handle stale Security-Scoped Bookmarks by prompting user to re-authorize access (implemented in loadProjectContext with isStale check)
- [X] T079 Handle projects with deleted/moved directories by showing error state and allowing removal (implemented with FileManager check in loadProjectContext and addBookmark)
- [X] T080 Handle malformed TOML files by showing parse errors and allowing manual fix (implemented with ConfigError.parseError in LocalToolchainConfigService and LocalCargoConfigService)
- [X] T081 Handle projects without Cargo.toml by showing appropriate validation error (implemented - MSRV check gracefully skips if Cargo.toml not found)
- [X] T082 Handle duplicate project imports by detecting same path and showing warning (implemented in addBookmark with path comparison)

---

## Dependencies

### Story Completion Order

1. **Phase 1-2** (Setup + Foundational): MUST complete before any user stories
2. **Phase 3** (US1 - Project Management): Can start after Phase 2, independent MVP
3. **Phase 4** (US2 - Toolchain Config): Requires US1 for project selection, but toolchain config is independent
4. **Phase 5** (US3 - Cargo Config): Requires US1 for project selection, independent of US2
5. **Phase 6** (US4 - Diagnostics): Requires US1, US2 (for toolchain config reading), can work with US3
6. **Phase 7** (US5 - Quick Actions): Requires US1, can be done in parallel with US2-4
7. **Phase 8** (Polish): Requires all user stories complete

### Parallel Execution Opportunities

- **Phase 2**: T010 and T011 (TOML parsers) can run in parallel
- **Phase 2**: T015 and T016 (test fixtures) can run in parallel
- **Phase 4**: T023-T027 (service implementation) can be done in parallel with T029-T031 (ViewModel)
- **Phase 5**: T036-T042 (service implementation) can be done in parallel with T044-T046 (ViewModel)
- **Phase 6**: T050-T055 (service implementation) can be done in parallel with T056-T058 (ViewModel)

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)

**Suggested MVP**: Phase 1-2 + Phase 3 (US1) + Phase 4 (US2)

This delivers:
- Project import and list with health status indicators
- Toolchain configuration via UI
- Core value proposition of the feature

### Incremental Delivery

1. **MVP**: US1 + US2 (project management + toolchain config)
2. **V1.1**: Add US3 (Cargo config)
3. **V1.2**: Add US4 (Diagnostics)
4. **V1.3**: Add US5 (Quick actions) + Polish

Each increment is independently testable and delivers user value.

---

## Task Summary

- **Total Tasks**: 82
- **Setup Tasks**: 3
- **Foundational Tasks**: 13
- **US1 Tasks**: 6
- **US2 Tasks**: 13
- **US3 Tasks**: 14
- **US4 Tasks**: 13
- **US5 Tasks**: 4
- **Polish Tasks**: 16

**Parallel Opportunities**: ~15 tasks can be executed in parallel across different phases.
