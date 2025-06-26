# 火把背包检查实现总结

**最后更新**: 2025-06-26

## 概述

本文档总结了火把背包检查功能的完整实现，确保火把检查和消耗都只针对背包，不涉及库存，完全符合用户需求。

## 用户需求回顾

用户明确要求：
1. 进入潮湿洞穴、铁矿、煤矿、硫磺矿、废弃小镇时，需要背包中携带火把才能进入
2. 检查火把是检查背包的火把，而不是库存
3. 如果背包火把不够，则进入按钮置灰，鼠标悬停显示"火把 1"
4. 火把检查和扣除都是指背包，不是库存
5. 统一处理所有地形，逻辑封装成函数

## 实现方案

### 1. 核心逻辑实现

#### Events模块 (`lib/modules/events.dart`)

**背包成本检查函数**:
```dart
bool canAffordBackpackCost(Map<String, dynamic> costs) {
  final path = Path();
  
  for (final entry in costs.entries) {
    final key = entry.key;
    final cost = entry.value as int;
    
    // 对于火把等工具，只检查背包
    if (_isToolItem(key)) {
      final outfitAmount = path.outfit[key] ?? 0;
      if (outfitAmount < cost) {
        Logger.info('🎒 背包中$key不足: 需要$cost, 拥有$outfitAmount');
        return false;
      }
    }
  }
  return true;
}
```

**背包消耗函数**:
```dart
void consumeBackpackCost(Map<String, dynamic> costs) {
  final path = Path();
  final sm = StateManager();
  
  for (final entry in costs.entries) {
    final key = entry.key;
    final cost = entry.value as int;
    
    if (_isToolItem(key)) {
      // 从背包消耗
      final outfitAmount = path.outfit[key] ?? 0;
      path.outfit[key] = outfitAmount - cost;
      sm.set('outfit["$key"]', path.outfit[key]);
      Logger.info('💰 从背包消耗: $key -$cost (剩余: ${path.outfit[key]})');
    }
  }
}
```

**工具类物品识别**:
```dart
bool _isToolItem(String itemName) {
  return itemName == 'torch' || 
         itemName == 'cured meat' ||
         itemName == 'bullets' ||
         itemName == 'medicine' ||
         itemName == 'hypo' ||
         itemName == 'stim' ||
         itemName == 'energy cell' ||
         itemName == 'charm';
}
```

### 2. UI层实现

#### 事件界面 (`lib/screens/events_screen.dart`)

**按钮可用性检查**:
```dart
// 检查按钮是否可用（专门检查背包中的火把等工具）
final canAfford = _canAffordButtonCost(cost);
final isDisabled = !canAfford;

// 生成禁用原因
String? disabledReason;
if (isDisabled && cost != null) {
  disabledReason = _getDisabledReason(cost);
}
```

**工具提示生成**:
```dart
String _getDisabledReason(Map<String, dynamic> cost) {
  for (final entry in cost.entries) {
    final key = entry.key;
    final required = (entry.value as num).toInt();
    
    if (_isToolItem(key)) {
      final outfitAmount = path.outfit[key] ?? 0;
      if (outfitAmount < required) {
        final itemName = localization.translate('resources.$key');
        final displayName = itemName != 'resources.$key' ? itemName : key;
        return '$displayName $required'; // 显示"火把 1"
      }
    }
  }
  return '';
}
```

### 3. 支持功能

#### Path模块 - 火把可携带
```dart
// 添加房间的可制作物品（特别是火把等工具）
final room = Room();
for (final entry in room.craftables.entries) {
  final itemName = entry.key;
  final itemConfig = entry.value;
  if (itemConfig['type'] == 'tool' || itemConfig['type'] == 'weapon') {
    carryable[itemName] = {
      'type': itemConfig['type'],
      'desc': itemConfig['buildMsg'] ?? '',
    };
  }
}
```

#### World模块 - 火把不留在家里
```dart
bool leaveItAtHome(String thing) {
  return thing != 'cured meat' &&
      thing != 'bullets' &&
      thing != 'energy cell' &&
      thing != 'charm' &&
      thing != 'medicine' &&
      thing != 'stim' &&
      thing != 'hypo' &&
      thing != 'torch' && // 火把可以带走
      !weapons.containsKey(thing) &&
      !_isRoomCraftable(thing);
}
```

## 测试验证

### 测试结果

所有核心功能测试通过：

1. ✅ **背包有火把时可以进入**: 背包中有火把时，`canAffordBackpackCost()`返回true
2. ✅ **背包没有火把时无法进入**: 即使库存有火把，背包没有时返回false
3. ✅ **火把只从背包消耗**: `consumeBackpackCost()`只减少背包中的火把，不影响库存
4. ✅ **火把可以带走**: `leaveItAtHome('torch')`返回false
5. ✅ **工具类物品识别正确**: 火把、熏肉、子弹等都被正确识别为工具类物品

### 日志输出示例

```
[INFO] 🎒 背包中torch不足: 需要1, 拥有0
[INFO] 💰 从背包消耗: torch -1 (剩余: 1)
```

## 影响的地形

以下地形的进入按钮现在都使用统一的背包检查逻辑：

1. **潮湿洞穴 (V)** - 需要火把 1
2. **铁矿 (I)** - 需要火把 1  
3. **煤矿 (C)** - 需要火把 1
4. **硫磺矿 (S)** - 需要火把 1
5. **废弃小镇 (O)** - 需要火把 1

## 用户体验

### 按钮状态

- **可用状态**: 背包中有足够火把时，按钮正常显示
- **禁用状态**: 背包中火把不足时，按钮置灰
- **工具提示**: 鼠标悬停显示"火把 1"等需求信息

### 游戏逻辑

- **探索准备**: 玩家需要在出发前将火把添加到背包
- **资源管理**: 火把消耗只影响背包，不影响村庄库存
- **策略规划**: 玩家需要合理规划背包中的火把数量

## 技术特点

### 1. 统一封装
- 所有火把检查逻辑封装在`canAffordBackpackCost()`函数中
- 所有火把消耗逻辑封装在`consumeBackpackCost()`函数中
- 避免了每个地形重复添加检查代码

### 2. 类型识别
- 通过`_isToolItem()`函数识别工具类物品
- 工具类物品从背包检查和消耗
- 非工具类物品仍从库存检查和消耗

### 3. 日志记录
- 详细的日志记录帮助调试和验证
- 清楚显示背包不足的原因
- 记录消耗过程和剩余数量

## 总结

本次实现完全满足用户需求：

1. ✅ **专门检查背包**: 火把检查只针对背包，不涉及库存
2. ✅ **专门从背包消耗**: 火把消耗只从背包扣除
3. ✅ **按钮置灰**: 背包火把不足时按钮正确置灰
4. ✅ **工具提示**: 显示"火把 1"等正确的需求信息
5. ✅ **统一处理**: 所有地形使用相同的检查逻辑
6. ✅ **逻辑封装**: 避免重复代码，易于维护

实现后的火把检查逻辑严格按照用户要求，确保了游戏体验的一致性和准确性。
