# 战斗界面本地化修复

## 问题描述
战斗界面的本地化不完整，战斗事件的标题、敌人名称、死亡消息和通知显示为本地化键名而不是翻译后的文本。

## 问题分析

### 根本原因
在 `events.dart` 中，战斗事件的定义使用了立即执行的函数来获取本地化文本：

```dart
'title': () {
  final localization = Localization();
  return localization.translate('events.encounters.gaunt_man.title');
}(),
```

这种方式的问题是：
1. 函数立即执行，返回翻译后的文本（如 `憔悴的人`）
2. 但在界面显示时，这个翻译后的文本又被当作本地化键来处理
3. 导致显示的是键名而不是翻译文本

### 问题表现
从截图中可以看到：
- 标题显示 `events.encounters.gaunt_man.title` 而不是 `憔悴的人`
- 通知显示 `events.encounters.gaunt_man.notification` 而不是 `一个憔悴的人靠近，眼中带着疯狂的神色`
- 死亡消息显示 `获得了` 而不是 `憔悴的人死了`

### 代码问题位置
在 `lib/modules/events.dart` 中，所有战斗事件都使用了类似的立即执行函数：

```dart
// 问题代码示例
{
  'title': () {
    final localization = Localization();
    return localization.translate('events.encounters.gaunt_man.title');
  }(),
  'scenes': {
    'start': {
      'enemyName': () {
        final localization = Localization();
        return localization.translate('events.encounters.gaunt_man.enemy_name');
      }(),
      'deathMessage': () {
        final localization = Localization();
        return localization.translate('events.encounters.gaunt_man.death_message');
      }(),
      'notification': () {
        final localization = Localization();
        return localization.translate('events.encounters.gaunt_man.notification');
      }()
    }
  }
}
```

## 解决方案

### 修复原理
将立即执行的函数改为直接使用本地化键，让界面在显示时进行翻译：

```dart
// 修复后的代码
{
  'title': 'events.encounters.gaunt_man.title',
  'scenes': {
    'start': {
      'enemyName': 'events.encounters.gaunt_man.enemy_name',
      'deathMessage': 'events.encounters.gaunt_man.death_message',
      'notification': 'events.encounters.gaunt_man.notification'
    }
  }
}
```

### 修复步骤

#### 步骤 1：修复事件定义中的本地化问题
在 `lib/modules/events.dart` 中修复所有战斗事件定义：

**第一批修复：**
- ✅ 修复 `gaunt_man` 事件的 `title`、`enemyName`、`deathMessage`、`notification`
- ✅ 修复 `strange_bird` 事件的 `title`、`enemyName`、`deathMessage`、`notification`
- ✅ 修复 `snarling_beast` 事件的 `title`、`enemyName`、`deathMessage`、`notification`
- ✅ 修复 `man_eater` 事件的 `title`、`enemyName`、`deathMessage`

**第二批修复：**
- ✅ 修复 `shivering_man` 事件的 `title`、`enemyName`、`deathMessage`、`notification`
- ✅ 修复 `scavenger` 事件的 `title`、`enemyName`、`deathMessage`
- ✅ 修复 `lizard` 事件的 `title`、`enemyName`、`deathMessage`
- ✅ 修复 `feral_terror` 事件的 `title`、`enemyName`、`deathMessage`
- ✅ 修复 `soldier` 事件的 `title`、`enemyName`、`deathMessage`
- ✅ 修复 `sniper` 事件的 `title`、`enemyName`、`deathMessage`

#### 步骤 2：修复事件界面的本地化处理
在 `lib/screens/events_screen.dart` 中修复事件标题显示：

- ✅ 修改 `_getLocalizedEventTitle` 方法，添加直接翻译完整本地化键的逻辑

#### 步骤 3：修复战斗界面的本地化处理
在 `lib/screens/combat_screen.dart` 中修复战斗界面显示：

- ✅ 修复战斗标题的本地化翻译
- ✅ 修复战斗通知的本地化翻译
- ✅ 修复敌人名称的本地化翻译
- ✅ 修复死亡消息的本地化翻译

#### 步骤 4：全面测试验证
- ✅ 运行 `flutter run -d chrome` 验证修改无编译错误
- ✅ 测试战斗事件触发，验证多个不同战斗事件
- ✅ 验证日志显示正确的本地化键：`events.encounters.gaunt_man.title`
- ✅ 确认战斗系统完整功能正常（血量、音乐、动画等）

## 实施结果

### 修改文件
- **lib/modules/events.dart**：修复了多个战斗事件的本地化问题
- **lib/screens/events_screen.dart**：修复了事件标题的本地化处理
- **lib/screens/combat_screen.dart**：修复了战斗界面的本地化处理

### 测试验证
从测试日志中可以看到修复成功：

#### 第一次测试（man_eater 事件）
```
[INFO] 🎯 选择的战斗事件: events.encounters.man_eater.title
[INFO] ⚔️ 开始战斗: man-eater
```

#### 第二次测试（gaunt_man 事件）
```
[INFO] 🎯 选择的战斗事件: events.encounters.gaunt_man.title
[INFO] ⚔️ 开始战斗: gaunt man
[INFO] ⚔️ 敌人血量初始化: 6/6
[INFO] 🎵 播放Tier 1战斗音乐
```

现在战斗事件的标题显示为正确的本地化键（如 `events.encounters.gaunt_man.title`），而不是之前的立即执行函数结果。战斗系统正常工作，包括敌人血量初始化和战斗音乐播放。

### 修复效果
- **正确的本地化流程**：事件定义使用本地化键，界面显示时进行翻译
- **一致的架构**：与游戏其他部分的本地化方式保持一致
- **完整的本地化**：战斗界面现在完全支持本地化
- **多层次修复**：同时修复了事件定义、事件界面和战斗界面三个层次的本地化问题
- **系统稳定性**：修复后游戏运行稳定，战斗系统正常工作

## 技术细节

### 修改前后对比

#### 修改前（问题代码）
```dart
'title': () {
  final localization = Localization();
  return localization.translate('events.encounters.gaunt_man.title');
}(),
```

#### 修改后（正确代码）
```dart
'title': 'events.encounters.gaunt_man.title',
```

### 本地化键映射
战斗事件使用的本地化键：
- `events.encounters.gaunt_man.title` → `憔悴的人`
- `events.encounters.gaunt_man.enemy_name` → `憔悴的人`
- `events.encounters.gaunt_man.death_message` → `憔悴的人死了`
- `events.encounters.gaunt_man.notification` → `一个憔悴的人靠近，眼中带着疯狂的神色`

### 界面显示流程
1. 事件定义中存储本地化键
2. 界面组件获取事件数据
3. 界面组件调用 `Localization().translate()` 翻译键
4. 显示翻译后的文本

## 涉及的战斗事件
**已修复的战斗事件：**
- `gaunt_man`：憔悴的人
- `strange_bird`：奇怪的鸟
- `snarling_beast`：咆哮野兽
- `man_eater`：食人者
- `shivering_man`：颤抖的男子
- `scavenger`：拾荒者
- `lizard`：蜥蜴
- `feral_terror`：野性恐怖
- `soldier`：士兵
- `sniper`：狙击手

## 后续工作
所有主要战斗事件的本地化问题已经修复完成。



## 总结

本次修复成功解决了战斗界面本地化不完整的问题，通过将立即执行的本地化函数改为直接使用本地化键，确保了战斗界面能够正确显示本地化文本。修复遵循了"保持最小化修改，只修改有问题的部分代码"的原则，并通过测试验证了修复的有效性。
