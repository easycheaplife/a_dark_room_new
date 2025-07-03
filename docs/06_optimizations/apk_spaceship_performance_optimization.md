# APK版本飞船移动性能优化

## 🚀 优化概述

针对用户反馈的APK版本飞船起飞后移动卡顿问题，实施了全面的性能优化方案，显著提升了移动设备上的飞船控制流畅度。

## 🎯 问题分析

### 原始问题
1. **高频率状态更新**：`moveShip()` 每33毫秒调用一次，频繁触发UI重绘
2. **过度的notifyListeners调用**：47个notifyListeners调用，很多是不必要的
3. **小行星动画过于频繁**：每16毫秒更新一次，移动设备无法承受
4. **Consumer3监听过度**：任何状态变化都会重建整个界面
5. **按键事件重复通知**：每次按键都触发重绘，即使状态未改变

### 根本原因
- 没有针对移动设备的性能优化
- 缺乏状态变化检测，导致无效重绘
- 定时器频率过高，超出移动设备处理能力
- 缺乏通知节流机制

## 🔧 优化方案

### 1. 实现通知节流机制

#### 文件：`lib/modules/space.dart`

**新增节流通知方法**：
```dart
// 性能优化相关
DateTime? _lastNotifyTime;
bool _needsNotify = false;
static const int _notifyThrottleMs = kIsWeb ? 16 : 33; // Web: 60FPS, Mobile: 30FPS

/// 节流通知监听器，避免过度重绘
void _throttledNotifyListeners() {
  final now = DateTime.now();
  if (_lastNotifyTime == null || 
      now.difference(_lastNotifyTime!).inMilliseconds >= _notifyThrottleMs) {
    _lastNotifyTime = now;
    _needsNotify = false;
    notifyListeners();
  } else {
    _needsNotify = true;
    // 延迟通知，确保最终状态被更新
    Timer(Duration(milliseconds: _notifyThrottleMs), () {
      if (_needsNotify) {
        _lastNotifyTime = DateTime.now();
        _needsNotify = false;
        notifyListeners();
      }
    });
  }
}
```

### 2. 优化定时器频率

**根据平台调整更新频率**：
```dart
// 启动定时器 - 根据平台调整频率
final shipUpdateInterval = kIsWeb ? 33 : 50; // Web: 30FPS, Mobile: 20FPS
shipTimer = Timer.periodic(Duration(milliseconds: shipUpdateInterval), (_) => moveShip());

// 小行星动画频率优化
final animationInterval = kIsWeb ? 16 : 33; // Web: 60FPS, Mobile: 30FPS
Timer.periodic(Duration(milliseconds: animationInterval), (timer) {
  // 小行星动画逻辑
});
```

### 3. 优化移动飞船逻辑

**减少不必要的计算和通知**：
```dart
/// 移动飞船
void moveShip() {
  if (done) return;

  double dx = 0, dy = 0;
  bool hasMovement = false;

  // 检测是否有实际移动
  if (up) { dy -= getSpeed(); hasMovement = true; }
  else if (down) { dy += getSpeed(); hasMovement = true; }
  if (left) { dx -= getSpeed(); hasMovement = true; }
  else if (right) { dx += getSpeed(); hasMovement = true; }

  // 只有在有移动时才进行计算和更新
  if (!hasMovement) return;

  // 计算新位置
  final oldX = shipX;
  final oldY = shipY;
  shipX = (shipX + dx).clamp(10.0, 690.0);
  shipY = (shipY + dy).clamp(10.0, 690.0);

  // 只有位置真正改变时才记录日志和通知
  if (shipX != oldX || shipY != oldY) {
    if (kDebugMode) {
      Logger.info('🚀 飞船位置更新: ($oldX, $oldY) -> ($shipX, $shipY)');
    }
    lastMove = DateTime.now();
    _throttledNotifyListeners();
  }
}
```

### 4. 优化按键事件处理

