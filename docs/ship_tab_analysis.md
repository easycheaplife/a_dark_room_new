# A Dark Room 破旧星舰页签出现机制分析

**最后更新**: 2025-06-29

## 🎯 分析目标

分析原游戏中破旧星舰页签的出现机制，找出Flutter项目中缺失的原因，并提供修复方案。

## 🔍 原游戏机制分析

### 1. 地标生成机制

在原游戏`world.js`中，坠毁星舰作为固定地标生成：

```javascript
// adarkroom/script/world.js:147
World.LANDMARKS[World.TILE.SHIP] = { 
  num: 1, 
  minRadius: 28, 
  maxRadius: 28, 
  scene: 'ship', 
  label: _('A Crashed Starship')
};
```

**关键特征**：
- 地标符号：`W`
- 数量：固定1个
- 位置：距离村庄28格的固定位置
- 场景：触发`ship`场景事件

### 2. 场景事件触发

当玩家访问坠毁星舰地标时，触发setpieces.js中的ship事件：

```javascript
// adarkroom/script/events/setpieces.js:3140-3147
"ship": {
  title: _('A Crashed Ship'),
  scenes: {
    'start': {
      onLoad: function() {
        World.markVisited(World.curPos[0], World.curPos[1]);
        World.drawRoad();
        World.state.ship = true;  // 关键：设置ship状态
      }
    }
  }
}
```

**关键操作**：
- 标记位置为已访问
- 绘制道路连接
- **设置`World.state.ship = true`** - 这是触发页签的关键

### 3. 页签创建机制

当玩家返回村庄时，world.js的goHome函数检查各种解锁条件：

```javascript
// adarkroom/script/world.js:965-968
if(World.state.ship && !$SM.get('features.location.spaceShip')) {
  Ship.init();  // 初始化Ship模块，创建页签
  Engine.event('progress', 'ship');
}
```

**检查逻辑**：
- 条件1：`World.state.ship` 为true（已访问坠毁星舰）
- 条件2：`features.location.spaceShip` 未设置（首次解锁）
- 动作：调用`Ship.init()`创建页签和界面

### 4. Ship.init()功能

Ship.init()方法的主要功能：

```javascript
// adarkroom/script/ship.js:11-26
init: function(options) {
  if(!$SM.get('features.location.spaceShip')) {
    $SM.set('features.location.spaceShip', true);
    $SM.setM('game.spaceShip', {
      hull: Ship.BASE_HULL,
      thrusters: Ship.BASE_THRUSTERS
    });
  }
  
  // Create the Ship tab
  this.tab = Header.addLocation(_("An Old Starship"), "ship", Ship);
  
  // Create the Ship panel
  this.panel = $('<div>').attr('id', "shipPanel")
    .addClass('location')
    .appendTo('div#locationSlider');
}
```

**关键功能**：
- 设置解锁标志`features.location.spaceShip = true`
- 初始化星舰数据（船体、引擎）
- **创建页签**：调用`Header.addLocation()`
- 创建星舰界面面板

## 🐛 Flutter项目中的问题

### 问题1：状态设置不一致

**Flutter实现**（错误）：
```dart
// lib/modules/setpieces.dart:2710
void activateShip() {
  final sm = StateManager();
  World().markVisited(World().curPos[0], World().curPos[1]);
  World().drawRoad();
  sm.set('game.world.ship', true);  // 错误：设置到StateManager
  notifyListeners();
}
```

**原游戏实现**（正确）：
```javascript
World.state.ship = true;  // 正确：设置到World.state
```

**问题分析**：
- Flutter项目设置的是`game.world.ship`到StateManager
- 但检查的是`World.state['ship']`
- 两者不匹配，导致条件永远不满足

### 问题2：Ship.init()被注释

**Flutter实现**（错误）：
```dart
// lib/modules/world.dart:1421
// Ship.init(); // 暂时注释掉，需要实现Ship模块
```

**原游戏实现**（正确）：
```javascript
Ship.init();  // 直接调用
```

**问题分析**：
- 即使状态检查正确，Ship.init()也不会被调用
- 导致页签永远不会被创建

### 问题3：检查逻辑不完整

**Flutter实现**：
```dart
if (state!['ship'] == true &&
    !sm.get('features.location.spaceShip', true)) {
  // Ship.init(); // 被注释
  sm.set('features.location.spaceShip', true);
  Logger.info('🏠 解锁星舰');
}
```

**分析**：
- 检查逻辑基本正确
- 但缺少实际的Ship.init()调用

## 🔧 修复方案

### 修复1：统一状态设置

修改`activateShip()`方法，直接设置到World.state：

```dart
void activateShip() {
  final world = World();
  world.markVisited(world.curPos[0], world.curPos[1]);
  world.drawRoad();
  
  // 设置世界状态 - 参考原游戏 World.state.ship = true
  world.state = world.state ?? {};
  world.state!['ship'] = true;
  
  Logger.info('🚀 坠毁星舰事件完成，设置 World.state.ship = true');
  notifyListeners();
}
```

### 修复2：启用Ship.init()调用

在world.dart中启用Ship模块初始化：

```dart
if (state!['ship'] == true &&
    !sm.get('features.location.spaceShip', true)) {
  Ship().init();  // 启用Ship模块初始化
  sm.set('features.location.spaceShip', true);
  Logger.info('🏠 解锁星舰');
}
```

### 修复3：确保不影响村庄返回逻辑

**重要**：修改时必须保持地图中经过地标A返回村庄的逻辑不变：

```dart
if (curTile == tile['village']) {
  Logger.info('🏠 触发村庄事件 - 回到小黑屋');
  goHome();  // 这个逻辑不能改变
}
```

## 🎯 完整流程

修复后的完整破旧星舰解锁流程：

1. **探索世界地图** → 找到坠毁星舰地标（W符号，距离村庄28格）
2. **访问坠毁星舰** → 触发ship场景事件
3. **activateShip()** → 设置`World.state['ship'] = true`
4. **返回村庄** → 经过地标A或手动返回，触发goHome()
5. **状态检查** → 检测到`state['ship'] == true`
6. **Ship().init()** → 创建"破旧星舰"页签
7. **页签显示** → 玩家可以访问星舰功能

## 📋 验证清单

- [ ] 修复状态设置不一致问题
- [ ] 启用Ship.init()调用
- [ ] 确保不影响村庄返回逻辑（地标A）
- [ ] 测试完整的解锁流程
- [ ] 验证页签正确显示
- [ ] 确认星舰界面功能正常

---

*本分析确保了破旧星舰页签的正确实现，同时保持了原有的村庄返回机制不受影响。*
