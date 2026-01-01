# Quickstart: 菜单栏工具链切换

**Created**: 2026-01-01  
**Feature**: [spec.md](./spec.md)

## Prerequisites

- macOS 15.6
- 已安装 Rustup 且可在终端正常工作
- RustMate 已完成首次设置（包含执行 Rustup 所需的目录授权）

## Manual Acceptance Steps

### 1) 菜单栏常驻与当前默认工具链展示（P1）

1. 启动 RustMate
2. 在菜单栏找到 RustMate 的入口
3. 验证菜单栏（或其菜单的显著位置）能看到“当前全局默认工具链标识”

**Expected**:
- 能在短时间内看到当前默认工具链
- 若无法获取状态，应看到清晰错误与“重试/打开主界面查看原因”等可行动选项

### 2) 从菜单栏切换全局默认工具链（P1）

1. 打开菜单栏菜单，查看可选工具链列表
2. 选择一个不同于当前默认的工具链
3. 等待切换完成

**Expected**:
- 切换过程中有可见的进行中状态
- 切换成功后，菜单栏展示更新为新默认工具链
- 切换失败时，显示结构化错误与建议动作，并明确“切换未生效”

### 3) 从菜单栏唤起主界面（P2）

1. 将 RustMate 主界面置于后台（或关闭窗口但保持 App 运行）
2. 从菜单栏选择“打开 RustMate”

**Expected**:
- RustMate 主界面被唤起并置于前台可交互

## Regression Checks (Optional)

- 在切换进行中重复触发切换，系统行为一致且可理解（提示/排队/取消）
- 断开授权或制造环境异常时，错误提示不应仅是原始输出文本

## Implementation Notes

### Architecture

The menu bar feature follows RustMate's established patterns:
- **ViewModel**: `MenuBarToolchainViewModel` manages state, errors, and switching logic
- **View**: `MenuBarToolchainMenu` provides the SwiftUI menu interface
- **Models**: `MenuBarModels.swift` contains `ToolchainOption` and `MenuBarActionResult`
- **Integration**: Integrated into `RustMateApp.swift` using `MenuBarExtra`

### Key Features

1. **State Aggregation**: The ViewModel derives the current default toolchain from the list of toolchains returned by `RustToolchainServiceProtocol`

2. **Concurrency Control**: Only one switch operation can be in progress at a time. New switch requests while a switch is in progress are rejected with a console warning.

3. **Error Handling**: All errors are routed through `ErrorPresentation` to provide structured, user-actionable error messages with suggested fixes.

4. **Display Space Management**: Long toolchain names are shortened for menu bar display (channel name only, or truncated with ellipsis).

5. **Window Activation**: The "Open RustMate" action uses `NSApp.activate()` to bring the app to the foreground and `makeKeyAndOrderFront()` to show the main window.

### Testing

Unit tests are located in `RustMateTests/ViewModelTests/MenuBarToolchainViewModelTests.swift` and cover:
- Default toolchain derivation from toolchain list
- Concurrent switching rejection strategy
- Toolchain ID validation
- Switch success and failure paths
- Error presentation structure
- Toolchain options generation

### Common Issues

**Menu bar doesn't show toolchain name:**
- Check that rustup is properly authorized in Settings
- Verify toolchains are installed (`rustup toolchain list`)
- Look for errors in the menu (shown in red with suggested fixes)

**Switching doesn't work:**
- Ensure only trusted toolchains from the list are being selected
- Check if another switch is already in progress
- Review error message for authorization or execution issues

**Menu bar shows generic icon instead of toolchain:**
- This is normal on first launch until state loads
- Click the menu to trigger a refresh if needed
- Check app logs for any load failures

