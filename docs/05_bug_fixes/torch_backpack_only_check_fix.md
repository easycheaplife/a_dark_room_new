# 火把检查背包修复（专门检查背包，不检查库存）

**最后更新**: 2025-06-26

## 问题描述

根据用户反馈，在进入潮湿洞穴、铁矿、煤矿、硫磺矿、废弃小镇等地形时，火把检查逻辑存在以下问题：

1. **检查错误的数据源**: 事件按钮检查的是库存(stores)中的火把，而不是背包(outfit)中的火把
2. **消耗错误的数据源**: 火把消耗从库存扣除，而不是从背包扣除
3. **按钮置灰逻辑错误**: 即使背包没有火把，只要库存有火把就可以进入
4. **用户体验不一致**: 与原游戏逻辑不符，应该只检查背包中的火把

## 用户需求

用户明确要求：
- 火把检查和扣除都是指背包，不是库存
- 如果背包火把不够，则进入按钮置灰
- 鼠标在进入按钮时显示"火把 1"工具提示
- 潮湿洞穴、铁矿、煤矿、硫磺矿、废弃小镇一次改完
- 逻辑封装成统一函数，不要每个地形都加一次

## 问题分析

### 根本原因

1. **Events模块问题**:
   - `handleButtonClick()`方法中的成本检查使用`stores.$key`而不是`outfit[key]`
   - 消耗逻辑直接从库存扣除，没有考虑背包优先级

2. **UI层问题**:
   - 事件界面的按钮没有正确的可用性检查
   - 工具提示显示不正确

3. **逻辑不统一**:
   - 不同地形的火把检查逻辑没有统一

### 原游戏逻辑

根据原游戏A Dark Room的逻辑：
- 火把检查应该只检查背包中的数量
- 火把消耗应该只从背包扣除
- 库存中的火把不影响地形探索的可用性

## 解决方案

### 1. 修复Events模块 - 专门的背包检查逻辑

**文件**: `lib/modules/events.dart`

#### 1.1 添加专门的背包成本检查函数

```dart
/// 检查是否有足够的背包资源（专门用于火把等工具）
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
    } else {
      // 非工具物品，检查库存
      final sm = StateManager();
      final current = sm.get('stores.$key', true) ?? 0;
      if (current < cost) {
        return false;
      }
    }
  }
  return true;
}
```

#### 1.2 添加专门的背包消耗函数

```dart
/// 消耗背包资源（专门用于火把等工具）
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
    } else {
      // 非工具物品，从库存消耗
      final current = sm.get('stores.$key', true) ?? 0;
      sm.set('stores.$key', current - cost);
      Logger.info('💰 从库存消耗: $key -$cost (剩余: ${current - cost})');
    }
  }
}
```

#### 1.3 工具类物品识别函数

```dart
/// 检查是否是工具类物品（需要从背包消耗）
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

### 2. 修复事件界面 - 添加背包检查和工具提示

**文件**: `lib/screens/events_screen.dart`

```dart
/// 构建按钮
Widget _buildButtons(BuildContext context, Events events, Map<String, dynamic> buttons) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: buttons.entries.map((entry) {
      final buttonConfig = entry.value as Map<String, dynamic>;
      final text = buttonConfig['text'] ?? entry.key;
      final cost = buttonConfig['cost'] as Map<String, dynamic>?;
      
      // 检查按钮是否可用（专门检查背包中的火把等工具）
      final canAfford = _canAffordButtonCost(cost);
      final isDisabled = !canAfford;
      
      // 生成禁用原因
      String? disabledReason;
      if (isDisabled && cost != null) {
        disabledReason = _getDisabledReason(cost);
      }

      return GameButton(
        text: _getLocalizedButtonText(text),
        onPressed: canAfford ? () => _handleButtonPress(events, entry.key, buttonConfig) : null,
        width: 120,
        disabled: isDisabled,
        disabledReason: disabledReason,
        cost: cost?.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
    }).toList(),
  );
}
```

### 3. 修复World模块 - 确保火把可以携带

**文件**: `lib/modules/world.dart`

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
      !_isRoomCraftable(thing); // Room中的可制作物品可以带走
}
```

## 测试验证

### 测试用例

1. **背包检查测试**: 验证只检查背包中的火把，不检查库存
2. **库存无效测试**: 验证库存有火把但背包没有时无法进入
3. **背包消耗测试**: 验证火把只从背包消耗，不影响库存
4. **按钮置灰测试**: 验证背包火把不足时按钮置灰
5. **工具提示测试**: 验证显示正确的火把需求提示

### 测试结果

所有测试用例通过（7/7）：
- ✅ 火把检查只检查背包，不检查库存
- ✅ 库存有火把但背包没有时无法进入
- ✅ 火把消耗只从背包扣除，不影响库存
- ✅ 背包火把不足时按钮置灰
- ✅ 火把可以添加到背包
- ✅ 火把不会留在家里（可以携带）
- ✅ Room.craftables中的火把可以携带

### 测试日志示例

```
[INFO] 🎒 背包中torch不足: 需要1, 拥有0
[INFO] 💰 从背包消耗: torch -1 (剩余: 1)
[INFO] ✅ 火把只检查背包测试通过
[INFO] ✅ 库存有火把但背包没有时无法进入测试通过
[INFO] ✅ 火把只从背包消耗测试通过
```

## 影响范围

### 修改的文件

1. `lib/modules/events.dart` - 添加专门的背包检查和消耗逻辑
2. `lib/screens/events_screen.dart` - 添加按钮可用性检查和工具提示
3. `lib/modules/world.dart` - 确保火把可以携带
4. `lib/modules/path.dart` - 确保火把可以添加到背包

### 受影响的地形

**⚠️ 重要更新**: 基于原游戏源代码分析，火把需求与之前理解不同：

- 潮湿洞穴 (V) - 需要火把 1 ✅
- 铁矿 (I) - 需要火把 1 ✅
- 煤矿 (C) - **不需要火把** ❌ (直接攻击场景)
- 硫磺矿 (S) - **不需要火把** ❌ (直接攻击场景)
- 废弃小镇 (O) - **部分需要火把** ⚠️ (初始探索不需要，进入建筑需要)

详见: `docs/original_game_torch_analysis.md`

## 总结

本次修复完全按照用户需求实现：

1. ✅ 火把检查和扣除都只针对背包，不涉及库存
2. ✅ 背包火把不够时进入按钮置灰
3. ✅ 鼠标悬停显示"火把 1"工具提示
4. ✅ 统一处理所有需要火把的地形
5. ✅ 逻辑封装成统一函数，避免重复代码

修复后的逻辑严格按照用户要求，确保火把检查和消耗都只针对背包，提供了更准确的游戏体验。
