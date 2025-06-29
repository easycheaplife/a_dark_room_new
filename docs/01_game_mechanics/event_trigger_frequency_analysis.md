# A Dark Room 事件触发频率分析

**创建时间**: 2025-06-29  
**分析范围**: 原游戏与Flutter项目中事件触发频率的对比分析

## 📋 目录

- [问题描述](#-问题描述)
- [原游戏事件触发机制](#-原游戏事件触发机制)
- [Flutter项目实现](#-flutter项目实现)
- [频率对比分析](#-频率对比分析)
- [问题诊断](#-问题诊断)
- [解决方案](#-解决方案)

## 🚨 问题描述

用户反馈现在游戏代码中事件触发不够频繁，相比原游戏，事件出现的间隔时间过长，影响游戏体验。

## 🎮 原游戏事件触发机制

### 基础配置
```javascript
// adarkroom/script/events.js
_EVENT_TIME_RANGE: [3, 6], // range, in minutes
```

### 调度逻辑
```javascript
scheduleNextEvent: function(scale) {
    var nextEvent = Math.floor(Math.random()*(Events._EVENT_TIME_RANGE[1] - Events._EVENT_TIME_RANGE[0])) + Events._EVENT_TIME_RANGE[0];
    if(scale > 0) { nextEvent *= scale; }
    Engine.log('next event scheduled in ' + nextEvent + ' minutes');
    Events._eventTimeout = Engine.setTimeout(Events.triggerEvent, nextEvent * 60 * 1000);
}
```

### 触发逻辑
```javascript
triggerEvent: function() {
    if(Events.activeEvent() == null) {
        var possibleEvents = [];
        for(var i in Events.EventPool) {
            var event = Events.EventPool[i];
            if(event.isAvailable()) {
                possibleEvents.push(event);
            }
        }

        if(possibleEvents.length === 0) {
            Events.scheduleNextEvent(0.5); // 如果没有可用事件，0.5倍时间后重试
            return;
        } else {
            var r = Math.floor(Math.random()*(possibleEvents.length));
            Events.startEvent(possibleEvents[r]);
        }
    }

    Events.scheduleNextEvent(); // 安排下一个事件
}
```

### 原游戏特点
1. **事件间隔**: 3-6分钟随机
2. **重试机制**: 无可用事件时0.5倍时间后重试
3. **立即调度**: 事件结束后立即安排下一个事件

## 🎯 Flutter项目实现

### 基础配置
```dart
// lib/events/events.dart & lib/modules/events.dart
static const List<int> eventTimeRange = [3, 6]; // 分钟范围
```

### 调度逻辑
```dart
void scheduleNextEvent() {
  final random = Random();
  final delay = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
      eventTimeRange[0];

  nextEventTimer = VisibilityManager().createTimer(Duration(minutes: delay),
      () => triggerEvent(), 'Events.nextEventTimer');
}
```

### 触发逻辑
```dart
void triggerEvent() {
  // 获取当前模块的事件
  final currentModule = Engine().activeModule;
  final contextEvents = getEventsForContext(currentModule);

  if (contextEvents.isNotEmpty) {
    // 筛选可用的事件
    final availableEvents = <Map<String, dynamic>>[];
    for (final event in contextEvents) {
      if (isEventAvailable(event)) {
        availableEvents.add(event);
      }
    }

    if (availableEvents.isNotEmpty) {
      final random = Random();
      final event = availableEvents[random.nextInt(availableEvents.length)];
      startEvent(event);
    }
  }
  scheduleNextEvent(); // 安排下一个事件
}
```

## 📊 频率对比分析

### 时间间隔对比

| 方面 | 原游戏 | Flutter项目 | 状态 |
|------|--------|-------------|------|
| **基础间隔** | 3-6分钟 | 3-6分钟 | ✅ 一致 |
| **计算方式** | `Math.floor(Math.random()*(6-3)) + 3` | `random.nextInt(6-3+1) + 3` | ✅ 一致 |
| **重试机制** | 无可用事件时0.5倍时间重试 | 无重试机制 | ❌ 缺失 |
| **事件池** | 全局事件池 | 按模块分离的事件池 | ⚠️ 不同 |

### 事件可用性对比

#### 原游戏
- **事件池**: 所有事件在一个全局池中
- **筛选**: 每次从全局池中筛选可用事件
- **覆盖面**: 所有模块的事件都可能触发

#### Flutter项目
- **事件池**: 按模块分离（Room、Outside、World等）
- **筛选**: 只从当前模块的事件中筛选
- **覆盖面**: 只有当前模块的事件可能触发

## 🔍 问题诊断

### 1. 事件池分离问题
**问题**: Flutter项目将事件按模块分离，导致可用事件数量减少
**影响**: 
- 当前模块可用事件少时，触发频率降低
- 某些模块可能长时间没有可用事件

### 2. 缺失重试机制
**问题**: 没有实现原游戏的0.5倍时间重试机制
**影响**: 
- 无可用事件时直接等待下一个完整周期
- 事件触发间隔变长

### 3. 事件可用性条件过严
**问题**: 某些事件的可用性条件可能过于严格
**影响**: 
- 可用事件数量进一步减少
- 事件触发概率降低

## 🔧 解决方案

### 1. 恢复全局事件池
```dart
void triggerEvent() {
  // 使用全局事件池而不是按模块分离
  final allEvents = [
    ...GlobalEvents.events,
    ...RoomEvents.events,
    ...OutsideEvents.events,
    ...WorldEvents.events,
  ];

  final availableEvents = <Map<String, dynamic>>[];
  for (final event in allEvents) {
    if (isEventAvailable(event)) {
      availableEvents.add(event);
    }
  }

  if (availableEvents.isEmpty) {
    // 实现重试机制
    scheduleNextEvent(0.5); // 0.5倍时间后重试
    return;
  }

  final random = Random();
  final event = availableEvents[random.nextInt(availableEvents.length)];
  startEvent(event);
  scheduleNextEvent();
}
```

### 2. 添加重试机制
```dart
void scheduleNextEvent([double scale = 1.0]) {
  final random = Random();
  var delay = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
      eventTimeRange[0];
  
  if (scale != 1.0) {
    delay = (delay * scale).round();
  }

  nextEventTimer = VisibilityManager().createTimer(Duration(minutes: delay),
      () => triggerEvent(), 'Events.nextEventTimer');
}
```

### 3. 优化事件可用性条件
- 检查所有事件的`isAvailable`条件
- 确保条件不过于严格
- 添加调试日志显示可用事件数量

### 4. 添加调试模式
```dart
void triggerEvent() {
  if (kDebugMode) {
    Logger.info('🎭 开始触发事件检查...');
    Logger.info('🎭 总事件数量: ${allEvents.length}');
    Logger.info('🎭 可用事件数量: ${availableEvents.length}');
  }
  
  // ... 触发逻辑
}
```

## 📈 预期改进效果

### 1. 事件频率提升
- 恢复到原游戏的3-6分钟间隔
- 无可用事件时快速重试（1.5-3分钟）

### 2. 事件多样性增加
- 所有模块的事件都可能触发
- 提高游戏的随机性和趣味性

### 3. 更好的调试能力
- 详细的事件触发日志
- 便于问题诊断和优化

## 🧪 测试建议

### 1. 频率测试
- 记录30分钟内的事件触发次数
- 对比修复前后的触发频率

### 2. 多样性测试
- 记录触发的事件类型分布
- 确保各类事件都能正常触发

### 3. 边界测试
- 测试无可用事件的情况
- 验证重试机制是否正常工作

## 🔗 相关文件

- `lib/events/events.dart` - 主要事件系统
- `lib/modules/events.dart` - 模块事件系统
- `lib/events/global_events.dart` - 全局事件定义
- `lib/events/room_events.dart` - 房间事件定义
- `lib/events/outside_events.dart` - 外部事件定义
- `lib/events/world_events.dart` - 世界事件定义
- `adarkroom/script/events.js` - 原游戏事件系统参考
