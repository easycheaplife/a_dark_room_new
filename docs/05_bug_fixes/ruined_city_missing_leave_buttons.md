# 废墟城市缺少离开按钮修复

## 问题描述

用户反馈："经过废墟城市时，如果没有带火把，无法进入，也没有离开按钮，游戏无法进行下去"

### 问题现象
1. **进入废墟城市**：玩家到达废墟城市地标
2. **遇到需要火把的场景**：某些场景的进入按钮需要火把
3. **没有火把时卡住**：如果玩家没有火把，进入按钮被禁用，但没有离开按钮
4. **无法继续游戏**：玩家被困在场景中，无法离开或继续

## 问题分析

### 根因分析

通过对比原游戏代码和当前实现，发现问题出现在废墟城市setpiece的某些场景中：

#### 原游戏中的正确实现
```javascript
// ../adarkroom/script/events/setpieces.js
'a4': {  // 医院场景
  text: [
    _('the shell of an abandoned hospital looms ahead.')
  ],
  buttons: {
    'enter': {
      text: _('enter'),
      cost: { 'torch': 1 },
      nextScene: {0.5: 'b7', 1: 'b8'}
    },
    'leave': {  // ✅ 有离开按钮
      text: _('leave city'),
      nextScene: 'end'
    }
  }
},

'c3': {  // 地铁隧道场景
  text: [
    _('street above the subway platform is blown away.'),
    _('lets some light down into the dusty haze.'),
    _('a sound comes from the tunnel, just ahead.')
  ],
  buttons: {
    'enter': {
      text: _('investigate'),
      cost: { 'torch': 1 },
      nextScene: {0.5: 'd2', 1: 'd3'}
    },
    'leave': {  // ✅ 有离开按钮
      text: _('leave city'),
      nextScene: 'end'
    }
  }
}
```

#### 当前实现的问题
```dart
// lib/modules/setpieces.dart - 修复前
'a3': {  // 医院场景
  'buttons': {
    'enter': {
      'cost': {'torch': 1},
      'nextScene': {'0.5': 'b5', '1': 'b6'}
    }
    // ❌ 缺少离开按钮
  }
},

'a4': {  // 地铁场景
  'buttons': {
    'enter': {
      'cost': {'torch': 1},
      'nextScene': {'0.5': 'b7', '1': 'b8'}
    }
    // ❌ 缺少离开按钮
  }
},

'c3': {  // 错误的实现
  'buttons': {
    'continue': {  // ❌ 应该是investigate按钮
      'nextScene': 'end1'
    }
    // ❌ 缺少离开按钮和火把需求
  }
}
```

**关键问题**：
1. **缺少离开按钮**：需要火把的场景没有提供离开选项
2. **场景实现错误**：c3场景的实现完全不符合原游戏
3. **玩家被困**：没有火把时无法进入也无法离开

## 修复方案

### 1. 修复a3场景（医院）- 添加离开按钮

**文件**：`lib/modules/setpieces.dart`

```dart
// 修复前
'a3': {
  'buttons': {
    'enter': {
      'text': () => localization.translate('ui.buttons.enter'),
      'cost': {'torch': 1},
      'nextScene': {'0.5': 'b5', '1': 'b6'}
    }
  }
}

// 修复后
'a3': {
  'buttons': {
    'enter': {
      'text': () => localization.translate('ui.buttons.enter'),
      'cost': {'torch': 1},
      'nextScene': {'0.5': 'b5', '1': 'b6'}
    },
    'leave': {
      'text': () => localization.translate('ui.buttons.leave_city'),
      'nextScene': 'finish'
    }
  }
}
```

### 2. 修复a4场景（地铁）- 添加离开按钮

**文件**：`lib/modules/setpieces.dart`

```dart
// 修复前
'a4': {
  'buttons': {
    'enter': {
      'text': () => localization.translate('ui.buttons.enter'),
      'cost': {'torch': 1},
      'nextScene': {'0.5': 'b7', '1': 'b8'}
    }
  }
}

// 修复后
'a4': {
  'buttons': {
    'enter': {
      'text': () => localization.translate('ui.buttons.enter'),
      'cost': {'torch': 1},
      'nextScene': {'0.5': 'b7', '1': 'b8'}
    },
    'leave': {
      'text': () => localization.translate('ui.buttons.leave_city'),
      'nextScene': 'finish'
    }
  }
}
```

