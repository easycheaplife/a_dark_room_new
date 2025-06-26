# A Dark Room 地图难度设计机制详解

## 📋 概述

本文档详细分析了A Dark Room游戏中地图难度的设计机制，包括距离分级、敌人强度、装备需求和地形影响等核心系统。

## 🎯 核心难度机制

### 距离分级系统

游戏采用**曼哈顿距离**（Manhattan Distance）作为难度的核心指标：

```javascript
// 距离计算公式
getDistance: function(from, to) {
    from = from || World.curPos;
    to = to || World.VILLAGE_POS;
    return Math.abs(from[0] - to[0]) + Math.abs(from[1] - to[1]);
}
```

### 三层难度分级

#### 🟢 Tier 1: 安全区域 (距离 ≤ 10)
- **敌人伤害**: 1-3点
- **敌人血量**: 4-6点
- **装备需求**: 基础武器即可
- **代表敌人**: 咆哮野兽、瘦弱男人、奇怪鸟类

#### 🟡 Tier 2: 危险区域 (距离 10-20)
- **敌人伤害**: 3-5点
- **敌人血量**: 20-30点
- **装备需求**: 建议铁制装备
- **代表敌人**: 颤抖男人、食人兽、拾荒者、巨蜥

#### 🔴 Tier 3: 极危区域 (距离 > 20)
- **敌人伤害**: 6-15点
- **敌人血量**: 30-50点
- **装备需求**: 必须钢制装备
- **代表敌人**: 野性恐兽、士兵、狙击手

## 🛡️ 装备需求系统

### 危险检测机制

```javascript
checkDanger: function() {
    if(!World.danger) {
        // 第一道防线：距离8格需要铁甲
        if($SM.get('stores["i armour"]', true) === 0 && World.getDistance() >= 8) {
            World.danger = true;
            return true;
        }
        // 第二道防线：距离18格需要钢甲
        if($SM.get('stores["s armour"]', true) === 0 && World.getDistance() >= 18) {
            World.danger = true;
            return true;
        }
    }
    return false;
}
```

### 装备分级要求

#### 🥉 基础装备 (距离 0-8)
- **武器**: 拳头、骨枪
- **防具**: 无需防具
- **生存**: 基础食物和水

#### 🥈 中级装备 (距离 8-18)
- **武器**: 铁剑、步枪
- **防具**: **铁甲 (必需)**
- **生存**: 充足的食物和水

#### 🥇 高级装备 (距离 18+)
- **武器**: 钢剑、激光步枪
- **防具**: **钢甲 (必需)**
- **生存**: 大量补给品

## 🌍 地形影响系统

### 地形类型与敌人分布

#### 🌲 森林 (Forest - ';')
- **Tier 1**: 咆哮野兽 (伤害1, 血量5)
- **Tier 2**: 食人兽 (伤害3, 血量25)
- **Tier 3**: 野性恐兽 (伤害6, 血量45)

#### 🌾 田野 (Field - ',')
- **Tier 1**: 奇怪鸟类 (伤害3, 血量4)
- **Tier 2**: 巨蜥 (伤害5, 血量20)
- **Tier 3**: 狙击手 (伤害15, 血量30)

#### 🏜️ 荒地 (Barrens - '.')
- **Tier 1**: 瘦弱男人 (伤害2, 血量6)
- **Tier 2**: 颤抖男人 (伤害5, 血量20)、拾荒者 (伤害4, 血量30)
- **Tier 3**: 士兵 (伤害8, 血量50)

## 🏛️ 地标难度分布

### 按距离分布的地标

```javascript
// 地标的最小和最大出现距离
World.LANDMARKS = {
    IRON_MINE:    { minRadius: 5,  maxRadius: 5 },   // 铁矿
    CAVE:         { minRadius: 3,  maxRadius: 10 },  // 洞穴
    COAL_MINE:    { minRadius: 10, maxRadius: 10 },  // 煤矿
    TOWN:         { minRadius: 10, maxRadius: 20 },  // 废弃小镇
    BOREHOLE:     { minRadius: 15, maxRadius: 45 },  // 钻孔
    BATTLEFIELD:  { minRadius: 18, maxRadius: 45 },  // 战场
    SULPHUR_MINE: { minRadius: 20, maxRadius: 20 },  // 硫磺矿
    CITY:         { minRadius: 20, maxRadius: 45 },  // 废弃城市
    SHIP:         { minRadius: 28, maxRadius: 28 },  // 坠毁飞船
    EXECUTIONER:  { minRadius: 28, maxRadius: 28 }   // 执行者
};
```

### 地标难度递增

#### 🟢 初级地标 (距离 3-10)
- **洞穴**: 基础探索，获得初级资源
- **铁矿**: 清理野兽，解锁铁矿开采

