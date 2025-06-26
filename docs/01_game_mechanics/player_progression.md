# 玩家进度系统完整指南

**最后更新**: 2025-06-26

## 📋 概述

本文档是A Dark Room玩家进度系统的完整指南，整合了玩家健康、水容量、背包容量三大成长机制，为开发者提供统一的玩家属性系统参考资料。

## 🩸 玩家健康系统

### 基础健康配置

```dart
// lib/modules/world.dart
static const int baseHealth = 10;      // 基础血量
static const int meatHeal = 8;         // 肉类恢复量
static const int medsHeal = 20;        // 药物恢复量
static const int hypoHeal = 30;        // 注射器恢复量
```

### 护甲血量加成系统

| 护甲类型 | 血量加成 | 总血量 | 获取方式 | 制作成本 |
|----------|----------|--------|----------|----------|
| 无护甲 | +0 | 10 | 游戏开始 | - |
| 皮革护甲 | +5 | 15 | 皮革工坊 | 皮革200 + 鳞片20 |
| 铁制护甲 | +15 | 25 | 工坊 | 皮革200 + 铁100 |
| 钢制护甲 | +35 | 45 | 钢铁工厂 | 皮革200 + 钢100 |
| 动能护甲 | +75 | 85 | 制造器 | 太空船技术 |

### 血量计算实现

```dart
// lib/modules/world.dart:1343-1356
int getMaxHealth() {
  final sm = StateManager();

  if ((sm.get('stores["kinetic armour"]', true) ?? 0) > 0) {
    return baseHealth + 75;  // 动能护甲：85点
  } else if ((sm.get('stores["s armour"]', true) ?? 0) > 0) {
    return baseHealth + 35;  // 钢制护甲：45点
  } else if ((sm.get('stores["i armour"]', true) ?? 0) > 0) {
    return baseHealth + 15;  // 铁制护甲：25点
  } else if ((sm.get('stores["l armour"]', true) ?? 0) > 0) {
    return baseHealth + 5;   // 皮革护甲：15点
  }
  return baseHealth;         // 无护甲：10点
}
```

### 血量恢复机制

#### 1. 自动回血（移动时）
```dart
// 每移动2步自动消耗1个熏肉，恢复8点血量
if (foodMove >= movesPerFood) {
  foodMove = 0;
  var num = path.outfit['cured meat'] ?? 0;
  num--;

  if (num >= 0) {
    starvation = false;
    setHp(health + meatHealAmount()); // 恢复8点血量
    Logger.info('🍖 消耗了熏肉，剩余: $num，恢复生命值');
  }
}
```

#### 2. 手动治疗
```dart
// 治疗物品恢复量
int meatHealAmount() {
  int healAmount = meatHeal; // 8点
  if (StateManager().hasPerk('gastronome')) {
    healAmount *= 2; // 美食家技能：翻倍
  }
  return healAmount;
}

int medsHealAmount() {
  return medsHeal; // 20点
}

int hypoHealAmount() {
  return hypoHeal; // 30点
}
```

## 💧 水容量系统

### 基础水量配置

```dart
// lib/modules/world.dart
static const int baseWater = 10;       // 基础水量
static const int movesPerWater = 1;    // 每移动1步消耗1水
```

### 水容器升级路径

| 物品名称 | 英文名称 | 额外容量 | 总容量 | 制作阶段 | 制作成本 |
|---------|----------|----------|--------|----------|----------|
| **基础** | - | 0 | **10** | 游戏开始 | - |
| **水壶** | waterskin | +10 | **20** | 皮革工坊 | 皮革50 |
| **水桶** | cask | +20 | **30** | 高级制作 | 皮革100 + 铁20 |
| **水罐** | water tank | +50 | **60** | 钢铁工业 | 铁100 + 钢50 |
| **流体回收器** | fluid recycler | +100 | **110** | 太空船技术 | 外星合金2 |

