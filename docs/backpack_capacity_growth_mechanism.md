# A Dark Room 背包容量增长机制详解

## 📋 概述

本文档详细分析了A Dark Room游戏中背包容量的增长机制，包括基础容量、升级物品、重量系统和技术实现等核心系统。

## 🎒 基础背包系统

### 核心常量

```javascript
// 原游戏常量定义
DEFAULT_BAG_SPACE: 10,        // 基础背包容量
```

### 重量系统

背包系统基于**重量**而非**数量**进行限制：

```javascript
// 物品重量配置
Weight: {
    'bone spear': 2,          // 骨枪重量2
    'iron sword': 3,          // 铁剑重量3
    'steel sword': 5,         // 钢剑重量5
    'rifle': 5,               // 步枪重量5
    'bullets': 0.1,           // 子弹重量0.1
    'energy cell': 0.2,       // 能量电池重量0.2
    'laser rifle': 5,         // 激光步枪重量5
    'bolas': 0.5,             // 流星锤重量0.5
    // 其他物品默认重量为1
}
```

## 📈 背包容量升级系统

### 升级路径表

| 物品名称 | 英文名称 | 额外容量 | 总容量 | 制作阶段 |
|---------|----------|----------|--------|----------|
| **基础** | - | 0 | **10** | 游戏开始 |
| **双肩包** | rucksack | +10 | **20** | 皮革工坊阶段 |
| **马车** | wagon | +30 | **40** | 工业制作阶段 |
| **车队** | convoy | +60 | **70** | 高级工业阶段 |
| **货运无人机** | cargo drone | +100 | **110** | 太空船技术阶段 |

### 容量计算逻辑

```javascript
// 原游戏实现
getCapacity: function() {
    if($SM.get('stores["cargo drone"]', true) > 0) {
        return Path.DEFAULT_BAG_SPACE + 100;  // 110总容量
    } else if($SM.get('stores.convoy', true) > 0) {
        return Path.DEFAULT_BAG_SPACE + 60;   // 70总容量
    } else if($SM.get('stores.wagon', true) > 0) {
        return Path.DEFAULT_BAG_SPACE + 30;   // 40总容量
    } else if($SM.get('stores.rucksack', true) > 0) {
        return Path.DEFAULT_BAG_SPACE + 10;   // 20总容量
    }
    return Path.DEFAULT_BAG_SPACE;            // 10基础容量
}
```

## 🔧 制作系统详解

### 1. 双肩包 (Rucksack)

#### 制作条件
```javascript
'rucksack': {
    name: _('rucksack'),
    type: 'upgrade',
    maximum: 1,                    // 只能制作1个
    buildMsg: _('carrying more means longer expeditions to the wilds'),
    cost: function() {
        return {
            'leather': 200         // 需要200皮革
        };
    }
}
```

#### 解锁要求
- **建筑**: 皮革工坊 (Tannery)
- **资源**: 200皮革
- **阶段**: 早期探索阶段
- **容量提升**: +10 (100%提升)

### 2. 马车 (Wagon)

#### 制作条件
```javascript
'wagon': {
    name: _('wagon'),
    type: 'upgrade',
    maximum: 1,
    buildMsg: _('the wagon can carry a lot of supplies'),
    cost: function() {
        return {
            'wood': 500,           // 需要500木材
            'iron': 100            // 需要100铁
        };
    }
}
```

#### 解锁要求
- **建筑**: 工坊 (Workshop) + 铁矿开采
- **资源**: 500木材 + 100铁
- **阶段**: 中期发展阶段
- **容量提升**: +30 (300%提升)

### 3. 车队 (Convoy)

#### 制作条件
```javascript
'convoy': {
    name: _('convoy'),
    type: 'upgrade',
    maximum: 1,
    buildMsg: _('the convoy can haul mostly everything'),
    cost: function() {
        return {
            'wood': 1000,          // 需要1000木材
            'iron': 200,           // 需要200铁
            'steel': 100           // 需要100钢
        };
    }
}
```

#### 解锁要求
- **建筑**: 钢铁工厂 (Steelworks)
- **资源**: 1000木材 + 200铁 + 100钢
- **阶段**: 后期工业阶段
- **容量提升**: +60 (600%提升)

### 4. 货运无人机 (Cargo Drone)

#### 制作条件
```javascript
'cargo drone': {
    name: _('cargo drone'),
    type: 'upgrade',
    maximum: 1,
    buildMsg: _('the workhorse of the wanderer fleet.'),
    cost: function() {
        return {
            'alien alloy': 2       // 需要2外星合金
        };
    }
}
```

#### 解锁要求
- **建筑**: 制造器 (Fabricator)
- **资源**: 2外星合金
- **阶段**: 终极科技阶段
- **容量提升**: +100 (1000%提升)

## ⚖️ 重量系统详解

### 物品分类与重量

#### 轻型物品 (重量 < 1)
- **子弹**: 0.1 (可大量携带)
- **能量电池**: 0.2 (可大量携带)
- **流星锤**: 0.5 (中等重量)

#### 标准物品 (重量 = 1)
- **大部分资源**: 木材、肉类、皮革等
- **消耗品**: 药物、火把等
- **默认重量**: 未特别定义的物品

#### 重型物品 (重量 > 1)
- **骨枪**: 2 (早期武器)
- **铁剑**: 3 (中期武器)
- **钢剑**: 5 (高级武器)
- **步枪**: 5 (远程武器)
- **激光步枪**: 5 (高科技武器)

