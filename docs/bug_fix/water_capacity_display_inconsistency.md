# 水容量显示不一致问题修复

## 🐛 问题描述

**问题**: 地图探索时出发时背包的水的数量和进入地图后水的数量不一致，背包只有10，进入地图30，后者是对的。

**影响**: 玩家在准备出发时看到的水量信息不准确，可能导致错误的决策。

## 🔍 问题分析

### 根本原因

在`lib/screens/path_screen.dart`文件中，水量显示被硬编码为固定值10，而不是从World模块获取实际的最大水量。

### 代码位置

**问题代码**:
```dart
// lib/screens/path_screen.dart:264-266
Widget _buildWaterRow(StateManager stateManager, Localization localization) {
  // 这里应该从World模块获取最大水量，暂时使用固定值
  final maxWater = 10;  // ❌ 硬编码固定值
```

**正确逻辑**:
- 背包界面应该显示玩家当前可携带的最大水量
- 最大水量根据玩家拥有的水容器升级物品计算：
  - 基础: 10水
  - 水壶(waterskin): +10 = 20水
  - 水桶(cask): +20 = 30水  
  - 水罐(water tank): +50 = 60水
  - 流体回收器(fluid recycler): +100 = 110水

## 🔧 修复方案

### 1. 添加World模块导入

```dart
// lib/screens/path_screen.dart:1-10
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../modules/path.dart';
import '../modules/world.dart';  // ✅ 添加World模块导入
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/game_button.dart';
import '../widgets/unified_stores_container.dart';
import '../core/logger.dart';
```

### 2. 修复水量显示逻辑

```dart
// lib/screens/path_screen.dart:264-266
Widget _buildWaterRow(StateManager stateManager, Localization localization) {
  // 从World模块获取实际的最大水量
  final maxWater = World.instance.getMaxWater();  // ✅ 使用正确的水量计算
  
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        localization.translate('resources.water'),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: 'Times New Roman',
        ),
      ),
      Text(
        '$maxWater',  // ✅ 显示正确的最大水量
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: 'Times New Roman',
        ),
      ),
    ],
  );
}
```

## ✅ 修复结果

### 修复前
- 背包界面始终显示水量为10
- 与实际游戏中的水容量不符
- 玩家无法准确了解自己的水资源状况

### 修复后
- 背包界面正确显示当前最大水量
- 根据玩家拥有的水容器升级物品动态计算
- 与地图探索中的水量显示保持一致

## 🧪 测试验证

### 自动化测试
运行单元测试验证水容量计算逻辑：
```bash
flutter test test/water_capacity_test.dart
```

### 手动测试步骤

#### 1. 启动游戏
```bash
flutter run -d chrome
```

#### 2. 测试基础水量 (10水)
1. 开始新游戏
2. 进入"漫漫尘途"界面
3. 检查水量显示应该为 **10**

#### 3. 测试水壶升级 (20水)
1. 在小黑屋制作水壶 (需要50皮革)
2. 进入"漫漫尘途"界面
3. 检查水量显示应该为 **20**

#### 4. 测试水桶升级 (30水)
1. 制作水桶 (需要100皮革 + 20铁)
2. 进入"漫漫尘途"界面
3. 检查水量显示应该为 **30**

#### 5. 测试水罐升级 (60水)
1. 制作水罐 (需要100铁 + 50钢)
2. 进入"漫漫尘途"界面
3. 检查水量显示应该为 **60**

#### 6. 测试流体回收器升级 (110水)
1. 制作流体回收器 (需要2外星合金)
2. 进入"漫漫尘途"界面
3. 检查水量显示应该为 **110**

#### 7. 验证地图探索一致性
1. 在任何水容器状态下出发探索
2. 进入地图后检查背包中的水量
3. 应该与出发前显示的最大水量一致

### 快速验证方法
使用浏览器开发者工具控制台：
```javascript
// 检查当前最大水量
console.log('最大水量:', World.instance.getMaxWater());

// 设置不同的水容器并测试
StateManager().set('stores.waterskin', 1);
console.log('水壶水量:', World.instance.getMaxWater()); // 应该是20

StateManager().set('stores.cask', 1);
console.log('水桶水量:', World.instance.getMaxWater()); // 应该是30
```

## 📝 相关文件

- `lib/screens/path_screen.dart` - 背包界面水量显示
- `lib/modules/world.dart` - 水量计算逻辑
- `lib/screens/world_screen.dart` - 地图界面水量显示
- `docs/water_capacity_growth_mechanism.md` - 水容量机制文档

## 🔗 相关问题

- 确保所有UI界面的水量显示都使用统一的计算逻辑
- 检查其他资源显示是否存在类似的硬编码问题

## 📅 修复信息

- **修复日期**: 2025-06-23
- **修复人员**: Augment Agent
- **问题严重程度**: 中等 (影响用户体验但不影响核心功能)
- **修复类型**: 界面显示修复
