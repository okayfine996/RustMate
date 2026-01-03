# Data Model: 玻璃拟态 UI 视觉升级（对齐参考风格）

**Feature**: `004-glass-ui-refresh`  
**Date**: 2026-01-02  
**Scope**: 本特性主要是“视觉与组件模式”升级，不新增业务数据模型；此文档用于把“设计系统”的抽象实体结构化，便于实现与验收一致。

## Entities

### 1) VisualTokenSet

代表一套跨页面一致的视觉 tokens（静态配置，非运行时用户数据）。

- **Fields**
  - `color`: 背景层级、文本、分割线、强调色、状态色（success/warning/error/info）
  - `spacing`: 4/8/12/16/24/32 等间距阶梯
  - `radius`: 卡片/按钮/徽标/弹窗圆角阶梯
  - `stroke`: 细描边策略（透明度、在浅/深色下的等效对比）
  - `elevation`: 阴影/高光层级（卡片、浮层、pressed/hover）
  - `typography`: 标题/正文/注释/徽标字号与字重层级

- **Validation rules**
  - 必须支持浅色/深色两套映射，且关键文本对比度满足可读性要求
  - tokens 数量保持克制，避免“每个页面新增一个特例 token”

### 2) UIPattern

代表可复用的界面模式（组件/组合），用于落地一致性。

- **Fields**
  - `name`: 如 `SummaryCard`、`ToolchainRow`、`StatusBadge`、`SegmentedFilter`、`InlineProgress`
  - `states`: 默认/hover/pressed/disabled/loading/failed（按需）
  - `inputs`: 文本、图标、状态、动作（最多 1~2 个主动作）
  - `layoutRules`: 内边距、对齐、最小高度、长文本截断策略

- **Validation rules**
  - 不依赖长文本堆叠表达状态；状态必须可扫描
  - 主操作在首屏可发现且按钮层级一致

### 3) ScreenCoverageItem

代表“页面覆盖映射”的一条记录，用于验收与回归。

- **Fields**
  - `screen`: Toolchains / Components / Targets / Projects / Tasks / Settings / MenuBar（可选）
  - `patternsUsed`: 本页面应使用的 UIPattern 集合
  - `statesCovered`: 必须覆盖的状态集合（empty/loading/running/failed）
  - `acceptanceChecks`: 可重复的验收点（与 quickstart 的步骤对应）

## Relationships

- `VisualTokenSet` 被所有 `UIPattern` 引用
- `UIPattern` 被多个 `ScreenCoverageItem` 引用（跨页面复用）

## Out of Scope

- 不新增/修改业务实体（Toolchain/Project/Task 等）
- 不改变服务层协议、XPC、执行逻辑或权限模型

