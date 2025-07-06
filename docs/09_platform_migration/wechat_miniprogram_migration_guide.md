# A Dark Room 微信小程序移植指南

## 概述
由于Flutter和微信小程序使用完全不同的技术栈，无法直接移植。需要重新开发微信小程序版本。

## 技术栈对比

### Flutter (当前项目)
- 语言：Dart
- UI：Flutter Widgets
- 状态管理：Provider
- 本地存储：SharedPreferences
- 多语言：flutter_localizations

### 微信小程序 (目标平台)
- 语言：JavaScript
- UI：WXML + WXSS
- 状态管理：Page data / 全局状态
- 本地存储：wx.setStorageSync
- 多语言：自定义实现

## 移植策略

### 第一阶段：项目结构搭建
1. 创建微信小程序项目
2. 设计页面结构
   - pages/room/room (小黑屋)
   - pages/outside/outside (漫漫尘途)
   - pages/fabricator/fabricator (制造器)
   - pages/ship/ship (破旧星舰)
   - pages/world/world (世界地图)

### 第二阶段：核心逻辑移植
1. 游戏状态管理 (lib/core/game_state.dart → utils/gameState.js)
2. 事件系统 (lib/events/ → utils/events.js)
3. 本地化系统 (assets/lang/ → utils/i18n.js)
4. 存档系统 (shared_preferences → wx.storage)

### 第三阶段：UI界面实现
1. 复制Flutter界面布局到WXML
2. 转换样式到WXSS
3. 实现交互逻辑

### 第四阶段：测试和优化
1. 功能测试
2. 性能优化
3. 微信小程序审核准备

## 关键文件映射

### 核心逻辑文件
- `lib/core/game_state.dart` → `utils/gameState.js`
- `lib/core/game_manager.dart` → `utils/gameManager.js`
- `lib/modules/room.dart` → `utils/modules/room.js`
- `lib/modules/outside.dart` → `utils/modules/outside.js`
- `lib/modules/fabricator.dart` → `utils/modules/fabricator.js`
- `lib/modules/ship.dart` → `utils/modules/ship.js`

### 界面文件
- `lib/screens/room_screen.dart` → `pages/room/room.wxml + room.js`
- `lib/screens/outside_screen.dart` → `pages/outside/outside.wxml + outside.js`
- `lib/screens/fabricator_screen.dart` → `pages/fabricator/fabricator.wxml + fabricator.js`
- `lib/screens/ship_screen.dart` → `pages/ship/ship.wxml + ship.js`

### 资源文件
- `assets/lang/zh.json` → `utils/i18n/zh.js`
- `assets/lang/en.json` → `utils/i18n/en.js`
- `assets/images/` → `images/`
- `assets/audio/` → `audio/` (需要转换为微信小程序支持的格式)

## 开发工具和环境
1. 微信开发者工具
2. 微信小程序开发文档
3. 小程序云开发 (可选，用于数据同步)

## 注意事项
1. 微信小程序有包大小限制 (2MB主包 + 20MB分包)
2. 某些API需要用户授权
3. 审核要求较严格
4. 需要ICP备案和软件著作权

## 预估工作量
- 项目搭建：1-2天
- 核心逻辑移植：5-7天
- UI界面实现：7-10天
- 测试优化：3-5天
- 总计：16-24天

## 替代方案
如果不想重新开发，可以考虑：
1. 发布为H5网页版本，在微信中以网页形式访问
2. 开发微信公众号版本
3. 考虑其他跨平台方案如uni-app
