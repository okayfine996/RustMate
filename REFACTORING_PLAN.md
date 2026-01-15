# RustMate 代码重构计划

## 项目概览

**项目规模**: ~20,816 行 Swift 代码
**架构模式**: MVVM + Service Layer + Local Process Execution
**评审日期**: 2026-01-15
**评审人**: Claude Code (Refactor Skill)

---

## 执行摘要

经过全面的代码审查，RustMate 项目整体架构合理，遵循了 MVVM 模式和依赖注入原则。但存在以下主要问题需要重构：

### 🔴 高优先级问题（影响可维护性和可靠性）
1. **过度使用全局通知中心** - 导致隐式依赖和难以追踪的数据流
2. **重复的代码模式** - ViewModels 中任务跟踪逻辑重复
3. **不一致的错误处理** - 混合使用 NSError 和自定义错误类型
4. **死代码存在** - Item.swift 是 Xcode 模板残留，未使用

### 🟡 中优先级问题（影响代码质量）
5. **状态管理分散** - UserDefaults 直接访问散落各处
6. **魔法字符串过多** - 通知名称、UserDefaults 键没有统一管理
7. **ViewModel 责任过重** - 部分 ViewModel 包含过多业务逻辑
8. **安全作用域资源管理复杂** - 多处手动管理，容易泄漏

### 🟢 低优先级问题（优化改进）
9. **测试覆盖率不足** - 缺少核心业务逻辑的单元测试
10. **代码注释不一致** - 部分关键逻辑缺少文档

---

## 第一部分：代码质量问题详细分析

### 1. 全局通知中心过度使用 🔴

**问题描述**:
项目中大量使用 `NotificationCenter.default.post` 进行组件间通信，发现了以下通知：

```swift
// 发现的通知名称（散落在不同文件中）
- "OpenMainWindow"
- "SetupCompleted"
- "AuthorizationCompleted"
- "OpenSettings"
- "AuthorizationRequired"
- "SettingsReset"
- "AllAuthorizationsCompleted"
```

**影响**:
- ❌ 隐式依赖：很难追踪谁发送、谁接收
- ❌ 类型不安全：通过字符串传递，容易拼写错误
- ❌ 维护困难：重构时很难找到所有相关代码
- ❌ 测试困难：难以 mock 和验证通知流
- ❌ 竞态条件：通知的执行顺序不可预测

**代码示例**（当前）:
```swift
// RustMateApp.swift:243
NotificationCenter.default.post(name: NSNotification.Name("SettingsReset"), object: nil)

// RootView:307
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AuthorizationRequired"))) { _ in
    print("🔐 RootView: Authorization required, switching to setup flow")
    appState.needsSetup = true
}
```

**代码气味**:
- **Message Chains**: 通知传递链路长且不透明
- **Middle Man**: NotificationCenter 成为中间人
- **Inappropriate Intimacy**: 通过全局通知耦合组件

---

### 2. ViewModels 中重复的任务跟踪逻辑 🔴

**问题描述**:
在 `ToolchainViewModel.swift`、`ComponentsViewModel`、`TargetsViewModel` 等多个 ViewModels 中，发现几乎相同的任务跟踪代码模式：

```swift
// 重复模式 1: 创建任务记录
let taskId = UUID()
let runningTask = TaskRecord(
    id: taskId,
    operation: "install",
    target: name,
    status: .running,
    startTime: Date()
)

// 重复模式 2: 跟踪任务开始
await trackTaskStarted(runningTask)

// 重复模式 3: 执行操作
let result = try await service.installToolchain(name: name)

// 重复模式 4: 创建完成任务
let completedTask = TaskRecord(
    id: taskId,
    operation: "install",
    target: name,
    status: result.status,
    // ... 更多字段
)

// 重复模式 5: 跟踪任务完成
await trackTaskCompleted(completedTask)
```

**影响**:
- ❌ 代码重复：估计 100+ 行重复代码
- ❌ 维护负担：修改任务跟踪逻辑需要同步修改多处
- ❌ 易错：容易遗漏某个步骤或不一致
- ❌ 违反 DRY 原则

**代码气味**:
- **Duplicate Code**: 高度相似的代码块在多个类中重复
- **Long Method**: 操作方法过长（包含任务跟踪样板代码）

**受影响文件**:
- `ToolchainViewModel.swift`: 5 个操作方法重复
- `ComponentsViewModel.swift`: 类似模式
- `TargetsViewModel.swift`: 类似模式
- `ProjectsViewModel.swift`: 类似模式

---

### 3. 不一致的错误处理 🔴

**问题描述**:
项目中混合使用了多种错误处理策略：

1. **自定义错误类型**: `RustupExecutionError`, `AuthorizationError`
2. **NSError 手动创建**:
```swift
// ProjectsViewModel.swift:73
error = NSError(domain: "RustMate", code: -1, userInfo: [
    NSLocalizedDescriptionKey: "Project directory not found..."
])
```
3. **直接抛出 Swift Error**: 部分代码直接抛出通用错误

**影响**:
- ❌ 错误处理不统一：UI 层难以区分错误类型
- ❌ 用户体验差：某些错误缺少友好提示
- ❌ 调试困难：错误信息格式不一致
- ❌ 国际化困难：错误消息硬编码

**代码示例**（当前）:
```swift
// 方式 1: 自定义错误（推荐）
throw RustupExecutionError.executionFailed(
    command: "rustup toolchain list",
    exitCode: result.exitCode,
    stderr: result.stderr,
    suggestedFix: "Check that rustup is working correctly..."
)

// 方式 2: NSError（不推荐，但项目中大量使用）
error = NSError(domain: "RustMate", code: -1, userInfo: [...])

// 方式 3: 通用 Error（最不推荐）
catch {
    self.error = error  // 丢失类型信息
}
```

**代码气味**:
- **Inconsistent Error Handling**: 错误处理策略不统一
- **Primitive Obsession**: 过度使用 NSError 而不是领域特定错误类型

---

### 4. 死代码和未使用的模板文件 🔴

