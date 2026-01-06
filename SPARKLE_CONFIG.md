# Sparkle 配置说明（无 Info.plist 项目）

本项目使用现代 Xcode 配置方式（无独立 Info.plist），Sparkle 的配置通过代码完成。

## 配置方式对比

### ✅ 当前实现（代码配置）

我们的实现**不依赖 Info.plist**，所有配置都在代码中完成：

**优点**：
- ✅ 可以动态切换 feed URL（stable/beta）
- ✅ 不需要修改项目配置文件
- ✅ 更灵活，易于测试

**已完成的配置**：
1. **Feed URL**：在 `UpdateFeeds.swift` 中定义
   ```swift
   static let stable = UpdateFeedConfig(
       channel: .stable,
       url: URL(string: "https://okayfine996.github.io/RustMate/appcast-stable.xml")!,
       minimumSystemVersion: "15.0"
   )
   ```

2. **自动检查**：在 `AppUpdateService.swift` 中配置
   ```swift
   updater.automaticallyChecksForUpdates = true
   updater.automaticallyDownloadsUpdates = true
   ```

3. **动态 Feed URL**：在运行时设置
   ```swift
   updater.feedURL = feedURL  // 根据用户选择的渠道动态设置
   ```

### 📝 可选：Info.plist 配置（如果 Sparkle 要求）

某些 Sparkle 功能可能需要 Info.plist 配置（如公钥验证）。如果需要，按以下步骤操作：

#### 方式一：在 Xcode Build Settings 中添加

1. 选择 RustMate target
2. Build Settings → 搜索 "Info Plist"
3. 找到 "Info.plist Values" 或点击 "+" → "Add User-Defined Setting"
4. 添加：
   - Key: `SUPublicEDKey`
   - Type: String
   - Value: `[你的 EdDSA 公钥]`

#### 方式二：创建 Info.plist 文件

如果 Xcode 提示需要 Info.plist：

```bash
# 创建文件
cat > RustMate/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPublicEDKey</key>
    <string>[你的 EdDSA 公钥]</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
</dict>
</plist>
EOF
```

然后在 Build Settings 中设置：
- `INFOPLIST_FILE` = `RustMate/Info.plist`

## EdDSA 密钥生成

更新包签名需要 EdDSA 密钥对：

### 1. 下载 Sparkle 工具

从 [Sparkle Releases](https://github.com/sparkle-project/Sparkle/releases) 下载最新版本。

### 2. 生成密钥对

```bash
# 解压后运行
cd Sparkle-2.x.x
./bin/generate_keys

# 输出示例：
# A key has been generated and saved in your Keychain (Sparkle EdDSA).
# 
# Public key (add to Info.plist as SUPublicEDKey):
# abcdef1234567890...
# 
# Private key will be used by generate_appcast for signing updates.
```

### 3. 保存密钥

- **公钥**：
  - 如果使用 Info.plist：添加到 `SUPublicEDKey`
  - 如果纯代码配置：可以在 `AppUpdateService` 中通过 `updater.publicEDKey` 设置
  
- **私钥**：
  - 保存在 macOS Keychain 中（自动）
  - 或导出为文件（用于 CI/CD）：
    ```bash
    # 从 Keychain 导出
    security find-generic-password -s "Sparkle EdDSA" -w > sparkle_private_key.txt
    ```
  - ⚠️ **不要提交到 Git！** 添加到 `.gitignore`

## 验证配置

### 检查 Feed URL 是否正确设置

在 `AppUpdateService.swift` 的日志中查看：

```
✅ AppUpdateService: Initialized with Stable channel
📡 AppUpdateService: Feed URL: https://okayfine996.github.io/RustMate/appcast-stable.xml
```

### 测试更新检查

1. 运行应用
2. 打开 Settings → Updates
3. 点击 "Check for Updates"
4. 查看 Xcode Console 日志

预期日志：
```
🔍 AppUpdateService: Manually checking for updates...
✅ AppUpdateService: Updater configured
   - Automatic checks: true
   - Automatic downloads: true
```

## 常见问题

### Q: Sparkle 报错 "No feed URL"

**原因**：Feed URL 未正确设置

**解决**：
1. 确认 `UpdateFeeds.swift` 中的 URL 正确
2. 确认 `AppUpdateService` 的 `configureUpdater()` 被调用
3. 检查日志中的 "Feed URL:" 输出

### Q: 更新检查失败，提示签名错误

**原因**：
- 公钥未配置
- 或 appcast 中的签名与公钥不匹配

**解决**：
1. 确认已生成 EdDSA 密钥对
2. 如果使用 Info.plist，确认公钥已添加
3. 如果纯代码配置，在 `AppUpdateService` 中添加：
   ```swift
   if let updater = updaterController.updater {
       updater.publicEDKey = "你的公钥"
   }
   ```

### Q: 能否完全不用签名？

**不推荐**，但可以：

在开发/测试阶段，可以临时禁用签名验证（仅用于测试）：
```swift
// ⚠️ 仅用于开发测试，生产环境必须启用签名验证
#if DEBUG
updater.validateUpdateSignature = false
#endif
```

**生产环境必须启用签名验证**，否则存在安全风险。

## 下一步

1. ✅ 代码配置已完成（无需额外操作）
2. ⏳ 生成 EdDSA 密钥对（发布前必须）
3. ⏳ 创建测试 appcast 进行验证
4. ⏳ 按 `RELEASING.md` 完成首次发布

---

**最后更新**：2026-01-05  
**状态**：代码配置已完成，等待密钥生成与测试

