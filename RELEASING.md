# RustMate 发布指南

本文档描述 RustMate 的发布流程，包括版本管理、构建、签名、公证与自动更新发布。

## 版本号策略

RustMate 采用语义化版本号（SemVer）+ 单调递增构建号：

- **`CFBundleShortVersionString`（Marketing Version）**：用户可见版本号
  - 稳定版：`1.2.0`、`1.2.1`
  - Beta 版：`1.3.0-beta.1`、`1.3.0-beta.2`
  
- **`CFBundleVersion`（Build Number）**：严格递增的整数
  - 格式：`XXYYZZ`（如 `1.2.0` → `010200`）或时间戳流水
  - 规则：**每次构建必须递增**，包括 beta → stable 的过渡

## 发布类型

### 稳定版（Stable Release）

- 目标用户：所有用户（默认更新渠道）
- GitHub Release：**非 pre-release**
- 更新清单：`appcast-stable.xml`

### 测试版（Beta Release）

- 目标用户：选择"接收 Beta 更新"的用户
- GitHub Release：**标记为 pre-release**
- 更新清单：`appcast-beta.xml`

## Sparkle 自动更新发布流程

### 前置条件

1. **Developer ID 证书**：已安装 Apple Developer ID Application 证书
2. **公证凭证**：已配置 `notarytool` keychain profile
3. **Sparkle 工具**：已安装 Sparkle 的 `generate_appcast` 工具
4. **GitHub 访问**：有权限上传 Releases 与更新 Pages

### 发布步骤

#### 1. 构建与签名

```bash
# 1. 在 Xcode 中 Archive（Product → Archive）
# 2. Export 为 Developer ID signed app
# 3. 或使用命令行构建：
xcodebuild -scheme RustMate -configuration Release -archivePath build/RustMate.xcarchive archive
xcodebuild -exportArchive -archivePath build/RustMate.xcarchive -exportPath build/Export -exportOptionsPlist ExportOptions.plist
```

#### 2. 打包 DMG

```bash
# 创建 DMG（使用 create-dmg 或手动）
# 命名规则：RustMate-<version>.dmg
# 例如：RustMate-1.2.0.dmg 或 RustMate-1.3.0-beta.1.dmg
```

#### 3. 签名 DMG

```bash
codesign --sign "Developer ID Application: Your Name (Team ID)" --timestamp RustMate-1.2.0.dmg
```

#### 4. 公证（Notarization）

```bash
# 提交公证
xcrun notarytool submit RustMate-1.2.0.dmg \
  --keychain-profile "YourKeychainProfile" \
  --wait

# 公证成功后，staple 票据
xcrun stapler staple RustMate-1.2.0.dmg

# 验证
spctl --assess --type open --context context:primary-signature -v RustMate-1.2.0.dmg
```

#### 5. 上传到 GitHub Releases

```bash
# 创建 Release（稳定版）
gh release create v1.2.0 RustMate-1.2.0.dmg \
  --title "RustMate 1.2.0" \
  --notes "Release notes here"

# 创建 Release（Beta 版）
gh release create v1.3.0-beta.1 RustMate-1.3.0-beta.1.dmg \
  --title "RustMate 1.3.0 Beta 1" \
  --notes "Beta release notes" \
  --prerelease
```

#### 6. 生成并更新 appcast

```bash
# 使用 Sparkle 的 generate_appcast 工具
# （需要先生成 EdDSA 密钥对）
./bin/generate_appcast /path/to/releases/

# 这会生成/更新 appcast.xml，包含：
# - 版本信息
# - 下载 URL（指向 GitHub Releases）
# - EdDSA 签名
# - 最低系统版本（15.0）
```

#### 7. 更新并发布 appcast

```bash
# 将生成的 appcast.xml 分别复制为 stable/beta 版本
cp appcast.xml appcast-stable.xml    # 仅包含稳定版
cp appcast.xml appcast-beta.xml      # 包含 beta 和稳定版

# 上传到 GitHub Pages（或 raw.githubusercontent.com）
# 固定 URL 示例：
# - https://okayfine996.github.io/RustMate/appcast-stable.xml
# - https://okayfine996.github.io/RustMate/appcast-beta.xml
```

### appcast 契约要求

每个 appcast 条目必须包含：

- **版本信息**：`sparkle:version`（构建号）和 `sparkle:shortVersionString`（展示版本）
- **下载 URL**：`enclosure url`（指向 GitHub Releases 的 DMG）
- **文件大小**：`length`（字节）
- **EdDSA 签名**：`sparkle:edSignature`
- **最低系统版本**：`sparkle:minimumSystemVersion="15.0"`
- **发布时间**：`pubDate`
- **Release Notes**（可选）：`sparkle:releaseNotesLink`

### 发布不变量（Contract）

- **PR-001**：DMG 必须完成 Developer ID 签名
- **PR-002**：DMG 必须完成公证并 staple
- **PR-003**：GitHub Releases 的 DMG URL 必须与 appcast 引用一致
- **PR-004**：appcast 更新必须原子且可回滚（先传 DMG，后更新 appcast）
- **PR-005**：appcast 签名字段必须与 DMG 匹配

## 验收检查清单

发布后，按以下步骤验证：

### 1. DMG 可用性

- [ ] 在全新 Mac 上下载 DMG
- [ ] 双击打开不出现"已损坏"提示
- [ ] `spctl --assess` 通过

### 2. 自动更新流程

- [ ] 安装旧版本应用
- [ ] 触发"检查更新"
- [ ] 能发现新版本
- [ ] 后台下载成功
- [ ] 提示"退出/重启安装"
- [ ] 安装后版本号正确

### 3. Beta 渠道

- [ ] 关闭"接收 Beta 更新"时，只看到稳定版
- [ ] 打开"接收 Beta 更新"时，能看到 beta 版本

### 4. 失败场景

- [ ] 断网时给出明确提示
- [ ] 低于 macOS 15 的系统不提示可安装更新

## 工具与资源

- **Sparkle 文档**：https://sparkle-project.org/documentation/
- **notarytool 指南**：https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- **create-dmg**：https://github.com/create-dmg/create-dmg
- **gh CLI**：https://cli.github.com/

## 常见问题

### Q: 如何生成 EdDSA 密钥对？

```bash
# 使用 Sparkle 的 generate_keys 工具
./bin/generate_keys
# 保存私钥到安全位置（不要提交到仓库）
# 公钥配置在应用的 Info.plist 中（SUPublicEDKey）
```

### Q: appcast 应该托管在哪里？

推荐 **GitHub Pages**（首选）或 `raw.githubusercontent.com`（备选）。

- GitHub Pages：更稳定，可自定义域名，缓存控制更好
- raw.githubusercontent.com：简单但缓存策略不可控

### Q: 如何回滚发布？

1. 从 appcast 中移除问题版本条目
2. 重新发布 appcast（用户将不再看到该版本）
3. 如需彻底撤回，删除 GitHub Release

### Q: Beta 用户如何回到稳定版？

关闭"接收 Beta 更新"后，下次检查更新会使用 stable appcast。如果当前 beta 版本高于最新 stable，Sparkle 不会自动降级，需要用户手动安装稳定版。

---

**最后更新**：2026-01-05  
**维护者**：RustMate 开发团队

