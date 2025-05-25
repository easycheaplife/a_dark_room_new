import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/outside.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/simple_button.dart';

/// 外部界面 - 显示村庄状态、建筑和工人管理
class OutsideScreen extends StatelessWidget {
  const OutsideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Outside, StateManager, Localization>(
      builder: (context, outside, stateManager, localization, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 收集区域
              _GatheringSection(outside: outside, stateManager: stateManager, localization: localization),

              const SizedBox(height: 24),

              // 村庄状态区域
              _VillageSection(outside: outside, stateManager: stateManager, localization: localization),

              const SizedBox(height: 24),

              // 建筑区域
              _BuildingSection(outside: outside, stateManager: stateManager, localization: localization),

              const SizedBox(height: 24),

              // 工人管理区域
              _WorkersSection(outside: outside, stateManager: stateManager, localization: localization),
            ],
          ),
        );
      },
    );
  }
}

class _GatheringSection extends StatelessWidget {
  final Outside outside;
  final StateManager stateManager;
  final Localization localization;

  const _GatheringSection({
    required this.outside,
    required this.stateManager,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌲 ${localization.translate('outside.gatherWood')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 收集木材
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('outside.gatherWood'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        localization.translate('outside.gatherWoodDesc'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleButton(
                  text: localization.translate('actions.gather'),
                  onPressed: () {
                    outside.gatherWood();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 检查陷阱
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('outside.checkTraps'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        localization.translate('outside.checkTrapsDesc'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleButton(
                  text: localization.translate('actions.check'),
                  onPressed: () {
                    outside.checkTraps();
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

class _VillageSection extends StatelessWidget {
  final Outside outside;
  final StateManager stateManager;
  final Localization localization;

  const _VillageSection({
    required this.outside,
    required this.stateManager,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏘️ 村庄',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 人口信息
            const Row(
              children: [
                Icon(Icons.people, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '人口: 0 / 20',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 村庄状态
            const Text(
              '状态: 一个孤独的小屋',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            // 人口进度条
            LinearProgressIndicator(
              value: 0.0,
              backgroundColor: Colors.grey[700],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildingSection extends StatelessWidget {
  final Outside outside;
  final StateManager stateManager;
  final Localization localization;

  const _BuildingSection({
    required this.outside,
    required this.stateManager,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
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
                        '小屋',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '需要: 木材 100',
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
}

class _WorkersSection extends StatelessWidget {
  final Outside outside;
  final StateManager stateManager;
  final Localization localization;

  const _WorkersSection({
    required this.outside,
    required this.stateManager,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '👷 工人管理',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                const Text(
                  '可用人口: 0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 工人示例
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '收集者',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '当前工人: 0',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    SimpleButton(
                      text: '-',
                      onPressed: () {
                        outside.decreaseWorker('gatherer', 1);
                      },
                      width: 40,
                    ),
                    const SizedBox(width: 8),
                    SimpleButton(
                      text: '+',
                      onPressed: () {
                        outside.increaseWorker('gatherer', 1);
                      },
                      width: 40,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
