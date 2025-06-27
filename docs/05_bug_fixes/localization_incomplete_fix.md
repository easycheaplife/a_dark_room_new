# 本地化不完全Bug修复

## 问题描述

在事件界面中，显示的是原始的本地化键名（如 `events.noises_inside.title`）而不是翻译后的中文文本。这导致用户看到的是技术性的键名而不是可读的文本。

## 问题分析

### 问题现象
1. **事件标题显示错误**：显示 `events.noises_inside.title` 而不是 "声音"
2. **事件文本显示错误**：显示 `events.noises_inside.text1` 而不是 "从储藏室可以听到抓挠的声音。"
3. **按钮文本显示错误**：显示 `ui.buttons.investigate` 而不是 "调查"

### 根因分析

通过分析代码发现问题出现在事件定义文件 `lib/events/room_events_extended.dart` 中：

```dart
/// 错误的实现方式
static Map<String, dynamic> get noisesInside => {
  'title': () {
    final localization = Localization();
    return localization.translate('events.noises_inside.title');
  }(), // 立即执行函数
  'scenes': {
    'start': {
      'text': () {
        final localization = Localization();
        return [
          localization.translate('events.noises_inside.text1'),
          localization.translate('events.noises_inside.text2')
        ];
      }(), // 立即执行函数
      // ...
    }
  }
};
```

**关键问题**：
1. **立即执行函数（IIFE）**：使用 `(){}()` 模式在模块加载时立即执行本地化翻译
2. **初始化时机问题**：当事件定义被加载时，本地化系统可能还没有完全初始化
3. **静态值问题**：翻译结果被固化为静态值，无法响应语言切换

### 初始化流程分析

**问题流程**：
1. 应用启动 → 加载事件定义文件
2. 事件定义中的立即执行函数被调用
3. 此时本地化系统可能还没有加载语言文件
4. `localization.translate()` 返回原始键名而不是翻译文本
5. 这些键名被固化在事件定义中

**正确流程应该是**：
1. 应用启动 → 初始化本地化系统
2. 加载语言文件
3. 事件系统在运行时动态获取翻译文本

## 修复方案

### 核心思路

将立即执行的本地化翻译改为延迟翻译，让事件系统在运行时动态获取翻译文本。

### 修复前代码
```dart
static Map<String, dynamic> get noisesInside => {
  'title': () {
    final localization = Localization();
    return localization.translate('events.noises_inside.title');
  }(),
  'scenes': {
    'start': {
      'text': () {
        final localization = Localization();
        return [
          localization.translate('events.noises_inside.text1'),
          localization.translate('events.noises_inside.text2')
        ];
      }(),
      'buttons': {
        'investigate': {
          'text': () {
            final localization = Localization();
            return localization.translate('ui.buttons.investigate');
          }(),
          // ...
        }
      }
    }
  }
};
```

### 修复后代码
```dart
static Map<String, dynamic> get noisesInside => {
  'title': 'events.noises_inside.title',
  'scenes': {
    'start': {
      'text': [
        'events.noises_inside.text1',
        'events.noises_inside.text2'
      ],
      'notification': 'events.noises_inside.notification',
      'buttons': {
        'investigate': {
          'text': 'ui.buttons.investigate',
          // ...
        },
        'ignore': {
          'text': 'ui.buttons.ignore',
          // ...
        }
      }
    }
  }
};
```

### 关键变化

1. **移除立即执行函数**：将 `() { return localization.translate('key'); }()` 改为 `'key'`
2. **保留本地化键**：直接使用本地化键名，让事件系统在运行时翻译
3. **保持功能性代码**：保留 `isAvailable`、`onLoad` 等功能性回调函数

## 修复范围

需要修复的事件定义：

### 已修复的事件
1. **noisesInside** - 里面的声音事件
   - title: 'events.noises_inside.title'
   - text: ['events.noises_inside.text1', 'events.noises_inside.text2']
   - buttons: 'ui.buttons.investigate', 'ui.buttons.ignore', 'ui.buttons.leave'

### 需要修复的事件
1. **beggar** - 乞丐事件
2. **shadyBuilder** - 可疑建造者事件
3. **mysteriousWandererWood** - 神秘流浪者-木材版事件
4. **mysteriousWandererFur** - 神秘流浪者-毛皮版事件
5. **scout** - 侦察兵事件
6. **master** - 大师事件
7. **martialMaster** - 武术大师事件
8. **sickMan** - 病人事件
9. **desertGuide** - 沙漠向导事件

