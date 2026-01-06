---

description: "Tasks for implementing auto-update (stable/beta) via Sparkle 2"
---

# Tasks: 自动更新（Stable/Beta 渠道）

**Input**: Design documents from `/specs/005-sparkle-auto-update/`  
**Prerequisites**: `specs/005-sparkle-auto-update/plan.md`, `specs/005-sparkle-auto-update/spec.md`, `specs/005-sparkle-auto-update/research.md`, `specs/005-sparkle-auto-update/data-model.md`, `specs/005-sparkle-auto-update/contracts/*`, `specs/005-sparkle-auto-update/quickstart.md`

**Tests**: 未在 spec 中要求 TDD/测试优先；本任务列表以实现与可重复手工验收（quickstart）为主。  
**Constitution**: 默认不引入 XPC；更新源必须 HTTPS；对外错误/状态必须结构化并可行动。

## Phase 1: Setup（Shared Infrastructure）

**Purpose**: 把 Sparkle 2 与更新配置接入工程，准备承载后续 US1/US2/US3 的代码结构。

- [X] T001 在 Xcode 工程添加 Sparkle 2 依赖（Swift Package Manager）于 `RustMate.xcodeproj`（需手动操作，见 SPARKLE_INTEGRATION.md）
- [X] T002 [P] 新增更新模块目录与占位文件：`RustMate/Services/Updates/`（添加 `.gitkeep` 或首个实现文件）
- [X] T003 [P] 在本 feature 文档补充仓库级发布说明入口：新增 `RELEASING.md`（包含"Sparkle 更新发布"小节）

---

## Phase 2: Foundational（Blocking Prerequisites）

**Purpose**: 统一“设置单一数据源”、定义结构化状态/错误与渠道配置，为所有用户故事提供稳定底座。  
**⚠️ CRITICAL**: 本阶段未完成前，不开始 US1/US2/US3 的 UI/流程集成。

- [X] T004 修正 Settings 的数据流为单一数据源（AppState）并可写回：更新 `RustMate/RustMateApp.swift` 与 `RustMate/Views/Settings/SettingsView.swift`
- [X] T005 让 SettingsViewModel 以 AppState/settings 为输入并写回（避免 copy 不持久化）：更新 `RustMate/ViewModels/SettingsViewModel.swift`
- [X] T006 在设置模型中加入更新渠道偏好字段（默认 stable）：更新 `RustMate/Models/AppSettings.swift`
- [X] T007 [P] 定义结构化更新状态与错误枚举（对应 data-model）：新增 `RustMate/Services/Updates/UpdateModels.swift`
- [X] T008 [P] 定义更新源配置（stable/beta 两个 HTTPS URL + 最低 macOS 15 约束）：新增 `RustMate/Services/Updates/UpdateFeeds.swift`
- [X] T009 在更新模块中加入 URL 校验与降级策略（必须 HTTPS、异常条目安全失败）：新增 `RustMate/Services/Updates/UpdateValidation.swift`

**Checkpoint**: Settings 的变更能持久化（UserDefaults），且具备 `stable/beta` 偏好字段；更新状态/错误可结构化表示。

---

## Phase 3: User Story 1 - 从稳定渠道自动更新（Priority: P1）🎯 MVP

**Goal**: 默认订阅 stable appcast，后台检查/下载，下载完成后提示用户退出/重启安装。  
**Independent Test**: 参照 `specs/005-sparkle-auto-update/quickstart.md` 的 P1 步骤，可在 stable 清单存在新版本时完成一次升级闭环。

- [X] T010 [P] [US1] 新增"更新协调器/服务"封装 Sparkle 更新器：新增 `RustMate/Services/Updates/AppUpdateService.swift`
- [X] T011 [US1] 在应用启动时初始化更新服务（默认 stable feed）：更新 `RustMate/RustMateApp.swift`
- [X] T012 [US1] 在 Settings 中新增"Updates"区块与"Check for Updates"入口（便于手工验收）：更新 `RustMate/Views/Settings/SettingsView.swift`
- [X] T013 [US1] 将"后台自动检查/后台下载"的策略配置为默认开启，并保证不阻塞 UI：更新 `RustMate/Services/Updates/AppUpdateService.swift`
- [X] T014 [US1] 在 UI 中展示最小状态（checking/downloading/readyToInstall/failed）：更新 `RustMate/Views/Settings/SettingsView.swift` 与 `RustMate/Services/Updates/UpdateModels.swift`