**问题描述**:
发现 Xcode 项目模板生成的死代码：

```swift
// Item.swift - 完全未使用的 SwiftData 模型
@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
```

**影响**:
- ❌ 增加项目复杂度
- ❌ 误导新开发者
- ❌ 增加编译时间（微小）
- ❌ 违反 YAGNI 原则

---

### 5. UserDefaults 直接访问分散 🟡

**问题描述**:
`UserDefaults.standard` 直接访问散落在 14 处，包括：

```swift
// ProjectsViewModel.swift:28
var overrideMode: String {
    get {
        UserDefaults.standard.string(forKey: "overrideMode") ?? "toolchainFile"
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "overrideMode")
    }
}

// RustMateApp.swift:222
let hasCompletedFirstLaunch = UserDefaults.standard.bool(forKey: firstLaunchKey)
```

**影响**:
- ❌ 魔法字符串：键名硬编码，容易拼写错误
- ❌ 难以测试：依赖全局单例
- ❌ 不方便迁移：如果未来要改用其他存储方案（如 Keychain、SwiftData），需要修改多处
- ❌ 类型安全性差：没有编译时检查

**代码气味**:
- **Primitive Obsession**: 直接使用字符串键而不是类型安全的包装
- **Shotgun Surgery**: 修改存储策略需要多处改动

---

### 6. 魔法字符串和魔法数字 🟡

**问题描述**:
项目中存在大量魔法字符串：

```swift
// 通知名称
"OpenMainWindow"
"SetupCompleted"
"AuthorizationRequired"

// UserDefaults 键
"overrideMode"
"RustMate.hasCompletedFirstLaunch"
"RustMate.AppSettings"
"projectBookmarks"

// 其他字符串常量
"com.finefine.RustMate.bookmarks"  // Keychain service name
```

**影响**:
- ❌ 拼写错误：运行时才能发现
- ❌ 重构困难：查找替换容易遗漏
- ❌ 缺少文档：字符串本身没有语义
- ❌ 难以发现重复：无法通过编译器检查

**代码气味**:
- **Magic Number/String**: 硬编码的字面量没有命名

---

### 7. ViewModel 职责过重 🟡

**问题描述**:
部分 ViewModel 包含了过多的业务逻辑，例如 `ProjectsViewModel`:

- 395 行代码
- 包含 bookmark 管理
- 包含安全作用域资源管理
- 包含项目上下文加载
- 包含健康状态计算
- 包含 UserDefaults 持久化

**影响**:
- ❌ 违反单一职责原则
- ❌ 难以测试：需要 mock 多个依赖
- ❌ 难以复用：逻辑耦合在 ViewModel 中
- ❌ 难以理解：类过大

**代码气味**:
- **Large Class**: 类承担过多职责
- **Divergent Change**: 多种原因导致类需要修改
- **Feature Envy**: ViewModel 操作其他对象的数据过多

---

### 8. 安全作用域资源管理复杂 🟡

**问题描述**:
Security-Scoped Resources 的管理逻辑散落在多处，容易出错：

```swift
// ProjectsViewModel.swift:91 - 手动管理资源
guard url.startAccessingSecurityScopedResource() else {
    error = NSError(...)
    return
}

// ... 操作 ...

url.stopAccessingSecurityScopedResource()

// 另一处 (ProjectsViewModel.swift:166) - 使用 defer
guard url.startAccessingSecurityScopedResource() else {
    throw NSError(...)
}

defer {
    url.stopAccessingSecurityScopedResource()
}
```

**影响**:
- ❌ 资源泄漏风险：忘记调用 `stopAccessing`
- ❌ 代码重复：每次访问资源都要写样板代码
- ❌ 错误处理复杂：需要在多个分支中清理资源
- ❌ 不一致：有些用 defer，有些不用

**代码气味**:
- **Duplicate Code**: 资源管理模式重复
- **Manual Resource Management**: 缺少自动化资源管理（如 RAII）

---

### 9. 缺少单元测试 🟢

**问题描述**:
项目中只有空的测试文件占位符：
- `RustMateTests/RustMateTests.swift`
- `RustMateUITests/RustMateUITests.swift`

关键业务逻辑缺少测试覆盖：
- ✗ 解析器（ToolchainParser, ComponentParser 等）
- ✗ 错误处理逻辑
- ✗ ViewModel 业务逻辑
- ✗ 授权验证逻辑

**影响**:
- ❌ 回归风险：重构时无法验证行为一致性
- ❌ 文档缺失：测试也是文档
- ❌ 设计问题：难测试的代码往往设计不好
- ❌ 维护困难：不敢大胆修改

---

### 10. TODO 注释未清理 🟢

**问题描述**:
发现 6 处 TODO 注释未清理：

```swift
// ToolchainListView.swift:331
// TODO: Add update detection

// AppUpdateService.swift:156
// TODO: Implement SPUUpdaterDelegate methods

// ProjectsViewModel.swift:209
// TODO: Implement proper component checking
```

**影响**:
- ⚠️ 功能不完整：标记了未完成的工作
- ⚠️ 技术债务：积累的 TODO 会被遗忘
- ⚠️ 优先级不明：不知道哪些 TODO 重要

---

## 第二部分：重构策略和优先级

### 重构原则

1. **安全第一**: 所有重构必须在测试保护下进行
2. **增量进行**: 小步快跑，每次重构后验证
3. **保持行为**: 不改变外部可观察行为
4. **先易后难**: 从低风险项开始
5. **持续集成**: 每个重构阶段都保持代码可运行

---

## 第三部分：重构任务详细计划

### Phase 1: 清理和准备（低风险，高收益）

**目标**: 清理死代码，建立重构基础设施

#### Task 1.1: 删除死代码 ✅ 易
**文件**: `RustMate/Item.swift`

**步骤**:
1. 使用 Xcode 的 "Find References" 确认 `Item.swift` 完全未使用
2. 从 Xcode 项目中移除文件
3. 删除文件
4. 验证编译通过

**验证**:
- ✓ 项目编译成功
- ✓ 应用运行正常

