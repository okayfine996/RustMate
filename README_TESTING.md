# 测试工具说明

本项目包含完整的 Sparkle 自动更新测试工具。

## 📁 测试文件

| 文件 | 用途 |
|------|------|
| `start-test-server.sh` | 一键启动本地测试服务器 |
| `test-appcast-stable.xml` | Stable 渠道测试 appcast |
| `test-appcast-beta.xml` | Beta 渠道测试 appcast |
| `QUICK_TEST.md` | 5 分钟快速测试指南 ⭐ |
| `LOCAL_TESTING.md` | 详细测试文档 |

## 🚀 快速开始

### 1. 安装 http-server

```bash
npm install -g http-server
```

### 2. 启动测试服务器

```bash
./start-test-server.sh
```

### 3. 配置 Xcode

按 **⌘<** → **Run** → **Arguments** → **Environment Variables**

添加：
```
SPARKLE_TEST_MODE = 1
```

### 4. 降低版本号

在 Xcode 项目设置中：
- Version: `1.0.0`
- Build: `1000000`

### 5. 运行测试

按 **⌘R** 运行应用，然后：
- Settings → Updates → Check for Updates

## 📖 详细文档

- **新手**：查看 `QUICK_TEST.md`
- **进阶**：查看 `LOCAL_TESTING.md`

## 🔧 测试模式说明

测试模式通过环境变量 `SPARKLE_TEST_MODE=1` 启用，仅在 DEBUG 构建中生效：

- ✅ 自动使用 `http://localhost:8000/test-appcast-*.xml`
- ✅ 允许 HTTP（仅限 localhost）
- ✅ Release 构建不受影响

**无需修改代码！**

## 🎯 测试覆盖

- [x] 检测新版本
- [x] Stable/Beta 渠道切换
- [x] 错误处理和重试
- [x] 系统版本检查
- [x] UI 状态变化
- [ ] 实际下载（需要真实 DMG）
- [ ] 签名验证（需要真实签名）
- [ ] 安装流程（需要真实 DMG）

## 🐛 问题排查

### http-server 未找到

```bash
npm install -g http-server
```

### 显示 "Feed URL must use HTTPS"

确认 Xcode Scheme 中已添加 `SPARKLE_TEST_MODE=1`

### 没有检测到更新

确保当前版本低于 appcast 中的版本：
- 当前：1.0.0 (build 1000000)
- Appcast：1.0.1 (build 1000001)

## 📦 生产环境

生产环境配置在 `UpdateFeeds.swift` 中：

```swift
// 自动使用 HTTPS 生产 URL
https://okayfine996.github.io/RustMate/appcast-stable.xml
https://okayfine996.github.io/RustMate/appcast-beta.xml
```

测试模式不会影响生产构建。

