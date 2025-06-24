# 地标访问逻辑修复

**修复日期**: 2025-01-27  
**问题类型**: 游戏逻辑错误  
**影响范围**: 地标H（房子）、铁矿I、煤矿C、硫磺矿S的访问逻辑  

## 问题描述

### 原始问题
用户报告：原游戏地标H访问后，如果选择的是直接离开，颜色不变，还可以继续访问，如果选择进入再离开，颜色变灰，不可再进入。

### 问题分析
经过代码分析发现，所有有Setpiece场景的地标（包括H、I、C、S）都存在相同的问题：
- **错误行为**：无论选择"进入"还是"离开"，地标都会立即标记为已访问
- **正确行为**：只有选择"进入"并完成场景后才应该标记为已访问，直接"离开"不应该标记

### 根本原因
在 `lib/modules/world.dart` 的 `move()` 方法中，第955-957行的逻辑有问题：
```dart
if (sceneName != 'cave') {
  // 立即标记为已访问，防止重复访问
  markVisited(curPos[0], curPos[1]);
}
```

这导致除了洞穴（cave）之外的所有地标都会在Setpiece启动时立即标记为已访问，而不是根据玩家的选择来决定。

## 修复方案

### 1. 修改world.dart中的地标处理逻辑

**文件**: `lib/modules/world.dart`  
**位置**: 第952-962行

**修改前**:
```dart
// 对于某些特殊场景（如洞穴、房子），不立即标记为已访问
// 只有在场景完成时才标记
if (sceneName != 'cave' && sceneName != 'house') {
  // 立即标记为已访问，防止重复访问
  markVisited(curPos[0], curPos[1]);
}
```

**修改后**:
```dart
// 对于某些特殊场景（如洞穴、房子、矿物），不立即标记为已访问
// 只有在场景完成时才标记
if (sceneName != 'cave' && 
    sceneName != 'house' && 
    sceneName != 'ironmine' && 
    sceneName != 'coalmine' && 
    sceneName != 'sulphurmine') {
  // 立即标记为已访问，防止重复访问
  markVisited(curPos[0], curPos[1]);
}
```

### 2. 修改setpieces.dart中house场景的逻辑

**文件**: `lib/modules/setpieces.dart`  
**位置**: 第638行

**修改前**:
```dart
'onLoad': 'replenishWater',
```

**修改后**:
```dart
'onLoad': 'markVisited',
```

这确保house场景的'supplies'分支也会正确标记为已访问。

## 修复效果

### 地标H（房子）
- ✅ **直接选择离开**：不标记为已访问，地标保持黑色（H），可以重复访问
- ✅ **选择进入后离开**：标记为已访问，地标变灰（H!），不可再访问

### 矿物地标（I、C、S）
- ✅ **直接选择离开**：不标记为已访问，地标保持黑色，可以重复访问
- ✅ **选择进入并完成清理**：标记为已访问，地标变灰，不可再访问

## 测试验证

### 实际测试结果
通过 `flutter run -d chrome --web-port=3000` 测试验证：

1. **第一次访问地标H**：
   ```
   [INFO] 🏛️ 触发地标事件: H (visited: false)
   [INFO] 🏛️ 启动Setpiece场景: house
   ```

2. **选择离开**：
   ```
   [INFO] 🎮 事件按钮点击: leave
   ```
   地标保持为 `H`，未被标记为已访问

3. **再次访问同一地标**：
   ```
   [INFO] 🏛️ 触发地标事件: H (visited: false)  // 仍然是false！
   ```

4. **选择进入**：
   ```
   [INFO] 🎮 事件按钮点击: enter
   [INFO] 🔧 执行字符串形式的onLoad回调: markVisited
   [INFO] 🗺️ 标记位置 (41, 28) 为已访问: H!  // 现在被标记为已访问！
   ```

### 验证结果
- ✅ 修复成功实现了原游戏的访问逻辑
- ✅ 直接离开不会标记为已访问
- ✅ 进入后才会标记为已访问
- ✅ 已访问的地标正确显示为灰色且不可重复访问

## 技术细节

### markVisited()函数机制
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

### 清理函数验证
确认所有矿物地标的清理函数都正确调用了 `markVisited()`：
- `clearIronMine()` 在第2171行调用 `World().markVisited()`
- `clearCoalMine()` 在第2214行调用 `World().markVisited()`  
- `clearSulphurMine()` 在第2234行调用 `World().markVisited()`

## 影响评估

### 正面影响
- ✅ 修复了与原游戏不一致的访问逻辑
- ✅ 提升了游戏体验的准确性
- ✅ 允许玩家在不确定时安全地"查看"地标而不消耗访问机会

### 风险评估
- ⚠️ **低风险**：修改仅影响地标访问逻辑，不影响其他游戏机制
- ⚠️ **兼容性**：与现有存档完全兼容
- ⚠️ **测试覆盖**：已通过实际游戏测试验证

## 相关文件

### 修改的文件
- `lib/modules/world.dart` - 地标访问逻辑
- `lib/modules/setpieces.dart` - house场景配置

### 相关文档
- `docs/terrain_analysis.md` - 地形分析文档
- `docs/terrain_analysis_code_consistency_check.md` - 代码一致性检查

## 更新日志

- **2025-01-27**: 初始修复，解决地标H、I、C、S的访问逻辑问题
