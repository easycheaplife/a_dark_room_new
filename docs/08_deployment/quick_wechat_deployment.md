# A Dark Room 微信快速发布指南

## 🚀 5分钟快速发布

### 第一步：构建项目 (1分钟)
```bash
# 使用自动化脚本构建
./scripts/deploy_wechat.sh build -c

# 构建完成后，文件位于 build/web/ 目录
```

### 第二步：本地测试 (1分钟)
```bash
# 启动本地测试服务器
./scripts/deploy_wechat.sh local

# 在浏览器中访问 http://localhost:8000 测试游戏
```

### 第三步：选择部署方式 (3分钟)

#### 方式A：免费部署（推荐新手）

**使用Vercel（免费）**
1. 注册 [Vercel账号](https://vercel.com)
2. 安装Vercel CLI：`npm i -g vercel`
3. 在项目根目录运行：`vercel --prod`
4. 选择 `build/web` 作为部署目录
5. 获得HTTPS域名，如：`https://adarkroom-xxx.vercel.app`

**使用Netlify（免费）**
1. 注册 [Netlify账号](https://netlify.com)
2. 安装Netlify CLI：
    npm install -g netlify-cli
    netlify login
    netlify deploy --prod --dir=build/web
3. 获得HTTPS域名，如：`https://adarkroom-xxx.netlify.app`


#### 方式B：云服务器部署

**阿里云/腾讯云ECS**
```bash
# 上传到服务器
./scripts/deploy_wechat.sh prod --server your-server.com --path /var/www/adarkroom

# 配置Nginx（参考完整部署指南）
```

### 第四步：微信配置 (可选)

如果需要分享功能：
1. 注册微信公众号
2. 在公众号后台设置JS安全域名
3. 配置分享信息

## 📱 测试清单

### 基础测试
- [ ] 游戏正常加载
- [ ] 界面适配移动端
- [ ] 触摸操作正常
- [ ] 存档功能正常

### 微信浏览器测试
- [ ] 在微信中打开游戏链接
- [ ] 检查界面显示效果
- [ ] 测试触摸响应
- [ ] 验证分享功能（如已配置）

## 🎯 常见问题

**Q: 游戏加载白屏？**
A: 检查HTTPS配置，微信要求HTTPS访问

**Q: 触摸操作不灵敏？**
A: 项目已优化移动端，确保使用最新构建版本

**Q: 分享功能不工作？**
A: 需要配置微信公众号和JS安全域名

**Q: 游戏卡顿？**
A: 项目已针对微信浏览器优化，建议使用CDN加速

## 📞 获取帮助

- 完整部署指南：`docs/08_deployment/wechat_publishing_guide.md`
- 问题排查：`docs/05_bug_fixes/`
- 快速导航：`docs/QUICK_NAVIGATION.md`

## 🎉 发布成功！

恭喜！您的A Dark Room游戏现在可以在微信中流畅运行了！

**分享您的游戏**：
- 将游戏链接分享给朋友
- 在微信群中推广
- 考虑后续开发小程序版本

---

**提示**：这是H5网页版本，如需最佳性能可考虑开发微信小程序版本。
