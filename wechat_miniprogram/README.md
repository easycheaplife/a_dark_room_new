# A Dark Room 微信小程序

这是A Dark Room游戏的微信小程序版本，采用内嵌H5的方式实现。

## 项目结构

```
wechat_miniprogram/
├── app.js                 # 小程序入口文件
├── app.json              # 小程序配置文件
├── pages/
│   └── game/
│       ├── game.js       # 游戏页面逻辑
│       ├── game.wxml     # 游戏页面模板
│       ├── game.wxss     # 游戏页面样式
│       └── game.json     # 游戏页面配置
└── utils/
    ├── storage.js        # 存储管理工具
    └── bridge.js         # 通信桥接工具
```

## 功能特性

### 核心功能
- 内嵌H5游戏页面
- 游戏数据本地存储
- 小程序与H5双向通信
- 自动保存和加载游戏进度

### 通信功能
- 保存游戏数据到小程序存储
- 从小程序加载游戏数据
- 显示系统提示消息
- 震动反馈
- 分享功能
- 退出确认

### 存储功能
- 游戏数据自动备份
- 用户设置保存
- 存储空间管理
- 数据恢复功能

## 配置说明

### 1. 环境配置设置
项目使用环境配置文件来管理不同环境的设置，确保敏感信息不会泄露。

#### 初始化配置
```bash
# 进入小程序目录
cd wechat_miniprogram

# 复制环境配置示例文件
cp config/env.example.js config/env.js

# 编辑配置文件，设置实际的H5页面地址
# 注意：config/env.js 文件不会被提交到版本控制
```

#### 配置文件说明
- `config/env.example.js` - 环境配置示例文件（可提交到版本控制）
- `config/env.js` - 实际环境配置文件（包含敏感信息，不提交到版本控制）

#### 环境配置项
```javascript
{
  h5Url: 'https://your-domain.com/a-dark-room',  // H5页面地址
  apiBaseUrl: 'https://api.your-domain.com',     // API地址
  debug: false,                                   // 调试模式
  logLevel: 'error',                             // 日志级别
  appId: 'your-production-appid'                 // 微信小程序AppID
}
```

### 2. 构建和部署
使用构建脚本来管理不同环境的部署：

```bash
# 开发环境构建
node scripts/build.js development

# 测试环境构建
node scripts/build.js staging

# 生产环境构建
node scripts/build.js production
```

### 3. 配置业务域名
在微信小程序后台配置业务域名，添加H5页面的域名。

### 4. 配置HTTPS
确保H5页面使用HTTPS协议，微信小程序要求所有网络请求都必须是HTTPS。

## 开发指南

### 1. 本地开发
1. 使用微信开发者工具打开项目
2. 配置本地H5开发服务器（需要HTTPS）
3. 修改 `app.js` 中的 `h5Url` 为本地地址

### 2. 消息通信
H5页面可以通过以下方式与小程序通信：

```javascript
// 保存游戏数据
wx.miniProgram.postMessage({
  data: {
    type: 'saveGame',
    gameData: gameState
  }
});

// 显示提示
wx.miniProgram.postMessage({
  data: {
    type: 'showToast',
    text: '操作成功',
    icon: 'success'
  }
});

// 退出游戏
wx.miniProgram.postMessage({
  data: {
    type: 'exitGame'
  }
});
```

### 3. 数据传递
小程序会通过URL参数向H5传递数据：

```
https://your-domain.com/a-dark-room?from=miniprogram&gameData=...&settings=...
```

H5页面可以解析这些参数来获取游戏数据和设置。

## 部署流程

### 1. 准备H5页面
1. 构建Flutter Web项目
2. 部署到HTTPS服务器
3. 确保域名已备案

### 2. 配置小程序
1. 在微信公众平台注册小程序
2. 配置业务域名
3. 上传小程序代码

### 3. 提交审核
1. 完善小程序信息
2. 提交审核
3. 发布上线

## 注意事项

### 技术限制
1. web-view组件会占满整个页面
2. 无法直接从小程序向H5发送消息
3. H5页面的某些功能可能受限

### 性能优化
1. 优化H5页面加载速度
2. 减少不必要的数据传输
3. 合理使用本地存储

### 用户体验
1. 添加加载动画
2. 处理网络错误
3. 提供重试机制

## 常见问题

### Q: H5页面无法加载？
A: 检查域名配置、HTTPS证书、网络连接

### Q: 游戏数据丢失？
A: 检查存储权限、数据格式、备份机制

### Q: 无法接收H5消息？
A: 检查消息格式、事件绑定、调试日志

## 更新日志

### v1.0.0
- 初始版本
- 基础的内嵌H5功能
- 游戏数据存储
- 双向通信机制