# 08_deployment - 部署相关文档

本目录包含A Dark Room Flutter项目的部署相关文档，主要涵盖Web平台和微信浏览器的部署指南。

## 📁 目录结构

### 部署指南
- `web_deployment_guide.md` - Web平台部署完整指南
  - 构建配置和命令
  - 服务器配置（Nginx/Apache）
  - CDN配置示例
  - 性能优化建议

- `wechat_publishing_guide.md` - 微信发布完整指南
  - H5网页版发布流程
  - 微信小程序开发方案
  - 微信公众号配置
  - 技术方案对比分析

- `quick_wechat_deployment.md` - 微信快速发布指南
  - 5分钟快速部署流程
  - 免费部署方案（Vercel/Netlify）
  - 测试清单和常见问题
  - 一键部署脚本使用

### 微信平台优化
- `flutter_web_wechat_optimization.md` - Flutter Web微信优化技术方案
  - 移动端界面适配
  - 微信浏览器兼容性
  - 性能优化策略
  - 存储系统优化

- `wechat_optimization_summary.md` - 微信浏览器优化完成总结
  - 优化工作总结
  - 技术实现亮点
  - 测试结果报告
  - 部署准备清单

## 🎯 使用指南

### 快速部署
1. **5分钟快速发布**：查看 `quick_wechat_deployment.md`
2. **完整部署流程**：查看 `wechat_publishing_guide.md`
3. **自动化脚本**：使用 `scripts/deploy_wechat.sh` 一键部署
4. **构建优化**：使用 `scripts/build_web.sh` 进行构建

### 微信平台
1. 参考 `flutter_web_wechat_optimization.md` 了解技术实现
2. 查看 `wechat_optimization_summary.md` 了解优化成果
3. 确保HTTPS部署和微信域名配置

## 🔗 相关目录
- `../03_implementation/` - 技术实现文档
- `../09_platform_migration/` - 平台迁移方案
- `../06_optimizations/` - 性能优化文档

## 📝 维护说明
- 部署相关的新文档请添加到此目录
- 更新部署流程时请同步更新相关文档
- 重要变更请在CHANGELOG.md中记录
