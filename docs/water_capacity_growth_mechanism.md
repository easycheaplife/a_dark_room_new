# A Dark Room 水容量增长机制详解

## 📋 概述

本文档详细分析了A Dark Room游戏中水容量的增长机制，包括基础水量、升级物品、制作条件和技术实现等核心系统。

## 💧 基础水资源系统

### 核心常量

```javascript
// 原游戏常量定义
BASE_WATER: 10,           // 基础水量
MOVES_PER_WATER: 1,       // 每移动1步消耗1水
```

### 水资源消耗机制

- **消耗速度**: 每移动1格消耗1水
- **死亡威胁**: 水耗尽后继续移动会导致死亡
- **补给方式**: 前哨站一次性补满到最大容量

## 🎒 水容量升级系统

### 升级路径表

| 物品名称 | 英文名称 | 额外容量 | 总容量 | 制作阶段 |
|---------|----------|----------|--------|----------|
| **基础** | - | 0 | **10** | 游戏开始 |
| **水壶** | waterskin | +10 | **20** | 皮革工坊阶段 |
| **水桶** | cask | +20 | **30** | 高级制作阶段 |
| **水罐** | water tank | +50 | **60** | 钢铁工业阶段 |
| **流体回收器** | fluid recycler | +100 | **110** | 太空船技术阶段 |

### 容量计算逻辑

```javascript
// 原游戏实现
getMaxWater: function() {
    if($SM.get('stores["fluid recycler"]', true) > 0) {
        return World.BASE_WATER + 100;  // 110总容量
    } else if($SM.get('stores["water tank"]', true) > 0) {
        return World.BASE_WATER + 50;   // 60总容量
    } else if($SM.get('stores.cask', true) > 0) {
        return World.BASE_WATER + 20;   // 30总容量
    } else if($SM.get('stores.waterskin', true) > 0) {
        return World.BASE_WATER + 10;   // 20总容量
    }
    return World.BASE_WATER;            // 10基础容量
}
```

## 🔧 制作系统详解

### 1. 水壶 (Waterskin)

#### 制作条件
```javascript
'waterskin': {
    name: _('waterskin'),
    type: 'upgrade',
    maximum: 1,                    // 只能制作1个
    buildMsg: _('this waterskin\'ll hold a bit of water, at least'),
    cost: function() {
        return {
            'leather': 50          // 需要50皮革
        };
    }
}
```

#### 解锁要求
- **建筑**: 皮革工坊 (Tannery)
- **资源**: 50皮革
- **阶段**: 早期探索阶段

### 2. 水桶 (Cask)

#### 制作条件
```javascript
'cask': {
    name: _('cask'),
    type: 'upgrade',
    maximum: 1,
    buildMsg: _('the cask holds enough water for longer expeditions'),
    cost: function() {
        return {
            'leather': 100,        // 需要100皮革
            'iron': 20             // 需要20铁
        };
    }
}
```

#### 解锁要求
- **建筑**: 皮革工坊 + 铁矿开采
- **资源**: 100皮革 + 20铁
- **阶段**: 中期发展阶段

### 3. 水罐 (Water Tank)

#### 制作条件
```javascript
'water tank': {
    name: _('water tank'),
    type: 'upgrade',
    maximum: 1,
    buildMsg: _('never go thirsty again'),
    cost: function() {
        return {
            'iron': 100,           // 需要100铁
            'steel': 50            // 需要50钢
        };
    }
}
```

#### 解锁要求
- **建筑**: 钢铁工厂 (Steelworks)
- **资源**: 100铁 + 50钢
- **阶段**: 后期工业阶段

### 4. 流体回收器 (Fluid Recycler)

