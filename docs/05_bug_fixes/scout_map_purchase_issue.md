# 侦察兵地图购买问题修复

## 问题描述

用户反馈购买地图条件从未触发过，无法遇到侦察兵事件来购买地图。

## 问题分析

### 原游戏侦察兵事件条件

在原游戏 `adarkroom/script/events/room.js` 中，侦察兵事件的触发条件是：

```javascript
{ /* The Scout  --  Map Merchant */
    title: _('The Scout'),
    isAvailable: function() {
        return Engine.activeModule == Room && $SM.get('features.location.world');
    },
    scenes: {
        'start': {
            text: [
                _("the scout says she's been all over."),
                _("willing to talk about it, for a price.")
            ],
            notification: _('a scout stops for the night'),
            blink: true,
            buttons: {
                'buyMap': {
                    text: _('buy map'),
                    cost: { 'fur': 200, 'scales': 10 },
                    available: function() {
                        return !World.seenAll;
                    },
                    notification: _('the map uncovers a bit of the world'),
                    onChoose: World.applyMap
                },
                // ... 其他按钮
            }
        }
    }
}
```

**关键发现：** 原游戏的侦察兵事件只需要两个条件：
1. `Engine.activeModule == Room` (当前在房间模块)
2. `$SM.get('features.location.world')` (世界功能已解锁)

### 我们的实现问题

在 `lib/events/room_events_extended.dart` 中，我们的实现错误地添加了火焰条件：

```dart
'isAvailable': () {
  final fire = _sm.get('game.fire.value', true) ?? 0;
  final worldUnlocked = _sm.get('features.location.world', true) ?? false;
  return fire > 0 && worldUnlocked;  // ❌ 错误：多加了火焰条件
},
```

### 世界功能解锁时机

在原游戏 `adarkroom/script/world.js` 的 `init()` 函数中：

```javascript
if(typeof $SM.get('features.location.world') == 'undefined') {
    $SM.set('features.location.world', true);
    $SM.set('features.executioner', true);
    $SM.setM('game.world', {
        map: World.generateMap(),
        mask: World.newMask()
    });
}
```

这意味着 `features.location.world` 在世界模块初始化时就会被设置为 `true`。

## 修复方案

### 1. 修正侦察兵事件触发条件

移除多余的火焰条件，只保留世界功能解锁条件：

```dart
'isAvailable': () {
  // 原游戏条件：Engine.activeModule == Room && $SM.get('features.location.world')
  // 只需要世界功能解锁即可，不需要火焰条件
  final worldUnlocked = _sm.get('features.location.world', true) ?? false;
  return worldUnlocked;
},
```

### 2. 确保世界功能正确初始化

在 `lib/modules/world.dart` 中，我们已经正确实现了世界功能的初始化：

```dart
// 如果世界功能未解锁或者世界数据不存在，则生成新地图
if (worldFeature == null || worldData == null || worldData is! Map) {
  Logger.info('🌍 Generating new world map...');
  sm.set('features.location.world', true);
  sm.set('features.executioner', true);
  sm.setM('game.world', {'map': generateMap(), 'mask': newMask()});
  Logger.info('🌍 New world map generation completed');
}
```

## 修复结果

修复后，侦察兵事件应该能够正常触发，条件为：
- 世界功能已解锁 (`features.location.world` = true)
- 当前在房间页签

购买地图的条件为：
- 拥有足够的资源 (毛皮 200, 鳞片 10)
- 地图尚未完全探索 (`!World.seenAll`)

## 测试验证

1. 启动游戏：`flutter run -d chrome`
2. 确认世界功能已解锁
3. 等待侦察兵事件触发
4. 验证地图购买功能正常工作

## 相关文件

- `lib/events/room_events_extended.dart` - 侦察兵事件定义
- `lib/modules/world.dart` - 世界模块初始化
- `adarkroom/script/events/room.js` - 原游戏侦察兵事件参考
- `adarkroom/script/world.js` - 原游戏世界模块参考
