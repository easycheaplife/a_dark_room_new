import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state_manager.dart';

/// StoresDisplay shows the player's resources
class StoresDisplay extends StatelessWidget {
  const StoresDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        // 暂时使用空的资源列表，直到我们解决类型问题
        final resources = <String, num>{};
        final weapons = <String, num>{};
        final special = <String, num>{};

        // 添加一些测试数据
        resources['wood'] = 10;
        resources['fur'] = 5;
        weapons['iron sword'] = 1;
        special['compass'] = 1;

        return Container(
          width: 200,
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resources
              if (resources.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Resources',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...resources.entries
                    .map((entry) => _buildResourceRow(entry.key, entry.value)),
              ],

              // Special items
              if (special.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Special',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...special.entries
                    .map((entry) => _buildResourceRow(entry.key, entry.value)),
              ],

              // Weapons
              if (weapons.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Weapons',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...weapons.entries
                    .map((entry) => _buildResourceRow(entry.key, entry.value)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceRow(String name, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            value.floor().toString(),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
