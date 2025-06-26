import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/events.dart';
import '../modules/world.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';

/// 战斗界面 - 完整翻译自原游戏的战斗系统
class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  // 用于跟踪是否显示丢弃界面
  bool _showDropInterface = false;
  String? _pendingLootKey;
  int? _pendingLootValue;

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
                        activeEvent['title'] != null
                            ? Localization().translate(activeEvent['title'])
                            : Localization().translate('combat.title'),
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
                          Localization().translate(scene['notification']),
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
                                Localization().translate('combat.wanderer'),
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
                                scene['enemyName'] != null
                                    ? Localization()
                                        .translate(scene['enemyName'])
                                    : Localization().translate('combat.enemy'),
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
        Text(
          Localization().translate('combat.choose_weapon'),
          style: const TextStyle(color: Colors.black, fontSize: 13), // 黑色文字
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
              '${Localization().translate('combat.eat_meat')} (${path.outfit['cured meat']})',
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
              '${Localization().translate('combat.use_medicine')} (${path.outfit['medicine']})',
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
              '${Localization().translate('combat.use_hypo')} (${path.outfit['hypo']})',
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
          child: Text(
            Localization().translate('combat.flee'),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// 构建战利品界面 - 参考原游戏的战斗胜利界面
  Widget _buildLootInterface(
      BuildContext context, Events events, Map<String, dynamic> scene) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 死亡消息
          Text(
            scene['deathMessage'] != null
                ? Localization().translate(scene['deathMessage'])
                : Localization().translate('combat.enemy_dead'),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // 主要内容区域 - 根据是否显示丢弃界面来决定布局
          if (_showDropInterface) ...[
            // 显示丢弃界面
            _buildDropInterface(context, events),
          ] else ...[
            // 显示正常的战利品界面
            if (events.currentLoot.isNotEmpty) ...[
              Text(
                Localization().translate('messages.gained'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 战利品网格布局 - 左边物品，右边按钮
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
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
                              side: const BorderSide(color: Colors.black),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 24),
                            ),
                            child: Text(
                              _showDropInterface
                                  ? '${Localization().translate('ui.buttons.take_all').split(' ')[0]} 0'
                                  : Localization()
                                      .translate('ui.buttons.take_all'),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              Text(
                Localization().translate('combat.no_loot'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 底部按钮区域 - 参考原游戏的按钮布局
            _buildLootActionButtons(context, events, scene),
          ],
        ],
      ),
    );
  }

  /// 构建丢弃界面 - 参考原游戏的丢弃物品界面
  Widget _buildDropInterface(BuildContext context, Events events) {
    final outfitItems =
        Path().outfit.entries.where((e) => e.value > 0).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 获得区域 - 显示待拾取的物品但按钮显示"带走 0"
        if (_pendingLootKey != null && _pendingLootValue != null) ...[
          Text(
            Localization().translate('messages.gained'),
            style: const TextStyle(
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
                        child: Text(
                          '${Localization().translate('ui.buttons.take_all').split(' ')[0]} 0',
                          style: const TextStyle(fontSize: 10),
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
                child: Text(
                  Localization().translate('messages.drop'),
                  style: const TextStyle(
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
                              child: Text(
                                Localization().translate('ui.buttons.drop_one'),
                                style: const TextStyle(fontSize: 10),
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
                  child: Text(
                    Localization().translate('ui.buttons.leave_empty'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建战利品界面的底部按钮 - 参考原游戏的按钮布局
  Widget _buildLootActionButtons(
      BuildContext context, Events events, Map<String, dynamic> scene) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 拿走一切以及离开按钮
        if (events.currentLoot.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ElevatedButton(
              onPressed: () {
                // 拿取所有物品
                final lootEntries = List.from(events.currentLoot.entries);
                bool bagFull = false;

                for (final entry in lootEntries) {
                  events.getLoot(
                    entry.key,
                    entry.value,
                    onBagFull: () {
                      bagFull = true;
                      setState(() {
                        _showDropInterface = true;
                        _pendingLootKey = entry.key;
                        _pendingLootValue = entry.value;
                      });
                    },
                  );

                  // 如果背包满了，停止拿取
                  if (bagFull) break;
                }

                // 只有在背包没满的情况下才离开
                if (!bagFull) {
                  Timer(const Duration(milliseconds: 500), () {
                    events.endEvent();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                Localization().translate('combat.take_all_and_leave'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),

        // 继续按钮 - 如果有下一个场景的话
        if (_hasNextScene(events, scene))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ElevatedButton(
              onPressed: () => _continueToNextScene(events, scene),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                Localization().translate('ui.buttons.continue'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),

        // 离开按钮
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ElevatedButton(
            onPressed: () => events.endEvent(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              Localization().translate('combat.leave'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),

        // 吃肉按钮 - 如果有熏肉的话
        if (Path().outfit['cured meat'] != null &&
            Path().outfit['cured meat']! > 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ElevatedButton(
              onPressed: () => events.eatMeat(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                Localization().translate('combat.eat_meat'),
                style: const TextStyle(fontSize: 12),
              ),
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

  /// 获取武器显示名称 - 使用武器的verb属性作为攻击动作名称
  String _getWeaponDisplayName(String weaponName) {
    final localization = Localization();
    final weapon = World.weapons[weaponName];

    if (weapon != null && weapon['verb'] != null) {
      final verb = weapon['verb'] as String;

      // 尝试从本地化获取动作名称
      final translatedVerb = localization.translate('combat.weapons.$verb');
      if (translatedVerb != 'combat.weapons.$verb') {
        return translatedVerb;
      }

      // 如果没有找到翻译，尝试使用武器名称
      final translatedName =
          localization.translate('combat.weapons.$weaponName');
      if (translatedName != 'combat.weapons.$weaponName') {
        return translatedName;
      }

      // 最后返回原verb
      return verb;
    }

    // 如果没有找到武器配置，返回原名称
    return weaponName;
  }

  /// 检查是否有下一个场景
  bool _hasNextScene(Events events, Map<String, dynamic> scene) {
    // 检查场景的buttons中是否有continue按钮且有nextScene配置
    final buttons = scene['buttons'] as Map<String, dynamic>? ?? {};
    final continueButton = buttons['continue'] as Map<String, dynamic>?;
    return continueButton != null && continueButton['nextScene'] != null;
  }

  /// 继续到下一个场景
  void _continueToNextScene(Events events, Map<String, dynamic> scene) {
    final buttons = scene['buttons'] as Map<String, dynamic>? ?? {};
    final continueButton = buttons['continue'] as Map<String, dynamic>?;

    if (continueButton != null && continueButton['nextScene'] != null) {
      // 直接调用Events的按钮点击处理逻辑
      events.handleButtonClick('continue', continueButton);
    } else {
      events.endEvent();
    }
  }
}
