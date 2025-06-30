# 统一按钮组件优化

**创建日期**: 2025-01-27  
**更新日期**: 2025-01-27  
**优化类型**: 代码复用和UI统一  
**优先级**: 中等  
**状态**: 已完成  

## 优化目标

统一游戏中所有按钮的样式和行为，复用伐木按钮的ProgressButton组件，实现：
1. 所有按钮使用统一的样式和交互效果
2. 复用代码，减少重复实现
3. 提供一致的用户体验

**用户需求**：
> "地图探索的战斗过程中，攻击，吃肉，吃药等按钮能否复用伐木按钮的代码"
> "包括出发按钮也复用伐木/添柴/检查陷进带进度条按钮的代码，不满足条件置灰，时间没到读进度条"
> "所有带进度条按钮风格样式保持一致"

## 原始状况分析

### 按钮组件分散问题

游戏中存在多个不同的按钮组件：

1. **ProgressButton** (`lib/widgets/progress_button.dart`)
   - 用于：伐木、添柴、检查陷阱、点火等
   - 特点：有进度条、统一样式、成本检查、悬停提示

2. **GameButton** (`lib/widgets/button.dart`)
   - 用于：战斗中的攻击、吃肉、吃药等
   - 特点：有冷却时间、但样式不统一

3. **普通按钮** (`lib/widgets/game_button.dart`)
   - 用于：出发按钮等
   - 特点：基础样式，功能有限

### 样式不一致问题

不同按钮组件的样式差异：
- 字体、颜色、边框不统一
- 进度条显示方式不同
- 悬停效果不一致
- 禁用状态样式不同

## 解决方案

### 1. 统一使用ProgressButton组件

将所有按钮统一使用 `ProgressButton` 组件，因为它具有最完整的功能：

#### 核心功能
- **进度条显示**: 支持操作进度可视化
- **成本检查**: 自动检查资源是否足够
- **禁用状态**: 支持条件不满足时的置灰显示
- **悬停提示**: 显示成本信息和操作说明
- **统一样式**: Times New Roman字体、黑色边框、白色背景

#### 样式规范
```dart
// 按钮样式统一规范
Container(
  decoration: BoxDecoration(
    color: isDisabled ? Colors.grey[300] : Colors.white,
    border: Border.all(
      color: isDisabled ? Colors.grey : Colors.black,
      width: 1,
    ),
  ),
  child: Text(
    widget.text,
    style: TextStyle(
      color: isDisabled ? Colors.grey[600] : Colors.black,
      fontSize: 11,
      fontFamily: 'Times New Roman',
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### 2. 修改战斗按钮

**文件**: `lib/screens/combat_screen.dart`

#### 攻击按钮
**修改前**:
```dart
GameButton(
  id: 'attack_${weaponName.replaceAll(' ', '_')}',
  text: _getWeaponDisplayName(weaponName),
  onClick: () => events.useWeapon(weaponName),
  cooldown: (cooldown * 1000).round(),
  cost: weapon?['cost'] as Map<String, num>?,
  width: 80,
)
```

**修改后**:
```dart
ProgressButton(
  text: _getWeaponDisplayName(weaponName),
  onPressed: () => events.useWeapon(weaponName),
  progressDuration: (cooldown * 1000).round(), // 冷却时间转为进度时间
  cost: costMap,
  width: 80,
)
```

#### 物品使用按钮
**修改前**:
```dart
GameButton(
  id: 'eat_meat',
  text: '${Localization().translate('combat.eat_meat')} (${path.outfit['cured meat']})',
  onClick: () => events.eatMeat(),
  cooldown: Events.eatCooldown * 1000,
  cost: const {'cured meat': 1},
  disabled: (path.outfit['cured meat'] ?? 0) == 0,
  width: 120,
)
```

**修改后**:
```dart
ProgressButton(
  text: '${Localization().translate('combat.eat_meat')} (${path.outfit['cured meat']})',
  onPressed: () => events.eatMeat(),
  progressDuration: Events.eatCooldown * 1000, // 5秒冷却转为进度
  cost: const {'cured meat': 1},
  disabled: (path.outfit['cured meat'] ?? 0) == 0,
  width: 120,
)
```

### 3. 修改出发按钮

**文件**: `lib/screens/path_screen.dart`

**修改前**:
```dart
GameButton(
  text: localization.translate('ui.buttons.embark'),
  onPressed: canEmbark ? () => path.embark() : null,
  width: 80,
)
```

**修改后**:
```dart
ProgressButton(
  text: localization.translate('ui.buttons.embark'),
  onPressed: (canEmbark && !shouldShowCooldown) ? () => path.embark() : null,
  disabled: !canEmbark || shouldShowCooldown,
  cost: const {'cured meat': 1}, // 出发需要熏肉
  width: 80,
  progressDuration: 1000, // 出发按钮点击后1秒进度
  tooltip: tooltipMessage,
)
```

## 技术实现细节

### 冷却时间转换为进度时间

原来的冷却时间机制转换为进度条机制：
- **冷却时间**: 按钮点击后禁用一段时间
- **进度时间**: 按钮点击后显示进度条，完成后可再次点击

```dart
// 原来的冷却时间（毫秒）
cooldown: Events.eatCooldown * 1000

