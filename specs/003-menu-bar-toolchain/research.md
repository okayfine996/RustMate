# Research: 菜单栏工具链切换

**Created**: 2026-01-01  
**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Decision 1: 菜单栏入口实现方式

**Decision**: 采用 SwiftUI 原生的菜单栏入口能力作为首选实现路径，并在需要更强控制时保留落回 AppKit 菜单栏项的备选方案。

**Rationale**:
- RustMate 已是 SwiftUI App，菜单栏入口应尽量复用现有 UI 架构与状态管理方式，减少跨框架胶水代码。
- 菜单栏交互以“显示当前状态 + 选择切换项 + 唤起主界面”为主，复杂度适中，适合使用原生的 SwiftUI 菜单栏能力承载。

**Alternatives considered**:
- 纯 AppKit `NSStatusItem` + `NSMenu`：控制力更强，但需要更多桥接与生命周期管理；作为备选方案保留。

## Decision 2: 获取“当前全局默认工具链”的数据源

**Decision**: 复用现有工具链 service 的“列出工具链”能力，以列表中 `isDefault` 标记作为“当前全局默认工具链”的权威来源。

**Rationale**:
- 现有 service 已包含沙盒授权校验、参数约束、输出解析与结构化错误建模，复用可降低安全与稳定性风险。
- UI 层已有 `ToolchainInfo.isDefault` 的用法（主界面默认选择），利于一致性与复用。

**Alternatives considered**:
- 通过单独的“查询当前默认工具链”命令/解析路径：可能更快，但会引入新的解析与错误面；在未证明必要前不增加额外路径。

## Decision 3: 切换并发与用户可见策略

**Decision**: 菜单栏切换操作在任一时刻只允许一个进行中；新请求到来时采取一致策略（例如提示“正在切换中”或将新请求排队），并将状态明确呈现给用户。

**Rationale**:
- 避免并发切换导致“显示状态与实际默认工具链不一致”的风险。
- 满足宪章对“可观测、结构化结果、避免 UI 卡顿”的要求：用户需要清楚知道当前是否在切换以及结果是什么。

**Alternatives considered**:
- 允许并发切换：实现复杂，且不符合菜单栏的“快速、确定”的用户期望。

## Decision 4: “唤起主界面”的行为定义

**Decision**: 从菜单栏触发时，确保 RustMate 主界面被置于前台并可交互；若已打开则切回/置前；若未打开则打开。

**Rationale**:
- 与用户预期一致：菜单栏“打开 RustMate”应总是把窗口带到前面。
- 与现有 AppState/Settings 唤起逻辑相容（已有通知驱动的“OpenSettings”路径）。

**Alternatives considered**:
- 仅激活 App 不保证窗口可见：可能导致用户认为“点击无效”，不满足可用性目标。