#### 制作条件
```javascript
'fluid recycler': {
    name: _('fluid recycler'),
    type: 'upgrade',
    maximum: 1,
    buildMsg: _('water out, water in. waste not, want not.'),
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

## 🎮 游戏设计意义

### 渐进式解锁机制

#### 探索范围扩展
```
基础水量(10) → 探索半径 ~10格
水壶(20)     → 探索半径 ~20格  
水桶(30)     → 探索半径 ~30格
水罐(60)     → 探索半径 ~60格
流体回收器(110) → 几乎无限探索
```

#### 技术树依赖
1. **皮革工坊** → 水壶 (基础升级)
2. **铁矿开采** → 水桶 (中级升级)  
3. **钢铁工业** → 水罐 (高级升级)
4. **外星科技** → 流体回收器 (终极升级)

### 资源投入递增

#### 制作成本分析
- **水壶**: 50皮革 (早期易获得)
- **水桶**: 100皮革 + 20铁 (中期资源)
- **水罐**: 100铁 + 50钢 (后期工业资源)
- **流体回收器**: 2外星合金 (稀有终极资源)

#### 收益递增设计
- **水壶**: +10容量 (100%提升)
- **水桶**: +20容量 (200%提升)
- **水罐**: +50容量 (500%提升)
- **流体回收器**: +100容量 (1000%提升)

## 🔧 Flutter实现状态

### 已实现功能

✅ **基础水量系统**
```dart
static const int baseWater = 10;
```

✅ **容量计算函数**
```dart
int getMaxWater() {
  final sm = StateManager();
  
  if ((sm.get('stores["fluid recycler"]', true) ?? 0) > 0) {
    return baseWater + 100;
  } else if ((sm.get('stores["water tank"]', true) ?? 0) > 0) {
    return baseWater + 50;
  } else if ((sm.get('stores.cask', true) ?? 0) > 0) {
    return baseWater + 20;
  } else if ((sm.get('stores.waterskin', true) ?? 0) > 0) {
    return baseWater + 10;
  }
  return baseWater;
}
```

✅ **制作物品配置**
```dart
// lib/modules/room.dart
'waterskin': {
  'cost': (StateManager sm) => {'leather': 50},
},
'cask': {
  'cost': (StateManager sm) => {'leather': 100, 'iron': 20},
},
'water tank': {
  'cost': (StateManager sm) => {'iron': 100, 'steel': 50},
},

// lib/modules/fabricator.dart  
'fluid recycler': {
  'cost': {'alien alloy': 2},
}
```

### 实现文件对照

| 功能模块 | 原游戏文件 | Flutter文件 |
|---------|-----------|-------------|
| 水量计算 | `world.js` | `lib/modules/world.dart` |
| 基础制作 | `room.js` | `lib/modules/room.dart` |
| 高级制作 | `fabricator.js` | `lib/modules/fabricator.dart` |

## 📊 容量增长曲线分析

### 线性增长阶段 (早期)
```
基础: 10 → 水壶: 20 (增长100%)
```

### 加速增长阶段 (中期)
```
水壶: 20 → 水桶: 30 (增长50%)
水桶: 30 → 水罐: 60 (增长100%)
```

### 指数增长阶段 (后期)
```
水罐: 60 → 流体回收器: 110 (增长83%)
```

### 探索能力对比

| 水容量 | 单程探索距离 | 往返探索距离 | 适用阶段 |
|--------|-------------|-------------|----------|
| 10 | 10格 | 5格 | 村庄周边 |
| 20 | 20格 | 10格 | 近距离地标 |
| 30 | 30格 | 15格 | 中距离探索 |
| 60 | 60格 | 30格 | 远距离探索 |
| 110 | 110格 | 55格 | 地图边缘 |

## 💡 设计智慧

### 心理激励机制

#### 明确的升级路径
- 每个升级都有**显著的容量提升**
- 制作成本与收益成**合理比例**
- 解锁条件与**游戏进度同步**

#### 探索欲望驱动
- 水容量直接限制**探索范围**
- 更大容量解锁**新的地标**
- 形成"升级→探索→资源→升级"的**正反馈循环**

### 平衡性设计

#### 资源稀缺性递增
- 早期升级使用**常见资源** (皮革)
- 中期升级需要**工业资源** (铁、钢)
- 后期升级依赖**稀有资源** (外星合金)

#### 收益递减控制
- 虽然绝对容量大幅增长
- 但相对提升比例逐渐降低
- 防止后期探索过于容易

## 🔗 相关文档

- [地图难度设计](map_difficulty_design.md)
- [前哨站产生机制](outpost_generation_mechanism.md)
- [Flutter实现指南](flutter_implementation_guide.md)

---

*本文档基于A Dark Room原游戏代码分析编写，为Flutter版本实现提供参考*
