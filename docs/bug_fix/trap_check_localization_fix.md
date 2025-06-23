# 检查陷阱事件日志本地化修复

## 问题描述
检查陷阱功能的事件日志本地化不完全，陷阱掉落物品的消息显示为英文键名（如 `some_meat`、`some_fur`）而不是正确的中文翻译（如 `一些肉`、`一些毛皮`）。

## 问题分析

### 根本原因
在 `checkTraps()` 方法中，陷阱掉落消息的本地化处理存在两个问题：

1. **未翻译消息键**：在第517行直接将本地化键（如 `'some_fur'`）添加到消息列表中，没有进行翻译
2. **本地化类别缺失**：这些消息键在语言文件的 `game_states` 部分，但本地化系统的查找类别中没有包含此部分

### 问题表现
从日志中可以看到：
```
[INFO] 🪤 陷阱掉落: meat -> some_meat -> some_meat
[INFO] 🪤 陷阱掉落: fur -> some_fur -> some_fur
```
翻译结果仍然是 `some_meat` 而不是期望的 `一些肉`。

### 代码问题位置

#### 1. 未翻译的消息键（`outside.dart` 第517行）
```dart
// 问题代码
if (num == 0) {
  msg.add(message);  // 直接添加未翻译的键
}

// 应该是
if (num == 0) {
  final translatedMessage = localization.translate(messageKey);
  msg.add(translatedMessage);  // 添加翻译后的消息
}
```

#### 2. 缺失的本地化类别（`localization.dart` 第115-126行）
```dart
// 问题：缺少 'game_states' 类别
List<String> categories = [
  'ui',
  'buildings',
  'crafting',
  'world.crafting',
  'resources',
  'workers',
  'weapons',
  'skills',
  'events',
  'messages'
];
```

## 解决方案

### 修复步骤 1：修复消息翻译逻辑
在 `lib/modules/outside.dart` 的 `checkTraps()` 方法中：

1. 提前获取本地化实例
2. 在循环中翻译消息键
3. 添加调试日志以验证翻译结果

```dart
// 获取本地化实例（提前获取以便在循环中使用）
final localization = Localization();

for (var i = 0; i < numDrops; i++) {
  final roll = random.nextDouble();
  for (final drop in trapDrops) {
    if (roll < drop['rollUnder']) {
      final name = drop['name'] as String;
      final messageKey = drop['message'] as String;
      final num = drops[name] ?? 0;
      if (num == 0) {
        // 翻译消息键并添加到消息列表
        final translatedMessage = localization.translate(messageKey);
        msg.add(translatedMessage);
        Logger.info('🪤 陷阱掉落: $name -> $messageKey -> $translatedMessage');
      }
      drops[name] = num + 1;
      break;
    }
  }
}
```

### 修复步骤 2：添加本地化类别
在 `lib/core/localization.dart` 的 `translate` 方法中添加 `game_states` 类别：

```dart
List<String> categories = [
  'ui',
  'buildings',
  'crafting',
  'world.crafting',
  'resources',
  'workers',
  'weapons',
  'skills',
  'events',
  'messages',
  'game_states'  // 添加游戏状态类别，用于陷阱掉落消息等
];
```

## 实施步骤

### 步骤 1：修复消息翻译逻辑
- ✅ 修改 `outside.dart` 第509-542行的 `checkTraps()` 方法
- ✅ 提前获取本地化实例
- ✅ 在循环中翻译消息键
- ✅ 添加详细的调试日志

### 步骤 2：扩展本地化类别
- ✅ 修改 `localization.dart` 第115-127行
- ✅ 在类别列表中添加 `'game_states'`
- ✅ 添加注释说明用途

### 步骤 3：测试验证
- ✅ 运行 `flutter run -d chrome` 验证修改无编译错误
- ✅ 测试检查陷阱功能
- ✅ 验证日志消息正确本地化

## 修改文件清单

### 修改文件
1. **lib/modules/outside.dart**
   - 第509-548行：重构 `checkTraps()` 方法的消息处理逻辑
   - 添加本地化翻译和调试日志

2. **lib/core/localization.dart**
   - 第115-127行：在类别列表中添加 `'game_states'`
   - 添加注释说明

### 修改详情

