# A Whirring Fabricator 开启条件分析

## 问题
用户询问图片中"A Whirring Fabricator"（破旧星舰）的开启条件是什么。

## 分析结果

### 开启条件
根据原游戏代码分析，"A Whirring Fabricator"的开启条件如下：

1. **前置条件：必须先开启 "An Old Starship"**
   - 需要在世界地图上找到并访问 "A Crashed Ship"（坠毁的星舰）地标
   - 坠毁星舰的位置：距离村庄半径28格的固定位置
   - 访问坠毁星舰后会开启 "An Old Starship" 功能

2. **核心条件：必须完成 "A Ravaged Battleship" 事件**
   - 需要在世界地图上找到并访问 "A Ravaged Battleship"（破损战舰）地标
   - 破损战舰的位置：距离村庄半径28格的固定位置（与坠毁星舰不同位置）
   - 必须完成整个破损战舰的探索事件链

### 详细流程

#### 第一步：开启星舰功能
```javascript
// 在 world.js 第965-968行
if(World.state.ship && !$SM.get('features.location.spaceShip')) {
  Ship.init();
  Engine.event('progress', 'ship');
}
```

#### 第二步：开启制造器功能
```javascript
// 在 world.js 第969-973行
if (World.state.executioner && !$SM.get('features.location.fabricator')) {
  Fabricator.init();
  Notifications.notify(null, _('builder knows the strange device when she sees it. takes it for herself real quick. doesn't ask where it came from.'));
  Engine.event('progress', 'fabricator');
}
```

### 地标位置信息
```javascript
// 在 world.js 第147行和第151行
World.LANDMARKS[World.TILE.SHIP] = { num: 1, minRadius: 28, maxRadius: 28, scene: 'ship', label: _('A Crashed Starship')};
World.LANDMARKS[World.TILE.EXECUTIONER] = { num: 1, minRadius: 28, maxRadius: 28, scene: 'executioner', 'label': _('A Ravaged Battleship')};
```

### 关键事件触发
在破损战舰事件的最后阶段（executioner.js 第537-540行）：
```javascript
onLoad: () => {
  World.drawRoad();
  World.state.executioner = true;
},
```

### 总结
"A Whirring Fabricator"的开启需要：
1. 探索世界地图，找到距离村庄28格的坠毁星舰
2. 访问坠毁星舰，开启星舰功能
3. 继续探索世界地图，找到距离村庄28格的破损战舰
4. 完成破损战舰的完整探索事件链
5. 在事件结束时获得"奇怪装置"，自动开启制造器功能

制造器开启后，建造者会自动识别这个装置并将其据为己有，玩家就可以使用制造器来制作高级物品了。

## 相关文件
- `adarkroom/script/world.js` - 地标定义和开启逻辑
- `adarkroom/script/events/setpieces.js` - 坠毁星舰事件
- `adarkroom/script/events/executioner.js` - 破损战舰事件
- `adarkroom/script/fabricator.js` - 制造器功能实现
- `adarkroom/script/ship.js` - 星舰功能实现
