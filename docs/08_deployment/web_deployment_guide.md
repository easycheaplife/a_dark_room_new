# A Dark Room Web部署指南

## 概述
本文档详细说明如何将A Dark Room Flutter项目构建并部署为Web版本，特别针对微信浏览器进行了优化。

## 构建配置

### 1. 环境要求
- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Chrome浏览器（用于测试）
- HTTPS域名（微信浏览器要求）

### 2. 构建命令

#### 开发构建
```bash
# 开发模式构建（用于测试）
flutter build web --debug --web-renderer html

# 带热重载的开发服务器
flutter run -d chrome --web-port 8080
```

#### 生产构建
```bash
# 生产模式构建（推荐）
flutter build web --release --web-renderer html --dart-define=flutter.web.use_skia=false

# 启用代码压缩和优化
flutter build web --release --web-renderer html --dart-define=flutter.web.use_skia=false --dart-define=flutter.web.auto_detect=false
```

#### 微信优化构建
```bash
# 专门为微信浏览器优化的构建
flutter build web --release \
  --web-renderer html \
  --dart-define=flutter.web.use_skia=false \
  --dart-define=flutter.web.auto_detect=false \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://unpkg.com/canvaskit-wasm@0.33.0/bin/ \
  --base-href /
```

### 3. 构建优化选项

#### Web渲染器选择
- `--web-renderer html`: 使用HTML渲染器（推荐，兼容性更好）
- `--web-renderer canvaskit`: 使用CanvasKit渲染器（性能更好，但体积更大）
- `--web-renderer auto`: 自动选择（不推荐用于生产）

#### 性能优化
```bash
# 启用Tree Shaking（移除未使用的代码）
flutter build web --release --tree-shake-icons

# 压缩资源
flutter build web --release --dart-define=flutter.web.use_skia=false --source-maps
```

## 部署配置

### 1. 静态文件服务器

#### Nginx配置
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    # SSL证书配置（微信浏览器要求HTTPS）
    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    
    # 网站根目录
    root /path/to/flutter/build/web;
    index index.html;
    
    # 主要路由配置
    location / {
        try_files $uri $uri/ /index.html;
        
        # 微信浏览器优化头部
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
    }
    
    # 静态资源缓存配置
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
    }
    
    # Flutter特殊文件
    location /flutter_service_worker.js {
        expires 0;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    location /manifest.json {
        expires 1d;
        add_header Cache-Control "public";
    }
    
    # 启用Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
}

# HTTP重定向到HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

#### Apache配置
```apache
<VirtualHost *:443>
    ServerName your-domain.com
    DocumentRoot /path/to/flutter/build/web
    
    # SSL配置
    SSLEngine on
    SSLCertificateFile /path/to/your/cert.pem
    SSLCertificateKeyFile /path/to/your/key.pem
    
    # 主要路由配置
    <Directory "/path/to/flutter/build/web">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Flutter路由支持
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.html [L]
    </Directory>
    
    # 静态资源缓存
    <LocationMatch "\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 year"
        Header set Cache-Control "public, immutable"
    </LocationMatch>
    
    # 启用压缩
    LoadModule deflate_module modules/mod_deflate.so
    <Location />
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \
            \.(?:gif|jpe?g|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \
            \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Location>
</VirtualHost>
```

### 2. CDN配置

#### 阿里云CDN
```yaml
# CDN配置示例
domain: your-domain.com
origin: your-server.com
cache_rules:
  - path: "*.js,*.css,*.png,*.jpg,*.gif,*.ico,*.svg"
    ttl: 31536000  # 1年
  - path: "/flutter_service_worker.js"
    ttl: 0  # 不缓存
  - path: "/"
    ttl: 3600  # 1小时
```

#### 腾讯云CDN
```json
{
  "domain": "your-domain.com",
  "origin": {
    "type": "domain",
    "value": "your-server.com"
  },
  "cache": [
    {
      "type": "file",
      "rule": "js;css;png;jpg;gif;ico;svg",
      "ttl": 31536000
    },
    {
      "type": "path",
      "rule": "/flutter_service_worker.js",
      "ttl": 0
    }
  ],
  "compression": {
    "switch": "on",
    "type": ["gzip", "brotli"]
  }
}
```

### 3. 微信公众号配置

#### JS安全域名
在微信公众号后台设置JS接口安全域名：
```
your-domain.com
```

#### 网页授权域名
如果需要微信登录功能：
```
your-domain.com
```

## 性能优化

### 1. 资源优化
```bash
# 压缩图片资源
find build/web -name "*.png" -exec pngquant --force --output {} {} \;
find build/web -name "*.jpg" -exec jpegoptim --max=85 {} \;

# 压缩JavaScript文件
find build/web -name "*.js" -exec gzip -k {} \;

# 生成WebP格式图片
find build/web -name "*.png" -exec cwebp {} -o {}.webp \;
```

### 2. 预加载优化
在`web/index.html`中添加关键资源预加载：
```html
<!-- 预加载关键资源 -->
<link rel="preload" href="main.dart.js" as="script">
<link rel="preload" href="icons/Icon-192.png" as="image">
<link rel="prefetch" href="assets/lang/zh.json">
<link rel="prefetch" href="assets/lang/en.json">
```

### 3. Service Worker
Flutter会自动生成Service Worker，确保启用：
```javascript
// 在web/index.html中确保Service Worker注册
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('flutter_service_worker.js');
}
```

## 监控和分析

### 1. 性能监控
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>

<!-- 百度统计 -->
<script>
var _hmt = _hmt || [];
(function() {
  var hm = document.createElement("script");
  hm.src = "https://hm.baidu.com/hm.js?YOUR_SITE_ID";
  var s = document.getElementsByTagName("script")[0]; 
  s.parentNode.insertBefore(hm, s);
})();
</script>
```

### 2. 错误监控
```javascript
// 全局错误捕获
window.addEventListener('error', function(e) {
  console.error('Global error:', e.error);
  // 发送错误报告到监控服务
});

window.addEventListener('unhandledrejection', function(e) {
  console.error('Unhandled promise rejection:', e.reason);
  // 发送错误报告到监控服务
});
```

## 部署检查清单

### 构建前检查
- [ ] Flutter版本兼容性
- [ ] 依赖包版本检查
- [ ] 资源文件完整性
- [ ] 本地化文件检查

### 构建后检查
- [ ] 构建文件完整性
- [ ] 文件大小合理性
- [ ] 关键功能测试
- [ ] 性能基准测试

### 部署后检查
- [ ] HTTPS证书有效
- [ ] 域名解析正确
- [ ] CDN配置生效
- [ ] 微信浏览器兼容性
- [ ] 移动端适配效果
- [ ] 加载速度测试
- [ ] 功能完整性测试

## 故障排除

### 常见问题
1. **白屏问题**: 检查base-href配置和路由设置
2. **资源加载失败**: 检查CORS设置和CDN配置
3. **微信分享不生效**: 检查JS-SDK配置和域名设置
4. **性能问题**: 检查资源压缩和缓存策略

### 调试工具
- Chrome DevTools
- Flutter Inspector
- 微信开发者工具
- 网络性能测试工具
