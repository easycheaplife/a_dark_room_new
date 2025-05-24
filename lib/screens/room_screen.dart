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
    // 获取当前火焰状态
    final fireValue = stateManager.get('game.fire.value', true) ?? 0;
    final tempValue = stateManager.get('game.temperature.value', true) ?? 0;

    // 获取火焰状态文本
    String fireText = '熄灭';
    Color fireColor = Colors.grey;

    for (final entry in Room.fireEnum.entries) {
      if (entry.value['value'] == fireValue) {
        fireText = entry.value['text'] as String;
        break;
      }
    }

    // 根据火焰状态设置颜色
    switch (fireValue) {
      case 0: fireColor = Colors.grey; break;
      case 1: fireColor = Colors.orange[300]!; break;
      case 2: fireColor = Colors.orange[500]!; break;
      case 3: fireColor = Colors.orange[700]!; break;
      case 4: fireColor = Colors.red; break;
    }

    // 获取温度状态文本
    String tempText = '冰冷';
    Color tempColor = Colors.blue;

    for (final entry in Room.tempEnum.entries) {
      if (entry.value['value'] == tempValue) {
        tempText = entry.value['text'] as String;
        break;
      }
    }

    // 根据温度设置颜色
    switch (tempValue) {
      case 0: tempColor = Colors.blue[300]!; break;
      case 1: tempColor = Colors.blue[200]!; break;
      case 2: tempColor = Colors.green[300]!; break;
      case 3: tempColor = Colors.orange[300]!; break;
      case 4: tempColor = Colors.red[300]!; break;
    }

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
            Text(
              '火$fireText。',
              style: TextStyle(
                color: fireColor,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            // 温度描述
            Text(
              '房间$tempText。',
              style: TextStyle(
                color: tempColor,
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
                    room.lightFire();
                  },
                ),
                const SizedBox(width: 12),
                SimpleButton(
                  text: '添柴',
                  onPressed: () {
                    room.stokeFire();
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
                    room.build('trap');
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
                    room.buy('scales');
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
