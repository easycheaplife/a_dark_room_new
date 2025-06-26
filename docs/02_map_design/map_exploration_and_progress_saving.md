# A Dark Room 地图探索范围扩展与进度保存机制详解

## 📋 概述

本文档详细分析了A Dark Room游戏中地图探索范围扩展和进度保存机制，包括视野系统、地图遮罩、探索进度保存和状态管理等核心系统。

## 🔍 视野与探索系统

### 基础视野机制

```javascript
// 原游戏常量定义
LIGHT_RADIUS: 2,              // 基础视野半径2格
```

#### 视野范围计算
- **基础视野**: 玩家周围2格的菱形区域
- **侦察技能加成**: 有侦察技能时视野翻倍至4格
- **永久记忆**: 已探索区域永久可见

### 地图遮罩系统

#### 遮罩初始化
```javascript
// 创建61x61的遮罩数组，初始全部为false（未探索）
newMask: function() {
    var mask = new Array(World.RADIUS * 2 + 1);
    for(var i = 0; i <= World.RADIUS * 2; i++) {
        mask[i] = new Array(World.RADIUS * 2 + 1);
    }
    // 初始点亮村庄周围区域
    World.lightMap(World.RADIUS, World.RADIUS, mask);
    return mask;
}
```

#### 视野照亮算法
```javascript
// 菱形视野算法
lightMap: function(x, y, mask) {
    var r = World.LIGHT_RADIUS;
    r *= $SM.hasPerk('scout') ? 2 : 1;  // 侦察技能翻倍
    World.uncoverMap(x, y, r, mask);
    return mask;
}

uncoverMap: function(x, y, r, mask) {
    mask[x][y] = true;
    for(var i = -r; i <= r; i++) {
        for(var j = -r + Math.abs(i); j <= r - Math.abs(i); j++) {
            if(y + j >= 0 && y + j <= World.RADIUS * 2 &&
                x + i <= World.RADIUS * 2 && x + i >= 0) {
                mask[x+i][y+j] = true;  // 标记为已探索
            }
        }
    }
}
```

### 探索范围扩展机制

#### 移动时的视野更新
```javascript
// 每次移动都会更新视野
move: function(direction) {
    var oldTile = World.state.map[World.curPos[0]][World.curPos[1]];
    World.curPos[0] += direction[0];
    World.curPos[1] += direction[1];
    
    // 关键：移动后立即更新视野
    World.lightMap(World.curPos[0], World.curPos[1], World.state.mask);
    World.drawMap();
    World.doSpace();
}
```

#### 技能影响视野范围

| 技能状态 | 视野半径 | 可见区域 | 探索效率 |
|---------|----------|----------|----------|
| **无侦察技能** | 2格 | 5×5菱形 | 标准 |
| **有侦察技能** | 4格 | 9×9菱形 | 4倍效率 |

### 全地图探索检测

```javascript
// 检查是否已探索完整个地图
testMap: function() {
    if(!World.seenAll) {
        var dark = false; 
        var mask = $SM.get('game.world.mask');
        
        // 遍历整个遮罩数组
        loop:
        for(var i = 0; i < mask.length; i++) {
            for(var j = 0; j < mask[i].length; j++) {
                if(!mask[i][j]) {
                    dark = true;
                    break loop;
                }
            }
        }
        World.seenAll = !dark;
    }
}
```

## 💾 进度保存机制

### 状态管理架构

#### 状态分类
```javascript
// 原游戏状态分类
var State = {
    version: 1.3,
    stores: {},        // 资源库存
    character: {},     // 角色状态和技能
    income: {},        // 收入系统
    timers: {},        // 定时器状态
    game: {            // 游戏核心状态
        world: {
            map: [],   // 地图数据
            mask: []   // 探索遮罩
        }
    },
    playStats: {},     // 游戏统计
    previous: {},      // 声望系统
    outfit: {},        // 装备配置
    config: {},        // 配置选项
    wait: {},          // 神秘流浪者
    cooldown: {}       // 冷却时间
};
```

### 自动保存系统

#### 触发保存的操作
```javascript
// 每次状态变更都会触发保存
set: function(stateName, value, noEvent) {
    // ... 设置状态值 ...
    
    if(!noEvent) {
        Engine.saveGame();  // 自动保存
        $SM.fireUpdate(stateName);
    }
}
```

#### 保存实现
```javascript
saveGame: function() {
    if(typeof Storage != 'undefined' && localStorage) {
        // 保存到浏览器本地存储
        localStorage.gameState = JSON.stringify(State);
        
        // 显示保存提示
        $('#saveNotify').css('opacity', 1).animate({opacity: 0}, 1000);
    }
}
```

### 地图状态保存

#### 探索进度保存
```javascript
// 地图和遮罩数据保存在game.world中
$SM.setM('game.world', {
    map: World.generateMap(),    // 地图地形数据
    mask: World.newMask()        // 探索遮罩数据
});
```