### 3. 修复c3场景 - 完全重新实现

**文件**：`lib/modules/setpieces.dart`

```dart
// 修复前 - 错误的实现
'c3': {
  'text': () => [localization.translate('setpieces.city_scenes.c3_text')],
  'loot': {
    'steel': {'min': 2, 'max': 4, 'chance': 0.9},
    'rifle': {'min': 1, 'max': 1, 'chance': 0.4}
  },
  'buttons': {
    'continue': {
      'text': () => localization.translate('ui.buttons.continue'),
      'nextScene': 'end1'
    }
  }
}

// 修复后 - 符合原游戏的实现
'c3': {
  'text': () => [
    localization.translate('setpieces.city_scenes.c3_text1'),
    localization.translate('setpieces.city_scenes.c3_text2'),
    localization.translate('setpieces.city_scenes.c3_text3')
  ],
  'buttons': {
    'enter': {
      'text': () => localization.translate('ui.buttons.investigate'),
      'cost': {'torch': 1},
      'nextScene': {'0.5': 'd2', '1': 'd3'}
    },
    'leave': {
      'text': () => localization.translate('ui.buttons.leave_city'),
      'nextScene': 'finish'
    }
  }
}
```

### 4. 修复本地化文本

**文件**：`assets/lang/zh.json`

```json
// 修复前
"c3_text": "一个武器储藏室，里面有钢铁和武器。"

// 修复后 - 符合原游戏描述
"c3_text1": "地铁站台上方的街道被炸毁了。",
"c3_text2": "让一些光线透过尘雾照射下来。",
"c3_text3": "前方隧道里传来声音。"
```

## 修复效果

### ✅ 修复后的行为

1. **有火把时**：
   - 可以选择进入探索（消耗火把）
   - 可以选择离开城市

2. **没有火把时**：
   - 进入按钮被禁用并显示火把需求提示
   - 离开按钮可用，玩家可以安全离开

3. **场景一致性**：
   - c3场景现在正确实现为地铁隧道场景
   - 需要火把调查隧道中的声音
   - 有离开城市的选项

### 🎯 用户体验改善

1. **不再卡住**：玩家在任何情况下都有离开选项
2. **清晰提示**：没有火把时会显示需求提示
3. **符合原游戏**：场景行为与原游戏一致
4. **逻辑合理**：探索危险区域需要火把，但总能安全离开

## 技术细节

### 按钮可用性检查

事件界面会自动检查按钮成本：
```dart
// lib/screens/events_screen.dart
bool _canAffordButtonCost(Map<String, dynamic>? cost) {
  if (cost == null || cost.isEmpty) return true;
  
  for (final entry in cost.entries) {
    final key = entry.key;
    final required = (entry.value as num).toInt();
    
    // 对于火把等工具，只检查背包
    if (_isToolItem(key)) {
      final outfitAmount = path.outfit[key] ?? 0;
      if (outfitAmount < required) {
        return false;  // 按钮被禁用
      }
    }
  }
  return true;
}
```

### 禁用提示显示

没有火把时会显示提示：
```dart
String? disabledReason;
if (isDisabled && cost != null) {
  disabledReason = _getDisabledReason(cost);  // "需要: 1 火把"
}
```

## 测试验证

### 测试场景
1. **有火把进入城市**：验证可以正常探索
2. **没有火把进入城市**：验证有离开选项
3. **c3场景**：验证正确的文本和按钮
4. **离开功能**：验证离开按钮正常工作

### 预期结果
- ✅ 玩家不会被困在废墟城市
- ✅ 火把需求提示清晰显示
- ✅ 离开按钮在所有需要的场景中可用
- ✅ 场景文本和逻辑符合原游戏

## 更新日期

2025-06-27

## 更新日志

- 2025-06-27: 修复废墟城市缺少离开按钮导致玩家被困的问题，重新实现c3场景
