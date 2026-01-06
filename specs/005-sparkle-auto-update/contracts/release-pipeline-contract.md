# Contract: 发布流水线（签名 + 公证 + GitHub 托管）

**Feature**: `specs/005-sparkle-auto-update/spec.md`  
**Date**: 2026-01-05  

本文件定义“每次发版必须满足的发布不变量”，确保自动更新链路对 Gatekeeper 友好且可审计。

## Release Artifacts

- **DMG**: `RustMate-<version>.dmg`（上传到 GitHub Releases）
- **appcast**: `appcast-stable.xml` / `appcast-beta.xml`（托管到 GitHub Pages 或 raw）

## Contract Rules（必须满足）

- **PR-001**: 发布产物必须完成 **Developer ID 签名**（以 Gatekeeper 可接受方式分发）。
- **PR-002**: DMG 必须完成 **notarytool 公证**，并完成 stapling（保证离线也可验证）。
- **PR-003**: 上传到 GitHub Releases 的 DMG 必须与 appcast 引用的 URL 一致（版本与文件名不可漂移）。
- **PR-004**: appcast 更新必须是“原子可回滚”的：发布新 DMG 前不得提前切换 appcast 指向；失败时可回退到上一条目。
- **PR-005**: appcast 中的签名字段必须与发布 DMG 匹配；签名不匹配视为发布失败。

## Verification Checklist

- 在全新机器/用户环境下下载 DMG：
  - 不出现“已损坏/无法打开”的常见拦截（或可通过标准系统提示打开）
  - `spctl` 能通过（人工验收）
- 启动旧版本应用后：
  - 能发现并下载更新
  - 更新安装后版本生效