**风险**: ⭐️ 极低

---

#### Task 1.2: 建立单元测试基础设施 ⚙️ 中等
**文件**: `RustMateTests/`

**步骤**:
1. 设置测试框架（使用 XCTest）
2. 为解析器创建测试样本数据（rustup 输出）
3. 为 ToolchainParser 编写基础测试

**示例测试**:
```swift
// RustMateTests/Parsers/ToolchainParserTests.swift
import XCTest
@testable import RustMate

class ToolchainParserTests: XCTestCase {
    func testParseValidOutput() {
        let output = """
        stable-aarch64-apple-darwin (default)
        beta-aarch64-apple-darwin
        nightly-aarch64-apple-darwin
        """

        let toolchains = ToolchainParser.parse(output)

        XCTAssertEqual(toolchains.count, 3)
        XCTAssertEqual(toolchains[0].name, "stable-aarch64-apple-darwin")
        XCTAssertTrue(toolchains[0].isDefault)
        XCTAssertFalse(toolchains[1].isDefault)
    }

    func testParseEmptyOutput() {
        let output = ""
        let toolchains = ToolchainParser.parse(output)
        XCTAssertTrue(toolchains.isEmpty)
    }
}
```

**验证**:
- ✓ 所有解析器有基础测试
- ✓ 测试通过率 100%

**风险**: ⭐️ 低（只是新增，不修改现有代码）

---

#### Task 1.3: 统一魔法字符串 ✅ 易
**文件**: 创建 `RustMate/Shared/Constants.swift`

**步骤**:
1. 创建中心化的常量文件
2. 定义所有通知名称
3. 定义所有 UserDefaults 键
4. 替换项目中的魔法字符串

**重构代码**:
```swift
// RustMate/Shared/Constants.swift
enum Constants {
    /// Notification names
    enum Notifications {
        static let openMainWindow = NSNotification.Name("OpenMainWindow")
        static let setupCompleted = NSNotification.Name("SetupCompleted")
        static let authorizationCompleted = NSNotification.Name("AuthorizationCompleted")
        static let authorizationRequired = NSNotification.Name("AuthorizationRequired")
        static let openSettings = NSNotification.Name("OpenSettings")
        static let settingsReset = NSNotification.Name("SettingsReset")
        static let allAuthorizationsCompleted = NSNotification.Name("AllAuthorizationsCompleted")
    }

    /// UserDefaults keys
    enum UserDefaultsKeys {
        static let hasCompletedFirstLaunch = "RustMate.hasCompletedFirstLaunch"
        static let appSettings = "RustMate.AppSettings"
        static let projectBookmarks = "projectBookmarks"
        static let overrideMode = "overrideMode"
    }

    /// Keychain identifiers
    enum Keychain {
        static let bookmarkServiceName = "com.finefine.RustMate.bookmarks"
    }
}
```

**使用示例**（重构后）:
```swift
// Before
NotificationCenter.default.post(name: NSNotification.Name("SettingsReset"), object: nil)

// After
NotificationCenter.default.post(name: Constants.Notifications.settingsReset, object: nil)
```

**验证**:
- ✓ 全局搜索无魔法字符串
- ✓ 编译通过，应用运行正常

**风险**: ⭐️⭐️ 低到中（需要修改多处，但编译器会捕获错误）

---

### Phase 2: 核心抽象重构（中等风险，高收益）

#### Task 2.1: 抽取任务跟踪协调器 🔧 中等
**目标**: 消除 ViewModel 中重复的任务跟踪样板代码

**创建文件**: `RustMate/Services/TaskCoordinator.swift`

**设计**:
```swift
// RustMate/Services/TaskCoordinator.swift
import Foundation

/// 协调任务的生命周期：创建、跟踪、通知
@MainActor
class TaskCoordinator {
    private let taskManager: TaskManager
    private let notificationManager: TaskNotificationManager

    init(
        taskManager: TaskManager = .shared,
        notificationManager: TaskNotificationManager = .shared
    ) {
        self.taskManager = taskManager
        self.notificationManager = notificationManager
    }

    /// 执行一个被跟踪的异步操作
    /// - Parameters:
    ///   - operation: 操作名称
    ///   - target: 操作目标（可选）
    ///   - work: 实际执行的异步工作，返回 TaskResult
    /// - Returns: TaskResult
    func execute(
        operation: String,
        target: String?,
        work: () async throws -> TaskResult
    ) async -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        // 1. 创建并跟踪开始任务
        let runningTask = TaskRecord(
            id: taskId,
            operation: operation,
            target: target,
            status: .running,
            startTime: startTime
        )
        await trackTaskStarted(runningTask)

        // 2. 执行实际工作
        let result: TaskResult
        do {
            result = try await work()
        } catch {
            // 3a. 工作失败 - 创建失败任务记录
            let failedTask = TaskRecord(
                id: taskId,
                operation: operation,
                target: target,
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)
            return TaskResult(
                taskId: taskId,
                toolchainName: target,
                operation: operation,
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
        }

        // 3b. 工作成功 - 创建完成任务记录
        let completedTask = TaskRecord(
            id: taskId,
            operation: operation,
            target: target,
            status: result.status,
            startTime: startTime,
            endTime: result.endTime ?? Date(),
            exitCode: result.exitCode,
            stdoutSnippet: result.stdoutSnippet,
            stderrSnippet: result.stderrSnippet,
            errorMessage: result.errorMessage,
            suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
        )
        await trackTaskCompleted(completedTask)

        return result
    }

    // MARK: - Private Helpers

    private func trackTaskStarted(_ task: TaskRecord) async {
        taskManager.addTask(task)
        await notificationManager.notifyTaskStarted(task)
    }

    private func trackTaskCompleted(_ task: TaskRecord) async {
        taskManager.addTask(task)
        await notificationManager.notifyTaskCompleted(task)
    }
}
```

