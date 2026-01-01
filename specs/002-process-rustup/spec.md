# Feature Specification: Sandboxed Direct Rustup Execution

**Feature Branch**: `002-process-rustup`  
**Created**: 2026-01-01  
**Status**: Draft  
**Input**: User description: "现在需要实现 主 App 保持沙盒（审核友好）使用 Process 直接调用 rustup 可执行文件 ，而不是走xpc。所有 rustup / .cargo / .rustup 的访问都通过用户选择 + security-scoped bookmark 授权（合规且稳定）所以必须把“授权范围”做对。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 首次授权并成功使用核心功能 (Priority: P1)

作为用户，我希望在不退出沙盒、不依赖 XPC 的前提下，完成一次“授权→执行→得到结构化结果”的闭环，
从而让我可以继续使用 RustMate 的核心 rustup 功能（例如读取工具链列表等）。

**Why this priority**: 这是所有 rustup 功能的前置条件；授权范围正确与否直接决定可用性与审核友好程度。  

**Independent Test**: 新安装状态下启动 App，按引导完成授权后触发一次最小 rustup 操作，看到成功结果。  

**Acceptance Scenarios**:

1. **Given** 用户从未授权过任何相关目录，**When** 用户尝试执行需要访问 rustup 的操作，**Then** 系统必须提示并引导用户完成必要授权，且在授权完成后该操作可成功返回结构化结果。
2. **Given** 用户已授权必要目录，**When** 用户再次执行相同操作，**Then** 系统无需重复授权流程即可完成执行，并返回结构化结果。

---

### User Story 2 - 授权失败/不足时的可恢复体验 (Priority: P2)

作为用户，我希望当我拒绝授权、授权了错误目录、或授权失效时，App 能明确告诉我缺了什么权限并提供重试，
而不是静默失败或给出难以理解的错误。

**Why this priority**: 文件权限与 rustup 安装位置在不同用户机器上差异较大，必须可恢复。  

**Independent Test**: 故意拒绝或选择错误目录，验证 App 的错误提示与重试路径。  

**Acceptance Scenarios**:

1. **Given** 用户在授权流程中点击取消/拒绝，**When** 继续执行需要 rustup 的操作，**Then** 系统必须给出明确提示（缺少授权）并提供再次授权入口。
2. **Given** 用户选择的目录不足以完成操作（例如缺少 rustup 可执行文件或所需数据目录），**When** 执行操作，**Then** 系统必须提示“当前授权范围不足/选择错误”，并引导用户重新选择正确目录。

---

### User Story 3 - 可见、可管理的授权范围 (Priority: P3)

作为用户，我希望能在设置里看到当前已授予的访问范围，并可以主动重新授权或清除授权，
以便我理解 RustMate 访问了哪些路径并保持可控。

**Why this priority**: 这是合规与信任的关键，避免“权限黑盒”。  

**Independent Test**: 在设置页查看授权状态，执行一次“重新授权/清除”后再触发操作验证效果。  

**Acceptance Scenarios**:

1. **Given** 用户已完成授权，**When** 打开设置页，**Then** 能看到当前授权状态（已授权/未授权/已失效）以及重新授权入口。
2. **Given** 用户清除授权后，**When** 再次触发 rustup 操作，**Then** 系统必须重新要求授权。

### Edge Cases

- 用户系统未安装 rustup，或 rustup 不在默认位置：App 必须提供明确提示与可执行的修复建议（例如“请安装 rustup 或在授权流程中选择 rustup 所在位置”）。
- 安全书签失效（例如系统重置、路径变化、权限撤销）：App 必须检测到并要求重新授权。
- 用户授权了 `.cargo` 但未包含 `bin`（或反之）导致可执行文件不可访问：必须提示“授权范围不足/错误”。
- 用户同时存在多种安装方式（官方 rustup、Homebrew 等）导致路径冲突：用户应能通过选择流程明确指定要使用的 rustup 来源。
- 执行失败（权限不足、目标不存在、网络失败等）：错误必须结构化呈现并包含可行动建议。

## Requirements *(mandatory)*

### Constitution Constraints (mandatory)

- **No-default-XPC**: 本功能必须在不依赖 XPC 的前提下达成目标；不得把 XPC 作为默认方案或前置条件。
- **Sandbox & Security**: 所有对 `rustup` 可执行文件与其数据目录的访问，必须建立在用户显式选择并授予的授权范围之上，且权限最小化。
- **Structured Results**: 对用户展示的结果必须是结构化状态/错误与可行动建议，不依赖原始多行输出作为 UI 协议。

### Functional Requirements

- **FR-001**: 系统必须在主 App（沙盒内）执行 rustup 相关操作，并且不依赖 XPC 服务作为执行前提。
- **FR-002**: 系统必须在执行前校验“当前授权范围是否满足该操作所需访问”，不足时必须引导用户补齐授权。
- **FR-003**: 系统必须支持用户通过交互式选择来授予对以下资源的访问（最小集合，可随需求扩展）：
  - rustup 可执行文件所在位置（或其可被访问的父目录）
  - rustup 数据目录（例如 `.rustup`）
  - cargo 相关目录（例如 `.cargo`，包含 `bin` 等必需内容）
- **FR-004**: 系统必须持久化用户授权，以便下次启动无需重复授权；同时必须能检测授权失效并要求重新授权。
- **FR-005**: 系统必须提供一个可见的授权管理入口（查看状态、重新授权、清除授权）。
- **FR-006**: 系统必须对所有执行结果提供结构化反馈：
  - 成功：明确的成功状态与必要的关键数据
  - 失败：错误分类（例如“缺少授权/找不到 rustup/执行失败”）与建议修复
- **FR-007**: 系统必须确保授权范围最小化：只访问用户选择的路径，不在未授权范围内扫描/读取用户文件。

### Key Entities *(include if feature involves data)*

- **AuthorizedPath**: 用户已授权的路径/资源的记录（用于展示状态与触发重新授权）。
- **ExecutionResult**: 一次 rustup 操作的结构化结果（成功/失败、错误分类、建议修复、关键数据摘要）。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 新用户在首次启动后，能在 2 分钟内完成授权并成功完成一次核心 rustup 操作（P1 用户故事）。
- **SC-002**: 当授权缺失/失效时，用户能在 1 次交互内到达“重新授权”入口，并在补齐后成功重试。
- **SC-003**: 用户在设置页能清晰理解当前授权状态（已授权/未授权/失效）且能自行清除授权。
- **SC-004**: 在常见失败场景（未安装/路径错误/权限不足）下，错误提示包含明确原因与可执行的下一步动作。
