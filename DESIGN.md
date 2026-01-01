# RustMate 设计文档（沙盒 SwiftUI + XPC 执行层，面向未来 App Store）

> 本文档基于 `RESEARCH.md` 的研究结论，结合你确认的约束：  
> **(1) 架构选择：B（XPC 通信）**；**(2) 未来希望走 Apple Store 分发（强制沙盒）**；**(3) 不需要日志系统（不做终端/长输出渲染）**。

---

## 1. 项目概述

RustMate 是一个运行在 macOS **App Sandbox** 内的 SwiftUI 应用，提供对 Rust 工具链生态（以 `rustup` 为核心，辅以必要的 `cargo` 查询能力）的可视化管理能力：

- **工具链（toolchain）**：stable / beta / nightly / 自定义 toolchain 的安装、卸载、设为默认、更新。
- **组件（component）**：clippy / rustfmt / rust-src / llvm-tools-preview 等安装与卸载。
- **目标（target）**：wasm32 / aarch64 等 targets 的安装与卸载。
- **项目视图（project context）**：解释当前目录“正在使用哪个 toolchain”及其来源（`rust-toolchain.toml` / rustup override / env / 默认）。

为满足可维护性与并发安全，应用采用 **MVVM +（隔离的）执行层**，其中执行层通过 **XPC** 与 UI 进程解耦：  
UI 负责状态展示与发起请求；执行层负责运行 `rustup`/`cargo`、解析输出、做结果建模与缓存。

---

## 2. 核心约束与关键结论（必须写死）

### 2.1 App Store 约束：必须沙盒

若未来上架 Apple Store：

- App 必须启用 **App Sandbox**。
- 不能依赖“安装到系统上的非沙盒常驻代理”来绕过沙盒（这类能力与分发/审核策略高度冲突）。

> 因此：**XPC 在本设计中主要用于“进程隔离、并发串行化、可测试/可替换的执行层”，而不是“逃逸沙盒”**。

### 2.2 现实限制：沙盒内对 Rust 工具链/项目扫描的能力边界

在沙盒内，RustMate 想要管理 rustup/cargo，通常会遇到：

- 默认无法自由访问 `~/.rustup`、`~/.cargo`、任意项目目录。
- GUI 不继承用户 shell 环境，需要自行构造 PATH/环境变量。
- 对用户项目目录的扫描需要用户授权（Security-Scoped Bookmarks）。

> 因此：未来 App Store 版本必须采用 **“用户授权目录（bookmarks）”** 的路径策略。  
> 早期非上架版本可以扩展为“外部代理/更强能力”，但那属于 **另一个分发渠道的增强模式**。

---

## 3. 需求分析（Requirements）

### 3.1 用户画像

- **Rust 初学者**：希望“点点按钮”完成 toolchain/组件/target 安装；希望解释清楚“为什么当前是 nightly”。
- **多项目开发者**：不同 repo 有不同 override；需要快速切换与查看来源。
- **轻量维护者**：只想更新 toolchain、装 clippy/rustfmt，不想记命令。

### 3.2 功能需求（FR）

#### FR-1 工具链管理（rustup toolchain）
- 展示已安装 toolchain 列表，标注：
  - default toolchain
  - nightly/beta/stable（可从名称推断）
  - host triple（可选）
- 支持操作：
  - 安装 toolchain（stable/beta/nightly/自定义名称）
  - 卸载 toolchain
  - 设为默认 toolchain
  - 更新 toolchain（全量 update 或指定 toolchain update）

#### FR-2 组件管理（rustup component）
- 对“选中的 toolchain”列出组件状态（installed/available）
- 支持安装/卸载组件（最小集合）：
  - rustfmt、clippy、rust-src（MVP）
  - 其他组件后续按需开放（避免 UI 过载）

#### FR-3 目标平台（rustup target）
- 对“选中的 toolchain”列出 targets 状态
- 支持安装/卸载 target

