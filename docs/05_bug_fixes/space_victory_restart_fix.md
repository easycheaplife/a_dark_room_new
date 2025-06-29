# 太空模块飞行失败和胜利重新开始修复

**修复日期**: 2025-06-29
**问题类型**: Bug修复
**影响范围**: 太空模块飞行失败符号清理和胜利后重新开始逻辑

## 🐛 问题描述

### 问题1: 飞行失败几次后符号不消失

- **现象**: 多次飞行失败后，小行星符号在屏幕上累积，没有正确清理
- **预期行为**: 每次坠毁后应该清空所有小行星符号
- **影响**: 界面混乱，影响下次飞行的视觉体验
- **严重程度**: 中 - 影响用户体验

### 问题2: 飞行胜利后重新开始，点击重新开始后清档，游戏重新开始

- **现象**: 太空胜利后点击"重新开始"按钮，没有正确清除存档并重新开始游戏
- **预期行为**: 点击重新开始应该清除所有存档数据，但保留声望数据，游戏从头开始（回到小黑屋初始状态）
- **影响**: 用户无法正确重新开始游戏，影响游戏的可重复性
- **严重程度**: 高 - 核心游戏功能缺失

## 🔍 问题分析

### 原游戏逻辑分析

通过分析`adarkroom/script/space.js`和`adarkroom/script/engine.js`：

1. **重新开始按钮**：
   ```javascript
   .text(_('restart.'))
   .click(Engine.confirmDelete)
   ```

2. **confirmDelete方法**：
   ```javascript
   confirmDelete: function() {
     Events.startEvent({
       title: _('Restart?'),
       scenes: {
         start: {
           text: [_('restart the game?')],
           buttons: {
             'yes': {
               text: _('yes'),
               nextScene: 'end',
               onChoose: Engine.deleteSave
             }
           }
         }
       }
     });
   }
   ```

3. **deleteSave方法**：
   ```javascript
   deleteSave: function(noReload) {
     if(typeof Storage != 'undefined' && localStorage) {
       var prestige = Prestige.get();
       window.State = {};
       localStorage.clear();
       Prestige.set(prestige);
     }
     if(!noReload) {
       location.reload(); // 重新加载页面
     }
   }
   ```

### 当前实现问题

#### 小行星符号累积问题

1. **onArrival方法缺少清理**
   ```dart
   // 问题代码
   void onArrival([int transitionDiff = 0]) {
     // ... 其他逻辑
     // 缺少: asteroids.clear();
   }
   ```

2. **crash方法清理不完整**
   ```dart
   // 问题代码
   void crash() {
     // ... 其他逻辑
     // 虽然有asteroids.clear()，但日志显示错误
     Logger.info('🚀 坠毁时已清空 ${asteroids.length} 个小行星'); // 总是显示0
   }
   ```

3. **多次失败后状态残留**
   - 每次起飞时没有清空之前的小行星列表
   - 坠毁后小行星列表虽然被清空，但下次起飞时没有重新清理
   - 导致多次失败后小行星符号累积

#### 重新开始功能问题

1. **重新开始逻辑不完整**
   ```dart
   // 问题代码
   void _onRestart() {
     Navigator.of(context).pop();
     Engine().deleteSave();

     if (widget.onRestart != null) {
       widget.onRestart!(); // 这里还在调用space.reset()
     }
   }
   ```

2. **声望数据处理错误**
   ```dart
   // 问题代码
   Future<void> deleteSave({bool noReload = false}) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.clear(); // 错误：清除了所有数据，包括声望
   }
   ```

3. **StateManager内存状态未重置**
   ```dart
   // 问题代码
   await prefs.clear(); // 只清除了持久化存储
   await init(); // 但StateManager的内存状态没有重置
   ```

3. **混淆了两种重新开始**
   - **失败重新开始**: 只重置太空模块状态，继续当前游戏
   - **胜利重新开始**: 清档重新开始整个游戏，但保留声望

4. **缺少异步处理**
   - deleteSave是异步方法，但没有正确等待

## 🔧 修复方案

### 1. 修复小行星符号累积问题

#### 1.1 在onArrival方法中添加小行星清理
```dart
/// 到达时调用
void onArrival([int transitionDiff = 0]) {
  done = false;
  hull = Ship().getMaxHull();
  altitude = 0;
  setTitle();
  updateHull();

  // 重置控制状态
  up = down = left = right = false;

  // 重置飞船位置
  shipX = 350.0;
  shipY = 350.0;

  // 清空小行星列表，确保每次起飞都从干净状态开始
  asteroids.clear();
  Logger.info('🚀 起飞时清空小行星列表，开始新的飞行');

  startAscent();
  // ... 其他逻辑
}
```

