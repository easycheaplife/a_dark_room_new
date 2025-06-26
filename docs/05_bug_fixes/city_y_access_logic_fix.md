# 废墟城市Y访问逻辑修复

## 问题描述

用户报告废墟城市Y的访问逻辑问题：

1. **进入城市时立即变灰**：废墟城市Y在进入时就变成灰色，而不是保持黑色
2. **转换失败**：即使使用"测试转换"按钮也无法将城市转换为前哨站P
3. **类型转换错误**：clearCity函数中出现类型转换异常

## 问题分析

### 根本原因

通过深入分析代码，发现了两个主要问题：

1. **doSpace中的立即标记问题**：
   - 在`lib/modules/world.dart`第1072行，废墟城市Y在进入时被立即调用`markVisited()`
   - 这导致城市在进入时就变成灰色Y!，而不是保持黑色Y

2. **clearCity中的调用顺序问题**：
   - 在`lib/modules/setpieces.dart`第2640-2646行，clearCity函数先调用`markVisited()`再调用`clearDungeon()`
   - 这导致城市先变灰再转换为前哨站，不符合原游戏逻辑

3. **类型转换错误**：
   - 在`lib/modules/setpieces.dart`第2619行，直接将地图数据强制转换为`List<List<String>>?`类型
   - 在Web环境中，地图数据是`JSArray<dynamic>`类型，导致类型转换失败

### 原游戏行为

根据原游戏逻辑，废墟城市的正确行为应该是：

1. **进入城市**：城市保持黑色Y，不立即标记为已访问
2. **探索过程**：城市在探索过程中保持黑色
3. **完成探索**：只有完成完整探索到达end1场景时，才调用clearCity
4. **城市转换**：clearCity直接将城市转换为前哨站P，不经过灰色状态

## 修复方案

### 修复1：移除doSpace中的立即标记

**位置**：`lib/modules/world.dart` 第1069-1073行
**修改内容**：
```dart
// 修改前
case 'Y': // 废墟城市
  NotificationManager().notify(
      name, localization.translate('world.notifications.ruined_city'));
  markVisited(curPos[0], curPos[1]);
  break;

// 修改后
case 'Y': // 废墟城市
  NotificationManager().notify(
      name, localization.translate('world.notifications.ruined_city'));
  // 注意：废墟城市不在这里标记为已访问
  // 只有完成完整探索后才会在clearCity中转换为前哨站
  break;
```

### 修复2：调整clearCity中的调用顺序

**位置**：`lib/modules/setpieces.dart` 第2640-2646行
**修改内容**：
```dart
// 修改前
// 先标记城市为已访问，然后转换为前哨站
Logger.info('🏛️ 调用 World().markVisited()');
world.markVisited(world.curPos[0], world.curPos[1]);

// 城市清理后也要转换为前哨站
Logger.info('🏛️ 调用 World().clearDungeon()');
world.clearDungeon();

// 修改后
// 城市清理后直接转换为前哨站，不需要先标记为已访问
// 因为clearDungeon会直接将地形改为P，而不是Y!
Logger.info('🏛️ 调用 World().clearDungeon()');
world.clearDungeon();
```

### 修复3：修复类型转换错误

**位置**：`lib/modules/setpieces.dart` 第2618-2623行
**修改内容**：
```dart
// 修改前
// 检查当前地形
final currentMap = world.state?['map'] as List<List<String>>?;
if (currentMap == null) {
  Logger.error('❌ 地图数据为空！');
  return;
}

// 修改后
// 检查当前地形
final mapData = world.state?['map'];
if (mapData == null) {
  Logger.error('❌ 地图数据为空！');
  return;
}

// 安全地转换地图数据类型
final currentMap = List<List<String>>.from(
    mapData.map((row) => List<String>.from(row)));
if (currentMap.isEmpty) {
  Logger.error('❌ 地图数据为空！');
  return;
}
```

## 测试验证

### 测试步骤

1. 启动应用：`flutter run -d chrome`
2. 进入世界地图，移动到废墟城市Y
3. 验证城市保持黑色Y状态
4. 进入城市，使用"测试转换"按钮
5. 验证城市成功转换为黑色前哨站P
6. 使用前哨站补充水源
7. 验证前哨站变为灰色P!

### 测试结果

✅ **所有测试通过**

1. **进入城市时保持黑色Y** - 日志显示：`原始地形: Y, 已访问: false`
2. **测试转换成功** - 日志显示：`地形转换: Y -> P 在位置 [32, 11]`
3. **转换后变成黑色P** - 日志显示：`原始地形: P, 已访问: false`
4. **前哨站正常使用** - 日志显示：`前哨站使用完成 - 水: 9 -> 30`
5. **使用后变灰色P!** - 日志显示：`最终状态 - 已使用: true, 地形: P!`

## 影响范围

### 修复效果

修复后，废墟城市的完整流程：

1. **城市访问**：
   - 进入废墟城市Y时保持黑色状态
   - 不会立即标记为已访问

2. **城市探索**：
   - 探索过程中城市保持黑色Y
   - 只有完成完整探索才触发转换

3. **城市转换**：
   - clearCity直接调用clearDungeon转换为前哨站
   - 城市从Y直接变为P，不经过灰色状态

4. **前哨站使用**：
   - 新创建的前哨站显示为黑色P
   - 可以使用一次补充水源
   - 使用后变为灰色P!，无法再次访问

### 兼容性

- ✅ 与原游戏逻辑完全一致
- ✅ 不影响其他地标的访问逻辑
- ✅ 保持现有的前哨站使用机制
- ✅ 修复了Web环境下的类型转换问题

## 更新日期

2025-01-28

## 更新日志

- 修复废墟城市Y进入时立即变灰的问题
- 修复clearCity函数中的调用顺序问题
- 修复Web环境下的类型转换错误
- 确保城市转换逻辑与原游戏完全一致