**重构示例**（ToolchainViewModel）:
```swift
// Before (133 行, 包含大量样板代码)
func installToolchain(name: String) async {
    guard ToolchainInfo.validateName(name) else {
        error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Invalid toolchain name"
        ])
        return
    }

    let taskId = UUID()
    let runningTask = TaskRecord(
        id: taskId,
        operation: "install",
        target: name,
        status: .running,
        startTime: Date()
    )
    await trackTaskStarted(runningTask)

    do {
        let result = try await service.installToolchain(name: name)

        let completedTask = TaskRecord(
            id: taskId,
            operation: "install",
            target: name,
            status: result.status,
            startTime: runningTask.startTime,
            endTime: result.endTime ?? Date(),
            exitCode: result.exitCode,
            stdoutSnippet: result.stdoutSnippet,
            stderrSnippet: result.stderrSnippet,
            errorMessage: result.errorMessage,
            suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
        )
        await trackTaskCompleted(completedTask)

        if result.status == .success {
            await loadToolchains()
        }
    } catch {
        self.error = error
        print("Failed to install toolchain: \(error)")

        let failedTask = TaskRecord(
            id: taskId,
            operation: "install",
            target: name,
            status: .failed,
            startTime: runningTask.startTime,
            endTime: Date(),
            exitCode: -1,
            errorMessage: error.localizedDescription
        )
        await trackTaskCompleted(failedTask)
    }
}

// After (简洁，专注业务逻辑)
private let taskCoordinator = TaskCoordinator()

func installToolchain(name: String) async {
    guard ToolchainInfo.validateName(name) else {
        error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Invalid toolchain name"
        ])
        return
    }

    let result = await taskCoordinator.execute(
        operation: "install",
        target: name
    ) {
        try await service.installToolchain(name: name)
    }

    if result.status == .success {
        await loadToolchains()
    } else if let errorMessage = result.errorMessage {
        self.error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
            NSLocalizedDescriptionKey: errorMessage
        ])
    }
}
```

**受影响文件**:
1. 创建 `TaskCoordinator.swift`
2. 重构 `ToolchainViewModel.swift` (5 个方法)
3. 重构 `ComponentsViewModel.swift`
4. 重构 `TargetsViewModel.swift`
5. 重构 `ProjectsViewModel.swift`

**验证**:
- ✓ 所有任务操作仍然正常工作
- ✓ 任务列表正确显示
- ✓ 通知仍然发送
- ✓ 代码行数减少 ~150 行

**风险**: ⭐️⭐️⭐️ 中等（改变核心逻辑，需要仔细测试）

---

#### Task 2.2: 创建类型安全的事件总线 🔧 中等
**目标**: 替换 NotificationCenter，提供类型安全的事件系统

**创建文件**: `RustMate/Shared/EventBus.swift`

**设计**:
```swift
// RustMate/Shared/EventBus.swift
import Combine
import Foundation

/// 应用内的事件定义
enum AppEvent {
    // 窗口事件
    case openMainWindow
    case openSettings

    // 设置事件
    case settingsReset

    // 授权事件
    case authorizationRequired(purposes: [AuthorizedDirectory.DirectoryPurpose])
    case authorizationCompleted(purpose: AuthorizedDirectory.DirectoryPurpose)
    case allAuthorizationsCompleted

    // 设置流程事件
    case setupCompleted
}

/// 类型安全的事件总线
@MainActor
class EventBus: ObservableObject {
    static let shared = EventBus()

    private let eventSubject = PassthroughSubject<AppEvent, Never>()

    private init() {}

    /// 发布事件
    func publish(_ event: AppEvent) {
        eventSubject.send(event)
    }

    /// 订阅事件流
    var events: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    /// 订阅特定类型的事件
    func subscribe<T>(
        to eventType: T.Type,
        handler: @escaping (T) -> Void
    ) -> AnyCancellable where T: Equatable {
        eventSubject
            .compactMap { event -> T? in
                // 使用 Mirror 进行类型匹配
                if let matched = event as? T {
                    return matched
                }
                return nil
            }
            .sink(receiveValue: handler)
    }
}

// SwiftUI 辅助方法
extension View {
    func onAppEvent(
        _ eventType: AppEvent,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onReceive(EventBus.shared.events) { event in
            if Self.matches(event: event, type: eventType) {
                action()
            }
        }
    }

    private static func matches(event: AppEvent, type: AppEvent) -> Bool {
        switch (event, type) {
        case (.openMainWindow, .openMainWindow),
             (.openSettings, .openSettings),
             (.settingsReset, .settingsReset),
             (.setupCompleted, .setupCompleted),
             (.allAuthorizationsCompleted, .allAuthorizationsCompleted):
            return true
        case (.authorizationRequired, .authorizationRequired),
             (.authorizationCompleted, .authorizationCompleted):
            return true
        default:
            return false
        }
    }
}
```

**使用示例**（重构后）:
```swift
// Before
NotificationCenter.default.post(
    name: NSNotification.Name("AuthorizationRequired"),
    object: nil
)

// After
EventBus.shared.publish(.authorizationRequired(purposes: missingPurposes))

// View 订阅
// Before
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettings"))) { _ in
    appState.showSettings = true
}

// After
.onAppEvent(.openSettings) {
    appState.showSettings = true
}
```

**迁移策略**:
1. 先创建 EventBus，与 NotificationCenter 并行运行
2. 逐个事件迁移，每次迁移后测试
3. 最后移除所有 NotificationCenter 用法

**验证**:
- ✓ 所有事件流正常工作
- ✓ 编译器捕获类型错误
- ✓ 无运行时错误

**风险**: ⭐️⭐️⭐️⭐️ 中到高（影响整个应用的通信机制）

---

#### Task 2.3: 统一错误处理策略 🔧 中等
**目标**: 创建统一的错误类型和处理机制

**创建文件**: `RustMate/Shared/Errors/AppError.swift`

