# Contract: appcast（stable/beta）

**Feature**: `specs/005-sparkle-auto-update/spec.md`  
**Date**: 2026-01-05  

本文件定义更新清单（appcast）的“契约”：字段要求、发布不变量与验收要点。该契约适用于两个渠道：stable 与 beta。

## Files

- `appcast-stable.xml`
- `appcast-beta.xml`

两者结构相同，仅内容（版本条目集合）不同。

## Contract Rules（必须满足）

- **CR-001**: appcast 必须通过 **HTTPS** 提供（禁止 http）。
- **CR-002**: 每个发布条目必须包含可比较的版本信息：
  - 展示版本（用户可读）
  - 构建版本（单调递增，用于严格比较）
- **CR-003**: 每个发布条目必须声明最低系统版本为 **macOS 15.0**。
- **CR-004**: 每个发布条目必须提供可下载的 DMG URL，指向 GitHub Releases 的固定版本资产。
- **CR-005**: 每个发布条目必须包含更新包签名信息（用于校验真实性与完整性）；校验失败视为不可安装更新。
- **CR-006**: beta 渠道可以包含 pre-release；stable 渠道不得包含未发布的 beta 条目。

## Recommended Fields（建议提供）

- 标题（版本号）
- 发布时间
- Release notes 链接（可选）
- 文件大小（便于下载进度与合理性检查）

## Verification Checklist

- 在浏览器中打开 appcast URL 能直接下载 XML（Content-Type 合理、无重定向循环）
- 从 appcast 中抽取最新条目：
  - 下载 URL 可访问
  - DMG 校验通过
  - 最低系统版本为 15.0


