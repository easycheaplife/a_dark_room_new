# A Dark Room 移动消耗熏肉机制分析

**创建时间**: 2025-06-29  
**分析范围**: 原游戏与Flutter项目中移动消耗熏肉的机制对比

## 📋 目录

- [原游戏机制分析](#-原游戏机制分析)
- [Flutter项目实现](#-flutter项目实现)
- [机制对比](#-机制对比)
- [技能影响](#-技能影响)
- [代码实现细节](#-代码实现细节)

## 🎮 原游戏机制分析

### 基础消耗规则

#### 📊 核心常量
```javascript
// adarkroom/script/world.js
World.MOVES_PER_FOOD = 2;  // 每2步消耗1个熏肉
World.MEAT_HEAL = 8;       // 熏肉恢复8点生命值
```

#### 🚶‍♂️ 移动消耗逻辑
```javascript
useSupplies: function() {
  World.foodMove++;        // 每次移动增加食物计数器
  World.waterMove++;       // 每次移动增加水计数器
  
  // 食物消耗检查
  var movesPerFood = World.MOVES_PER_FOOD;  // 基础值：2
  movesPerFood *= $SM.hasPerk('slow metabolism') ? 2 : 1;  // 技能影响
  
  if(World.foodMove >= movesPerFood) {
    World.foodMove = 0;    // 重置计数器
    var num = Path.outfit['cured meat'];
    num--;                 // 消耗1个熏肉
    
    if(num === 0) {
      // 熏肉用完警告
      Notifications.notify(World, _('the meat has run out'));
    } else if(num < 0) {
      // 饥饿状态处理
      num = 0;
      if(!World.starvation) {
        Notifications.notify(World, _('starvation sets in'));
        World.starvation = true;
      } else {
        // 饥饿死亡
        World.die();
        return false;
      }
    } else {
      // 正常消耗，恢复生命值
      World.starvation = false;
      World.setHp(World.health + World.meatHeal());
    }
    Path.outfit['cured meat'] = num;
  }
}
```

### 消耗时机

1. **每次移动都调用**: `useSupplies()` 在每次移动时被调用
2. **计数器机制**: 使用 `foodMove` 计数器跟踪移动次数
3. **达到阈值消耗**: 当 `foodMove >= movesPerFood` 时消耗熏肉
4. **重置计数器**: 消耗后重置 `foodMove = 0`

### 消耗效果

1. **生命值恢复**: 消耗熏肉时恢复8点生命值
2. **饥饿状态**: 熏肉不足时进入饥饿状态
3. **死亡机制**: 持续饥饿会导致死亡

## 🎯 Flutter项目实现

### 基础配置
```dart
// lib/modules/world.dart
static const int movesPerFood = 2;  // 每2步消耗1个熏肉
static const int meatHeal = 8;      // 熏肉恢复8点生命值
```

### 实现逻辑
```dart
bool useSupplies() {
  foodMove++;        // 每次移动增加食物计数器
  waterMove++;       // 每次移动增加水计数器
  
  // 食物消耗检查
  int currentMovesPerFood = movesPerFood;  // 基础值：2
  if (StateManager().hasPerk('slow metabolism')) {
    currentMovesPerFood *= 2;  // 技能影响：消耗减半
  }
  
  if (foodMove >= currentMovesPerFood) {
    foodMove = 0;    // 重置计数器
    var num = path.outfit['cured meat'] ?? 0;
    num--;           // 消耗1个熏肉
    
    if (num == 0) {
      // 熏肉用完警告
      NotificationManager().notify(name, 
          localization.translate('world.notifications.out_of_meat'));
    } else if (num < 0) {
      // 饥饿状态处理
      num = 0;
      if (!starvation) {
        NotificationManager().notify(name,
            localization.translate('world.notifications.starvation_begins'));
        starvation = true;
      } else {
        // 饥饿死亡
        die();
        return false;
      }
    } else {
      // 正常消耗，恢复生命值
      starvation = false;
      final healAmount = meatHealAmount();
      setHp(health + healAmount);
    }
    
    // 更新背包和StateManager
    path.outfit['cured meat'] = num;
    sm.set('outfit["cured meat"]', num);
  }
  return true;
}
```

## 🔍 机制对比

### ✅ 一致性方面

| 方面 | 原游戏 | Flutter项目 | 状态 |
|------|--------|-------------|------|
| **基础消耗频率** | 每2步消耗1个熏肉 | 每2步消耗1个熏肉 | ✅ 一致 |
| **生命值恢复** | 8点 | 8点 | ✅ 一致 |
| **计数器机制** | foodMove计数器 | foodMove计数器 | ✅ 一致 |
| **饥饿状态** | 熏肉不足进入饥饿 | 熏肉不足进入饥饿 | ✅ 一致 |
| **死亡机制** | 持续饥饿死亡 | 持续饥饿死亡 | ✅ 一致 |
| **技能影响** | slow metabolism减半消耗 | slow metabolism减半消耗 | ✅ 一致 |

### 🔧 实现细节差异

#### 1. 错误处理
- **原游戏**: 直接访问 `Path.outfit['cured meat']`
- **Flutter项目**: 使用 `try-catch` 和 `?? 0` 进行安全访问

#### 2. 状态同步
- **原游戏**: 只更新 `Path.outfit`
- **Flutter项目**: 同时更新 `Path.outfit` 和 `StateManager`

#### 3. 日志记录
- **原游戏**: 无详细日志
- **Flutter项目**: 详细的调试日志

#### 4. 本地化
- **原游戏**: 使用 `_()` 函数
- **Flutter项目**: 使用 `Localization().translate()`

## ⚙️ 技能影响

### 缓慢新陈代谢 (Slow Metabolism)

#### 原游戏实现
```javascript
var movesPerFood = World.MOVES_PER_FOOD;  // 2
movesPerFood *= $SM.hasPerk('slow metabolism') ? 2 : 1;  // 变成4
```

#### Flutter项目实现
```dart
int currentMovesPerFood = movesPerFood;  // 2
if (StateManager().hasPerk('slow metabolism')) {
  currentMovesPerFood *= 2;  // 变成4
}
```

**效果**: 食物消耗频率从每2步变为每4步，实际上是消耗减半。

### 美食家 (Gastronome)

#### 治疗效果增强
```dart
int meatHealAmount() {
  int healAmount = meatHeal;  // 8点
  if (StateManager().hasPerk('gastronome')) {
    healAmount *= 2;  // 变成16点
  }
  return healAmount;
}
```

**效果**: 熏肉治疗效果从8点翻倍到16点。

## 📊 消耗计算示例

### 正常情况
- **移动1步**: foodMove = 1, 不消耗
- **移动2步**: foodMove = 2 >= 2, 消耗1个熏肉, foodMove重置为0
- **移动3步**: foodMove = 1, 不消耗
- **移动4步**: foodMove = 2 >= 2, 消耗1个熏肉, foodMove重置为0

### 有缓慢新陈代谢技能
- **移动1-3步**: foodMove = 1-3, 不消耗
- **移动4步**: foodMove = 4 >= 4, 消耗1个熏肉, foodMove重置为0
- **移动5-7步**: foodMove = 1-3, 不消耗
- **移动8步**: foodMove = 4 >= 4, 消耗1个熏肉, foodMove重置为0

## 🎯 结论

### ✅ 机制正确性
我们的Flutter项目完全正确地实现了原游戏的移动消耗熏肉机制：

1. **基础消耗**: 每2步消耗1个熏肉 ✅
2. **生命值恢复**: 每次消耗恢复8点生命值 ✅
3. **技能影响**: 正确实现了相关技能的效果 ✅
4. **饥饿机制**: 正确实现了饥饿状态和死亡逻辑 ✅

### 🔧 改进方面
Flutter项目在保持原游戏机制的基础上，增加了：

1. **更好的错误处理**: 防止null访问错误
2. **详细的日志记录**: 便于调试和问题排查
3. **状态同步**: 确保数据一致性
4. **本地化支持**: 支持多语言

### 📝 验证方法
可以通过以下方式验证机制正确性：
1. 在世界地图中移动，观察每2步消耗1个熏肉
2. 检查生命值在消耗熏肉时是否恢复8点
3. 测试缓慢新陈代谢技能是否将消耗频率改为每4步
4. 验证美食家技能是否将治疗效果翻倍到16点
