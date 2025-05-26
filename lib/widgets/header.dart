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

/// Header displays the navigation tabs for different game modules
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Engine, StateManager, Localization>(
      builder: (context, engine, stateManager, localization, child) {
        final activeModuleName = engine.activeModule?.name ?? 'Room';

        return Container(
          height: 40, // 原游戏header高度
          padding: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Room tab - 总是显示，根据火焰状态显示不同标题
              _buildTab(
                context,
                _getRoomTitle(stateManager),
                activeModuleName == 'Room',
                onTap: () => _navigateToModule(context, 'Room'),
              ),

              // Outside tab - 只有在解锁森林后才显示
              if (_isOutsideUnlocked(stateManager))
                _buildTab(
                  context,
                  '静谧森林',
                  activeModuleName == 'Outside',
                  onTap: () => _navigateToModule(context, 'Outside'),
                ),

              // Path tab - 只有在获得指南针后才显示
              if (_isPathUnlocked(stateManager))
                _buildTab(
                  context,
                  '尘土飞扬的小径',
                  activeModuleName == 'Path',
                  onTap: () => _navigateToModule(context, 'Path'),
                ),

              // World tab - 只有在解锁世界后才显示
              if (_isWorldUnlocked(stateManager))
                _buildTab(
                  context,
                  '世界',
                  activeModuleName == 'World',
                  onTap: () => _navigateToModule(context, 'World'),
                ),

              // Fabricator tab - 只有在解锁制造器后才显示
              if (_isFabricatorUnlocked(stateManager))
                _buildTab(
                  context,
                  '嗡嗡作响的制造器',
                  activeModuleName == 'Fabricator',
                  onTap: () => _navigateToModule(context, 'Fabricator'),
                ),

              // Ship tab - 只有在解锁飞船后才显示
              if (_isShipUnlocked(stateManager))
                _buildTab(
                  context,
                  '飞船',
                  activeModuleName == 'Ship',
                  onTap: () => _navigateToModule(context, 'Ship'),
                ),

              // 语言切换按钮
              const Spacer(),
              _buildLanguageButton(context, localization),
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
    return fireValue < 2 ? '黑暗房间' : '火光房间';
  }

  Widget _buildTab(BuildContext context, String title, bool isSelected,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontFamily: 'Times New Roman',
            decoration: isSelected ? TextDecoration.underline : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, Localization localization) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.language,
        color: Colors.white,
      ),
      onSelected: (String languageCode) {
        localization.switchLanguage(languageCode);
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'zh',
          child: Text('中文'),
        ),
        const PopupMenuItem<String>(
          value: 'en',
          child: Text('English'),
        ),
      ],
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
