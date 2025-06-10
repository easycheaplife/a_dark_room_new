# A Dark Room 地图设计机制深度分析

## 概述

A Dark Room 是一个基于文本的生存游戏，其地图设计巧妙地通过**资源限制**、**渐进式探索**和**难度递增**创造了引人入胜的游戏体验。本文档详细分析了游戏的核心设计机制。

## 1. 水资源限制系统

### 1.1 基础配置

```javascript
// 核心常量定义
BASE_WATER: 10,           // 基础水量
MOVES_PER_WATER: 1,       // 每移动1步消耗1水
MOVES_PER_FOOD: 2,        // 每移动2步消耗1食物
```

### 1.2 水容量升级系统

游戏通过制作系统提供水容量升级路径：

| 物品 | 额外容量 | 总容量 | 解锁条件 |
|------|----------|--------|----------|
| 基础 | 0 | 10 | 游戏开始 |
| 水袋 (waterskin) | +10 | 20 | 皮革工坊 |
| 水桶 (cask) | +20 | 30 | 高级制作 |
| 水箱 (water tank) | +50 | 60 | 工厂制作 |
| 流体回收器 (fluid recycler) | +100 | 110 | 太空船技术 |

### 1.3 水资源消耗机制

```javascript
useSupplies: function() {
    World.waterMove++;
    
    // 检查是否需要消耗水
    var movesPerWater = World.MOVES_PER_WATER;
    movesPerWater *= $SM.hasPerk('desert rat') ? 2 : 1;  // 沙漠鼠技能减半消耗
    
    if(World.waterMove >= movesPerWater) {
        World.waterMove = 0;
        var water = World.water;
        water--;  // 消耗1水
        
        if(water === 0) {
            // 水即将耗尽警告
            Notifications.notify(World, _('there is no more water'));
        } else if(water < 0) {
            // 脱水状态
            water = 0;
            if(!World.thirst) {
                Notifications.notify(World, _('the thirst becomes unbearable'));
                World.thirst = true;
            } else {
                // 脱水伤害：每步扣1血
                World.setHp(World.health - 1);
                if(World.health <= 0) {
                    World.die();  // 脱水死亡
                }
            }
        }
        World.setWater(water);
    }
}
```

### 1.4 水资源补充机制

#### 前哨站系统
```javascript
useOutpost: function() {
    Notifications.notify(null, _('water replenished'));
    World.setWater(World.getMaxWater());  // 补满水
    // 标记此前哨站已使用（一次性）
    World.usedOutposts[World.curPos[0] + ',' + World.curPos[1]] = true;
}
```

#### 房子事件
- 25%概率：找到药物
- 25%概率：找到补给品 + **补满水**
- 50%概率：遭遇敌人战斗

## 2. 渐进式探索机制

### 2.1 视野系统

```javascript
LIGHT_RADIUS: 2,  // 玩家周围2格的视野半径
```

- **迷雾战争**：玩家只能看到周围2格范围
- **逐步揭开**：移动时会点亮新区域
- **永久记忆**：已探索区域永久可见

### 2.2 地图遮罩系统

```javascript
// 初始化：所有区域被遮罩
mask: World.newMask()  // 61x61的false数组

// 移动时点亮周围区域
lightMap: function(x, y, mask) {
    for(var i = x - World.LIGHT_RADIUS; i <= x + World.LIGHT_RADIUS; i++) {
        for(var j = y - World.LIGHT_RADIUS; j <= y + World.LIGHT_RADIUS; j++) {
            if(i >= 0 && i < mask.length && j >= 0 && j < mask[0].length) {
                mask[i][j] = true;  // 点亮此区域
            }
        }
    }
}
```

### 2.3 地标距离分布

地标按距离村庄的远近精心分布，形成自然的探索节奏：

