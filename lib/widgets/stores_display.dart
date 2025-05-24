import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state_manager.dart';

/// StoresDisplay shows the player's resources
class StoresDisplay extends StatelessWidget {
  const StoresDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        // 从StateManager获取实际的资源数据
        final storesData = stateManager.get('stores');
        final stores = storesData != null ? Map<String, dynamic>.from(storesData) : <String, dynamic>{};

        final resources = <String, num>{};
        final weapons = <String, num>{};
        final special = <String, num>{};

        // 分类资源
        for (final entry in stores.entries) {
          final value = entry.value as num? ?? 0;
          // 显示所有资源，包括0值的资源（玩家需要看到当前状态）

          switch (entry.key) {
            case 'wood':
            case 'fur':
            case 'meat':
            case 'bait':
            case 'leather':
            case 'cured meat':
            case 'iron':
            case 'coal':
            case 'sulphur':
            case 'steel':
            case 'bullets':
            case 'scales':
            case 'teeth':
            case 'medicine':
            case 'energy cell':
            case 'alien alloy':
              resources[entry.key] = value;
              break;
            case 'iron sword':
            case 'steel sword':
            case 'rifle':
            case 'bone spear':
            case 'bolas':
            case 'grenade':
            case 'bayonet':
            case 'laser rifle':
              weapons[entry.key] = value;
              break;
            case 'compass':
            case 'torch':
            case 'waterskin':
            case 'cask':
            case 'water tank':
            case 'rucksack':
            case 'wagon':
            case 'convoy':
            case 'l armour':
            case 'i armour':
            case 's armour':
              special[entry.key] = value;
              break;
          }
        }

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