**Checkpoint**: 不开启 Beta 时，应用使用 stable 更新清单；可手动触发检查更新；下载完成后出现“需要退出/重启安装”的提示。

---

## Phase 4: User Story 2 - 用户选择加入/退出 Beta 渠道（Priority: P2）

**Goal**: Settings 增加“接收 Beta 更新”开关；切换后下次检查更新走对应 appcast。  
**Independent Test**: 参照 `specs/005-sparkle-auto-update/quickstart.md` 的 P2 步骤，切换开关后能从不同清单发现不同版本条目。

- [X] T015 [US2] 在 Settings 增加"接收 Beta 更新"Toggle，并绑定到 `AppSettings`：更新 `RustMate/Views/Settings/SettingsView.swift`
- [X] T016 [US2] 将 Toggle 变更写回并持久化（重启后仍生效）：更新 `RustMate/Models/AppSettings.swift` 与 `RustMate/ViewModels/SettingsViewModel.swift`
- [X] T017 [US2] 更新服务按偏好选择 stable/beta feed（切换后下次检查生效）：更新 `RustMate/Services/Updates/AppUpdateService.swift` 与 `RustMate/Services/Updates/UpdateFeeds.swift`
- [X] T018 [US2] 在 UI 中展示当前渠道（Stable/Beta）用于用户确认：更新 `RustMate/Views/Settings/SettingsView.swift`

**Checkpoint**: 开关切换后，下一次“检查更新”确实使用对应渠道；偏好可持久化。

---

## Phase 5: User Story 3 - 更新失败时给出可行动的反馈（Priority: P3）

**Goal**: 网络失败、清单不可用、签名校验失败、系统版本不满足等场景下给出结构化、可行动提示。  
**Independent Test**: 参照 `specs/005-sparkle-auto-update/quickstart.md` 的 P3 步骤，能得到明确错误与建议动作。

- [X] T019 [US3] 建立 Sparkle 错误到 `UpdateError` 的映射（分类 + 用户消息 + 建议动作）：更新 `RustMate/Services/Updates/AppUpdateService.swift` 与 `RustMate/Services/Updates/UpdateModels.swift`
- [X] T020 [US3] 在 Settings 的 Updates 区块展示错误信息与"重试"入口：更新 `RustMate/Views/Settings/SettingsView.swift`
- [X] T021 [US3] 对"系统版本不满足（< 15.0）"提供明确提示并阻止安装路径：更新 `RustMate/Services/Updates/UpdateValidation.swift`
- [X] T022 [US3] 对"签名校验失败"强制失败并提示风险（不可继续安装）：更新 `RustMate/Services/Updates/AppUpdateService.swift`

**Checkpoint**: 断网/清单不可访问/签名失败/系统版本不满足等场景能给出清晰反馈与可执行下一步。

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 让发布/托管与验收闭环更顺滑，降低后续维护成本。

- [X] T023 [P] 为 GitHub Pages（或 raw）补齐 appcast 托管说明与固定 URL 约定：更新 `RELEASING.md`
- [X] T024 [P] 为 GitHub Releases 补齐 DMG 命名、tag 规则与"先传 DMG 后更新 appcast"的不变量：更新 `RELEASING.md`
- [X] T025 [P] 增加发布用工作流骨架（占位、需后续填 secrets）：新增 `.github/workflows/release-dmg.yml`
- [X] T026 将 quickstart 的步骤与产品 UI 对齐（确保都有入口可操作）：更新 `specs/005-sparkle-auto-update/quickstart.md`
- [ ] T027 进行一次 end-to-end 手工回归并记录结果（以日志/截图为准）：更新 `specs/005-sparkle-auto-update/quickstart.md`（需实际测试）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** → **Phase 2 (Foundational)** → **US1 (MVP)** → **US2** → **US3** → **Polish**

### User Story Dependencies

- **US1** 依赖 Foundational（设置可写回 + 状态/错误模型 + feed 配置）
- **US2** 依赖 US1（已有更新服务与 Updates UI 基座）
- **US3** 依赖 US1（已有更新流程），可与 US2 并行推进但建议在 US2 后补齐 UI 文案与状态

### Parallel Opportunities

- **[P]** 标记的任务可并行（不同文件/弱耦合），例如：更新模型/校验工具/发布文档/工作流骨架

---

## Implementation Strategy

### MVP First（只做 US1）

完成 Phase 1 + Phase 2 后，实现 US1（T010-T014），然后按 `specs/005-sparkle-auto-update/quickstart.md` 的 P1 进行验收；通过后再进入 US2/US3。