#### 🟡 中级地标 (距离 10-20)
- **煤矿**: 对抗敌对势力
- **废弃小镇**: 复杂的拾荒者战斗
- **钻孔**: 神秘的地下结构

#### 🔴 高级地标 (距离 18-28)
- **战场**: 大规模战斗遗迹
- **硫磺矿**: 军事封锁区域
- **废弃城市**: 最复杂的城市探索
- **坠毁飞船**: 终极目标
- **执行者**: 最终Boss

## ⚔️ 战斗系统难度

### 战斗概率机制

```javascript
checkFight: function() {
    World.fightMove++;
    if(World.fightMove > World.FIGHT_DELAY) {  // 至少3次移动后
        var chance = World.FIGHT_CHANCE;       // 基础20%概率
        chance *= $SM.hasPerk('stealthy') ? 0.5 : 1;  // 潜行技能减半
        if(Math.random() < chance) {
            World.fightMove = 0;
            Events.triggerFight();
        }
    }
}
```

### 敌人强度递增表

| 距离范围 | 敌人类型 | 伤害 | 血量 | 特殊能力 |
|---------|---------|------|------|----------|
| 0-10    | 野兽类   | 1-3  | 4-6  | 无 |
| 10-20   | 人形敌人 | 3-5  | 20-30| 基础战术 |
| 20+     | 军事单位 | 6-15 | 30-50| 远程攻击 |

## 🎮 游戏设计意义

### 渐进式难度曲线

1. **新手友好**: 村庄附近相对安全
2. **装备驱动**: 必须升级装备才能探索更远
3. **风险回报**: 距离越远，奖励越丰富
4. **心理压力**: 距离警告创造紧张感

### 资源管理压力

#### 水资源限制
- **基础水量**: 10单位
- **消耗速度**: 每移动1格消耗1水
- **补给方式**: 前哨站一次性补满

#### 食物消耗
- **消耗速度**: 每移动2格消耗1食物
- **饥饿惩罚**: 影响战斗能力

### 探索激励机制

#### 距离奖励递增
- **近距离**: 基础资源 (木材、肉类)
- **中距离**: 制作材料 (铁、煤炭)
- **远距离**: 稀有物品 (钢材、能量电池)

## 🔧 Flutter实现状态

### 已实现功能
✅ 距离计算系统  
✅ 三层难度分级  
✅ 装备需求检测  
✅ 地形敌人分布  
✅ 战斗概率系统  
✅ 地标距离分布  

### 实现文件
- `lib/modules/world.dart` - 核心难度逻辑
- `lib/modules/events.dart` - 敌人遭遇系统
- `lib/modules/setpieces.dart` - 地标事件

### 关键常量对照

| 原游戏常量 | Flutter实现 | 说明 |
|-----------|-------------|------|
| `RADIUS: 30` | `radius = 30` | 地图半径 |
| `FIGHT_CHANCE: 0.20` | `fightChance = 0.20` | 战斗概率 |
| `FIGHT_DELAY: 3` | `fightDelay = 3` | 战斗间隔 |
| `LIGHT_RADIUS: 2` | `lightRadius = 2` | 视野范围 |

## 📝 开发注意事项

### 平衡性调整
1. 确保敌人强度与距离成正比
2. 装备需求与探索收益匹配
3. 水资源消耗与补给点分布平衡

### 测试要点
1. 验证距离计算的准确性
2. 测试装备需求警告系统
3. 检查敌人出现的距离限制
4. 确认地标分布的合理性

## 🎲 概率与随机性设计

### 地形生成概率

```javascript
// 地形出现概率
World.TILE_PROBS = {
    FOREST: 0.15,   // 森林 15%
    FIELD: 0.35,    // 田野 35%
    BARRENS: 0.5    // 荒地 50%
};
```

### 粘性系统 (Stickiness)

```javascript
// 相邻地形影响概率
STICKINESS: 0.5  // 50%概率继承相邻地形
```

这个系统确保：
- 地形不会过于分散
- 形成自然的地形群落
- 增加地图的真实感

### 战斗触发概率

#### 基础概率
- **战斗概率**: 20% (每次移动后检查)
- **冷却时间**: 至少3次移动
- **潜行加成**: 有潜行技能时概率减半

#### 概率计算示例
```dart
// Flutter实现
bool checkFight() {
  fightMove++;
  if (fightMove > fightDelay) {
    double chance = fightChance;  // 0.20
    if (hasStealthyPerk) chance *= 0.5;  // 0.10

    if (Random().nextDouble() < chance) {
      fightMove = 0;
      return true;  // 触发战斗
    }
  }
  return false;
}
```

## 🗺️ 地图生成算法

### 螺旋生成模式

