# Contract: Component Patterns（可复用 UI 模式）

**Feature**: `004-glass-ui-refresh`  
**Date**: 2026-01-02  
**Purpose**: 把参考风格拆成可复用的组件/组合模式，避免每个页面各自实现。

## 1) Summary Cards（概览卡片）

- **用途**: Toolchains 首屏显示关键概览（Active Global / Updates Available / Directory Overrides）
- **结构**: 图标 + 标题（短）+ 主数值/主信息 + 次要说明（可选）
- **状态**: normal / loading / empty（无数据时提供引导动作）
- **动作**: 卡片整体可点击或右侧提供 secondary action（最多 1 个）

## 2) List Row（主列表行）

- **用途**: toolchains/components/targets 等条目列表
- **结构**: 左：符号/状态条；中：主标题 + 次信息（版本/使用项目数）；右：主操作按钮（Manage/Install/Update）
- **规则**:
  - 状态必须可扫描（徽标/颜色/图标）
  - 主操作按钮位置固定，减少列表跳动

## 3) Status Badge（状态徽标）

- **用途**: DEFAULT / INSTALLED / AVAILABLE / UPDATE 等
- **规则**: 文案短；颜色与语义一致；深浅色保持对比

## 4) Segmented Filter / Chips（胶囊筛选）

- **用途**: All / Stable / Beta / Nightly 等过滤
- **规则**: 选中态明确；hover/pressed 清晰；不与 primary action 竞争注意力

## 5) Inline Progress（行内进度）

- **用途**: 安装/更新/切换进行中
- **规则**: 进度提示不遮挡主信息；完成后有成功/失败反馈入口

## 6) Error Callout（错误提示块）

- **结构**: 图标 + 摘要（1~2 行）+ 建议动作（重试/设置/复制）
- **规则**: 不默认展开长文本；允许“复制详情”作为辅助入口