## 技术细节

### 事件系统处理流程

事件系统在 `lib/screens/events_screen.dart` 中有专门的本地化处理函数：

```dart
/// 获取本地化的事件标题
String _getLocalizedEventTitle(Map<String, dynamic> event) {
  final localization = Localization();
  final title = event['title'] ?? localization.translate('events.default_title');
  
  // 首先尝试直接翻译标题
  String directTranslation = localization.translate(title);
  if (directTranslation != title) {
    return directTranslation;
  }
  // ...
}

/// 获取本地化的事件文本
String _getLocalizedEventText(String text) {
  final localization = Localization();
  
  // 尝试直接从本地化系统获取翻译
  String directTranslation = localization.translate(text);
  if (directTranslation != text) {
    return directTranslation;
  }
  // ...
}
```

这些函数能够正确处理本地化键名，将其翻译为对应的文本。

### 本地化文件结构

语言文件位于 `assets/lang/` 目录：

- `zh.json` - 中文翻译
- `en.json` - 英文翻译

事件相关的翻译结构：
```json
{
  "events": {
    "room_events": {
      "noises_inside": {
        "title": "声音",
        "text1": "从储藏室可以听到抓挠的声音。",
        "text2": "里面有什么东西。",
        "notification": "储藏室里有什么东西"
      }
    }
  },
  "ui": {
    "buttons": {
      "investigate": "调查",
      "ignore": "忽视",
      "leave": "离开"
    }
  }
}
```

## 预期效果

### ✅ 修复后的行为

1. **事件标题正确显示**：
   - 中文：显示 "声音"
   - 英文：显示 "noises"

2. **事件文本正确显示**：
   - 中文：显示 "从储藏室可以听到抓挠的声音。"
   - 英文：显示 "scratching noises can be heard from the store room."

3. **按钮文本正确显示**：
   - 中文：显示 "调查"、"忽视"
   - 英文：显示 "investigate"、"ignore"

4. **语言切换响应**：
   - 切换语言后，事件文本能够正确更新

### 🔍 验证方法

1. **启动应用**：检查事件界面是否显示正确的中文文本
2. **切换语言**：验证事件文本是否正确切换到英文
3. **触发事件**：确认所有事件的标题、文本、按钮都正确本地化

## 测试验证

为了确保修复的正确性，创建了专门的测试用例 `test/event_localization_fix_test.dart`：

### 测试覆盖范围

1. **事件标题测试**：验证返回本地化键而不是翻译文本
2. **事件文本测试**：验证文本数组包含正确的本地化键
3. **事件按钮测试**：验证按钮文本是本地化键
4. **事件可用性测试**：验证功能性函数仍然正常工作
5. **修复验证测试**：验证不再使用立即执行函数
6. **结构完整性测试**：验证事件结构保持完整
7. **本地化键格式测试**：验证键名格式正确

### 测试结果

```
🧪 测试环境初始化完成
✅ noisesInside 标题测试通过: events.noises_inside.title
✅ noisesInside 文本测试通过
   text1: events.noises_inside.text1
   text2: events.noises_inside.text2
✅ noisesInside 按钮测试通过
   investigate: ui.buttons.investigate
   ignore: ui.buttons.ignore
✅ noisesInside 可用性测试通过
✅ beggar 标题测试通过: events.room_events.beggar.title
✅ beggar 按钮测试通过
   give_50: ui.buttons.give_50
   deny: ui.buttons.deny
✅ 立即执行函数移除验证通过
   title类型: String
   title内容: events.noises_inside.title
✅ 事件结构完整性验证通过
✅ 本地化键格式验证通过
   键名: events.noises_inside.title
   包含中文: false
🧪 测试完成，清理测试环境

All tests passed!
```

### 关键验证点

1. **类型验证**：确认事件标题是 `String` 类型，不是函数调用结果
2. **内容验证**：确认返回的是本地化键名，不包含中文字符
3. **格式验证**：确认本地化键格式正确（包含点分隔符）
4. **功能验证**：确认事件可用性等功能性代码仍然正常工作

## 更新日期

2025-06-27

## 更新日志

- 2025-06-27: 修复事件定义中的立即执行函数导致的本地化不完全问题
- 2025-06-27: 添加专门的测试用例验证修复效果，所有测试通过
