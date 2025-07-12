#!/bin/bash

# A Dark Room Flutter Web 微信环境构建脚本
# 专门为微信小程序WebView环境优化构建

set -e

echo "🔥 开始构建 A Dark Room Flutter Web (微信优化版本)"

# 检查Flutter环境
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装或不在PATH中"
    exit 1
fi

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📁 项目目录: $PROJECT_ROOT"

# 清理之前的构建
echo "🧹 清理之前的构建..."
flutter clean
rm -rf build/web

# 获取依赖
echo "📦 获取依赖..."
flutter pub get

# 构建Web版本（微信优化配置）
echo "🏗️ 构建Flutter Web (微信优化版本)..."

# 使用HTML渲染器，禁用Service Worker，优化微信兼容性
flutter build web \
  --release \
  --web-renderer html \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=false \
  --no-tree-shake-icons \
  --source-maps

echo "✅ Flutter Web构建完成"

# 微信环境优化处理
echo "🔧 应用微信环境优化..."

BUILD_DIR="$PROJECT_ROOT/build/web"

# 1. 修改index.html，添加微信兼容性标记
if [ -f "$BUILD_DIR/index.html" ]; then
    # 在head中添加微信环境标记
    sed -i.bak 's/<head>/<head>\n  <!-- 微信环境优化版本 -->\n  <meta name="wechat-optimized" content="true">/' "$BUILD_DIR/index.html"
    
    # 添加微信环境CSS优化
    cat >> "$BUILD_DIR/index.html" << 'EOF'
<style>
/* 微信环境CSS优化 */
body {
  /* 防止微信环境下的滚动问题 */
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
}

/* 微信环境下的触摸优化 */
* {
  -webkit-tap-highlight-color: transparent;
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  user-select: none;
}

/* Flutter应用容器优化 */
#flutter-view {
  width: 100vw;
  height: 100vh;
  position: fixed;
  top: 0;
  left: 0;
}

/* 加载动画优化 */
#loading {
  background: #000;
  color: #fff;
  font-family: 'Courier New', monospace;
}
</style>
EOF
    
    echo "✅ 已优化index.html for 微信环境"
fi

# 2. 创建微信环境检测文件
cat > "$BUILD_DIR/wechat_check.js" << 'EOF'
// 微信环境检测和诊断
(function() {
  const isWeChat = /MicroMessenger/i.test(navigator.userAgent);
  const isMiniProgram = window.wx && window.wx.miniProgram;
  
  console.log('微信环境检测结果:', {
    isWeChat: isWeChat,
    isMiniProgram: isMiniProgram,
    userAgent: navigator.userAgent,
    buildTime: new Date().toISOString()
  });
  
  if (isWeChat) {
    console.log('✅ 微信环境检测成功，已加载优化配置');
  } else {
    console.log('ℹ️ 非微信环境');
  }
})();
EOF

# 3. 创建部署说明文件
cat > "$BUILD_DIR/WECHAT_DEPLOYMENT.md" << 'EOF'
# 微信小程序WebView部署说明

## 构建信息
- 构建时间: $(date)
- Flutter版本: $(flutter --version | head -n 1)
- 渲染器: HTML (微信优化)
- Service Worker: 已禁用

## 部署要求

### 1. 域名配置
- ❌ 不能使用IP地址: https://8.140.248.32/
- ✅ 必须使用合法域名: https://adarkroom.yourdomain.com/
- ✅ 必须使用HTTPS协议
- ✅ SSL证书必须有效

### 2. 微信小程序后台配置
1. 登录微信小程序后台
2. 进入"开发" -> "开发设置" -> "服务器域名"
3. 在"业务域名"中添加你的域名

### 3. 服务器配置示例 (Nginx)
```nginx
server {
    listen 443 ssl;
    server_name adarkroom.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        root /path/to/this/build/web;
        try_files $uri $uri/ /index.html;
        
        # 微信兼容性头部
        add_header X-Frame-Options ALLOWALL;
        add_header Access-Control-Allow-Origin *;
        
        # 缓存配置
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 4. 测试步骤
1. 部署到HTTPS服务器
2. 在微信小程序后台添加业务域名
3. 修改小程序config/env.js中的h5Url
4. 在微信开发者工具中测试
5. 发布到微信小程序

## 故障排除

### 白屏问题
- 检查域名是否在微信小程序业务域名白名单中
- 检查HTTPS证书是否有效
- 查看微信开发者工具控制台错误信息

### 加载缓慢
- 检查网络连接
- 优化资源文件大小
- 使用CDN加速

## 联系支持
如有问题，请查看项目文档或提交Issue。
EOF

# 4. 生成文件清单
echo "📋 生成文件清单..."
find "$BUILD_DIR" -type f -name "*.js" -o -name "*.html" -o -name "*.css" | sort > "$BUILD_DIR/file_manifest.txt"

# 5. 计算构建大小
BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
echo "📊 构建大小: $BUILD_SIZE"

# 6. 创建压缩包（可选）
if command -v zip &> /dev/null; then
    echo "📦 创建部署压缩包..."
    cd "$BUILD_DIR"
    zip -r "../a_dark_room_wechat_$(date +%Y%m%d_%H%M%S).zip" .
    cd "$PROJECT_ROOT"
    echo "✅ 压缩包已创建"
fi

echo ""
echo "🎉 微信优化版本构建完成！"
echo ""
echo "📁 构建目录: $BUILD_DIR"
echo "📊 构建大小: $BUILD_SIZE"
echo ""
echo "⚠️  重要提醒："
echo "   1. 必须使用合法域名，不能使用IP地址"
echo "   2. 必须在微信小程序后台配置业务域名白名单"
echo "   3. 必须使用有效的HTTPS证书"
echo ""
echo "📖 详细部署说明请查看: $BUILD_DIR/WECHAT_DEPLOYMENT.md"
echo ""
