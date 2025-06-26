# 前哨站状态管理统一修复

## 问题描述

用户报告前哨站访问状态不一致：有些灰色的前哨站(P!)不能再次访问，但有些灰色前哨站可以再次访问。

## 问题分析

### 根本原因

前哨站有两套独立的状态管理系统：

1. **访问状态 (Visited Status)**
   - 标记方式：地图上显示为 `P!`（带感叹号）
   - 管理函数：`markVisited(x, y)`
   - 作用：标记地形已被访问过

2. **使用状态 (Used Status)**
   - 标记方式：存储在 `usedOutposts` Map中
   - 管理函数：`markOutpostUsed()`、`outpostUsed()`
   - 作用：标记前哨站的补水功能已被使用

### 状态不同步问题

这两个状态可能不同步，导致：
- 有些 `P!` 仍然可以使用（访问了但没使用补水功能）
- 有些 `P!` 不能使用（已经使用过补水功能）

### 持久化问题

原实现中 `usedOutposts` 只存储在内存中，没有持久化到StateManager，导致游戏重启后状态丢失。

## 修复方案

### 1. 改进前哨站使用状态检查

**修复前**：
```dart
bool outpostUsed() {
  final key = '${curPos[0]},${curPos[1]}';
  return usedOutposts[key] ?? false;
}
```

**修复后**：
```dart
bool outpostUsed([int? x, int? y]) {
  x ??= curPos[0];
  y ??= curPos[1];
  final key = '$x,$y';
  
  // 首先检查内存中的状态
  if (usedOutposts[key] == true) {
    return true;
  }
  
  // 然后检查StateManager中的持久化状态
  final sm = StateManager();
  final persistedUsedOutposts = sm.get('game.world.usedOutposts', true) ?? {};
  return persistedUsedOutposts[key] == true;
}
```

### 2. 改进前哨站使用状态标记

**修复前**：
```dart
void markOutpostUsed() {
  final key = '${curPos[0]},${curPos[1]}';
  usedOutposts[key] = true;
}
```

**修复后**：
```dart
void markOutpostUsed([int? x, int? y]) {
  x ??= curPos[0];
  y ??= curPos[1];
  final key = '$x,$y';
  
  // 更新内存状态
  usedOutposts[key] = true;
  
  // 立即持久化到StateManager
  final sm = StateManager();
  final persistedUsedOutposts = sm.get('game.world.usedOutposts', true) ?? {};
  persistedUsedOutposts[key] = true;
  sm.set('game.world.usedOutposts', persistedUsedOutposts);
  
  Logger.info('🏛️ 前哨站 ($x, $y) 已标记为已使用并持久化');
}
```

### 3. 改进前哨站使用逻辑

**修复前**：
```dart
void useOutpost() {
  // 补充水到最大值
  water = getMaxWater();
  // 标记前哨站为已使用
  markOutpostUsed();
  // 标记前哨站为已访问
  markVisited(curPos[0], curPos[1]);
}
```

**修复后**：
```dart
void useOutpost() {
  Logger.info('🏛️ 使用前哨站 - 位置: [${curPos[0]}, ${curPos[1]}]');
  
  // 检查前哨站是否已经使用过
  if (outpostUsed()) {
    Logger.info('🏛️ 前哨站已经使用过，无法再次使用');
    final localization = Localization();
    NotificationManager().notify(
        name, localization.translate('world.notifications.outpost_already_used'));
    return;
  }
  
  // 补充水到最大值
  final oldWater = water;
  water = getMaxWater();
  
  // 同时标记前哨站为已使用和已访问，确保状态同步
  markOutpostUsed();
  markVisited(curPos[0], curPos[1]);

  Logger.info('🏛️ 前哨站使用完成 - 水: $oldWater -> $water, 位置已标记为已访问和已使用');
}
```

### 4. 添加状态初始化

在 `World.init()` 中添加前哨站状态加载：

```dart
Logger.info('🏛️ 加载前哨站使用状态...');
// 从StateManager加载已使用的前哨站状态
final persistedUsedOutposts = sm.get('game.world.usedOutposts', true);
if (persistedUsedOutposts != null && persistedUsedOutposts is Map) {
  usedOutposts = Map<String, bool>.from(persistedUsedOutposts);
  Logger.info('🏛️ 已加载 ${usedOutposts.length} 个已使用的前哨站状态');
} else {
  usedOutposts = {};
  Logger.info('🏛️ 初始化空的前哨站使用状态');
}
```

### 5. 修复执行者检查逻辑

移除了错误的前哨站检查逻辑：

**修复前**：
```dart
if (originalTile != tile['outpost'] || !outpostUsed()) {
```

**修复后**：
```dart
// 执行者不是前哨站，移除错误的前哨站检查逻辑
if (!isVisited) {
```

### 6. 添加本地化支持

添加了前哨站已使用的通知文本：

**中文 (zh.json)**：
```json
"outpost_already_used": "这个前哨站已经使用过了"
```

**英文 (en.json)**：
```json
"outpost_already_used": "this outpost has already been used"
```

## 修复效果

### ✅ 解决的问题

1. **状态同步**：访问状态和使用状态现在完全同步
2. **持久化**：前哨站使用状态现在正确持久化到StateManager
3. **重复使用检查**：防止玩家重复使用同一个前哨站
4. **状态恢复**：游戏重启后正确恢复前哨站使用状态
5. **用户反馈**：当尝试使用已使用的前哨站时显示明确提示

### 🎯 预期行为

1. **新建前哨站**：
   - 显示为黑色 `P`
   - 可以使用补水功能
   - 使用后变为灰色 `P!` 且不能再次使用

2. **已使用前哨站**：
   - 显示为灰色 `P!`
   - 不能再次使用补水功能
   - 尝试使用时显示"已使用"提示

3. **状态一致性**：
   - 访问状态和使用状态完全同步
   - 游戏重启后状态保持一致

## 测试验证

### 测试用例1：新建前哨站
1. 清理洞穴获得前哨站
2. 验证显示为黑色 `P`
3. 使用补水功能
4. 验证变为灰色 `P!` 且不能再次使用

### 测试用例2：状态持久化
1. 使用前哨站
2. 重启游戏
3. 验证前哨站仍显示为已使用状态

### 测试用例3：重复使用检查
1. 尝试使用已使用的前哨站
2. 验证显示"已使用"提示
3. 验证水量不变

## 相关文件

- `lib/modules/world.dart` - 前哨站状态管理逻辑
- `assets/lang/zh.json` - 中文本地化文本
- `assets/lang/en.json` - 英文本地化文本
- `docs/outpost_access_inconsistency_analysis.md` - 问题分析文档

## 技术细节

### 状态存储格式

```dart
// StateManager中的存储格式
'game.world.usedOutposts': {
  '28,33': true,  // 位置(28,33)的前哨站已使用
  '15,20': true,  // 位置(15,20)的前哨站已使用
}
```

### 日志输出

```
🏛️ 使用前哨站 - 位置: [28, 33]
🏛️ 前哨站 (28, 33) 已标记为已使用并持久化
🗺️ 标记位置 (28, 33) 为已访问: P!
🏛️ 前哨站使用完成 - 水: 8 -> 20, 位置已标记为已访问和已使用
```

这个修复确保了前哨站状态管理的完全一致性和可靠性。
