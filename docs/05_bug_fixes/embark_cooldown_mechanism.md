# 出发冷却机制实现

**创建日期**: 2025-01-27  
**更新日期**: 2025-01-27  
**问题类型**: 功能缺失  
**优先级**: 中等  
**状态**: 已完成  

## 问题描述

原游戏中，漫漫尘途的出发功能有以下冷却机制：
1. 首次出发无冷却时间
2. 战斗失败或死亡后，需要等待120秒（2分钟）才能再次出发
3. 冷却期间出发按钮应该被禁用
4. 地图探索失败后应返回漫漫尘途页签

但Flutter版本中缺少这个冷却机制，导致玩家可以无限制地重复出发。

## 原游戏参考

根据原游戏源代码分析：
- `DEATH_COOLDOWN: 120` - 死亡冷却时间为120秒
- `Button.cooldown($('#embarkButton'))` - 死亡时设置按钮冷却
- `Button.clearCooldown($('#embarkButton'))` - 到达世界时清除冷却

## 解决方案

### 1. 添加配置参数

在 `lib/config/game_config.dart` 中添加：
```dart
/// 出发冷却时间 (秒)
/// 原游戏: DEATH_COOLDOWN: 120
static const int embarkCooldown = 120; // 2分钟

/// 首次出发是否有冷却时间
/// 原游戏: 首次出发无冷却，死亡后才有冷却
static const bool firstEmbarkHasCooldown = false;
```

### 2. 修改Path模块

在 `lib/modules/path.dart` 中添加冷却时间管理方法：
- `hasEmbarkCooldown()` - 检查是否有冷却时间
- `getEmbarkCooldownRemaining()` - 获取剩余冷却时间
- `setEmbarkCooldown()` - 设置冷却时间
- `clearEmbarkCooldown()` - 清除冷却时间
- `isFirstEmbark()` - 检查是否为首次出发
- `markEmbarked()` - 标记已出发过

### 3. 修改World模块死亡处理

在 `lib/modules/world.dart` 的 `die()` 方法中：
- 设置出发冷却时间：`path.setEmbarkCooldown()`
- 返回漫漫尘途页签而不是小黑屋：`engine.travelTo(path)`

### 4. 修改界面显示

在 `lib/screens/path_screen.dart` 中：
- 根据冷却状态禁用出发按钮
- 显示冷却剩余时间的提示信息
- 实现冷却时间倒计时更新

### 5. 添加本地化支持

在 `assets/lang/zh.json` 中添加：
```json
"embark_cooldown_remaining": "出发冷却中，剩余时间：{0}秒"
```

## 技术实现细节

### 冷却时间存储
使用StateManager存储冷却时间：
```dart
sm.set('cooldown.embark', GameConfig.embarkCooldown.toDouble());
```

### 倒计时机制
使用Timer.periodic每秒更新冷却时间：
```dart
_cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  final remaining = sm.get('cooldown.embark', true) ?? 0;
  if (remaining <= 1) {
    timer.cancel();
    sm.remove('cooldown.embark');
  } else {
    sm.set('cooldown.embark', remaining - 1, true);
  }
});
```

### 首次出发检测
使用StateManager标记是否已出发过：
```dart
bool isFirstEmbark() {
  final sm = StateManager();
  return sm.get('game.firstEmbark', true) ?? true;
}
```

## 测试验证

1. **首次出发测试**: 确认首次出发无冷却时间
2. **死亡冷却测试**: 确认死亡后有120秒冷却时间
3. **按钮状态测试**: 确认冷却期间按钮被禁用
4. **倒计时测试**: 确认冷却时间正确倒计时
5. **页签切换测试**: 确认死亡后返回漫漫尘途页签
6. **残留冷却测试**: 确认重新进入游戏时冷却时间正确恢复

## 相关文件

- `lib/config/game_config.dart` - 配置参数
- `lib/modules/path.dart` - 冷却时间管理
- `lib/modules/world.dart` - 死亡处理
- `lib/screens/path_screen.dart` - 界面显示
- `assets/lang/zh.json` - 本地化字符串

## 注意事项

1. 冷却时间使用秒为单位存储，避免精度问题
2. 使用Timer.periodic实现倒计时，确保UI实时更新
3. 在模块初始化时检查残留冷却时间
4. 冷却期间禁用按钮但保持提示信息显示

## 后续优化

1. 可考虑添加音效提示冷却结束
2. 可考虑添加视觉进度条显示冷却进度
3. 可考虑添加快捷键显示剩余时间
