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
                    child: Padding(
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

                          // 战斗者信息
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 玩家
                              _buildFighterInfo(
                                '流浪者',
                                '@',
                                world.health,
                                world.getMaxHealth(),
                                isPlayer: true,
                              ),

                              // 敌人
                              _buildFighterInfo(
                                scene['enemyName'] ?? '敌人',
                                scene['chara'] ?? 'E',
                                scene['health'] ?? 10,
                                scene['health'] ?? 10,
                                isPlayer: false,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 攻击按钮
                          _buildAttackButtons(context, events, path),

                          const SizedBox(height: 16),

                          // 物品按钮
                          _buildItemButtons(context, events, path, world),
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

  /// 构建战斗者信息
  Widget _buildFighterInfo(String name, String chara, int hp, int maxHp,
      {required bool isPlayer}) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF444444)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // 角色符号
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isPlayer ? const Color(0xFF2A5A2A) : const Color(0xFF5A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                chara,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 名称
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // 血量
          Text(
            '$hp/$maxHp',
            style: TextStyle(
              color: hp > maxHp * 0.5
                  ? Colors.green
                  : hp > maxHp * 0.25
                      ? Colors.orange
                      : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 吃肉
        if ((path.outfit['cured meat'] ?? 0) > 0)
          ElevatedButton(
            onPressed: () => events.eatMeat(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
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
            ),
            child: Text('注射器 (${path.outfit['hypo']})'),
          ),

        // 逃跑按钮
        ElevatedButton(
          onPressed: () => events.endEvent(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            foregroundColor: Colors.white,
          ),
          child: const Text('逃跑'),
        ),
      ],
    );
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
