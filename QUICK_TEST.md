# 🚀 快速测试 Sparkle 更新（5 分钟）

## 步骤 1：安装并启动测试服务器

**首次使用**，先安装 http-server：

```bash
npm install -g http-server
# 或
brew install http-server
```

**启动服务器**：

```bash
./start-test-server.sh
```

保持这个终端窗口运行。

## 步骤 2：配置 Xcode

1. 按 **⌘<** 打开 Scheme 编辑器
2. 选择 **Run** → **Arguments**
3. 在 **Environment Variables** 添加：
   ```
   SPARKLE_TEST_MODE = 1
   ```
4. 点击 **Close**

**💡 提示**：如果需要使用本机 IP 地址（如 `192.168.31.70`）：
- 直接修改 `UpdateFeeds.swift` 中的 IP 地址
- 或者在真机上测试时使用本机 IP

## 步骤 3：降低版本号

在 Xcode 中：
1. 选择项目 → RustMate target → **General**
2. 修改：
   - **Version**: `1.0.0`
   - **Build**: `1000000`

## 步骤 4：运行并测试

1. 按 **⌘R** 运行应用
2. 打开 **Settings → Updates**
3. 点击 **Check for Updates**

### 预期结果

✅ **成功**：显示 "Update available: 1.0.1"
❌ **失败**：显示错误信息（因为 DMG 不存在，这是正常的）

### 测试 Beta 渠道

1. 打开 **Receive Beta Updates** 开关
2. 再次点击 **Check for Updates**
3. 应该看到 "Update available: 1.1.0-beta.1"

## 步骤 5：清理

1. 按 **Ctrl+C** 停止测试服务器
2. 在 Xcode Scheme 中移除 `SPARKLE_TEST_MODE` 环境变量
3. 恢复版本号到正确的值

---

## 🐛 问题排查

### 问题：显示 "updates need to be signed with an EdDSA key"

**原因**：环境变量未设置或应用未重新构建

**解决**：
1. 确认 Xcode Scheme 中 `SPARKLE_TEST_MODE=1` 已添加
2. **完全重新构建**：Product → Clean Build Folder (⇧⌘K)
3. 重新运行应用 (⌘R)

### 问题：显示 "Feed URL must use HTTPS"

**原因**：环境变量未设置

**解决**：确认 Xcode Scheme 中 `SPARKLE_TEST_MODE=1` 已添加

### 问题：显示 "Network unavailable"

**原因**：测试服务器未运行

**解决**：运行 `./start-test-server.sh`

### 问题：没有检测到更新

**原因**：版本号太高

**解决**：确保当前版本低于 appcast 中的版本
- 当前：1.0.0 (build 1000000)
- Appcast：1.0.1 (build 1000001)

---

## 📖 详细文档

查看 `LOCAL_TESTING.md` 了解更多测试场景和调试技巧。