| 地标类型 | 距离范围 | 数量 | 主要奖励 |
|----------|----------|------|----------|
| 铁矿 (Iron Mine) | 5格 | 1个 | 解锁铁矿开采 |
| 洞穴 (Cave) | 3-10格 | 5个 | 毛皮、牙齿、武器 |
| 房子 (House) | 0-45格 | 10个 | 补给品、水、药物 |
| 煤矿 (Coal Mine) | 10格 | 1个 | 解锁煤矿开采 |
| 小镇 (Town) | 10-20格 | 10个 | 大量资源 |
| 硫磺矿 (Sulphur Mine) | 20格 | 1个 | 解锁硫磺开采 |
| 城市 (City) | 20-45格 | 20个 | 高级资源 |
| 钻孔 (Borehole) | 15-45格 | 10个 | 外星合金 |
| 战场 (Battlefield) | 18-45格 | 5个 | 武器装备 |
| 沼泽 (Swamp) | 15-45格 | 1个 | 特殊技能 |
| 星舰 (Ship) | 28格 | 1个 | 游戏终极目标 |
| 执行者 (Executioner) | 28格 | 1个 | 最终Boss |

## 3. 难度递增系统

### 3.1 基于距离的危险等级

```javascript
checkDanger: function() {
    if(!World.danger) {
        // 第一道防线：距离8格开始危险（需要铁甲）
        if($SM.get('stores["i armour"]', true) === 0 && World.getDistance() >= 8) {
            World.danger = true;
            Notifications.notify(World, _('dangerous to be this far from the village without proper protection'));
            return true;
        }
        // 第二道防线：距离18格极度危险（需要钢甲）
        if($SM.get('stores["s armour"]', true) === 0 && World.getDistance() >= 18) {
            World.danger = true;
            return true;
        }
    }
}
```

### 3.2 战斗概率系统

```javascript
FIGHT_CHANCE: 0.20,    // 基础20%战斗概率
FIGHT_DELAY: 3,        // 战斗间至少间隔3步

checkFight: function() {
    World.fightMove++;
    if(World.fightMove > World.FIGHT_DELAY) {
        var chance = World.FIGHT_CHANCE;
        chance *= $SM.hasPerk('stealthy') ? 0.5 : 1;  // 潜行技能减半概率
        if(Math.random() < chance) {
            World.fightMove = 0;
            Events.triggerFight();  // 触发随机遭遇战
        }
    }
}
```

### 3.3 敌人强度分层

游戏将敌人分为三个等级，基于距离村庄的远近：

#### Tier 1 (距离 ≤ 10格)
| 敌人 | 地形 | 伤害 | 血量 | 命中率 | 主要掉落 |
|------|------|------|------|--------|----------|
| 咆哮野兽 | 森林 | 1 | 5 | 80% | 毛皮、肉、牙齿 |
| 憔悴男人 | 荒地 | 2 | 6 | 80% | 布料、牙齿、皮革 |
| 奇异鸟类 | 田野 | 3 | 4 | 80% | 鳞片、牙齿、肉 |

#### Tier 2 (距离 10-20格)
| 敌人 | 地形 | 伤害 | 血量 | 命中率 | 主要掉落 |
|------|------|------|------|--------|----------|
| 颤抖男人 | 荒地 | 5 | 20 | 50% | 药物、牙齿 |
| 食人兽 | 森林 | 3 | 25 | 80% | 大量毛皮、肉 |
| 拾荒者 | 荒地 | 4 | 30 | 80% | 布料、皮革、铁 |
| 巨型蜥蜴 | 田野 | 5 | 20 | 80% | 鳞片、牙齿、肉 |

#### Tier 3 (距离 > 20格)
| 敌人 | 地形 | 伤害 | 血量 | 命中率 | 特殊能力 | 主要掉落 |
|------|------|------|------|--------|----------|----------|
| 野性恐兽 | 森林 | 6 | 45 | 80% | 快速攻击 | 大量毛皮、肉 |
| 士兵 | 荒地 | 8 | 50 | 80% | 远程攻击 | 子弹、步枪 |
| 狙击手 | 田野 | 15 | 30 | 80% | 远程高伤害 | 子弹、步枪 |

### 3.4 装备需求递增

游戏通过装备需求强制玩家进行装备升级：

