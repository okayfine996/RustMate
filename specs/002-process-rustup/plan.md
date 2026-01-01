# Implementation Plan: Sandboxed Direct Rustup Execution

**Branch**: `002-process-rustup` | **Date**: 2026-01-01 | **Spec**: `specs/002-process-rustup/spec.md`  
**Input**: Feature specification from `specs/002-process-rustup/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

在保持主 App 仍为 **App Sandbox（审核友好）** 的前提下，移除“必须走 XPC 执行 rustup”的前置依赖，
改为在主进程中直接执行 rustup 相关操作；同时把 `rustup/.cargo/.rustup` 的访问全部纳入
**用户选择 + security-scoped bookmark** 的授权体系中，确保“授权范围”正确、可见、可恢复。

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Swift 5.x (project setting: `SWIFT_VERSION = 5.0`)  
**Primary Dependencies**: SwiftUI, AppKit (`NSOpenPanel`), Foundation (`Process`), Security (Keychain + bookmarks)  
**Storage**: Keychain（保存 bookmarkData）+ UserDefaults（设置/项目列表等）  
**Testing**: XCTest（已包含 ParserTests / ViewModelTests 等基础）  
**Target Platform**: macOS（App Sandbox）  
**Project Type**: macOS App（SwiftUI + MVVM）  
**Performance Goals**: UI 保持响应；长任务不阻塞主线程；输出摘要化避免内存峰值  
**Constraints**: 不依赖 XPC；所有文件系统访问必须在用户授权范围内；错误必须结构化呈现  
**Scale/Scope**: 覆盖 rustup 的核心读操作与常见写操作（安装/卸载/组件/target/override 等沿用现有能力）

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

用项目宪章（`.specify/memory/constitution.md`）生成并填写以下检查项（不通过则必须在“Complexity Tracking”里说明）：

- **用户价值**：本功能的 P1 用户旅程是否可独立验收与演示？
- **简化优先 / XPC**：是否引入或扩展 XPC？若是，是否给出替代方案对比与复杂度成本？
- **安全/沙盒**：是否涉及目录授权、外部命令、参数校验、权限最小化？
- **可测试**：是否明确哪些逻辑需要 fixtures/单测，哪些边界需要回归验证？
- **结构化结果**：对外是否以结构化状态/错误为主，避免把多行输出当 UI 协议？

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
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
RustMate/
├── Models/
├── Services/
│   ├── Protocols/
│   ├── XPC/                      # 将逐步替换为本地执行层（本次 feature 重点）
│   └── Mock/
├── Utilities/
├── ViewModels/
└── Views/

RustMateXPC/                      # 现有 XPC target（本次目标是不再作为主路径依赖）
└── Parsers/                      # 解析器未来将迁移/复用到主 App

RustMateTests/
└── Fixtures/                     # 可用于执行层与解析器的回归样本
```

**Structure Decision**: 保持当前单一 macOS App 结构；新增/替换执行层实现放入 `RustMate/Services/`，
解析器能力尽量复用（必要时迁移到 App target 或 Shared）。

## Phase 0: Research (output: `research.md`)

见 `specs/002-process-rustup/research.md`。目标是把以下关键点定型为可执行决策：

- 沙盒内直接执行 rustup 的可行性边界与风险
- security-scoped bookmark 的“最小授权集合”如何定义，才能稳定覆盖 rustup 的可执行与数据目录访问
- 如何在 UX 上表达授权范围、授权不足、授权失效与恢复路径

## Phase 1: Design (outputs: `data-model.md`, `contracts/`, `quickstart.md`)

见：

- `specs/002-process-rustup/data-model.md`
- `specs/002-process-rustup/contracts/`
- `specs/002-process-rustup/quickstart.md`

设计目标：

- 把“授权范围”数据模型化（可展示、可验证、可清除、可刷新）
- 定义“本地执行层”的输入/输出契约（结构化结果、错误分类、输出摘要）
- 定义最小可回归的验证路径（不依赖真实 rustup 的单测/fixture + 最小手工验证）

## Post-Design Constitution Check

- **用户价值**：P1 形成“授权→执行→结构化结果”的闭环，可独立验收 ✅  
- **简化优先 / XPC**：不引入新 XPC；现有 XPC 逐步降级为非主路径 ✅  
- **安全/沙盒**：以 security-scoped bookmark 为唯一授权入口，强调最小权限 ✅  
- **可测试**：解析器/错误分类与授权校验可单测；执行层可用 fixture 验证 ✅  
- **结构化结果**：输出/错误统一建模，避免依赖 raw 文本 ✅

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
