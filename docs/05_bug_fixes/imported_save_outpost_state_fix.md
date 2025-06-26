# 前哨站状态持久化修复

**最后更新**: 2025-06-22

## 问题描述

用户报告：
1. 灰色的前哨站P不能再次访问，但是有的灰色前哨站可再次访问
2. 导入存档的数据还是能访问灰色的P，访问一次就不能再访问了
3. **新问题**：访问潮湿洞穴后，转换成黑色P，访问P，P变成灰色，此时灰色P不可再访问，返回村庄；再次进入地图，灰色P又可以访问了

## 问题分析

### 根本原因

#### 1. 原游戏存档格式限制
原游戏的存档格式中**不包含前哨站使用状态**：
- 存档只保存地图的访问状态（P vs P!）
- 不保存前哨站的使用状态（usedOutposts）
- 原游戏可能使用不同的机制管理前哨站状态

#### 2. 导入后状态不一致
当导入原游戏存档时：
```dart
// 导入的存档数据结构
{
  "version": 1.3,
  "stores": {...},
  "game": {
    "world": {
      "map": [...], // 包含P!（已访问的前哨站）
      "mask": [...],
      // 注意：没有usedOutposts字段
    }
  }
}
```

#### 3. Flutter版本的状态管理
Flutter版本使用双重状态管理：
- **访问状态**：地图上的P!标记
- **使用状态**：usedOutposts Map

导入时只恢复了访问状态，使用状态为空。

#### 4. 回到村庄后状态丢失问题（新发现）
在`goHome()`和`onArrival()`函数中存在状态管理缺陷：

**goHome()函数**：
- 只保存了`state`到StateManager
- **没有保存`usedOutposts`状态**

**onArrival()函数**：
- 重新创建了临时世界状态
- **没有恢复`usedOutposts`状态**

导致前哨站使用状态在回到村庄后丢失。

### 具体问题场景

#### 场景1：导入存档后的灰色前哨站
```dart
// 导入后的状态
地图显示: P! (已访问)
usedOutposts: {} (空，因为原存档没有这个字段)

// 第一次访问
outpostUsed() -> false (因为usedOutposts为空)
// 允许使用一次，然后标记为已使用
markOutpostUsed() -> usedOutposts["x,y"] = true

// 第二次访问
outpostUsed() -> true (现在已标记为使用)
// 不允许再次使用
```

#### 场景2：Flutter版本创建的前哨站
```dart
// 正常流程
clearDungeon() -> 创建P
useOutpost() -> 标记为P!并设置usedOutposts["x,y"] = true
// 状态一致，不能再次使用
```

## 修复方案

### 方案1：导入时推断前哨站使用状态

在导入存档时，对于已访问的前哨站（P!），自动标记为已使用：

```dart
// 在StateManager.importGameState()中添加
void _inferOutpostUsageFromMap(Map<String, dynamic> importedData) {
  final worldData = importedData['game']?['world'];
  if (worldData == null) return;
  
  final map = worldData['map'];
  if (map == null || map is! List) return;
  
  final usedOutposts = <String, bool>{};
  
  // 扫描地图，找到已访问的前哨站
  for (int i = 0; i < map.length; i++) {
    if (map[i] is! List) continue;
    for (int j = 0; j < map[i].length; j++) {
      final tile = map[i][j].toString();
      if (tile == 'P!') {
        // 已访问的前哨站，标记为已使用
        final key = '$i,$j';
        usedOutposts[key] = true;
        Logger.info('🏛️ 推断前哨站 ($i, $j) 为已使用状态');
      }
    }
  }
  
  if (usedOutposts.isNotEmpty) {
    worldData['usedOutposts'] = usedOutposts;
    Logger.info('🏛️ 为导入存档推断了 ${usedOutposts.length} 个前哨站使用状态');
  }
}
```

### 方案2：改进导入验证逻辑

```dart
Future<bool> importGameState(String jsonData) async {
  try {
    final importedData = jsonDecode(jsonData) as Map<String, dynamic>;
    
    // 验证导入数据
    if (!_validateImportData(importedData)) {
      return false;
    }
    
    // 推断前哨站使用状态（针对原游戏存档）
    _inferOutpostUsageFromMap(importedData);
    
    // 继续原有的导入流程...
    _state = importedData;
    _ensureStateStructure();
    updateOldState();
    await saveGame();
    notifyListeners();
    
    return true;
  } catch (e) {
    Logger.error('❌ Import failed: $e');
    return false;
  }
}
```

### 方案3：改进World初始化逻辑

在World.init()中添加兼容性检查：

```dart
Logger.info('🏛️ 加载前哨站使用状态...');
final persistedUsedOutposts = sm.get('game.world.usedOutposts', true);

if (persistedUsedOutposts != null && persistedUsedOutposts is Map) {
  usedOutposts = Map<String, bool>.from(persistedUsedOutposts);
  Logger.info('🏛️ 已加载 ${usedOutposts.length} 个已使用的前哨站状态');
} else {
  // 如果没有使用状态数据，尝试从地图推断
  usedOutposts = {};
  _inferUsedOutpostsFromMap();
  Logger.info('🏛️ 初始化前哨站使用状态');
}
```

### 方案4：添加地图推断函数

