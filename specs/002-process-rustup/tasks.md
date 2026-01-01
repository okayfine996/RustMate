---

description: "Task list for sandboxed in-app rustup execution (no XPC)"
---

# Tasks: Sandboxed Direct Rustup Execution

**Input**: Design documents from `specs/002-process-rustup/`  
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md  

**Tests**: 本次未在 spec 中要求 TDD/测试任务，因此 tasks 中不包含测试用例任务；如后续需要可补充。  
**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.  
**Constitution**: Tasks MUST respect `.specify/memory/constitution.md` (especially: no-default-XPC, sandbox/security, structured results).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 为“主进程直接执行 rustup + bookmark 授权”建立最小可迭代的代码骨架与开关。

- [X] T001 Create feature folder `specs/002-process-rustup/contracts/` and confirm docs present (plan/research/data-model/quickstart) in `specs/002-process-rustup/`
- [X] T002 [P] Add local execution folder `RustMate/Services/LocalExecution/` (group in Xcode) and add placeholder file `RustMate/Services/LocalExecution/README.md`
- [X] T003 [P] Add errors folder `RustMate/Services/LocalExecution/Errors/` and placeholder `RustMate/Services/LocalExecution/Errors/README.md`
- [X] T004 [P] Add parsers folder `RustMate/Services/Parsers/` (or `RustMate/Utilities/Parsers/`) and placeholder `RustMate/Services/Parsers/README.md`
- [X] T005 [P] Add authorization helper folder `RustMate/Utilities/Authorization/` and placeholder `RustMate/Utilities/Authorization/README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 把“授权范围”“本地执行层契约”“结构化错误/结果”变成可复用基础设施（所有 US 共享）。

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Define refined authorization purposes in `RustMate/Models/AuthorizedDirectory.swift` (add: rustupExecutableDir, cargoHome, rustupHome; keep backward compatibility for existing rustupAccess)
- [X] T007 Update `AuthorizedDirectory.DirectoryPurpose.displayText` in `RustMate/Models/AuthorizedDirectory.swift` to match the refined purposes (user-facing labels)
- [X] T008 Add migration helper for legacy `rustupAccess` entries in `RustMate/Models/AuthorizedDirectory.swift` (document mapping + fallback behavior)

- [X] T009 Implement a single source-of-truth accessor for authorized directories in `RustMate/Models/AppSettings.swift` (helpers to get directories by purpose, avoiding scattered filters)
- [X] T010 [P] Update any code filtering `.rustupAccess` to use the new helper API in `RustMate/ViewModels/SettingsViewModel.swift`

- [X] T011 Create `RustMate/Utilities/Authorization/AuthorizationScope.swift` defining which purposes are required for each operation family (toolchains/components/targets/project-context)
- [X] T012 Create `RustMate/Utilities/Authorization/AuthorizationError.swift` with structured cases (missingScope, staleBookmark, accessDenied, invalidSelection) and user-facing messages
- [X] T013 Create `RustMate/Utilities/Authorization/AuthorizationService.swift` to:
  - resolve bookmarks via `BookmarkManager`
  - `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`
  - validate required scopes for an operation
  - return actionable errors on failure

- [X] T014 Create `RustMate/Services/LocalExecution/ProcessOutputLimiter.swift` to enforce output truncation (stdout/stderr) for "summary only"
- [X] T015 Create `RustMate/Services/LocalExecution/ProcessRunner.swift` as async wrapper around `Process` (no main-thread blocking; capture stdout/stderr; enforce truncation via ProcessOutputLimiter)
- [X] T016 Create `RustMate/Services/LocalExecution/RustupCommandResolver.swift` to determine which rustup executable to run (from settings override or authorized executable dir) without scanning un-authorized paths
- [X] T017 Create `RustMate/Services/LocalExecution/RustupExecutionError.swift` with categories aligned to spec (missingAuthorization, rustupNotFound, executionFailed, parseFailed, unknown) and suggestedFix

- [X] T018 Extract/copy parsers from XPC target into App target:
  - `RustMate/Services/Parsers/ToolchainParser.swift`
  - `RustMate/Services/Parsers/ComponentParser.swift`
  - `RustMate/Services/Parsers/TargetParser.swift`
  - `RustMate/Services/Parsers/ShowParser.swift`
  (source from `RustMateXPC/Parsers/*.swift`)
- [X] T019 Update parser imports and shared model imports in the new parser files under `RustMate/Services/Parsers/` (use `RustMate/Shared/Models/*` types)

- [X] T020 Create `RustMate/Services/LocalExecution/LocalRustupToolchainService.swift` implementing `RustToolchainServiceProtocol` using:
  - AuthorizationService (scopes)
  - RustupCommandResolver (executable)
  - ProcessRunner (execution)
  - Parsers (decode output)
- [X] T021 Create `RustMate/Services/LocalExecution/LocalProjectContextService.swift` implementing `ProjectContextServiceProtocol` using AuthorizationService + ProcessRunner + ShowParser and file I/O (for rust-toolchain.toml mode)

- [X] T022 Add common "TaskResult/TaskRecord mapping" helpers for local execution in `RustMate/Shared/Models/TaskResult.swift` (or a new helper file `RustMate/Services/LocalExecution/TaskResultFactory.swift`) to keep UI consistent
- [X] T023 Add a single place to translate AuthorizationError/RustupExecutionError into user-facing error messages in `RustMate/Services/LocalExecution/ErrorPresentation.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - 首次授权并成功使用核心功能 (Priority: P1) 🎯 MVP

**Goal**: 新用户完成授权后，能在沙盒内执行一次最小 rustup 操作并看到结构化成功结果（不走 XPC）。
**Independent Test**: 按 `specs/002-process-rustup/quickstart.md` Step 1-2 完成。

### Implementation for User Story 1

- [X] T024 [P] Replace default toolchain service injection in `RustMate/ViewModels/ToolchainViewModel.swift` from `XPCToolchainService()` to `LocalRustupToolchainService()`
- [X] T025 [P] Replace default toolchain service injection in `RustMate/ViewModels/TargetsViewModel.swift` from `XPCToolchainService()` to `LocalRustupToolchainService()`
- [X] T026 [P] Replace default toolchain service injection in `RustMate/ViewModels/ComponentsViewModel.swift` from `XPCToolchainService()` to `LocalRustupToolchainService()`

- [X] T027 Replace view-level service creation in `RustMate/Views/Toolchains/ToolchainListView.swift` to use `LocalRustupToolchainService()` (or environment-injected service) instead of `XPCToolchainService()`
- [X] T028 Replace view-level service creation in `RustMate/Views/Components/ComponentsListView.swift` to use `LocalRustupToolchainService()` instead of `XPCToolchainService()`
- [X] T029 Replace view-level service creation in `RustMate/Views/Targets/TargetsListView.swift` to use `LocalRustupToolchainService()` instead of `XPCToolchainService()`

- [X] T030 Remove XPC bookmark send on app entry:
  - delete/disable `XPCClient.shared.sendCargoBookmark()` call in `RustMate/Views/MainContentView.swift`
- [X] T031 Remove XPC bookmark send on setup:
  - delete/disable `XPCClient.shared.updateCargoBookmark()` call in `RustMate/ViewModels/SetupViewModel.swift`

- [X] T032 Update setup "required bookmarks" logic in `RustMate/ViewModels/SetupViewModel.swift` to require the refined minimum set (rustupExecutableDir + cargoHome + rustupHome)
- [X] T033 Update setup UI copy + rows in `RustMate/Views/Setup/SetupView.swift` to show 3 authorization items (one per required scope) with clear descriptions
- [X] T034 Implement setup authorization actions in `RustMate/ViewModels/SetupViewModel.swift`:
  - add methods: authorizeRustupExecutableDir(), authorizeCargoHome(), authorizeRustupHome()
  - use `BookmarkManager.createBookmark`
  - persist to `AppSettings.authorizedDirectories` (or existing storage strategy)

- [X] T035 Update `RustMate/RustMateApp.swift` setup gate logic to reflect new required scopes (not only `~/.cargo/bin`)
- [X] T036 Update `RustMate/Utilities/EnvironmentValidator.swift` to validate by executing a minimal rustup command via `ProcessRunner` (populate `ValidationResult.version` without XPC)
- [X] T037 Ensure EnvironmentValidator uses AuthorizationService when in sandbox mode (no un-authorized path probing) in `RustMate/Utilities/EnvironmentValidator.swift`

- [X] T038 Update settings environment validation to match new validator behavior in `RustMate/ViewModels/SettingsViewModel.swift` (remove "version will be checked by XPC" assumption)

**Checkpoint**: User Story 1 fully functional: 授权→执行→结构化成功结果，且 UI 不冻结

---

## Phase 4: User Story 2 - 授权失败/不足时的可恢复体验 (Priority: P2)

**Goal**: 拒绝授权/选错目录/授权失效时，用户能得到明确原因与一键重试路径，而不是静默失败。
**Independent Test**: 按 `specs/002-process-rustup/quickstart.md` Step 3 (A/B/C) 逐个验证。

### Implementation for User Story 2

- [X] T039 Add structured error surface in ViewModels:
  - map AuthorizationError/RustupExecutionError to UI state in `RustMate/ViewModels/ToolchainViewModel.swift`
- [X] T040 [P] Add structured error surface in `RustMate/ViewModels/TargetsViewModel.swift` (same mapping strategy)
- [X] T041 [P] Add structured error surface in `RustMate/ViewModels/ComponentsViewModel.swift` (same mapping strategy)
- [X] T042 Add "re-authorize" call-to-action plumbing:
  - define a common callback or Notification for "RequestAuthorization(scope)" in `RustMate/Utilities/Authorization/AuthorizationCoordinator.swift`
- [X] T043 Implement UI prompt for missing authorization in `RustMate/Views/Shared/AuthorizationRequiredView.swift` (T043)
- [X] T044 Wire the prompt into toolchain list view flow in `RustMate/Views/Toolchains/ToolchainListView.swift` (show UI when errorCategory == missingAuthorization)

- [X] T045 Implement stale bookmark detection & refresh UX:
  - update `BookmarkManager.resolveBookmark` usage patterns to surface "stale" explicitly (new API or wrapper) in `RustMate/Utilities/Authorization/AuthorizationService.swift`
- [X] T046 When stale/accessDenied occurs, ensure UI suggests "Re-authorize" and routes user to the correct NSOpenPanel flow in `RustMate/ViewModels/SettingsViewModel.swift` (enhanced re-authorization with removeExistingBookmark)

- [X] T047 Ensure error messages avoid leaking raw stderr as primary UX; only show summary (structured) in `RustMate/Services/LocalExecution/ErrorPresentation.swift` (uses userFacingMessage from structured errors)

**Checkpoint**: ✅ Phase 4 Complete - 授权失败/不足/失效都有清晰提示 + 可恢复路径

---

## Phase 5: User Story 3 - 可见、可管理的授权范围 (Priority: P3)

**Goal**: 设置中可查看当前授权项状态，并支持重新授权/清除授权。
**Independent Test**: 打开 Settings → Permissions，能看到授权项与状态；清除后触发操作会重新要求授权。

### Implementation for User Story 3

- [X] T048 Update `RustMate/ViewModels/SettingsViewModel.swift` to:
  - remove `xpcClient` dependency (already removed)
  - remove `testXPCConnection()` + `xpcConnectionStatus` fields (already removed)
  - compute authorization state for new purposes (rustupExecutableDir/cargoHome/rustupHome/projectAccess) - authorizationStates tracking implemented
- [X] T049 Update Permissions tab UI in `RustMate/Views/Settings/SettingsView.swift`:
  - show 3 required scopes as separate rows (Authorize/Remove) - implemented with status badges and re-authorize support
  - keep project directories section (projectAccess) - preserved
- [X] T050 Update Settings Advanced tab in `RustMate/Views/Settings/SettingsView.swift` to remove "XPC Service" section - replaced with "Execution Mode" explanation
- [X] T051 Update `SettingsViewModel.authorizeDirectory(purpose:)` to support new purposes with correct default `directoryURL` per purpose (e.g., `~/.cargo`, `~/.rustup`, bin dirs) - defaultDirectoryURL implemented
- [X] T052 Update `SettingsViewModel.removeBookmark(purpose:)` to delete bookmark data from Keychain using `BookmarkManager.deleteBookmark(for:)` (removeExistingBookmark deletes from Keychain)
- [X] T053 Add "authorization status" validation routine in `RustMate/ViewModels/SettingsViewModel.swift` (validateAuthorizationStates implemented)

**Checkpoint**: 授权范围对用户透明、可管理、可清除

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: 清理 XPC 主路径依赖、统一文案与文档，确保 quickstart 可复现。

- [X] T054 Remove automatic XPC connection side-effects by eliminating remaining `XPCClient.shared` call sites in `RustMate/` (grep + delete unused wiring)
- [X] T055 [P] Deprecate XPC service implementations by marking `RustMate/Services/XPC/*` as legacy in comments and ensuring no default initializers reference them
- [X] T056 [P] Update user-facing copy to consistently say "授权范围" and "可恢复" in `RustMate/Views/Setup/SetupView.swift` and `RustMate/Views/Settings/SettingsView.swift`
- [X] T057 Ensure `AppState.checkSetupStatus()` in `RustMate/RustMateApp.swift` correctly detects "all required scopes exist" in sandbox builds
- [X] T058 Update `specs/002-process-rustup/quickstart.md` after implementation with any final UI label/path changes (keep it runnable)
- [X] T059 Run manual validation checklist from `specs/002-process-rustup/quickstart.md` and note any deviations in `specs/002-process-rustup/quickstart.md` (append findings)

**Checkpoint**: ✅ Phase N Complete - XPC dependencies removed, documentation updated, validation checklist ready

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion  
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Builds on US1 error surfaces and authorization flows, but should not require new backend changes
- **User Story 3 (P3)**: Can start after Foundational (Phase 2), but benefits from US1’s refined purposes and storage strategy

### Parallel Opportunities

- Parser extraction (T018-T019) can proceed in parallel with authorization helpers (T011-T013)
- Local execution primitives (T014-T017) can proceed in parallel with model refinements (T006-T010)
- ViewModel default injection updates (T024-T026) can proceed in parallel across files

---

## Parallel Example: User Story 1

```bash
Task: "Replace default toolchain service injection in RustMate/ViewModels/ToolchainViewModel.swift"
Task: "Replace default toolchain service injection in RustMate/ViewModels/TargetsViewModel.swift"
Task: "Replace default toolchain service injection in RustMate/ViewModels/ComponentsViewModel.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Follow `specs/002-process-rustup/quickstart.md` Step 1-2

### Incremental Delivery

1. US1: 授权→执行→成功
2. US2: 授权失败/失效的可恢复体验
3. US3: 设置中授权范围可见可管理

