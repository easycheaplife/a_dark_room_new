import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/events.dart';
import '../modules/world.dart';
import '../modules/path.dart';

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
          color: Colors.black.withValues(alpha: 0.8),
          child: Center(
            child: Container(
              width: 600,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                border: Border.all(color: const Color(0xFF555555)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF555555)),
                      ),
                    ),
                    child: Text(
                      activeEvent['title'] ?? '战斗',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 战斗描述
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 通知文本
                          if (scene['notification'] != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                border:
                                    Border.all(color: const Color(0xFF444444)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scene['notification'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          // 战斗区域 - 参考原游戏布局
                          Container(
                            height: 150,
                            padding: const EdgeInsets.all(16),
                            child: Stack(
                              children: [
                                // 玩家 - 左侧
                                Positioned(
                                  left: events.currentAnimation ==
                                          'melee_wanderer'
                                      ? 100
                                      : 50,
                                  bottom: 15,
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
                                  right:
                                      events.currentAnimation == 'melee_enemy'
                                          ? 100
                                          : 50,
                                  bottom: 15,
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
                                if (events.currentAnimation
                                        ?.startsWith('ranged') ==
                                    true)
                                  _buildBulletAnimation(
                                      events.currentAnimation!),

                                // 伤害数字动画
                                if (events.currentAnimationDamage > 0)
                                  _buildDamageText(
                                      events.currentAnimationDamage),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 根据战斗状态显示不同内容
                          if (events.showingLoot)
                            _buildLootInterface(context, events, scene)
                          else ...[
                            // 攻击按钮
                            _buildAttackButtons(context, events, path),

                            const SizedBox(height: 16),

                            // 物品按钮
                            _buildItemButtons(context, events, path, world),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
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
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              chara,
              style: const TextStyle(
                color: Colors.white,
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
      children: [
        const Text(
          '选择武器:',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableWeapons.map((weaponName) {
            return ElevatedButton(
              onPressed: () => events.useWeapon(weaponName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF444444),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                _getWeaponDisplayName(weaponName),
                style: const TextStyle(fontSize: 12),
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
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        // 吃肉
        if ((path.outfit['cured meat'] ?? 0) > 0)
          ElevatedButton(
            onPressed: () => events.eatMeat(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('吃肉 (${path.outfit['cured meat']})'),
          ),

        // 使用药物
        if ((path.outfit['medicine'] ?? 0) > 0)
          ElevatedButton(
            onPressed: () => events.useMeds(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF228B22),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('用药 (${path.outfit['medicine']})'),
          ),

        // 使用注射器
        if ((path.outfit['hypo'] ?? 0) > 0)
          ElevatedButton(
            onPressed: () => events.useHypo(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('注射器 (${path.outfit['hypo']})'),
          ),

        // 逃跑按钮
        ElevatedButton(
          onPressed: () => events.endEvent(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('逃跑'),
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
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            scene['deathMessage'] ?? '敌人死了',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // 战利品列表
        if (events.currentLoot.isNotEmpty) ...[
          const Text(
            '战利品:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => events.getLoot(entry.key, entry.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF444444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                    child: const Text('拿取', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          const Text(
            '没有战利品',
            style: TextStyle(color: Colors.white),
          ),
        ],

        const SizedBox(height: 20),

        // 离开按钮
        ElevatedButton(
          onPressed: () => events.endEvent(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('离开'),
        ),
      ],
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
