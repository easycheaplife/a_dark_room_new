import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/outside.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/game_button.dart';
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
          child: Stack(
            children: [
              // 收集木材按钮区域 - 左上角
              Positioned(
                left: 0,
                top: 0,
                child: _buildGatheringButtons(outside, stateManager),
              ),

              // 村庄状态区域 - 原游戏位置: top: 0px, right: 0px
              Positioned(
                right: 0,
                top: 0,
                child: _buildVillageStatus(outside, stateManager),
              ),

              // 工人管理区域 - 原游戏位置: top: -4px, left: 160px
              Positioned(
                left: 160,
                top: -4,
                child: _buildWorkersButtons(outside, stateManager),
              ),

              // 库存容器 - 原游戏中在Outside模块也显示，位置动态调整
              Positioned(
                right: 0,
                top: _calculateStoresTop(outside, stateManager),
                child: _buildStoresContainer(stateManager),
              ),
            ],
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
        ProgressButton(
          text: '伐木',
          onPressed: () => outside.gatherWood(),
          width: 100,
          progressDuration: 1000, // 1秒收集时间
        ),

        // 如果有陷阱，显示检查陷阱按钮
        if (numTraps > 0) ...[
          const SizedBox(height: 10), // 垂直间距
          ProgressButton(
            text: '查看陷阱',
            onPressed: () => outside.checkTraps(),
            width: 100,
            progressDuration: 1500, // 1.5秒检查时间
          ),
        ],
      ],
    );
  }

  // 村庄状态区域 - 模拟原游戏的 village 容器
  Widget _buildVillageStatus(Outside outside, StateManager stateManager) {
    final population = stateManager.get('game.population', true) ?? 0;
    final villageTitle = outside.getTitle(); // 这会根据小屋数量动态变化
    final numHuts = stateManager.get('game.buildings.hut', true) ?? 0;

    // 如果没有小屋，不显示村庄状态
    if (numHuts == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 村庄标题 - 模拟原游戏的 data-legend 属性
          Container(
            transform: Matrix4.translationValues(8, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                villageTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),

          // 人口显示 - 模拟原游戏的 population 容器
          Container(
            transform: Matrix4.translationValues(10, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '人口 $population',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 显示建筑物状态
          ..._buildBuildingsList(stateManager),
        ],
      ),
    );
  }

  // 构建建筑物列表
  List<Widget> _buildBuildingsList(StateManager stateManager) {
    final List<Widget> buildings = [];
    final gameBuildings = stateManager.get('game.buildings', true) ?? {};

    for (final entry in gameBuildings.entries) {
      final buildingName = entry.key;
      final buildingCount = entry.value as int;

      if (buildingCount > 0) {
        if (buildingName == 'trap') {
          // 陷阱特殊处理：显示有饵料和无饵料的陷阱
          final numBait = stateManager.get('stores.bait', true) ?? 0;
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
        return '制革厂';
      case 'smokehouse':
        return '熏制房';
      case 'workshop':
        return '工作坊';
      case 'steelworks':
        return '钢铁厂';
      case 'armoury':
        return '军械库';
      default:
        return buildingName;
    }
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
          _buildWorkerButton('伐木者', 'gatherer', outside, stateManager),
          _buildWorkerButton('猎人', 'hunter', outside, stateManager),
          _buildWorkerButton('制革工', 'tanner', outside, stateManager),
          _buildWorkerButton('制钢工', 'steelworker', outside, stateManager),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
    );
  }

  // 构建工人控制按钮 - 模拟原游戏的上下箭头按钮
  Widget _buildWorkerControlButton(String text, VoidCallback? onPressed) {
    return Container(
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
      case 'tanner':
        return (stateManager.get('game.buildings.tannery', true) ?? 0) > 0;
      case 'steelworker':
        return (stateManager.get('game.buildings.steelworks', true) ?? 0) > 0;
      default:
        return false;
    }
  }

  // 计算库存容器的顶部位置 - 模拟原游戏的动态定位
  double _calculateStoresTop(Outside outside, StateManager stateManager) {
    final numHuts = stateManager.get('game.buildings.hut', true) ?? 0;

    if (numHuts == 0) {
      // 没有村庄时，库存容器在默认位置
      return 0;
    } else {
      // 有村庄时，库存容器在村庄下方
      // 原游戏使用: village.height() + 26 + Outside._STORES_OFFSET
      // 我们估算村庄高度约为 150px，加上间距
      return 150 + 26;
    }
  }

  // 库存容器 - 模拟原游戏的 storesContainer
  Widget _buildStoresContainer(StateManager stateManager) {
    final stores = stateManager.get('stores', true) ?? {};
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 - 模拟原游戏的 data-legend 属性
          Container(
            transform: Matrix4.translationValues(8, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: const Text(
                '库存',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),

          // 资源列表
          ...resourceStores.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
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
              )),
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
}
