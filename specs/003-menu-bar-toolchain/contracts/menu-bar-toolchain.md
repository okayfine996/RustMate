# Contract: Menu Bar Toolchain Interactions

**Created**: 2026-01-01  
**Feature**: [spec.md](../spec.md)

> 说明：本项目不是 Web/API 产品，不适用 OpenAPI/GraphQL。此处用“交互契约”方式描述 UI ↔ Service 的输入/输出与错误语义，确保可回归与一致性。

## Contract 1: Load menu bar state (current default + options)

**Trigger**:
- App 启动后初始化菜单栏
- 用户手动刷新
- 切换完成后强制刷新

**Input**:
- 无（使用当前 App 的 settings/授权上下文）

**Output (success)**:
- `toolchains`: 工具链选项列表（至少包含 `id/displayName/isDefault`）
- `currentDefaultToolchainId`: 当前默认的工具链标识（应与某一 `toolchains[i].id` 对应）

**Output (failure)**:
- 结构化错误，包含：
  - **category**: 可用于 UI 路由（例如：需要授权 / 环境异常 / 执行失败 / 解析失败）
  - **title/message**: 用户可理解的描述
  - **suggestedFix**: 至少一种建议动作（例如：重试、打开主界面/设置完成授权）

## Contract 2: Switch global default toolchain

**Trigger**:
- 用户在菜单栏选择目标工具链

**Input**:
- `toolchainId`: 目标工具链标识（必须是“受信”的既有选项或通过严格校验的输入）

**Output (success)**:
- 结构化任务结果（成功/耗时/摘要）
- 随后应触发一次状态刷新，以确保菜单栏展示与系统一致

**Output (failure)**:
- 结构化任务结果（失败/原因/建议动作）
- 菜单栏展示必须保持为“切换前默认工具链”（或明确标注切换未生效）

## Contract 3: Open main window

**Trigger**:
- 用户在菜单栏点击“打开 RustMate”

**Input**:
- 无

**Output**:
- RustMate 主界面窗口应可见并置于前台（可交互）

