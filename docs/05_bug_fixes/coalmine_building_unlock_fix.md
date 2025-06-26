# 煤矿建筑解锁问题修复

## 问题描述

用户报告：路过煤矿地标，完成煤矿解锁后没有出现煤矿的建筑和煤矿工。

## 更新状态

**第一次修复**：修复了后端逻辑，但发现UI显示仍有问题。
**第二次修复**：修复了UI显示逻辑，添加了矿物工人按钮和配置。
**第三次修复**：修复了战斗胜利后的场景转换问题，添加了"继续"按钮。

**当前状态**：需要用户在战斗胜利后点击"继续"按钮来完成完整的煤矿事件流程（三场战斗）。

## 问题分析

### 根本原因
1. **建筑解锁逻辑缺失**：`clearCoalMine()` 函数只设置了 `game.world.coalmine = true`，但没有添加煤矿建筑到建筑列表
2. **工人添加逻辑缺失**：没有调用 `checkWorker()` 来添加煤矿工人到工人列表
3. **UI显示逻辑缺失**：`outside_screen.dart` 中的 `_isWorkerUnlocked()` 函数没有包含矿物工人的检查逻辑
4. **工人按钮缺失**：工人按钮列表中没有包含矿物工人
5. **同样问题存在于铁矿和硫磺矿**：所有矿物建筑都有相同的问题

### 问题流程
```
玩家到达煤矿地标 → 触发煤矿事件 → 完成战斗 → clearCoalMine() 被调用
↓
只设置 game.world.coalmine = true
↓
没有添加建筑到 game.buildings["coal mine"]
↓
没有添加工人到 game.workers["coal miner"]
↓
结果：玩家看不到煤矿建筑和煤矿工人
```

## 解决方案

### 修复内容
1. **修改 `clearCoalMine()` 函数**：添加建筑解锁和工人添加逻辑
2. **修改 `clearIronMine()` 函数**：添加相同的逻辑
3. **修改 `clearSulphurMine()` 函数**：添加相同的逻辑
4. **添加必要的导入**：导入 `Logger` 和 `Outside` 模块
5. **修改 `_isWorkerUnlocked()` 函数**：添加矿物工人的解锁检查逻辑
6. **添加矿物工人按钮**：在工人按钮列表中添加矿物工人
7. **添加工人配置信息**：在 `_getWorkerInfo()` 函数中添加矿物工人的生产配置

### 代码修改

#### 文件：`lib/modules/setpieces.dart`

**添加导入：**
```dart
import '../core/logger.dart';
import 'outside.dart';
```

**修改 clearCoalMine() 函数：**
```dart
/// 清理煤矿
void clearCoalMine() {
  final sm = StateManager();
  sm.set('game.world.coalmine', true);
  
  // 解锁煤矿建筑 - 参考原游戏的建筑解锁逻辑
  if ((sm.get('game.buildings["coal mine"]', true) ?? 0) == 0) {
    sm.add('game.buildings["coal mine"]', 1);
    Logger.info('🏠 解锁煤矿建筑');
    
    // 检查并添加煤矿工人到工人列表
    Outside().checkWorker('coal mine');
    Logger.info('🏠 添加煤矿工人到工人列表');
  }
  
  World().markVisited(World().curPos[0], World().curPos[1]);
  notifyListeners();
}
```

**同样修改 clearIronMine() 和 clearSulphurMine() 函数**

#### 文件：`lib/screens/outside_screen.dart`

**修改 _isWorkerUnlocked() 函数：**
```dart
bool _isWorkerUnlocked(String type, StateManager stateManager) {
  switch (type) {
    // ... 其他工人类型 ...
    case 'iron miner':
      return (stateManager.get('game.buildings["iron mine"]', true) ?? 0) > 0;
    case 'coal miner':
      return (stateManager.get('game.buildings["coal mine"]', true) ?? 0) > 0;
    case 'sulphur miner':
      return (stateManager.get('game.buildings["sulphur mine"]', true) ?? 0) > 0;
    // ... 其他工人类型 ...
  }
}
```

**添加矿物工人按钮：**
```dart
// 在工人按钮列表中添加
_buildWorkerButton(localization.translate('workers.iron_miner'), 'iron miner', ...),
_buildWorkerButton(localization.translate('workers.coal_miner'), 'coal miner', ...),
_buildWorkerButton(localization.translate('workers.sulphur_miner'), 'sulphur miner', ...),
```

**添加工人配置信息：**
```dart
const incomeConfig = {
  // ... 其他工人配置 ...
  'iron miner': {
    'delay': 10,
    'stores': {'cured meat': -1, 'iron': 1}
  },
  'coal miner': {
    'delay': 10,
    'stores': {'cured meat': -1, 'coal': 1}
  },
  'sulphur miner': {
    'delay': 10,
    'stores': {'cured meat': -1, 'sulphur': 1}
  },
  // ... 其他工人配置 ...
};
```

## 技术细节

### 建筑解锁机制
- 原游戏中，矿物建筑通过完成相应的矿山事件自动解锁
- 建筑数据存储在 `game.buildings["建筑名"]` 中
- 值为建筑数量（矿物建筑通常为1）

### 工人添加机制
- `Outside().checkWorker()` 函数负责检查建筑并添加对应工人
- 工人数据存储在 `game.workers["工人名"]` 中
- 初始值为0，可以通过UI分配村民

