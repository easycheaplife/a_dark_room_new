# A Dark Room 事件系统实现指南

## 概述

本文档描述了A Dark Room Flutter版本中事件系统的完整实现，包括事件定义、触发机制、UI界面和战斗系统。

## 文件结构

```
lib/
├── events/
│   ├── events.dart           # 基础事件系统类
│   ├── global_events.dart    # 全局事件定义
│   ├── room_events.dart      # 房间事件定义
│   ├── outside_events.dart   # 外部事件定义
│   └── world_events.dart     # 世界地图事件定义
├── modules/
│   └── events.dart           # 主要事件模块
└── screens/
    ├── events_screen.dart    # 事件UI界面
    └── combat_screen.dart    # 战斗UI界面
```

## 事件定义格式

### 基本事件结构

```dart
{
  'title': '事件标题',
  'isAvailable': () => bool, // 可用性检查函数
  'scenes': {
    'start': {
      'text': ['事件描述文本'],
      'notification': '通知文本',
      'buttons': {
        'option1': {
          'text': '选择1',
          'nextScene': 'scene1',
          'cost': {'wood': 5}, // 可选的消耗
          'reward': {'meat': 3}, // 可选的奖励
        }
      }
    }
  }
}
```

### 战斗事件结构

```dart
{
  'title': '战斗事件标题',
  'scenes': {
    'start': {
      'combat': true,
      'enemy': '敌人名称',
      'health': 20,
      'damage': 3,
      'hit': 0.8, // 命中率
      'attackDelay': 2, // 攻击间隔(秒)
      'ranged': false, // 是否远程攻击
      'loot': {
        'meat': [1, 3], // [最小值, 最大值]
        'fur': [0, 2]
      }
    }
  }
}
```

## 事件触发机制

### 1. 时间触发
- 每3-6分钟随机触发一个事件
- 通过`scheduleNextEvent()`方法实现

### 2. 条件触发
- 通过`isAvailable`函数检查触发条件
- 常见条件：建筑数量、资源数量、游戏进度等

### 3. 位置触发
- 世界地图事件根据探索距离触发
- 不同距离有不同的敌人类型和难度

## 事件处理流程

### 1. 事件初始化
```dart
void init() {
  eventPool = [
    ...GlobalEvents.events,
    ...RoomEvents.events,
    ...OutsideEvents.events,
    ...WorldEvents.events,
  ];
  scheduleNextEvent();
}
```

### 2. 事件触发
```dart
void triggerRandomEvent() {
  if (eventPool.isEmpty) return;
  
  final random = Random();
  final event = eventPool[random.nextInt(eventPool.length)];
  
  if (isEventAvailable(event)) {
    startEvent(event);
  }
}
```

### 3. 场景加载
```dart
void loadScene(String sceneName) {
  activeScene = sceneName;
  final scene = activeEvent['scenes'][sceneName];
  
  // 处理奖励、通知等
  if (scene['combat'] == true) {
    startCombat(scene);
  } else {
    startStory(scene);
  }
}
```

### 4. 按钮处理
```dart
void handleButtonClick(String buttonKey, Map<String, dynamic> buttonConfig) {
  // 检查成本
  // 扣除资源
  // 给予奖励
  // 跳转场景
}
```

## UI界面实现

### 事件对话框
- 使用`Container`和`BoxDecoration`创建边框
- 支持多行文本显示
- 动态生成按钮

### 战斗界面
- 显示敌人信息和血量
- 武器选择和使用
- 战斗动画效果
- 战利品分配

## 战斗系统

### 战斗流程
1. 初始化敌人血量
2. 启动敌人攻击定时器
3. 玩家选择武器攻击
4. 计算伤害和命中
5. 检查胜负条件
6. 分配战利品

### 伤害计算
```dart
int dmg = -1;
if (Random().nextDouble() <= hitChance) {
  dmg = weapon['damage'] ?? 1;
}
```

### 战利品生成
```dart
void drawLoot(Map<String, dynamic> lootTable) {
  for (final entry in lootTable.entries) {
    final range = entry.value as List<int>;
    final amount = range[0] + Random().nextInt(range[1] - range[0] + 1);
    if (amount > 0) {
      currentLoot[entry.key] = amount;
    }
  }
}
```

## 资源管理

### 成本检查
```dart
if (buttonConfig['cost'] != null) {
  final costs = buttonConfig['cost'] as Map<String, dynamic>;
  for (final entry in costs.entries) {
    final current = sm.get('stores.${entry.key}', true) ?? 0;
    if (current < entry.value) {
      // 资源不足
      return;
    }
  }
}
```

### 奖励分配
```dart
if (buttonConfig['reward'] != null) {
  final rewards = buttonConfig['reward'] as Map<String, dynamic>;
  for (final entry in rewards.entries) {
    final current = sm.get('stores.${entry.key}', true) ?? 0;
    sm.set('stores.${entry.key}', current + entry.value);
  }
}
```

## 本地化支持

所有事件文本都支持中文显示：
- 事件标题和描述
- 按钮文本
- 通知消息
- 敌人名称

## 测试建议

1. **功能测试**
   - 验证事件触发条件
   - 测试资源消耗和奖励
   - 检查场景跳转逻辑

2. **战斗测试**
   - 测试不同武器的伤害
   - 验证敌人攻击机制
   - 检查战利品生成

3. **UI测试**
   - 验证界面显示正确
   - 测试按钮响应
   - 检查动画效果

4. **集成测试**
   - 测试与其他模块的交互
   - 验证状态保存和恢复
   - 检查性能表现

## 扩展建议

1. **新事件类型**
   - 添加更多故事事件
   - 实现特殊事件链
   - 增加季节性事件

2. **战斗增强**
   - 添加状态效果
   - 实现技能系统
   - 增加战斗动画

3. **UI改进**
   - 添加音效支持
   - 实现更好的动画
   - 优化移动端体验
