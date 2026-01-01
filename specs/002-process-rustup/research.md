# Research: Sandboxed Direct Rustup Execution

**Feature**: `specs/002-process-rustup/spec.md`  
**Date**: 2026-01-01

## Goal

在不依赖 XPC 的前提下，让沙盒内主 App 能稳定执行 rustup，并且把所有文件访问严格限制在
用户选择并授权的 security-scoped bookmark 范围内。

## Key Decisions

### Decision 1: 执行层由 XPC 改为主进程本地执行

**Decision**: 以主 App 内部执行层为主（`Process`/异步封装），XPC 不再作为执行前置依赖。  
**Rationale**:

- 降低架构复杂度与调试成本，减少 XPC 连接/协议/签名校验等额外面
- 与宪章“简化优先 / 不默认 XPC”一致

**Risks / Mitigations**:

- 风险：沙盒下子进程的文件访问行为与 security-scoped 访问的继承关系存在不确定性  
  - 缓解：优先做“最小可行验证”（授权后执行 `rustup --version` + 读取最基本状态）作为早期 gate
  - 缓解：把执行失败的错误分类细化为“缺少授权/可执行不可访问/数据目录不可访问/执行失败”，便于定位

### Decision 2: 授权范围采用“最小集合 + 可扩展”

**Decision**: 将授权拆成多个目的（purpose），并允许用户分别授权/重置：

- `rustup executable`：rustup 可执行文件所在位置（或其目录）
- `cargo home`：`.cargo`（至少包含 `bin`）
- `rustup home`：`.rustup`
-（可选）项目目录：仅当功能需要读取项目上下文/写入 `rust-toolchain.toml` 时才要求授权

**Rationale**:

- rustup 的“可执行路径”与“数据目录”是两类不同资源，必须分别覆盖才能稳定工作
- 最小授权集合更审核友好，也更符合“最小权限原则”

### Decision 3: 结果与错误以结构化模型呈现（输出摘要化）

**Decision**: 执行层返回统一的结构化结果（成功/失败、错误分类、建议修复、关键数据摘要），
而不是把 stdout/stderr 原样长文本作为 UI 主要内容。

**Rationale**:

- 避免 UI 对多行输出的耦合与脆弱性
- 避免大输出造成内存/卡顿
- 与既有 `TaskResult/TaskRecord` 模型方向一致

## Alternatives Considered

- **继续使用 XPC**：可行，但复杂度更高（协议/连接/校验/两端同步/测试成本）。与当前宪章不符，故拒绝。
- **放弃沙盒**：不审核友好，与目标冲突，拒绝。

## Open Validation Items (must prove early)

- 授权后运行 rustup 的最小验证用例是否能在沙盒环境稳定通过
- 授权不足时是否能稳定检测并给出可行动提示