#### FR-4 项目视图（active toolchain / override 解释）
- 用户选择一个项目目录后，展示：
  - active toolchain
  - 来源解释（优先级从高到低）：
    1) `RUSTUP_TOOLCHAIN`（若应用内自定义 env）
    2) `rust-toolchain.toml` / `rust-toolchain`
    3) `rustup override set`（rustup override DB）
    4) 默认 toolchain
- 提供操作（二选一策略，并在设置中固定）：
  - 方案 A：写入 `rust-toolchain.toml`（更显式、可提交到 repo）
  - 方案 B：调用 `rustup override set/unset`（不改 repo 文件）

#### FR-5 任务与进度（不做日志）
- 所有会执行命令的操作都在 UI 显示“任务状态”：
  - running / success / failed / cancelled
  - 显示精简信息：操作名、对象（toolchain/component/target）、开始/结束时间、错误摘要
- 支持取消（尽力而为：对正在运行的 Process 发送 terminate/interrupt）

> 说明：不做“实时日志面板/终端渲染”。但必须返回足够的错误摘要（例如截断后的 stderr）。

### 3.3 非功能需求（NFR）

- **可用性**：首次启动必须能自检 rustup 是否存在，并给出明确修复指引。
- **可靠性**：rustup 输出解析应容错，不因格式小变动崩溃；失败时回退展示原始文本摘要。
- **并发安全**：对 rustup 的操作应串行化（避免锁冲突与状态抖动）。
- **性能**：UI 不因任务执行阻塞；执行层在后台线程完成解析与 IO。
- **安全**：XPC 服务仅接受来自主 App 的连接；对命令与参数做白名单控制（避免被利用执行任意命令）。
- **可测试**：执行层抽象成协议；可注入 Mock 执行器用于 Preview/单测。

---

## 4. 体验与信息架构（IA）

### 4.1 主要页面

- **Toolchains**
  - 列表：已安装 toolchain
  - 详情：版本、default 标记、常用操作按钮
- **Components**
  - toolchain 下组件列表 + 安装/卸载
- **Targets**
  - toolchain 下 targets 列表 + 安装/卸载
- **Projects**
  - 最近项目列表（bookmarks）
  - 当前项目 active toolchain 与来源解释
  - 设置/清除 override
- **Tasks（轻量）**
  - 最近任务列表（成功/失败/取消）
  - 失败任务点开：显示“错误摘要 + 建议修复”
- **Settings**
  - rustup/cargo 路径策略
  - RUSTUP_HOME / CARGO_HOME（可选）
  - override 写入策略（toolchain file vs rustup override）
  - 授权目录管理（bookmarks）

---

## 5. 总体架构

### 5.1 分层（MVVM + Service）

- **SwiftUI Views**
  - 只做展示与用户交互
- **ViewModels（@MainActor）**
  - 持有可观察状态（toolchains/components/targets/projects/tasks）
  - 将用户意图转为 Service 调用
- **Domain Models（纯数据）**
  - `Toolchain` / `Component` / `Target` / `ProjectContext` / `TaskRecord`
- **Service Layer（协议化）**
  - `RustToolchainServiceProtocol`
  - 默认实现通过 XPC Client 调用执行层
- **Execution Layer（XPC Service）**
  - 实际运行 `rustup` / `cargo`，解析并返回结构化结果
  - 串行化执行（Actor/队列）

### 5.2 进程形态（面向 App Store）

#### 形态 1（App Store 推荐）：内置 XPC Service

- RustMate.app（Sandbox）
- RustMateXPC.xpc（与 App 一起签名/打包，运行在独立进程，仍受沙盒约束）

用途：
- 进程隔离（UI 不阻塞）
- 更清晰的权限边界与可测试性
- 执行任务串行化

#### 形态 2（非商店增强模式，未来可选）：外部 Agent（非沙盒/更强能力）

> 本形态不作为 App Store 目标实现的前提条件，仅作为“独立分发版增强能力”的路线保留。  
如果你未来确定要做独立分发版，可在此基础上扩展：更自由的项目扫描、无需频繁授权等。

---

## 6. 沙盒与文件访问策略（App Store 关键）

### 6.1 基本策略：Security-Scoped Bookmarks

RustMate 的“项目视图”与“对项目执行 cargo 命令（可选）”必须依赖用户授权目录：

