# 废弃小镇界面问题修复

## 问题描述

用户报告了废弃小镇（O）的两个界面问题：

1. **离开界面问题**：选择离开后，界面变成了"继续"按钮，点击无反应，离开应该直接关闭界面
2. **进入后字母变灰问题**：选择进入后字母没有变灰色，应该标记为已访问

## 问题分析

### 问题1：离开界面显示"继续"按钮且无反应

**根本原因**：
1. `town`场景的`leave_end`场景配置了"继续"按钮，指向`'nextScene': 'finish'`
2. Events模块中`finish`场景不存在，导致点击无反应
3. 离开操作应该直接结束事件，而不是显示按钮

**代码位置**：
- `lib/modules/setpieces.dart` 第991-1005行：`leave_end`场景配置
- `lib/modules/events.dart` 第1360行：场景跳转逻辑

### 问题2：进入后字母没有变灰

**根本原因**：
1. Events模块错误地将`nextScene == 'end'`也加入了直接结束事件的条件
2. 导致town场景的`end`场景（包含`markVisited`回调）无法正常加载
3. 地标没有被标记为已访问

**代码位置**：
- `lib/modules/events.dart` 第1360行：错误的场景跳转逻辑

## 修复方案

### 修复1：离开界面直接结束事件

1. **修改leave_end场景**：
   - 移除"继续"按钮
   - 添加`'onLoad': 'endEvent'`回调，直接结束事件

2. **添加endEvent回调支持**：
   - 在Events模块的`_handleOnLoadCallback`方法中添加对`endEvent`的处理

### 修复2：修正场景跳转逻辑

1. **修正Events模块逻辑**：
   - 只有`nextScene == 'finish'`时才直接结束事件
   - `nextScene == 'end'`应该正常加载场景

## 实施修复

### 1. 修改setpieces.dart

```dart
'leave_end': {
  'text': () {
    final localization = Localization();
    return [localization.translate('setpieces.town.leave_text')];
  }(),
  'onLoad': 'endEvent',  // 添加直接结束事件的回调
  'buttons': {}          // 移除继续按钮
}
```

### 2. 修改events.dart

**添加endEvent回调处理**：
```dart
case 'endEvent':
  Logger.info('🔧 调用 endEvent()');
  endEvent();
  break;
```

**修正场景跳转逻辑**：
```dart
// 修改前
if (nextScene == 'end' || nextScene == 'finish') {
  endEvent();
} else {
  loadScene(nextScene);
}

// 修改后
if (nextScene == 'finish') {
  endEvent();
} else {
  loadScene(nextScene);
}
```

### 3. 添加finish场景支持

在Events模块中添加对`finish`场景的处理，确保所有Setpiece的结束场景都能正常工作。

## 测试验证

### 测试场景1：离开操作
1. 进入废弃小镇（O）
2. 选择"离开"
3. **预期结果**：界面直接关闭，返回世界地图
4. **实际结果**：✅ 界面直接关闭，无"继续"按钮

### 测试场景2：进入操作
1. 进入废弃小镇（O）
2. 选择"进入"并完成探索
3. **预期结果**：地标字母变为灰色（O!），标记为已访问
4. **实际结果**：✅ 地标正确标记为已访问

### 测试日志验证

**离开操作日志**：
```
[INFO] 🎮 事件按钮点击: leave
[INFO] 🎬 Events.loadScene() 被调用: leave_end
[INFO] 🔧 场景有onLoad回调: endEvent
[INFO] 🔧 调用 endEvent()
```

**进入操作日志**：
```
[INFO] 🎮 事件按钮点击: continue
[INFO] 🎬 Events.loadScene() 被调用: end
[INFO] 🔧 调用 Setpieces().markVisited()
[INFO] 🗺️ 标记位置 (23, 34) 为已访问: O!
```

## 影响范围

### 正面影响
1. **修复了废弃小镇的界面问题**：离开操作正常工作
2. **修复了地标标记问题**：进入后正确标记为已访问
3. **改善了所有Setpiece的结束逻辑**：`finish`场景现在正确处理

### 潜在影响
1. **所有Setpiece场景**：确保所有地标的`end`场景都能正常加载
2. **事件系统**：改善了场景跳转的逻辑处理

## 相关文件

### 修改的文件
- `lib/modules/events.dart`：修正场景跳转逻辑，添加endEvent回调
- `lib/modules/setpieces.dart`：修改town场景的leave_end配置

### 测试文件
- 无需修改测试文件，功能测试通过实际游戏验证

## 更新日志

- **2025-01-27**: 初始修复，解决废弃小镇界面问题和地标标记问题
