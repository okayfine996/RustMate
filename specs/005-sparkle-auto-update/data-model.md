# Data Model: 自动更新（Stable/Beta 渠道）

**Feature**: `specs/005-sparkle-auto-update/spec.md`  
**Date**: 2026-01-05  

本功能的“数据模型”主要服务于：用户偏好持久化、UI 状态展示、错误可诊断（结构化）。

## Entity: UpdateChannelPreference

- **Fields**
  - `channel`: `stable | beta`
  - `lastChangedAt`: Date（可选，用于诊断/日志）
- **Validation**
  - 仅允许上述枚举值
- **Notes**
  - 持久化在本地设置存储中（不引入新权限）

## Entity: UpdateFeed

- **Fields**
  - `channel`: `stable | beta`
  - `url`: String（HTTPS URL）
  - `minimumSystemVersion`: `15.0`
- **Validation**
  - `url` 必须是 HTTPS
  - `minimumSystemVersion` 必须等于或高于产品支持下限（当前为 15.0）

## Entity: UpdateState

- **States**
  - `idle`：未检查 / 已完成
  - `checking`：检查中
  - `noUpdate`：无更新
  - `updateAvailable`：检测到新版本（包含版本/说明链接等摘要信息）
  - `downloading`：下载中（可包含进度）
  - `readyToInstall`：下载完成，等待用户退出/重启安装
  - `failed`：失败（包含结构化错误）

## Entity: UpdateError

- **Fields**
  - `category`:
    - `networkUnavailable`
    - `feedUnavailable`
    - `invalidFeed`
    - `signatureInvalid`
    - `downloadFailed`
    - `unsupportedSystemVersion`
    - `unknown`
  - `userMessage`: String（用户可理解、可行动）
  - `recoverySuggestion`: String（例如“检查网络后重试/稍后再试/手动下载/升级系统”）
  - `debugContext`: Dictionary（可选，用于日志）

## State Transitions（示意）

```text
idle
  -> checking
checking
  -> noUpdate
  -> updateAvailable -> downloading -> readyToInstall
  -> failed
readyToInstall
  -> idle (after install + relaunch)
failed
  -> checking (retry)
```


