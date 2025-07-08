# 飞船模块建造和升级系统完善

**日期**: 2025-07-08  
**类型**: 功能优化  
**状态**: 已完成  

## 问题描述

用户要求完善飞船模块的建造和升级系统。经过分析发现，当前的飞船模块实现基本完整，但缺少一些原游戏的重要细节功能，特别是起飞冷却时间机制和相关的状态管理。

## 原游戏分析

根据原游戏`ship.js`文件分析，飞船系统具有以下特征：

### 核心功能
- **船体强化** (reinforceHull): 消耗1个外星合金，增加1点船体
- **引擎升级** (upgradeEngine): 消耗1个外星合金，增加1点推进器
- **起飞功能** (liftOff): 需要船体>0才能起飞

### 冷却时间机制
- **起飞冷却**: 120秒冷却时间
- **冷却触发**: 太空飞行坠毁后自动设置冷却
- **冷却清除**: 在起飞确认对话框中选择"等待"可清除冷却

### 按钮状态管理
- **起飞按钮禁用**: 当船体≤0时按钮被禁用
- **冷却期间禁用**: 冷却时间内按钮不可用
- **状态同步**: 强化船体后自动启用起飞按钮

## 实现方案

### 1. 添加冷却时间管理系统

**文件**: `lib/modules/ship.dart`

#### 添加冷却时间状态变量
```dart
// 冷却时间管理
DateTime? liftoffCooldownEnd;
bool get isLiftoffOnCooldown => liftoffCooldownEnd != null && DateTime.now().isBefore(liftoffCooldownEnd!);
```

#### 实现冷却时间管理方法
```dart
/// 设置起飞冷却时间
void setLiftoffCooldown() {
  liftoffCooldownEnd = DateTime.now().add(Duration(seconds: liftoffCooldown));
  Logger.info('🚀 设置起飞冷却时间: $liftoffCooldown秒');
  notifyListeners();
}

/// 清除起飞冷却时间
void clearLiftoffCooldown() {
  liftoffCooldownEnd = null;
  Logger.info('🚀 清除起飞冷却时间');
  notifyListeners();
}

/// 获取剩余冷却时间（秒）
int getRemainingCooldown() {
  if (!isLiftoffOnCooldown) return 0;
  return liftoffCooldownEnd!.difference(DateTime.now()).inSeconds.clamp(0, liftoffCooldown);
}
```

### 2. 完善起飞条件检查

#### 修改canLiftOff方法
```dart
/// 检查是否可以起飞
bool canLiftOff() {
  return hull > 0 && !isLiftoffOnCooldown;
}
```

#### 更新起飞确认对话框
```dart
'wait': {
  'text': localization.translate('ship.liftoff_event.wait'),
  'onChoose': () {
    // 清除起飞按钮冷却 - 参考原游戏Button.clearCooldown
    clearLiftoffCooldown();
    NotificationManager().notify(name, localization.translate('ship.notifications.wait_decision'));
  },
  'nextScene': 'end'
}
```

### 3. 集成太空模块坠毁机制

**文件**: `lib/modules/space.dart`

#### 在crash方法中设置冷却时间
```dart
// 设置起飞冷却时间 - 参考原游戏Button.cooldown($('#liftoffButton'))
ship.setLiftoffCooldown();
Logger.info('🚀 坠毁后设置起飞冷却时间');
```

### 4. 更新UI显示系统

**文件**: `lib/screens/ship_screen.dart`

#### 添加冷却时间显示逻辑
```dart
// 获取起飞按钮的成本文本
String _getLiftoffCostText(Map<String, dynamic> shipStatus, Localization localization) {
  if (shipStatus['isLiftoffOnCooldown']) {
    final remaining = shipStatus['remainingCooldown'] as int;
    return localization.translate('ship.cooldown.remaining', [remaining.toString()]);
  } else if (!shipStatus['canLiftOff'] && shipStatus['hull'] <= 0) {
    return localization.translate('ship.requirements.hull_needed');
  }
  return '';
}
```

