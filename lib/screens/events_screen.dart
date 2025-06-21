import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/events.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/game_button.dart';
import '../core/logger.dart';

/// 事件界面 - 显示Setpiece事件（如洞穴探索、废弃城镇等）
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // 丢弃界面相关状态
  bool _showDropInterface = false;
  String? _pendingLootKey;
  int? _pendingLootValue;

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
                _getLocalizedEventTitle(event),
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
                              _getLocalizedEventText(text.toString()),
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

                        // 根据是否显示丢弃界面来决定布局
                        if (_showDropInterface) ...[
                          // 显示丢弃界面
                          _buildDropInterface(context, events),
                        ] else ...[
                          // 显示正常的战利品界面
                          Text(
                            _getLocalizedText('发现了：', 'found:'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 战利品表格布局 - 与战斗结算界面保持一致
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2), // 物品名称列
                                1: FlexColumnWidth(1), // 按钮列
                              },
                              children: events.currentLoot.entries.map((entry) {
                                return TableRow(
                                  children: [
                                    // 左列：物品名称和数量
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        '${_getItemDisplayName(entry.key)} [${entry.value}]',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    // 右列：带走所有按钮
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        color: Colors.white,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          events.getLoot(
                                            entry.key,
                                            entry.value,
                                            onBagFull: () {
                                              // 显示丢弃界面
                                              setState(() {
                                                _showDropInterface = true;
                                                _pendingLootKey = entry.key;
                                                _pendingLootValue = entry.value;
                                              });
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          side: const BorderSide(
                                              color: Colors.black),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          minimumSize: const Size(0, 24),
                                        ),
                                        child: Text(
                                          _getLocalizedText('带走 所有', 'take all'),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
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
          text: _getLocalizedButtonText(text),
          onPressed: () => _handleButtonPress(events, entry.key, buttonConfig),
          width: 120,
        );
      }).toList(),
    );
  }

  /// 处理按钮点击
  void _handleButtonPress(
      Events events, String buttonKey, Map<String, dynamic> buttonConfig) {
    final localization = Localization();
    Logger.info('🎮 ${localization.translateLog('event_button_clicked')}: $buttonKey');

    // 使用事件系统的统一按钮处理逻辑
    events.handleButtonClick(buttonKey, buttonConfig);
  }

  /// 构建丢弃界面 - 参考战斗结算界面的丢弃界面
  Widget _buildDropInterface(BuildContext context, Events events) {
    final outfitItems =
        Path().outfit.entries.where((e) => e.value > 0).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 获得区域 - 显示待拾取的物品但按钮显示"带走 0"
        if (_pendingLootKey != null && _pendingLootValue != null) ...[
          const Text(
            '获得:',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: Colors.white,
                      ),
                      child: Text(
                        '${_getItemDisplayName(_pendingLootKey!)} [${_pendingLootValue!}]',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: Colors.white,
                      ),
                      child: ElevatedButton(
                        onPressed: null, // 禁用状态
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.grey[600],
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 24),
                        ),
                        child: const Text(
                          '带走 0',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 丢弃区域 - 参考原游戏的边框样式
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 丢弃标题
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black)),
                ),
                child: const Text(
                  '丢弃:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 背包物品列表
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: outfitItems.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(color: Colors.black, width: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${_getItemDisplayName(entry.key)} x${entry.value}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // 丢弃一个物品
                                Path().outfit[entry.key] = entry.value - 1;
                                StateManager().set('outfit["${entry.key}"]',
                                    Path().outfit[entry.key]);
                                Path().updateOutfitting();

                                // 尝试拾取待处理的物品
                                if (_pendingLootKey != null &&
                                    _pendingLootValue != null) {
                                  events.getLoot(
                                      _pendingLootKey!, _pendingLootValue!);
                                }

                                // 关闭丢弃界面
                                setState(() {
                                  _showDropInterface = false;
                                  _pendingLootKey = null;
                                  _pendingLootValue = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                minimumSize: const Size(24, 20),
                              ),
                              child: const Text(
                                '一',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 一无所获按钮
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showDropInterface = false;
                      _pendingLootKey = null;
                      _pendingLootValue = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    '一无所获',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 获取物品显示名称
  String _getItemDisplayName(String itemName) {
    final localization = Localization();
    final translatedName = localization.translate('resources.$itemName');

    // 如果翻译存在且不等于原键名，返回翻译
    if (translatedName != 'resources.$itemName') {
      return translatedName;
    }

    // 否则返回原名称
    return itemName;
  }

  /// 获取本地化的事件标题
  String _getLocalizedEventTitle(Map<String, dynamic> event) {
    final localization = Localization();
    final title = event['title'] ?? '事件';

    // 尝试从房间事件翻译中获取标题
    String translatedTitle = localization.translate('events.room_events.$title.title');
    if (translatedTitle != 'events.room_events.$title.title') {
      return translatedTitle;
    }

    // 尝试从事件标题翻译中获取
    translatedTitle = localization.translate('events.titles.$title');
    if (translatedTitle != 'events.titles.$title') {
      return translatedTitle;
    }

    // 尝试从通用事件翻译中获取
    translatedTitle = localization.translate('events.$title');
    if (translatedTitle != 'events.$title') {
      return translatedTitle;
    }

    // 如果没有找到翻译，返回原标题
    return title;
  }

  /// 获取本地化的事件文本
  String _getLocalizedEventText(String text) {
    final localization = Localization();

    // 定义文本映射 - 将中文文本映射到翻译键
    final textMappings = {
      '一个陌生人出现在火堆旁。': 'events.stranger_event.text1',
      '他穿着厚重的斗篷，看不清面容。': 'events.stranger_event.text2',
      '"我需要一些木材来修理我的工具，"他说，"我可以给你一些回报。"': 'events.stranger_event.text3',
      '陌生人接过木材，从斗篷下取出一些物品。': 'events.stranger_event.trade_text1',
      '"这些应该对你有用，"他说着消失在黑暗中。': 'events.stranger_event.trade_text2',
      '陌生人点点头，没有说什么。': 'events.stranger_event.decline_text1',
      '他转身离开，消失在夜色中。': 'events.stranger_event.decline_text2',
      '一个神秘的陌生人从黑暗中走来。': 'events.mysterious_wanderer_event.text1',
      '他的眼中闪着奇异的光芒。': 'events.mysterious_wanderer_event.text2',
      '"我有些东西可能对你有用。"他说道。': 'events.mysterious_wanderer_event.text3',

      // 房间事件
      '建造者看起来更加熟练了。': 'events.room_events.builder.text1',
      '他开始制作更复杂的工具。': 'events.room_events.builder.text2',
      '火光在黑暗中摇曳。': 'events.room_events.firekeeper.text1',
      '一个身影从阴影中走出。': 'events.room_events.firekeeper.text2',
      '建造者已经到来。': 'events.room_events.firekeeper.text3',
      '一个游牧商人走近火堆。': 'events.room_events.nomad.text1',
      '他提议用毛皮换取有用的物品。': 'events.room_events.nomad.text2',
      '一只流浪猫走进房间。': 'events.room_events.straycat.text1',
      '它看起来又饿又冷。': 'events.room_events.straycat.text2',
      '一个受伤的人跌跌撞撞地走进房间。': 'events.room_events.wounded.text1',
      '他需要医疗救助。': 'events.room_events.wounded.text2',
      '奇怪的声音从外面传来。': 'events.room_events.noisesOutside.text1',
      '黑暗中有什么东西在移动。': 'events.room_events.noisesOutside.text2',
    };

    // 查找对应的翻译键
    if (textMappings.containsKey(text)) {
      final translatedText = localization.translate(textMappings[text]!);
      if (translatedText != textMappings[text]) {
        return translatedText;
      }
    }

    // 如果没有找到映射，返回原文本
    return text;
  }

  /// 获取本地化的按钮文本
  String _getLocalizedButtonText(String text) {
    final localization = Localization();

    // 定义按钮文本映射
    final buttonMappings = {
      '交易': 'events.stranger_event.trade_button',
      '拒绝': 'events.stranger_event.decline_button',
      '继续': 'events.stranger_event.continue_button',
      '与他交谈': 'events.mysterious_wanderer_event.talk_button',
      '忽视他': 'events.mysterious_wanderer_event.ignore_button',
    };

    // 查找对应的翻译键
    if (buttonMappings.containsKey(text)) {
      final translatedText = localization.translate(buttonMappings[text]!);
      if (translatedText != buttonMappings[text]) {
        return translatedText;
      }
    }

    // 尝试从通用按钮翻译中获取
    final translatedButton = localization.translate('ui.buttons.$text');
    if (translatedButton != 'ui.buttons.$text') {
      return translatedButton;
    }

    // 如果没有找到翻译，返回原文本
    return text;
  }

  /// 获取本地化文本 - 根据当前语言返回中文或英文
  String _getLocalizedText(String chineseText, String englishText) {
    final localization = Localization();

    // 定义文本映射
    final textMappings = {
      '发现了：': 'messages.found',
      '带走 所有': 'ui.buttons.take_all',
    };

    // 如果是中文文本，尝试查找翻译
    if (textMappings.containsKey(chineseText)) {
      final translatedText = localization.translate(textMappings[chineseText]!);
      if (translatedText != textMappings[chineseText]) {
        return translatedText;
      }
    }

    // 否则根据当前语言返回对应文本
    return localization.currentLanguage == 'zh' ? chineseText : englishText;
  }
}
