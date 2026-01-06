#!/bin/bash
# 启动本地测试服务器用于 Sparkle 更新测试

echo "🚀 Starting local test server for Sparkle updates..."
echo ""

# 检查 http-server 是否安装
if ! command -v http-server &> /dev/null; then
    echo "❌ http-server not found!"
    echo ""
    echo "📦 Please install it first:"
    echo "   npm install -g http-server"
    echo ""
    echo "   Or use Homebrew:"
    echo "   brew install http-server"
    echo ""
    exit 1
fi

echo "📡 Server URLs:"
echo "   - Local:   http://localhost:8000"
echo "   - Network: http://$(ipconfig getifaddr en0 2>/dev/null || echo "N/A"):8000"
echo ""
echo "📄 Appcast files:"
echo "   - Stable:  /test-appcast-stable.xml"
echo "   - Beta:    /test-appcast-beta.xml"
echo ""
echo "⚠️  Remember to:"
echo "   1. Set SPARKLE_TEST_MODE=1 in Xcode Scheme"
echo "   2. Lower app version to test updates"
echo ""
echo "📖 See QUICK_TEST.md for step-by-step instructions"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# 启动 http-server (绑定到所有接口，允许局域网访问)
http-server -p 8000 --cors -a 0.0.0.0

