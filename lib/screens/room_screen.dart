import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/room.dart';
import '../modules/outside.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/game_button.dart';
import '../widgets/progress_button.dart';

/// 房间界面 - 显示火焰状态、建筑和交易
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Room, StateManager, Localization>(
      builder: (context, room, stateManager, localization, child) {
        return Container(
          width: 700,
          height: 700,
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 火焰控制按钮区域
              _buildFireButtons(room, stateManager),

              const SizedBox(height: 10),

              // 伐木按钮区域（如果森林已解锁）
              _buildGatherButtons(room, stateManager),

              const SizedBox(height: 20),

              // 主要按钮区域 - 水平布局
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 建筑按钮区域
                  _buildBuildButtons(room, stateManager),

                  const SizedBox(width: 20),

                  // 制作按钮区域
                  _buildCraftButtons(room, stateManager),

                  const SizedBox(width: 20),

                  // 购买按钮区域
                  _buildBuyButtons(room, stateManager),

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

  // 火焰控制按钮
  Widget _buildFireButtons(Room room, StateManager stateManager) {
    final fireValue = stateManager.get('game.fire.value', true) ?? 0;
    final wood = stateManager.get('stores.wood', true) ?? 0;
    final bool isFree = wood == 0;

    // 根据原始游戏逻辑：火焰熄灭时显示点火按钮，否则显示添柴按钮
    if (fireValue == Room.fireEnum['Dead']!['value']) {
      // 火焰熄灭 - 显示点火按钮
      return ProgressButton(
        text: '点燃火堆',
        onPressed: () => room.lightFire(),
        cost: isFree ? null : {'wood': 5},
        width: 80,
        free: isFree,
        progressDuration: 1000, // 1秒点火时间
      );
    } else {
      // 火焰燃烧 - 显示添柴按钮
      return ProgressButton(
        text: '添柴',
        onPressed: () => room.stokeFire(),
        cost: isFree ? null : {'wood': 1},
        width: 80,
        free: isFree,
        progressDuration: 500, // 0.5秒添柴时间
      );
    }
  }

  // 伐木按钮区域 - 移除，因为伐木功能应该在Outside模块中
  Widget _buildGatherButtons(Room room, StateManager stateManager) {
    // 在房间模块中不显示伐木按钮
    // 伐木功能应该在Outside模块中实现
    return const SizedBox.shrink();
  }

  // 建筑按钮区域
  Widget _buildBuildButtons(Room room, StateManager stateManager) {
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
          ...room.craftables.entries
              .where((entry) => entry.value['type'] == 'building')
              .map((entry) => _buildCraftableButton(
                  entry.key, entry.value, room, stateManager))
              .toList(),
        ],
      ),
    );
  }

  // 制作按钮区域
  Widget _buildCraftButtons(Room room, StateManager stateManager) {
    return Container(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: const Text(
              '制作',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 制作按钮列表
          ...room.craftables.entries
              .where((entry) => entry.value['type'] != 'building')
              .map((entry) => _buildCraftableButton(
                  entry.key, entry.value, room, stateManager))
              .toList(),
        ],
      ),
    );
  }

  // 购买按钮区域
  Widget _buildBuyButtons(Room room, StateManager stateManager) {
    return Container(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: const Text(
              '购买',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 购买按钮列表
          ...room.tradeGoods.entries
              .map((entry) =>
                  _buildTradeButton(entry.key, entry.value, room, stateManager))
              .toList(),
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

  // 构建可制作物品按钮
  Widget _buildCraftableButton(String key, Map<String, dynamic> item, Room room,
      StateManager stateManager) {
    // 检查是否解锁
    final isUnlocked = room.craftUnlocked(key);
    if (!isUnlocked) return const SizedBox.shrink();

    // 计算成本
    final costFunction = item['cost'] as Function(StateManager);
    final costResult = costFunction(stateManager);
    final cost = Map<String, int>.from(costResult);

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
      text: item['name'] ?? key,
      onPressed: canAfford ? () => room.buildItem(key) : null,
      cost: cost,
      width: 130,
      disabled: !canAfford,
    );
  }

  // 构建交易物品按钮
  Widget _buildTradeButton(String key, Map<String, dynamic> item, Room room,
      StateManager stateManager) {
    // 检查是否解锁
    final isUnlocked = room.buyUnlocked(key);
    if (!isUnlocked) return const SizedBox.shrink();

    // 计算成本
    final costFunction = item['cost'] as Function(StateManager);
    final costResult = costFunction(stateManager);
    final cost = Map<String, int>.from(costResult);

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
      text: key,
      onPressed: canAfford ? () => room.buyItem(key) : null,
      cost: cost,
      width: 130,
      disabled: !canAfford,
    );
  }
}
