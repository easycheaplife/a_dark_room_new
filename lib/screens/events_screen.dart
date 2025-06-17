import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/events.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../widgets/game_button.dart';
import '../core/logger.dart';

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

                      // 显示实际生成的战利品
                      if (events.showingLoot &&
                          events.currentLoot.isNotEmpty) ...[
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
                        ...events.currentLoot.entries.map((entry) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_getItemDisplayName(entry.key)} [${entry.value}]',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    events.getLoot(
                                      entry.key,
                                      entry.value,
                                      onBagFull: () {
                                        // 显示丢弃物品对话框
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text('背包空间不足'),
                                              content: SizedBox(
                                                width: 300,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                        '请选择要丢弃的物品以腾出空间：'),
                                                    ...Path()
                                                        .outfit
                                                        .entries
                                                        .where(
                                                            (e) => e.value > 0)
                                                        .map((e) => ListTile(
                                                              title: Text(
                                                                  '${_getItemDisplayName(e.key)} x${e.value}'),
                                                              trailing:
                                                                  ElevatedButton(
                                                                onPressed: () {
                                                                  Path().outfit[
                                                                          e.key] =
                                                                      e.value -
                                                                          1;
                                                                  StateManager().set(
                                                                      'outfit["${e.key}"]',
                                                                      Path().outfit[
                                                                          e.key]);
                                                                  Path()
                                                                      .updateOutfitting();
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child:
                                                                    const Text(
                                                                        '丢弃1'),
                                                              ),
                                                            )),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('关闭'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Colors.black),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                  child: const Text('拿取',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        // 拿取所有按钮
                        if (events.currentLoot.isNotEmpty)
                          ElevatedButton(
                            onPressed: () {
                              // 拿取所有物品
                              final lootEntries =
                                  List.from(events.currentLoot.entries);
                              for (final entry in lootEntries) {
                                events.getLoot(
                                  entry.key,
                                  entry.value,
                                  onBagFull: () {
                                    // 显示丢弃物品对话框
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('背包空间不足'),
                                          content: SizedBox(
                                            width: 300,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('请选择要丢弃的物品以腾出空间：'),
                                                ...Path()
                                                    .outfit
                                                    .entries
                                                    .where((e) => e.value > 0)
                                                    .map((e) => ListTile(
                                                          title: Text(
                                                              '${_getItemDisplayName(e.key)} x${e.value}'),
                                                          trailing:
                                                              ElevatedButton(
                                                            onPressed: () {
                                                              Path().outfit[
                                                                      e.key] =
                                                                  e.value - 1;
                                                              StateManager().set(
                                                                  'outfit["${e.key}"]',
                                                                  Path().outfit[
                                                                      e.key]);
                                                              Path()
                                                                  .updateOutfitting();
                                                              // 关闭对话框
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              // 重新打开对话框以刷新显示
                                                              showDialog(
                                                                context: context,
                                                                builder: (context) {
                                                                  return AlertDialog(
                                                                    title: const Text('背包空间不足'),
                                                                    content: SizedBox(
                                                                      width: 300,
                                                                      child: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          const Text('请选择要丢弃的物品以腾出空间：'),
                                                                          ...Path()
                                                                              .outfit
                                                                              .entries
                                                                              .where((e) => e.value > 0)
                                                                              .map((e) => ListTile(
                                                                                    title: Text('${_getItemDisplayName(e.key)} x${e.value}'),
                                                                                    trailing: ElevatedButton(
                                                                                      onPressed: () {
                                                                                        Path().outfit[e.key] = e.value - 1;
                                                                                        StateManager().set('outfit["${e.key}"]', Path().outfit[e.key]);
                                                                                        Path().updateOutfitting();
                                                                                        Navigator.of(context).pop();
                                                                                        // 递归调用以刷新显示
                                                                                        showDialog(
                                                                                          context: context,
                                                                                          builder: (context) {
                                                                                            return AlertDialog(
                                                                                              title: const Text('背包空间不足'),
                                                                                              content: SizedBox(
                                                                                                width: 300,
                                                                                                child: Column(
                                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                                  children: [
                                                                                                    const Text('请选择要丢弃的物品以腾出空间：'),
                                                                                                    ...Path()
                                                                                                        .outfit
                                                                                                        .entries
                                                                                                        .where((e) => e.value > 0)
                                                                                                        .map((e) => ListTile(
                                                                                                              title: Text('${_getItemDisplayName(e.key)} x${e.value}'),
                                                                                                              trailing: ElevatedButton(
                                                                                                                onPressed: () {
                                                                                                                  // 同样的逻辑，但不再递归调用
                                                                                                                  Path().outfit[e.key] = e.value - 1;
                                                                                                                  StateManager().set('outfit["${e.key}"]', Path().outfit[e.key]);
                                                                                                                  Path().updateOutfitting();
                                                                                                                  Navigator.of(context).pop();
                                                                                                                  // 再次打开对话框
                                                                                                                  showDialog(
                                                                                                                    context: context,
                                                                                                                    builder: (context) => AlertDialog(
                                                                                                                      title: const Text('背包空间不足'),
                                                                                                                      content: SizedBox(
                                                                                                                        width: 300,
                                                                                                                        child: Column(
                                                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                                                          children: [
                                                                                                                            const Text('请选择要丢弃的物品以腾出空间：'),
                                                                                                                            ...Path()
                                                                                                                                .outfit
                                                                                                                                .entries
                                                                                                                                .where((e) => e.value > 0)
                                                                                                                                .map((e) => ListTile(
                                                                                                                                      title: Text('${_getItemDisplayName(e.key)} x${e.value}'),
                                                                                                                                      trailing: ElevatedButton(
                                                                                                                                        onPressed: () {
                                                                                                                                          Path().outfit[e.key] = e.value - 1;
                                                                                                                                          StateManager().set('outfit["${e.key}"]', Path().outfit[e.key]);
                                                                                                                                          Path().updateOutfitting();
                                                                                                                                          Navigator.of(context).pop();
                                                                                                                                        },
                                                                                                                                        child: const Text('丢弃1'),
                                                                                                                                      ),
                                                                                                                                    )),
                                                                                                                          ],
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                      actions: [
                                                                                                                        TextButton(
                                                                                                                          onPressed: () {
                                                                                                                            Navigator.of(context).pop();
                                                                                                                          },
                                                                                                                          child: const Text('关闭'),
                                                                                                                        ),
                                                                                                                      ],
                                                                                                                    ),
                                                                                                                  );
                                                                                                                },
                                                                                                                child: const Text('丢弃1'),
                                                                                                              ),
                                                                                                            )),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              actions: [
                                                                                                TextButton(
                                                                                                  onPressed: () {
                                                                                                    Navigator.of(context).pop();
                                                                                                  },
                                                                                                  child: const Text('关闭'),
                                                                                                ),
                                                                                              ],
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      },
                                                                                      child: const Text('丢弃1'),
                                                                                    ),
                                                                                  )),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop();
                                                                        },
                                                                        child: const Text('关闭'),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            child: const Text(
                                                                '丢弃1'),
                                                          ),
                                                        )),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('关闭'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                            ),
                            child: const Text('拿走一切'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 按钮区域
              if (scene['buttons'] != null)
                _buildButtons(
                    context, events, scene['buttons'] as Map<String, dynamic>),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建按钮
  Widget _buildButtons(
      BuildContext context, Events events, Map<String, dynamic> buttons) {
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
  void _handleButtonPress(
      Events events, String buttonKey, Map<String, dynamic> buttonConfig) {
    Logger.info('🎮 事件按钮点击: $buttonKey');

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
        // 随机选择场景 - 使用累积概率
        final random = Random().nextDouble();
        String? selectedScene;

        // 将概率键转换为数字并排序
        final sortedEntries = nextScene.entries.toList()
          ..sort((a, b) => (double.tryParse(a.key) ?? 0.0)
              .compareTo(double.tryParse(b.key) ?? 0.0));

        for (final entry in sortedEntries) {
          final chance = double.tryParse(entry.key) ?? 0.0;
          if (random <= chance) {
            selectedScene = entry.value;
            break;
          }
        }

        // 如果没有选中任何场景，选择最后一个（概率为1.0的场景）
        if (selectedScene == null && sortedEntries.isNotEmpty) {
          selectedScene = sortedEntries.last.value;
        }

        if (selectedScene != null) {
          events.loadScene(selectedScene);
        }
      }
    }
  }

  /// 获取物品显示名称
  String _getItemDisplayName(String itemName) {
    switch (itemName) {
      case 'fur':
        return '毛皮';
      case 'meat':
        return '肉';
      case 'cured meat':
        return '熏肉';
      case 'scales':
        return '鳞片';
      case 'teeth':
        return '牙齿';
      case 'cloth':
        return '布料';
      case 'leather':
        return '皮革';
      case 'iron':
        return '铁';
      case 'steel':
        return '钢';
      case 'coal':
        return '煤炭';
      case 'sulphur':
        return '硫磺';
      case 'medicine':
        return '药剂';
      case 'bullets':
        return '子弹';
      case 'energy cell':
        return '能量电池';
      case 'laser rifle':
        return '激光步枪';
      case 'rifle':
        return '步枪';
      case 'bayonet':
        return '刺刀';
      case 'grenade':
        return '手榴弹';
      case 'bolas':
        return '流星锤';
      case 'alien alloy':
        return '外星合金';
      case 'charm':
        return '护身符';
      default:
        return itemName;
    }
  }
}
