# 游戏设置中添加音频开关功能

## 概述

在游戏设置界面中添加了音频开关功能，允许玩家控制游戏中的背景音乐和音效播放。这个功能完全集成了现有的音频系统，提供了用户友好的音频控制选项。

## 实现内容

### 1. 本地化文本更新

#### 中文本地化 (assets/lang/zh.json)
```json
"settings": {
  "audio_section": "🔊 音频设置",
  "audio_enabled": "启用音频",
  "audio_disabled": "禁用音频", 
  "audio_description": "控制游戏中的背景音乐和音效播放"
}
```

#### 英文本地化 (assets/lang/en.json)
```json
"settings": {
  "audio_section": "🔊 audio settings",
  "audio_enabled": "audio enabled",
  "audio_disabled": "audio disabled",
  "audio_description": "control background music and sound effects in the game"
}
```

### 2. 设置界面更新

#### 新增音频设置区域
- 位置：保存状态信息和导入导出提示之间
- 样式：绿色边框容器，与其他设置区域保持一致的设计风格
- 功能：开关控件 + 状态文本显示

#### 核心功能
```dart
Widget _buildAudioSection(StateManager stateManager) {
  return Consumer<Localization>(
    builder: (context, localization, child) {
      final soundOn = stateManager.get('config.soundOn', true) == true;
      
      return Container(
        // 音频设置区域UI
        child: Row(
          children: [
            Switch(
              value: soundOn,
              onChanged: (value) async {
                await Engine().toggleVolume(value);
              },
            ),
            Text(soundOn ? '启用音频' : '禁用音频'),
          ],
        ),
      );
    },
  );
}
```

### 3. 集成现有音频系统

#### 与Engine.toggleVolume()集成
- 直接调用Engine类的toggleVolume方法
- 自动保存音频设置到StateManager
- 实时更新AudioEngine的主音量

#### 状态管理
- 音频开关状态存储在`config.soundOn`
- 默认值为true（启用音频）
- 设置变更立即生效并保存

## 技术特点

### 1. 用户体验优化
- **即时反馈**：开关切换立即生效，无需重启游戏
- **状态显示**：清晰显示当前音频状态（启用/禁用）
- **一致性设计**：与现有设置界面风格保持一致

### 2. 代码复用
- **最小化修改**：复用现有的Engine.toggleVolume()方法
- **统一管理**：使用现有的StateManager进行状态存储
- **本地化支持**：完全支持中英文切换

### 3. 系统集成
- **音频引擎集成**：直接控制AudioEngine的主音量
- **状态持久化**：音频设置自动保存，重启游戏后保持
- **实时更新**：UI状态与音频系统状态同步

## 测试验证

### 功能测试
1. ✅ 音频开关正常显示在设置界面
2. ✅ 开关状态正确反映当前音频设置
3. ✅ 切换开关立即生效
4. ✅ 音频设置正确保存和恢复
5. ✅ 中英文本地化正常工作

### 集成测试
1. ✅ 与现有音频系统无冲突
2. ✅ 不影响其他设置功能
3. ✅ 游戏启动时正确加载音频设置
4. ✅ 音频开关与游戏内音频播放同步

## 使用说明

### 访问音频设置
1. 点击游戏界面右上角的设置按钮（⚙️）
2. 在设置界面中找到"🔊 音频设置"区域
3. 使用开关控件切换音频开启/关闭状态

### 音频控制
- **开启音频**：开关向右，显示"启用音频"，游戏播放背景音乐和音效
- **关闭音频**：开关向左，显示"禁用音频"，游戏静音

## 技术实现细节

### 状态管理流程
```
用户切换开关 → Engine.toggleVolume() → StateManager.set('config.soundOn') → AudioEngine.setMasterVolume() → UI更新
```

### 音频控制逻辑
- 启用音频：主音量设置为1.0
- 禁用音频：主音量设置为0.0
- 音量变化有500ms的淡入淡出效果

## 更新日志

- **2025-01-07**: 完成音频开关功能实现
- **2025-01-07**: 添加中英文本地化支持
- **2025-01-07**: 集成到设置界面并测试验证

---

*此功能增强了游戏的用户体验，为玩家提供了便捷的音频控制选项，同时保持了与原游戏音频系统的完全兼容性。*
