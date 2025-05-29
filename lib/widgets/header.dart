import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/engine.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../modules/room.dart';
import '../modules/outside.dart';
import '../modules/path.dart';
import '../modules/world.dart';
import '../modules/fabricator.dart';
import '../modules/ship.dart';
import '../screens/settings_screen.dart';
import 'import_export_dialog.dart';

/// Header displays the navigation tabs for different game modules
/// 基于原始游戏的header.js实现
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Engine, StateManager, Localization>(
      builder: (context, engine, stateManager, localization, child) {
        final activeModuleName = engine.activeModule?.name ?? 'Room';

        // 构建可用的页签列表
        List<Widget> tabs = [];

        // Room tab - 总是显示，根据火焰状态显示不同标题
        tabs.add(_buildTab(
          context,
          _getRoomTitle(stateManager),
          activeModuleName == 'Room',
          onTap: () => _navigateToModule(context, 'Room'),
          isFirst: true, // 第一个页签
        ));

        // Outside tab - 只有在解锁森林后才显示
        if (_isOutsideUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            _getOutsideTitle(stateManager),
            activeModuleName == 'Outside',
            onTap: () => _navigateToModule(context, 'Outside'),
          ));
        }

        // Path tab - 只有在获得指南针后才显示
        if (_isPathUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            '尘土飞扬的小径',
            activeModuleName == 'Path',
            onTap: () => _navigateToModule(context, 'Path'),
          ));
        }

        // World tab - 只有在解锁世界后才显示
        if (_isWorldUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            '世界',
            activeModuleName == 'World',
            onTap: () => _navigateToModule(context, 'World'),
          ));
        }

        // Fabricator tab - 只有在解锁制造器后才显示
        if (_isFabricatorUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            '嗡嗡作响的制造器',
            activeModuleName == 'Fabricator',
            onTap: () => _navigateToModule(context, 'Fabricator'),
          ));
        }

        // Ship tab - 只有在解锁飞船后才显示
        if (_isShipUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            '飞船',
            activeModuleName == 'Ship',
            onTap: () => _navigateToModule(context, 'Ship'),
          ));
        }

        return Container(
          height: 40, // 原游戏header高度
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 页签列表
              ...tabs,

              // 右侧空间填充
              const Spacer(),

              // 导入/导出按钮
              Container(
                margin: const EdgeInsets.only(right: 5),
                child: IconButton(
                  onPressed: () => _openImportExport(context),
                  icon: const Icon(
                    Icons.save_alt,
                    color: Colors.black,
                    size: 20,
                  ),
                  tooltip: '导入/导出存档',
                ),
              ),

              // 设置按钮
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.black,
                    size: 20,
                  ),
                  tooltip: '游戏设置',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 导航到指定模块
  void _navigateToModule(BuildContext context, String moduleName) {
    final engine = Provider.of<Engine>(context, listen: false);

    switch (moduleName) {
      case 'Room':
        engine.travelTo(Provider.of<Room>(context, listen: false));
        break;
      case 'Outside':
        engine.travelTo(Provider.of<Outside>(context, listen: false));
        break;
      case 'Path':
        engine.travelTo(Provider.of<Path>(context, listen: false));
        break;
      case 'World':
        engine.travelTo(Provider.of<World>(context, listen: false));
        break;
      case 'Fabricator':
        engine.travelTo(Provider.of<Fabricator>(context, listen: false));
        break;
      case 'Ship':
        engine.travelTo(Provider.of<Ship>(context, listen: false));
        break;
    }
  }

  // 打开导入/导出对话框
  void _openImportExport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ImportExportDialog(),
    );
  }

  // 打开设置页面
  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  // 检查森林是否解锁
  bool _isOutsideUnlocked(StateManager stateManager) {
    return stateManager.get('features.location.outside') == true;
  }

  // 检查路径是否解锁
  bool _isPathUnlocked(StateManager stateManager) {
    return (stateManager.get('stores.compass', true) ?? 0) > 0;
  }

  // 检查世界是否解锁
  bool _isWorldUnlocked(StateManager stateManager) {
    return stateManager.get('features.location.world') == true;
  }

  // 检查制造器是否解锁
  bool _isFabricatorUnlocked(StateManager stateManager) {
    return stateManager.get('features.location.fabricator') == true;
  }

  // 检查飞船是否解锁
  bool _isShipUnlocked(StateManager stateManager) {
    return stateManager.get('features.location.ship') == true;
  }

  // 获取房间标题（根据火焰状态）
  String _getRoomTitle(StateManager stateManager) {
    final fireValue = stateManager.get('game.fire.value', true) ?? 0;
    return fireValue < 2 ? '小黑屋' : '生火间';
  }

  // 获取外部区域标题（根据小屋数量）
  String _getOutsideTitle(StateManager stateManager) {
    final numHuts =
        (stateManager.get('game.buildings["hut"]', true) ?? 0) as int;

    if (numHuts == 0) {
      return "静谧森林";
    } else if (numHuts == 1) {
      return "孤独小屋";
    } else if (numHuts <= 4) {
      return "小型村落";
    } else if (numHuts <= 8) {
      return "中型村落";
    } else if (numHuts <= 14) {
      return "大型村落";
    } else {
      return "喧嚣小镇";
    }
  }

  Widget _buildTab(BuildContext context, String title, bool isSelected,
      {VoidCallback? onTap, bool isFirst = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: EdgeInsets.only(left: isFirst ? 0 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: isFirst
                ? BorderSide.none
                : const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 17, // 原游戏字体大小
            fontFamily: 'Times New Roman',
            decoration: isSelected ? TextDecoration.underline : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Add a location tab
  static Widget addLocation(String title, String name, dynamic module) {
    // This would create a tab for a module
    // In the original game, this would add a tab to the header
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
