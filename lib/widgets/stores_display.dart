import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';

/// StoresDisplay shows the player's resources
class StoresDisplay extends StatelessWidget {
  const StoresDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StateManager, Localization>(
      builder: (context, stateManager, localization, child) {
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    localization.translate('resources.title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...resources.entries
                    .map((entry) => _buildResourceRow(entry.key, entry.value, localization)),
              ],

              // Special items
              if (special.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '特殊物品',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...special.entries
                    .map((entry) => _buildResourceRow(entry.key, entry.value, localization)),
              ],

              // Weapons
              if (weapons.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '武器',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...weapons.entries
                    .map((entry) => _buildResourceRow(entry.key, entry.value, localization)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceRow(String name, num value, Localization localization) {
    // 获取本地化的资源名称
    String localizedName = localization.translate('resources.$name');
    if (localizedName == 'resources.$name') {
      // 如果没有找到翻译，使用原名称
      localizedName = name;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizedName,
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
