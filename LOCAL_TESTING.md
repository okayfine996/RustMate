# 本地测试 Sparkle 自动更新

本文档说明如何在本地测试 Sparkle 自动更新功能。

## 🧪 测试方案

### 方案 1：本地 HTTP 服务器（推荐）

#### 步骤 1：安装并启动本地服务器

**安装 http-server**（如果还没安装）：

```bash
# 使用 npm
npm install -g http-server

# 或使用 Homebrew
brew install http-server
```

**启动服务器**：

在项目根目录运行：

```bash
./start-test-server.sh
```

或手动启动：

```bash
http-server -p 8000 --cors
```

服务器会在 `http://localhost:8000` 上运行。

#### 步骤 2：在 Xcode 中启用测试模式

在 Xcode 中设置环境变量（**无需修改代码！**）：

1. 选择 **Product → Scheme → Edit Scheme...**（或按 ⌘<）
2. 选择左侧的 **Run**
3. 选择 **Arguments** 标签
4. 在 **Environment Variables** 部分点击 **+**
5. 添加：
   - Name: `SPARKLE_TEST_MODE`
   - Value: `1`
6. 点击 **Close**

这样代码会自动：
- ✅ 使用 `http://localhost:8000/test-appcast-*.xml`
- ✅ 允许 HTTP（仅限 localhost）
- ✅ 不影响 Release 构建

#### 步骤 3：降低当前应用版本

在 Xcode 中修改版本号，使其低于 appcast 中的版本：

1. 选择项目 → RustMate target → General
2. 修改版本号：
   - **Version**: `1.0.0`（低于 appcast 的 1.0.1）
   - **Build**: `1000000`（低于 appcast 的 1000001）

#### 步骤 4：运行应用测试

```bash
# 1. 确保本地服务器在运行
./start-test-server.sh

# 2. 在 Xcode 中运行应用（⌘R）

# 3. 打开 Settings → Updates

# 4. 点击 "Check for Updates"
```

**预期结果**：
- ✅ 应用检测到 1.0.1 版本可用
- ✅ 显示更新提示
- ❌ 下载会失败（因为 DMG 文件不存在）

---

## 🎭 测试场景

### 场景 1：测试"有更新可用"

**设置**：
- 当前版本：1.0.0 (build 1000000)
- Appcast 版本：1.0.1 (build 1000001)

**预期**：显示"Update available: 1.0.1"

### 场景 2：测试"无更新"

**设置**：
- 当前版本：1.0.1 (build 1000001)
- Appcast 版本：1.0.1 (build 1000001)

**预期**：显示"No updates available"

### 场景 3：测试 Beta 渠道切换

**步骤**：
1. 默认 Stable 渠道 → 检查更新 → 看到 1.0.1
2. 打开 "Receive Beta Updates"
3. 再次检查更新 → 看到 1.1.0-beta.1

### 场景 4：测试错误处理

**方法**：
- 关闭本地服务器
- 点击 "Check for Updates"

**预期**：显示网络错误，带重试按钮

### 场景 5：测试最低系统版本

**方法**：
- 修改 appcast 中的 `minimumSystemVersion` 为 `99.0`
- 检查更新

**预期**：显示系统版本不满足要求的错误

---

## 🔍 调试技巧

### 查看控制台日志

在 Xcode 控制台中查找：

```
✅ AppUpdateService: Initialized with Stable channel
📡 AppUpdateService: Feed URL: http://localhost:8000/test-appcast-stable.xml
🔍 AppUpdateService: Manually checking for updates...
```

### 使用 Sparkle 的调试模式

在 `AppUpdateService.swift` 的 `configureUpdater()` 中添加：

```swift
// 启用 Sparkle 的详细日志
updater.sendsSystemProfile = false
updater.automaticallyChecksForUpdates = false  // 禁用自动检查，仅手动
```

### 测试模式的安全性

测试模式（`SPARKLE_TEST_MODE=1`）会：
- ✅ 允许 HTTP (仅本地网络)
  - `localhost` / `127.0.0.1`
  - `192.168.x.x` (局域网)
  - `10.x.x.x` (私有网络)
  - `172.16.x.x - 172.31.x.x` (私有网络)
- ✅ 允许无签名更新
- ⚠️ **仅在 DEBUG 构建中生效**
- ✅ Release 构建自动禁用，保证安全

### 使用本机 IP 地址测试

如果需要在真机或其他设备上测试，可以使用本机 IP：

1. 查看本机 IP：
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. 修改 `UpdateFeeds.swift` 中的 IP 地址：
   ```swift
   return "http://192.168.31.70:8000/test-appcast-stable.xml"
   ```

3. 启动服务器时绑定到所有接口：
   ```bash
   http-server -p 8000 --cors -a 0.0.0.0
   ```

---

## 🚨 测试后清理

**重要**：测试完成后，记得：

1. **Xcode Scheme**：移除或禁用 `SPARKLE_TEST_MODE` 环境变量
2. **版本号**：恢复到正确的版本号
3. **本地服务器**：关闭测试服务器（Ctrl+C）

**✅ 好消息**：代码无需修改，测试配置只在 DEBUG 模式下生效！

---

## 📝 快速测试清单

- [ ] 启动本地 HTTP 服务器（`./start-test-server.sh`）
- [ ] 在 Xcode Scheme 中添加 `SPARKLE_TEST_MODE=1` 环境变量
- [ ] 降低应用版本号（Version: 1.0.0, Build: 1000000）
- [ ] 运行应用（⌘R）
- [ ] 测试 Stable 渠道更新检查
- [ ] 测试 Beta 渠道切换
- [ ] 测试错误处理（关闭服务器）
- [ ] 查看控制台日志
- [ ] 移除环境变量
- [ ] 恢复版本号

---

## 🎯 方案 2：使用真实的测试环境

如果你想测试完整流程（包括下载），可以：

1. 在 GitHub 创建一个测试 Release
2. 上传一个真实的 DMG（可以是旧版本）
3. 创建真实的 appcast 文件
4. 托管在 GitHub Pages 上

这样可以测试完整的下载和安装流程。

---

需要帮助吗？告诉我你遇到的问题！

