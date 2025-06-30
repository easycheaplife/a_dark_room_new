# 战斗中吃肉冷却时间修复

**创建日期**: 2025-01-27  
**更新日期**: 2025-01-27  
**问题类型**: 游戏机制修复  
**优先级**: 高  
**状态**: 已完成

## 问题描述

### 用户反馈
用户反映"战斗中的吃肉没有冷却时间也没有读进度条"，可以连续点击吃肉按钮，没有5秒冷却限制。

### 问题分析
战斗中的吃肉按钮应该有5秒冷却时间（参考原游戏Events._EAT_COOLDOWN），但实际上可以连续点击，违反了游戏平衡性。

## 根本原因

### 问题定位
ProgressButton使用动态文本作为进度跟踪ID，导致进度状态管理失效：

```dart
// 问题代码
String get _progressId => 'ProgressButton.${widget.text}';

// 战斗中吃肉按钮文本是动态的
text: '${Localization().translate('combat.eat_meat')} (${path.outfit['cured meat']})'
// 结果：'吃肉 (18)' -> '吃肉 (17)' -> '吃肉 (16)' ...
```

### 问题机制
1. 每次吃肉后，熏肉数量减少，按钮文本改变
2. 文本改变导致`_progressId`改变
3. ProgressManager无法跟踪同一个按钮的进度状态
4. 每次点击都被视为新的按钮，绕过了冷却机制

## 解决方案

### 1. 添加固定ID参数
为ProgressButton添加可选的固定ID参数：

```dart
class ProgressButton extends StatefulWidget {
  // ... 其他参数
  final String? id; // 固定ID，用于进度跟踪

  const ProgressButton({
    // ... 其他参数
    this.id, // 可选的固定ID
  });
}
```

### 2. 修改进度ID生成逻辑
使用固定ID优先，文本作为后备：

```dart
// 修复后的代码
String get _progressId => widget.id ?? 'ProgressButton.${widget.text}';
```

### 3. 为战斗按钮设置固定ID
为所有战斗中的物品按钮设置固定ID：

```dart
// 战斗中吃肉按钮
ProgressButton(
  text: '${Localization().translate('combat.eat_meat')} (${path.outfit['cured meat']})',
  onPressed: () => events.eatMeat(),
  progressDuration: GameConfig.eatCooldown * 1000,
  id: 'combat.eat_meat', // 固定ID，避免因文本变化导致进度跟踪失效
),

// 战斗中使用药物按钮
ProgressButton(
  id: 'combat.use_medicine', // 固定ID
),

// 战斗中使用兴奋剂按钮
ProgressButton(
  id: 'combat.use_hypo', // 固定ID
),
```

## 修改的文件

### 1. lib/widgets/progress_button.dart
- 添加`id`参数到ProgressButton类
- 修改`_progressId`生成逻辑

### 2. lib/screens/combat_screen.dart
- 为战斗中的吃肉按钮添加固定ID `'combat.eat_meat'`
- 为战斗中的药物按钮添加固定ID `'combat.use_medicine'`
- 为战斗中的兴奋剂按钮添加固定ID `'combat.use_hypo'`

## 测试验证

### 测试过程
1. 启动游戏并进入战斗
2. 连续点击战斗中的吃肉按钮
3. 观察日志输出和按钮状态

### 测试结果
修复后的日志显示冷却机制正常工作：

```
[INFO] 🚀 ProgressButton started: 吃肉 (18), duration: 5000ms
[INFO] ✅ Action executed immediately for combat.eat_meat
[INFO] ✅ ProgressManager.startProgress called for combat.eat_meat

// 5秒后
[INFO] ✅ ProgressManager: Progress combat.eat_meat completed
[INFO] ✅ Cooldown completed for combat.eat_meat

// 第二次点击
[INFO] 🚀 ProgressButton started: 吃肉 (17), duration: 5000ms
[INFO] ✅ Action executed immediately for combat.eat_meat
[INFO] ✅ ProgressManager.startProgress called for combat.eat_meat
```

### 验证要点
- ✅ 战斗中吃肉有5秒冷却时间
- ✅ 动作立即执行（血量立即恢复）
- ✅ 冷却期间按钮正确禁用
- ✅ 使用固定ID `combat.eat_meat` 跟踪进度
- ✅ 文本变化不影响进度跟踪

## 设计对比

### 修复前 vs 修复后
| 方面 | 修复前 | 修复后 |
|------|--------|--------|
| 进度ID | 动态文本 | 固定ID |
| 冷却机制 | 失效 | 正常 |
| 连续点击 | 可以 | 被阻止 |
| 进度跟踪 | 断裂 | 连续 |

### 与原游戏对比
| 场景 | 原游戏 | 修复后 |
|------|--------|--------|
| 战斗中吃肉 | 5秒冷却 | 5秒冷却 ✅ |
| 战斗结束吃肉 | 无冷却 | 无冷却 ✅ |
| 立即执行 | 是 | 是 ✅ |

## 技术细节

### 向后兼容性
- 新增的`id`参数是可选的，不影响现有代码
- 未设置`id`时自动使用文本作为ID，保持原有行为

### 扩展性
- 其他需要固定ID的ProgressButton可以使用相同方案
- 为未来的动态文本按钮提供了解决方案

## 总结

这次修复解决了一个关键的游戏平衡问题。通过为ProgressButton添加固定ID支持，确保了战斗中物品使用的冷却机制正常工作，维护了游戏的平衡性和原游戏的一致性。

修复后的系统完全符合原游戏设计：
- 战斗中吃肉有5秒冷却时间
- 战斗结束后吃肉无冷却时间  
- 所有动作立即执行，进度条只显示冷却时间