#### 移动时的状态更新
```javascript
// Flutter实现中的保存逻辑
void move(List<int> direction) {
    // ... 移动逻辑 ...
    
    // 更新遮罩并保存到StateManager
    final mask = List<List<bool>>.from(
        state!['mask'].map((row) => List<bool>.from(row)));
    lightMap(curPos[0], curPos[1], mask);
    state!['mask'] = mask;
    
    // 立即保存遮罩到StateManager以确保持久化
    final sm = StateManager();
    sm.set('game.world.mask', mask);
}
```

## 🔧 Flutter实现状态

### 已实现功能

✅ **基础视野系统**
```dart
static const int lightRadius = 2;

List<List<bool>> lightMap(int x, int y, List<List<bool>> mask) {
  int r = lightRadius;
  // r *= sm.hasPerk('scout') ? 2 : 1; // 暂时注释掉技能系统
  uncoverMap(x, y, r, mask);
  return mask;
}
```

✅ **菱形视野算法**
```dart
void uncoverMap(int x, int y, int r, List<List<bool>> mask) {
  mask[x][y] = true;
  for (int i = -r; i <= r; i++) {
    for (int j = -r + i.abs(); j <= r - i.abs(); j++) {
      if (y + j >= 0 && y + j <= radius * 2 &&
          x + i <= radius * 2 && x + i >= 0) {
        mask[x + i][y + j] = true;
      }
    }
  }
}
```

✅ **遮罩初始化**
```dart
List<List<bool>> newMask() {
  final mask = List.generate(
      radius * 2 + 1, (i) => List<bool>.filled(radius * 2 + 1, false));
  lightMap(radius, radius, mask);
  return mask;
}
```

✅ **全地图探索检测**
```dart
void testMap() {
  if (!seenAll) {
    bool dark = false;
    final sm = StateManager();
    final mask = sm.get('game.world.mask');
    
    // 检查是否还有未探索区域
    for (int i = 0; i < mask.length; i++) {
      for (int j = 0; j < mask[i].length; j++) {
        if (!mask[i][j]) {
          dark = true;
          break;
        }
      }
      if (dark) break;
    }
    seenAll = !dark;
  }
}
```

✅ **状态保存系统**
```dart
// 自动保存游戏状态（每30秒）
void startAutoSave() {
  Timer.periodic(const Duration(seconds: 30), (timer) {
    saveGame();
  });
}

Future<void> saveGame() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonState = jsonEncode(_state);
  await prefs.setString('gameState', jsonState);
}
```

### 实现文件对照

| 功能模块 | 原游戏文件 | Flutter文件 |
|---------|-----------|-------------|
| 视野系统 | `world.js` | `lib/modules/world.dart` |
| 状态管理 | `state_manager.js` | `lib/core/state_manager.dart` |
| 保存机制 | `engine.js` | `lib/core/state_manager.dart` |
| 地图显示 | `world.js` | `lib/screens/world_screen.dart` |

## 🎮 游戏设计意义

### 渐进式探索体验

#### 迷雾战争机制
- **有限视野**创造**未知感**和**探索欲望**
- **逐步揭开**地图增加**发现的乐趣**
- **永久记忆**避免重复探索的**挫败感**

#### 技能驱动的探索效率
- **侦察技能**提供**明显的探索优势**
- **4倍视野面积**大幅提升**探索效率**
- 鼓励玩家**投资技能系统**

### 进度保护机制

#### 实时保存
- **每次状态变更**都会**自动保存**
- **防止意外丢失**探索进度
- **无缝游戏体验**，无需手动保存

#### 数据完整性
- **完整保存**地图状态和探索进度
- **版本兼容性**处理游戏更新
- **导入导出**功能支持数据迁移

## 📊 探索效率分析

### 视野覆盖面积

#### 基础视野 (半径2)
```
覆盖面积: 13格
探索效率: 1x
形状: 菱形
```

#### 侦察技能视野 (半径4)
```
覆盖面积: 41格
探索效率: 3.15x
形状: 大菱形
```

### 完整地图探索时间

| 探索方式 | 需要移动次数 | 预估时间 |
|---------|-------------|----------|
| **无侦察技能** | ~300步 | 15-20分钟 |
| **有侦察技能** | ~100步 | 5-8分钟 |

## 💡 设计智慧

### 心理激励机制

#### 探索奖励
- **新区域发现**带来**成就感**
- **地标发现**提供**实质奖励**
- **完整地图**解锁**终极目标**

#### 技能价值体现
- **侦察技能**的**显著效果**
- **投资回报**清晰可见
- **技能选择**影响游戏体验

### 技术设计优势

#### 性能优化
- **遮罩系统**只渲染**已探索区域**
- **增量更新**避免**全地图重绘**
- **本地存储**确保**快速加载**

#### 扩展性设计
- **模块化状态管理**
- **版本兼容性**处理
- **灵活的保存机制**

## 🔗 相关文档

- [地图难度设计](map_difficulty_design.md)
- [水容量增长机制](water_capacity_growth_mechanism.md)
- [背包容量增长机制](backpack_capacity_growth_mechanism.md)
- [Flutter实现指南](flutter_implementation_guide.md)

---

*本文档基于A Dark Room原游戏代码分析编写，为Flutter版本实现提供参考*
