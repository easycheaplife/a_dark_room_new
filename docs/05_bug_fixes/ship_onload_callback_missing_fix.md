# 访问W地标后没有出现破旧星舰页签问题修复

**最后更新**: 2025-06-29

## 🐛 问题描述

**问题**: 用户访问W地标（坠毁星舰）后，没有出现破旧星舰页签。

**影响**: 玩家无法访问星舰功能，无法进行船体强化、引擎升级和最终的太空探索。

## 🔍 根本原因分析

通过详细分析代码流程，发现问题出现在Events模块的onLoad回调处理中。

### 完整的星舰解锁流程

#### 1. 地标访问流程
1. 玩家在世界地图中移动到W地标（坠毁星舰）
2. `world.dart`的`doSpace()`方法检测到地标
3. 调用`setpieces.startSetpiece('ship')`启动ship场景事件
4. `events.dart`的`startEvent()`方法处理场景事件
5. `loadScene('start')`加载ship场景的start场景
6. **关键步骤**：处理场景的`onLoad`回调

#### 2. onLoad回调处理
在setpieces.dart中，ship场景定义了onLoad回调：
```dart
'ship': {
  'scenes': {
    'start': {
      'onLoad': 'activateShip',  // 字符串形式的回调
      // ...
    }
  }
}
```

#### 3. 问题所在
在`events.dart`的`_handleOnLoadCallback()`方法中，缺少对'activateShip'回调的处理：

**修复前的代码**：
```dart
void _handleOnLoadCallback(String callbackName) {
  switch (callbackName) {
    case 'useOutpost':
      Setpieces().useOutpost();
      break;
    case 'clearCity':
      Setpieces().clearCity();
      break;
    // ... 其他回调
    default:
      Logger.info('⚠️ 未知的onLoad回调: $callbackName');  // activateShip会走到这里
      break;
  }
}
```

**结果**：当ship场景的onLoad回调'activateShip'被触发时，会走到default分支，只是记录一个警告日志，但不会执行任何实际操作。

## 🔧 修复方案

### 修复内容

在`events.dart`的`_handleOnLoadCallback()`方法中添加对'activateShip'和'activateExecutioner'回调的处理：

**文件**: `lib/modules/events.dart`

```dart
void _handleOnLoadCallback(String callbackName) {
  Logger.info('🔧 _handleOnLoadCallback() 被调用: $callbackName');
  switch (callbackName) {
    // ... 现有的回调处理
    case 'clearCity':
      Logger.info('🔧 调用 Setpieces().clearCity()');
      Setpieces().clearCity();
      break;
    case 'activateShip':  // 新增：处理星舰激活回调
      Logger.info('🔧 调用 Setpieces().activateShip()');
      Setpieces().activateShip();
      break;
    case 'activateExecutioner':  // 新增：处理执行者激活回调
      Logger.info('🔧 调用 Setpieces().activateExecutioner()');
      Setpieces().activateExecutioner();
      break;
    case 'endEvent':
      Logger.info('🔧 调用 endEvent()');
      endEvent();
      break;
    default:
      Logger.info('⚠️ 未知的onLoad回调: $callbackName');
      break;
  }
}
```

### 修复逻辑

修复后的完整流程：
1. 玩家访问W地标 → 触发ship场景事件
2. 加载ship场景的start场景 → 检测到`onLoad: 'activateShip'`
3. 调用`_handleOnLoadCallback('activateShip')` → 匹配到新增的case
4. 执行`Setpieces().activateShip()` → 设置`World.state['ship'] = true`
5. 玩家返回村庄 → `goHome()`检查世界状态
6. 检测到`state['ship'] == true` → 调用`Ship().init()`
7. 设置`features.location.spaceShip = true` → 页签显示条件满足
8. "破旧星舰"页签正确显示

## ✅ 修复验证

### 测试步骤
1. 启动游戏，进入世界地图探索
2. 寻找并访问坠毁星舰地标（W符号）
3. 观察日志输出，确认activateShip回调被正确调用
4. 返回村庄，检查是否出现"破旧星舰"页签
5. 点击页签，验证星舰界面是否正常显示

### 预期日志输出
修复后，访问W地标时应该看到以下日志：
```
[INFO] 🏛️ 启动Setpiece场景: ship
[INFO] 🎬 成功加载场景: start
[INFO] 🔧 场景有onLoad回调: activateShip
[INFO] 🔧 执行字符串形式的onLoad回调: activateShip
[INFO] 🔧 _handleOnLoadCallback() 被调用: activateShip
[INFO] 🔧 调用 Setpieces().activateShip()
[INFO] 🚀 坠毁星舰事件完成，设置 World.state.ship = true
```

返回村庄时应该看到：
```
[INFO] 🚀 检测到ship状态为true，开始初始化Ship模块
[INFO] 🏠 解锁星舰页签完成
```

## 🎯 相关问题

这个修复同时解决了执行者（Executioner）事件的类似问题，因为执行者事件也使用了'activateExecutioner'回调，之前同样会被忽略。

## 📋 修改文件清单

