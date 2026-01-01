# Data Model: Sandboxed Direct Rustup Execution

**Feature**: `specs/002-process-rustup/spec.md`  
**Date**: 2026-01-01

## Overview

本 feature 的核心数据是“授权范围”（security-scoped bookmarks）与“执行结果”（结构化成功/失败）。
现有代码已经具备：

- `AuthorizedDirectory`（含 purpose + bookmarkData）
- `AppSettings.authorizedDirectories`
- `BookmarkManager`（Keychain 持久化 bookmarkData）

本阶段将把“授权目的”细化到能覆盖 rustup 的可执行与数据目录。

## Entities

### AuthorizedDirectory (existing)

**Represents**: 用户显式授权的目录/资源（以 security-scoped bookmark 持久化）。  
**Fields**:

- `id`: UUID
- `path`: String
- `bookmarkData`: Data
- `purpose`: DirectoryPurpose
- `authorizedDate`: Date
- `lastValidated`: Date?

**Notes**:

- `path` 必须代表“用户授权的资源根”，不应存储推导出来的子路径（避免授权范围误判）
- 需要支持“失效检测与刷新”（bookmark stale / startAccessing 失败）

**DirectoryPurpose (proposed refinement)**

目前有：

- `rustupAccess`（说明为访问 `~/.cargo/bin`）
- `projectAccess`
- `customToolchainPath`

为满足本 feature，建议将授权目的更精确化为：

- `rustupExecutableDir`：rustup 可执行文件所在目录（例如 `~/.cargo/bin` 或 `/opt/homebrew/bin`）
- `cargoHome`：`.cargo`
- `rustupHome`：`.rustup`
- `projectAccess`：项目目录（仅在涉及项目上下文/写文件时使用）

### ExecutionResult (new concept)

**Represents**: 一次 rustup 操作的结构化结果（供 UI 展示与任务记录）。  
**Fields (conceptual)**:

- `operation`: String（例如 listToolchains / addTarget 等）
- `startedAt` / `finishedAt`
- `status`: success | failure | cancelled
- `errorCategory`: missingAuthorization | rustupNotFound | executionFailed | parseFailed | unknown
- `message`: String（用户可理解的摘要）
- `suggestedFix`: String?（下一步动作）
- `rawOutputSummary`: String?（可选、截断后的摘要）

## Relationships

- `AppSettings.authorizedDirectories` 是授权范围的 source-of-truth
- 具体的“执行层”在运行时通过 `BookmarkManager.resolveBookmark` → `startAccessingSecurityScopedResource`
  将授权范围应用到执行链路中

