# Tasks: 菜单栏工具链切换

**Input**: Design documents from `/specs/003-menu-bar-toolchain/`  
**Prerequisites**: `specs/003-menu-bar-toolchain/plan.md`, `specs/003-menu-bar-toolchain/spec.md`, `specs/003-menu-bar-toolchain/research.md`, `specs/003-menu-bar-toolchain/data-model.md`, `specs/003-menu-bar-toolchain/contracts/menu-bar-toolchain.md`, `specs/003-menu-bar-toolchain/quickstart.md`

**Tests**: 本 feature spec 未要求 TDD/必须测试；以下任务以“可重复手工验收（quickstart.md）+ 关键逻辑轻量单测”为主，仅在高收益处加入单测任务。  
**Constitution**: 所有任务必须满足“不默认 XPC、沙盒/参数校验、结构化结果、不阻塞主线程”。

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 为菜单栏功能落地准备最小结构与接入点

- [X] T001 创建菜单栏功能目录与基础文件骨架：`RustMate/Features/MenuBar/`（新增 `MenuBarToolchainViewModel.swift`, `MenuBarToolchainMenu.swift`）
- [X] T002 [P] 补充/对齐模型与结果类型（如缺失则新增）：`RustMate/Shared/Models/`（例如 `MenuBarActionResult.swift` 或复用现有 `TaskResult` 的映射类型）

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 菜单栏功能依赖的"状态获取/错误呈现/并发策略"基础能力（完成后才能做 US1/US2/US3）

- [X] T003 实现"菜单栏状态聚合"逻辑（从 toolchain 列表推导当前默认 toolchain）：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [X] T004 [P] 定义并实现"进行中/错误/可行动建议"的结构化呈现模型（菜单栏消费）：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [X] T005 定义切换并发策略（单飞行、拒绝/排队其一，并保证 UI 可见）：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [X] T006 [P] 增加轻量单测覆盖默认 toolchain 推导与并发策略（如可行）：`RustMateTests/ViewModelTests/MenuBarToolchainViewModelTests.swift`

**Checkpoint**: 完成后可以开始 US1/US2/US3 的 UI 接入与交互实现

---

## Phase 3: User Story 1 - 菜单栏显示当前全局工具链 (Priority: P1) 🎯 MVP

**Goal**: 菜单栏常驻入口能显示"当前全局默认工具链标识"，并在失败时给出可行动提示

**Independent Test**: 仅实现 US1 时，按 `specs/003-menu-bar-toolchain/quickstart.md` 的 1) 步骤可验收

- [X] T007 [US1] 增加菜单栏入口并接入到 App 生命周期：`RustMate/RustMateApp.swift`
- [X] T008 [US1] 实现菜单栏菜单 UI：展示当前默认 toolchain（空间不足可降级到菜单内展示）：`RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`
- [X] T009 [US1] 在菜单栏菜单中提供"刷新"入口并绑定刷新逻辑：`RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`
- [X] T010 [US1] 失败态 UI：展示结构化错误与建议动作（至少重试/打开主界面查看）：`RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`
- [ ] T011 [US1] 验收 US1：按 `specs/003-menu-bar-toolchain/quickstart.md` 的 1) 执行并记录结果（手工步骤）

---

## Phase 4: User Story 2 - 从菜单栏切换全局默认工具链 (Priority: P1)

**Goal**: 菜单栏列出可选工具链并支持切换全局默认工具链；切换中有状态；失败有结构化提示且不改变显示

**Independent Test**: 仅实现 US2（可依赖已完成的 US1 菜单栏入口）时，按 `specs/003-menu-bar-toolchain/quickstart.md` 的 2) 步骤可验收

- [X] T012 [US2] 菜单栏菜单中展示可用工具链列表并标注当前默认项：`RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`
- [X] T013 [US2] 绑定"选择工具链 → 发起切换默认工具链"的动作（输入必须来自受信列表或通过严格校验）：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [X] T014 [US2] 切换进行中状态：菜单项禁用/显示"切换中"提示（不得阻塞主线程）：`RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`
- [X] T015 [US2] 切换成功后强制刷新并更新菜单栏显示：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [X] T016 [US2] 切换失败处理：保持显示仍为切换前默认项，并展示结构化失败原因与建议动作：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [X] T017 [US2] 并发切换行为一致化（提示/排队/取消策略按 T005 定义落地）：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [ ] T018 [US2] 验收 US2：按 `specs/003-menu-bar-toolchain/quickstart.md` 的 2) 执行并记录结果（手工步骤）

---

## Phase 5: User Story 3 - 从菜单栏唤起 App 主界面 (Priority: P2)

**Goal**: 菜单栏提供"打开 RustMate"，可将主界面唤起并置前可交互

**Independent Test**: 仅实现 US3（可依赖已完成的菜单栏入口）时，按 `specs/003-menu-bar-toolchain/quickstart.md` 的 3) 步骤可验收

- [X] T019 [US3] 菜单栏菜单增加"打开 RustMate"菜单项：`RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`
- [X] T020 [US3] 实现"唤起主界面并置前"行为（窗口存在则置前，不存在则打开）：`RustMate/RustMateApp.swift`（或新增 `RustMate/Utilities/AppActivation.swift` 作为封装）
- [ ] T021 [US3] 验收 US3：按 `specs/003-menu-bar-toolchain/quickstart.md` 的 3) 执行并记录结果（手工步骤）

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 打磨多旅程共用体验、稳定性与回归路径

- [X] T022 [P] 菜单栏显示空间不足的降级策略（仅图标/更短标识/仅菜单内显示）与文案优化：`RustMate/Features/MenuBar/MenuBarToolchainMenu.swift`
- [X] T023 错误分类到菜单栏的映射一致性（授权缺失/执行失败/解析失败等）：`RustMate/Features/MenuBar/MenuBarToolchainViewModel.swift`
- [X] T024 [P] 更新开发者说明：补充菜单栏功能的手工验收与常见问题：`specs/003-menu-bar-toolchain/quickstart.md`
- [ ] T025 最终回归：执行 `specs/003-menu-bar-toolchain/quickstart.md` 全流程并确认满足 SC-001~SC-004

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** → **Phase 2 (Foundational)** → **US1/US2/US3**（US1 与 US2 同为 P1，但建议先完成 US1 的“入口与状态展示”，再完成 US2 的“切换交互”）→ **Polish**

## Parallel Opportunities

- Phase 1/2 中标记 `[P]` 的任务可并行（不同文件、低耦合）
- US2 与 US3 在 US1 菜单栏入口落地后可并行推进（分别聚焦“切换”与“唤起窗口”）

