<!--
Sync Impact Report
- Version change: TEMPLATE → 1.0.0
- Modified principles: N/A (initial ratification)
- Added sections: Core Principles; Architecture Constraints; Development Workflow; Governance
- Removed sections: N/A (template placeholders removed)
- Templates requiring updates:
  - ✅ `.specify/templates/plan-template.md`
  - ✅ `.specify/templates/spec-template.md`
  - ✅ `.specify/templates/tasks-template.md`
  - ✅ `.specify/templates/checklist-template.md`
- Follow-up TODOs:
  - TODO(RATIFICATION_DATE): 首次通过宪章的日期未知，需要补齐
-->

# RustMate Constitution

## Core Principles

### I. 以用户价值为先（迭代可交付）

- 每个功能必须以可演示的用户旅程定义（P1/P2/P3），并能独立验收。
- 任何“为架构而架构”的改动必须有明确的用户价值或风险缓解（安全/可靠性/合规）。

### II. 简化优先（当前不默认使用 XPC）

- 当前阶段**不把 XPC 作为默认方案**：新功能不得以“需要 XPC”作为前提。
- 只有在出现明确、可验证的收益时才允许引入/扩展 XPC（例如：强隔离、崩溃隔离、并发模型更清晰）。
- 如果确实需要 XPC，必须在计划文档中给出：
  - 不能用单进程/进程内服务满足的原因
  - 替代方案对比与拒绝理由
  - 额外复杂度与测试/发布成本评估

### III. 安全与沙盒边界不可妥协

- 对外部命令/路径/参数必须进行白名单校验或严格约束，禁止拼接未验证输入形成命令执行。
- 涉及文件系统权限的功能必须通过用户授权的目录（例如 security-scoped bookmark），且最小权限原则。
- 不引入“试图逃逸沙盒”的实现或文案；任何权限提升相关需求必须先形成书面评审结论。

### IV. 可测试与可回归（优先小而确定的测试）

- 解析器/格式转换等纯逻辑必须有单元测试覆盖（使用 fixtures）。
- 对跨模块边界（例如 service 层、执行层、序列化协议）的变化，必须有至少一种可回归验证方式：
  - 单元测试、契约测试、或可重复的手工验收步骤（写入 quickstart）。
- 长耗时/易失败操作必须有清晰错误建模（用户可理解、可行动），而不是仅输出原始文本。

### V. 可观测但不过度（结构化结果优先）

- 对外暴露的结果以结构化状态/错误为主（例如：成功/失败、错误码、建议修复），避免把多行输出当 UI。
- 日志用于调试与定位问题，但不得作为核心业务协议（避免对日志文本耦合）。

## Architecture Constraints

- **默认架构**：SwiftUI + MVVM + 协议化 Service（可替换 mock），以进程内实现为主。
- **并发与响应**：任何可能阻塞的操作不得在 UI 主线程执行；需要明确取消/超时策略。
- **外部命令执行（若存在）**：
  - 必须明确可执行文件定位策略（避免依赖不稳定的环境）
  - 必须对输出做上限控制与摘要化（防止内存/卡顿）
  - 必须对错误进行分类与用户提示（含建议修复）

## Development Workflow

- 以规格驱动：`spec.md` → `plan.md` → `tasks.md`，且在关键节点做宪章检查（见模板）。
- 变更范围控制：优先小 PR；一次 PR 只解决一个核心问题，减少跨层大改。
- 文档同步：对外行为/接口/权限模型变化必须同步到 quickstart/合同或相应说明文档。

## Governance

- 宪章是最高优先级规则：当与其它文档冲突时，以宪章为准，并在相应文档中修正。
- 修订流程：
  - 提出变更动机与影响范围（含与现有实现/文档的冲突点）
  - 评审通过后更新版本号与日期，并同步更新相关模板
- 版本策略（SemVer）：
  - MAJOR：原则被移除/重新定义（破坏性治理变更）
  - MINOR：新增原则或新增强制性章节
  - PATCH：澄清、措辞调整、非语义改动
- 审查要求：每次计划/规格/任务生成必须进行“Constitution Check”，若有违反必须显式记录与论证。

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): 首次通过宪章的日期未知 | **Last Amended**: 2026-01-01
