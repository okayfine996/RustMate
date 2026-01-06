# Implementation Plan: 自动更新（Stable/Beta 渠道）

**Branch**: `[005-sparkle-auto-update]` | **Date**: 2026-01-05 | **Spec**: `specs/005-sparkle-auto-update/spec.md`  
**Input**: Feature specification from `/specs/005-sparkle-auto-update/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

为 RustMate 增加非 App Store 的自动更新能力：默认订阅稳定渠道更新清单（stable appcast），并允许用户在设置里打开“接收 Beta 更新”后切换到 beta appcast。更新包以 DMG 形式发布，产物在发布前必须完成签名与公证；DMG 上传至 GitHub Releases，两个 appcast 固定托管在 GitHub Pages（或 raw）。更新体验采用后台下载，下载完成后提示用户退出/重启完成安装；安全性依赖 HTTPS + 更新包签名校验。

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Swift 5.x（由 Xcode 工具链决定；工程内存在 `SWIFT_VERSION = 5.0` 配置）  
**Primary Dependencies**: SwiftUI / AppKit / Foundation / Combine；新增：Sparkle 2（自动更新）  
**Storage**: UserDefaults（保存设置项，包括更新渠道偏好）  
**Testing**: XCTest（单元测试为主；更新流程以手工回归步骤为主）  
**Target Platform**: macOS 15.0+（由更新清单声明并强制执行）  
**Project Type**: 单体 macOS App（Xcode 工程：`RustMate.xcodeproj`）  
**Performance Goals**: 更新检查结果在 3 秒内返回（成功/失败/无更新），不阻塞 UI 主线程  
**Constraints**: 不默认引入 XPC；更新源仅允许 HTTPS；错误必须可行动且结构化  
**Scale/Scope**: 1 个 App，2 个更新渠道（stable/beta），1 个设置入口（Settings）

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

用项目宪章（`.specify/memory/constitution.md`）生成并填写以下检查项（不通过则必须在“Complexity Tracking”里说明）：

- **用户价值**：通过“发现更新 → 后台下载 → 提示重启安装”的闭环，P1 旅程可独立验收与演示（无需 Beta 即可完成 MVP）。
- **简化优先 / XPC**：不引入/扩展 XPC（默认进程内更新）；若未来追求完全静默替换，可另立功能评审并说明复杂度成本。
- **安全/沙盒**：涉及网络与外部输入（更新清单/下载 URL/版本字段），必须做来源约束与校验；不涉及额外目录授权或执行外部命令；权限最小化（只读网络获取更新）。
- **可测试**：渠道切换逻辑、URL 构造/校验、状态机与错误映射需要单元测试；更新安装本身以可重复手工步骤回归（写入 quickstart）。
- **结构化结果**：更新状态与错误类型必须结构化建模（供 UI 展示与日志诊断），避免把原始文本当协议。

## Project Structure

### Documentation (this feature)

```text
specs/005-sparkle-auto-update/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
```text
RustMate/
├── RustMateApp.swift
├── Models/
│   └── AppSettings.swift
├── ViewModels/
│   └── SettingsViewModel.swift
├── Views/
│   └── Settings/
│       └── SettingsView.swift
├── Services/
│   └── (现有本地执行/解析/协议服务)
└── Features/
    └── Settings/ (现有 Settings feature 目录)

RustMateTests/
RustMateUITests/
```

**Structure Decision**: 本功能为单体 macOS App 的一部分；更新渠道设置入口落在现有 `SettingsView/SettingsViewModel/AppSettings`，更新器相关逻辑以新增 Service/Coordinator 的形式挂在应用生命周期（`RustMateApp.swift`）中，保持 MVVM 边界清晰、可替换 mock。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | 本功能不引入 XPC、不过度抽象、不增加多项目结构 | N/A |

## Phase 0: Research & Decisions（输出到 `research.md`）

需要在实现前确认并固化的决策点（若与现有工程约束冲突，应在 research 中记录取舍）：

- 更新清单（appcast）字段：如何声明最低系统版本（macOS 15.0）以及版本比较字段策略
- 渠道切换：如何在不重装的情况下让用户在 stable/beta 两个固定 URL 之间切换
- 更新签名与校验：更新包签名字段（EdDSA 等）与是否启用“Signed Appcast”
- GitHub 托管细节：Releases 资产下载 URL 的稳定性；Pages/raw 的缓存与 MIME 类型注意事项

## Phase 1: Design Artifacts（输出到 `data-model.md`、`contracts/`、`quickstart.md`）

- `data-model.md`: 更新渠道偏好、更新状态、错误分类等领域模型（用于 UI 与日志）
- `contracts/`:  
  - `appcast-stable.xml` / `appcast-beta.xml` 的结构约束与字段清单（作为“契约”）  
  - 发布流程契约（“签名→公证→上传→更新清单发布”的步骤与不变量）  
- `quickstart.md`: 可重复的手工验收步骤（切换渠道、触发检查更新、模拟失败场景、验证最低系统版本生效）
