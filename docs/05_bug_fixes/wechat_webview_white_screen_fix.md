# 微信内嵌Flutter Web白屏问题修复方案

## 问题描述

微信小程序内嵌Flutter Web项目（https://8.140.248.32/）显示"正在加载游戏"后出现白屏，而使用百度等其他网站可以正常显示。

## 问题分析

### 1. 域名白名单问题 ⚠️ **主要原因**
- **IP地址限制**: 微信小程序不允许使用IP地址作为业务域名
- **域名白名单**: 必须在微信小程序后台配置合法的域名
- **HTTPS要求**: 必须使用有效的HTTPS证书

### 2. Flutter Web渲染器兼容性问题
- **CanvasKit渲染器**: 在微信浏览器中可能不完全支持
- **WebGL限制**: 微信浏览器对WebGL支持有限制
- **WebAssembly支持**: 微信环境对WASM支持不完整

### 3. 资源加载问题
- **跨域限制**: 微信环境对跨域资源加载有严格限制
- **Content Security Policy**: 微信浏览器有严格的CSP策略
- **Service Worker**: 微信环境可能不支持Service Worker

## 修复方案

### 方案1: 域名配置修复（推荐）

#### 1.1 申请合法域名
```bash
# 建议使用域名替代IP地址
# 例如: https://adarkroom.yourdomain.com
```

#### 1.2 配置HTTPS证书
```nginx
server {
    listen 443 ssl;
    server_name adarkroom.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        root /path/to/flutter/build/web;
        try_files $uri $uri/ /index.html;
        
        # 添加微信兼容性头部
        add_header X-Frame-Options ALLOWALL;
        add_header Access-Control-Allow-Origin *;
    }
}
```

#### 1.3 微信小程序后台配置
1. 登录微信小程序后台
2. 进入"开发" -> "开发设置" -> "服务器域名"
3. 在"业务域名"中添加: `https://adarkroom.yourdomain.com`

### 方案2: Flutter Web微信兼容性优化

#### 2.1 修改渲染器配置
```dart
// 在web/index.html中修改Flutter配置
window.addEventListener('load', function(ev) {
  // 检测微信环境，使用HTML渲染器
  const isWeChat = /MicroMessenger/i.test(navigator.userAgent);
  
  _flutter.loader.loadEntrypoint({
    serviceWorker: {
      serviceWorkerVersion: serviceWorkerVersion,
    },
    onEntrypointLoaded: function(engineInitializer) {
      engineInitializer.initializeEngine({
        renderer: isWeChat ? "html" : "auto", // 微信环境强制使用HTML渲染器
        hostElement: document.querySelector("#flutter-view")
      }).then(function(appRunner) {
        appRunner.runApp();
      });
    }
  });
});
```

#### 2.2 添加微信环境检测和错误处理
```javascript
// 在web/index.html中添加
function handleWeChatEnvironment() {
  if (!/MicroMessenger/i.test(navigator.userAgent)) {
    return;
  }
  
  console.log('检测到微信环境，应用兼容性配置');
  
  // 禁用Service Worker
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
      for(let registration of registrations) {
        registration.unregister();
      }
    });
  }
  
  // 添加错误监听
  window.addEventListener('error', function(e) {
    console.error('微信环境错误:', e);
    // 发送错误信息到小程序
    if (window.wx && window.wx.miniProgram) {
      window.wx.miniProgram.postMessage({
        data: { type: 'error', message: e.message }
      });
    }
  });
}

// 页面加载时执行
handleWeChatEnvironment();
```

### 方案3: 临时测试方案

#### 3.1 使用微信开发者工具测试
1. 在微信开发者工具中打开小程序项目
2. 在"详情" -> "本地设置"中勾选"不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书"
3. 这样可以临时测试IP地址

#### 3.2 构建简化版本
```bash
# 构建针对微信优化的版本
flutter build web --web-renderer html --release
```

## 实施步骤

### 第一步: 立即可行的修复
1. 申请域名并配置HTTPS证书
2. 在微信小程序后台添加业务域名
3. 修改小程序配置文件中的h5Url

### 第二步: Flutter Web优化
1. 修改渲染器配置为HTML模式
2. 添加微信环境检测
3. 优化资源加载策略

### 第三步: 测试验证
1. 在微信开发者工具中测试
2. 在真实微信环境中测试
3. 收集错误日志并优化

## 预期效果

修复后应该能够：
- ✅ 在微信小程序中正常加载Flutter Web页面
- ✅ 游戏功能正常运行
- ✅ 音频播放正常（如果微信环境支持）
- ✅ 数据保存和加载正常

## 注意事项

1. **域名是关键**: IP地址是导致白屏的主要原因
2. **渲染器选择**: 微信环境建议使用HTML渲染器
3. **证书有效性**: 确保HTTPS证书有效且被微信信任
4. **测试环境**: 开发阶段可以在开发者工具中关闭域名校验进行测试

## 相关文件

- `wechat_miniprogram/config/env.js` - 环境配置
- `web/index.html` - Flutter Web入口文件
- `lib/utils/wechat_adapter.dart` - 微信适配器
- `lib/utils/wechat_debug_helper.dart` - 微信调试助手
