# A Dark Room 微信小程序部署和发布指南

## 概述

本指南详细说明如何将A Dark Room微信小程序内嵌H5方案部署到生产环境并发布到微信小程序平台。

## 部署前准备

### 1. 环境要求
- 已备案的域名
- HTTPS SSL证书
- Web服务器（Nginx/Apache）
- 微信小程序开发者账号
- 微信开发者工具

### 2. 项目文件检查
确保以下文件已准备完毕：
```
项目根目录/
├── build/web/                    # Flutter Web构建产物
├── wechat_miniprogram/           # 微信小程序代码
│   ├── app.js
│   ├── app.json
│   ├── pages/game/
│   └── utils/
└── docs/09_platform_migration/  # 部署文档
```

## 第一阶段：H5页面部署

### 1.1 构建Flutter Web项目
```bash
# 进入项目目录
cd /path/to/a_dark_room_new

# 清理之前的构建
flutter clean

# 获取依赖
flutter pub get

# 构建生产版本
flutter build web --release \
  --web-renderer html \
  --dart-define=flutter.web.use_skia=false \
  --dart-define=flutter.web.auto_detect=false

# 检查构建结果
ls -la build/web/
```

### 1.2 服务器配置
#### Nginx配置示例
```nginx
# /etc/nginx/sites-available/adarkroom
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL证书配置
    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;

    # 网站根目录
    root /var/www/adarkroom;
    index index.html;

    # 主要路由
    location / {
        try_files $uri $uri/ /index.html;

        # 安全头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";

        # Gzip压缩
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types
            text/plain
            text/css
            application/json
            application/javascript
            text/xml
            application/xml
            application/xml+rss
            text/javascript
            image/svg+xml;
    }

    # Service Worker
    location /flutter_service_worker.js {
        expires 0;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 日志配置
    access_log /var/log/nginx/adarkroom_access.log;
    error_log /var/log/nginx/adarkroom_error.log;
}
```

### 1.3 部署脚本
```bash
#!/bin/bash
# deploy_h5.sh - H5页面部署脚本

set -e

# 配置变量
PROJECT_DIR="/path/to/a_dark_room_new"
WEB_ROOT="/var/www/adarkroom"
BACKUP_DIR="/var/backups/adarkroom"
DOMAIN="your-domain.com"

echo "🚀 开始部署A Dark Room H5页面..."

# 1. 备份现有文件
if [ -d "$WEB_ROOT" ]; then
    echo "📦 备份现有文件..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r "$WEB_ROOT" "$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S)"
fi

# 2. 构建项目
echo "🔨 构建Flutter Web项目..."
cd "$PROJECT_DIR"
flutter clean
flutter pub get
flutter build web --release \
  --web-renderer html \
  --dart-define=flutter.web.use_skia=false

# 3. 部署文件
echo "📤 部署文件到服务器..."
sudo mkdir -p "$WEB_ROOT"
sudo cp -r build/web/* "$WEB_ROOT/"

# 4. 设置权限
echo "🔐 设置文件权限..."
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo chmod -R 644 "$WEB_ROOT"
sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \;

# 5. 重启Nginx
echo "🔄 重启Nginx..."
sudo nginx -t
sudo systemctl reload nginx

# 6. 验证部署
echo "✅ 验证部署..."
curl -I "https://$DOMAIN" | head -n 1

echo "🎉 H5页面部署完成！"
echo "🌐 访问地址: https://$DOMAIN"
```

## 第二阶段：微信小程序配置

### 2.1 微信公众平台配置
1. 登录微信公众平台 (mp.weixin.qq.com)
2. 进入"开发" -> "开发管理" -> "开发设置"
3. 配置服务器域名：
   - request合法域名：`https://your-domain.com`
   - socket合法域名：`https://your-domain.com`
   - uploadFile合法域名：`https://your-domain.com`
   - downloadFile合法域名：`https://your-domain.com`
   - 业务域名：`https://your-domain.com`

### 2.2 小程序代码配置
修改 `wechat_miniprogram/app.js` 中的H5地址：
```javascript
// app.js
initGlobalData: function() {
  this.globalData = {
    // 修改为实际的H5页面地址
    h5Url: 'https://your-domain.com',
    // ... 其他配置
  };
}
```

### 2.3 小程序信息配置
创建 `wechat_miniprogram/app.json`：
```json
{
  "pages": [
    "pages/game/game"
  ],
  "window": {
    "backgroundTextStyle": "light",
    "navigationBarBackgroundColor": "#000000",
    "navigationBarTitleText": "A Dark Room",
    "navigationBarTextStyle": "white",
    "backgroundColor": "#000000"
  },
  "style": "v2",
  "sitemapLocation": "sitemap.json",
  "permission": {
    "scope.userLocation": {
      "desc": "你的位置信息将用于小程序位置接口的效果展示"
    }
  },
  "requiredBackgroundModes": ["audio"],
  "networkTimeout": {
    "request": 10000,
    "downloadFile": 10000
  }
}
```

