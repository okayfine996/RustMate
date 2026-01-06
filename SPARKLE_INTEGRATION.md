# Sparkle 2 集成步骤

**任务**: T001 - 在 Xcode 工程添加 Sparkle 2 依赖（Swift Package Manager）

## 手动操作步骤

由于 SPM 依赖需要在 Xcode 中添加，请按以下步骤操作：

### 1. 在 Xcode 中添加 Sparkle 2 包

1. 打开 `RustMate.xcodeproj`
2. 选择项目导航器中的项目根节点（RustMate）
3. 选择 "Package Dependencies" 标签页
4. 点击 "+" 按钮添加新包
5. 在搜索框输入：`https://github.com/sparkle-project/Sparkle`
6. 选择 Sparkle 2.x 最新版本（建议 2.6.0 或更高）
7. 在 "Add to Target" 中选择 `RustMate`
8. 点击 "Add Package"

### 2. 验证集成

添加完成后，你应该能在：
- Project Navigator → Package Dependencies 中看到 Sparkle
- Build Phases → Link Binary With Libraries 中看到 Sparkle framework

### 3. 配置 Sparkle（Build Settings）

由于项目使用现代 Xcode 配置（无独立 Info.plist），需要在 Build Settings 中添加 Sparkle 配置：

1. 在 Xcode 中选择项目根节点（RustMate）
2. 选择 RustMate target
3. 切换到 "Build Settings" 标签页
4. 搜索 "Info.plist" 或点击 "+" → "Add User-Defined Setting"
5. 添加以下配置：

**方式一：使用 Build Settings（推荐）**
- 搜索 "Info Plist Values" 或 "Custom iOS/macOS Target Properties"
- 添加以下 keys：
  - `SUFeedURL` = `https://okayfine996.github.io/RustMate/appcast-stable.xml`
  - `SUEnableAutomaticChecks` = `YES`
  - `SUPublicEDKey` = `[待生成的公钥]`

**方式二：创建 Info.plist（如果需要）**
如果 Xcode 提示需要 Info.plist，可以创建一个：
```bash
# 在项目根目录创建
touch RustMate/Info.plist
```

然后在 Build Settings 中设置：
- `INFOPLIST_FILE` = `RustMate/Info.plist`

并在 Info.plist 中添加：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUFeedURL</key>
    <string>https://okayfine996.github.io/RustMate/appcast-stable.xml</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUPublicEDKey</key>
    <string>[待生成的公钥]</string>
</dict>
</plist>
```

### 4. 生成 EdDSA 密钥对

Sparkle 2 使用 EdDSA 签名来验证更新包的真实性：

```bash
# 下载 Sparkle 工具（如果还没有）
# 从 https://github.com/sparkle-project/Sparkle/releases 下载最新版本

# 运行 generate_keys 工具
./bin/generate_keys

# 输出示例：
# A key has been generated and saved in your keychain.
# 
# Public key (add to Info.plist as SUPublicEDKey):
# abcd1234...xyz
# 
# Private key (keep secret, use for signing):
# [保存在 Keychain 中]
```

**重要**：
- 公钥：添加到 Build Settings 的 `SUPublicEDKey`
- 私钥：保存在安全位置，用于发布时签名更新包（不要提交到 Git）

## 参考

- Sparkle 官方文档：https://sparkle-project.org/documentation/
- SPM 集成指南：https://sparkle-project.org/documentation/package-managers/

## 状态

- [X] 已在 Xcode 中添加 Sparkle 2 包依赖
- [X] 已验证 Sparkle 出现在 Package Dependencies
- [X] 已验证构建成功（无编译错误）

## 配置说明

由于本项目**没有独立的 Info.plist 文件**，所有 Sparkle 配置都在代码中完成：

- ✅ Feed URL：在 `UpdateFeeds.swift` 中定义
- ✅ 自动检查：在 `AppUpdateService.swift` 中配置
- ✅ 动态渠道切换：运行时设置 `updater.feedURL`

详细说明请查看 `SPARKLE_CONFIG.md`。

**下一步**：
1. 生成 EdDSA 密钥对（发布前必须）
2. 按 `quickstart.md` 进行功能测试
3. 按 `RELEASING.md` 完成首次发布

