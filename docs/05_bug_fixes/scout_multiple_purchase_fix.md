# 侦察兵事件多次购买问题修复

## 问题描述

用户反馈侦察兵事件中的购买地图和学习侦察技能按钮，点击一次后就会关闭事件对话框，无法进行多次购买。这与原游戏的行为不符。

## 问题分析

### 原游戏行为

在原游戏 `adarkroom/script/events/room.js` 中，侦察兵事件的按钮配置如下：

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
                    // 注意：没有 nextScene 配置
                },
                'learn': {
                    text: _('learn scouting'),
                    cost: { 'fur': 1000, 'scales': 50, 'teeth': 20 },
                    available: function() {
                        return !$SM.hasPerk('scout');
                    },
                    onChoose: function() {
                        $SM.addPerk('scout');
                    }
                    // 注意：没有 nextScene 配置
                },
                'leave': {
                    text: _('say goodbye'),
                    nextScene: 'end'  // 只有这个按钮有 nextScene
                }
            }
        }
    }
}
```

**关键发现：**
- `buyMap` 和 `learn` 按钮都没有 `nextScene` 配置
- 只有 `leave` 按钮有 `nextScene: 'end'` 配置
- 这意味着购买和学习按钮不会结束事件，允许多次交互

### 我们的实现问题

在 `lib/modules/events.dart` 的 `handleButtonClick` 方法中，我们的逻辑是：

```dart
// 跳转到下一个场景
if (buttonConfig['nextScene'] != null) {
  // 处理场景跳转
} else {
  Logger.info('🔘 没有nextScene配置，结束事件');
  endEvent(); // ❌ 错误：直接结束事件
}
```

这个逻辑错误地假设没有 `nextScene` 的按钮应该结束事件。

## 修复方案

### 1. 修复事件处理逻辑

修改 `lib/modules/events.dart` 中的 `handleButtonClick` 方法：

```dart
// 跳转到下一个场景
if (buttonConfig['nextScene'] != null) {
  final nextSceneConfig = buttonConfig['nextScene'];
  // ... 处理场景跳转逻辑
  
  if (nextScene == 'finish' || nextScene == 'end') {
    Logger.info('🔘 结束事件');
    endEvent();
  } else {
    Logger.info('🔘 加载下一个场景: $nextScene');
    loadScene(nextScene);
  }
} else {
  // 没有nextScene配置，保持在当前场景，允许继续交互
  // 这是原游戏的行为：购买地图、学习技能等按钮不会结束事件
  Logger.info('🔘 没有nextScene配置，保持在当前场景继续交互');
  notifyListeners(); // 刷新UI以反映状态变化
}
```

### 2. 确保侦察兵事件按钮配置正确

在 `lib/events/room_events_extended.dart` 中，确保购买和学习按钮没有 `nextScene` 配置：

```dart
'buyMap': {
  // ... 其他配置
  'onChoose': () {
    final world = World.instance;
    world.applyMap();
    Logger.info('🗺️ Map purchased and applied');
  }
  // 注意：没有nextScene，允许多次购买
},
'learn': {
  // ... 其他配置
  'onChoose': () {
    _sm.set('character.perks.scout', true);
    Logger.info('🎯 Learned scouting skill');
  }
  // 注意：没有nextScene，允许多次交互
},
```

## 修复结果

修复后的行为：

1. **购买地图按钮**：点击后执行购买逻辑，但保持在当前场景，允许继续购买（如果有足够资源且地图未完全探索）
2. **学习侦察按钮**：点击后学习技能，但保持在当前场景，允许继续交互
3. **告别按钮**：点击后结束事件，返回游戏主界面

这与原游戏的行为完全一致。

## 测试验证

创建了测试文件 `test/events/scout_multiple_purchase_test.dart` 来验证：

1. 侦察兵事件允许多次购买地图
2. 侦察兵事件允许学习侦察技能后继续交互
3. 只有告别按钮会结束事件

## 相关文件

- `lib/modules/events.dart` - 事件处理逻辑修复
- `lib/events/room_events_extended.dart` - 侦察兵事件配置
- `test/events/scout_multiple_purchase_test.dart` - 测试验证
- `adarkroom/script/events/room.js` - 原游戏参考

## 更新日期

2025-01-11

## 影响范围

这个修复不仅适用于侦察兵事件，还适用于所有类似的事件（如商人事件），确保没有 `nextScene` 配置的按钮不会意外结束事件。