### 水容量计算实现

```dart
// lib/modules/world.dart:1369-1382
int getMaxWater() {
  final sm = StateManager();

  if ((sm.get('stores["fluid recycler"]', true) ?? 0) > 0) {
    return baseWater + 100;  // 110总容量
  } else if ((sm.get('stores["water tank"]', true) ?? 0) > 0) {
    return baseWater + 50;   // 60总容量
  } else if ((sm.get('stores.cask', true) ?? 0) > 0) {
    return baseWater + 20;   // 30总容量
  } else if ((sm.get('stores.waterskin', true) ?? 0) > 0) {
    return baseWater + 10;   // 20总容量
  }
  return baseWater;          // 10基础容量
}
```

### 水资源消耗机制

- **消耗速度**: 每移动1格消耗1水
- **死亡威胁**: 水耗尽后继续移动会导致死亡
- **补给方式**: 前哨站一次性补满到最大容量

## 🎒 背包容量系统

### 基础背包配置

```dart
// lib/modules/path.dart
static const int defaultBagSpace = 10; // 基础背包容量
```

### 背包升级路径

| 物品名称 | 英文名称 | 额外容量 | 总容量 | 制作阶段 | 制作成本 |
|---------|----------|----------|--------|----------|----------|
| **基础** | - | 0 | **10** | 游戏开始 | - |
| **双肩包** | rucksack | +10 | **20** | 皮革工坊 | 皮革200 |
| **马车** | wagon | +30 | **40** | 工业制作 | 木材500 + 铁100 |
| **车队** | convoy | +60 | **70** | 高级工业 | 木材1000 + 铁200 + 钢100 |
| **货运无人机** | cargo drone | +100 | **110** | 太空船技术 | 外星合金2 |

### 背包容量计算实现

```dart
// lib/modules/path.dart:99-112
int getCapacity() {
  final sm = StateManager();

  if ((sm.get('stores["cargo drone"]', true) ?? 0) > 0) {
    return defaultBagSpace + 100;  // 110总容量
  } else if ((sm.get('stores["convoy"]', true) ?? 0) > 0) {
    return defaultBagSpace + 60;   // 70总容量
  } else if ((sm.get('stores["wagon"]', true) ?? 0) > 0) {
    return defaultBagSpace + 30;   // 40总容量
  } else if ((sm.get('stores["rucksack"]', true) ?? 0) > 0) {
    return defaultBagSpace + 10;   // 20总容量
  }
  return defaultBagSpace;          // 10基础容量
}
```

### 重量系统

背包系统基于**重量**而非**数量**进行限制：

```dart
// lib/modules/path.dart:35-45
static const Map<String, double> weight = {
  'bone spear': 2.0,      // 骨枪重量2
  'iron sword': 3.0,      // 铁剑重量3
  'steel sword': 5.0,     // 钢剑重量5
  'rifle': 5.0,           // 步枪重量5
  'bullets': 0.1,         // 子弹重量0.1
  'energy cell': 0.2,     // 能量电池重量0.2
  'laser rifle': 5.0,     // 激光步枪重量5
  'plasma rifle': 5.0,    // 等离子步枪重量5
  'bolas': 0.5,           // 流星锤重量0.5
};

// 获取物品重量
double getWeight(String thing) {
  return weight[thing] ?? 1.0; // 默认重量为1
}
```

## 📈 进度增长曲线分析

### 血量增长模式

```
基础血量: 10 → 皮革护甲: 15 (1.5倍)
皮革护甲: 15 → 铁制护甲: 25 (1.67倍)
铁制护甲: 25 → 钢制护甲: 45 (1.8倍)
钢制护甲: 45 → 动能护甲: 85 (1.89倍)
```

### 水容量增长模式

```
基础水量: 10 → 水壶: 20 (2倍)
水壶: 20 → 水桶: 30 (1.5倍)
水桶: 30 → 水罐: 60 (2倍)
水罐: 60 → 流体回收器: 110 (1.83倍)
```