```dart
void _inferUsedOutpostsFromMap() {
  final sm = StateManager();
  final worldMap = sm.get('game.world.map');
  
  if (worldMap == null || worldMap is! List) return;
  
  try {
    final map = List<List<String>>.from(
        worldMap.map((row) => List<String>.from(row)));
    
    int inferredCount = 0;
    for (int i = 0; i < map.length; i++) {
      for (int j = 0; j < map[i].length; j++) {
        if (map[i][j] == 'P!') {
          // 已访问的前哨站，推断为已使用
          final key = '$i,$j';
          usedOutposts[key] = true;
          inferredCount++;
        }
      }
    }
    
    if (inferredCount > 0) {
      // 保存推断的状态
      sm.set('game.world.usedOutposts', usedOutposts);
      Logger.info('🏛️ 从地图推断了 $inferredCount 个前哨站使用状态');
    }
  } catch (e) {
    Logger.info('⚠️ 推断前哨站状态失败: $e');
  }
}
```

## 实施方案

### ✅ 已实施修复方案

**修改文件**：`lib/modules/world.dart`

#### 修复1：World初始化时推断前哨站状态

#### 1. 修改World.init()逻辑
```dart
Logger.info('🏛️ 加载前哨站使用状态...');
final persistedUsedOutposts = sm.get('game.world.usedOutposts', true);
if (persistedUsedOutposts != null && persistedUsedOutposts is Map) {
  usedOutposts = Map<String, bool>.from(persistedUsedOutposts);
  Logger.info('🏛️ 已加载 ${usedOutposts.length} 个已使用的前哨站状态');
} else {
  // 如果没有使用状态数据，尝试从地图推断（兼容原游戏存档）
  usedOutposts = {};
  _inferUsedOutpostsFromMap();
  Logger.info('🏛️ 初始化前哨站使用状态');
}
```

#### 2. 添加推断函数
```dart
void _inferUsedOutpostsFromMap() {
  final sm = StateManager();
  final worldMap = sm.get('game.world.map');

  if (worldMap == null || worldMap is! List) return;

  try {
    final map = List<List<String>>.from(
        worldMap.map((row) => List<String>.from(row)));

    int inferredCount = 0;
    for (int i = 0; i < map.length; i++) {
      for (int j = 0; j < map[i].length; j++) {
        if (map[i][j] == 'P!') {
          // 已访问的前哨站，推断为已使用
          final key = '$i,$j';
          usedOutposts[key] = true;
          inferredCount++;
          Logger.info('🏛️ 推断前哨站 ($i, $j) 为已使用状态');
        }
      }
    }

    if (inferredCount > 0) {
      // 保存推断的状态
      sm.set('game.world.usedOutposts', usedOutposts);
      Logger.info('🏛️ 从地图推断了 $inferredCount 个前哨站使用状态并保存');
    }
  } catch (e) {
    Logger.info('⚠️ 推断前哨站状态失败: $e');
  }
}
```

#### 修复2：goHome()函数中保存前哨站状态

```dart
// 保存世界状态到StateManager - 参考原游戏逻辑
if (state != null) {
  final sm = StateManager();
  sm.setM('game.world', state!);
  Logger.info('🏠 保存世界状态完成');

  // 确保前哨站使用状态也被保存
  if (usedOutposts.isNotEmpty) {
    sm.set('game.world.usedOutposts', usedOutposts);
    Logger.info('🏛️ 保存前哨站使用状态: ${usedOutposts.length} 个已使用');
  }
}
```

#### 修复3：onArrival()函数中恢复前哨站状态

```dart
// 设置初始位置和状态
curPos = [villagePos[0], villagePos[1]];
health = getMaxHealth();
water = getMaxWater();

// 恢复前哨站使用状态
final persistedUsedOutposts = sm.get('game.world.usedOutposts', true);
if (persistedUsedOutposts != null && persistedUsedOutposts is Map) {
  usedOutposts = Map<String, bool>.from(persistedUsedOutposts);
  Logger.info('🏛️ 恢复前哨站使用状态: ${usedOutposts.length} 个已使用');
} else {
  usedOutposts = {};
  Logger.info('🏛️ 初始化空的前哨站使用状态');
}
```

### 🔄 未来优化：导入时直接处理
可以在StateManager.importGameState()中添加推断逻辑，提供更好的用户体验。

## 预期效果

### ✅ 修复后的行为
1. **导入原游戏存档**：
   - 灰色前哨站P!自动标记为已使用
   - 不能再次访问使用
   - 状态一致性

2. **导入Flutter版本存档**：
   - 正确恢复前哨站使用状态
   - 保持原有行为

3. **新游戏**：
   - 前哨站状态管理正常
   - 不受影响

4. **回到村庄后再次进入地图**：
   - 前哨站使用状态正确保持
   - 已使用的前哨站仍然不能再次使用
   - 状态持久化正常

### 🎯 测试用例
1. **导入存档测试**：
   - 导入包含灰色前哨站的原游戏存档
   - 验证灰色前哨站不能使用
   - 导入Flutter版本存档验证状态正确

2. **状态持久化测试**：
   - 访问潮湿洞穴，清理后获得前哨站
   - 使用前哨站，验证变为灰色且不能再次使用
   - 回到村庄，再次进入地图
   - 验证灰色前哨站仍然不能使用

3. **新游戏测试**：
   - 验证前哨站正常工作
   - 验证状态管理不受影响

## 技术细节

### 推断逻辑
```
P  (黑色前哨站) -> 未使用 (usedOutposts[key] = false)
P! (灰色前哨站) -> 已使用 (usedOutposts[key] = true)
```

### 日志输出
```
🏛️ 加载前哨站使用状态...
🏛️ 从地图推断了 3 个前哨站使用状态
🏛️ 推断前哨站 (28, 33) 为已使用状态
🏛️ 推断前哨站 (15, 20) 为已使用状态
🏛️ 推断前哨站 (42, 18) 为已使用状态
```

这个修复确保了导入存档后前哨站状态的一致性和正确性。
