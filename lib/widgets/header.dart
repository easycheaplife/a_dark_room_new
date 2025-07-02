import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/engine.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/responsive_layout.dart';
import '../modules/room.dart';
import '../modules/outside.dart';
import '../modules/path.dart';
// import '../modules/world.dart'; // 移除世界模块导入，不再需要独立的世界页签
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
        final activeModule = engine.activeModule;
        final layoutParams = GameLayoutParams.getLayoutParams(context);

        // 检查页签导航是否被禁用（如在世界地图中）
        if (!engine.tabNavigation) {
          return Container(
            height: layoutParams.useVerticalLayout ? 50 : 40, // 移动端增加高度
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 右侧空间填充
                const Spacer(),

                // 语言切换按钮
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: PopupMenuButton<String>(
                    onSelected: (String language) =>
                        _switchLanguage(context, language),
                    icon: Icon(
                      Icons.language,
                      color: Colors.black,
                      size: layoutParams.useVerticalLayout ? 24 : 20, // 移动端增大图标
                    ),
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
                  ),
                ),

                // 设置按钮
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    onPressed: () => _openSettings(context),
                    icon: Icon(
                      Icons.settings,
                      color: Colors.black,
                      size: layoutParams.useVerticalLayout ? 24 : 20, // 移动端增大图标
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 构建可用的页签列表
        List<Widget> tabs = [];

        // Room tab - 总是显示，根据火焰状态显示不同标题
        tabs.add(_buildTab(
          context,
          _getRoomTitle(stateManager, localization),
          activeModule is Room,
          onTap: () => _navigateToModule(context, 'Room'),
          isFirst: true, // 第一个页签
        ));

        // Outside tab - 只有在解锁森林后才显示
        if (_isOutsideUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            _getOutsideTitle(stateManager, localization),
            activeModule is Outside,
            onTap: () => _navigateToModule(context, 'Outside'),
          ));
        }

        // Path tab - 只有在获得指南针后才显示
        if (_isPathUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            localization.translate('ui.menus.path'),
            activeModule is Path,
            onTap: () => _navigateToModule(context, 'Path'),
          ));
        }

        // World tab - 移除世界页签，用户只能通过漫漫尘途的出发功能进入世界地图
        // 世界地图现在作为漫漫尘途模块的一部分，不再是独立页签

        // Fabricator tab - 只有在解锁制造器后才显示
        if (_isFabricatorUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            localization.translate('ui.menus.fabricator'),
            activeModule is Fabricator,
            onTap: () => _navigateToModule(context, 'Fabricator'),
          ));
        }

        // Ship tab - 只有在解锁飞船后才显示
        if (_isShipUnlocked(stateManager)) {
          tabs.add(_buildTab(
            context,
            localization.translate('ui.menus.ship'),
            activeModule is Ship,
            onTap: () => _navigateToModule(context, 'Ship'),
          ));
        }

        return Container(
          height: layoutParams.useVerticalLayout ? 50 : 40, // 移动端增加高度
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: layoutParams.useVerticalLayout
              ? _buildMobileHeader(context, tabs, localization, layoutParams)
              : _buildDesktopHeader(context, tabs, localization, layoutParams),
        );
      },
    );
  }

  /// 移动端Header布局 - 优化移动设备显示
  Widget _buildMobileHeader(BuildContext context, List<Widget> tabs,
      Localization localization, GameLayoutParams layoutParams) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 页签列表 - 可横向滚动
          ...tabs,

          // 右侧按钮组
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 语言切换按钮
                PopupMenuButton<String>(
                  onSelected: (String language) =>
                      _switchLanguage(context, language),
                  icon: Icon(
                    Icons.language,
                    color: Colors.black,
                    size: 24, // 移动端增大图标
                  ),
                  tooltip: localization.translate('ui.menus.language'),
                  itemBuilder: (BuildContext context) {
                    final supportedLanguages = {
                      'zh': localization.translate('ui.language.chinese'),
                      'en': localization.translate('ui.language.english'),
                    };

                    return supportedLanguages.entries.map((entry) {
                      return PopupMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Text(
                              entry.value,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight:
                                    entry.key == localization.currentLanguage
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            if (entry.key == localization.currentLanguage)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.check,
                                    color: Colors.green, size: 16),
                              ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),

                // 导入/导出按钮
                IconButton(
                  onPressed: () => _openImportExport(context),
                  icon: const Icon(
                    Icons.save_alt,
                    color: Colors.black,
                    size: 24, // 移动端增大图标
                  ),
                  tooltip: localization.translate('ui.menus.import_export'),
                ),

                // 设置按钮
                IconButton(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.black,
                    size: 24, // 移动端增大图标
                  ),
                  tooltip: localization.translate('ui.menus.settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 桌面端Header布局 - 保持原有设计
  Widget _buildDesktopHeader(BuildContext context, List<Widget> tabs,
      Localization localization, GameLayoutParams layoutParams) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 页签列表
        ...tabs,

        // 右侧空间填充
        const Spacer(),

        // 语言切换按钮
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: PopupMenuButton<String>(
            onSelected: (String language) => _switchLanguage(context, language),
            icon: const Icon(
              Icons.language,
              color: Colors.black,
              size: 20,
            ),
            tooltip: localization.translate('ui.menus.language'),
            itemBuilder: (BuildContext context) {
              final supportedLanguages = {
                'zh': localization.translate('ui.language.chinese'),
                'en': localization.translate('ui.language.english'),
              };

              return supportedLanguages.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: entry.key == localization.currentLanguage
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (entry.key == localization.currentLanguage)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child:
                              Icon(Icons.check, color: Colors.green, size: 16),
                        ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ),

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
            tooltip: localization.translate('ui.menus.import_export'),
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
            tooltip: localization.translate('ui.menus.settings'),
          ),
        ),
      ],
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
      // World 导航已移除 - 世界地图现在通过漫漫尘途的出发功能访问
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

  // 切换语言
  void _switchLanguage(BuildContext context, String language) {
    final localization = Provider.of<Localization>(context, listen: false);
    localization.switchLanguage(language);
  }

  // 检查森林是否解锁
  bool _isOutsideUnlocked(StateManager stateManager) {
    return stateManager.get('features.location.outside') == true;
  }

  // 检查路径是否解锁
  bool _isPathUnlocked(StateManager stateManager) {
    final compassCount = stateManager.get('stores.compass', true) ?? 0;

    // 检查是否有足够资源制作指南针
    final fur = stateManager.get('stores.fur', true) ?? 0;
    final scales = stateManager.get('stores.scales', true) ?? 0;
    final teeth = stateManager.get('stores.teeth', true) ?? 0;
    final hasTradingPost =
        (stateManager.get('game.buildings["trading post"]', true) ?? 0) > 0;

    // 如果有指南针，直接解锁
    if (compassCount > 0) {
      return true;
    }

    // 如果有交易站且有足够资源制作指南针，也显示页签
    if (hasTradingPost && fur >= 400 && scales >= 20 && teeth >= 10) {
      return true;
    }

    return false;
  }

  // 检查世界是否解锁 - 已移除，世界地图现在通过漫漫尘途访问
  // bool _isWorldUnlocked(StateManager stateManager) {
  //   return stateManager.get('features.location.world') == true;
  // }

  // 检查制造器是否解锁
  bool _isFabricatorUnlocked(StateManager stateManager) {
    return stateManager.get('features.location.fabricator') == true;
  }

  // 检查飞船是否解锁
  bool _isShipUnlocked(StateManager stateManager) {
    return stateManager.get('features.location.spaceShip') == true;
  }

  // 获取房间标题（根据火焰状态）
  String _getRoomTitle(StateManager stateManager, Localization localization) {
    final fireValue = stateManager.get('game.fire.value', true) ?? 0;
    return fireValue < 2
        ? localization.translate('ui.titles.dark_room')
        : localization.translate('ui.titles.lit_room');
  }

  // 获取外部区域标题（根据小屋数量）
  String _getOutsideTitle(
      StateManager stateManager, Localization localization) {
    final numHuts =
        (stateManager.get('game.buildings["hut"]', true) ?? 0) as int;

    if (numHuts == 0) {
      return localization.translate("ui.titles.quiet_forest");
    } else if (numHuts == 1) {
      return localization.translate("ui.titles.lonely_hut");
    } else if (numHuts <= 4) {
      return localization.translate("ui.titles.small_village");
    } else if (numHuts <= 8) {
      return localization.translate("ui.titles.medium_village");
    } else if (numHuts <= 14) {
      return localization.translate("ui.titles.large_village");
    } else {
      return localization.translate("ui.titles.bustling_town");
    }
  }

  Widget _buildTab(BuildContext context, String title, bool isSelected,
      {VoidCallback? onTap, bool isFirst = false}) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: layoutParams.useVerticalLayout ? 8 : 10, // 移动端减少内边距
          vertical: layoutParams.useVerticalLayout ? 10 : 8, // 移动端增加垂直内边距
        ),
        margin: EdgeInsets.only(
            left: isFirst
                ? 0
                : (layoutParams.useVerticalLayout ? 5 : 10)), // 移动端减少间距
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
            fontSize: layoutParams.useVerticalLayout ? 15 : 17, // 移动端减小字体
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