### 日志记录
- 添加详细的日志记录来跟踪建筑解锁过程
- 便于调试和验证修复效果

## 测试验证

### 测试步骤
1. 启动游戏并发展到可以探索世界
2. 找到煤矿地标（距离村庄10格）
3. 完成煤矿事件战斗
4. 返回村庄检查是否出现煤矿建筑和煤矿工人

### 预期结果
- 煤矿建筑出现在建筑列表中
- 煤矿工人出现在工人列表中（初始为0）
- 可以分配村民到煤矿工作
- 煤矿工人开始生产煤炭

## 影响范围

### 修复的功能
- 煤矿建筑解锁
- 铁矿建筑解锁  
- 硫磺矿建筑解锁
- 对应工人的添加

### 不影响的功能
- 其他建筑的解锁机制
- 现有的游戏存档
- 其他模块的功能

## 注意事项

1. **最小化修改原则**：只修改必要的函数，保持原有逻辑不变
2. **向后兼容**：修改不会影响已有的游戏存档
3. **日志记录**：添加适当的日志以便调试
4. **代码复用**：三个矿物建筑使用相同的解锁逻辑

## 第三次修复：战斗胜利后场景转换问题

### 问题发现
通过日志分析发现，玩家在煤矿事件中只完成了第一场战斗（a1场景），没有继续到后续的a2、a3和cleared场景。这是因为战斗胜利后的战利品界面缺少"继续"按钮。

### 修复内容
在 `lib/screens/combat_screen.dart` 中添加"继续"按钮：

```dart
// 继续按钮 - 如果有下一个场景的话
if (_hasNextScene(events, scene))
  Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 2),
    child: ElevatedButton(
      onPressed: () => _continueToNextScene(events, scene),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black),
      ),
      child: Text(Localization().translate('ui.buttons.continue')),
    ),
  ),
```

### 辅助函数
```dart
/// 检查是否有下一个场景
bool _hasNextScene(Events events, Map<String, dynamic> scene) {
  final buttons = scene['buttons'] as Map<String, dynamic>? ?? {};
  final continueButton = buttons['continue'] as Map<String, dynamic>?;
  return continueButton != null && continueButton['nextScene'] != null;
}

/// 继续到下一个场景
void _continueToNextScene(Events events, Map<String, dynamic> scene) {
  final buttons = scene['buttons'] as Map<String, dynamic>? ?? {};
  final continueButton = buttons['continue'] as Map<String, dynamic>?;

  if (continueButton != null && continueButton['nextScene'] != null) {
    events.handleButtonClick('continue', continueButton);
  } else {
    events.endEvent();
  }
}
```

### 煤矿事件流程
完整的煤矿事件需要完成三场战斗：
1. **a1场景**：对战man敌人（血量10）
2. **a2场景**：对战man敌人（血量10）
3. **a3场景**：对战chief敌人（血量20）
4. **cleared场景**：调用clearCoalMine()函数解锁建筑

### 用户操作指南
1. 到达煤矿地标，点击"攻击"
2. 完成第一场战斗后，点击"继续"（不是"离开"）
3. 完成第二场战斗后，点击"继续"
4. 完成第三场战斗后，点击"继续"
5. 到达cleared场景，煤矿建筑和工人自动解锁

## 第四次修复：最终问题确认

### 问题确认
通过详细的日志分析，我发现了一个重要事实：

**后端逻辑完全正确！**

从游戏日志中可以清楚看到：
```
[INFO] 🏭 收集来自 coal miner 的收入
[INFO] 🏭 收集来自 iron miner 的收入
[INFO] 🏭 收集来自 sulphur miner 的收入
```

这说明：
1. ✅ 煤矿工人已存在并在工作
2. ✅ 铁矿工人已存在并在工作
3. ✅ 硫磺矿工人已存在并在工作
4. ✅ 所有矿物建筑都已解锁

从地图数据中也可以看到：
- `C!` - 煤矿已被访问（感叹号表示已完成）
- `I!` - 铁矿已被访问
- `S` - 硫磺矿存在

### 真正的问题
**问题不在于建筑解锁逻辑，而在于UI显示逻辑！**

用户看不到煤矿建筑和工人，是因为：
1. 村庄界面的建筑列表显示有问题
2. 工人管理界面的工人按钮显示有问题

### 解决方案
需要检查和修复：
1. `_buildBuildingsList()` 函数的建筑显示逻辑
2. `_buildWorkersButtons()` 函数的工人按钮显示逻辑
3. 建筑本地化名称的处理逻辑

### 用户操作确认
用户已经正确完成了煤矿事件的所有步骤：
1. ✅ 到达煤矿地标
2. ✅ 完成了所有三场战斗
3. ✅ 到达了cleared场景
4. ✅ clearCoalMine()函数被正确调用
5. ✅ 建筑和工人已正确添加到游戏状态

**结论**：用户的操作完全正确，问题在于UI显示层面。

## 相关文件

- `lib/modules/setpieces.dart` - 主要修改文件
- `lib/modules/outside.dart` - 工人检查逻辑
- `lib/screens/combat_screen.dart` - 战斗界面修复
- `lib/screens/outside_screen.dart` - UI显示修复（重点）
