# 宗师事件触发条件分析

## 问题
用户反映宗师事件从未触发过，需要分析触发条件和可能的问题。

## 原游戏宗师事件分析

### 原游戏触发条件
根据原游戏 `adarkroom/script/events/room.js` 第525-597行：

```javascript
{ /* The Wandering Master */
  title: _('The Master'),
  isAvailable: function() {
    return Engine.activeModule == Room && $SM.get('features.location.world');
  },
  // ... 事件内容
}
```

**原游戏触发条件**：
1. 当前模块必须是 `Room`（小黑屋）
2. 必须已解锁世界地图功能 (`features.location.world` = true)

### 事件内容
- **标题**: "The Master" (宗师)
- **描述**: 一位老流浪者到达，微笑着请求过夜的住宿
- **成本**: 100腌肉 + 100毛皮 + 1火把
- **奖励**: 可选择学习三种技能之一：
  - **闪避** (evasion) - 提高战斗中的闪避能力
  - **精准** (precision) - 提高攻击精度
  - **力量** (force) - 提高攻击力

## Flutter项目实现分析

### 当前实现
在 `lib/events/room_events_extended.dart` 第537-668行：

```dart
static Map<String, dynamic> get master => {
  'title': () {
    final localization = Localization();
    return localization.translate('events.room_events.master.title');
  }(),
  'isAvailable': () {
    final fire = _sm.get('game.fire.value', true) ?? 0;
    final worldUnlocked = _sm.get('features.location.world', true) ?? false;
    return fire > 0 && worldUnlocked;
  },
  // ... 事件内容
};
```

**Flutter项目触发条件**：
1. 火焰值 > 0
2. 世界地图功能已解锁 (`features.location.world` = true)

### 问题分析

#### 1. 触发条件差异
- **原游戏**: 只需要在Room模块且世界已解锁
- **Flutter项目**: 需要火焰值>0且世界已解锁

#### 2. 模块检查缺失
Flutter项目的触发条件中缺少了对当前模块的检查。原游戏明确要求 `Engine.activeModule == Room`。

#### 3. 事件注册正确
宗师事件已正确注册在 `lib/events/room_events.dart` 第22行：
```dart
RoomEventsExtended.master,
```

#### 4. 世界解锁时机
世界地图功能在以下情况下解锁：
- 玩家首次出发到世界地图时 (`lib/modules/path.dart` 第330行)
- 世界模块初始化时 (`lib/modules/world.dart` 第309行)

## 根本原因

### 主要问题：事件触发逻辑
在 `lib/modules/events.dart` 第804-810行，房间事件的触发逻辑：

```dart
case 'Room':
  // 房间中只触发房间事件和全局事件，不触发战斗事件
  contextEvents = [
    ...RoomEvents.events,
    ...GlobalEvents.events,
  ];
  break;
```

这个逻辑是正确的，宗师事件应该能够在房间中触发。

### 可能的问题
1. **世界功能未正确解锁**: 玩家可能还没有解锁世界地图
2. **火焰状态问题**: 火焰可能熄灭了
3. **事件随机性**: 事件触发是随机的，可能运气不好
4. **事件冲突**: 其他事件可能优先触发

## 解决方案

### 1. 修复触发条件
将Flutter项目的触发条件修改为与原游戏一致：

```dart
'isAvailable': () {
  final worldUnlocked = _sm.get('features.location.world', true) ?? false;
  return worldUnlocked; // 移除火焰检查，与原游戏一致
},
```

### 2. 添加调试功能
添加调试日志来跟踪事件触发：

```dart
'isAvailable': () {
  final worldUnlocked = _sm.get('features.location.world', true) ?? false;
  Logger.info('🧙 宗师事件检查 - 世界已解锁: $worldUnlocked');
  return worldUnlocked;
},
```

### 3. 检查世界解锁状态
玩家可以通过以下方式检查世界是否已解锁：
- 查看是否有"漫漫尘途"页签
- 检查是否可以出发到世界地图

## 测试验证

### 验证步骤
1. 确保世界地图已解锁（有"漫漫尘途"页签）
2. 在小黑屋中等待事件触发
3. 检查是否有足够的资源（100腌肉 + 100毛皮 + 1火把）
4. 观察事件日志

### 预期结果
修复后，宗师事件应该能够在世界地图解锁后的小黑屋中随机触发。

## 相关文件
- `adarkroom/script/events/room.js` - 原游戏宗师事件实现
- `lib/events/room_events_extended.dart` - Flutter项目宗师事件实现
- `lib/events/room_events.dart` - 房间事件注册
- `lib/modules/events.dart` - 事件触发系统
- `lib/modules/world.dart` - 世界功能解锁逻辑
- `lib/modules/path.dart` - 出发功能和世界解锁
