# Tasks: 玻璃拟态 UI 视觉升级（对齐参考风格）

**Input**: Design documents from `/specs/004-glass-ui-refresh/`  
**Prerequisites**: `specs/004-glass-ui-refresh/plan.md`, `specs/004-glass-ui-refresh/spec.md`, `specs/004-glass-ui-refresh/contracts/*`, `specs/004-glass-ui-refresh/quickstart.md`

**Tests**: 本特性以 UI 视觉一致性为主，未要求 TDD。优先提供 SwiftUI Preview + quickstart 手工验收矩阵；仅在新增纯逻辑时补最小单测。

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 为跨页面一致性准备"设计系统"落点与文件结构

- [X] T001 Create design system folders in `RustMate/Views/Shared/DesignSystem/` (tokens, components, styles)
- [X] T002 [P] Add `RustMate/Views/Shared/DesignSystem/GlassTokens.swift` (颜色/间距/圆角/字体层级的统一入口)
- [X] T003 [P] Add `RustMate/Views/Shared/DesignSystem/GlassCard.swift`（卡片容器：elevation/描边/克制 material）
- [X] T004 [P] Add `RustMate/Views/Shared/DesignSystem/StatusBadgeView.swift`（DEFAULT/INSTALLED/UPDATE 等徽标）
- [X] T005 [P] Add `RustMate/Views/Shared/DesignSystem/SummaryCardView.swift`（Toolchains 概览卡）
- [X] T006 [P] Add `RustMate/Views/Shared/DesignSystem/SegmentedChipsView.swift`（胶囊筛选：All/Stable/Beta/Nightly）
- [X] T007 [P] Add `RustMate/Views/Shared/DesignSystem/InlineProgressView.swift`（行内进度：running 状态）
- [X] T008 [P] Add `RustMate/Views/Shared/DesignSystem/EmptyStateView.swift`（统一空态：图标+标题+一句话+动作）
- [X] T009 [P] Add `RustMate/Views/Shared/DesignSystem/ErrorCalloutView.swift`（错误摘要 + 建议动作 + 复制入口）
- [X] T010 [P] Add `RustMate/Views/Shared/DesignSystem/ButtonStyles.swift`（主次按钮层级统一）

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 将现有 Shared 组件接入 tokens/模式，形成可复用基础（阻塞所有页面一致性落地）

- [X] T011 Update `RustMate/Views/Shared/LoadingView.swift` to use `GlassTokens` (字体层级/间距/占位一致)
- [X] T012 Update `RustMate/Views/Shared/ErrorView.swift` to align with `ErrorCalloutView` patterns (摘要、建议、动作层级)
- [X] T013 Update `RustMate/Views/Shared/AuthorizationRequiredView.swift` to use `GlassCard` + 统一按钮层级
- [X] T014 [P] Add `RustMate/Views/Shared/DesignSystem/Extensions/Color+Tokens.swift`（如需：统一从 tokens 获取颜色）
- [X] T015 [P] Add `RustMate/Views/Shared/DesignSystem/Extensions/Typography.swift`（如需：标题/正文/注释样式）
- [X] T016 Define "状态语义映射表" in `RustMate/Views/Shared/DesignSystem/StatusSemantics.swift`（toolchain/component/target/task → badge/icon/颜色）

**Checkpoint**: Foundation ready - 可以开始按 User Story 改页面

---

## Phase 3: User Story 1 - Toolchains 首屏层级与卡片化（Priority: P1) 🎯 MVP

**Goal**: Toolchains 页面对齐参考截图：标题+摘要+概览卡+列表；状态可扫描、主操作清晰、进行中/失败有结构化反馈

**Independent Test**: 按 `specs/004-glass-ui-refresh/quickstart.md` 的 “A. Toolchains（P1）” 验收项逐条验证

### Implementation for User Story 1

- [X] T017 [US1] Add header section (title/subtitle + summary cards) in `RustMate/Views/Toolchains/ToolchainListView.swift`
- [X] T018 [US1] Add segmented chips filter state (All/Stable/Beta/Nightly) in `RustMate/Views/Toolchains/ToolchainListView.swift`
- [X] T019 [US1] Apply `GlassCard` + `SummaryCardView` to the Toolchains overview cards in `RustMate/Views/Toolchains/ToolchainListView.swift`
- [X] T020 [US1] Refactor empty state to `EmptyStateView` in `RustMate/Views/Toolchains/ToolchainListView.swift`
- [X] T021 [US1] Replace standard error UI with `ErrorCalloutView` (keep Retry / Open Settings entry) in `RustMate/Views/Toolchains/ToolchainListView.swift`
- [X] T022 [US1] Update list row visuals to match "left status + middle content + right action" in `RustMate/Views/Toolchains/ToolchainRowView.swift`
- [X] T023 [US1] Replace DEFAULT badge rendering with `StatusBadgeView` in `RustMate/Views/Toolchains/ToolchainRowView.swift`
- [ ] T024 [US1] Add inline progress indicator hook (when toolchain has running task) in `RustMate/Views/Toolchains/ToolchainRowView.swift`
- [X] T025 [US1] Align detail page layout/card sections to new tokens in `RustMate/Views/Toolchains/ToolchainDetailView.swift`
- [X] T026 [US1] Ensure Toolchains toolbar buttons follow primary/secondary hierarchy (Update All vs Install) in `RustMate/Views/Toolchains/ToolchainListView.swift`

**Checkpoint**: User Story 1 页面单独可验收（首屏层级/状态扫描/主操作/空态错态）

---

## Phase 4: User Story 2 - 跨页面一致性与状态组件统一（Priority: P2）

