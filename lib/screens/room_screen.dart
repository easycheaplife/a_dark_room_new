import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/room.dart';
import '../core/state_manager.dart';
import '../widgets/simple_button.dart';

/// 房间界面 - 显示火焰状态、建筑和交易
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Room, StateManager>(
      builder: (context, room, stateManager, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 火焰状态区域
              _buildFireSection(context, room, stateManager),

              const SizedBox(height: 24),

              // 建筑区域
              _buildBuildingSection(context, room, stateManager),

              const SizedBox(height: 24),

              // 交易区域
              _buildTradingSection(context, room, stateManager),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFireSection(BuildContext context, Room room, StateManager stateManager) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔥 火焰',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 火焰状态描述
            const Text(
              '火已熄灭。',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            // 温度描述
            const Text(
              '房间里很冷。',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            // 火焰控制按钮
            Row(
              children: [
                SimpleButton(
                  text: '点火',
                  onPressed: () {
                    // TODO: 实现点火功能
                  },
                ),
                const SizedBox(width: 12),
                SimpleButton(
                  text: '收集木材',
                  onPressed: () {
                    // TODO: 实现收集木材功能
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingSection(BuildContext context, Room room, StateManager stateManager) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏗️ 建筑',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 建筑示例
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '陷阱',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '需要: 木材 10',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleButton(
                  text: '建造',
                  onPressed: () {
                    // TODO: 实现建造功能
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingSection(BuildContext context, Room room, StateManager stateManager) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🛒 交易',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 商品示例
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '鳞片',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '需要: 毛皮 150',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleButton(
                  text: '购买',
                  onPressed: () {
                    // TODO: 实现购买功能
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
