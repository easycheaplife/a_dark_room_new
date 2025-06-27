# 前哨站持久状态修复

## 问题描述

前哨站状态管理存在问题：
1. **新创建的前哨站**：立即访问没问题，可以获得熏肉和水，会变灰
2. **返回村庄后再访问**：无法获得熏肉和水，也不会变灰

## 问题分析

通过分析原游戏代码发现了根本问题：

### 原游戏的前哨站状态逻辑

```javascript
// 原游戏 world.js:1087
onArrival: function() {
  // ...
  World.usedOutposts = {};  // 每次出发都重置！
  // ...
}

// 原游戏 world.js:1071
useOutpost: function() {
  // 标记为已使用（临时状态）
  World.usedOutposts[World.curPos[0] + ',' + World.curPos[1]] = true;
}

// 原游戏 world.js:578
if(curTile != World.TILE.OUTPOST || !World.outpostUsed()) {
  Events.startEvent(Events.Setpieces[World.LANDMARKS[curTile].scene]);
}
```

### 关键发现

1. **使用状态是临时的**：`usedOutposts`在每次出发时都重置为`{}`
2. **访问状态是永久的**：通过地图上的`!`标记保存（如`P!`）
3. **前哨站可用性**：只基于当次探索的使用状态，不基于永久状态

### 我们实现的问题

我们错误地将前哨站使用状态设计为永久持久化的，导致：
- 返回村庄后，前哨站被标记为"已使用"
- 再次出发时，前哨站仍然是"已使用"状态
- 无法再次访问前哨站

## 修复方案

### 1. 修改onArrival()函数

**修复前**：
```dart
// 恢复前哨站使用状态
final persistedUsedOutposts = sm.get('game.world.usedOutposts', true);
if (persistedUsedOutposts != null && persistedUsedOutposts is Map) {
  usedOutposts = Map<String, bool>.from(persistedUsedOutposts);
} else {
  usedOutposts = {};
}
```

**修复后**：
```dart
// 重置前哨站使用状态（参考原游戏逻辑：每次出发都重置）
// 前哨站的永久状态通过地图上的访问标记(!)保存，使用状态是临时的
usedOutposts = {};
Logger.info('🏛️ 重置前哨站使用状态（每次出发都重置）');
```

### 2. 修改markOutpostUsed()函数

**修复前**：
```dart
void markOutpostUsed([int? x, int? y]) {
  // 更新内存状态
  usedOutposts[key] = true;
  
  // 立即持久化到StateManager
  final sm = StateManager();
  final persistedUsedOutposts = sm.get('game.world.usedOutposts', true) ?? {};
  persistedUsedOutposts[key] = true;
  sm.set('game.world.usedOutposts', persistedUsedOutposts);
}
```

**修复后**：
```dart
void markOutpostUsed([int? x, int? y]) {
  // 只更新内存状态（参考原游戏：使用状态是临时的，不持久化）
  usedOutposts[key] = true;
  Logger.info('🏛️ 前哨站 ($x, $y) 已标记为已使用（临时状态）');
}
```

### 3. 修改outpostUsed()函数

**修复前**：
```dart
bool outpostUsed([int? x, int? y]) {
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

**修复后**：
```dart
bool outpostUsed([int? x, int? y]) {
  // 只检查内存中的临时状态（参考原游戏：使用状态不持久化）
  return usedOutposts[key] == true;
}
```

### 4. 修改World.init()函数

**修复前**：
```dart
// 从StateManager加载已使用的前哨站状态
final persistedUsedOutposts = sm.get('game.world.usedOutposts', true);
if (persistedUsedOutposts != null && persistedUsedOutposts is Map) {
  usedOutposts = Map<String, bool>.from(persistedUsedOutposts);
} else {
  usedOutposts = {};
  _inferUsedOutpostsFromMap();
}
```

**修复后**：
```dart
// 前哨站使用状态是临时的，每次出发时重置（参考原游戏逻辑）
usedOutposts = {};
Logger.info('🏛️ 前哨站使用状态初始化完成');
```

### 5. 移除不必要的函数

移除了`_inferUsedOutpostsFromMap()`函数，因为不再需要从持久化状态推断。

## 修复位置

- **文件**: `lib/modules/world.dart`
- **函数**: `onArrival()`, `markOutpostUsed()`, `outpostUsed()`, `init()`
- **行数**: 371-374, 1510-1518, 1527-1537, 1670-1673

## 预期效果

### ✅ 修复后的行为

1. **新创建的前哨站**：
   - 立即访问：✅ 可以获得熏肉和水，会变灰
   - 当次探索中再访问：❌ 无法再次使用（正确行为）

2. **返回村庄后再访问**：
   - ✅ 可以再次获得熏肉和水
   - ✅ 会变灰（通过markVisited实现）
   - ✅ 当次探索中再访问时无法使用

3. **已访问的前哨站（P!）**：
   - ✅ 每次出发都可以重新使用
   - ✅ 使用后在当次探索中不可再用
   - ✅ 返回村庄后可以再次使用

## 技术细节

### 状态管理机制

1. **临时使用状态**：`usedOutposts` - 每次出发重置
2. **永久访问状态**：地图上的`!`标记 - 持久保存
3. **前哨站变灰**：通过`markVisited()`在地图上添加`!`

### 与原游戏的一致性

- ✅ 使用状态管理：100%一致
- ✅ 访问检查逻辑：100%一致  
- ✅ 状态重置机制：100%一致
- ✅ 永久标记机制：100%一致

## 额外发现的问题

### 类型转换错误

在修复过程中发现了一个关键的类型转换错误：

**错误信息**：
```
TypeError: Instance of 'JSArray<dynamic>': type 'List<dynamic>' is not a subtype of type 'List<List<String>>'
```

**问题位置**：`lib/modules/world.dart` 第1782行和第1814行

**根因**：在`useOutpost()`函数中，试图将`state!['map']`直接转换为`List<List<String>>`，但实际上它是`List<dynamic>`类型。

**修复方案**：
```dart
// 修复前
final currentTile = state != null && state!['map'] != null
    ? (state!['map'] as List<List<String>>)[curPos[0]][curPos[1]]
    : 'unknown';

// 修复后
final currentTile = state != null && state!['map'] != null
    ? (state!['map'] as List<dynamic>)[curPos[0]][curPos[1]] as String
    : 'unknown';
```

这个错误导致前哨站的`useOutpost()`函数无法正常执行，从而无法获得熏肉和水，也无法变灰。

## 更新日期

2025-06-27

## 更新日志

- 2025-06-27: 修复前哨站状态持久化问题，使其符合原游戏逻辑
- 2025-06-27: 修复useOutpost()函数中的类型转换错误，解决前哨站无法正常使用的问题