**Goal**: Components / Targets / Projects / Tasks / Settings 与 Toolchains 共享同一套 tokens 与模式（列表行、徽标、空态、错态、进行中）

**Independent Test**: 按 `quickstart.md` 的 “B. Components / Targets / Projects / Tasks / Settings（P2）” 逐条验收；随机切换两个页面不应出现割裂感

### Implementation for User Story 2

- [X] T027 [P] [US2] Apply `GlassTokens` + `GlassCard` to status bar container in `RustMate/Views/Components/ComponentsListView.swift`
- [X] T028 [P] [US2] Apply `GlassTokens` + `GlassCard` to status bar container in `RustMate/Views/Targets/TargetsListView.swift`
- [X] T029 [US2] Replace Components empty/loading states with `EmptyStateView` / `LoadingView` conventions in `RustMate/Views/Components/ComponentsListView.swift`
- [X] T030 [US2] Replace Targets empty/loading states with `EmptyStateView` / `LoadingView` conventions in `RustMate/Views/Targets/TargetsListView.swift`
- [X] T031 [US2] Normalize "suggestions section" card style in `RustMate/Views/Targets/TargetsListView.swift` (and related card view in same file)
- [X] T032 [US2] Update Projects list row/container style to match list row pattern in `RustMate/Views/Projects/ProjectsListView.swift`
- [X] T033 [US2] Update Project context page sections to `GlassCard` pattern in `RustMate/Views/Projects/ProjectContextView.swift`
- [X] T034 [US2] Update Tasks list items to card/list-row pattern and status badges in `RustMate/Views/Tasks/TasksListView.swift`
- [X] T035 [US2] Update Task detail page sections to new tokens + error callout in `RustMate/Views/Tasks/TaskDetailView.swift`
- [X] T036 [US2] Update Settings sections to card grouping + consistent error callout in `RustMate/Views/Settings/SettingsView.swift`
- [X] T037 [US2] Align main shell (search/toolbar/sidebar spacing) with tokens in `RustMate/Views/MainContentView.swift`
- [ ] T038 [US2] (Optional if already present) Apply compact style patterns to menu bar UI in `RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`

**Checkpoint**: 任意两页面切换仍保持一致的层级、间距、按钮与状态语义

---

## Phase 5: User Story 3 - 深浅色与可访问性体验可靠（Priority: P3）

**Goal**: 玻璃拟态不牺牲可读性；浅/深色、较大字号、减少动效、键盘焦点都可靠

**Independent Test**: 按 `quickstart.md` 的 “C. 可访问性（P3）” 完整走一遍（浅/深/字号/Reduce Motion/键盘导航）

### Implementation for User Story 3

- [X] T039 [US3] Add accessibility labels/values to `StatusBadgeView` in `RustMate/Views/Shared/DesignSystem/StatusBadgeView.swift`
- [X] T040 [US3] Ensure focus ring visibility for interactive chips/buttons in `RustMate/Views/Shared/DesignSystem/SegmentedChipsView.swift`
- [ ] T041 [US3] Add dynamic type friendly layout rules (truncation/minHeight) in `RustMate/Views/Shared/DesignSystem/*` components
- [X] T042 [US3] Add Reduce Motion handling (avoid required animations) in `RustMate/Views/Shared/DesignSystem/InlineProgressView.swift`
- [ ] T043 [US3] Verify and adjust contrast for light mode tokens in `RustMate/Views/Shared/DesignSystem/GlassTokens.swift`
- [ ] T044 [US3] Ensure keyboard navigation order is reasonable in `RustMate/Views/Toolchains/ToolchainListView.swift` (sidebar→filter→list→actions)

**Checkpoint**: 满足 SC-004（可访问性）并通过 quickstart C 部分

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 覆盖回归风险点，收敛一致性与性能

- [ ] T045 [P] Add/refresh SwiftUI previews for new components in `RustMate/Views/Shared/DesignSystem/*` (至少每个组件 1 个 preview)
- [ ] T046 Audit and reduce heavy blur/shadow usage across views (performance) in `RustMate/Views/**` (focus: Toolchains list + headers)
- [ ] T047 Run `specs/004-glass-ui-refresh/quickstart.md` end-to-end and record any follow-up fixes directly in affected view files
- [ ] T048 Clean up dead styles and keep old UI code paths minimal in `RustMate/Views/**`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational completion
- **Polish (Phase 6)**: Depends on completing the intended user stories (at least US1)

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 only
- **US2 (P2)**: Depends on Phase 2 only（可在 US1 完成后推进，也可并行推进不同页面）
- **US3 (P3)**: Depends on Phase 2（通常在 US1/US2 之后集中收敛）

### Parallel Opportunities

- Phase 1 的组件文件新增（T002–T010）可并行
- Phase 4 中 Components/Targets 的状态栏与空态（T027–T031）可并行
- Phase 6 的 previews 与性能审计（T045–T046）可并行

---

## Parallel Example: User Story 1

```text
Task: "Add header section in RustMate/Views/Toolchains/ToolchainListView.swift"
Task: "Update row visuals in RustMate/Views/Toolchains/ToolchainRowView.swift"
Task: "Align detail sections in RustMate/Views/Toolchains/ToolchainDetailView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. 完成 Phase 1 + Phase 2（tokens + 组件模式）
2. 完成 Phase 3（Toolchains 页面）
3. **STOP and VALIDATE**：按 `quickstart.md` 的 A 部分验收

### Incremental Delivery

1. US1（Toolchains）先对齐参考风格 → 可演示 MVP
2. US2 逐页铺开一致性（Components/Targets/Projects/Tasks/Settings）
3. US3 集中做可访问性与浅色模式收敛