```javascript
// 从村庄中心螺旋向外生成
for(var r = 1; r <= World.RADIUS; r++) {
    for(var t = 0; t < r * 8; t++) {
        var x, y;
        if(t < 2 * r) {
            x = World.RADIUS - r + t;
            y = World.RADIUS - r;
        } else if(t < 4 * r) {
            x = World.RADIUS + r;
            y = World.RADIUS - (3 * r) + t;
        } else if(t < 6 * r) {
            x = World.RADIUS + (5 * r) - t;
            y = World.RADIUS + r;
        } else {
            x = World.RADIUS - r;
            y = World.RADIUS + (7 * r) - t;
        }
        map[x][y] = World.chooseTile(x, y, map);
    }
}
```

### 地标放置算法

```javascript
placeLandmark: function(minRadius, maxRadius, landmark, map) {
    var x = World.RADIUS, y = World.RADIUS;
    while(!World.isTerrain(map[x][y])) {
        var r = Math.floor(Math.random() * (maxRadius - minRadius)) + minRadius;
        var xDist = Math.floor(Math.random() * r);
        var yDist = r - xDist;
        if(Math.random() < 0.5) xDist = -xDist;
        if(Math.random() < 0.5) yDist = -yDist;
        x = World.RADIUS + xDist;
        y = World.RADIUS + yDist;
    }
    map[x][y] = landmark;
    return [x, y];
}
```

## 🔍 视野与探索系统

### 视野范围计算

```javascript
// 基础视野半径
LIGHT_RADIUS: 2

// 侦察技能加成
lightMap: function(x, y, mask) {
    var r = World.LIGHT_RADIUS;
    r *= $SM.hasPerk('scout') ? 2 : 1;  // 侦察技能翻倍视野
    World.uncoverMap(x, y, r, mask);
    return mask;
}
```

### 地图遮罩系统

#### 菱形视野算法
```javascript
uncoverMap: function(x, y, r, mask) {
    mask[x][y] = true;
    for(var i = -r; i <= r; i++) {
        for(var j = -r + Math.abs(i); j <= r - Math.abs(i); j++) {
            if(y + j >= 0 && y + j <= World.RADIUS * 2 &&
                x + i <= World.RADIUS * 2 && x + i >= 0) {
                mask[x+i][y+j] = true;
            }
        }
    }
}
```

## 💊 生存系统设计

### 生命值系统

#### 基础数值
- **基础生命值**: 10点
- **最大生命值**: 随装备和技能提升
- **治疗物品**:
  - 肉类: 恢复8点
  - 药物: 恢复20点
  - 注射器: 恢复30点

#### 伤害计算
```javascript
// 敌人攻击伤害
damage = enemy.damage;  // 基础伤害
// 护甲减免（暂未实现）
// 技能加成（暂未实现）
```

### 资源消耗机制

#### 水资源
- **基础容量**: 10单位
- **消耗速度**: 每移动1格消耗1水
- **死亡威胁**: 水耗尽会导致死亡
- **补给方式**: 前哨站一次性补满

#### 食物资源
- **消耗速度**: 每移动2格消耗1食物
- **饥饿效果**: 影响战斗表现
- **获取方式**: 狩猎、探索、交易

## 🎯 技能系统影响

### 已知技能效果

#### 潜行 (Stealthy)
- **效果**: 战斗概率减半
- **适用**: 所有地形的随机遭遇
- **价值**: 大幅提升生存能力

#### 侦察 (Scout)
- **效果**: 视野范围翻倍
- **适用**: 地图探索
- **价值**: 更快发现地标和资源

#### 拳击手 (Boxer)
- **效果**: 徒手伤害翻倍
- **适用**: 使用拳头战斗时
- **价值**: 早期战斗能力提升

## 📊 难度曲线分析

### 指数增长模式

#### 敌人强度增长
```
距离 0-10:  伤害 1-3,  血量 4-6   (线性增长)
距离 10-20: 伤害 3-5,  血量 20-30 (跳跃增长)
距离 20+:   伤害 6-15, 血量 30-50 (指数增长)
```

#### 装备需求门槛
```
距离 0-8:   无装备要求
距离 8-18:  必须铁甲 (硬性门槛)
距离 18+:   必须钢甲 (硬性门槛)
```

### 心理压力设计

#### 警告系统
- **第一次警告**: 距离8格无铁甲
- **第二次警告**: 距离18格无钢甲
- **持续提醒**: 每次移动都会检查

#### 死亡威胁
- **水资源耗尽**: 立即死亡
- **战斗失败**: 生命值归零
- **装备不足**: 大幅增加死亡风险

## 🔗 相关文档链接

- [前哨站产生机制](outpost_generation_mechanism.md)
- [地标事件模式](landmark_event_patterns.md)
- [Flutter实现指南](flutter_implementation_guide.md)
- [地图设计分析](a_dark_room_map_design_analysis.md)

---

*本文档基于A Dark Room原游戏代码分析编写，为Flutter版本实现提供参考*
