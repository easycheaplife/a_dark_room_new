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
          color: Colors.white, // 与房间界面一致的白色背景
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 收集木材按钮区域
              _buildGatheringButtons(outside, stateManager),

              const SizedBox(height: 20),

              // 村庄状态区域
              _buildVillageStatus(outside, stateManager),

              const SizedBox(height: 20),

              // 主要按钮区域 - 水平布局
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 建筑按钮区域
                  _buildBuildingButtons(outside, stateManager),

                  const SizedBox(width: 20),

                  // 工人管理区域
                  _buildWorkersButtons(outside, stateManager),

                  const Spacer(),

                  // 资源存储区域 - 右侧
                  _buildStoresContainer(stateManager),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 收集木材按钮区域
  Widget _buildGatheringButtons(Outside outside, StateManager stateManager) {
    return ProgressButton(
      text: '收集木材',
      onPressed: () => outside.gatherWood(),
      width: 100,
      progressDuration: 1000, // 1秒收集时间
    );
  }

  // 村庄状态区域
  Widget _buildVillageStatus(Outside outside, StateManager stateManager) {
    final population = stateManager.get('game.population', true) ?? 0;
    final maxPopulation = outside.getMaxPopulation();
    final villageTitle = outside.getTitle();

    return Container(
      width: 300,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏘️ $villageTitle',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Times New Roman',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '👥 人口: $population / $maxPopulation',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Times New Roman',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '状态: $villageTitle',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 14,
              fontFamily: 'Times New Roman',
            ),
          ),
        ],
      ),
    );
  }

  // 建筑按钮区域
  Widget _buildBuildingButtons(Outside outside, StateManager stateManager) {
    return Container(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: const Text(
              '建筑',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 建筑按钮列表
          _buildBuildingButton('小屋', {'wood': 100}, outside, stateManager),
          _buildBuildingButton('陷阱', {'wood': 10}, outside, stateManager),
        ],
      ),
    );
  }

  // 工人管理区域
  Widget _buildWorkersButtons(Outside outside, StateManager stateManager) {
    return Container(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: const Text(
              '工人',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 工人管理按钮
          _buildWorkerButton('收集者', 'gatherer', outside, stateManager),
        ],
      ),
    );
  }

  // 资源存储区域
  Widget _buildStoresContainer(StateManager stateManager) {
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
          const Text(
            '资源',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Times New Roman',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // 显示所有资源
          ...stateManager
                  .get('stores', true)
                  ?.entries
                  .map((entry) => Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Times New Roman',
                        ),
                      ))
                  .toList() ??
              [],
        ],
      ),
    );
  }

  // 构建建筑按钮
  Widget _buildBuildingButton(String name, Map<String, int> cost,
      Outside outside, StateManager stateManager) {
    // 检查是否有足够资源
    bool canAfford = true;
    for (var k in cost.keys) {
      final have = stateManager.get('stores["$k"]', true) ?? 0;
      if (have < cost[k]!) {
        canAfford = false;
        break;
      }
    }

    return GameButton(
      text: name,
      onPressed: canAfford
          ? () => _buildBuilding(name, cost, outside, stateManager)
          : null,
      cost: cost,
      width: 130,
      disabled: !canAfford,
    );
  }

  // 构建工人按钮
  Widget _buildWorkerButton(
      String name, String type, Outside outside, StateManager stateManager) {
    final currentWorkers = stateManager.get('game.workers["$type"]', true) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name: $currentWorkers',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),
          Row(
            children: [
              GameButton(
                text: '-',
                onPressed: () => outside.decreaseWorker(type, 1),
                width: 30,
              ),
              const SizedBox(width: 5),
              GameButton(
                text: '+',
                onPressed: () => outside.increaseWorker(type, 1),
                width: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 建造建筑
  void _buildBuilding(String name, Map<String, int> cost, Outside outside,
      StateManager stateManager) {
    // 扣除资源
    for (var k in cost.keys) {
      final current = stateManager.get('stores["$k"]', true) ?? 0;
      stateManager.set('stores["$k"]', current - cost[k]!);
    }

    // 增加建筑数量
    final buildingKey = name.toLowerCase();
    final current =
        stateManager.get('game.buildings["$buildingKey"]', true) ?? 0;
    stateManager.set('game.buildings["$buildingKey"]', current + 1);
  }
}