- 用户在 Projects 页面通过选择目录创建 bookmark
- App 持久化 bookmark（Keychain 或 UserDefaults，建议 Keychain/文件持久化并做加密/校验）
- 使用时 `startAccessingSecurityScopedResource()` 获取临时访问权限

### 6.2 rustup/cargo 位置与 HOME 目录访问

App Store 沙盒内：

- **默认无法访问 `~/.cargo/bin`** 来直接执行 rustup/cargo
- 需要设计“可行路径”：
  - **路径策略 S1（推荐）**：要求用户在 Settings 中选择 `~/.cargo` 或 `~/.cargo/bin` 作为授权目录（bookmark）
  - **路径策略 S2（可选）**：用户手动指定 `rustup` 可执行文件路径（文件选择器拿到 bookmark）

> 设计要点：在 App Store 路线下，**“rustup/cargo 可执行文件本身”也要通过用户授权的方式访问**，否则无法稳定运行。

---

## 7. XPC 接口设计（不做日志版）

### 7.1 设计原则

- **结构化结果优先**：返回模型，不返回大段文本
- **错误摘要**：保留 stderr 的前/后若干 KB，用于 UI 提示
- **命令白名单**：不允许 UI 传任意字符串命令；只允许枚举化的操作 + 参数校验
- **串行执行**：rustup 的写操作必须串行

### 7.2 数据类型（建议）

- `ToolchainInfo`
  - `name: String`
  - `isDefault: Bool`
  - `version: String?`（可通过 `rustc --version` 解析）
  - `installed: Bool`
- `ComponentInfo`
  - `name: String`
  - `isInstalled: Bool`
- `TargetInfo`
  - `triple: String`
  - `isInstalled: Bool`
- `ProjectContextInfo`
  - `projectPath: String`
  - `activeToolchain: String`
  - `reason: String`（enum 映射为 string：env/toolchainFile/overrideDb/default/unknown）
  - `sourcePath: String?`（如 toolchain 文件路径）
- `TaskResult`
  - `exitCode: Int`
  - `stdoutSnippet: String?`
  - `stderrSnippet: String?`
  - `errorMessage: String?`（高层错误）

### 7.3 XPC API（草案）

建议定义一个主协议 `RustMateXPCProtocol`，方法均为 async 风格（XPC completion）。

- **环境与自检**
  - `ping()`
  - `validateEnvironment() -> (hasRustup: Bool, rustupPath: String?, hints: [String])`
- **toolchain**
  - `listToolchains() -> [ToolchainInfo]`
  - `installToolchain(name: String) -> TaskResult`
  - `uninstallToolchain(name: String) -> TaskResult`
  - `setDefaultToolchain(name: String) -> TaskResult`
  - `updateAll() -> TaskResult`
- **component**
  - `listComponents(toolchain: String) -> [ComponentInfo]`
  - `addComponent(toolchain: String, name: String) -> TaskResult`
  - `removeComponent(toolchain: String, name: String) -> TaskResult`
- **target**
  - `listTargets(toolchain: String) -> [TargetInfo]`
  - `addTarget(toolchain: String, triple: String) -> TaskResult`
  - `removeTarget(toolchain: String, triple: String) -> TaskResult`
- **project context**
  - `getProjectContext(projectPath: String) -> ProjectContextInfo`
  - `setProjectOverride(projectPath: String, toolchain: String, mode: String) -> TaskResult`
  - `clearProjectOverride(projectPath: String, mode: String) -> TaskResult`

> 取消：不做日志流时，取消能力可以限制为“当前运行任务的 best-effort terminate”，并在 UI 上提示“取消可能需要几秒生效”。

---

## 8. 执行层实现要点

### 8.1 Process 执行器（无日志流版）

- 使用 `Process` + `Pipe`
- 收集 stdout/stderr（可分别收集，或合并后再做片段截取）
- 设置超时（可选，至少对明显卡死场景要能中断）
- 返回 `TaskResult`：
  - 成功：exitCode = 0
  - 失败：保留 stderrSnippet（截断，例如最大 32KB）

