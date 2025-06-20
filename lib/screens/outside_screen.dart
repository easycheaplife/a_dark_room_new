import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/outside.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/localization_helper.dart';
import '../widgets/progress_button.dart';

/// 外部界面 - 显示村庄状态、建筑和工人管理
/// 使用与房间界面一致的UI风格
class OutsideScreen extends StatelessWidget {
  const OutsideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Outside, StateManager, Localization>(
      builder: (context, outside, stateManager, localization, child) {
        return Container(
          width: 700,
          height: 700,
          color: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部行：收集按钮、工人管理、村庄状态
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 收集木材按钮区域
                      _buildGatheringButtons(outside, stateManager),

                      const SizedBox(width: 20),

                      // 工人管理区域
                      Expanded(
                        child: _buildWorkersButtons(outside, stateManager),
                      ),

                      const SizedBox(width: 20),

                      // 村庄状态区域
                      _buildVillageStatus(outside, stateManager),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 底部：库存容器
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildStoresContainer(stateManager),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 收集木材按钮区域
  Widget _buildGatheringButtons(Outside outside, StateManager stateManager) {
    final numTraps = stateManager.get('game.buildings.trap', true) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 伐木按钮
        Consumer<Localization>(
          builder: (context, localization, child) {
            return ProgressButton(
              text: LocalizationHelper().localizeButtonText('gather wood'),
              onPressed: () => outside.gatherWood(),
              width: 100,
              progressDuration: 1000, // 1秒收集时间
            );
          },
        ),

        // 如果有陷阱，显示检查陷阱按钮
        if (numTraps > 0) ...[
          const SizedBox(height: 10), // 垂直间距
          Consumer<Localization>(
            builder: (context, localization, child) {
              return ProgressButton(
                text: LocalizationHelper().localizeButtonText('check traps'),
                onPressed: () => outside.checkTraps(),
                width: 100,
                progressDuration: 1500, // 1.5秒检查时间
              );
            },
          ),
        ],
      ],
    );
  }

  // 村庄状态区域 - 模拟原游戏的 village 容器，支持折叠显示
  Widget _buildVillageStatus(Outside outside, StateManager stateManager) {
    final numHuts = stateManager.get('game.buildings.hut', true) ?? 0;

    // 如果没有小屋，不显示村庄状态
    if (numHuts == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<Localization>(
      builder: (context, localization, child) {
        return _VillageWidget(
          outside: outside,
          stateManager: stateManager,
          localization: localization,
        );
      },
    );
  }

  // 工人管理区域 - 模拟原游戏的 workers 容器
  Widget _buildWorkersButtons(Outside outside, StateManager stateManager) {
    final population = stateManager.get('game.population', true) ?? 0;

    // 如果没有人口，不显示工人管理
    if (population == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 工人管理按钮
          _buildWorkerButton(
              LocalizationHelper().localizeButtonText('gatherer'),
              'gatherer',
              outside,
              stateManager),
          _buildWorkerButton(LocalizationHelper().localizeButtonText('hunter'),
              'hunter', outside, stateManager),
          _buildWorkerButton(LocalizationHelper().localizeButtonText('trapper'),
              'trapper', outside, stateManager),
          _buildWorkerButton(LocalizationHelper().localizeButtonText('tanner'),
              'tanner', outside, stateManager),
          _buildWorkerButton(
              LocalizationHelper().localizeButtonText('charcutier'),
              'charcutier',
              outside,
              stateManager),
          _buildWorkerButton(
              LocalizationHelper().localizeButtonText('steelworker'),
              'steelworker',
              outside,
              stateManager),
        ],
      ),
    );
  }

