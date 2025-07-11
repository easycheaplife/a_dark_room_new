# 地形重复访问问题修复

## 问题描述
玩家报告访问地形I（铁矿）后，还可以继续访问，没有被标记为已访问状态。

## 问题分析

### 根本原因
通过分析代码发现，矿物地形（I、C、S）的访问标记时机有问题：

1. **当前逻辑**：只有在Setpiece事件完成时才调用 `markVisited()`
2. **问题场景**：如果玩家进入事件但中途离开，地形不会被标记为已访问
3. **结果**：玩家可以重复访问同一个矿物地形

### 代码分析

#### 矿物地形处理流程
```dart
case 'I': // 铁矿
  // 触发铁矿事件
  Events().triggerSetpiece('ironmine');
  break; // 问题：没有立即标记为已访问
```

#### Setpiece事件中的标记
```dart
void clearIronMine() {
  final sm = StateManager();
  sm.set('game.world.ironmine', true);
  World().markVisited(World().curPos[0], World().curPos[1]); // 只有完成事件才标记
  notifyListeners();
}
```

### 与其他地形的对比
其他简单地标地形都是立即标记为已访问：

```dart
case 'H': // 旧房子
  NotificationManager().notify(name, '发现了一座废弃的房子...');
  // 处理奖励...
  markVisited(curPos[0], curPos[1]); // 立即标记
  break;
```

## 解决方案

### 修复策略
在矿物地形事件触发时立即标记为已访问，而不是等到事件完成。

### 修复原理
1. **一致性**：与其他地标地形保持一致的处理方式
2. **防重复**：确保玩家不能重复访问同一个地形获得奖励
3. **用户体验**：避免玩家因为中途离开而能够重复刷取资源

### 具体修改

#### 修复铁矿 (I)
```dart
case 'I': // 铁矿
  // 触发铁矿事件
  Events().triggerSetpiece('ironmine');
  // 立即标记为已访问，防止重复访问
  markVisited(curPos[0], curPos[1]);
  break;
```

#### 修复煤矿 (C)
```dart
case 'C': // 煤矿
  // 触发煤矿事件
  Events().triggerSetpiece('coalmine');
  // 立即标记为已访问，防止重复访问
  markVisited(curPos[0], curPos[1]);
  break;
```

#### 修复硫磺矿 (S)
```dart
case 'S': // 硫磺矿
  // 触发硫磺矿事件
  Events().triggerSetpiece('sulphurmine');
  // 立即标记为已访问，防止重复访问
  markVisited(curPos[0], curPos[1]);
  break;
```

## 实施结果

### 修改文件
- **lib/modules/world.dart**：在 `_handleMissingSetpiece` 方法中修复了三个矿物地形的处理逻辑

### 修复效果
- ✅ 铁矿（I）访问后立即标记为已访问 (`I!`)
- ✅ 煤矿（C）访问后立即标记为已访问 (`C!`)
- ✅ 硫磺矿（S）访问后立即标记为已访问 (`S!`)
- ✅ 防止玩家重复访问获得奖励

### 测试验证
- ✅ 游戏成功启动，没有编译错误
- ✅ 修复逻辑与其他地标地形保持一致
- ✅ **实际测试确认修复有效**：
  - 第一次访问铁矿：`🏛️ 触发地标事件: I (visited: false)` → `🗺️ 标记位置 (28, 33) 为已访问: I!`
  - 第二次访问铁矿：`🏛️ 触发地标事件: I (visited: true)` → `🏛️ 地标已访问，跳过事件`
  - 地形正确从 `I` 变为 `I!`，防止重复访问

## 技术细节

### markVisited() 函数机制
```dart
void markVisited(int x, int y) {
  if (state != null && state!['map'] != null) {
    final map = state!['map'];
    if (!map[x][y].endsWith('!')) {
      map[x][y] = '$currentTile!'; // 添加已访问标记
      // 更新临时状态，回到村庄时保存
    }
  }
}
```

### 状态持久化
- **临时标记**：在探险期间立即标记地形为已访问
- **永久保存**：回到村庄时通过 `goHome()` 保存到 `StateManager`
- **视觉反馈**：已访问地形在地图上显示为灰色

### 双重保护机制
现在矿物地形有双重保护：
1. **立即标记**：访问时立即标记为已访问（本次修复）
2. **完成标记**：事件完成时再次标记（原有逻辑）

这确保了无论玩家是否完成事件，都不能重复访问。

## 设计考虑

### 游戏平衡
- **防止刷取**：避免玩家通过重复访问获得大量资源
- **一致体验**：所有地标地形都遵循"访问一次"的规则

### 用户体验
- **清晰反馈**：地形变灰明确表示已访问
- **避免困惑**：防止玩家误以为可以重复获得奖励

### 代码质量
- **一致性**：所有地标地形使用相同的访问控制机制
- **可维护性**：修复逻辑简单明了，易于理解和维护

## 相关文档
- **docs/terrain_analysis.md**：完整的地形处理逻辑分析
- **原游戏参考**：A Dark Room 原版游戏的地形访问机制

## 测试结果详细分析

### 修复前的问题
根据用户报告和代码分析，矿物地形（I、C、S）可以重复访问，原因是：
1. 只有在Setpiece事件完成时才调用 `markVisited()`
2. 如果玩家中途离开事件，地形不会被标记为已访问
3. 导致玩家可以重复获得奖励，破坏游戏平衡

### 修复后的效果
通过实际测试验证，修复完全有效：

#### 第一次访问铁矿
```
[INFO] 🗺️ doSpace() - 当前位置: [28, 33], 地形: I
[INFO] 🏛️ 触发地标事件: I (visited: false)
[INFO] 🏛️ 启动Setpiece场景: ironmine
[INFO] 🗺️ 标记位置 (28, 33) 为已访问: I!
```

#### 第二次访问铁矿
```
[INFO] 🗺️ doSpace() - 当前位置: [28, 33], 地形: I!
[INFO] 🏛️ 触发地标事件: I (visited: true)
[INFO] 🏛️ 地标已访问，跳过事件
```

### 关键改进
1. **立即标记**：在 `setpieces.startSetpiece(sceneName)` 后立即调用 `markVisited()`
2. **状态同步**：地形从 `I` 正确变为 `I!`
3. **访问控制**：第二次访问时正确识别为已访问并跳过事件
4. **一致性**：与其他地标地形的处理逻辑保持一致

## 总结

本次修复成功解决了矿物地形可以重复访问的问题，通过在事件触发时立即标记为已访问，确保了游戏的平衡性和一致性。修复遵循了"保持最小化修改，只修改有问题的部分代码"的原则，并与现有的地标处理逻辑保持一致。

**修复验证**：通过实际游戏测试确认，铁矿地形在第一次访问后正确标记为已访问，第二次访问时正确跳过事件，完全解决了重复访问问题。
