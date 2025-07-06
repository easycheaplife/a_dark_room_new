# Flutter Web 微信优化方案

## 概述
将现有Flutter项目优化为适合在微信内嵌浏览器中运行的H5版本。

## 优化目标
1. 移动端界面适配
2. 微信浏览器兼容性
3. 加载性能优化
4. 触摸操作优化

## 具体优化步骤

### 1. 移动端界面适配

#### 响应式布局优化
```dart
// 添加屏幕尺寸检测
class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }
  
  static bool isWeChatBrowser() {
    // 检测微信浏览器
    return kIsWeb && 
           js.context.hasProperty('navigator') &&
           js.context['navigator']['userAgent'].contains('MicroMessenger');
  }
}
```

#### 触摸友好的按钮尺寸
- 最小点击区域：44x44px
- 按钮间距：至少8px
- 文字大小：最小14px

### 2. 微信浏览器兼容性

#### 添加微信特定配置
```html
<!-- web/index.html 添加微信优化 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="format-detection" content="telephone=no">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black">
```

#### 禁用不必要的功能
- 禁用右键菜单
- 禁用文本选择
- 禁用图片拖拽

### 3. 性能优化

#### 代码分割和懒加载
```dart
// 使用延迟加载减少初始包大小
import 'package:flutter/material.dart' deferred as material;

// 图片懒加载
class LazyImage extends StatelessWidget {
  final String src;
  
  @override
  Widget build(BuildContext context) {
    return FadeInImage.assetNetwork(
      placeholder: 'assets/images/loading.png',
      image: src,
      fit: BoxFit.cover,
    );
  }
}
```

#### 资源优化
- 压缩图片资源
- 使用WebP格式
- 移除未使用的资源

### 4. 微信分享功能

#### 添加微信JS-SDK支持
```html
<!-- 在web/index.html中添加 -->
<script src="https://res.wx.qq.com/open/js/jweixin-1.6.0.js"></script>
```

#### 配置分享信息
```dart
// 添加分享配置
class WeChatShare {
  static void configShare() {
    if (kIsWeb) {
      js.context.callMethod('configWeChatShare', [
        {
          'title': 'A Dark Room - 黑暗房间',
          'desc': '一个引人入胜的文字冒险游戏',
          'link': window.location.href,
          'imgUrl': '${window.location.origin}/icons/Icon-512.png'
        }
      ]);
    }
  }
}
```

### 5. 存储优化

#### 使用localStorage替代SharedPreferences
```dart
import 'dart:html' as html;

class WebStorage {
  static void setString(String key, String value) {
    if (kIsWeb) {
      html.window.localStorage[key] = value;
    }
  }
  
  static String? getString(String key) {
    if (kIsWeb) {
      return html.window.localStorage[key];
    }
    return null;
  }
}
```

## 部署配置

### 1. 构建优化
```bash
# 构建Web版本
flutter build web --release --web-renderer html

# 启用代码压缩
flutter build web --release --web-renderer html --dart-define=flutter.web.use_skia=false
```

### 2. 服务器配置
```nginx
# nginx配置示例
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    # SSL配置（微信要求HTTPS）
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        root /path/to/flutter/build/web;
        try_files $uri $uri/ /index.html;
        
        # 缓存配置
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 3. CDN加速
- 使用CDN加速静态资源
- 启用Gzip压缩
- 配置浏览器缓存

## 测试清单

### 功能测试
- [ ] 游戏核心功能正常
- [ ] 存档加载正常
- [ ] 多语言切换正常
- [ ] 触摸操作流畅

### 兼容性测试
- [ ] 微信内嵌浏览器
- [ ] iOS Safari
- [ ] Android Chrome
- [ ] 不同屏幕尺寸

### 性能测试
- [ ] 首屏加载时间 < 3秒
- [ ] 交互响应时间 < 100ms
- [ ] 内存使用合理

## 预估工作量
- 界面适配：2-3天
- 性能优化：1-2天
- 兼容性调试：1-2天
- 部署配置：1天
- 总计：5-8天

## 注意事项
1. 微信浏览器有一些限制，如音频播放需要用户交互触发
2. 需要HTTPS域名才能在微信中正常访问
3. 建议添加加载动画提升用户体验
4. 考虑添加离线缓存支持