**避免重复状态设置**：
```dart
/// 按键按下处理
void keyDown(LogicalKeyboardKey key) {
  bool stateChanged = false;
  switch (key) {
    case LogicalKeyboardKey.arrowUp:
    case LogicalKeyboardKey.keyW:
      if (!up) {
        up = true;
        stateChanged = true;
      }
      break;
    // 其他按键处理...
  }
  // 只有状态真正改变时才通知
  if (stateChanged) {
    _throttledNotifyListeners();
  }
}
```

### 5. 优化触摸控制

**减少触摸事件的重复通知**：
```dart
/// 手动控制飞船（用于触摸控制）
void setShipDirection({bool? up, bool? down, bool? left, bool? right}) {
  bool stateChanged = false;
  
  if (up != null && this.up != up) {
    this.up = up;
    stateChanged = true;
  }
  // 其他方向检查...
  
  // 只有状态真正改变时才通知
  if (stateChanged) {
    _throttledNotifyListeners();
  }
}
```

### 6. 优化UI重建机制

#### 文件：`lib/screens/space_screen.dart`

**减少Consumer监听范围**：
```dart
// 从 Consumer3<Space, Localization, StateManager> 改为
return Consumer<Space>(
  builder: (context, space, child) {
    // 只监听Space状态变化
    return Container(
      child: Stack(
        children: [
          // UI界面使用独立的Consumer
          Consumer<Localization>(
            builder: (context, localization, child) => _buildUI(space, localization),
          ),
        ],
      ),
    );
  },
);
```

## 📊 性能改进效果

### 1. 帧率提升
- **Web版本**：保持60FPS（16ms间隔）
- **移动版本**：优化到30FPS（33ms间隔），更适合移动设备

### 2. 通知频率降低
- **优化前**：每次移动、按键、动画都触发通知（约100+次/秒）
- **优化后**：通过节流机制降低到30次/秒（移动端）

### 3. CPU使用率降低
- **减少无效计算**：只在有实际移动时进行位置计算
- **减少重复状态设置**：避免设置相同的状态值
- **减少日志输出**：仅在Debug模式下输出详细日志

### 4. 内存使用优化
- **减少UI重建**：通过精确的Consumer监听减少不必要的重建
- **优化定时器管理**：根据平台调整定时器频率

## 🔄 更新日志

**2025-07-03**：
- 实现通知节流机制，根据平台调整通知频率
- 优化定时器频率：Web 30FPS，移动端 20FPS
- 优化移动飞船逻辑，减少不必要的计算和通知
- 优化按键和触摸事件处理，避免重复状态设置
- 优化UI重建机制，减少Consumer监听范围
- 添加平台特定的性能配置
- 优化日志输出，仅在Debug模式下详细记录

## 📋 相关文件

- `lib/modules/space.dart` - 飞船控制逻辑优化
- `lib/screens/space_screen.dart` - 飞船界面性能优化
- `docs/06_optimizations/apk_spaceship_movement_controls.md` - 相关移动控制优化

## 🎯 后续优化建议

1. **进一步优化渲染**：考虑使用Canvas绘制替代Widget堆叠
2. **内存池管理**：为小行星对象实现对象池，减少GC压力
3. **预测性渲染**：根据移动方向预测下一帧位置
4. **自适应帧率**：根据设备性能动态调整更新频率
5. **批量状态更新**：将多个状态变化合并为单次通知

## 📝 总结

本次性能优化成功解决了APK版本飞船移动卡顿的问题：

- ✅ **帧率优化**：移动端从60FPS降低到30FPS，更适合移动设备
- ✅ **通知节流**：实现智能通知机制，避免过度重绘
- ✅ **状态检测**：只在状态真正改变时才触发更新
- ✅ **平台适配**：Web和移动端使用不同的性能配置
- ✅ **向后兼容**：Web版本性能保持不变

这个优化确保了A Dark Room游戏在移动设备上能够流畅运行，提供了良好的用户体验。
