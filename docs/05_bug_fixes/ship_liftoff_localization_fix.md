# 飞船起飞确认对话框本地化修复

**日期**: 2025-07-03  
**类型**: Bug修复  
**状态**: ✅ 已修复  

## 🐛 问题描述

**问题**: 在中文状态下，飞船起飞确认对话框仍然显示英文文本，包括标题"ready to leave?"、内容"time to leave this place. won't be coming back."和按钮"lift off"。

**影响**: 破坏了游戏的本地化一致性，中文用户体验不佳。

## 🔍 根本原因分析

### 问题定位

通过代码分析发现，在 `lib/modules/ship.dart` 的 `checkLiftOff()` 方法中，起飞确认对话框的文本是硬编码的英文，没有使用本地化系统：

```dart
// 问题代码 - 硬编码英文文本
final liftOffEvent = {
  'title': 'ready to leave?',  // 硬编码英文
  'scenes': {
    'start': {
      'text': ['time to leave this place. won\'t be coming back.'],  // 硬编码英文
      'buttons': {
        'fly': {
          'text': 'lift off',  // 硬编码英文
          // ...
        },
        'wait': {
          'text': 'wait',  // 硬编码英文
          // ...
        }
      }
    }
  }
};
```

### 根本原因

1. **缺少本地化键值**: 本地化文件中没有定义起飞确认对话框的翻译
2. **硬编码文本**: 代码中直接使用英文字符串，没有调用本地化系统
3. **不一致的实现**: 其他部分已经使用本地化，但这个对话框被遗漏了

## 🛠️ 修复实施

### 1. 添加本地化翻译

#### 文件：`assets/lang/zh.json`

在 `ship` 部分添加起飞事件的翻译：

```json
"ship": {
  // ... 其他配置
  "liftoff_event": {
    "title": "准备离开？",
    "text": "是时候离开这个地方了。不会再回来了。",
    "lift_off": "起飞",
    "wait": "等待"
  }
}
```

#### 文件：`assets/lang/en.json`

添加对应的英文翻译：

```json
"ship": {
  // ... 其他配置
  "liftoff_event": {
    "title": "ready to leave?",
    "text": "time to leave this place. won't be coming back.",
    "lift_off": "lift off",
    "wait": "wait"
  }
}
```

### 2. 修改代码使用本地化

#### 文件：`lib/modules/ship.dart`

修改 `checkLiftOff()` 方法，使用本地化系统：

```dart
/// 检查起飞条件
void checkLiftOff() {
  final sm = StateManager();

  if (sm.get('game.spaceShip.seenWarning', true) != true) {
    // 显示警告事件 - 使用本地化文本
    final localization = Localization();
    final liftOffEvent = {
      'title': localization.translate('ship.liftoff_event.title'),
      'scenes': {
        'start': {
          'text': [localization.translate('ship.liftoff_event.text')],
          'buttons': {
            'fly': {
              'text': localization.translate('ship.liftoff_event.lift_off'),
              'onChoose': () {
                sm.set('game.spaceShip.seenWarning', true);
                liftOff();
              },
              'nextScene': 'end'
            },
            'wait': {
              'text': localization.translate('ship.liftoff_event.wait'),
              'onChoose': () {
                // 清除起飞按钮冷却
                NotificationManager().notify(name, 
                    localization.translate('ship.notifications.wait_decision'));
              },
              'nextScene': 'end'
            }
          }
        }
      }
    };

    Events().startEvent(liftOffEvent);
  } else {
    liftOff();
  }
}
```

## ✅ 修复验证

### 测试步骤

1. **启动游戏**：确保游戏正常启动
2. **切换到中文**：验证语言设置为中文
3. **进入飞船页签**：导航到破旧星舰页签
4. **点击起飞按钮**：触发起飞确认对话框
5. **验证本地化**：确认所有文本都显示为中文

### 预期结果

- ✅ 对话框标题显示："准备离开？"
- ✅ 对话框内容显示："是时候离开这个地方了。不会再回来了。"
- ✅ 起飞按钮显示："起飞"
- ✅ 等待按钮显示："等待"

### 实际测试结果

通过热重启测试，确认：
- ✅ 所有文本正确显示中文
- ✅ 按钮功能正常工作
- ✅ 语言切换功能正常
- ✅ 不影响其他功能

## 🎯 技术要点

### 1. 本地化键值设计

使用层级结构组织翻译键值：
```
ship.liftoff_event.title
ship.liftoff_event.text
ship.liftoff_event.lift_off
ship.liftoff_event.wait
```

### 2. 动态文本生成

在运行时根据当前语言设置动态生成对话框内容，确保语言切换时立即生效。

### 3. 向后兼容

保持原有的事件结构不变，只是将硬编码文本替换为本地化调用，确保不影响其他功能。

## 📋 修改文件清单

### 主要修改文件
- `lib/modules/ship.dart` - 修改起飞确认对话框使用本地化
- `assets/lang/zh.json` - 添加中文翻译
- `assets/lang/en.json` - 添加英文翻译

### 相关文件
- `lib/core/localization.dart` - 本地化系统（无需修改）
- `lib/modules/events.dart` - 事件系统（无需修改）

## 🔄 后续改进建议

1. **全面审查**: 检查其他可能存在硬编码文本的地方
2. **自动化检测**: 建立机制检测未本地化的文本
3. **翻译质量**: 优化翻译文本的准确性和流畅性
4. **多语言支持**: 为其他语言添加相应翻译

## 📝 总结

本次修复成功解决了飞船起飞确认对话框的本地化问题：

- ✅ **完整本地化**: 所有文本都正确使用本地化系统
- ✅ **用户体验**: 中文用户现在看到一致的中文界面
- ✅ **代码质量**: 消除了硬编码文本，提高了代码可维护性
- ✅ **向后兼容**: 不影响现有功能和英文用户体验

这个修复确保了A Dark Room游戏在所有语言环境下都能提供一致的本地化体验。

---

*本修复解决了游戏本地化的一个重要缺陷，提升了中文用户的游戏体验。*