**设计**:
```swift
// RustMate/Shared/Errors/AppError.swift
import Foundation

/// 应用级错误，统一所有错误类型
enum AppError: LocalizedError {
    // 授权相关
    case authorizationMissing(purpose: AuthorizedDirectory.DirectoryPurpose)
    case authorizationStale(path: String)
    case authorizationDenied(path: String)

    // 执行相关
    case rustupNotFound
    case commandExecutionFailed(command: String, exitCode: Int32, stderr: String)
    case parseFailed(output: String, reason: String)

    // 项目相关
    case projectNotFound(path: String)
    case projectAlreadyAdded(path: String)
    case invalidProjectDirectory(path: String)

    // 网络相关
    case networkUnavailable
    case updateCheckFailed

    // 系统相关
    case fileSystemError(underlying: Error)
    case unknownError(underlying: Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .authorizationMissing(let purpose):
            return "Missing authorization for \(purpose.displayText)"
        case .authorizationStale(let path):
            return "Authorization for \(path) has expired"
        case .authorizationDenied(let path):
            return "Access to \(path) was denied"
        case .rustupNotFound:
            return "rustup is not installed or not accessible"
        case .commandExecutionFailed(let command, let exitCode, _):
            return "Command '\(command)' failed with exit code \(exitCode)"
        case .parseFailed(_, let reason):
            return "Failed to parse output: \(reason)"
        case .projectNotFound(let path):
            return "Project not found at \(path)"
        case .projectAlreadyAdded:
            return "This project is already in your list"
        case .invalidProjectDirectory(let path):
            return "Invalid project directory: \(path)"
        case .networkUnavailable:
            return "Network connection is not available"
        case .updateCheckFailed:
            return "Failed to check for updates"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .authorizationMissing:
            return "Go to Settings and authorize the required directory."
        case .authorizationStale:
            return "Go to Settings and re-authorize the directory."
        case .authorizationDenied:
            return "Check System Settings > Privacy & Security to grant access."
        case .rustupNotFound:
            return "Install rustup from https://rustup.rs or add it to your PATH."
        case .commandExecutionFailed(_, _, let stderr):
            return TaskResult.suggestFix(for: stderr)
        case .parseFailed:
            return "This may be due to a rustup version incompatibility. Try updating rustup."
        case .projectNotFound:
            return "The project directory may have been moved or deleted."
        case .projectAlreadyAdded:
            return nil
        case .invalidProjectDirectory:
            return "Select a valid Rust project directory containing Cargo.toml."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .updateCheckFailed:
            return "Check your internet connection or try again later."
        case .fileSystemError, .unknownError:
            return "Try restarting the app or contact support."
        }
    }

    /// 错误分类（用于 UI 路由）
    var category: ErrorPresentation.ErrorCategory {
        switch self {
        case .authorizationMissing:
            return .requiresAuthorization
        case .authorizationStale, .authorizationDenied:
            return .authorizationProblem
        case .rustupNotFound:
            return .requiresSetup
        case .networkUnavailable, .updateCheckFailed:
            return .network
        default:
            return .execution
        }
    }
}

// MARK: - 从现有错误类型转换

extension AppError {
    /// 从 RustupExecutionError 转换
    init(_ error: RustupExecutionError) {
        switch error {
        case .rustupNotFound:
            self = .rustupNotFound
        case .executionFailed(let command, let exitCode, let stderr, _):
            self = .commandExecutionFailed(command: command, exitCode: exitCode, stderr: stderr)
        case .parseFailed(_, let output, let reason):
            self = .parseFailed(output: output, reason: reason)
        }
    }

    /// 从 AuthorizationError 转换
    init(_ error: AuthorizationError) {
        switch error {
        case .missingScope(let purpose):
            self = .authorizationMissing(purpose: purpose)
        case .staleBookmark(let path, _):
            self = .authorizationStale(path: path)
        case .accessDenied(let path, _):
            self = .authorizationDenied(path: path)
        }
    }
}
```

**迁移策略**:
1. 保留现有错误类型（向后兼容）
2. 添加 `AppError` 转换构造器
3. 在 ViewModel 中使用 `AppError`
4. 更新 `ErrorPresentation` 支持 `AppError`

**重构示例**:
```swift
// Before
catch {
    self.error = error  // 丢失类型信息
}

// After
catch let error as RustupExecutionError {
    self.error = AppError(error)
} catch let error as AuthorizationError {
    self.error = AppError(error)
} catch {
    self.error = AppError.unknownError(underlying: error)
}
```

**验证**:
- ✓ 所有错误正确显示
- ✓ 用户看到友好的错误消息
- ✓ 恢复建议准确

**风险**: ⭐️⭐️⭐️ 中等（影响错误处理流程）

---

#### Task 2.4: 封装 UserDefaults 访问 ✅ 易
**目标**: 提供类型安全的 UserDefaults 包装

**创建文件**: `RustMate/Shared/Storage/UserDefaultsStore.swift`

**设计**:
```swift
// RustMate/Shared/Storage/UserDefaultsStore.swift
import Foundation

/// 类型安全的 UserDefaults 访问层
@propertyWrapper
struct UserDefaultsValue<T> {
    let key: String
    let defaultValue: T
    let storage: UserDefaults

    init(
        key: String,
        defaultValue: T,
        storage: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: T {
        get {
            storage.object(forKey: key) as? T ?? defaultValue
        }
        set {
            storage.set(newValue, forKey: key)
        }
    }
}

/// 应用配置存储
struct AppUserDefaults {
    @UserDefaultsValue(
        key: Constants.UserDefaultsKeys.hasCompletedFirstLaunch,
        defaultValue: false
    )
    static var hasCompletedFirstLaunch: Bool

    @UserDefaultsValue(
        key: Constants.UserDefaultsKeys.overrideMode,
        defaultValue: "toolchainFile"
    )
    static var overrideMode: String

    // Codable 类型的支持
    static var appSettings: AppSettings? {
        get {
            guard let data = UserDefaults.standard.data(
                forKey: Constants.UserDefaultsKeys.appSettings
            ) else {
                return nil
            }
            return try? JSONDecoder().decode(AppSettings.self, from: data)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(
                    forKey: Constants.UserDefaultsKeys.appSettings
                )
                return
            }
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: Constants.UserDefaultsKeys.appSettings)
        }
    }

    static var projectBookmarks: [ProjectBookmark] {
        get {
            guard let data = UserDefaults.standard.data(
                forKey: Constants.UserDefaultsKeys.projectBookmarks
            ) else {
                return []
            }
            return (try? JSONDecoder().decode([ProjectBookmark].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: Constants.UserDefaultsKeys.projectBookmarks)
        }
    }
}
```