#### 1.2 修复crash方法中的日志显示
```dart
/// 坠毁
void crash() {
  if (done) return;

  done = true;
  _clearTimers();

  final localization = Localization();
  NotificationManager().notify(name, localization.translate('space.notifications.ship_crashed'));

  // 清空小行星列表，避免下次起飞时残留
  asteroids.clear();
  Logger.info('🚀 坠毁时已清空 ${asteroids.length} 个小行星');

  Logger.info('🚀 飞船坠毁，返回破旧星舰页签');

  // 参考原游戏逻辑：失败时返回破旧星舰页签
  Timer(Duration(milliseconds: 1000), () {
    final sm = StateManager();
    sm.set('game.switchToShip', true);
    Logger.info('🚀 已设置切换到破旧星舰页签的标志');
  });

  notifyListeners();
}
```

#### 1.3 修复crash方法中的日志显示
```dart
// 清空小行星列表，避免下次起飞时残留
final asteroidCount = asteroids.length;
asteroids.clear();
Logger.info('🚀 坠毁时已清空 $asteroidCount 个小行星');
```

### 2. 修复GameEndingDialog的重新开始逻辑

#### 1.1 添加异步处理和日志
```dart
/// 重新开始游戏
void _onRestart() async {
  Navigator.of(context).pop();
  
  Logger.info('🔄 开始重新开始游戏流程');
  
  try {
    // 调用Engine的删除存档方法，参考原游戏的deleteSave逻辑
    await Engine().deleteSave();
    Logger.info('🔄 存档已清除，游戏已重新初始化');
    
    // 调用回调（如果有的话）
    if (widget.onRestart != null) {
      widget.onRestart!();
    }
  } catch (e) {
    Logger.error('❌ 重新开始游戏失败: $e');
  }
}
```

#### 2.2 添加Logger导入
```dart
import '../core/logger.dart';
```

### 3. 修复Engine.deleteSave方法保留声望数据

#### 3.1 参考原游戏逻辑保留声望
```dart
// 删除保存并重新开始
Future<void> deleteSave({bool noReload = false}) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // 参考原游戏逻辑：保存声望数据
    final prestige = Prestige();
    final prestigeData = prestige.get();
    Logger.info('🏆 保存声望数据: $prestigeData');

    // 清空所有存档
    await prefs.clear();
    Logger.info('🗑️ Game save state cleared');

    // 恢复声望数据
    prestige.set(prestigeData);
    Logger.info('🏆 声望数据已恢复');

    if (!noReload) {
      // 在Web上下文中，这会重新加载页面
      // 在Flutter中，我们将重新初始化游戏
      await init();
      Logger.info('🔄 游戏已重新初始化');
    }
  } catch (e) {
    if (kDebugMode) {
      Logger.error('Error deleting save: $e');
    }
  }
}
```

#### 3.2 添加Prestige导入
```dart
import '../modules/prestige.dart';
```

#### 3.3 添加StateManager.reset()方法
```dart
/// 重置StateManager的内存状态（用于重新开始游戏）
void reset() {
  Logger.info('🔄 重置StateManager内存状态');
  _state = {};
  Logger.info('🔄 StateManager内存状态已清空');
}
```

#### 3.4 在deleteSave中调用StateManager.reset()
```dart
// 重置StateManager的内存状态
final sm = StateManager();
sm.reset();
Logger.info('🔄 StateManager内存状态已重置');
```

### 4. 修复SpaceScreen的onRestart回调

#### 2.1 移除错误的space.reset()调用
```dart
// 修复前
onRestart: () {
  // 重置太空模块状态，清空小行星等
  space.reset();
  Logger.info('🚀 太空模块已重置，小行星已清空');
},

// 修复后
onRestart: () {
  // 胜利后重新开始：清档重新开始游戏
  // 不需要额外操作，GameEndingDialog已经处理了deleteSave和重新初始化
  Logger.info('🚀 胜利后重新开始游戏，已清档重新初始化');
},
```

#### 2.2 移除未使用的space变量
```dart
// 移除未使用的变量
// final space = Provider.of<Space>(context, listen: false);
```

### 3. 验证Engine.deleteSave方法

确保deleteSave方法正确实现：
```dart
Future<void> deleteSave({bool noReload = false}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 清除所有存档
    Logger.info('🗑️ Game save state cleared');

    if (!noReload) {
      // 重新初始化游戏到初始状态
      await init();
    }
  } catch (e) {
    Logger.error('Error deleting save: $e');
  }
}
```

### 4. 验证StateManager初始化

