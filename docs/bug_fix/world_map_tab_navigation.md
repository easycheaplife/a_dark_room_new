# 世界地图页签导航隐藏修复

## 📋 问题描述

用户反馈：**前往世界地图后，页签不需要显示，无法通过页签返回，只有在主动返回村庄或者战斗失败返回**

在当前的实现中，进入世界地图后页签仍然显示，但根据原游戏的逻辑，进入世界地图时应该隐藏页签导航，只能通过主动返回村庄或死亡返回来恢复页签导航。

## 🔍 问题分析

### 当前实现问题
1. **页签始终显示**: 进入世界地图后，页签仍然可见和可点击
2. **导航逻辑错误**: 用户可以通过页签直接返回其他模块，这与原游戏不符
3. **游戏体验不一致**: 原游戏中世界地图是一个独立的探索模式，不应该有页签导航

### 原游戏逻辑分析

通过查看原游戏代码 `adarkroom/script/world.js` 和 `adarkroom/script/engine.js`：

#### 进入世界地图时（World.onArrival）
```javascript
Engine.tabNavigation = false;
```

#### 死亡时（World.die）
```javascript
Engine.tabNavigation = true;
```

#### 安全回家时（World.goHome）
```javascript
Engine.restoreNavigation = true;
```

#### 按键处理时（Engine.keyUp）
```javascript
if(Engine.restoreNavigation){
  Engine.tabNavigation = true;
  Engine.restoreNavigation = false;
}
```

## 🛠️ 修复方案

### 1. 修改Header组件支持页签隐藏

#### 修改文件：`lib/widgets/header.dart`

**添加页签导航检查**：
```dart
@override
Widget build(BuildContext context) {
  return Consumer3<Engine, StateManager, Localization>(
    builder: (context, engine, stateManager, localization, child) {
      final activeModule = engine.activeModule;

      // 检查页签导航是否被禁用（如在世界地图中）
      if (!engine.tabNavigation) {
        return Container(
          height: 40, // 保持相同高度
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 右侧空间填充
              const Spacer(),

              // 语言切换按钮
              Container(
                margin: const EdgeInsets.only(right: 5),
                child: PopupMenuButton<String>(
                  onSelected: (String language) =>
                      _switchLanguage(context, language),
                  icon: const Icon(
                    Icons.language,
                    color: Colors.black,
                    size: 20,
                  ),
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'zh',
                      child: Text('中文'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'en',
                      child: Text('English'),
                    ),
                  ],
                ),
              ),

              // 设置按钮
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // 构建可用的页签列表
      List<Widget> tabs = [];
      // ... 原有的页签构建逻辑
    },
  );
}
```

### 2. 修改World模块控制页签导航

#### 修改文件：`lib/modules/world.dart`

**进入世界地图时禁用页签导航**：
```dart
/// 到达时调用 - 参考原游戏的onArrival函数
void onArrival([int transitionDiff = 0]) {
  final sm = StateManager();

  // 禁用页签导航 - 参考原游戏 Engine.tabNavigation = false
  final engine = Engine();
  engine.tabNavigation = false;
  Logger.info('🌍 页签导航已禁用');

  // ... 其他初始化逻辑
}
```

**安全回家时恢复页签导航**：
```dart
/// 回家 - 参考原游戏的goHome函数
void goHome() {
  Logger.info('🏠 World.goHome() 开始');

  // 重新启用页签导航 - 参考原游戏 Engine.restoreNavigation = true
  final engine = Engine();
  engine.restoreNavigation = true;
  Logger.info('🌍 页签导航将在下次按键时恢复');

  // ... 其他回家逻辑
}
```

**死亡时立即恢复页签导航**：
```dart
/// 死亡 - 参考原游戏的World.die函数
void die() {
  if (!dead) {
    dead = true;
    health = 0;
    Logger.info('💀 玩家死亡');

    // 重新启用页签导航 - 参考原游戏 Engine.tabNavigation = true
    final engine = Engine();
    engine.tabNavigation = true;
    Logger.info('🌍 页签导航已重新启用');

    // ... 其他死亡处理逻辑
  }
}
```

### 3. 修改Engine类处理导航恢复

#### 修改文件：`lib/core/engine.dart`

**在模块切换时检查导航恢复**：
```dart
// 前往不同的模块
void travelTo(dynamic module) {
  if (activeModule == module) {
    return;
  }

  // 更新活动模块
  activeModule = module;

  // 调用新模块的onArrival
  module.onArrival(1);

  // 检查是否需要恢复导航 - 参考原游戏的restoreNavigation逻辑
  if (restoreNavigation) {
    tabNavigation = true;
    restoreNavigation = false;
    Logger.info('🌍 页签导航已恢复');
  }

  // 打印模块的通知
  NotificationManager().printQueue(module.name);

  notifyListeners();
}
```

**在按键处理时恢复导航**（已存在）：
```dart
// 处理按键释放事件
void keyUp(KeyEvent event) {
  keyPressed = false;

  if (activeModule != null && activeModule.keyUp != null) {
    activeModule.keyUp(event);
  } else {
    // 处理导航键
    // 这将根据键码实现
  }

  if (restoreNavigation) {
    tabNavigation = true;
    restoreNavigation = false;
  }
}
```

## ✅ 修复结果

### 1. 页签导航控制 ✅
- ✅ **进入世界地图**: 页签导航被禁用，只显示语言切换和设置按钮
- ✅ **安全回家**: 页签导航通过 `restoreNavigation` 标志恢复
- ✅ **死亡返回**: 页签导航立即恢复

### 2. 用户体验 ✅
- ✅ **世界地图独立性**: 进入世界地图后无法通过页签返回
- ✅ **强制探索**: 用户必须完成探索或死亡才能返回
- ✅ **原游戏一致性**: 完全符合原游戏的导航逻辑

### 3. 代码质量 ✅
- ✅ **参考原游戏**: 严格按照原游戏的 `Engine.tabNavigation` 逻辑实现
- ✅ **状态管理**: 通过 `tabNavigation` 和 `restoreNavigation` 标志控制
- ✅ **日志记录**: 添加了详细的日志记录便于调试

## 🎯 技术亮点

1. **原游戏逻辑复现**: 完全按照原游戏的页签导航控制逻辑实现
2. **状态管理**: 使用 `tabNavigation` 和 `restoreNavigation` 两个标志精确控制导航状态
3. **UI适配**: Header组件智能检测导航状态，在禁用时只显示必要的控件
4. **多路径恢复**: 支持安全回家和死亡两种方式恢复页签导航

## 📝 遵循要求

- ✅ **参考原游戏**: 严格按照原游戏的导航控制逻辑进行实现
- ✅ **最小化修改**: 只修改必要的组件和方法
- ✅ **代码复用**: 利用现有的Engine状态管理机制
- ✅ **关键日志**: 添加了重要的日志记录
- ✅ **文档记录**: 在 `docs/bug_fix` 目录下详细记录了修复过程

这次修复成功实现了与原游戏完全一致的世界地图页签导航控制，确保了游戏体验的准确性和一致性。
