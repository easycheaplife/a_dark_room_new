# A Dark Room 微信发布完整指南

## 📋 概述

本指南详细说明如何将A Dark Room Flutter项目发布到微信中，让用户可以在微信浏览器中流畅游玩。

## 🚀 发布方式选择

### 方式一：H5网页版（推荐）
- **优势**：开发成本低，快速上线，维护简单
- **劣势**：性能略低于原生小程序
- **适用场景**：快速验证市场，初期推广

### 方式二：微信小程序
- **优势**：性能最佳，用户体验好，微信生态集成度高
- **劣势**：需要重新开发，开发周期长
- **适用场景**：长期运营，追求最佳用户体验

## 📱 方式一：H5网页版发布（推荐）

### 第一步：项目构建

#### 1. 环境准备
```bash
# 确保Flutter环境
flutter doctor

# 检查Web支持
flutter config --enable-web
```

#### 2. 微信优化构建
```bash
# 使用项目提供的构建脚本（推荐）
./scripts/build_web.sh wechat -c -o -r

# 或手动构建
flutter build web --release \
  --web-renderer html \
  --dart-define=flutter.web.use_skia=false \
  --dart-define=flutter.web.auto_detect=false
```

#### 3. 验证构建结果
```bash
# 本地测试
flutter run -d chrome

# 检查构建文件
ls -la build/web/
```

### 第二步：服务器部署

#### 1. 选择服务器
**推荐服务商**：
- 阿里云ECS + CDN
- 腾讯云CVM + CDN  
- 华为云ECS + CDN
- Vercel（免费选项）
- Netlify（免费选项）

#### 2. 域名和SSL证书
```bash
# 必须要求
- 已备案的域名
- 有效的SSL证书（微信要求HTTPS）
- 域名解析到服务器IP
```

#### 3. Nginx配置示例
```nginx
server {
    listen 443 ssl http2;
    server_name yourgame.com;
    
    # SSL证书配置
    ssl_certificate /etc/ssl/certs/yourgame.com.pem;
    ssl_certificate_key /etc/ssl/private/yourgame.com.key;
    
    # 网站根目录
    root /var/www/adarkroom/build/web;
    index index.html;
    
    # Flutter路由支持
    location / {
        try_files $uri $uri/ /index.html;
        
        # 微信浏览器优化
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;
}

# HTTP重定向到HTTPS
server {
    listen 80;
    server_name yourgame.com;
    return 301 https://$server_name$request_uri;
}
```

### 第三步：微信公众号配置

#### 1. 注册微信公众号
- 访问 [微信公众平台](https://mp.weixin.qq.com/)
- 注册服务号或订阅号
- 完成认证（服务号需要认证才能使用JS-SDK）

#### 2. 配置JS接口安全域名
```
登录微信公众平台 → 设置与开发 → 公众号设置 → 功能设置 → JS接口安全域名
添加：yourgame.com
```

#### 3. 获取AppID和AppSecret
```
登录微信公众平台 → 开发 → 基本配置
记录：AppID 和 AppSecret（用于分享功能）
```

### 第四步：微信分享功能配置

#### 1. 后端签名服务（可选）
如果需要完整的分享功能，需要搭建签名服务：

```javascript
// Node.js示例
const express = require('express');
const crypto = require('crypto');
const app = express();

app.get('/api/wechat/signature', (req, res) => {
    const url = req.query.url;
    const timestamp = Math.floor(Date.now() / 1000);
    const nonceStr = Math.random().toString(36).substr(2, 15);
    
    // 获取access_token和jsapi_ticket的逻辑
    const jsapi_ticket = getJsapiTicket(); // 需要实现
    
    const signature = generateSignature(jsapi_ticket, timestamp, nonceStr, url);
    
    res.json({
        appId: 'YOUR_APP_ID',
        timestamp,
        nonceStr,
        signature
    });
});
```

#### 2. 前端分享配置
项目已经集成了微信分享功能，会自动配置基本分享信息。

### 第五步：测试和优化

#### 1. 微信开发者工具测试
- 下载 [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
- 选择"公众号网页调试"
- 输入游戏URL进行测试

#### 2. 真机测试
```
测试设备：
- iPhone微信浏览器
- Android微信浏览器
- 不同版本的微信客户端

测试内容：
- 游戏加载速度
- 触摸操作响应
- 界面适配效果
- 分享功能
- 存档功能
```

#### 3. 性能优化
```bash
# 启用CDN加速
- 配置阿里云CDN或腾讯云CDN
- 启用Gzip压缩
- 配置浏览器缓存

# 监控配置
- 添加百度统计或Google Analytics
- 配置错误监控
```

## 🎯 方式二：微信小程序发布

### 技术方案选择

#### 1. uni-app重新开发（推荐）
```bash
# 创建uni-app项目
npx @dcloudio/uvm@latest create adarkroom-miniprogram

# 参考现有Flutter代码逻辑
# 使用Vue.js语法重新实现游戏逻辑
```

#### 2. 原生小程序开发
```bash
# 下载微信开发者工具
# 创建小程序项目
# 参考docs/09_platform_migration/目录下的迁移指南
```

### 开发工作量评估
- **uni-app方案**：10-15天
- **原生小程序**：16-24天
- **详细分析**：参考 `docs/09_platform_migration/wechat_miniprogram_migration_guide.md`

## 📊 发布流程总结

### H5网页版发布流程
```
1. 项目构建 (1小时)
   ↓
2. 服务器部署 (2-4小时)
   ↓
3. 域名SSL配置 (1-2小时)
   ↓
4. 微信公众号配置 (1小时)
   ↓
5. 测试优化 (2-4小时)
   ↓
6. 正式发布 ✅
```

### 小程序发布流程
```
1. 技术方案选择 (1天)
   ↓
2. 重新开发 (10-24天)
   ↓
3. 小程序审核 (1-7天)
   ↓
4. 正式发布 ✅
```

## 🎉 推荐方案

### 立即可行：H5网页版
1. **使用现有构建脚本**：`./scripts/build_web.sh wechat -c -o -r`
2. **部署到云服务器**：配置HTTPS和域名
3. **配置微信公众号**：设置JS安全域名
4. **测试发布**：在微信中测试游戏

### 长期规划：小程序版本
1. **选择uni-app**：基于现有代码重新开发
2. **分阶段实现**：先实现核心功能，再完善高级功能
3. **用户反馈**：根据H5版本的用户反馈优化小程序版本

## 🔗 相关资源

- [微信公众平台](https://mp.weixin.qq.com/)
- [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
- [微信JS-SDK文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html)
- [uni-app官网](https://uniapp.dcloud.net.cn/)

## 📞 技术支持

如果在发布过程中遇到问题，可以参考：
- `docs/08_deployment/` - 部署相关文档
- `docs/05_bug_fixes/` - 常见问题解决方案
- `docs/QUICK_NAVIGATION.md` - 快速导航指南

---

**建议**：先发布H5网页版进行市场验证，根据用户反馈决定是否投入资源开发小程序版本。