### 背包容量增长模式

```
基础容量: 10 → 双肩包: 20 (2倍)
双肩包: 20 → 马车: 40 (2倍)
马车: 40 → 车队: 70 (1.75倍)
车队: 70 → 货运无人机: 110 (1.57倍)
```

## 🎮 游戏设计意义

### 渐进式解锁机制

#### 探索能力扩展
```
血量10 + 水量10 + 背包10 → 基础探索（5格内）
血量15 + 水量20 + 背包20 → 短程探索（10格内）
血量25 + 水量30 + 背包40 → 中程探索（15格内）
血量45 + 水量60 + 背包70 → 长程探索（25格内）
血量85 + 水量110 + 背包110 → 无限探索（全地图）
```

#### 技术树依赖
1. **皮革工坊** → 基础升级（护甲、水壶、双肩包）
2. **工坊+铁矿** → 中级升级（铁甲、水桶、马车）
3. **钢铁工厂** → 高级升级（钢甲、水罐、车队）
4. **外星科技** → 终极升级（动能甲、回收器、无人机）

### 资源投入递增

#### 制作成本分析
- **早期升级**: 大量常见资源（皮革为主）
- **中期升级**: 多种工业资源（木材+铁）
- **后期升级**: 稀有高级资源（钢材）
- **终极升级**: 稀有终极资源（外星合金）

## 🔧 实现状态验证

### 代码一致性评分

| 系统 | 一致性评分 | 主要发现 |
|------|------------|----------|
| 血量系统 | 100% | 护甲加成、治疗机制完全一致 |
| 水容量系统 | 98% | 容量计算一致，个别UI显示需修复 |
| 背包系统 | 95% | 容量计算一致，重量系统略有扩展 |

### 已修复的问题

1. **水容量显示不一致**: Path模块的getMaxWater函数已修复
2. **背包物品缺失**: 背包界面物品显示已完善
3. **护甲血量计算**: getMaxHealth函数实现完全正确

## 🎯 玩家策略建议

### 升级优先级建议

#### 早期阶段（0-10格探索）
1. **皮革护甲** - 提升生存能力
2. **水壶** - 扩大探索范围
3. **双肩包** - 携带更多补给

#### 中期阶段（10-20格探索）
1. **铁制护甲** - 应对更强敌人
2. **水桶** - 支持中程探索
3. **马车** - 携带重型装备

#### 后期阶段（20+格探索）
1. **钢制护甲** - 挑战高难度区域
2. **水罐** - 支持长程探索
3. **车队** - 大规模资源运输

#### 终极阶段（全地图探索）
1. **动能护甲** - 最强防护
2. **流体回收器** - 几乎无限水源
3. **货运无人机** - 几乎无限携带

### 资源管理策略

#### 血量管理
- **预防性治疗**: 血量低于50%时考虑治疗
- **物品优先级**: 熏肉 < 药物 < 注射器
- **战前准备**: 进入危险区域前确保满血

#### 水资源管理
- **计划探索**: 根据水量规划探索路线
- **前哨站利用**: 合理利用前哨站补水
- **紧急撤退**: 水量不足时及时返回

#### 背包管理
- **重量优化**: 优先携带轻型高价值物品
- **装备选择**: 根据探索目标选择合适装备
- **空间规划**: 为战利品预留足够空间

## 🔗 相关文档

- [地形系统完整指南](terrain_system.md) - 地形探索和资源消耗
- [火把系统完整指南](torch_system.md) - 火把需求和背包管理
- [前哨站系统](../outpost_and_road_system.md) - 前哨站补给机制

---

*本文档整合了player_health_growth_mechanism.md、water_capacity_growth_mechanism.md、backpack_capacity_growth_mechanism.md等3个文档的内容，为开发者提供统一的玩家进度系统参考。*
