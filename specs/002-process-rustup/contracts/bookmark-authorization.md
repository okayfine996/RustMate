# Contract: Bookmark Authorization (Scope & Recovery)

**Feature**: `specs/002-process-rustup/spec.md`  
**Date**: 2026-01-01

## Purpose

定义 RustMate 在沙盒内访问 `rustup/.cargo/.rustup` 时的授权范围规则，以及授权不足/失效时的恢复路径。

## Authorization Scopes

最小授权集合（可扩展）：

- rustup 可执行文件所在位置（或其目录）
- `.cargo`（至少包含 `bin`）
- `.rustup`

可选授权：

- 项目目录（仅当需要读取项目上下文或写入 `rust-toolchain.toml` 时）

## Rules

- 执行前必须校验：本次操作所需的资源根是否已被授权
- 如果授权缺失：
  - 必须以用户可理解的方式提示缺少的授权范围（不要只显示“失败”）
  - 必须提供一键进入授权流程的入口
- 如果书签失效/访问被拒绝：
  - 必须提示“授权已失效/需要重新授权”
  - 允许用户重新授权并重试

## UX Requirements

- 在设置中可见：列出当前授权项与状态（已授权/失效/未知）
- 支持：重新授权、清除授权（清除后下一次操作必须重新授权）