// 转换为进度时间（毫秒）
progressDuration: Events.eatCooldown * 1000
```

### 成本检查统一

所有按钮都使用统一的成本检查机制：
```dart
cost: const {'cured meat': 1}  // 消耗1个熏肉
cost: const {'medicine': 1}    // 消耗1个药品
cost: const {'hypo': 1}        // 消耗1个注射器
```

### 禁用状态统一

统一的禁用条件处理：
```dart
disabled: !canEmbark || shouldShowCooldown  // 出发按钮
disabled: (path.outfit['cured meat'] ?? 0) == 0  // 吃肉按钮
```

## 用户体验改进

### 1. 视觉一致性
- 所有按钮使用相同的字体、颜色、边框
- 统一的悬停效果和点击反馈
- 一致的禁用状态显示

### 2. 交互一致性
- 统一的进度条显示方式
- 一致的成本提示信息
- 相同的操作反馈机制

### 3. 功能完整性
- 所有按钮都支持成本检查
- 统一的悬停提示功能
- 一致的禁用状态处理

## 代码复用效果

### 删除重复代码
- 移除了多个不同的按钮组件
- 统一使用ProgressButton组件
- 减少了样式定义的重复

### 维护性提升
- 按钮样式修改只需在一个地方进行
- 新功能添加更加简单
- 代码结构更加清晰

### 性能优化
- 减少了组件类型，降低内存占用
- 统一的渲染逻辑，提升性能
- 更少的代码量，加快加载速度

## 相关文件

- `lib/widgets/progress_button.dart` - 统一按钮组件
- `lib/screens/combat_screen.dart` - 战斗界面按钮修改
- `lib/screens/path_screen.dart` - 出发按钮修改
- `lib/screens/outside_screen.dart` - 伐木、检查陷阱按钮（已使用ProgressButton）
- `lib/screens/room_screen.dart` - 点火、添柴按钮（已使用ProgressButton）

## 测试验证

1. **样式一致性测试**: 确认所有按钮样式统一
2. **功能完整性测试**: 确认进度条、成本检查、禁用状态正常
3. **交互体验测试**: 确认悬停提示、点击反馈一致
4. **性能测试**: 确认统一后性能没有下降

## 后续优化建议

1. **动画效果**: 可以为所有按钮添加统一的动画效果
2. **音效反馈**: 统一的按钮点击音效
3. **键盘支持**: 添加键盘快捷键支持
4. **无障碍功能**: 改进屏幕阅读器支持

## 总结

通过统一使用ProgressButton组件，实现了：
- ✅ 所有按钮样式完全一致
- ✅ 代码复用率大幅提升
- ✅ 用户体验更加统一
- ✅ 维护成本显著降低
- ✅ 符合原游戏的简洁风格

这次优化不仅解决了用户提出的按钮复用需求，还提升了整体代码质量和用户体验。