| 距离范围 | 推荐装备 | 防护效果 | 解锁条件 |
|----------|----------|----------|----------|
| 0-8格 | 无装备要求 | - | 游戏开始 |
| 8-18格 | 铁甲 (i armour) | +15血量 | 铁矿 + 制作台 |
| 18+格 | 钢甲 (s armour) | +35血量 | 煤矿 + 高级制作 |
| 终极区域 | 动能装甲 (kinetic armour) | +75血量 | 太空船技术 |

## 4. 地图生成算法

### 4.1 螺旋生成算法

```javascript
generateMap: function() {
    var map = new Array(World.RADIUS * 2 + 1);  // 61x61地图

    // 村庄固定在正中心
    map[World.RADIUS][World.RADIUS] = World.TILE.VILLAGE;  // (30,30)

    // 从中心螺旋向外生成地形
    for(var r = 1; r <= World.RADIUS; r++) {
        for(var t = 0; t < r * 8; t++) {
            var x, y;
            // 计算螺旋坐标
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

    // 放置地标
    for(var k in World.LANDMARKS) {
        var landmark = World.LANDMARKS[k];
        for(var l = 0; l < landmark.num; l++) {
            World.placeLandmark(landmark.minRadius, landmark.maxRadius, k, map);
        }
    }

    return map;
}
```

### 4.2 地形粘性系统

```javascript
STICKINESS: 0.5,  // 相同地形聚集概率50%

// 地形生成概率
World.TILE_PROBS[World.TILE.FOREST] = 0.15;   // 森林15%
World.TILE_PROBS[World.TILE.FIELD] = 0.35;    // 田野35%
World.TILE_PROBS[World.TILE.BARRENS] = 0.5;   // 荒地50%

chooseTile: function(x, y, map) {
    // 检查相邻地形
    var adjacent = [
        y > 0 ? map[x][y-1] : null,
        y < World.RADIUS * 2 ? map[x][y+1] : null,
        x < World.RADIUS * 2 ? map[x+1][y] : null,
        x > 0 ? map[x-1][y] : null
    ];

    var chances = {};
    var nonSticky = 1;

    // 计算粘性影响
    for(var i in adjacent) {
        if(typeof adjacent[i] == 'string') {
            var cur = chances[adjacent[i]] || 0;
            chances[adjacent[i]] = cur + World.STICKINESS;
            nonSticky -= World.STICKINESS;
        }
    }

    // 添加基础概率
    for(var t in World.TILE) {
        var tile = World.TILE[t];
        if(World.isTerrain(tile)) {
            var cur = chances[tile] || 0;
            cur += World.TILE_PROBS[tile] * nonSticky;
            chances[tile] = cur;
        }
    }

    // 随机选择地形
    var r = Math.random();
    var c = 0;
    for(var tile in chances) {
        c += chances[tile];
        if(r < c) {
            return tile;
        }
    }

    return World.TILE.BARRENS;  // 默认荒地
}
```

## 5. 地标事件系统

### 5.1 洞穴系统 (Cave)

洞穴是游戏中最复杂的地标，采用多层随机分支结构：

```
入口 → 需要火把
├── 30% → 遭遇野兽 (伤害1, 血量5)
├── 30% → 狭窄通道
└── 40% → 废弃营地 (获得肉、火把、皮革)

深入探索 → 多种可能结果：
├── 野兽巢穴 → 大量资源 (肉5-10, 毛皮5-10, 鳞片5-10)
├── 补给缓存 → 制作材料 (布料、皮革、铁、钢)
└── 古老箱子 → 钢剑 + 药物
```

#### 洞穴奖励递增机制
- **入口层**：基础资源 (1-5个)
- **中层**：中等资源 + 武器
- **深层**：大量资源 (5-10个) + 稀有物品

### 5.2 矿山系统

三个矿山代表游戏的主要进度节点：

#### 铁矿 (距离5格)
```javascript
'enter': {
    combat: true,
    enemy: 'beastly matriarch',  // 野兽族长
    damage: 4,
    health: 10,
    loot: {
        'teeth': { min: 5, max: 10, chance: 1 },
        'scales': { min: 5, max: 10, chance: 0.8 }
    }
}
```
- **解锁**：铁矿开采建筑
- **效果**：连接道路到村庄
- **意义**：进入中期发展阶段

