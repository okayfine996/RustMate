# Implementation Plan: 玻璃拟态 UI 视觉升级（对齐参考风格）

**Branch**: `004-glass-ui-refresh` | **Date**: 2026-01-02 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/004-glass-ui-refresh/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

在不改变现有信息架构与核心功能的前提下，对 RustMate 的主界面（Toolchains / Components / Targets / Projects / Tasks / Settings）进行统一的“Apple 风格玻璃拟态 + 卡片化”视觉升级，达到参考截图的清爽开发者工具质感：更清晰的层级、可扫描的状态、统一的空态/错态/进行中态，并确保浅/深色与可访问性可靠。

## Technical Context

**Language/Version**: Swift 5.9+（Xcode 15+）  
**Primary Dependencies**: SwiftUI（macOS）、Foundation、Observation/@MainActor；菜单栏相关使用 AppKit（NSStatusItem）  
**Storage**: N/A（本特性不新增持久化；沿用现有 UserDefaults/Keychain 等设置与书签存储）  
**Testing**: XCTest（ViewModel/逻辑单测），手工验收矩阵写入 `quickstart.md`（本特性以视觉一致性为主）  
**Target Platform**: macOS 13.0+（Ventura 及以上，App Sandbox）  
**Project Type**: macOS 桌面应用（Xcode multi-target 项目：主 App + 既有 XPC 可选）  
**Performance Goals**: 滚动与交互保持 60fps；列表与卡片渲染不产生明显卡顿；避免过度模糊/阴影造成 GPU 压力  
**Constraints**:
- 不新增权限/授权范围，不改变沙盒边界
- 不改变现有信息架构与主要交互路径（确保主操作可发现性不下降）
- 状态与错误展示坚持结构化（摘要 + 建议动作），避免长输出主导界面
- 玻璃拟态在可读性与可访问性前提下使用（对比度、焦点可见、键盘可操作）
**Scale/Scope**:
- 6 个主页面 +（若已存在）菜单栏弹窗
- 统一设计语言（tokens + 可复用组件）覆盖核心列表/卡片/徽标/按钮/提示

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### 用户价值 ✅

**Status**: PASS

- ✅ P1 旅程（Toolchains 首屏层级 + 状态可扫描 + 主操作可完成）可独立演示与验收（见 spec User Story 1）

### 简化优先 / XPC ✅

**Status**: PASS

- ✅ 本特性不引入/扩展 XPC（纯 UI 视觉与呈现层改进）
- ✅ 更改范围限定为“tokens + 可复用视图组件 + 既有页面布局微调”

### 安全/沙盒 ✅

**Status**: PASS

- ✅ 不新增权限/授权范围
- ✅ 不改变外部命令执行边界；错误提示仅做呈现统一

### 可测试 ✅

**Status**: PASS

- ✅ 关键验收点以可重复的手工验收矩阵定义在 `quickstart.md`
- ✅ 如新增可复用组件，会补 SwiftUI Preview 与最小快照/渲染断言（若现有测试框架允许）

### 结构化结果 ✅

**Status**: PASS

- ✅ 状态/错误以“摘要 + 建议动作”呈现，不依赖多行输出文本作为协议

**GATE RESULT**: ✅ **PASS** - 符合宪章，进入 Phase 0。

## Project Structure

### Documentation (this feature)

```text
specs/004-glass-ui-refresh/
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
├── Features/                       # Feature modules (Toolchains/Components/Targets/Projects/Tasks/Settings/MenuBar)
├── Views/                          # SwiftUI pages + shared views
│   ├── Toolchains/
│   ├── Components/
│   ├── Targets/
│   ├── Projects/
│   ├── Tasks/
│   ├── Settings/
│   └── Shared/                     # 可复用 UI（本特性将主要在此处沉淀设计系统）
├── ViewModels/                     # @MainActor view models
├── Services/                       # Service layer（本特性原则上不改）
└── Assets.xcassets/                # AppIcon / accent 等（必要时补充颜色资产）

RustMateTests/                      # Unit tests（ViewModelTests 等）
RustMateUITests/                    # UI tests（如用于 smoke）
```

**Structure Decision**: 单一 macOS 应用工程（多 target），本特性聚焦 `RustMate/Views/*` 与 `RustMate/Views/Shared/*`，通过“设计 tokens + 组件模式”实现跨页面一致性。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations detected.** 本特性不触碰宪章的高风险项（权限/XPC/命令执行），复杂度主要来自“视觉一致性覆盖面”，已通过 tokens + 复用组件控范围。

---

## Phase 0: Research Outcomes

✅ **Completed**: See [research.md](./research.md)

**Key Decisions**:
1. **视觉语言**：暗色为主、玻璃拟态（material/blur）克制使用、卡片化层级与清晰留白
2. **Tokens**：颜色/间距/圆角/阴影/字体层级统一，避免页面各自为政
3. **状态体系**：统一 loading / running / success / failed / empty 的呈现与动作入口
4. **可访问性优先**：对比度与焦点可见优先于“更像玻璃”的效果

---

## Phase 1: Design Artifacts

### Data Model

✅ **Completed**: See [data-model.md](./data-model.md)

### Contracts（UI 规范契约）

✅ **Completed**: See `contracts/`:
- `contracts/ui-style-spec.md`（tokens + 视觉层级规则）
- `contracts/component-patterns.md`（卡片/徽标/筛选/按钮/提示等模式）
- `contracts/screen-coverage.md`（页面覆盖与验收点映射）

### Developer Onboarding

✅ **Completed**: See [quickstart.md](./quickstart.md)

---

## Post-Design Constitution Check

*Re-validation after Phase 1 design completion*

### All Principles: ✅ PASS

研究与设计产物没有引入新的权限或执行层复杂度；所有验收点都可通过 quickstart 的步骤重复验证，符合宪章要求。
