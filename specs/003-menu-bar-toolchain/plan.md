# Implementation Plan: 菜单栏工具链切换

**Branch**: `003-menu-bar-toolchain` | **Date**: 2026-01-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-menu-bar-toolchain/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

为 RustMate 增加一个 macOS 菜单栏常驻入口，用于：
- 展示“当前全局默认工具链标识”
- 从菜单栏直接切换全局默认工具链
- 一键唤起 RustMate 主界面

技术上复用现有的工具链 service（已具备“列出工具链/设置默认工具链”的能力）与现有的结构化错误呈现约束；新增一个轻量的菜单栏状态层用于拉取与刷新当前默认工具链，并将菜单栏交互映射为结构化任务结果。

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Swift（Xcode 工程；Swift 语言版本在工程内为 5.0）  
**Primary Dependencies**: SwiftUI、Combine、AppKit（用于 macOS 生命周期/窗口激活）  
**Storage**: UserDefaults（AppSettings 已持久化）；本功能自身无新增持久化需求（N/A）  
**Testing**: XCTest（已有 RustMateTests/…）；本功能预计以轻量单测 + 可重复手工验收为主  
**Target Platform**: macOS 15.6（由工程设置 MACOSX_DEPLOYMENT_TARGET 推断）
**Project Type**: 单一 macOS App（SwiftUI + MVVM + 协议化 Service；仓库另包含 RustMateXPC 但不作为默认依赖）  
**Performance Goals**: 菜单栏入口应在 App 启动后快速可用；状态刷新与切换反馈应在“用户可感知的短时间”内完成（详见 spec 的 SC-001/SC-002）  
**Constraints**: 沙盒环境下的外部命令执行必须走既有授权与参数校验；不得阻塞 UI 主线程；结果必须结构化呈现  
**Scale/Scope**: 单用户本地工具；菜单栏交互以小菜单/轻量面板为主，不引入复杂状态编辑器

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

用项目宪章（`.specify/memory/constitution.md`）生成并填写以下检查项（不通过则必须在“Complexity Tracking”里说明）：

- **用户价值**：通过菜单栏可独立完成 P1（查看当前全局默认工具链、切换默认工具链）与 P2（唤起主界面）；每个旅程均有可独立验收场景（PASS）。
- **简化优先 / XPC**：不引入/扩展 XPC；复用现有进程内 service 与错误建模（PASS）。
- **安全/沙盒**：菜单栏触发的切换动作必须复用既有授权校验与参数验证；不新增权限范围；失败需提供可行动提示（PASS，设计中会明确责任边界）。
- **可测试**：核心逻辑（默认工具链解析/菜单栏状态更新/并发切换策略）可通过单元测试覆盖；端到端以 quickstart 手工步骤回归（PASS）。
- **结构化结果**：菜单栏 UI 只消费结构化状态/错误与简短摘要，不将多行原始输出作为 UI 协议（PASS）。

## Project Structure

### Documentation (this feature)

```text
specs/003-menu-bar-toolchain/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
RustMate/                         # 主应用（SwiftUI）
├── RustMateApp.swift
├── Views/
│   ├── MainContentView.swift
│   └── Toolchains/...
├── ViewModels/
│   └── ToolchainViewModel.swift
├── Services/
│   ├── Protocols/
│   │   └── RustToolchainServiceProtocol.swift
│   ├── LocalExecution/
│   │   └── LocalRustupToolchainService.swift
│   └── Parsers/...
└── Utilities/...

RustMateTests/                    # 单元测试（XCTest）
└── ...

RustMateXPC/                      # XPC 服务（现有，但本功能不默认依赖）
└── ...
```

**Structure Decision**: 采用仓库现有的“SwiftUI + MVVM + 协议化 Service”结构；菜单栏入口作为主应用的一部分，调用 `RustToolchainServiceProtocol` 执行“列出/设置默认工具链”，并复用既有授权与错误呈现体系。该功能不要求 XPC。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