#### 煤矿 (距离10格)
```javascript
// 三波敌人：普通人 → 普通人 → 首领
'a3': {
    enemy: 'chief',
    damage: 5,
    health: 20,
    loot: {
        'cured meat': { min: 5, max: 10, chance: 1 },
        'iron': { min: 1, max: 5, chance: 0.8 }
    }
}
```

#### 硫磺矿 (距离20格)
```javascript
// 三波敌人：士兵 → 士兵 → 老兵
'a3': {
    enemy: 'veteran',
    damage: 10,
    health: 65,
    loot: {
        'bayonet': { min: 1, max: 1, chance: 0.5 }
    }
}
```

### 5.3 特殊地标

#### 沼泽 (Swamp)
- **需求**：护身符 (charm)
- **奖励**：美食家技能 (gastronome perk)
- **效果**：减少食物消耗

#### 战场 (Battlefield)
- **特点**：无战斗，直接获得战利品
- **奖励**：步枪、激光枪、手榴弹、外星合金
- **意义**：高级武器装备来源

#### 钻孔 (Borehole)
- **特点**：稳定的外星合金来源
- **奖励**：1-3个外星合金 (100%概率)
- **意义**：制作终极装备的关键材料

## 6. 技能系统与难度缓解

### 6.1 资源消耗减少技能

| 技能名称 | 效果 | 获得方式 |
|----------|------|----------|
| 慢代谢 (slow metabolism) | 食物消耗减半 | 经验积累 |
| 沙漠鼠 (desert rat) | 水消耗减半 | 经验积累 |
| 潜行 (stealthy) | 战斗概率减半 | 经验积累 |
| 精准 (precise) | 命中率+10% | 经验积累 |
| 美食家 (gastronome) | 食物效果增强 | 沼泽地标 |

### 6.2 技能获得机制

```javascript
// 基于行动次数的经验系统
addPerk: function(perk) {
    if(!$SM.hasPerk(perk)) {
        $SM.set('character.perks["' + perk + '"]', true);
        Notifications.notify(null, _('learned ' + perk));
    }
}
```

## 7. 核心设计理念

### 7.1 资源管理压力

- **水是硬限制**：没水会脱水死亡，无法逆转
- **食物是软限制**：没食物会饥饿但不会立即死亡
- **距离越远，风险越大**：战斗概率和装备需求递增

### 7.2 风险回报平衡

| 风险等级 | 距离范围 | 主要威胁 | 主要奖励 |
|----------|----------|----------|----------|
| 低风险 | 0-8格 | 弱小敌人 | 基础资源、铁矿 |
| 中风险 | 8-18格 | 中等敌人 | 制作材料、煤矿 |
| 高风险 | 18+格 | 强大敌人 | 高级装备、硫磺矿 |
| 极限风险 | 28格 | 终极挑战 | 游戏目标、最强装备 |

### 7.3 渐进式解锁循环

```
准备阶段 → 探索阶段 → 收集阶段 → 返回阶段 → 升级阶段 → 准备更远探索
    ↑                                                           ↓
    ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

这个循环确保玩家：
1. **有明确目标**：下一个地标或资源
2. **感受进步**：每次探索都有收获
3. **面临挑战**：需要更好装备才能走得更远
4. **体验成长**：通过制作和技能变得更强

## 8. 实现建议

### 8.1 Flutter实现要点

1. **状态管理**：使用Provider管理世界状态、玩家位置、资源
2. **地图渲染**：实现高效的瓦片渲染系统
3. **事件系统**：模块化的地标事件处理
4. **保存系统**：支持游戏进度的持久化存储

### 8.2 关键算法

1. **距离计算**：曼哈顿距离 `|x1-x2| + |y1-y2|`
2. **视野计算**：以玩家为中心的矩形区域
3. **概率系统**：基于权重的随机选择
4. **路径生成**：从地标到村庄的最短路径

这个设计创造了一个完美平衡的探索体验，让玩家在资源限制的压力下，逐步探索越来越危险但回报丰厚的区域。

