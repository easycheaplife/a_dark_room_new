import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/room.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/simple_button.dart';

/// 房间界面 - 显示火焰状态、建筑和交易
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Room, StateManager, Localization>(
      builder: (context, room, stateManager, localization, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 火焰状态区域
              _buildFireSection(context, room, stateManager, localization),

              const SizedBox(height: 24),

              // 建筑区域
              _buildBuildingSection(context, room, stateManager, localization),

              const SizedBox(height: 24),

              // 交易区域
              _buildTradingSection(context, room, stateManager, localization),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFireSection(BuildContext context, Room room, StateManager stateManager, Localization localization) {
    // 获取当前火焰状态
    final fireValue = stateManager.get('game.fire.value', true) ?? 0;
    final tempValue = stateManager.get('game.temperature.value', true) ?? 0;

    // 获取火焰状态文本
    String fireText = 'dead';
    Color fireColor = Colors.grey;

    for (final entry in Room.fireEnum.entries) {
      if (entry.value['value'] == fireValue) {
        fireText = entry.key; // 使用key作为翻译键
        break;
      }
    }

    // 本地化火焰状态文本
    final localizedFireText = localization.translate('fire.$fireText');

    // 根据火焰状态设置颜色
    switch (fireValue) {
      case 0: fireColor = Colors.grey; break;
      case 1: fireColor = Colors.orange[300]!; break;
      case 2: fireColor = Colors.orange[500]!; break;
      case 3: fireColor = Colors.orange[700]!; break;
      case 4: fireColor = Colors.red; break;
    }

    // 获取温度状态文本
    String tempText = 'freezing';
    Color tempColor = Colors.blue;

    for (final entry in Room.tempEnum.entries) {
      if (entry.value['value'] == tempValue) {
        tempText = entry.key; // 使用key作为翻译键
        break;
      }
    }

    // 本地化温度状态文本
    final localizedTempText = localization.translate('temperature.$tempText');

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
              '🔥 ${localization.translate('ui.fire')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 火焰状态描述
            Text(
              '火$localizedFireText。',
              style: TextStyle(
                color: fireColor,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            // 温度描述
            Text(
              '房间$localizedTempText。',
              style: TextStyle(
                color: tempColor,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            // 火焰控制按钮 - 根据火焰状态显示不同按钮
            _buildFireButtons(context, room, stateManager, fireValue, localization),
          ],
        ),
      ),
    );
  }

  Widget _buildFireButtons(BuildContext context, Room room, StateManager stateManager, int fireValue, Localization localization) {
    final wood = stateManager.get('stores.wood', true) ?? 0;
    final bool isFree = wood == 0;

    // 根据原始游戏逻辑：火焰熄灭时显示点火按钮，否则显示添柴按钮
    if (fireValue == Room.fireEnum['Dead']!['value']) {
      // 火焰熄灭 - 显示点火按钮
      return Row(
        children: [
          SimpleButton(
            text: isFree
              ? localization.translate('room.lightFireFree')
              : localization.translate('room.lightFire'),
            onPressed: () {
              room.lightFire();
            },
          ),
        ],
      );
    } else {
      // 火焰燃烧 - 显示添柴按钮
      return Row(
        children: [
          SimpleButton(
            text: isFree
              ? localization.translate('room.stokeFireFree')
              : localization.translate('room.stokeFire'),
            onPressed: () {
              room.stokeFire();
            },
          ),
        ],
      );
    }
  }

  Widget _buildBuildingSection(BuildContext context, Room room, StateManager stateManager, Localization localization) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏗️ ${localization.translate('buildings.title')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 建筑示例
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('buildings.trap'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        localization.translate('buildings.costs.trap'),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleButton(
                  text: localization.translate('actions.build'),
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

  Widget _buildTradingSection(BuildContext context, Room room, StateManager stateManager, Localization localization) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🛒 ${localization.translate('ui.trading')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 商品示例
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('resources.scales'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        localization.translate('formats.cost_format', ['${localization.translate('resources.fur')} 150']),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleButton(
                  text: localization.translate('actions.buy'),
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
