# Contract: UI Style Spec（玻璃拟态 + 卡片化）

**Feature**: `004-glass-ui-refresh`  
**Date**: 2026-01-02  
**Purpose**: 定义可执行的 UI 视觉规范（tokens + 规则），让实现与验收可对齐。

## 1) 视觉目标（参考风格）

- 暗色为主的“开发者工具感”
- 卡片化信息层级（标题/摘要/概览卡/列表）
- 玻璃拟态克制使用：用于容器/浮层层级，不牺牲可读性
- 胶囊筛选（segmented / chips）与清晰主次按钮

## 2) Tokens（最小集合）

> 具体值以实现时统一定义为准；本 contract 约束“层级与使用规则”，避免每页自定义。

- **Color layers**
  - `bg.canvas`: 页面底
  - `bg.surface`: 卡片底（可轻微透明）
  - `bg.elevated`: 浮层/弹窗（更明显层级）
  - `text.primary / secondary / tertiary`
  - `stroke.subtle`: 细描边（用于玻璃边缘与分割）
  - `accent.primary`: 主强调色（克制使用）
  - `status.success / warning / error / info`

- **Spacing**
  - 基础单位 4；常用阶梯：8/12/16/24/32

- **Radius**
  - 卡片：12–16
  - 按钮/胶囊：999（或等效）
  - 弹窗：16+

- **Elevation**
  - `e0`: 无阴影（列表行）
  - `e1`: 卡片轻阴影/高光
  - `e2`: 浮层更明确阴影/高光

## 3) 规则（必须遵守）

- **R-001（对比度）**: 标题/主按钮/关键状态必须在浅/深色下保持高对比；玻璃效果不能让文字变灰糊。
- **R-002（克制玻璃）**: 大面积背景不使用强 blur；玻璃只用于容器层级与浮层强调。
- **R-003（状态可扫描）**: success/failed/available 等状态不能只靠文本；必须有徽标/图标/颜色之一。
- **R-004（主次按钮）**: 每屏最多 1 个 primary action，其余为 secondary/tertiary；避免多处“同等重要”按钮。
- **R-005（长文本）**: 路径/版本/名称过长必须有一致的截断与 tooltip/详情入口策略。

## 4) 验收点（抽样即可）

- Toolchains 首屏：标题 + 摘要 + 2~3 张概览卡 + 列表；层级一眼可辨
- 胶囊筛选：选中态与 hover/pressed 明确
- 错误提示：摘要 + 建议动作（重试/设置/复制）一致，且不默认展开长文本

