# Localization 测试修复

## 问题描述

`localization_test.dart` 测试文件在运行时失败，主要错误包括：

1. **单例模式问题**: Localization 使用单例模式，在测试之间共享状态，导致后续测试失败
2. **Mock 数据不一致**: 不同测试组设置了不同的 mock 翻译数据，导致某些翻译在特定测试中不可用
3. **过早释放问题**: 在 `tearDown` 中调用了 `dispose()`，但单例一旦被释放就不能再使用

## 错误信息

```
Expected: '房间'
Actual: 'ui.modules.room'

Expected: '需要 5 个木材'
Actual: 'crafting.wood_needed'

Expected: '欢迎来到黑暗房间'
Actual: 'welcome'
```

## 解决方案

### 1. 修改单例模式支持测试重置

在 `Localization` 类中添加了重置单例实例的方法：

```dart
class Localization with ChangeNotifier {
  static Localization? _instance;

  factory Localization() {
    _instance ??= Localization._internal();
    return _instance!;
  }

  /// 重置单例实例（仅用于测试）
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  @override
  void dispose() {
    _translations.clear();
    super.dispose();
  }
}
```

### 2. 统一 Mock 数据设置

在测试的 `setUpAll` 中设置统一的 mock 翻译数据，包含所有测试需要的翻译：

```dart
setUpAll(() {
  // 设置统一的 mock 翻译数据，供所有测试使用
  const String mockTranslationJson = '''
  {
    "ui": {
      "buttons": {"light_fire": "点火", "stoke_fire": "添柴"},
      "modules": {"room": "房间", "outside": "外部"}
    },
    "buildings": {"trap": "陷阱", "cart": "手推车"},
    "crafting": {"wood_needed": "需要 {0} 个木材", "multiple_items": "制作 {0} 个 {1}"},
    "messages": {"welcome": "欢迎来到黑暗房间"},
    "logs": {"start": "开始", "complete": "完成", "error": "错误"}
  }
  ''';
  
  // 同时设置中文和英文翻译数据
});
```

### 3. 修改测试设置和清理

修改测试的 `setUp` 和 `tearDown` 方法：

```dart
setUp(() {
  SharedPreferences.setMockInitialValues({});
  // 重置单例实例以确保每个测试都有干净的状态
  Localization.resetInstance();
  localization = Localization();
});

tearDown(() {
  // 在测试结束时重置单例实例
  Localization.resetInstance();
});
```

### 4. 移除重复的 Mock 设置

移除了各个测试组中重复的 mock 数据设置，统一使用 `setUpAll` 中的设置。

## 修改文件

- `lib/core/localization.dart`: 添加单例重置支持和 dispose 方法
- `test/localization_test.dart`: 统一 mock 数据设置，修改测试设置和清理

## 测试结果

修复后，所有 14 个测试用例全部通过：

```
00:02 +14: All tests passed!
```

## 关键改进

1. **单例模式兼容性**: 通过 `resetInstance()` 方法解决了单例在测试环境中的状态共享问题
2. **数据一致性**: 统一的 mock 数据确保所有测试都能访问到需要的翻译
3. **最小化修改**: 只修改必要的部分，保持原有功能不变
4. **测试隔离**: 每个测试都有干净的初始状态，避免测试间的相互影响

## 更新时间

2025-01-09

## 相关文件

- [Localization 类](../../lib/core/localization.dart)
- [Localization 测试](../../test/localization_test.dart)
