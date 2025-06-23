import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/game_button.dart';
import '../widgets/unified_stores_container.dart';
import '../core/logger.dart';

/// 漫漫尘途界面 - 显示装备管理和出发准备
class PathScreen extends StatelessWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Path, StateManager, Localization>(
      builder: (context, path, stateManager, localization, child) {
        final compassCount = stateManager.get('stores.compass', true) ?? 0;

        // 如果没有指南针，显示提示信息
        if (compassCount == 0) {
          return _buildNoCompassView(stateManager, localization);
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: SingleChildScrollView(
            // 添加整个页面的滚动支持
            child: SizedBox(
              width: double.infinity,
              height: 800, // 设置足够的高度以容纳所有内容
              child: Stack(
                children: [
                  // 左侧：装备区域和出发按钮 - 绝对定位，与小黑屋保持一致
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 装备区域
                        _buildOutfittingSection(
                            path, stateManager, localization),

                        const SizedBox(height: 20),

                        // 出发按钮
                        _buildEmbarkButton(path, stateManager, localization),
                      ],
                    ),
                  ),

                  // 库存容器 - 绝对定位，与小黑屋完全一致的位置: top: 0px, right: 0px
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _buildStoresContainer(stateManager, localization),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建没有指南针时的视图
  Widget _buildNoCompassView(
      StateManager stateManager, Localization localization) {
    final fur = stateManager.get('stores.fur', true) ?? 0;
    final scales = stateManager.get('stores.scales', true) ?? 0;
    final teeth = stateManager.get('stores.teeth', true) ?? 0;
    final hasTradingPost =
        (stateManager.get('game.buildings["trading post"]', true) ?? 0) > 0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localization.translate('ui.modules.path'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Times New Roman',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localization.translate('path.need_compass'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'Times New Roman',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (hasTradingPost) ...[
              Text(
                '${localization.translate('path.compass_requirements')}:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Times New Roman',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${localization.translate('resources.fur')}: $fur / 400',
                style: TextStyle(
                  fontSize: 14,
                  color: fur >= 400 ? Colors.green : Colors.red,
                  fontFamily: 'Times New Roman',
                ),
              ),
              Text(
                '${localization.translate('resources.scales')}: $scales / 20',
                style: TextStyle(
                  fontSize: 14,
                  color: scales >= 20 ? Colors.green : Colors.red,
                  fontFamily: 'Times New Roman',
                ),
              ),
              Text(
                '${localization.translate('resources.teeth')}: $teeth / 10',
                style: TextStyle(
                  fontSize: 14,
                  color: teeth >= 10 ? Colors.green : Colors.red,
                  fontFamily: 'Times New Roman',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localization.translate('path.craft_compass_hint'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Times New Roman',
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                localization.translate('path.need_trading_post'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Times New Roman',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建装备区域 - 模拟原游戏的outfitting容器
  Widget _buildOutfittingSection(
      Path path, StateManager stateManager, Localization localization) {
    return Container(
      width: 320, // 调整宽度，刚好容纳内容
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1), // 确保边框显示
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
                  width: 300, // 设置宽度以容纳完整的标题行
                  child: Text(
                    '${localization.translate('messages.supply')}:——${localization.translate('messages.backpack')}${localization.translate('messages.space')}: ${path.getFreeSpace().floor()}/${path.getCapacity()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                    overflow: TextOverflow.visible, // 确保文本不被截断
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 护甲行
              _buildArmourRow(stateManager, localization),

              const SizedBox(height: 10),

              // 水行
              _buildWaterRow(stateManager, localization),

              const SizedBox(height: 10),

              // 装备物品列表
              ..._buildOutfitItems(path, stateManager, localization),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建护甲行
  Widget _buildArmourRow(StateManager stateManager, Localization localization) {
    String armour = localization.translate('ui.status.none');
    if ((stateManager.get('stores["kinetic armour"]', true) ?? 0) > 0) {
      armour = localization.translate('ui.status.kinetic');
    } else if ((stateManager.get('stores["s armour"]', true) ?? 0) > 0) {
      armour = localization.translate('ui.status.steel');
    } else if ((stateManager.get('stores["i armour"]', true) ?? 0) > 0) {
      armour = localization.translate('ui.status.iron');
    } else if ((stateManager.get('stores["l armour"]', true) ?? 0) > 0) {
      armour = localization.translate('ui.status.leather');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localization.translate('resources.armour'),
          style: const TextStyle(
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
  Widget _buildWaterRow(StateManager stateManager, Localization localization) {
    // 这里应该从World模块获取最大水量，暂时使用固定值
    final maxWater = 10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localization.translate('resources.water'),
          style: const TextStyle(
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
  List<Widget> _buildOutfitItems(
      Path path, StateManager stateManager, Localization localization) {
    final List<Widget> items = [];

    // 可携带物品配置 - 基于原游戏的carryable对象
    final carryableItems = {
      // 基础可携带物品
      'cured meat': {'type': 'tool', 'desc_key': 'messages.restores_2_health'},
      'bullets': {'type': 'tool', 'desc_key': 'messages.for_use_with_rifle'},
      'grenade': {'type': 'weapon'},
      'bolas': {'type': 'weapon'},
      'laser rifle': {'type': 'weapon'},
      'energy cell': {'type': 'tool', 'desc_key': 'messages.glows_softly_red'},
      'bayonet': {'type': 'weapon'},
      'charm': {'type': 'tool'},
      'alien alloy': {'type': 'tool'},
      'medicine': {'type': 'tool', 'desc_key': 'messages.restores_20_health'},

      // 从Room.Craftables添加的武器
      'bone spear': {'type': 'weapon'},
      'iron sword': {'type': 'weapon'},
      'steel sword': {'type': 'weapon'},
      'rifle': {'type': 'weapon'},

      // 从Room.Craftables添加的工具 - 遗漏的重要物品！
      'torch': {'type': 'tool', 'desc_key': 'messages.torch_desc'},

      // 从Fabricator.Craftables添加的工具 - 遗漏的重要物品！
      'hypo': {'type': 'tool', 'desc_key': 'messages.hypo_desc'},
      'stim': {'type': 'tool', 'desc_key': 'messages.stim_desc'},
      'glowstone': {'type': 'tool', 'desc_key': 'messages.glowstone_desc'},
      'energy blade': {'type': 'weapon'},
      'disruptor': {'type': 'weapon'},
      'plasma rifle': {'type': 'weapon'},
    };

    for (final entry in carryableItems.entries) {
      final itemName = entry.key;
      final itemConfig = entry.value;
      final have = stateManager.get('stores["$itemName"]', true) ?? 0;
      final equipped = path.outfit[itemName] ?? 0;

      if (have > 0 &&
          (itemConfig['type'] == 'tool' || itemConfig['type'] == 'weapon')) {
        items.add(_buildOutfitRow(itemName, equipped, have, itemConfig, path,
            stateManager, localization));
      }
    }

    return items;
  }

  /// 构建装备行
  Widget _buildOutfitRow(
      String itemName,
      int equipped,
      int available,
      Map<String, dynamic> config,
      Path path,
      StateManager stateManager,
      Localization localization) {
    final localizedName = _getLocalizedItemName(itemName, localization);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Tooltip(
        message: _getItemTooltip(itemName, config, localization),
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

                // 按钮组 - 模拟原游戏的4个按钮布局
                SizedBox(
                  width: 30, // 容纳两列按钮
                  height: 20, // 容纳两行按钮
                  child: Stack(
                    children: [
                      // upBtn - 增加1个（左侧，上方）
                      Positioned(
                        right: 15,
                        top: 0,
                        child: _buildSupplyButton(
                          'up',
                          1,
                          _canIncreaseSupply(
                                  itemName, equipped, available, path)
                              ? () => _increaseSupply(
                                  itemName, 1, path, stateManager)
                              : null,
                        ),
                      ),

                      // dnBtn - 减少1个（左侧，下方）
                      Positioned(
                        right: 15,
                        bottom: 0,
                        child: _buildSupplyButton(
                          'down',
                          1,
                          equipped > 0
                              ? () => _decreaseSupply(
                                  itemName, 1, path, stateManager)
                              : null,
                        ),
                      ),

                      // upManyBtn - 增加10个（右侧，上方）
                      Positioned(
                        right: 0,
                        top: 0,
                        child: _buildSupplyButton(
                          'up',
                          10,
                          _canIncreaseSupply(
                                  itemName, equipped, available, path, 10)
                              ? () => _increaseSupply(
                                  itemName, 10, path, stateManager)
                              : null,
                        ),
                      ),

                      // dnManyBtn - 减少10个（右侧，下方）
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _buildSupplyButton(
                          'down',
                          10,
                          equipped >= 10
                              ? () => _decreaseSupply(
                                  itemName, 10, path, stateManager)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建供应按钮 - 模拟原游戏的三角形箭头按钮
  Widget _buildSupplyButton(
      String direction, int amount, VoidCallback? onPressed) {
    final bool isUp = direction == 'up';
    final bool isEnabled = onPressed != null;
    final bool isMany = amount >= 10; // 10个或以上为"Many"按钮

    return SizedBox(
      width: 14,
      height: 12,
      child: InkWell(
        onTap: onPressed,
        child: CustomPaint(
          size: const Size(14, 12),
          painter: _TriangleButtonPainter(
            isUp: isUp,
            isEnabled: isEnabled,
            isMany: isMany,
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
  String _getLocalizedItemName(String itemName, Localization localization) {
    return localization.translate('resources.$itemName');
  }

  /// 获取物品提示信息
  String _getItemTooltip(
      String itemName, Map<String, dynamic> config, Localization localization) {
    final List<String> tooltipLines = [];

    if (config['type'] == 'weapon') {
      // 这里应该从World模块获取伤害值，暂时使用固定值
      tooltipLines.add('${localization.translate('ui.status.damage')}: 1');
    } else if (config['desc_key'] != null) {
      tooltipLines.add(localization.translate(config['desc_key']));
    }

    tooltipLines.add(
        '${localization.translate('ui.status.weight')}: ${Path().getWeight(itemName)}');

    return tooltipLines.join('\n');
  }

  /// 构建出发按钮
  Widget _buildEmbarkButton(
      Path path, StateManager stateManager, Localization localization) {
    final canEmbark = path.canEmbark();

    return Tooltip(
      message: canEmbark
          ? localization.translate('messages.go_to_world_map')
          : localization.translate('messages.need_cured_meat_to_embark'),
      child: GameButton(
        text: localization.translate('ui.buttons.embark'),
        onPressed: canEmbark
            ? () {
                Logger.info(
                    '🎯 PathScreen: ${localization.translateLog('embark_button_clicked')}');
                path.embark();
              }
            : null,
        width: 80,
      ),
    );
  }

  /// 构建技能区域
  Widget _buildPerksSection(
      StateManager stateManager, Localization localization) {
    final perks = stateManager.get('character.perks', true);

    Logger.info('🎯 技能数据: $perks');

    if (perks == null || (perks as Map).isEmpty) {
      Logger.info('🎯 没有技能数据，隐藏技能区域');
      return const SizedBox.shrink();
    }

    return Container(
      width: 200, // 固定宽度，与小黑屋保持一致
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: Colors.black, width: 1), // 与StoresDisplay保持一致的边框宽度
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题 - 与StoresDisplay保持一致的位置
              Container(
                transform: Matrix4.translationValues(
                    8, -13, 0), // 与StoresDisplay保持一致的位置
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    localization.translate('ui.menus.skills'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 技能列表
              ..._buildPerksList(perks as Map<String, dynamic>, localization),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建技能列表
  List<Widget> _buildPerksList(
      Map<String, dynamic> perks, Localization localization) {
    final List<Widget> perkWidgets = [];

    for (final entry in perks.entries) {
      final perkName = entry.key;
      final hasPerk = entry.value as bool;

      if (hasPerk) {
        perkWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Tooltip(
              message: _getPerkDescription(perkName, localization),
              child: Text(
                _getLocalizedPerkName(perkName, localization),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16, // 与StoresDisplay保持一致的字体大小
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
  String _getLocalizedPerkName(String perkName, Localization localization) {
    return localization.translate('skills.$perkName');
  }

  /// 获取技能描述
  String _getPerkDescription(String perkName, Localization localization) {
    return localization.translate('skill_descriptions.$perkName');
  }

  /// 构建库存容器 - 使用统一的库存容器组件
  Widget _buildStoresContainer(
      StateManager stateManager, Localization localization) {
    return UnifiedStoresContainer(
      showPerks: true,
      perksBuilder: _buildPerksSection,
      showVillageStatus: false,
    );
  }
}

/// 三角形按钮绘制器 - 模拟原游戏的上下箭头按钮样式
class _TriangleButtonPainter extends CustomPainter {
  final bool isUp;
  final bool isEnabled;
  final bool isMany; // 是否为"Many"按钮（10个）

  _TriangleButtonPainter({
    required this.isUp,
    required this.isEnabled,
    this.isMany = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = isEnabled ? Colors.black : const Color(0xFF999999)
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 计算三角形的点位置，模拟原游戏CSS中的border样式
    final double centerX = size.width / 2;
    final double borderWidth = 6.0; // 对应原游戏CSS的border-width: 6px
    // 根据按钮类型设置内部三角形大小
    final double innerWidth = isMany ? 3.0 : 4.0; // Many按钮更细，普通按钮更粗

    ui.Path outerPath = ui.Path();
    ui.Path innerPath = ui.Path();

    if (isUp) {
      // 向上的三角形 - 模拟原游戏的upBtn样式
      // 外边框三角形
      outerPath.moveTo(centerX, 1); // 顶点
      outerPath.lineTo(centerX - borderWidth, size.height - 3); // 左下
      outerPath.lineTo(centerX + borderWidth, size.height - 3); // 右下
      outerPath.close();

      // 内部白色三角形（创建空心效果）
      innerPath.moveTo(centerX, 1 + (borderWidth - innerWidth)); // 顶点
      innerPath.lineTo(centerX - innerWidth, size.height - 3); // 左下
      innerPath.lineTo(centerX + innerWidth, size.height - 3); // 右下
      innerPath.close();
    } else {
      // 向下的三角形 - 模拟原游戏的dnBtn样式
      // 外边框三角形
      outerPath.moveTo(centerX, size.height - 1); // 底点
      outerPath.lineTo(centerX - borderWidth, 3); // 左上
      outerPath.lineTo(centerX + borderWidth, 3); // 右上
      outerPath.close();

      // 内部白色三角形（创建空心效果）
      innerPath.moveTo(
          centerX, size.height - 1 - (borderWidth - innerWidth)); // 底点
      innerPath.lineTo(centerX - innerWidth, 3); // 左上
      innerPath.lineTo(centerX + innerWidth, 3); // 右上
      innerPath.close();
    }

    // 绘制外边框三角形
    canvas.drawPath(outerPath, borderPaint);

    // 绘制内部白色三角形（创建空心效果）
    canvas.drawPath(innerPath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _TriangleButtonPainter ||
        oldDelegate.isUp != isUp ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.isMany != isMany;
  }
}