### 8.2 串行化与互斥

执行层内部使用以下任一方式保证 rustup 写操作串行：

- Swift Concurrency `actor RustupExecutor`
- 或单一串行 `DispatchQueue`

读操作（list/show）可并行，但为了简单与稳定，MVP 可以全部串行。

### 8.3 输出解析（容错）

- `rustup toolchain list`：解析 `(default)` 标记
- `rustup show`：解析 `active toolchain` 段落与 `overridden by` 路径
- 解析失败：返回 `unknown` reason + stdoutSnippet 用于 UI fallback

---

## 9. 安全设计

### 9.1 XPC 连接校验

- XPC Service 仅允许主 App 连接（校验签名/TeamID/BundleID）
- 协议版本号：主 App 与 XPC service 握手返回版本，不匹配则提示升级

### 9.2 命令白名单与参数校验

执行层只允许以下命令集合：

- `rustup toolchain ...`
- `rustup component ...`
- `rustup target ...`
- `rustup show`
- （可选）`rustc --version` / `cargo --version`

并对参数做校验：

- toolchain 名称：允许 `[A-Za-z0-9._-]+`，限制长度
- target triple：同上
- projectPath：必须是目录且在 bookmark 授权范围内（App Store 路线）

---

## 10. 状态刷新与一致性

由于用户可能在 App 外用终端修改 rustup 状态：

- **刷新时机（MVP）**
  - App 启动
  - App 回到前台
  - 任何写操作完成后
- **更高级（后续）**
  - 监听 `~/.rustup/toolchains` 变动（App Store 路线下需先获得对 `~/.rustup` 的授权）

---

## 11. 错误处理与用户提示（无日志版）

统一错误分层：

- **用户可行动错误**（可给出修复步骤）
  - rustup 不存在 / 无法执行（提示安装 rustup、或在设置中选择 rustup 路径）
  - 权限不足（提示去 Projects/Settings 授权目录）
  - 网络问题（rustup 下载失败，提示重试/检查代理）
- **系统/未知错误**
  - 保留 `stderrSnippet`，提供“复制错误信息”按钮

---

## 12. 可测试性与依赖注入

定义协议：

- `RustToolchainServiceProtocol`
- `ProjectContextServiceProtocol`

并提供：

- `XPC*Service`：真实实现
- `Mock*Service`：用于 SwiftUI Preview 与单元测试

ViewModel 只依赖协议，避免直接引用 XPC 细节。

---

## 13. 里程碑建议（按你当前选择优化）

### M0：架构打底（1 周）
- MVVM 骨架
- XPC Service target 建立（App Store 形态）
- `ping/validateEnvironment`

### M1：工具链 MVP（1–2 周）
- list/install/uninstall/setDefault/updateAll
- 任务列表（无日志，只有状态与错误摘要）

### M2：组件与 target（1–2 周）
- components/targets 列表与安装卸载
- 失败提示打磨

### M3：项目视图（1–2 周）
- Projects（bookmarks）管理
- active toolchain + override 来源解释
- set/clear override（固定一种策略）

---

## 14. 风险清单（需要提前接受）

- **App Store 路线下**：必须依赖用户授权访问 `~/.cargo/bin`（或 rustup 可执行文件）以及项目目录；否则 rustup/cargo 无法稳定运行。
- **XPC Service 仍在沙盒内**：它能带来隔离与工程质量，但不能天然突破沙盒权限。
- **rustup 输出变化**：解析需要持续维护，必须准备 fallback 与测试样本库。

---

## 15. 待你确认的实现决策（写进 README/Settings）

1) **override 策略**：  
   - A：写 `rust-toolchain.toml`（推荐：可解释、可提交）  
   - B：`rustup override set/unset`（不改 repo）

2) **rustup 路径策略（App Store）**：  
   - 让用户选择 `rustup` 可执行文件  
   - 或授权 `~/.cargo/bin` 并自动解析

3) **是否支持 cargo（MVP）**：  
   - 只做 rustup（更稳）  
   - 或增加 `cargo metadata --no-deps`（只读能力）