**使用示例**（重构后）:
```swift
// Before
let hasCompletedFirstLaunch = UserDefaults.standard.bool(forKey: firstLaunchKey)

// After
let hasCompletedFirstLaunch = AppUserDefaults.hasCompletedFirstLaunch

// Before
UserDefaults.standard.set(true, forKey: firstLaunchKey)

// After
AppUserDefaults.hasCompletedFirstLaunch = true
```

**验证**:
- ✓ 所有设置正常读写
- ✓ 编译器捕获类型错误
- ✓ 无运行时错误

**风险**: ⭐️⭐️ 低到中（简单包装，影响范围明确）

---

### Phase 3: 架构优化（高风险，高收益）

#### Task 3.1: 抽取 Security-Scoped Resource 管理器 🔧 中等
**目标**: 使用 RAII 模式自动管理安全作用域资源

**创建文件**: `RustMate/Utilities/ScopedResourceManager.swift`

**设计**:
```swift
// RustMate/Utilities/ScopedResourceManager.swift
import Foundation

/// RAII-style 安全作用域资源管理器
/// 使用 `defer` 自动释放资源
struct ScopedResource {
    let url: URL

    /// 初始化并开始访问资源
    /// - Throws: 如果无法访问资源
    init(url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(
                domain: "ScopedResource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to access security-scoped resource"]
            )
        }
        self.url = url
    }

    /// 自动释放资源
    deinit {
        url.stopAccessingSecurityScopedResource()
    }

    /// 执行需要访问资源的工作
    /// 资源会在闭包执行完毕后自动释放
    static func withAccess<T>(
        to url: URL,
        work: (URL) throws -> T
    ) rethrows -> T {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(
                domain: "ScopedResource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to access security-scoped resource"]
            )
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        return try work(url)
    }

    /// 异步版本
    static func withAccess<T>(
        to url: URL,
        work: (URL) async throws -> T
    ) async rethrows -> T {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(
                domain: "ScopedResource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to access security-scoped resource"]
            )
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        return try await work(url)
    }
}
```

**使用示例**（重构后）:
```swift
// Before (手动管理，容易出错)
var isStale = false
let url = try URL(
    resolvingBookmarkData: project.bookmarkData,
    options: .withSecurityScope,
    relativeTo: nil,
    bookmarkDataIsStale: &isStale
)

guard url.startAccessingSecurityScopedResource() else {
    throw NSError(...)
}

defer {
    url.stopAccessingSecurityScopedResource()
}

let context = try await service.getProjectContext(projectPath: url.path)

// After (自动管理，安全)
var isStale = false
let url = try URL(
    resolvingBookmarkData: project.bookmarkData,
    options: .withSecurityScope,
    relativeTo: nil,
    bookmarkDataIsStale: &isStale
)

let context = try await ScopedResource.withAccess(to: url) { url in
    try await service.getProjectContext(projectPath: url.path)
}
```

**验证**:
- ✓ 无资源泄漏（使用 Instruments 验证）
- ✓ 所有文件操作正常工作
- ✓ 错误情况下资源正确释放

**风险**: ⭐️⭐️⭐️ 中等（资源管理关键，但模式简单）

---

#### Task 3.2: 拆分 ProjectsViewModel 🔧 高级
**目标**: 按单一职责原则拆分 ViewModel

**策略**: 将 `ProjectsViewModel` (395 行) 拆分为：
1. `ProjectsViewModel` - 项目列表和选择管理 (~150 行)
2. `ProjectBookmarkService` - Bookmark 持久化逻辑 (新建)
3. `ProjectHealthService` - 健康状态计算 (新建)

**设计**:
```swift
// RustMate/Services/ProjectBookmarkService.swift
import Foundation

/// 管理项目 bookmark 的持久化
class ProjectBookmarkService {
    func loadBookmarks() -> [ProjectBookmark] {
        return AppUserDefaults.projectBookmarks
    }

    func saveBookmarks(_ bookmarks: [ProjectBookmark]) {
        AppUserDefaults.projectBookmarks = bookmarks
    }

    func createBookmark(for url: URL) throws -> ProjectBookmark {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        return ProjectBookmark(
            id: UUID(),
            path: url.path,
            displayName: url.lastPathComponent,
            bookmarkData: bookmarkData,
            addedDate: Date(),
            isFavorite: false
        )
    }

    func updateBookmark(_ bookmark: ProjectBookmark, with url: URL) throws -> ProjectBookmark {
        let newBookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        var updated = bookmark
        updated.bookmarkData = newBookmarkData
        return updated
    }

    func resolveBookmark(_ bookmark: ProjectBookmark) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark.bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }
}

// RustMate/ViewModels/ProjectsViewModel.swift (重构后，简化版)
@MainActor
class ProjectsViewModel: ObservableObject {
    // Services
    private let bookmarkService = ProjectBookmarkService()
    private let contextService: LocalProjectContextService
    private let healthService = ProjectHealthService()
    private let taskManager = TaskManager.shared

    // State
    @Published var projects: [ProjectBookmark] = []
    @Published var selectedProject: ProjectBookmark?
    @Published var projectContext: ProjectContextInfo?
    @Published var isLoading = false
    @Published var error: AppError?

    init() {
        self.contextService = LocalProjectContextService()
        loadBookmarks()
    }

    // MARK: - Bookmark Management (简化)

    func loadBookmarks() {
        projects = bookmarkService.loadBookmarks()
    }

    func addBookmark(url: URL) {
        do {
            // Validate directory
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw AppError.projectNotFound(path: url.path)
            }

            // Check duplicates
            if projects.contains(where: { $0.path == url.path }) {
                throw AppError.projectAlreadyAdded(path: url.path)
            }

            // Create bookmark
            let bookmark = try ScopedResource.withAccess(to: url) { url in
                try bookmarkService.createBookmark(for: url)
            }

            projects.append(bookmark)
            bookmarkService.saveBookmarks(projects)

            // Auto-select first project
            if projects.count == 1 {
                selectedProject = bookmark
            }
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = .unknownError(underlying: error)
        }
    }

    func removeBookmark(_ bookmark: ProjectBookmark) {
        projects.removeAll { $0.id == bookmark.id }
        bookmarkService.saveBookmarks(projects)

        if selectedProject?.id == bookmark.id {
            selectedProject = projects.first
            projectContext = nil
        }
    }

    // ... 其他方法类似简化
}
```