  // 构建工人按钮 - 模拟原游戏的 workerRow 样式
  Widget _buildWorkerButton(
      String name, String type, Outside outside, StateManager stateManager) {
    final currentWorkers = stateManager.get('game.workers["$type"]', true) ?? 0;
    final population = stateManager.get('game.population', true) ?? 0;
    final totalWorkers = stateManager
            .get('game.workers', true)
            ?.values
            .fold(0, (sum, count) => sum + count) ??
        0;
    final availableWorkers = population - totalWorkers;

    // 检查是否有相应的建筑物解锁此工人类型
    bool isUnlocked = _isWorkerUnlocked(type, stateManager);
    if (!isUnlocked) {
      return const SizedBox.shrink();
    }

    // 获取工人的生产/消耗信息
    final workerInfo = _getWorkerInfo(type, currentWorkers, availableWorkers);

    // 对于伐木者，显示剩余人口数量，不显示调整按钮
    if (type == 'gatherer') {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Tooltip(
          message: workerInfo,
          child: Row(
            children: [
              // 工人名称
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              // 显示剩余人口数量（伐木者数量）
              Text(
                '$availableWorkers',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Tooltip(
        message: workerInfo,
        child: Row(
          children: [
            // 工人名称和数量
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),

            // 工人数量和控制按钮
            Row(
              children: [
                Text(
                  '$currentWorkers',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Times New Roman',
                  ),
                ),

                const SizedBox(width: 5),

                // 减少按钮
                _buildWorkerControlButton(
                  '▼',
                  currentWorkers > 0
                      ? () => outside.decreaseWorker(type, 1)
                      : null,
                ),

                const SizedBox(width: 2),

                // 增加按钮
                _buildWorkerControlButton(
                  '▲',
                  availableWorkers > 0
                      ? () => outside.increaseWorker(type, 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建工人控制按钮 - 模拟原游戏的上下箭头按钮
  Widget _buildWorkerControlButton(String text, VoidCallback? onPressed) {
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
                fontSize: 8,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 检查工人类型是否已解锁
  bool _isWorkerUnlocked(String type, StateManager stateManager) {
    switch (type) {
      case 'gatherer':
        return true; // 伐木者总是可用
      case 'hunter':
        return (stateManager.get('game.buildings.lodge', true) ?? 0) > 0;
      case 'trapper':
        return (stateManager.get('game.buildings.lodge', true) ?? 0) >
            0; // 陷阱师也由狩猎小屋解锁
      case 'tanner':
        return (stateManager.get('game.buildings.tannery', true) ?? 0) > 0;
      case 'charcutier':
        return (stateManager.get('game.buildings.smokehouse', true) ?? 0) >
            0; // 熏肉师由熏肉房解锁
      case 'steelworker':
        return (stateManager.get('game.buildings.steelworks', true) ?? 0) > 0;
      default:
        return false;
    }
  }

  // 获取工人的生产/消耗信息
  String _getWorkerInfo(String type, int currentWorkers, int availableWorkers) {
    // 基于原游戏的收入配置
    const incomeConfig = {
      'gatherer': {
        'name': '伐木者',
        'delay': 10,
        'stores': {'wood': 1}
      },
      'hunter': {
        'name': '猎人',
        'delay': 10,
        'stores': {'fur': 0.5, 'meat': 0.5}
      },
      'trapper': {
        'name': '陷阱师',
        'delay': 10,
        'stores': {'meat': -1, 'bait': 1}
      },
      'tanner': {
        'name': '皮革师',
        'delay': 10,
        'stores': {'fur': -5, 'leather': 1}
      },
      'charcutier': {
        'name': '熏肉师',
        'delay': 10,
        'stores': {'meat': -5, 'wood': -5, 'cured meat': 1}
      },
      'steelworker': {
        'name': '钢铁工',
        'delay': 10,
        'stores': {'coal': -1, 'iron': -1, 'steel': 1}
      },
    };

    final config = incomeConfig[type];
    if (config == null) return '';

    final stores = config['stores'] as Map<String, dynamic>;
    final delay = config['delay'] as int;

    List<String> effects = [];

    // 计算当前工人的效果
    if (type == 'gatherer') {
      final totalProduction = availableWorkers * (stores['wood'] as num);
      if (totalProduction > 0) {
        effects.add('生产: +${totalProduction.toStringAsFixed(1)} 木材 每$delay秒');
      }
    } else {
      for (final entry in stores.entries) {
        final resource = entry.key;
        final rate = entry.value as num;
        final totalRate = currentWorkers * rate;

        if (totalRate != 0) {
          final resourceName =
              LocalizationHelper().localizeButtonText(resource);
          final prefix = totalRate > 0 ? '+' : '';
          effects.add(
              '${totalRate > 0 ? '生产' : '消耗'}: $prefix${totalRate.toStringAsFixed(1)} $resourceName 每$delay秒');
        }
      }
    }

    if (effects.isEmpty) {
      return '当前无生产/消耗';
    }

    return effects.join('\n');
  }

  // 库存容器 - 模拟原游戏的 storesContainer，支持折叠显示
  Widget _buildStoresContainer(StateManager stateManager) {
    return Consumer<Localization>(
      builder: (context, localization, child) {
        return _StoresWidget(
            stateManager: stateManager, localization: localization);
      },
    );
  }
}

// 可折叠的库存显示组件
class _StoresWidget extends StatefulWidget {
  final StateManager stateManager;
  final Localization localization;

  const _StoresWidget({
    required this.stateManager,
    required this.localization,
  });

  @override
  State<_StoresWidget> createState() => _StoresWidgetState();
}

class _StoresWidgetState extends State<_StoresWidget> {
  bool _isExpanded = true; // 默认展开

  @override
  Widget build(BuildContext context) {
    final stores = widget.stateManager.get('stores', true) ?? {};
    final resourceStores = <String, dynamic>{};

    // 过滤出资源类物品（非武器、非升级、非建筑）
    for (var entry in stores.entries) {
      final key = entry.key;
      if (key.contains('blueprint')) continue; // 跳过蓝图

      // 这里需要根据物品类型分类，暂时显示所有非武器物品
      if (!_isWeapon(key)) {
        resourceStores[key] = entry.value;
      }
    }

    if (resourceStores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 可点击的标题栏
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  // 标题 - 模拟原游戏的 data-legend 属性
                  Container(
                    transform: Matrix4.translationValues(8, -13, 0),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            LocalizationHelper().localizeMenuText('库存'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Times New Roman',
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 可折叠的资源列表
          if (_isExpanded) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: resourceStores.entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Tooltip(
                            message: _getResourceIncomeInfo(entry.key),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getLocalizedResourceName(entry.key),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: 'Times New Roman',
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: 'Times New Roman',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 判断是否为武器
  bool _isWeapon(String itemName) {
    const weapons = [
      'bone spear',
      'iron sword',
      'steel sword',
      'rifle',
      'bolas',
      'grenade',
      'bayonet',
      'laser rifle'
    ];
    return weapons.contains(itemName);
  }

  // 获取本地化资源名称
  String _getLocalizedResourceName(String resourceKey) {
    return LocalizationHelper().localizeButtonText(resourceKey);
  }

  // 获取资源的收入信息
  String _getResourceIncomeInfo(String resourceKey) {
    final income = widget.stateManager.get('income', true) ?? {};
    List<String> effects = [];

    // 遍历所有收入来源，查找影响此资源的
    for (final entry in income.entries) {
      final sourceName = entry.key;
      final incomeData = entry.value;
      final stores = incomeData['stores'] as Map<String, dynamic>? ?? {};
      final delay = incomeData['delay'] as int? ?? 10;

      if (stores.containsKey(resourceKey)) {
        final rate = stores[resourceKey] as num;
        if (rate != 0) {
          final sourceDisplayName = _getWorkerDisplayName(sourceName);
          final prefix = rate > 0 ? '+' : '';
          effects.add(
              '$sourceDisplayName: $prefix${rate.toStringAsFixed(1)} 每$delay秒');
        }
      }
    }

    if (effects.isEmpty) {
      return '无生产/消耗';
    }

    // 计算总计
    double totalRate = 0;
    int commonDelay = 10;
    for (final entry in income.entries) {
      final incomeData = entry.value;
      final stores = incomeData['stores'] as Map<String, dynamic>? ?? {};
      if (stores.containsKey(resourceKey)) {
        totalRate += (stores[resourceKey] as num).toDouble();
      }
    }

    if (totalRate != 0) {
      final prefix = totalRate > 0 ? '+' : '';
      effects.add('总计: $prefix${totalRate.toStringAsFixed(1)} 每$commonDelay秒');
    }

    return effects.join('\n');
  }

  // 获取工人显示名称
  String _getWorkerDisplayName(String workerKey) {
    const workerNames = {
      'gatherer': '伐木者',
      'hunter': '猎人',
      'trapper': '陷阱师',
      'tanner': '制革工',
      'charcutier': '熏肉师',
      'steelworker': '钢铁工',
      'thieves': '小偷',
    };
    return workerNames[workerKey] ?? workerKey;
  }
}

// 可折叠的村庄状态显示组件
class _VillageWidget extends StatefulWidget {
  final Outside outside;
  final StateManager stateManager;
  final Localization localization;

  const _VillageWidget({
    required this.outside,
    required this.stateManager,
    required this.localization,
  });

  @override
  State<_VillageWidget> createState() => _VillageWidgetState();
}

class _VillageWidgetState extends State<_VillageWidget> {
  bool _isExpanded = true; // 默认展开

  @override
  Widget build(BuildContext context) {
    final population = widget.stateManager.get('game.population', true) ?? 0;
    final villageTitle = widget.outside.getTitle(); // 这会根据小屋数量动态变化

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 可点击的村庄标题栏
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      // 村庄标题 - 模拟原游戏的 data-legend 属性
                      Container(
                        transform: Matrix4.translationValues(-8, -13, 0),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                villageTitle,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Times New Roman',
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 可折叠的建筑物列表
              if (_isExpanded) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildBuildingsList(),
                  ),
                ),
              ],
            ],
          ),

          // 人口显示 - 与村庄标题在同一水平线上，右侧位置
          Positioned(
            top: -3,
            right: 10,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '人口 $population/${widget.outside.getMaxPopulation()}',
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

  // 构建建筑物列表
  List<Widget> _buildBuildingsList() {
    final List<Widget> buildings = [];
    final gameBuildings = widget.stateManager.get('game.buildings', true) ?? {};

    for (final entry in gameBuildings.entries) {
      final buildingName = entry.key;
      final buildingCount = entry.value as int;

      if (buildingCount > 0) {
        if (buildingName == 'trap') {
          // 陷阱特殊处理：显示有饵料和无饵料的陷阱
          final numBait = widget.stateManager.get('stores.bait', true) ?? 0;
          final baitedTraps =
              (numBait < buildingCount) ? numBait : buildingCount;
          final unbaitedTraps = buildingCount - baitedTraps;

          if (unbaitedTraps > 0) {
            buildings.add(
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '陷阱: $unbaitedTraps',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
            );
          }

          if (baitedTraps > 0) {
            buildings.add(
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '有饵陷阱: $baitedTraps',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
            );
          }
        } else {
          // 其他建筑物的显示
          String localizedName = _getBuildingLocalizedName(buildingName);
          buildings.add(
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '$localizedName: $buildingCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          );
        }
      }
    }

    return buildings;
  }

  // 获取建筑物的本地化名称
  String _getBuildingLocalizedName(String buildingName) {
    switch (buildingName) {
      case 'hut':
        return '小屋';
      case 'cart':
        return '手推车';
      case 'lodge':
        return '狩猎小屋';
      case 'trading post':
        return '贸易站';
      case 'tannery':
        return '制革屋';
      case 'smokehouse':
        return '熏肉房';
      case 'workshop':
        return '工坊';
      case 'steelworks':
        return '炼钢坊';
      case 'armoury':
        return '军械库';
      default:
        return buildingName;
    }
  }
}
