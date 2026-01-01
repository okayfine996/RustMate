# Contract: Local Rustup Execution (In-App)

**Feature**: `specs/002-process-rustup/spec.md`  
**Date**: 2026-01-01

## Purpose

定义“主 App 内本地执行层”的行为边界与输入/输出约束，确保 UI/VM/Service 层可以在不依赖 XPC 的情况下
执行 rustup，并得到结构化结果。

## Preconditions

- 执行任何 rustup 操作前，必须完成必要授权检查（详见 `bookmark-authorization.md`）。
- 执行必须是异步的，不能阻塞 UI 主线程。

## Operations (logical)

执行层需支持与现有协议等价的操作集合（按既有 `RustToolchainServiceProtocol` / `ProjectContextServiceProtocol`）：

- Toolchains: list / install / uninstall / setDefault / updateAll / updateOne
- Components: list / add / remove
- Targets: list / add / remove
- Project Context: detect / setOverride / clearOverride（若该 feature 范围内需要）

## Output Contract

- 所有操作必须返回结构化结果：
  - 成功：包含必要数据（例如 toolchains 列表）或任务成功状态
  - 失败：必须分类（缺少授权 / 找不到 rustup / 执行失败 / 解析失败），并给出建议修复
- 输出（stdout/stderr）如需展示，只能作为可选摘要，并且必须截断（避免大输出导致内存与 UX 问题）

## Security Contract

- 执行层不得在未授权范围内扫描用户文件系统
- 只能访问用户显式授权的资源根（bookmark），并且在使用期内正确开启/关闭 security-scoped 访问