**验证**:
- ✓ 所有项目功能正常
- ✓ 代码职责清晰
- ✓ 易于测试

**风险**: ⭐️⭐️⭐️⭐️ 高（大规模重构，需要充分测试）

---

### Phase 4: 测试和文档（低风险，高价值）

#### Task 4.1: 完善单元测试覆盖率 ⚙️ 中等
**目标**: 为关键业务逻辑添加单元测试

**测试清单**:
- ✅ ToolchainParser
- ✅ ComponentParser
- ✅ TargetParser
- ✅ ShowParser
- ✅ TaskCoordinator
- ✅ AppError 转换逻辑
- ✅ EventBus
- ✅ ScopedResourceManager
- ⬜ ViewModels（使用 Mock Services）

**示例测试**（TaskCoordinator）:
```swift
// RustMateTests/Services/TaskCoordinatorTests.swift
@MainActor
class TaskCoordinatorTests: XCTestCase {
    var coordinator: TaskCoordinator!
    var mockTaskManager: MockTaskManager!
    var mockNotificationManager: MockTaskNotificationManager!

    override func setUp() {
        super.setUp()
        mockTaskManager = MockTaskManager()
        mockNotificationManager = MockTaskNotificationManager()
        coordinator = TaskCoordinator(
            taskManager: mockTaskManager,
            notificationManager: mockNotificationManager
        )
    }

    func testExecute_Success() async {
        // Given
        let expectedResult = TaskResult(
            taskId: UUID(),
            toolchainName: "stable",
            operation: "install",
            status: .success,
            startTime: Date(),
            endTime: Date(),
            exitCode: 0
        )

        // When
        let result = await coordinator.execute(
            operation: "install",
            target: "stable"
        ) {
            return expectedResult
        }

        // Then
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(mockTaskManager.addedTasks.count, 2) // started + completed
        XCTAssertEqual(mockNotificationManager.startedTasks.count, 1)
        XCTAssertEqual(mockNotificationManager.completedTasks.count, 1)
    }

    func testExecute_Failure() async {
        // Given
        let error = NSError(domain: "Test", code: -1)

        // When
        let result = await coordinator.execute(
            operation: "install",
            target: "stable"
        ) {
            throw error
        }

        // Then
        XCTAssertEqual(result.status, .failed)
        XCTAssertNotNil(result.errorMessage)
    }
}
```

**验证**:
- ✓ 测试通过率 100%
- ✓ 代码覆盖率 > 70% (核心逻辑)

**风险**: ⭐️ 低（只是新增测试）

---

#### Task 4.2: 添加代码文档和架构文档 📝 易
**目标**: 为关键组件添加文档注释

**文档清单**:
1. 更新 `DESIGN.md` - 反映重构后的架构
2. 添加 `ARCHITECTURE.md` - 详细架构图和模块说明
3. 为所有 public API 添加文档注释
4. 为复杂算法添加内联注释

