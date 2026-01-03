# Feature Specification: 玻璃拟态 UI 视觉升级（对齐参考风格）

**Feature Branch**: `004-glass-ui-refresh`  
**Created**: 2026-01-02  
**Status**: Draft  
**Input**: User description: "按照这种风格重新优化一下对应的界面"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - 主要页面获得更清晰的层级与“开发者工具感” (Priority: P1)

作为 RustMate 用户，我希望 Toolchains（及其关联操作区）以更清晰、现代、克制的“玻璃拟态 + 卡片化”风格呈现，
让我能更快看清当前全局工具链状态、更新可用性、目录覆盖概览，并能顺畅完成核心操作（安装/更新/设默认/管理）。

**Why this priority**: Toolchains 是核心入口；视觉层级与信息密度直接影响“看见状态→做出动作”的效率。

**Independent Test**: 只改 Toolchains 页面即可独立验收：用户能在不阅读说明的情况下识别全局默认工具链、发现更新入口并完成一次操作。

**Acceptance Scenarios**:

1. **Given** 用户打开主界面并进入 Toolchains，**When** 页面加载完成，**Then** 页面应在首屏清晰呈现“当前全局默认工具链标识”、更新可用概览、目录覆盖概览（若存在），且视觉层级可一眼区分（主标题/摘要/卡片/列表/操作）。
2. **Given** 列表中存在“已安装/可用/可更新”等不同状态的条目，**When** 用户浏览列表，**Then** 每个条目的状态应以统一且非文本堆叠的方式呈现（例如状态徽标/颜色/图标之一），并保证可读性与一致性。
3. **Given** 用户对某条工具链执行关键操作（如安装/更新/设为默认），**When** 操作进行中与结束，**Then** UI 应呈现明确的进行中/成功/失败状态与下一步动作入口（例如查看详情、重试、复制错误摘要），且不以长篇多行输出作为主要信息。

---

### User Story 2 - 跨页面一致性与状态组件统一 (Priority: P2)

作为 RustMate 用户，我希望 Components / Targets / Projects / Tasks / Settings 与 Toolchains 保持统一的导航、卡片、徽标与提示样式，
这样在不同页面间切换时不会产生“换了一个应用”的割裂感，并能在空态/错误态/加载态中得到清晰引导。

**Why this priority**: 一致性是专业感与学习成本的关键；而空态与错误态往往决定用户是否能自助恢复。

**Independent Test**: 仅做跨页面的视觉一致性与状态态样式规范即可验收：随机切换任意两个页面，用户仍能用相同的视觉线索理解状态与下一步动作。

**Acceptance Scenarios**:

1. **Given** 用户在侧边栏依次进入 Toolchains、Components、Targets、Projects、Tasks、Settings，**When** 页面切换，**Then** 导航与内容区的布局规则、字体层级、间距密度、按钮样式、徽标样式应一致，并符合同一套“玻璃拟态/卡片化”语言。
2. **Given** 任一页面出现空数据（例如无项目/无任务/无可用工具链）或加载中状态，**When** 状态出现，**Then** UI 应提供一致的空态/加载态组件（含简短说明与可行动入口），而非留白或难以理解的占位。
3. **Given** 任一页面出现可恢复错误（如权限不足、环境未就绪、操作失败），**When** 错误发生，**Then** UI 应使用统一的错误提示样式，包含“原因摘要 + 建议动作（重试/打开设置/复制信息）”。

---

### User Story 3 - 深浅色与可访问性体验可靠 (Priority: P3)

作为 RustMate 用户（包含视觉需求用户），我希望新的玻璃拟态视觉在浅色/深色模式下都清晰、对比充足、可键盘操作，
并在减少动效/更大字号时仍保持可用与不拥挤。

**Why this priority**: 玻璃拟态最容易踩到“对比不足/信息丢失/动效过度”的坑；可访问性是长期质量底线。

**Independent Test**: 仅通过切换系统外观（浅/深）、字体尺寸、对比度偏好与键盘导航即可独立验收。

**Acceptance Scenarios**:

1. **Given** 系统切换到浅色/深色外观，**When** 用户打开任意核心页面，**Then** 主要信息（标题、状态、主按钮、错误提示）应保持清晰可读，且背景半透明效果不会导致文字与徽标难以辨认。
2. **Given** 用户启用更大字号或减少动效偏好，**When** 用户进行页面切换与关键操作，**Then** UI 不应出现信息被裁切到不可用、关键按钮不可见、或依赖动效才能理解状态的情况。
3. **Given** 用户仅使用键盘进行导航，**When** 在侧边栏与列表/按钮间移动，**Then** 焦点可见且顺序合理，用户可完成至少一个核心任务（例如在 Toolchains 触发“安装/更新/设默认”之一）。

---

### Edge Cases

