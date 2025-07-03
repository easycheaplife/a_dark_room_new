# Energy Blade 本地化修复

**日期**: 2025-07-03  
**类型**: 本地化修复  
**状态**: 已完成  

## 问题描述

用户反馈在中文语言环境下，部分物品名称显示为英文键值而不是中文翻译。具体表现为：

- 在背包界面中，"energy blade" 显示为 "resources.energy blade" 而不是中文 "能量刃"
- 其他制造器相关物品也可能存在类似问题

![问题截图](用户提供的截图显示了这个问题)

## 问题分析

### 根本原因

通过代码分析发现，问题出现在本地化文件 `assets/lang/zh.json` 和 `assets/lang/en.json` 的 `resources` 部分缺少制造器相关物品的翻译。

### 代码逻辑分析

物品名称显示逻辑位于多个文件中：
- `lib/screens/world_screen.dart` - `_getItemDisplayName()` 方法
- `lib/screens/combat_screen.dart` - `_getItemDisplayName()` 方法  
- `lib/screens/events_screen.dart` - `_getItemDisplayName()` 方法

这些方法都使用 `localization.translate('resources.$itemName')` 来获取物品的本地化名称：

```dart
String _getItemDisplayName(String itemName) {
  final localization = Localization();
  final translatedName = localization.translate('resources.$itemName');

  // 如果翻译存在且不等于原键名，返回翻译
  if (translatedName != 'resources.$itemName') {
    return translatedName;
  }

  // 否则返回原名称
  return itemName;
}
```

当本地化系统找不到对应的翻译键值时，会返回原始键名，导致显示 "resources.energy blade"。

## 修复方案

### 1. 补充中文本地化

**修改文件**: `assets/lang/zh.json`

在 `resources` 部分添加缺失的制造器物品翻译：

```json
{
  "resources": {
    // ... 现有翻译 ...
    "energy blade": "能量刃",
    "plasma rifle": "等离子步枪",
    "disruptor": "干扰器",
    "hypo": "注射器",
    "stim": "兴奋剂",
    "glowstone": "发光石",
    "kinetic armour": "动能护甲"
  }
}
```

### 2. 补充英文本地化

**修改文件**: `assets/lang/en.json`

在 `resources` 部分添加对应的英文翻译：

```json
{
  "resources": {
    // ... 现有翻译 ...
    "energy blade": "energy blade",
    "plasma rifle": "plasma rifle",
    "disruptor": "disruptor",
    "hypo": "hypo",
    "stim": "stim",
    "glowstone": "glowstone",
    "kinetic armour": "kinetic armour"
  }
}
```

## 修复实施

### 修改详情

**文件**: `assets/lang/zh.json` (第169-181行)
```diff
    "laser rifle": "激光步枪",
    "bayonet": "刺刀",
    "bone spear": "骨枪",
    "iron sword": "铁剑",
    "steel sword": "钢剑",
-   "rifle": "步枪"
+   "rifle": "步枪",
+   "energy blade": "能量刃",
+   "plasma rifle": "等离子步枪",
+   "disruptor": "干扰器",
+   "hypo": "注射器",
+   "stim": "兴奋剂",
+   "glowstone": "发光石",
+   "kinetic armour": "动能护甲"
```

**文件**: `assets/lang/en.json` (第177-189行)
```diff
    "laser rifle": "laser rifle",
    "bayonet": "bayonet",
    "bone spear": "bone spear",
    "iron sword": "iron sword",
    "steel sword": "steel sword",
-   "rifle": "rifle"
+   "rifle": "rifle",
+   "energy blade": "energy blade",
+   "plasma rifle": "plasma rifle",
+   "disruptor": "disruptor",
+   "hypo": "hypo",
+   "stim": "stim",
+   "glowstone": "glowstone",
+   "kinetic armour": "kinetic armour"
```

## 测试验证

1. 启动应用：`flutter run -d chrome`
2. 切换到中文语言
3. 检查背包界面中 energy blade 等物品是否正确显示中文名称
4. 切换到英文语言验证英文显示正常

## 相关文件

- `assets/lang/zh.json` - 中文本地化文件
- `assets/lang/en.json` - 英文本地化文件
- `lib/screens/world_screen.dart` - 世界界面物品显示
- `lib/screens/combat_screen.dart` - 战斗界面物品显示
- `lib/screens/events_screen.dart` - 事件界面物品显示

## 更新日期

2025-07-03

## 更新日志

- 2025-07-03: 修复 energy blade 等制造器物品在 resources 部分的本地化缺失问题