#### 更新飞船状态信息
```dart
return {
  'hull': hull,
  'thrusters': thrusters,
  'alienAlloy': alienAlloy,
  'canLiftOff': canLiftOff(),
  'canReinforceHull': canReinforceHull(),
  'canUpgradeEngine': canUpgradeEngine(),
  'seenShip': sm.get('game.spaceShip.seenShip', true) == true,
  'seenWarning': sm.get('game.spaceShip.seenWarning', true) == true,
  'completed': sm.get('game.completed', true) == true,
  'isLiftoffOnCooldown': isLiftoffOnCooldown,
  'remainingCooldown': getRemainingCooldown(),
};
```

### 5. 添加本地化支持

**文件**: `assets/lang/zh.json` 和 `assets/lang/en.json`

#### 中文本地化
```json
"cooldown": {
  "remaining": "冷却时间剩余: {0}秒"
}
```

#### 英文本地化
```json
"cooldown": {
  "remaining": "cooldown remaining: {0}s"
}
```

## 测试验证

创建了完整的测试套件 `test/ship_building_upgrade_system_test.dart`，包含：

1. **常量配置测试** ✅ - 验证所有常量值正确
2. **初始化测试** ✅ - 验证模块初始化状态
3. **建造功能测试** ✅ - 验证船体强化和引擎升级
4. **资源检查测试** ✅ - 验证外星合金不足时的处理
5. **冷却时间测试** ✅ - 验证完整的冷却时间机制
6. **坠毁集成测试** ✅ - 验证太空坠毁后的冷却设置
7. **状态管理测试** ✅ - 验证飞船状态信息完整性
8. **重置功能测试** ✅ - 验证重置功能清除所有状态
9. **描述系统测试** ✅ - 验证船体描述随状态变化
10. **工具方法测试** ✅ - 验证getMaxHull等方法

### 测试结果
```
00:02 +12: All tests passed!
```

## 游戏流程

完善后的飞船建造和升级流程：

1. **获取外星合金** → 通过执行者事件或制造器获得
2. **强化船体** → 消耗外星合金，增加船体强度
3. **升级引擎** → 消耗外星合金，提高飞行速度
4. **准备起飞** → 船体>0且无冷却时间时可起飞
5. **起飞确认** → 首次起飞显示确认对话框
6. **太空飞行** → 进入小行星躲避游戏
7. **坠毁处理** → 坠毁后返回并设置120秒冷却时间
8. **冷却等待** → 等待冷却结束或选择"等待"清除冷却

## 技术特点

### 1. 忠实原游戏
- 100%按照原游戏ship.js实现
- 保持所有数值和机制一致
- 维持原有的游戏平衡性

### 2. 完整状态管理
- 实时冷却时间计算
- 状态同步机制
- 错误处理和边界情况

### 3. 用户体验优化
- 清晰的冷却时间显示
- 智能的按钮状态管理
- 完整的本地化支持

## 相关文件

### 修改文件
- `lib/modules/ship.dart` - 添加冷却时间管理系统
- `lib/modules/space.dart` - 集成坠毁后冷却设置
- `lib/screens/ship_screen.dart` - 更新UI显示逻辑
- `assets/lang/zh.json` - 添加中文冷却时间文本
- `assets/lang/en.json` - 添加英文冷却时间文本

### 新增文件
- `test/ship_building_upgrade_system_test.dart` - 完整测试套件

## 总结

成功完善了飞船模块的建造和升级系统，包括：
- 完整的起飞冷却时间机制
- 智能的按钮状态管理
- 与太空模块的无缝集成
- 完善的用户界面显示
- 全面的测试覆盖

这标志着A Dark Room Flutter版本的飞船系统达到了与原游戏完全一致的功能水平，为玩家提供了完整的飞船建造、升级和起飞体验。
