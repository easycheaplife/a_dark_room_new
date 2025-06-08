import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/events.dart';
import '../widgets/game_button.dart';

/// 事件界面 - 显示Setpiece事件（如洞穴探索、废弃城镇等）
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Events>(
      builder: (context, events, child) {
        final activeEvent = events.activeEvent();
        
        // 如果没有活动事件，不显示界面
        if (activeEvent == null || events.activeScene == null) {
          return const SizedBox.shrink();
        }

        final scene = activeEvent['scenes'][events.activeScene];
        if (scene == null) {
          return const SizedBox.shrink();
        }

        // 如果是战斗场景，由CombatScreen处理
        if (scene['combat'] == true) {
          return const SizedBox.shrink();
        }

        return _buildEventDialog(context, events, activeEvent, scene);
      },
    );
  }

  /// 构建事件对话框
  Widget _buildEventDialog(BuildContext context, Events events, 
      Map<String, dynamic> event, Map<String, dynamic> scene) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 600,
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 事件标题
              Text(
                event['title'] ?? '事件',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 场景文本
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (scene['text'] != null) ...[
                        for (final text in scene['text'] as List<dynamic>)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              text.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                      
                      // 显示战利品
                      if (scene['loot'] != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          '发现了：',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final entry in (scene['loot'] as Map<String, dynamic>).entries)
                          Text(
                            '${entry.key}: ${_getLootAmount(entry.value)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 按钮区域
              if (scene['buttons'] != null)
                _buildButtons(context, events, scene['buttons'] as Map<String, dynamic>),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建按钮
  Widget _buildButtons(BuildContext context, Events events, Map<String, dynamic> buttons) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons.entries.map((entry) {
        final buttonConfig = entry.value as Map<String, dynamic>;
        final text = buttonConfig['text'] ?? entry.key;
        
        return GameButton(
          text: text,
          onPressed: () => _handleButtonPress(events, entry.key, buttonConfig),
          width: 120,
        );
      }).toList(),
    );
  }

  /// 处理按钮点击
  void _handleButtonPress(Events events, String buttonKey, Map<String, dynamic> buttonConfig) {
    print('🎮 事件按钮点击: $buttonKey');
    
    // 处理冷却时间
    final cooldown = buttonConfig['cooldown'];
    if (cooldown != null) {
      // 这里可以添加冷却时间处理逻辑
    }
    
    // 处理下一个场景
    final nextScene = buttonConfig['nextScene'];
    if (nextScene != null) {
      if (nextScene == 'finish') {
        // 结束事件
        events.endEvent();
      } else if (nextScene is String) {
        // 加载指定场景
        events.loadScene(nextScene);
      } else if (nextScene is Map<String, dynamic>) {
        // 随机选择场景
        final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
        String? selectedScene;
        
        for (final entry in nextScene.entries) {
          final chance = double.tryParse(entry.key) ?? 0.0;
          if (random <= chance) {
            selectedScene = entry.value;
            break;
          }
        }
        
        if (selectedScene != null) {
          events.loadScene(selectedScene);
        }
      }
    }
  }

  /// 获取战利品数量描述
  String _getLootAmount(dynamic lootConfig) {
    if (lootConfig is Map<String, dynamic>) {
      final min = lootConfig['min'] ?? 1;
      final max = lootConfig['max'] ?? 1;
      final chance = lootConfig['chance'] ?? 1.0;
      
      if (min == max) {
        return '$min (${(chance * 100).toInt()}%几率)';
      } else {
        return '$min-$max (${(chance * 100).toInt()}%几率)';
      }
    }
    return lootConfig.toString();
  }
}