### 空间计算示例

```javascript
// 计算剩余空间
getFreeSpace: function() {
    var num = 0;
    if(Path.outfit) {
        for(var k in Path.outfit) {
            var n = Path.outfit[k];
            if(typeof n != 'number') {
                Path.outfit[k] = n = 0;
            }
            num += n * Path.getWeight(k);  // 数量 × 重量
        }
    }
    return Path.getCapacity() - num;
}
```

## 🎮 游戏设计意义

### 渐进式解锁机制

#### 探索能力扩展
```
基础容量(10) → 携带基础装备
双肩包(20)     → 携带更多补给
马车(40)     → 长距离探索
车队(70)     → 大规模探索
货运无人机(110) → 几乎无限携带
```

#### 技术树依赖
1. **皮革工坊** → 双肩包 (基础升级)
2. **工坊+铁矿** → 马车 (中级升级)
3. **钢铁工厂** → 车队 (高级升级)
4. **外星科技** → 货运无人机 (终极升级)

### 资源投入递增

#### 制作成本分析
- **双肩包**: 200皮革 (早期大量资源)
- **马车**: 500木材 + 100铁 (中期工业资源)
- **车队**: 1000木材 + 200铁 + 100钢 (后期大量资源)
- **货运无人机**: 2外星合金 (稀有终极资源)

#### 收益递增设计
- **双肩包**: +10容量 (100%提升)
- **马车**: +30容量 (300%提升)
- **车队**: +60容量 (600%提升)
- **货运无人机**: +100容量 (1000%提升)

## 🔧 Flutter实现状态

### 已实现功能

✅ **基础容量系统**
```dart
static const int defaultBagSpace = 10;
```

✅ **重量系统**
```dart
static const Map<String, double> weight = {
  'bone spear': 2.0,
  'iron sword': 3.0,
  'steel sword': 5.0,
  'rifle': 5.0,
  'bullets': 0.1,
  'energy cell': 0.2,
  'laser rifle': 5.0,
  'bolas': 0.5,
};
```

✅ **容量计算函数**
```dart
int getCapacity() {
  final sm = StateManager();
  
  if ((sm.get('stores["cargo drone"]', true) ?? 0) > 0) {
    return defaultBagSpace + 100;
  } else if ((sm.get('stores.convoy', true) ?? 0) > 0) {
    return defaultBagSpace + 60;
  } else if ((sm.get('stores.wagon', true) ?? 0) > 0) {
    return defaultBagSpace + 30;
  } else if ((sm.get('stores.rucksack', true) ?? 0) > 0) {
    return defaultBagSpace + 10;
  }
  return defaultBagSpace;
}
```

✅ **制作物品配置**
```dart
// lib/modules/room.dart
'rucksack': {
  'cost': (StateManager sm) => {'leather': 200},
},
'wagon': {
  'cost': (StateManager sm) => {'wood': 500, 'iron': 100},
},
'convoy': {
  'cost': (StateManager sm) => {'wood': 1000, 'iron': 200, 'steel': 100},
},

// lib/modules/fabricator.dart
'cargo drone': {
  'cost': {'alien alloy': 2},
}
```

### 实现文件对照

| 功能模块 | 原游戏文件 | Flutter文件 |
|---------|-----------|-------------|
| 容量计算 | `path.js` | `lib/modules/path.dart` |
| 基础制作 | `room.js` | `lib/modules/room.dart` |
| 高级制作 | `fabricator.js` | `lib/modules/fabricator.dart` |
| UI显示 | `path.js` | `lib/screens/path_screen.dart` |

## 📊 容量增长曲线分析

### 指数增长模式

#### 容量增长倍数
```
基础: 10 → 双肩包: 20 (2倍)
双肩包: 20 → 马车: 40 (2倍)
马车: 40 → 车队: 70 (1.75倍)
车队: 70 → 货运无人机: 110 (1.57倍)
```

#### 携带能力对比

| 容量 | 可携带重型武器 | 可携带子弹 | 适用阶段 |
|------|---------------|------------|----------|
| 10 | 2把钢剑 | 100发 | 基础探索 |
| 20 | 4把钢剑 | 200发 | 短程探索 |
| 40 | 8把钢剑 | 400发 | 中程探索 |
| 70 | 14把钢剑 | 700发 | 长程探索 |
| 110 | 22把钢剑 | 1100发 | 无限探索 |

## 💡 设计智慧

### 平衡性机制

#### 重量限制的意义
- **防止囤积**: 不能无限携带所有物品
- **策略选择**: 必须选择携带哪些装备
- **风险管理**: 重武器占用更多空间

#### 升级成本递增
- **早期**: 大量常见资源 (200皮革)
- **中期**: 多种工业资源 (木材+铁)
- **后期**: 稀有高级资源 (外星合金)

### 心理激励机制

#### 明确的收益
- 每次升级都有**显著的容量提升**
- 解锁**新的探索可能性**
- 形成"升级→探索→资源→升级"的**正反馈循环**

#### 技术进步感
- 从**双肩包**到**马车**到**车队**再到**无人机**
- 体现了从**原始**到**工业**到**科技**的发展历程
- 每个阶段都有**质的飞跃**

## 🔗 相关文档

- [水容量增长机制](water_capacity_growth_mechanism.md)
- [地图难度设计](map_difficulty_design.md)
- [Flutter实现指南](flutter_implementation_guide.md)

---

*本文档基于A Dark Room原游戏代码分析编写，为Flutter版本实现提供参考*
