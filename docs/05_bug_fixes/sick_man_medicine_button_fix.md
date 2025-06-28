# 病人事件药品按钮修复

## 🐛 问题描述

在病人事件中，虽然库存中有药品，但"帮助他"按钮显示为灰色（不可用状态）。

### 问题现象
- 库存显示有药品（medicine）
- 病人事件可以触发（说明满足了事件可用性条件）
- 但"帮助他"按钮被禁用，无法点击

### 问题截图
用户提供的截图显示：
- 事件标题：病人
- 事件描述：一个生病的男人蹒跚着走向你的火堆，他看起来很虚弱，急需医疗帮助
- 按钮："帮助他"显示为灰色，"拒绝帮助"可用
- 库存显示：药品 1

## 🔍 问题分析

### 根本原因
药品存储位置检查不一致：

1. **事件可用性检查**（正确）：
   ```dart
   // lib/events/room_events_extended.dart
   'isAvailable': () {
     final medicine = _sm.get('stores.medicine', true) ?? 0;
     return fire > 0 && medicine > 0; // 检查库存中的药品
   }
   ```

2. **按钮可用性检查**（错误）：
   ```dart
   // lib/screens/events_screen.dart
   bool _isToolItem(String itemName) {
     return itemName == 'medicine' || ...; // 药品被标记为工具类物品
   }
   
   // 导致检查背包而不是库存
   if (_isToolItem(key)) {
     final outfitAmount = path.outfit[key] ?? 0; // 检查背包
   }
   ```

### 药品存储逻辑
- **库存（stores.medicine）**：在房间/村庄中的药品存储
- **背包（outfit.medicine）**：在路径探索中携带的药品
- **房间事件**：应该从库存消耗药品，而不是从背包

### 原游戏对比
原游戏 `adarkroom/script/events/room.js` 中：
```javascript
{ /* The Sick Man */
  title: _('The Sick Man'),
  isAvailable: function() {
    return Engine.activeModule == Room && $SM.get('stores.medicine', true) > 0;
  },
  scenes: {
    'start': {
      buttons: {
        'help': {
          text: _('give 1 medicine'),
          cost: { 'medicine': 1 }, // 从库存消耗
        }
      }
    }
  }
}
```

## 🔧 解决方案

### 修复内容
将药品从工具类物品列表中移除，使其按照普通库存物品处理：

**文件1**: `lib/screens/events_screen.dart`
```dart
/// 检查是否是工具类物品（需要从背包消耗）
bool _isToolItem(String itemName) {
  return itemName == 'torch' ||
      itemName == 'cured meat' ||
      itemName == 'bullets' ||
      itemName == 'hypo' ||
      itemName == 'stim' ||
      itemName == 'energy cell' ||
      itemName == 'charm';
  // 注意：medicine在房间事件中从库存消耗，不是从背包消耗
}
```

**文件2**: `lib/modules/events.dart`
```dart
/// 检查是否是工具类物品（需要从背包消耗）
bool _isToolItem(String itemName) {
  return itemName == 'torch' ||
      itemName == 'cured meat' ||
      itemName == 'bullets' ||
      itemName == 'hypo' ||
      itemName == 'stim' ||
      itemName == 'energy cell' ||
      itemName == 'charm';
  // 注意：medicine在房间事件中从库存消耗，不是从背包消耗
}
```

### 修复逻辑
1. **按钮可用性检查**：药品不再被视为工具类物品，检查 `stores.medicine`
2. **成本消耗**：药品从 `stores.medicine` 扣除，而不是从 `outfit.medicine`
3. **保持一致性**：事件可用性和按钮可用性都检查同一个存储位置

## ✅ 验证结果

修复后的行为：
1. 库存中有药品时，病人事件可以触发
2. "帮助他"按钮可用（不再显示灰色）
3. 点击按钮后，从库存中扣除1个药品
4. 事件正常进行，可能获得奖励

## 🎯 影响范围

### 受影响的功能
- 病人事件（房间事件）
- 其他使用药品的房间事件

### 不受影响的功能
- 路径探索中的药品使用（仍从背包消耗）
- 战斗中的药品使用（仍从背包消耗）
- 其他工具类物品的处理逻辑

## 📝 技术细节

### 物品分类逻辑
- **工具类物品**：火把、熏肉、子弹、注射器、兴奋剂、能量电池、护身符
  - 在路径探索中使用
  - 从背包（outfit）消耗
- **库存物品**：木材、毛皮、肉类、药品等
  - 在房间/村庄中使用
  - 从库存（stores）消耗

### 药品的特殊性
药品是唯一既可以在房间使用（治疗病人）又可以在路径使用（战斗治疗）的物品：
- **房间使用**：从库存消耗
- **路径使用**：从背包消耗

## 🔄 相关代码位置

- `lib/screens/events_screen.dart` - 事件界面按钮检查
- `lib/modules/events.dart` - 事件处理逻辑
- `lib/events/room_events_extended.dart` - 病人事件定义
- `lib/modules/path.dart` - 路径模块药品使用
- `lib/screens/combat_screen.dart` - 战斗中药品使用