- 窗口尺寸很小或侧边栏被折叠时，信息层级如何保持（主标题/关键卡片/主操作仍可发现）？
- 工具链名称很长、包含 host triple、或存在大量条目时，列表如何避免拥挤且仍可扫描？
- 菜单栏空间不足/标题被截断时，是否仍能在菜单内清晰看到当前全局工具链与关键操作入口？
- 空态：无安装工具链、无项目、无任务记录时，是否有统一且可行动的引导？
- 错误态：权限不足/环境不可用/操作失败时，是否给出一致的“摘要 + 建议动作”，并避免大段原始输出主导界面？
- 进行中态：连续触发操作或快速切换页面时，进行中提示是否会丢失或造成误判？

## Requirements *(mandatory)*

### Constitution Constraints (mandatory)

- **No-default-XPC**: N/A（纯 UI 视觉与信息呈现优化，不引入新的执行层依赖；现有执行机制保持不变）。
- **Sandbox & Security**: 本特性不得新增权限范围或扩大访问；任何需要用户授权/修复的提示必须保持“最小权限 + 明确解释 + 可行动入口”。
- **Structured Results**: UI 的状态与错误展示必须以结构化信息为主（状态、对象、原因摘要、建议动作），不得依赖原始多行输出作为核心协议或主视觉内容。

### Functional Requirements

- **FR-001（范围）**: 系统 MUST 对以下界面做统一风格升级：Toolchains、Components、Targets、Projects、Tasks、Settings，以及（若已存在）菜单栏弹窗/菜单。
- **FR-002（视觉语言）**: 系统 MUST 定义并应用一套一致的“玻璃拟态 + 卡片化”视觉语言，包括：页面层级（标题/摘要/卡片/列表/操作）、间距密度、图标与徽标、分割线与阴影/边框的使用规则。
- **FR-003（信息架构保持）**: 系统 MUST 保持现有信息架构与功能入口不被破坏；视觉升级不得导致关键操作更难发现或步骤增加（以用户可完成任务为准）。
- **FR-004（状态呈现）**: 系统 MUST 对以下状态提供统一且可复用的呈现：加载中、进行中、成功、失败、空态；并在失败时提供至少一种可行动的下一步（重试/打开设置/复制错误摘要）。
- **FR-005（列表可扫描性）**: 系统 MUST 让用户能在列表中快速区分条目类型与状态（例如默认/已安装/可更新/可用），且在大量条目情况下仍可通过筛选/搜索/分组（如已有）进行定位。
- **FR-006（主操作可发现性）**: 系统 MUST 保证每个页面的主操作在首屏可发现，并使用一致的主次按钮层级。
- **FR-007（错误信息克制）**: 系统 MUST 仅在需要时展示“错误摘要”，并提供“复制详细信息”能力；不得把长文本作为默认展开内容从而破坏简洁性。
- **FR-008（可访问性）**: 系统 MUST 支持浅色/深色模式，并满足可读性与操作性要求（对比充足、焦点可见、键盘可操作、在更大字号/减少动效偏好下保持可用）。

### Assumptions & Dependencies

- 假设现有功能与页面结构已存在（工具链/组件/目标/项目/任务/设置），本特性主要改进“视觉与信息呈现一致性”，不新增核心业务能力。
- 参考风格以用户提供的截图为视觉目标（暗色、卡片化、胶囊筛选、克制的强调色、清晰层级），但最终以“可读性与可访问性优先”。
- 若菜单栏功能尚在开发中，则本特性只要求“风格规范可复用”，菜单栏具体落地可在其对应特性内完成。

### Key Entities *(include if feature involves data)*

- **Visual Style Spec**: 视觉语言规范（层级、间距、颜色/强调色策略、玻璃拟态使用边界、徽标与状态语义）。
- **Reusable UI Patterns**: 可复用的界面模式集合（卡片、列表行、徽标、空态、错误提示、进行中提示、主次按钮层级）。
- **Screen Coverage Map**: 页面覆盖清单（哪些页面/组件已完成升级，哪些复用规范但延后落地）。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001（可发现性）**: 90% 的用户在首次进入 Toolchains 后 5 秒内能指出“当前全局默认工具链”所在位置，并在 10 秒内找到“新增/安装工具链”的入口。
- **SC-002（任务完成率）**: 90% 的用户能在不看说明的情况下完成至少一个核心任务（安装/更新/设默认/管理之一），且主路径点击不超过 3 次关键点击。
- **SC-003（一致性）**: 核心页面（Toolchains/Components/Targets/Projects/Tasks/Settings）在视觉层级、按钮层级、状态提示样式上达到一致（通过设计评审 checklist 全部通过）。
- **SC-004（可访问性）**: 在浅色/深色模式与更大字号/减少动效偏好下，核心信息不丢失且可完成核心任务（通过可访问性验收 checklist 全部通过）。
