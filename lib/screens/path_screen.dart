import 'package:flutter/material.dart';
import '../widgets/simple_button.dart';

/// 路径界面 - 显示装备管理和出发准备
class PathScreen extends StatelessWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 装备状态区域
          _OutfitSection(),

          SizedBox(height: 24),

          // 制作区域
          _CraftingSection(),

          SizedBox(height: 24),

          // 出发区域
          _EmbarkSection(),
        ],
      ),
    );
  }
}

class _OutfitSection extends StatelessWidget {
  const _OutfitSection();

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
              '🎒 装备',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 容量信息
            const Row(
              children: [
                Icon(Icons.inventory, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '容量: 0.0 / 10.0',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 16),
                Text(
                  '剩余: 10.0',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 容量进度条
            LinearProgressIndicator(
              value: 0.0,
              backgroundColor: Colors.grey[700],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),

            const SizedBox(height: 16),

            // 装备列表
            const Text(
              '背包是空的',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _CraftingSection extends StatelessWidget {
  const _CraftingSection();

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
              '🔨 制作',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 制作物品示例
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '火把',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '需要: 木材 1, 布 1',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleButton(
                  text: '制作',
                  onPressed: () {
                    // TODO: 实现制作功能
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

class _EmbarkSection extends StatelessWidget {
  const _EmbarkSection();

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
              '🚶 出发',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 出发状态
            const Text(
              '准备好出发探索世界',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            // 出发按钮
            Center(
              child: SimpleButton(
                text: '出发探索',
                onPressed: () {
                  // TODO: 实现出发功能
                },
                width: 200,
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
