# 战斗按钮冷却时间机制实现

**创建日期**: 2025-01-27  
**更新日期**: 2025-01-27  
**问题类型**: 功能缺失  
**优先级**: 高  
**状态**: 已完成  

## 问题描述

在A Dark Room Flutter版本中，地图探索的战斗过程中缺少按钮冷却时间机制，与原游戏不符。

**用户反馈**：
> "地图探索的战斗过程中，攻击，吃肉，吃药等按钮都有冷却时间；没有逃跑按钮，细节参考原游戏"

**问题现象**：
1. 攻击按钮没有冷却时间，可以连续点击
2. 吃肉、吃药按钮没有冷却时间
3. 战斗中有逃跑按钮（原游戏中没有）
4. 离开按钮没有冷却时间

## 原游戏参考

根据原游戏 `events.js` 源代码分析，冷却时间常量如下：

```javascript
_EAT_COOLDOWN: 5,      // 吃肉冷却5秒
_MEDS_COOLDOWN: 7,     // 使用药品冷却7秒  
_HYPO_COOLDOWN: 7,     // 使用兴奋剂冷却7秒
_SHIELD_COOLDOWN: 10,  // 护盾冷却10秒
_STIM_COOLDOWN: 10,    // 刺激剂冷却10秒
_LEAVE_COOLDOWN: 1,    // 离开冷却1秒
```

**武器冷却时间**：每个武器都有自己的 `cooldown` 属性，通常为1-2秒。

**逃跑按钮**：原游戏战斗中没有逃跑按钮，只有在战斗胜利后才有"leave"按钮。

## 解决方案

### 1. 添加冷却时间常量

在 `lib/modules/events.dart` 中已经存在冷却时间常量：

```dart
static const int eatCooldown = 5;      // 吃肉冷却5秒
static const int medsCooldown = 7;     // 使用药品冷却7秒
static const int hypoCooldown = 7;     // 使用兴奋剂冷却7秒
static const int shieldCooldown = 10;  // 护盾冷却10秒
static const int stimCooldown = 10;    // 刺激剂冷却10秒
static const int leaveCooldown = 1;    // 离开冷却1秒
```

### 2. 修改战斗界面按钮

**文件**: `lib/screens/combat_screen.dart`

#### 攻击按钮
**修改前**:
```dart
ElevatedButton(
  onPressed: () => events.useWeapon(weaponName),
  // ... 样式配置
)
```

**修改后**:
```dart
GameButton(
  id: 'attack_${weaponName.replaceAll(' ', '_')}',
  text: _getWeaponDisplayName(weaponName),
  onClick: () => events.useWeapon(weaponName),
  cooldown: (cooldown * 1000).round(), // 转换为毫秒
  cost: weapon?['cost'] as Map<String, num>?,
  width: 80,
)
```

#### 吃肉按钮
**修改前**:
```dart
ElevatedButton(
  onPressed: () => events.eatMeat(),
  // ... 样式配置
)
```

**修改后**:
```dart
GameButton(
  id: 'eat_meat',
  text: '${Localization().translate('combat.eat_meat')} (${path.outfit['cured meat']})',
  onClick: () => events.eatMeat(),
  cooldown: Events.eatCooldown * 1000, // 5秒冷却
  cost: const {'cured meat': 1},
  disabled: (path.outfit['cured meat'] ?? 0) == 0,
  width: 120,
)
```

#### 使用药物按钮
**修改前**:
```dart
ElevatedButton(
  onPressed: () => events.useMeds(),
  // ... 样式配置
)
```

**修改后**:
```dart
GameButton(
  id: 'use_meds',
  text: '${Localization().translate('combat.use_medicine')} (${path.outfit['medicine']})',
  onClick: () => events.useMeds(),
  cooldown: Events.medsCooldown * 1000, // 7秒冷却
  cost: const {'medicine': 1},
  disabled: (path.outfit['medicine'] ?? 0) == 0,
  width: 120,
)
```

#### 使用注射器按钮
**修改前**:
```dart
ElevatedButton(
  onPressed: () => events.useHypo(),
  // ... 样式配置
)
```

**修改后**:
```dart
GameButton(
  id: 'use_hypo',
  text: '${Localization().translate('combat.use_hypo')} (${path.outfit['hypo']})',
  onClick: () => events.useHypo(),
  cooldown: Events.hypoCooldown * 1000, // 7秒冷却
  cost: const {'hypo': 1},
  disabled: (path.outfit['hypo'] ?? 0) == 0,
  width: 120,
)
```

### 3. 删除逃跑按钮

**修改前**:
```dart
// 逃跑按钮
ElevatedButton(
  onPressed: () => events.endEvent(),
  child: Text(Localization().translate('combat.flee')),
)
```

**修改后**:
```dart
// 原游戏战斗中没有逃跑按钮，只有在胜利后才有离开按钮
```

### 4. 修改离开按钮

在战斗胜利后的战利品界面中，为离开按钮添加冷却时间：

**修改前**:
```dart
ElevatedButton(
  onPressed: () => events.endEvent(),
  child: Text(Localization().translate('combat.leave')),
)
```

**修改后**:
```dart
GameButton(
  id: 'leave_combat',
  text: Localization().translate('combat.leave'),
  onClick: () => events.endEvent(),
  cooldown: Events.leaveCooldown * 1000, // 1秒冷却
  width: double.infinity,
)
```

## 技术实现细节

### GameButton组件

使用 `lib/widgets/button.dart` 中的 `GameButton` 组件，它支持：

1. **冷却时间机制**: `cooldown` 参数（毫秒）
2. **成本检查**: `cost` 参数检查资源消耗
3. **禁用状态**: `disabled` 参数
4. **状态保存**: 冷却时间可以保存到StateManager

### 冷却时间转换

原游戏使用秒为单位，Flutter使用毫秒：
```dart
cooldown: Events.eatCooldown * 1000  // 5秒 -> 5000毫秒
```

### 武器冷却时间

每个武器从 `World.weapons` 配置中获取冷却时间：
```dart
final weapon = World.weapons[weaponName];
final cooldown = weapon?['cooldown'] ?? 2; // 默认2秒
```

## 用户体验改进

1. **符合原游戏**: 按钮冷却时间与原游戏完全一致
2. **防止误操作**: 冷却时间防止玩家连续点击
3. **视觉反馈**: 冷却时间有进度条显示
4. **战术深度**: 玩家需要合理安排使用物品的时机

## 相关文件

- `lib/modules/events.dart` - 冷却时间常量定义
- `lib/screens/combat_screen.dart` - 战斗界面按钮修改
- `lib/widgets/button.dart` - GameButton组件实现
- `lib/modules/world.dart` - 武器配置数据

## 测试验证

1. **攻击冷却测试**: 确认攻击按钮有对应武器的冷却时间
2. **物品冷却测试**: 确认吃肉、吃药按钮有正确的冷却时间
3. **逃跑按钮测试**: 确认战斗中没有逃跑按钮
4. **离开按钮测试**: 确认战斗胜利后离开按钮有1秒冷却
5. **成本检查测试**: 确认按钮正确检查资源消耗

## 注意事项

1. 战利品界面中的吃肉按钮无冷却时间（符合原游戏）
2. 冷却时间会保存到StateManager，页面刷新后仍然有效
3. 所有按钮都有成本检查，资源不足时自动禁用
4. 按钮样式保持与原游戏一致的简洁风格

## 后续优化

1. 可考虑添加音效反馈
2. 可考虑添加更多视觉效果
3. 可考虑优化冷却时间的显示方式