### 主要修改文件
- `lib/modules/events.dart` - 添加activateShip和activateExecutioner回调处理

### 相关文件
- `lib/modules/setpieces.dart` - activateShip()方法实现
- `lib/modules/world.dart` - Ship模块初始化逻辑
- `lib/modules/ship.dart` - Ship模块实现
- `lib/widgets/header.dart` - 页签显示逻辑

## 🔗 相关修复

这个修复是对之前"破旧星舰页签缺失问题修复"的补充，之前的修复解决了状态设置和检查的一致性问题，这次修复解决了onLoad回调处理的缺失问题。

两个修复结合起来，完整解决了破旧星舰页签无法显示的问题。

## 🔄 第三次发现的问题

### 问题：goHome()方法中的null检查错误

在修复onLoad回调和页签键值后，发现在返回村庄时出现新的错误：

```
type 'Null' is not a 'bool' in boolean expression
```

**错误位置**: `lib/modules/world.dart` 第1420行和第1429行

### 根本原因

在goHome()方法中，使用了`!`操作符来检查布尔值，但是StateManager.get()可能返回null：

```dart
// 错误的写法
if (state!['ship'] == true && !sm.get('features.location.spaceShip', true)) {
  // 如果sm.get()返回null，!null会导致类型错误
}
```

### 第三次修复

**文件**: `lib/modules/world.dart`

```dart
// 修复前
if (state!['ship'] == true &&
    !sm.get('features.location.spaceShip', true)) {

// 修复后
if (state!['ship'] == true &&
    (sm.get('features.location.spaceShip', true) != true)) {
```

同样修复了fabricator的检查：

```dart
// 修复前
if (state!['command'] == true &&
    !sm.get('features.location.fabricator', true)) {

// 修复后
if (state!['command'] == true &&
    (sm.get('features.location.fabricator', true) != true)) {
```

### 修复说明

使用`!= true`而不是`!`操作符的好处：
- `!= true`：null、false都会返回true，只有true返回false
- `!`操作符：对null使用会导致类型错误

这样修复后，即使StateManager返回null，也不会导致类型错误。

## ✅ 完整修复验证

修复后的完整流程：
1. 访问W地标 → 触发ship场景事件
2. onLoad回调 → 正确调用activateShip()
3. 设置状态 → World.state['ship'] = true
4. 返回村庄 → goHome()检查状态（无类型错误）
5. 初始化Ship → Ship().init()设置features.location.spaceShip = true
6. 页签检查 → header.dart检查features.location.spaceShip（键值一致）
7. 页签显示 → "破旧星舰"页签正确显示

## 🧪 测试建议

如果用户之前访问过W地标但页签仍未显示，建议：

1. **重新访问W地标** - 确保完整的解锁流程被触发
2. **观察日志输出** - 确认以下关键日志：
   - `🔧 调用 Setpieces().activateShip()`
   - `🚀 坠毁星舰事件完成，设置 World.state.ship = true`
   - `🚀 检测到ship状态为true，开始初始化Ship模块`
   - `🚀 Ship模块初始化完成，页签应该显示`
   - `🏠 解锁星舰页签完成`

3. **返回村庄** - 确保goHome()被调用来检查世界状态
4. **验证页签** - 检查"破旧星舰"页签是否出现

## 🔄 第四次发现的问题

### 问题：页签检查键值仍然不一致

在修复了onLoad回调、页签键值和null检查后，发现页签仍然不显示。通过日志分析发现：

1. **Ship模块正确初始化** - 日志显示`🚀 检测到ship状态为true，开始初始化Ship模块`
2. **但页签仍不显示** - 用户反馈页签没有显示，只有执行器

重新检查代码发现header.dart中的修复没有生效。

### 根本原因

header.dart中的`_isShipUnlocked`方法仍然检查错误的键值：

```dart
// 错误的检查
bool _isShipUnlocked(StateManager stateManager) {
  return stateManager.get('features.location.ship') == true;  // 应该是spaceShip
}
```

而Ship模块设置的是`features.location.spaceShip`。

### 第四次修复

**文件**: `lib/widgets/header.dart`

```dart
// 修复前
bool _isShipUnlocked(StateManager stateManager) {
  return stateManager.get('features.location.ship') == true;
}

// 修复后
bool _isShipUnlocked(StateManager stateManager) {
  return stateManager.get('features.location.spaceShip') == true;
}
```

### 修复验证

修复后的完整流程验证：

1. **✅ onLoad回调** - Events模块正确处理'activateShip'回调
2. **✅ 状态设置** - Setpieces().activateShip()设置World.state['ship'] = true
3. **✅ 返回村庄** - goHome()检查世界状态，无null错误
4. **✅ Ship初始化** - Ship().init()设置features.location.spaceShip = true
5. **✅ 页签检查** - header.dart检查features.location.spaceShip（键值一致）
6. **✅ 页签显示** - "破旧星舰"页签正确显示

---

*本修复确保了场景事件的onLoad回调能够正确执行，解决了页签键值不一致和null检查错误的问题，彻底解决了星舰页签无法显示的问题。*
