# 库存本地化修复

## 问题描述

在库存界面中，"wagon"（马车）物品没有被正确翻译成中文，显示为英文原文而不是中文"马车"。

## 问题分析

通过检查本地化文件发现：

1. 在 `assets/lang/zh.json` 的 `world.crafting` 部分已经有 "wagon": "马车" 的翻译
2. 但在 `resources` 部分缺少 "wagon" 的翻译条目
3. 库存界面使用的是 `resources.$itemName` 的翻译路径
4. 当在 `resources` 部分找不到翻译时，会显示原英文名称

## 修复方案

在本地化文件的 `resources` 部分添加缺失的翻译条目：

### 中文文件 (assets/lang/zh.json)

在 `resources` 部分添加：
```json
"wagon": "马车",
"convoy": "车队",
```

### 英文文件 (assets/lang/en.json)

在 `resources` 部分添加：
```json
"wagon": "wagon",
"convoy": "convoy",
```

## 修复位置

- **文件**: `assets/lang/zh.json`
- **行数**: 154-170
- **文件**: `assets/lang/en.json`  
- **行数**: 155-178

## 测试验证

1. 启动应用程序：`flutter run -d chrome --web-port=3000`
2. 进入游戏，获得wagon物品
3. 查看库存界面，确认显示为"马车"而不是"wagon"

## 相关代码

库存物品名称翻译逻辑位于：
- `lib/screens/world_screen.dart` - `_getItemDisplayName()` 方法
- `lib/screens/combat_screen.dart` - `_getItemDisplayName()` 方法  
- `lib/screens/events_screen.dart` - `_getItemDisplayName()` 方法
- `lib/modules/room.dart` - `getLocalizedName()` 方法

这些方法都使用 `localization.translate('resources.$itemName')` 来获取物品的本地化名称。

## 更新日期

2025-06-27

## 更新日志

- 2025-06-27: 修复wagon和convoy在resources部分的本地化缺失问题