**示例文档**:
```swift
/// 协调任务的生命周期管理
///
/// `TaskCoordinator` 负责：
/// - 创建任务记录并分配 UUID
/// - 跟踪任务状态（running -> success/failed）
/// - 广播任务事件到 TaskManager 和通知系统
/// - 统一错误处理逻辑
///
/// 使用示例：
/// ```swift
/// let result = await coordinator.execute(
///     operation: "install",
///     target: "stable"
/// ) {
///     try await service.installToolchain(name: "stable")
/// }
/// ```
///
/// - Note: 所有任务操作应通过 TaskCoordinator 执行，以确保一致的跟踪和通知
/// - SeeAlso: `TaskManager`, `TaskNotificationManager`
@MainActor
class TaskCoordinator {
    // ...
}
```

**验证**:
- ✓ 文档完整
- ✓ 代码可读性提高

**风险**: ⭐️ 极低

---

#### Task 4.3: 清理 TODO 注释 📝 易
**目标**: 评估并清理所有 TODO 注释

**策略**:
1. 将重要的 TODO 转换为 GitHub Issues
2. 实现简单的 TODO
3. 删除过时的 TODO
4. 为保留的 TODO 添加上下文

**TODO 处理清单**:
- [ ] `ToolchainListView.swift:331` - TODO: Add update detection
  → 转换为 Issue: "Feature: Add toolchain update detection"

- [ ] `AppUpdateService.swift:156` - TODO: Implement SPUUpdaterDelegate
  → 转换为 Issue: "Feature: Custom update UI"

- [ ] `ProjectsViewModel.swift:209` - TODO: Implement proper component checking
  → 实现基础逻辑或转换为 Issue

- [ ] `CargoConfigParser.swift:142` - TODO: Implement TOML serialization
  → 转换为 Issue: "Feature: Cargo config write support"

**验证**:
- ✓ 无孤立的 TODO 注释
- ✓ 所有 TODO 有跟踪

**风险**: ⭐️ 极低

---

## 第四部分：实施时间表和里程碑

### Phase 1: 清理和准备（1-2 周）
**里程碑**: M1 - Foundation Cleanup
- ✅ Task 1.1: 删除死代码 (1 天)
- ⚙️ Task 1.2: 建立测试基础设施 (3-5 天)
- ✅ Task 1.3: 统一魔法字符串 (2-3 天)

**交付物**:
- 无死代码
- 解析器有 100% 测试覆盖
- 无魔法字符串
- 所有测试通过

---

### Phase 2: 核心抽象重构（2-3 周）
**里程碑**: M2 - Core Abstractions
- 🔧 Task 2.1: 抽取 TaskCoordinator (3-5 天)
- 🔧 Task 2.2: 创建 EventBus (5-7 天)
- 🔧 Task 2.3: 统一错误处理 (3-5 天)
- ✅ Task 2.4: 封装 UserDefaults (1-2 天)

**交付物**:
- TaskCoordinator 运行正常
- EventBus 替换 NotificationCenter
- 统一的 AppError 类型
- 类型安全的配置访问

---

### Phase 3: 架构优化（2-3 周）
**里程碑**: M3 - Architecture Refinement
- 🔧 Task 3.1: ScopedResourceManager (3-5 天)
- 🔧 Task 3.2: 拆分 ProjectsViewModel (5-7 天)

**交付物**:
- 无资源泄漏
- ViewModel 职责单一
- 代码可测试性提升

---

### Phase 4: 测试和文档（1-2 周）
**里程碑**: M4 - Quality Assurance
- ⚙️ Task 4.1: 完善测试覆盖 (5-7 天)
- 📝 Task 4.2: 添加文档 (2-3 天)
- 📝 Task 4.3: 清理 TODO (1 天)

**交付物**:
- 70%+ 代码覆盖率
- 完整的架构文档
- 无孤立 TODO

---

## 第五部分：风险管理和回滚策略

### 风险等级定义
- ⭐️ 极低：可直接执行
- ⭐️⭐️ 低：需要代码审查
- ⭐️⭐️⭐️ 中：需要充分测试
- ⭐️⭐️⭐️⭐️ 高：需要分支开发和全面测试
- ⭐️⭐️⭐️⭐️⭐️ 极高：需要全面评估和备份

### 回滚策略
1. **Git 分支策略**:
   - 每个 Phase 创建独立分支
   - 每个 Task 创建 feature 分支
   - 通过 PR 合并到 Phase 分支
   - Phase 完成后合并到 main

2. **测试门槛**:
   - 所有测试必须通过
   - 代码覆盖率不能下降
   - 应用功能正常运行
   - 性能无明显退化

3. **回滚触发条件**:
   - 发现严重 bug
   - 测试通过率下降
   - 性能显著下降
   - 用户体验严重受影响

---

## 第六部分：成功指标

### 代码质量指标
- ✅ 无死代码
- ✅ 无魔法字符串
- ✅ 代码重复率 < 3%
- ✅ 平均方法长度 < 30 行
- ✅ 平均类长度 < 300 行
- ✅ 循环复杂度 < 10

### 测试指标
- ✅ 单元测试覆盖率 > 70%
- ✅ 测试通过率 = 100%
- ✅ 关键路径有集成测试

### 架构指标
- ✅ ViewModels 职责单一
- ✅ 服务层可独立测试
- ✅ 依赖方向清晰（DIP）
- ✅ 模块耦合度低

### 维护性指标
- ✅ 新功能开发时间减少 30%
- ✅ Bug 修复时间减少 40%
- ✅ 代码审查时间减少 50%

---

## 第七部分：后续优化建议

### 未包含在此次重构中的项目（但值得考虑）

1. **性能优化**
   - 异步 parsers 以避免阻塞主线程
   - 缓存 rustup 输出（带过期策略）
   - 优化大型项目列表的渲染

2. **功能增强**
   - 完善项目健康检查逻辑
   - 实现 rustup 输出的实时流式显示
   - 添加批量操作支持

3. **开发体验**
   - 添加 SwiftLint 配置
   - 设置 CI/CD pipeline
   - 集成崩溃报告（Sentry/Firebase）

4. **XPC Service（未来考虑）**
   - 如设计文档所述，考虑实现 XPC Service 提高安全性
   - 当前本地执行足够，但 App Store 分发可能需要

---

## 附录：重构前后对比

### 代码行数对比（预估）
| 组件 | 重构前 | 重构后 | 减少 |
|------|--------|--------|------|
| ToolchainViewModel | 491 | ~350 | -141 (-28%) |
| ProjectsViewModel | 395 | ~200 | -195 (-49%) |
| 其他 ViewModels | ~800 | ~600 | -200 (-25%) |
| **总计** | **~20,816** | **~19,500** | **-1,316** |

### 代码重复率对比（预估）
| 指标 | 重构前 | 重构后 | 改善 |
|------|--------|--------|------|
| 重复代码行数 | ~800 | ~200 | -75% |
| 重复代码率 | ~3.8% | ~1.0% | ✅ |

### 测试覆盖率对比
| 组件 | 重构前 | 重构后 | 改善 |
|------|--------|--------|------|
| Parsers | 0% | 100% | +100% |
| Services | 0% | 70% | +70% |
| ViewModels | 0% | 50% | +50% |
| **整体** | **0%** | **70%** | **+70%** |

---

## 总结

本重构计划旨在系统性地提升 RustMate 项目的代码质量、可维护性和可测试性。通过 4 个阶段的渐进式重构，我们将：

1. **消除技术债务** - 清理死代码和不一致的模式
2. **提升代码质量** - 减少重复、统一抽象、改善错误处理
3. **改善架构** - 分离关注点、明确职责、降低耦合
4. **完善基础设施** - 建立测试体系、补充文档

**关键成功因素**:
- ✅ 增量式重构，每步可验证
- ✅ 测试先行，保证行为一致性
- ✅ 清晰的回滚策略
- ✅ 持续的代码审查

**预期收益**:
- 🎯 开发效率提升 30%+
- 🎯 代码质量显著改善
- 🎯 维护成本降低 40%+
- 🎯 新人上手时间缩短 50%+

---

**文档版本**: v1.0
**创建日期**: 2026-01-15
**作者**: Claude Code Refactor Skill
**审批状态**: ⏳ 待审批

请在开始重构前审阅此计划，并根据团队实际情况调整优先级和时间表。
