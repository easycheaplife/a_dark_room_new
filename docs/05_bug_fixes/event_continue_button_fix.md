# 事件弹窗继续按钮无反应问题修复

## 问题描述

用户报告弹出事件（如小偷事件）点击"继续"按钮无反应，界面不关闭。

## 问题分析

### 根本原因

通过代码分析发现，问题出现在事件系统的场景跳转逻辑中：

1. **事件配置问题**：小偷事件等全局事件的"继续"按钮配置为`'nextScene': 'end'`
2. **场景跳转逻辑不一致**：
   - 旧版本Events模块（`lib/events/events.dart`第363行）：当`nextScene == 'end'`时直接调用`endEvent()`
   - 新版本Events模块（`lib/modules/events.dart`第1360行）：只有当`nextScene == 'finish'`时才调用`endEvent()`
3. **场景不存在**：当前使用的是新版本Events模块，它尝试加载名为`'end'`的场景，但小偷事件中没有定义该场景

### 代码位置

**问题代码**：`lib/modules/events.dart` 第1360-1364行
```dart
if (nextScene == 'finish') {
  endEvent();
} else {
  loadScene(nextScene);
}
```

**事件配置**：`lib/events/global_events.dart` 第288行
```dart
'continue': {'text': localization.translate('ui.buttons.continue'), 'nextScene': 'end'}
```

## 修复方案

### 解决方案

修改`lib/modules/events.dart`中的`handleButtonClick`方法，让它能正确处理`nextScene == 'end'`的情况，与旧版本保持一致。

### 修复代码

```dart
// 修改前
if (nextScene == 'finish') {
  endEvent();
} else {
  loadScene(nextScene);
}

// 修改后
if (nextScene == 'finish' || nextScene == 'end') {
  endEvent();
} else {
  loadScene(nextScene);
}
```

## 实施修复

### 修改文件：lib/modules/events.dart

**位置**：第1360-1364行
**修改内容**：在场景跳转逻辑中添加对`'end'`场景的处理

```dart
if (nextScene == 'finish' || nextScene == 'end') {
  endEvent();
} else {
  loadScene(nextScene);
}
```

## 影响范围

### 受影响的事件

所有使用`'nextScene': 'end'`配置的事件，包括但不限于：

1. **全局事件**（`lib/events/global_events.dart`）：
   - 小偷事件（thief）
   - 乞丐事件（beggar）
   - 拾荒者事件（scavenger）

2. **房间事件**（`lib/events/room_events.dart`）：
   - 陌生人事件（stranger）
   - 游牧商人事件（nomad）

3. **扩展事件**（`lib/events/room_events_extended.dart`）：
   - 房间内的声音事件（noisesInside）

### 修复效果

修复后，所有使用`'nextScene': 'end'`的事件的"继续"按钮都能正常工作，点击后会正确关闭事件界面。

## 测试验证

### 测试步骤

1. 启动游戏：`flutter run -d chrome`
2. 等待小偷事件触发（需要大量资源）
3. 选择"追赶"或"忽略"选项
4. 点击"继续"按钮
5. 验证事件界面是否正确关闭

### 预期结果

- 点击"继续"按钮后，事件界面立即关闭
- 返回到正常的游戏界面
- 不再出现按钮无反应的问题

## 更新日期

2025-06-25

## 更新日志

- 2025-06-25：初始修复，统一事件结束逻辑，支持`'end'`和`'finish'`两种结束场景配置
