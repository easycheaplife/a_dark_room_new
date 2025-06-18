import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/events.dart';
import '../modules/world.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/logger.dart';

/// 战斗界面 - 完整翻译自原游戏的战斗系统
class CombatScreen extends StatelessWidget {
  const CombatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Events, World, Path>(
      builder: (context, events, world, path, child) {
        final combatStatus = events.getCombatStatus();
        final activeEvent = events.activeEvent();

        if (!combatStatus['inCombat'] || activeEvent == null) {
          return const SizedBox.shrink();
        }

        final scene = activeEvent['scenes'][events.activeScene];
        if (scene == null) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.white.withValues(alpha: 0.9), // 白色半透明背景
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight:
                    MediaQuery.of(context).size.height * 0.9, // 最大高度为屏幕的90%
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // 白色背景
                  border: Border.all(color: Colors.black), // 黑色边框
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black), // 黑色边框
                        ),
                      ),
                      child: Text(
                        activeEvent['title'] ?? '战斗',
                        style: const TextStyle(
                          color: Colors.black, // 黑色文字
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 通知文本 - 移到顶部，减少高度
                    if (scene['notification'] != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100], // 浅灰色背景
                          border: Border.all(color: Colors.grey), // 灰色边框
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          scene['notification'],
                          style: const TextStyle(
                            color: Colors.black, // 黑色文字
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // 战斗区域 - 减少高度
                    Container(
                      height: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        children: [
                          // 玩家 - 左侧
                          Positioned(
                            left: events.currentAnimation == 'melee_wanderer'
                                ? 80
                                : 40,
                            bottom: 10,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              child: _buildFighterDiv(
                                '流浪者',
                                '@',
                                world.health,
                                world.getMaxHealth(),
                                isPlayer: true,
                              ),
                            ),
                          ),

                          // 敌人 - 右侧
                          Positioned(
                            right: events.currentAnimation == 'melee_enemy'
                                ? 80
                                : 40,
                            bottom: 10,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              child: _buildFighterDiv(
                                scene['enemyName'] ?? '敌人',
                                scene['chara'] ?? 'E',
                                events.getCurrentEnemyHealth(),
                                scene['health'] ?? 10,
                                isPlayer: false,
                              ),
                            ),
                          ),

                          // 子弹动画
                          if (events.currentAnimation?.startsWith('ranged') ==
                              true)
                            _buildBulletAnimation(events.currentAnimation!),

                          // 伤害数字动画
                          if (events.currentAnimationDamage > 0)
                            _buildDamageText(events.currentAnimationDamage),
                        ],
                      ),
                    ),

                    // 根据战斗状态显示不同内容 - 紧凑布局
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: events.showingLoot
                            ? _buildLootInterface(context, events, scene)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 攻击按钮
                                  _buildAttackButtons(context, events, path),
                                  const SizedBox(height: 12),
                                  // 物品按钮
                                  _buildItemButtons(
                                      context, events, path, world),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建战斗者Div - 参考原游戏的createFighterDiv
  Widget _buildFighterDiv(String name, String chara, int hp, int maxHp,
      {required bool isPlayer}) {
    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 角色标签 - 参考原游戏的.label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.black, width: 1), // 黑色边框
            ),
            child: Text(
              chara,
              style: const TextStyle(
                color: Colors.black, // 黑色文字
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 血量显示 - 参考原游戏的.hp
          Text(
            '$hp/$maxHp',
            style: TextStyle(
              color: hp > maxHp * 0.5
                  ? Colors.green
                  : hp > maxHp * 0.25
                      ? Colors.orange
                      : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建子弹动画 - 参考原游戏的bullet
  Widget _buildBulletAnimation(String animationType) {
    final isWandererAttack = animationType == 'ranged_wanderer';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 800),
      left: isWandererAttack ? 150 : 50,
      right: isWandererAttack ? 50 : 150,
      bottom: 25,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.yellow,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'o',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建伤害数字动画
  Widget _buildDamageText(int damage) {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1000),
          opacity: 0.8,
          child: Text(
            '-$damage',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建攻击按钮
  Widget _buildAttackButtons(BuildContext context, Events events, Path path) {
    final availableWeapons = events.getAvailableWeapons();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '选择武器:',
          style: TextStyle(color: Colors.black, fontSize: 13), // 黑色文字
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: availableWeapons.map((weaponName) {
            return ElevatedButton(
              onPressed: () => events.useWeapon(weaponName),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200], // 浅灰色背景
                foregroundColor: Colors.black, // 黑色文字
                side: const BorderSide(color: Colors.black), // 黑色边框
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32), // 减少最小高度
              ),
              child: Text(
                _getWeaponDisplayName(weaponName),
                style: const TextStyle(fontSize: 11),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建物品按钮
  Widget _buildItemButtons(
      BuildContext context, Events events, Path path, World world) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        // 吃肉
        if ((path.outfit['cured meat'] ?? 0) > 0)
          ElevatedButton(
            onPressed: () => events.eatMeat(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[100], // 浅棕色背景
              foregroundColor: Colors.black, // 黑色文字
              side: const BorderSide(color: Colors.brown), // 棕色边框
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32), // 减少最小高度
            ),
            child: Text(
              '吃肉 (${path.outfit['cured meat']})',
              style: const TextStyle(fontSize: 11),
            ),
          ),

        // 使用药物
        if ((path.outfit['medicine'] ?? 0) > 0)
          ElevatedButton(
            onPressed: () => events.useMeds(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[100], // 浅绿色背景
              foregroundColor: Colors.black, // 黑色文字
              side: const BorderSide(color: Colors.green), // 绿色边框
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32), // 减少最小高度
            ),
            child: Text(
              '用药 (${path.outfit['medicine']})',
              style: const TextStyle(fontSize: 11),
            ),
          ),

        // 使用注射器
        if ((path.outfit['hypo'] ?? 0) > 0)
          ElevatedButton(
            onPressed: () => events.useHypo(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[100], // 浅蓝色背景
              foregroundColor: Colors.black, // 黑色文字
              side: const BorderSide(color: Colors.blue), // 蓝色边框
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32), // 减少最小高度
            ),
            child: Text(
              '注射器 (${path.outfit['hypo']})',
              style: const TextStyle(fontSize: 11),
            ),
          ),

        // 逃跑按钮
        ElevatedButton(
          onPressed: () => events.endEvent(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[100], // 浅红色背景
            foregroundColor: Colors.black, // 黑色文字
            side: const BorderSide(color: Colors.red), // 红色边框
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32), // 减少最小高度
          ),
          child: const Text(
            '逃跑',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// 构建战利品界面 - 参考原游戏的战斗胜利界面
  Widget _buildLootInterface(
      BuildContext context, Events events, Map<String, dynamic> scene) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 死亡消息
        Text(
          scene['deathMessage'] ?? '敌人死了',
          style: const TextStyle(
            color: Colors.black, // 黑色文字
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // 战利品列表
        if (events.currentLoot.isNotEmpty) ...[
          const Text(
            '战利品:',
            style: TextStyle(
              color: Colors.black, // 黑色文字
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...events.currentLoot.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_getItemDisplayName(entry.key)} [${entry.value}]',
                      style: const TextStyle(
                        color: Colors.black, // 黑色文字
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      events.getLoot(
                        entry.key,
                        entry.value,
                        onBagFull: () {
                          // 显示简化的丢弃物品对话框
                          _showDropItemDialog(
                              context, entry.key, entry.value, events);
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // 白色背景
                      foregroundColor: Colors.black, // 黑色文字
                      side: const BorderSide(color: Colors.black), // 黑色边框
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      minimumSize: const Size(0, 28), // 减少最小高度
                    ),
                    child: const Text(
                      '拿取',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          const Text(
            '没有战利品',
            style: TextStyle(
              color: Colors.black, // 黑色文字
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // 显示场景定义中的按钮，而不是固定的离开按钮
        _buildSceneButtons(context, events, scene),
      ],
    );
  }

  /// 构建场景按钮 - 显示场景定义中的按钮
  Widget _buildSceneButtons(
      BuildContext context, Events events, Map<String, dynamic> scene) {
    final buttons = scene['buttons'] as Map<String, dynamic>? ?? {};

    if (buttons.isEmpty) {
      // 如果没有定义按钮，显示默认的离开按钮
      return ElevatedButton(
        onPressed: () => events.endEvent(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[100], // 浅红色背景
          foregroundColor: Colors.black, // 黑色文字
          side: const BorderSide(color: Colors.red), // 红色边框
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: const Text(
          '离开',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: buttons.entries.map((entry) {
        final buttonConfig = entry.value as Map<String, dynamic>;
        final text = buttonConfig['text'] ?? entry.key;

        return ElevatedButton(
          onPressed: () =>
              _handleSceneButtonPress(events, entry.key, buttonConfig),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // 白色背景
            foregroundColor: Colors.black, // 黑色文字
            side: const BorderSide(color: Colors.black), // 黑色边框
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 36),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  /// 处理场景按钮点击
  void _handleSceneButtonPress(
      Events events, String buttonKey, Map<String, dynamic> buttonConfig) {
    Logger.info('🎮 战利品界面按钮点击: $buttonKey');

    // 处理冷却时间
    final cooldown = buttonConfig['cooldown'];
    if (cooldown != null) {
      // 这里可以添加冷却时间处理逻辑
    }

    // 处理消耗品
    final cost = buttonConfig['cost'] as Map<String, dynamic>?;
    if (cost != null) {
      final sm = StateManager();
      for (final entry in cost.entries) {
        final current = sm.get('stores["${entry.key}"]', true) ?? 0;
        if (current < entry.value) {
          Logger.info('⚠️ 资源不足: ${entry.key} 需要${entry.value}，当前$current');
          return;
        }
      }
      // 扣除消耗品
      for (final entry in cost.entries) {
        final current = sm.get('stores["${entry.key}"]', true) ?? 0;
        sm.set('stores["${entry.key}"]', current - entry.value);
      }
    }

    // 处理下一个场景
    final nextScene = buttonConfig['nextScene'];
    if (nextScene != null) {
      if (nextScene is String) {
        if (nextScene == 'end') {
          events.endEvent();
        } else {
          events.loadScene(nextScene);
        }
      } else if (nextScene is Map<String, dynamic>) {
        // 处理概率场景选择
        final random = Random().nextDouble();
        String? selectedScene;

        final sortedEntries = nextScene.entries.toList()
          ..sort((a, b) => double.parse(a.key).compareTo(double.parse(b.key)));

        for (final entry in sortedEntries) {
          final probability = double.parse(entry.key);
          if (random <= probability) {
            selectedScene = entry.value;
            break;
          }
        }

        if (selectedScene != null) {
          if (selectedScene == 'end') {
            events.endEvent();
          } else {
            events.loadScene(selectedScene);
          }
        }
      }
    } else {
      // 如果没有定义nextScene，默认结束事件
      events.endEvent();
    }
  }

  /// 显示简化的丢弃物品对话框
  void _showDropItemDialog(
      BuildContext context, String itemKey, int itemValue, Events events) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('背包空间不足'),
          content: SizedBox(
            width: 300,
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('请选择要丢弃的物品以腾出空间：'),
                  const SizedBox(height: 8),
                  ...Path()
                      .outfit
                      .entries
                      .where((e) => e.value > 0)
                      .map((e) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_getItemDisplayName(e.key)} x${e.value}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Path().outfit[e.key] = e.value - 1;
                                    StateManager().set('outfit["${e.key}"]',
                                        Path().outfit[e.key]);
                                    Path().updateOutfitting();
                                    Navigator.of(context).pop();
                                    // 重新尝试拾取物品
                                    events.getLoot(itemKey, itemValue);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 28),
                                  ),
                                  child: const Text(
                                    '丢弃1',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
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
  }

  /// 获取物品显示名称
  String _getItemDisplayName(String itemName) {
    switch (itemName) {
      case 'fur':
        return '毛皮';
      case 'meat':
        return '肉';
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
      case 'coal':
        return '煤炭';
      case 'steel':
        return '钢铁';
      case 'sulphur':
        return '硫磺';
      case 'energy cell':
        return '能量电池';
      case 'bullets':
        return '子弹';
      case 'medicine':
        return '药物';
      case 'cured meat':
        return '熏肉';
      default:
        return itemName;
    }
  }

  /// 获取武器显示名称
  String _getWeaponDisplayName(String weaponName) {
    switch (weaponName) {
      case 'fists':
        return '拳头';
      case 'bone spear':
        return '骨矛';
      case 'iron sword':
        return '铁剑';
      case 'steel sword':
        return '钢剑';
      case 'bayonet':
        return '刺刀';
      case 'rifle':
        return '步枪';
      case 'laser rifle':
        return '激光步枪';
      case 'grenade':
        return '手榴弹';
      case 'bolas':
        return '流星锤';
      case 'plasma rifle':
        return '等离子步枪';
      case 'energy blade':
        return '能量剑';
      case 'disruptor':
        return '干扰器';
      default:
        return weaponName;
    }
  }
}
