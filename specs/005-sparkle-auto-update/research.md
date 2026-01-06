# Research: 自动更新（Stable/Beta 渠道）

**Feature**: `specs/005-sparkle-auto-update/spec.md`  
**Date**: 2026-01-05  

本文件用于记录在进入实现前需要明确的关键决策、理由与备选方案，确保后续实现可落地且可回归。

## Decision 1: appcast 声明最低系统版本（macOS 15.0）

- **Decision**: 在 appcast 的每个 release item 中声明最低系统版本为 **15.0**，并确保低于该版本的系统不会被提示可安装更新。
- **Rationale**: 最低系统版本是“能否安装”的硬门槛，应由更新源侧显式声明并在客户端严格遵守，避免用户下载后才发现无法运行/安装。
- **Alternatives considered**:
  - **仅在客户端判断**：容易与发布源失配，且无法通过 appcast 进行精确约束。
  - **仅写在 release notes**：不可验证，也无法阻止错误升级路径。

## Decision 2: Stable/Beta 两条 appcast，客户端按用户偏好切换

- **Decision**: 使用两个固定 URL（`appcast-stable.xml` / `appcast-beta.xml`）。客户端默认 stable；用户打开“接收 Beta 更新”后切换到 beta。
- **Rationale**: 这是最直观、可控、可审计的渠道策略；发布端与客户端的责任边界清晰，便于回滚与灰度管理。
- **Alternatives considered**:
  - **单 appcast + 过滤字段**：实现与调试复杂，容易误放/误判。
  - **依赖 GitHub Releases 的 latest**：对 pre-release（beta）支持不稳定，不适合作为“渠道最新”的长期入口。

## Decision 3: 更新包真实性与完整性校验策略

- **Decision**: 启用 Sparkle 的更新包签名校验（以每个 enclosure 的签名字段为准）；发布流程把“生成签名字段”作为强制步骤。
- **Rationale**: HTTPS 只解决传输安全，无法完全覆盖 CDN/镜像/托管端被篡改的风险；更新链路必须有“可验证的发布者身份”。
- **Alternatives considered**:
  - **仅依赖 HTTPS**：对供应链风险不充分。
  - **完全自研校验与更新器**：成本高、容易出错，与“简化优先”冲突。

## Decision 4: 更新体验为“后台下载 + 提示重启/退出安装”

- **Decision**: 更新检查与下载后台进行；安装阶段提示用户退出/重启完成替换，不追求完全无感静默安装。
- **Rationale**: macOS 运行中的 `.app` 替换存在天然限制；在不引入额外常驻 helper/XPC 的前提下，该体验最稳、最少权限、失败面最小。
- **Alternatives considered**:
  - **完全静默更新**：往往需要常驻 helper/daemon 或更复杂的安装路径，增加测试/发布与安全审查成本。

## Decision 5: GitHub 托管职责划分

- **Decision**: DMG 上传到 GitHub Releases；appcast 固定托管在 GitHub Pages（首选）或 `raw.githubusercontent.com`（备选）。
- **Rationale**: appcast URL 需要稳定且可缓存控制；Releases 适合存放大文件与版本资产，但不适合作为“固定更新清单 URL”。
- **Alternatives considered**:
  - **appcast 放 Releases**：缺乏清晰的“固定地址”与 beta/stable 分流能力，维护成本更高。


