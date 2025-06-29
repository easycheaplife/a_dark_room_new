# 破旧星舰页签布局一致性优化

**日期**: 2025-06-29  
**类型**: 功能优化  
**状态**: 已完成  

## 🎯 优化目标

根据用户要求，修改破旧星舰页签的布局风格，使其与漫漫尘途页签保持一致：

1. **库存位置一致性** - 破旧星舰页签的库存位置与漫漫尘途页签保持一致
2. **布局风格一致性** - 破旧星舰页签的整体布局风格与漫漫尘途页签一致
3. **代码复用** - 尽量复用现有的统一库存容器组件

## 🔍 问题分析

### 原有布局问题

**破旧星舰页签原布局**：
- 使用垂直排列（Column）布局
- 库存显示在页面底部
- 整体采用卡片式设计风格

**漫漫尘途页签布局**：
- 使用绝对定位（Stack + Positioned）布局
- 库存显示在页面右上角（right: 0, top: 0）
- 左侧显示功能区域（装备、出发按钮等）
- 采用原游戏风格的边框设计

### 一致性要求

用户明确要求：
1. 破旧星舰库存的位置和漫漫尘途的页签位置保持一致
2. 破旧星舰页签的布局风格和漫漫尘途一致
3. 尽量复用代码

## 🛠️ 修复实施

### 1. 修改整体布局结构

**文件**: `lib/screens/ship_screen.dart`

**修改前**：
```dart
return SingleChildScrollView(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildShipStatusSection(localization, shipStatus),
      const SizedBox(height: 20),
      _buildShipActionsSection(localization, shipStatus),
      const SizedBox(height: 20),
      _buildStoresContainer(),
    ],
  ),
);
```

**修改后**：
```dart
return Container(
  width: double.infinity,
  height: double.infinity,
  color: Colors.white,
  child: SingleChildScrollView(
    child: SizedBox(
      width: double.infinity,
      height: 800, // 设置足够的高度以容纳所有内容
      child: Stack(
        children: [
          // 左侧：飞船状态和操作按钮区域 - 绝对定位，与漫漫尘途保持一致
          Positioned(
            left: 10,
            top: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShipStatusSection(localization, shipStatus),
                const SizedBox(height: 20),
                _buildShipActionsSection(localization, shipStatus),
              ],
            ),
          ),
          // 库存容器 - 绝对定位，与漫漫尘途完全一致的位置: top: 0px, right: 0px
          Positioned(
            right: 0,
            top: 0,
            child: _buildStoresContainer(),
          ),
        ],
      ),
    ),
  ),
);
```

### 2. 修改飞船状态区域样式

**参考漫漫尘途页签的装备区域样式**：

**修改前**：
```dart
return Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Colors.grey[900],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[700]!),
  ),
  // ...
);
```

**修改后**：
```dart
return Container(
  width: 300, // 固定宽度，与漫漫尘途装备区域保持一致
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.black, width: 1), // 与原游戏保持一致的边框样式
  ),
  child: Stack(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题 - 模拟原游戏的 data-legend 属性
          Container(
            transform: Matrix4.translationValues(-8, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                localization.translate('ship.status.title'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),
          // ... 其他内容
        ],
      ),
    ],
  ),
);
```

### 3. 修改文本样式

将所有文本样式改为与原游戏一致：
- 字体：`Times New Roman`
- 颜色：黑色（`Colors.black`）
- 背景：白色（`Colors.white`）

### 4. 修改按钮样式

**修改前**：
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: isSpecial
      ? (enabled ? Colors.red[700] : Colors.grey[800])
      : (enabled ? Colors.blue[700] : Colors.grey[800]),
    foregroundColor: Colors.white,
    // ...
  ),
  // ...
)
```

**修改后**：
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: enabled ? Colors.white : Colors.grey[300],
    foregroundColor: enabled ? Colors.black : Colors.grey[600],
    side: BorderSide(
      color: enabled ? Colors.black : Colors.grey[500]!,
      width: 1,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0), // 方形按钮，符合原游戏风格
    ),
    // ...
  ),
  // ...
)
```

### 5. 添加本地化键值

**文件**: `assets/lang/zh.json` 和 `assets/lang/en.json`

添加缺失的 `ship.status.title` 键值：

**中文**：
```json
"status": {
  "title": "飞船状态",
  "hull": "船体",
  "engine": "引擎"
},
```

**英文**：
```json
"status": {
  "title": "ship status",
  "hull": "hull",
  "engine": "engine"
},
```

## ✅ 优化效果

### 布局一致性
- ✅ 库存容器位置与漫漫尘途页签完全一致（right: 0, top: 0）
- ✅ 左侧功能区域布局与漫漫尘途页签保持一致
- ✅ 整体采用Stack + Positioned绝对定位布局

### 视觉风格一致性
- ✅ 边框样式与原游戏保持一致（黑色1px边框）
- ✅ 文本样式统一使用Times New Roman字体
- ✅ 颜色方案与原游戏保持一致（黑白配色）
- ✅ 按钮样式符合原游戏风格（方形、黑边框）

### 代码复用
- ✅ 继续使用UnifiedStoresContainer统一库存容器组件
- ✅ 保持与其他页签的代码一致性
- ✅ 遵循最小化修改原则

## 📋 修改文件清单

### 主要修改文件
- `lib/screens/ship_screen.dart` - 修改布局结构和样式
- `assets/lang/zh.json` - 添加ship.status.title中文翻译
- `assets/lang/en.json` - 添加ship.status.title英文翻译

### 相关文件
- `lib/widgets/unified_stores_container.dart` - 统一库存容器（复用）
- `lib/screens/path_screen.dart` - 漫漫尘途页签（参考布局）

## 🎯 预期结果

修改完成后：
- ✅ 破旧星舰页签的库存位置与漫漫尘途页签完全一致
- ✅ 破旧星舰页签的布局风格与漫漫尘途页签保持一致
- ✅ 界面视觉效果符合原游戏风格
- ✅ 代码复用性良好，维护性强

---

*本优化确保了破旧星舰页签与漫漫尘途页签的布局一致性，提升了用户体验的连贯性。*
