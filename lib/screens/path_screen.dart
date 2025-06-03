import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/game_button.dart';

/// 漫漫尘途界面 - 显示装备管理和出发准备
class PathScreen extends StatelessWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Path, StateManager, Localization>(
      builder: (context, path, stateManager, localization, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧：装备区域和出发按钮
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 装备区域
                  _buildOutfittingSection(path, stateManager, localization),

                  const SizedBox(height: 20),

                  // 出发按钮
                  _buildEmbarkButton(path, stateManager, localization),
                ],
              ),

              const SizedBox(width: 20),

              // 右侧：技能区域（如果有的话）
              _buildPerksSection(path, stateManager, localization),
            ],
          ),
        );
      },
    );
  }

  /// 构建装备区域 - 模拟原游戏的outfitting容器
  Widget _buildOutfittingSection(
      Path path, StateManager stateManager, Localization localization) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题 - 模拟原游戏的 data-legend 属性
              Container(
                transform: Matrix4.translationValues(-8, -13, 0),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: const Text(
                    '补给:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 护甲行
              _buildArmourRow(stateManager),

              const SizedBox(height: 10),

              // 水行
              _buildWaterRow(stateManager),

              const SizedBox(height: 10),

              // 装备物品列表
              ..._buildOutfitItems(path, stateManager),
            ],
          ),

          // 背包空间显示 - 右上角
          Positioned(
            top: -13,
            right: 10,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '剩余 ${path.getFreeSpace().floor()}/${path.getCapacity()}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建护甲行
  Widget _buildArmourRow(StateManager stateManager) {
    String armour = "无";
    if ((stateManager.get('stores["kinetic armour"]', true) ?? 0) > 0) {
      armour = "动能";
    } else if ((stateManager.get('stores["s armour"]', true) ?? 0) > 0) {
      armour = "钢制";
    } else if ((stateManager.get('stores["i armour"]', true) ?? 0) > 0) {
      armour = "铁制";
    } else if ((stateManager.get('stores["l armour"]', true) ?? 0) > 0) {
      armour = "皮革";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '护甲',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Times New Roman',
          ),
        ),
        Text(
          armour,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Times New Roman',
          ),
        ),
      ],
    );
  }

  /// 构建水行
  Widget _buildWaterRow(StateManager stateManager) {
    // 这里应该从World模块获取最大水量，暂时使用固定值
    final maxWater = 10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '水',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Times New Roman',
          ),
        ),
        Text(
          '$maxWater',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Times New Roman',
          ),
        ),
      ],
    );
  }

  /// 构建装备物品列表
  List<Widget> _buildOutfitItems(Path path, StateManager stateManager) {
    final List<Widget> items = [];

    // 可携带物品配置 - 基于原游戏的carryable对象
    final carryableItems = {
      'cured meat': {'type': 'tool', 'desc': '恢复 2 生命值'},
      'bullets': {'type': 'tool', 'desc': '配合步枪使用'},
      'grenade': {'type': 'weapon'},
      'bolas': {'type': 'weapon'},
      'laser rifle': {'type': 'weapon'},
      'energy cell': {'type': 'tool', 'desc': '发出柔和的红光'},
      'bayonet': {'type': 'weapon'},
      'charm': {'type': 'tool'},
      'alien alloy': {'type': 'tool'},
      'medicine': {'type': 'tool', 'desc': '恢复 20 生命值'},
      // 从Room.Craftables添加
      'bone spear': {'type': 'weapon'},
      'iron sword': {'type': 'weapon'},
      'steel sword': {'type': 'weapon'},
      'rifle': {'type': 'weapon'},
    };

    for (final entry in carryableItems.entries) {
      final itemName = entry.key;
      final itemConfig = entry.value;
      final have = stateManager.get('stores["$itemName"]', true) ?? 0;
      final equipped = path.outfit[itemName] ?? 0;

      if (have > 0 &&
          (itemConfig['type'] == 'tool' || itemConfig['type'] == 'weapon')) {
        items.add(_buildOutfitRow(
            itemName, equipped, have, itemConfig, path, stateManager));
      }
    }

    return items;
  }

  /// 构建装备行
  Widget _buildOutfitRow(String itemName, int equipped, int available,
      Map<String, dynamic> config, Path path, StateManager stateManager) {
    final localizedName = _getLocalizedItemName(itemName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Tooltip(
        message: _getItemTooltip(itemName, config),
        child: Row(
          children: [
            // 物品名称
            Expanded(
              child: Text(
                localizedName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),

            // 数量和控制按钮
            Row(
              children: [
                Text(
                  '$equipped',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Times New Roman',
                  ),
                ),

                const SizedBox(width: 5),

                // 减少按钮
                _buildSupplyButton(
                    '▼',
                    equipped > 0
                        ? () => _decreaseSupply(itemName, 1, path, stateManager)
                        : null),

                const SizedBox(width: 2),

                // 增加按钮
                _buildSupplyButton(
                    '▲',
                    _canIncreaseSupply(itemName, equipped, available, path)
                        ? () => _increaseSupply(itemName, 1, path, stateManager)
                        : null),

                const SizedBox(width: 2),

                // 减少10按钮
                _buildSupplyButton(
                    '▼▼',
                    equipped >= 10
                        ? () =>
                            _decreaseSupply(itemName, 10, path, stateManager)
                        : null),

                const SizedBox(width: 2),

                // 增加10按钮
                _buildSupplyButton(
                    '▲▲',
                    _canIncreaseSupply(itemName, equipped, available, path, 10)
                        ? () =>
                            _increaseSupply(itemName, 10, path, stateManager)
                        : null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建供应按钮 - 模拟原游戏的上下箭头按钮
  Widget _buildSupplyButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: 14,
      height: 12,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: onPressed != null ? Colors.black : Colors.grey),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: onPressed != null ? Colors.black : Colors.grey,
                fontSize: 6,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 检查是否可以增加供应
  bool _canIncreaseSupply(
      String itemName, int equipped, int available, Path path,
      [int amount = 1]) {
    return equipped < available &&
        path.getFreeSpace() >= path.getWeight(itemName) * amount;
  }

  /// 增加供应
  void _increaseSupply(
      String itemName, int amount, Path path, StateManager stateManager) {
    final current = path.outfit[itemName] ?? 0;
    final available = stateManager.get('stores["$itemName"]', true) ?? 0;
    final maxByWeight =
        (path.getFreeSpace() / path.getWeight(itemName)).floor();
    final maxByStore = available - current;
    final actualAmount = [amount, maxByWeight, maxByStore]
        .reduce((a, b) => a < b ? a : b)
        .toInt();

    if (actualAmount > 0) {
      path.outfit[itemName] = (current + actualAmount).toInt();
      stateManager.set('outfit["$itemName"]', path.outfit[itemName]);
      path.updateOutfitting();
    }
  }

  /// 减少供应
  void _decreaseSupply(
      String itemName, int amount, Path path, StateManager stateManager) {
    final current = path.outfit[itemName] ?? 0;
    if (current > 0) {
      path.outfit[itemName] = (current - amount).clamp(0, current);
      stateManager.set('outfit["$itemName"]', path.outfit[itemName]);
      path.updateOutfitting();
    }
  }

  /// 获取本地化物品名称
  String _getLocalizedItemName(String itemName) {
    const itemNames = {
      'cured meat': '腌肉',
      'bullets': '子弹',
      'grenade': '手榴弹',
      'bolas': '流星锤',
      'laser rifle': '激光步枪',
      'energy cell': '能量电池',
      'bayonet': '刺刀',
      'charm': '护身符',
      'alien alloy': '外星合金',
      'medicine': '药品',
      'bone spear': '骨矛',
      'iron sword': '铁剑',
      'steel sword': '钢剑',
      'rifle': '步枪',
    };
    return itemNames[itemName] ?? itemName;
  }

  /// 获取物品提示信息
  String _getItemTooltip(String itemName, Map<String, dynamic> config) {
    final List<String> tooltipLines = [];

    if (config['type'] == 'weapon') {
      // 这里应该从World模块获取伤害值，暂时使用固定值
      tooltipLines.add('伤害: 1');
    } else if (config['desc'] != null) {
      tooltipLines.add(config['desc']);
    }

    tooltipLines.add('重量: ${Path().getWeight(itemName)}');

    return tooltipLines.join('\n');
  }

  /// 构建出发按钮
  Widget _buildEmbarkButton(
      Path path, StateManager stateManager, Localization localization) {
    final canEmbark = path.canEmbark();
    print('🎯 PathScreen: canEmbark=$canEmbark');

    return Tooltip(
      message: canEmbark ? '前往世界地图' : '需要携带腌肉才能出发',
      child: GameButton(
        text: '出发',
        onPressed: canEmbark
            ? () {
                print('🎯 PathScreen: 出发按钮被点击');
                path.embark();
              }
            : null,
        width: 80,
      ),
    );
  }

  /// 构建技能区域
  Widget _buildPerksSection(
      Path path, StateManager stateManager, Localization localization) {
    final perks = stateManager.get('character.perks', true);

    if (perks == null || (perks as Map).isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Container(
                transform: Matrix4.translationValues(-8, -13, 0),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: const Text(
                    '技能',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 技能列表
              ..._buildPerksList(perks as Map<String, dynamic>),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建技能列表
  List<Widget> _buildPerksList(Map<String, dynamic> perks) {
    final List<Widget> perkWidgets = [];

    for (final entry in perks.entries) {
      final perkName = entry.key;
      final hasPerk = entry.value as bool;

      if (hasPerk) {
        perkWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Tooltip(
              message: _getPerkDescription(perkName),
              child: Text(
                _getLocalizedPerkName(perkName),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),
        );
      }
    }

    return perkWidgets;
  }

  /// 获取本地化技能名称
  String _getLocalizedPerkName(String perkName) {
    const perkNames = {
      'boxer': '拳击手',
      'martial artist': '武术家',
      'unarmed master': '徒手大师',
      'barbarian': '野蛮人',
      'slow metabolism': '缓慢代谢',
      'desert rat': '沙漠老鼠',
      'evasive': '闪避',
      'precise': '精准',
      'scout': '侦察兵',
    };
    return perkNames[perkName] ?? perkName;
  }

  /// 获取技能描述
  String _getPerkDescription(String perkName) {
    const perkDescriptions = {
      'boxer': '徒手攻击伤害+1',
      'martial artist': '徒手攻击伤害+2',
      'unarmed master': '徒手攻击伤害+3',
      'barbarian': '所有攻击伤害+1',
      'slow metabolism': '食物消耗减半',
      'desert rat': '水消耗减半',
      'evasive': '被击中几率-10%',
      'precise': '命中率+10%',
      'scout': '遭遇敌人几率-10%',
    };
    return perkDescriptions[perkName] ?? '未知技能';
  }
}
