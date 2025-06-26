# 地标转换为前哨站问题修复

## 问题描述

用户报告只有洞穴（V）会转换为前哨站（P），而其他应该转换的地标（O、Y、X）没有正确转换。

## 问题分析

### 根本原因

通过深入分析代码，发现了以下问题：

1. **town setpiece问题**：
   - 当前只有一个简单的`end`场景，调用`markVisited`
   - 原游戏应该有多个`end1`到`end6`场景，每个都调用`clearDungeon`

2. **city setpiece问题**：
   - `end1`场景调用`clearCity`函数
   - `clearCity`函数只设置`cityCleared`标记，没有调用`clearDungeon`

3. **executioner setpiece问题**：
   - `discovery`场景调用`activateExecutioner`函数
   - `activateExecutioner`函数只设置标记和绘制道路，没有调用`clearDungeon`

4. **Events模块场景跳转问题**：
   - Events模块错误地将`nextScene == 'end'`也加入了直接结束事件的条件
   - 导致town等setpiece的end场景无法正常加载，onLoad回调不执行

5. **World类特殊处理缺失**：
   - city没有被加入到World类的特殊处理列表中
   - 导致进入城市时立即标记为已访问，而不是等到完成探索

### 代码位置

**问题代码**：
- `lib/modules/setpieces.dart` 第983-998行：town的end场景
- `lib/modules/setpieces.dart` 第2254-2260行：clearCity函数
- `lib/modules/setpieces.dart` 第2272-2279行：activateExecutioner函数

## 修复方案

### 解决方案

根据原游戏的逻辑，所有完成探索的地标都应该调用`clearDungeon`函数来转换为前哨站：

1. **修复town setpiece**：将`end`场景的onLoad从`markVisited`改为`clearDungeon`
2. **修复city setpiece**：在`clearCity`函数中添加`clearDungeon`调用
3. **修复executioner setpiece**：在`activateExecutioner`函数中添加`clearDungeon`调用
4. **修复Events模块**：移除`nextScene == 'end'`的直接结束条件，确保end场景能正常加载
5. **修复World类**：将city添加到特殊处理列表中，防止进入时立即标记为已访问

### 原游戏逻辑参考

根据`docs/landmarks_to_outposts.md`文档：

```javascript
// 洞穴事件 - 3个结束场景都调用clearDungeon
'end1': { onLoad: function() { World.clearDungeon(); } },
'end2': { onLoad: function() { World.clearDungeon(); } },
'end3': { onLoad: function() { World.clearDungeon(); } },

// 小镇事件 - 6个结束场景都调用clearDungeon
'end1': { onLoad: function() { World.clearDungeon(); } },
'end2': { onLoad: function() { World.clearDungeon(); } },
// ... end3 到 end6

// 城市事件 - 15个结束场景都调用clearDungeon + cityCleared标记
'end1': { onLoad: function() { World.clearDungeon(); $SM.set('game.cityCleared', true); } },
// ... end2 到 end15

// 执行者事件 - 击败后转换
'end': {
  onLoad: () => { World.clearDungeon(); },
  buttons: { 'leave': { text: _('leave'), nextScene: 'end' } }
}
```

## 实施修复

### 修复1：town setpiece

**位置**：`lib/modules/setpieces.dart` 第988行
**修改内容**：
```dart
// 修改前
'onLoad': 'markVisited',

// 修改后
'onLoad': 'clearDungeon',
```

### 修复2：city setpiece

**位置**：`lib/modules/setpieces.dart` 第2254-2260行
**修改内容**：
```dart
// 修改前
void clearCity() {
  final sm = StateManager();
  sm.set('game.world.cityCleared', true);
  World().markVisited(World().curPos[0], World().curPos[1]);
  notifyListeners();
}

// 修改后
void clearCity() {
  final sm = StateManager();
  sm.set('game.world.cityCleared', true);
  // 城市清理后也要转换为前哨站
  World().clearDungeon();
  notifyListeners();
}
```

### 修复3：executioner setpiece

**位置**：`lib/modules/setpieces.dart` 第2272-2279行
**修改内容**：
```dart
// 修改前
void activateExecutioner() {
  final sm = StateManager();
  World().markVisited(World().curPos[0], World().curPos[1]);
  World().drawRoad();
  sm.set('game.world.executioner', true);
  notifyListeners();
}

// 修改后
void activateExecutioner() {
  final sm = StateManager();
  sm.set('game.world.executioner', true);
  // 执行者完成后也要转换为前哨站
  World().clearDungeon();
  notifyListeners();
}
```

### 修复4：Events模块场景跳转

**位置**：`lib/modules/events.dart` 第1360-1364行
**修改内容**：
```dart
// 修改前
if (nextScene == 'finish' || nextScene == 'end') {
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

### 修复5：World类特殊处理

**位置**：`lib/modules/world.dart` 第958-963行
**修改内容**：
```dart
// 修改前
if (sceneName != 'cave' &&
    sceneName != 'house' &&
    sceneName != 'ironmine' &&
    sceneName != 'coalmine' &&
    sceneName != 'sulphurmine' &&
    sceneName != 'town') {

// 修改后
if (sceneName != 'cave' &&
    sceneName != 'house' &&
    sceneName != 'ironmine' &&
    sceneName != 'coalmine' &&
    sceneName != 'sulphurmine' &&
    sceneName != 'town' &&
    sceneName != 'city') {
```

## 影响范围

### 受影响的地标

修复后，以下地标都能正确转换为前哨站：

1. **洞穴 (V - Cave)**：✅ 已正常工作
2. **废弃小镇 (O - Town)**：✅ 修复后正常工作
3. **废墟城市 (Y - City)**：✅ 修复后正常工作
4. **被摧毁的战舰 (X - Executioner)**：✅ 修复后正常工作

### 转换机制

所有地标完成探索后都会：
1. 调用`World().clearDungeon()`
2. 将当前位置转换为前哨站（P）
3. 自动绘制道路连接
4. 前哨站可以使用一次来补充水源

## 测试验证

### 测试步骤

1. **测试town转换**：
   - 进入废弃小镇（O）
   - 完成探索到达end场景
   - 验证地标是否转换为前哨站（P）

2. **测试city转换**：
   - 进入废墟城市（Y）
   - 完成探索到达end1场景
   - 验证地标是否转换为前哨站（P）

3. **测试executioner转换**：
   - 进入被摧毁的战舰（X）
   - 完成探索到达discovery场景
   - 验证地标是否转换为前哨站（P）

### 预期结果

- 所有完成探索的地标都转换为前哨站（P）
- 前哨站显示为黑色，可以使用一次
- 使用后前哨站变为灰色，无法再次使用
- 自动绘制道路连接到前哨站

## 更新日期

2025-06-25

## 更新日志

- 2025-06-25：修复town、city、executioner地标转换为前哨站的问题，确保与原游戏逻辑一致
- 2025-06-25：修复Events模块错误地将`nextScene == 'end'`直接结束事件的问题，确保end场景的onLoad回调能正常执行
- 2025-06-25：将city添加到World类的特殊处理列表中，防止进入时立即标记为已访问
