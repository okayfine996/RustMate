# Quickstart: 自动更新（Stable/Beta 渠道）

**Feature**: `specs/005-sparkle-auto-update/spec.md`  
**Date**: 2026-01-05  

本 quickstart 关注“可重复的验收/回归步骤”，用于验证更新渠道切换、最低系统版本门槛、失败提示与安装流程。

## Prerequisites

- 能访问更新清单（stable/beta 两个固定 HTTPS URL）
- 能访问 GitHub Releases 上的 DMG 资产下载链接
- 准备 2 个版本的发布资产（例如：一个稳定版、一个 beta 版），并确保：
  - 更新清单中版本信息与下载链接匹配
  - 更新包签名校验可通过
  - 更新清单对版本条目声明最低系统版本为 15.0

## Manual Acceptance: P1 稳定渠道自动更新闭环

1. 安装旧版本 RustMate，并启动应用
2. 打开 Settings（⌘,）
3. 找到"Updates"区块，确认当前渠道为 Stable（未开启"Receive Beta Updates"）
4. 点击"Check for Updates"按钮
5. 期望结果：
   - UI 显示"Checking for updates..."状态（带进度指示器）
   - UI 不冻结，其它功能可正常使用
   - 若存在新稳定版本：
     - 状态变为"Update available: X.Y.Z"
     - 显示版本号、下载大小、Release Notes 链接
     - Sparkle 自动开始后台下载
   - 下载中显示进度："Downloading... XX%"
   - 下载完成后状态变为"Ready to install X.Y.Z"
   - Sparkle 弹出提示："需要退出/重启安装"（允许"稍后"）
6. 点击"Install and Restart"：
   - 应用退出
   - 重新启动后版本已更新（可通过 About/版本号验证）

## Manual Acceptance: P2 切换 Beta 渠道

1. 打开 Settings（⌘,）
2. 在"Updates"区块找到"Receive Beta Updates" Toggle
3. 打开 Toggle
4. 期望结果：
   - Toggle 立即切换到开启状态
   - "Current channel"显示从"Stable"变为"Beta"（橙色标识）
   - 下方提示文字变为"You'll receive early access to new features and improvements"
5. 点击"Check for Updates"
6. 期望结果：
   - 更新来源切换为 beta 清单（https://okayfine996.github.io/RustMate/appcast-beta.xml）
   - 若 beta 清单包含更高版本：可发现并下载该版本
7. 关闭"Receive Beta Updates" Toggle
8. 期望结果：
   - "Current channel"显示回到"Stable"（绿色标识）
   - 下方提示文字变为"You'll receive stable, tested releases"
9. 再次点击"Check for Updates"
10. 期望结果：更新来源回到 stable 清单

## Manual Acceptance: P3 失败场景可行动反馈

- **断网**
  1. 关闭网络（Wi-Fi 或断开网线）
  2. 打开 Settings → Updates
  3. 点击"Check for Updates"
  4. 期望：
     - 状态显示"Update failed: 无法检查更新"
     - 显示红色错误提示框（ErrorCalloutView）
     - 错误消息："无法检查更新"
     - 建议动作："请检查网络连接后重试"
     - 出现"Retry"按钮
  5. 重新连接网络后点击"Retry"
  6. 期望：能正常检查更新

- **清单不可访问（404/超时）**
  1. 临时将清单 URL 指向不可用地址（或在托管端制造 404）
  2. 触发检查更新
  3. 期望：
     - 快速失败（不超过 10 秒）
     - 错误消息："更新源不可用"
     - 建议动作："请稍后重试或检查网络设置"
     - 出现"Retry"按钮

- **签名校验失败**
  1. 提供一个签名字段错误/缺失的更新条目
  2. 触发更新
  3. 期望：
     - 错误消息："更新包签名验证失败"
     - 建议动作："此更新可能已被篡改，已阻止安装。请从官方渠道重新下载。"
     - 不会进入安装流程
     - 出现"Retry"按钮（重试会再次失败，符合预期）

## Manual Acceptance: 最低系统版本门槛（macOS 15.0）

在低于 macOS 15 的系统上（或使用测试机）：

1. 启动应用
2. 触发检查更新
3. 期望：即使存在新版本条目，也不会提示可安装更新，并提示“需要 macOS 15.0+”