## 第三阶段：小程序发布

### 3.1 开发者工具上传
1. 打开微信开发者工具
2. 导入小程序项目（`wechat_miniprogram` 目录）
3. 填写AppID（从微信公众平台获取）
4. 点击"上传"按钮
5. 填写版本号和项目备注

### 3.2 提交审核
1. 登录微信公众平台
2. 进入"版本管理"
3. 选择刚上传的版本
4. 点击"提交审核"
5. 填写审核信息：
   - 功能页面：pages/game/game
   - 标签：游戏、娱乐
   - 功能描述：文字冒险游戏

### 3.3 审核要点
确保满足微信小程序审核要求：
- 功能完整，无明显bug
- 界面美观，用户体验良好
- 内容健康，符合相关法规
- 隐私政策完善
- 用户协议清晰

## 第四阶段：监控和维护

### 4.1 部署监控脚本
```bash
#!/bin/bash
# monitor.sh - 部署监控脚本

DOMAIN="your-domain.com"
LOG_FILE="/var/log/adarkroom_monitor.log"

# 检查H5页面状态
check_h5_status() {
    local status=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN")
    if [ "$status" = "200" ]; then
        echo "$(date): H5页面正常 (HTTP $status)" >> "$LOG_FILE"
        return 0
    else
        echo "$(date): H5页面异常 (HTTP $status)" >> "$LOG_FILE"
        # 发送告警通知
        send_alert "H5页面访问异常: HTTP $status"
        return 1
    fi
}

# 检查SSL证书
check_ssl_cert() {
    local expiry=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    local expiry_timestamp=$(date -d "$expiry" +%s)
    local current_timestamp=$(date +%s)
    local days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

    if [ "$days_left" -lt 30 ]; then
        echo "$(date): SSL证书即将过期 ($days_left 天)" >> "$LOG_FILE"
        send_alert "SSL证书即将过期: $days_left 天"
    else
        echo "$(date): SSL证书正常 ($days_left 天有效)" >> "$LOG_FILE"
    fi
}

# 发送告警
send_alert() {
    local message="$1"
    # 这里可以集成邮件、短信或其他告警方式
    echo "ALERT: $message" >> "$LOG_FILE"
}

# 主监控循环
main() {
    echo "$(date): 开始监控检查" >> "$LOG_FILE"

    check_h5_status
    check_ssl_cert

    echo "$(date): 监控检查完成" >> "$LOG_FILE"
}

main
```

### 4.2 自动化部署
```yaml
# .github/workflows/deploy.yml - GitHub Actions自动部署
name: Deploy A Dark Room

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'

    - name: Install dependencies
      run: flutter pub get

    - name: Build web
      run: |
        flutter build web --release \
          --web-renderer html \
          --dart-define=flutter.web.use_skia=false

    - name: Deploy to server
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          cd /var/www/adarkroom
          sudo systemctl stop nginx
          sudo rm -rf *

    - name: Upload files
      uses: appleboy/scp-action@v0.1.4
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        source: "build/web/*"
        target: "/var/www/adarkroom"
        strip_components: 2

    - name: Restart services
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          sudo chown -R www-data:www-data /var/www/adarkroom
          sudo systemctl start nginx
          sudo systemctl reload nginx
```

## 第五阶段：发布后维护

### 5.1 性能监控
- 使用微信小程序后台监控用户访问数据
- 配置服务器监控（CPU、内存、磁盘、网络）
- 设置日志分析和告警

### 5.2 用户反馈处理
- 建立用户反馈渠道
- 定期检查小程序评价
- 及时修复发现的问题

### 5.3 版本更新流程
1. 开发新功能或修复bug
2. 在测试环境验证
3. 更新H5页面
4. 更新小程序代码（如需要）
5. 提交审核
6. 发布新版本

## 常见问题解决

### 1. H5页面无法加载
- 检查域名配置
- 验证SSL证书
- 确认服务器状态
- 检查防火墙设置

### 2. 小程序审核被拒
- 仔细阅读拒绝原因
- 修改相应内容
- 重新提交审核

### 3. 性能问题
- 优化H5页面加载速度
- 减少不必要的网络请求
- 启用CDN加速

### 4. 数据同步问题
- 检查通信机制
- 验证数据格式
- 确认存储权限

## 总结

通过以上步骤，可以成功将A Dark Room游戏部署为微信小程序内嵌H5方案。这个方案具有以下优势：

1. **开发效率高**：复用现有Flutter Web代码
2. **维护成本低**：只需维护一套H5代码
3. **功能完整**：保持游戏的完整功能
4. **用户体验好**：通过优化提供流畅体验

部署完成后，建议持续监控和优化，确保为用户提供最佳的游戏体验。