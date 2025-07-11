import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/events.dart';
import '../modules/world.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/responsive_layout.dart';
import '../core/logger.dart';
import '../widgets/progress_button.dart';
import '../config/game_config.dart';

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
                                isStunned: events.isEnemyStunned,
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
      {required bool isPlayer, bool isStunned = false}) {
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

          // 眩晕状态显示
          if (isStunned)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.yellow[200],
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                '😵 眩晕',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
        // 移除"选择武器"文字，参考原游戏
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: availableWeapons.map((weaponName) {
            final weapon = World.weapons[weaponName];
            final cooldown = weapon?['cooldown'] ?? 2; // 默认2秒冷却
            final cost = weapon?['cost'] as Map<String, dynamic>?;
            final costMap =
                cost?.map((k, v) => MapEntry(k, (v as num).toInt()));
            return ProgressButton(
              text: _getWeaponDisplayName(weaponName),
              onPressed: () => events.useWeapon(weaponName),
              progressDuration: (cooldown * 1000).round(), // 转换为毫秒
              cost: costMap,
              width: GameConfig.combatButtonWidth.toDouble(), // 参考原游戏CSS
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
        // 吃肉 - 带冷却时间
        if ((path.outfit['cured meat'] ?? 0) > 0)
          ProgressButton(
            text:
                '${Localization().translate('combat.eat_meat')} (${path.outfit['cured meat']})',
            onPressed: () => events.eatMeat(),
            progressDuration: GameConfig.eatCooldown * 1000, // 转换为毫秒
            // 移除成本提示，参考原游戏：战斗中按钮不显示成本
            disabled: (path.outfit['cured meat'] ?? 0) == 0,
            width: GameConfig.combatButtonWidth.toDouble(), // 参考原游戏CSS
            id: 'combat.eat_meat', // 固定ID，避免因文本变化导致进度跟踪失效
          ),

        // 使用药物 - 带冷却时间
        if ((path.outfit['medicine'] ?? 0) > 0)
          ProgressButton(
            text:
                '${Localization().translate('combat.use_medicine')} (${path.outfit['medicine']})',
            onPressed: () => events.useMeds(),
            progressDuration: GameConfig.medsCooldown * 1000, // 转换为毫秒
            cost: const {'medicine': 1},
            disabled: (path.outfit['medicine'] ?? 0) == 0,
            width: GameConfig.combatButtonWidth.toDouble(), // 参考原游戏CSS
            id: 'combat.use_medicine', // 固定ID
          ),

        // 使用注射器 - 带冷却时间
        if ((path.outfit['hypo'] ?? 0) > 0)
          ProgressButton(
            text:
                '${Localization().translate('combat.use_hypo')} (${path.outfit['hypo']})',
            onPressed: () => events.useHypo(),
            progressDuration: GameConfig.hypoCooldown * 1000, // 转换为毫秒
            cost: const {'hypo': 1},
            disabled: (path.outfit['hypo'] ?? 0) == 0,
            width: GameConfig.combatButtonWidth.toDouble(), // 参考原游戏CSS
            id: 'combat.use_hypo', // 固定ID
          ),

        // 原游戏战斗中没有逃跑按钮，只有在胜利后才有离开按钮
      ],
    );
  }

  /// 构建战利品界面 - 参考原游戏的战斗胜利界面，针对APK版本优化
  Widget _buildLootInterface(
      BuildContext context, Events events, Map<String, dynamic> scene) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 死亡消息 - 移动端增大字体
          Text(
            scene['deathMessage'] != null
                ? Localization().translate(scene['deathMessage'])
                : Localization().translate('combat.enemy_dead'),
            style: TextStyle(
              color: Colors.black,
              fontSize: layoutParams.useVerticalLayout ? 16 : 15, // 移动端增大字体
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: layoutParams.useVerticalLayout ? 16 : 12), // 移动端增加间距

          // 主要内容区域 - 根据是否显示丢弃界面来决定布局
          if (_showDropInterface) ...[
            // 显示丢弃界面
            _buildDropInterface(context, events),
          ] else ...[
            // 显示正常的战利品界面
            if (events.currentLoot.isNotEmpty) ...[
              Text(
                Localization().translate('messages.gained'),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: layoutParams.useVerticalLayout ? 15 : 14, // 移动端增大字体
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                  height: layoutParams.useVerticalLayout ? 12 : 8), // 移动端增加间距

              // 战利品布局 - 移动端和桌面端使用不同布局
              _buildLootItemsList(context, events, layoutParams),
            ] else ...[
              Text(
                Localization().translate('combat.no_loot'),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: layoutParams.useVerticalLayout ? 14 : 12, // 移动端增大字体
                ),
              ),
            ],

            SizedBox(
                height: layoutParams.useVerticalLayout ? 16 : 12), // 移动端增加间距

            // 底部按钮区域 - 参考原游戏的按钮布局
            _buildLootActionButtons(context, events, scene),
          ],
        ],
      ),
    );
  }

  /// 构建战利品物品列表 - 针对不同设备类型优化布局
  Widget _buildLootItemsList(
      BuildContext context, Events events, GameLayoutParams layoutParams) {
    if (layoutParams.useVerticalLayout) {
      // 移动端：使用垂直列表布局，更适合触摸操作
      return Column(
        children: events.currentLoot.entries.map((entry) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 物品名称和数量
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    '${_getItemDisplayName(entry.key)} [${entry.value}]',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14, // 移动端增大字体
                    ),
                  ),
                ),
                // 按钮区域
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
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
                          horizontal: 16, vertical: 12), // 增大触摸区域
                      minimumSize: const Size(0, 40), // 增大最小高度
                    ),
                    child: Text(
                      _showDropInterface
                          ? '${Localization().translate('ui.buttons.take_all').split(' ')[0]} 0'
                          : Localization().translate('ui.buttons.take_all'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      // 桌面端：保持原有的表格布局
      return Container(
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                          : Localization().translate('ui.buttons.take_all'),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }
  }

  /// 构建丢弃界面 - 参考原游戏的丢弃物品界面，针对APK版本优化
  Widget _buildDropInterface(BuildContext context, Events events) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);
    final outfitItems =
        Path().outfit.entries.where((e) => e.value > 0).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 获得区域 - 显示待拾取的物品但按钮显示"带走 0"
        if (_pendingLootKey != null && _pendingLootValue != null) ...[
          Text(
            Localization().translate('messages.gained'),
            style: TextStyle(
              color: Colors.black,
              fontSize: layoutParams.useVerticalLayout ? 15 : 14, // 移动端增大字体
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: layoutParams.useVerticalLayout ? 12 : 8), // 移动端增加间距
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

  /// 构建战利品界面的底部按钮 - 参考原游戏的按钮布局，针对APK版本优化
  Widget _buildLootActionButtons(
      BuildContext context, Events events, Map<String, dynamic> scene) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 拿走一切以及离开按钮
        if (events.currentLoot.isNotEmpty)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(
                vertical: layoutParams.useVerticalLayout ? 4 : 2), // 移动端增加间距
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
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical:
                      layoutParams.useVerticalLayout ? 12 : 6, // 移动端增大触摸区域
                ),
                minimumSize: Size(
                    0, layoutParams.useVerticalLayout ? 48 : 32), // 移动端增大最小高度
              ),
              child: Text(
                Localization().translate('combat.take_all_and_leave'),
                style: TextStyle(
                    fontSize:
                        layoutParams.useVerticalLayout ? 14 : 12), // 移动端增大字体
              ),
            ),
          ),

        // 继续按钮 - 如果有下一个场景的话
        if (_hasNextScene(events, scene))
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(
                vertical: layoutParams.useVerticalLayout ? 4 : 2), // 移动端增加间距
            child: ElevatedButton(
              onPressed: () => _continueToNextScene(events, scene),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical:
                      layoutParams.useVerticalLayout ? 12 : 6, // 移动端增大触摸区域
                ),
                minimumSize: Size(
                    0, layoutParams.useVerticalLayout ? 48 : 32), // 移动端增大最小高度
              ),
              child: Text(
                Localization().translate('ui.buttons.continue'),
                style: TextStyle(
                    fontSize:
                        layoutParams.useVerticalLayout ? 14 : 12), // 移动端增大字体
              ),
            ),
          ),

        // 离开按钮 - 统一样式，修复：正确处理场景中的leave按钮逻辑
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(
              vertical: layoutParams.useVerticalLayout ? 4 : 2), // 移动端增加间距
          child: ElevatedButton(
            onPressed: () => _handleLeaveButton(events, scene),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: layoutParams.useVerticalLayout ? 12 : 6, // 移动端增大触摸区域
              ),
              minimumSize: Size(
                  0, layoutParams.useVerticalLayout ? 48 : 32), // 移动端增大最小高度
            ),
            child: Text(
              Localization().translate('combat.leave'),
              style: TextStyle(
                  fontSize:
                      layoutParams.useVerticalLayout ? 14 : 12), // 移动端增大字体
            ),
          ),
        ),

        // 吃肉按钮 - 统一样式
        Consumer<Path>(
          builder: (context, path, child) {
            final curedMeat = path.outfit['cured meat'] ?? 0;
            if (curedMeat > 0) {
              return Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(
                    vertical:
                        layoutParams.useVerticalLayout ? 4 : 2), // 移动端增加间距
                child: ElevatedButton(
                  onPressed: () => events.eatMeat(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical:
                          layoutParams.useVerticalLayout ? 12 : 6, // 移动端增大触摸区域
                    ),
                    minimumSize: Size(0,
                        layoutParams.useVerticalLayout ? 48 : 32), // 移动端增大最小高度
                  ),
                  child: Text(
                    Localization().translate('combat.eat_meat'),
                    style: TextStyle(
                        fontSize: layoutParams.useVerticalLayout
                            ? 14
                            : 12), // 移动端增大字体
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
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

  /// 处理离开按钮 - 修复铁矿访问问题
  void _handleLeaveButton(Events events, Map<String, dynamic> scene) {
    final buttons = scene['buttons'] as Map<String, dynamic>? ?? {};
    final leaveButton = buttons['leave'] as Map<String, dynamic>?;

    if (leaveButton != null && leaveButton['nextScene'] != null) {
      // 处理场景中配置的leave按钮逻辑，确保正确跳转到下一个场景
      Logger.info('🔘 战斗胜利后处理leave按钮，跳转到下一个场景');
      events.handleButtonClick('leave', leaveButton);
    } else {
      // 如果没有配置leave按钮或nextScene，则直接结束事件
      Logger.info('🔘 没有leave按钮配置，直接结束事件');
      events.endEvent();
    }
  }
}