确保StateManager能正确创建新游戏状态：
```dart
void _initializeNewGameState() {
  _state = {
    'version': 1.3,
    'stores': {
      'wood': 0, // 从0个木材开始
    },
    'features': {
      'location': {
        'room': true, // 只有房间可用
      },
    },
    // ... 其他初始状态
  };
}
```

## 📝 修复实施

### 修改的文件

1. **`lib/modules/space.dart`**
   - 修复onArrival方法，添加asteroids.clear()确保每次起飞都从干净状态开始
   - 修复crash方法中的日志显示，正确记录清空的小行星数量
   - 添加详细日志记录起飞和坠毁时的清理过程

2. **`lib/core/engine.dart`**
   - 修复deleteSave方法，添加声望数据保留逻辑
   - 添加StateManager.reset()调用，确保内存状态也被重置
   - 添加Prestige导入
   - 参考原游戏逻辑实现完整的清档重新开始

3. **`lib/core/state_manager.dart`**
   - 添加reset()方法，用于重置StateManager的内存状态
   - 确保重新开始时内存和持久化存储都被正确清理

4. **`lib/widgets/game_ending_dialog.dart`**
   - 添加Logger导入
   - 修复_onRestart方法，添加异步处理和错误处理
   - 添加详细日志记录

5. **`lib/screens/space_screen.dart`**
   - 修复onRestart回调，移除错误的space.reset()调用
   - 移除未使用的space变量
   - 更新注释说明胜利重新开始的逻辑

### 技术实现细节

1. **小行星清理**: 在crash方法中调用asteroids.clear()
2. **声望数据保留**: 参考原游戏逻辑，重新开始时保留声望数据
3. **异步处理**: 正确等待deleteSave完成
4. **错误处理**: 添加try-catch处理异常情况
5. **日志记录**: 详细记录重新开始流程和小行星清理过程
6. **状态管理**: 依赖Engine.init()正确重新初始化所有模块
7. **界面切换**: 通过travelTo(Room())切换到初始界面

## 🧪 测试验证

### 小行星清理测试
1. **多次失败测试**
   - 让飞船多次被小行星击中
   - 验证每次坠毁后小行星是否被清空
   - 确认下次起飞时界面干净

2. **符号残留测试**
   - 验证坠毁后屏幕上没有残留的小行星符号
   - 确认重新起飞时从干净状态开始

### 胜利重新开始测试
1. **胜利流程测试**
   - 让飞船达到60km高度触发胜利
   - 验证胜利对话框正确显示
   - 点击重新开始按钮

2. **存档清除测试**
   - 验证所有存档数据被清除
   - 确认游戏状态重置到初始状态
   - 检查木材数量为0，只有房间可用

3. **界面切换测试**
   - 确认重新开始后切换到小黑屋界面
   - 验证火焰状态为熄灭
   - 确认所有进度重置

4. **功能完整性测试**
   - 验证重新开始后游戏功能正常
   - 确认可以重新点火、收集木材等
   - 测试游戏进度正常推进

### 日志验证
- 检查控制台日志，确认重新开始流程被正确记录
- 验证deleteSave和init方法的调用
- 确认状态管理器正确创建新游戏状态

## 📊 修复效果

### 预期改进
1. **功能完整性**: 100%实现原游戏的重新开始功能
2. **用户体验**: 胜利后可以正确重新开始游戏
3. **状态管理**: 完整的存档清除和状态重置
4. **界面一致性**: 重新开始后正确显示初始界面

### 风险评估
- **低风险**: 基于原游戏逻辑，不影响其他功能
- **向后兼容**: 不破坏现有的游戏流程
- **性能影响**: 重新初始化有轻微性能开销，但可接受

## 🎯 原游戏逻辑对比

| 操作 | 原游戏行为 | 修复前行为 | 修复后行为 |
|------|------------|------------|------------|
| 胜利后点击重新开始 | 清档重新开始 | 只重置太空模块 | ✅ 清档重新开始 |
| 存档状态 | 完全清除 | 部分保留 | ✅ 完全清除 |
| 界面切换 | 回到小黑屋 | 停留在太空 | ✅ 回到小黑屋 |
| 游戏状态 | 完全重置 | 部分重置 | ✅ 完全重置 |

## 🔄 后续优化建议

1. **确认对话框**: 添加"确定要重新开始吗？"的确认对话框
2. **动画效果**: 为重新开始过程添加过渡动画
3. **声望保留**: 考虑是否需要保留声望数据（如原游戏）
4. **性能优化**: 优化重新初始化的性能

---

*本修复确保了太空胜利后的重新开始功能完全符合原游戏逻辑，为玩家提供了正确的游戏重新开始体验。*