#### outside.dart 修改
```diff
+ // 获取本地化实例（提前获取以便在循环中使用）
+ final localization = Localization();
+
  for (var i = 0; i < numDrops; i++) {
    final roll = random.nextDouble();
    for (final drop in trapDrops) {
      if (roll < drop['rollUnder']) {
        final name = drop['name'] as String;
-       final message = drop['message'] as String;
+       final messageKey = drop['message'] as String;
        final num = drops[name] ?? 0;
        if (num == 0) {
-         msg.add(message);
+         // 翻译消息键并添加到消息列表
+         final translatedMessage = localization.translate(messageKey);
+         msg.add(translatedMessage);
+         Logger.info('🪤 陷阱掉落: $name -> $messageKey -> $translatedMessage');
        }
        drops[name] = num + 1;
        break;
      }
    }
  }

- // 构建消息
- final localization = Localization();
+ // 构建消息
  if (msg.isEmpty) {
    // ... 其余代码保持不变
  } else {
    // ...
-   s += msg[l];
+   s += msg[l]; // 现在 msg[l] 已经是翻译后的文本
  }
```

#### localization.dart 修改
```diff
  List<String> categories = [
    'ui',
    'buildings',
    'crafting',
    'world.crafting',
    'resources',
    'workers',
    'weapons',
    'skills',
    'events',
    'messages',
+   'game_states'  // 添加游戏状态类别，用于陷阱掉落消息等
  ];
```

## 技术细节

### 语言文件结构
陷阱掉落消息在语言文件中的位置：
```json
{
  "game_states": {
    "some_fur": "一些毛皮",
    "some_meat": "一些肉",
    "some_scales": "一些鳞片",
    "some_teeth": "一些牙齿",
    "some_cloth": "一些布料",
    "a_charm": "一个护身符"
  }
}
```

### 本地化查找逻辑
修复后的查找流程：
1. 尝试 `game_states.some_meat` → 找到 `一些肉`
2. 返回翻译结果
3. 添加到消息列表中

### 调试日志格式
```
[INFO] 🪤 陷阱掉落: meat -> some_meat -> 一些肉
[INFO] 🪤 陷阱掉落: fur -> some_fur -> 一些毛皮
```
格式：`资源名 -> 消息键 -> 翻译结果`

## 测试结果

### 功能测试
- ✅ 游戏正常启动和运行
- ✅ 检查陷阱功能正常工作
- ✅ 陷阱掉落消息正确本地化
- ✅ 消息拼接逻辑正常（多个物品用"和"连接）

### 本地化测试
- ✅ 中文环境下显示中文消息：`陷阱里有一些肉和一些毛皮`
- ✅ 英文环境下显示英文消息：`the traps contain some meat and some fur`
- ✅ 空陷阱消息正确显示：`陷阱里什么都没有`

### 日志验证
修复前：
```
[INFO] 🪤 陷阱掉落: meat -> some_meat -> some_meat
```

修复后：
```
[INFO] 🪤 陷阱掉落: meat -> some_meat -> 一些肉
[INFO] 🪤 陷阱掉落: fur -> some_fur -> 一些毛皮
[INFO] 🪤 陷阱掉落: scales -> some_scales -> 一些鳞片
```

## 修复效果

### 用户体验改善
- **完整本地化**：陷阱检查消息现在完全本地化
- **一致性**：与游戏其他部分的本地化保持一致
- **可读性**：用户看到的是有意义的中文文本而不是技术键名

### 代码质量提升
- **正确的翻译流程**：消息在使用前进行翻译
- **完善的本地化支持**：扩展了本地化类别覆盖范围
- **调试友好**：添加了详细的调试日志

### 维护性改善
- **统一的本地化架构**：所有消息都通过统一系统处理
- **易于扩展**：新的游戏状态消息可以轻松添加
- **问题定位**：调试日志帮助快速定位本地化问题

## 后续建议

1. **全面审查**：检查其他模块是否存在类似的本地化问题
2. **测试覆盖**：为本地化功能添加自动化测试
3. **文档完善**：更新本地化开发指南，说明正确的使用方式

## 总结

本次修复成功解决了检查陷阱事件日志本地化不完全的问题，通过最小化修改（仅修改两个文件的关键部分）实现了完整的本地化支持。修复遵循了"保持最小化修改，只修改有问题的部分代码"的原则，确保了修复的精准性和安全性。
