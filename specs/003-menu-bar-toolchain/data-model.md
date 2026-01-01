# Data Model: 菜单栏工具链切换

**Created**: 2026-01-01  
**Feature**: [spec.md](./spec.md)

> 本文描述该功能涉及的“数据实体/状态/校验规则”，不包含具体实现细节。

## Entity: MenuBarToolchainState

**Represents**: 菜单栏展示与交互所需的最小状态集合

**Fields**:
- **currentDefaultToolchainId**: 当前全局默认工具链的标识（字符串）
- **toolchains**: 可选择的工具链列表（`ToolchainOption[]`）
- **status**: 当前状态（`idle` / `loading` / `switching` / `error`）
- **lastUpdatedAt**: 最近一次成功刷新时间（可选）
- **lastError**: 最近一次错误（结构化错误对象或可被映射为用户提示的错误）

**Validation rules**:
- `currentDefaultToolchainId` 必须来自 `toolchains` 的某一项；否则进入 `error` 并触发一次刷新或提示用户重试。

## Entity: ToolchainOption

**Represents**: 菜单栏中可供选择的一个工具链项

**Fields**:
- **id**: 工具链标识（字符串，作为唯一键）
- **displayName**: 用于菜单展示的名称（字符串，可与 `id` 相同）
- **isDefault**: 是否为当前全局默认
- **isSelectable**: 是否可被选择（例如在异常状态下可为 false）

**Validation rules**:
- `id` 必须符合“工具链标识”命名规则（与现有业务一致：仅允许受信输入进入切换路径）。

## Entity: MenuBarActionResult

**Represents**: 菜单栏触发动作（刷新/切换/打开主界面）的结果

**Fields**:
- **actionType**: `refresh` / `switchDefault` / `openMainWindow`
- **status**: `success` / `failure`
- **userMessage**: 可对用户展示的一句话摘要（可选）
- **errorDetail**: 结构化错误信息（失败时，包含原因与建议动作）

## State Transitions

- `idle -> loading`: 启动后首次刷新，或用户手动刷新
- `loading -> idle`: 成功获取 toolchains 与 default
- `loading -> error`: 获取失败（环境/授权/执行/解析）
- `idle -> switching`: 用户选择新默认工具链
- `switching -> idle`: 切换成功并刷新展示
- `switching -> error`: 切换失败（应保持 currentDefaultToolchainId 不变或明确标注未生效）

