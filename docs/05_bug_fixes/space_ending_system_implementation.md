# 太空模块胜利失败系统实现

## 问题描述

用户要求实现A Dark Room游戏中的太空飞行功能，包括：
1. 点击起飞后播放飞行动画
2. 小行星从天而降，如果命中飞船则飞船血量减一
3. 如果飞船血量归零则失败
4. 如果到达太空（60km高度）则胜利
5. 显示胜利/失败界面，包含分数和重新开始选项

## 解决方案

### 1. 完善太空模块的胜利失败逻辑

**文件**: `lib/modules/space.dart`

**主要修改**：
- 添加了完整的`endGame()`方法处理胜利逻辑
- 修改了`crash()`方法处理失败逻辑
- 添加了`_saveGameScore()`方法保存分数到声望系统
- 修改高度检测逻辑，当达到60km时触发胜利
- 添加了结束对话框显示标志

**关键代码**：
```dart
/// 游戏结束 - 胜利
void endGame() {
  if (done) return;
  done = true;
  _clearTimers();
  
  // 标记游戏完成
  final sm = StateManager();
  sm.set('game.completed', true);
  sm.set('game.won', true);
  
  // 保存分数和声望数据
  _saveGameScore();
  
  // 显示胜利动画和结束选项
  Timer(Duration(seconds: 2), () {
    showEndingOptions(true);
  });
}
```

### 2. 创建游戏结束对话框组件

**文件**: `lib/widgets/game_ending_dialog.dart`

**功能特点**：
- 显示胜利/失败标题
- 显示当前游戏分数和总分数
- 显示分数等级
- 提供重新开始按钮
- 包含应用推广信息（iOS/Android按钮）
- 使用淡入动画效果

**界面设计**：
- 黑色背景，白色边框，符合原游戏风格
- 使用Times New Roman字体保持一致性
- 响应式布局，适配不同屏幕尺寸

### 3. 集成结束对话框到太空界面

**文件**: `lib/screens/space_screen.dart`

**主要修改**：
- 添加了状态监听，检测是否需要显示结束对话框
- 使用`Consumer3`监听StateManager状态变化
- 在`_checkShowEndingDialog`方法中处理对话框显示逻辑
- 优化小行星显示，使用原游戏的字符显示方式

**小行星显示优化**：
```dart
child: Text(
  asteroid['character'], // 使用 #、$、%、&、H 字符
  style: const TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Times New Roman',
    fontWeight: FontWeight.bold,
  ),
),
```

### 4. 添加本地化支持

**文件**: `assets/lang/zh.json` 和 `assets/lang/en.json`

**新增键值**：
```json
"ending": {
  "victory_title": "胜利！",
  "defeat_title": "失败",
  "current_score": "本局得分: {score}",
  "total_score": "总分: {score}",
  "rank": "等级: {rank}",
  "restart": "重新开始",
  "app_promotion": "扩展故事。备用结局。幕后评论。获取应用。",
  "ios": "iOS",
  "android": "Android"
}
```

## 技术实现细节

### 胜利条件
- 当高度达到60km时自动触发胜利
- 调用`endGame()`方法处理胜利逻辑

### 失败条件
- 当飞船船体血量降至0时触发失败
- 调用`crash()`方法处理失败逻辑

### 分数系统集成
- 使用现有的Score模块计算分数
- 通过Prestige模块保存分数到声望系统
- 支持分数累计和等级评定

### 动画和视觉效果
- 小行星使用原游戏的字符显示（#、$、%、&、H）
- 结束对话框使用淡入动画
- 保持原游戏的黑白配色风格

## 当前状态

### 已完成功能
1. ✅ 太空模块的胜利失败逻辑已实现
2. ✅ 游戏结束对话框组件已创建
3. ✅ 本地化文本已添加
4. ✅ 小行星显示优化（使用字符显示）
5. ✅ 分数保存和声望系统集成

### 待解决问题
1. ❌ Space模块的onArrival方法调用错误
   - 错误信息：Dynamic call with too many positional arguments. Expected: 0 Actual: 1
   - 原因：Engine.travelTo方法传递参数1，但Space.onArrival方法签名不匹配
   - 解决方案：需要检查方法签名一致性

2. ❌ 结束对话框显示逻辑需要测试
   - 需要验证StateManager状态监听是否正常工作
   - 需要测试胜利和失败场景的对话框显示

## 测试验证

1. **胜利测试**：飞船到达60km高度时应显示胜利界面
2. **失败测试**：飞船被小行星击中血量归零时应显示失败界面
3. **分数测试**：结束界面应正确显示当前分数和总分数
4. **重新开始测试**：点击重新开始按钮应清除存档并重新开始游戏
5. **本地化测试**：切换语言时界面文本应正确显示
6. **起飞测试**：点击起飞按钮应正常进入太空模块

## 参考原游戏

实现完全参考原游戏`adarkroom/script/space.js`中的逻辑：
- `endGame()`方法的胜利处理
- `crash()`方法的失败处理
- `showEndingOptions()`的结束界面显示
- 小行星字符和动画效果

## 后续优化

1. 添加音效支持（撞击声、胜利音乐等）
2. 优化小行星动画的性能
3. 添加更多视觉特效（爆炸效果、星空动画等）
4. 支持触摸控制（移动设备）
