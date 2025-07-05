import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/world.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/responsive_layout.dart';
import '../core/logger.dart';
import '../screens/events_screen.dart';
import '../screens/combat_screen.dart';

/// 世界地图屏幕 - 参考原游戏的world.js
class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  @override
  void initState() {
    super.initState();
    // 设置键盘监听
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final world = Provider.of<World>(context, listen: false);
      _handleKeyPress(event, world);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return Scaffold(
      backgroundColor: Colors.white, // 白色背景
      body: Stack(
        children: [
          // 主界面
          Consumer<World>(
            builder: (context, world, child) {
              return Column(
                children: [
                  // 主内容区域 - 使用SingleChildScrollView让页面可滚动
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                          layoutParams.useVerticalLayout ? 12 : 16),
                      physics: const ClampingScrollPhysics(), // 使用更平滑的滚动物理
                      child: Column(
                        children: [
                          // 背包区域 - 参考原游戏的bagspace-world
                          _buildBagspace(world, layoutParams),

                          SizedBox(
                              height: layoutParams.useVerticalLayout ? 12 : 16),

                          // 地图区域 - 固定大小，不滚动
                          _buildMap(world, layoutParams),

                          // APK版本专用：方向按钮
                          if (!kIsWeb) ...[
                            SizedBox(
                                height:
                                    layoutParams.useVerticalLayout ? 12 : 16),
                            _buildDirectionButtons(world, layoutParams),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 事件界面覆盖层
          const EventsScreen(),

          // 战斗界面覆盖层
          const CombatScreen(),
        ],
      ),
    );
  }

  /// 构建地图 - 参考原游戏的drawMap函数，固定大小显示地图，不使用内部滚动
  Widget _buildMap(World world, GameLayoutParams layoutParams) {
    try {
      final mapData = world.state?['map'];
      final maskData = world.state?['mask'];

      if (mapData == null || maskData == null) {
        return Consumer<Localization>(
          builder: (context, localization, child) {
            return Center(
              child: Text(
                localization.translate('world.map_not_initialized'),
                style: const TextStyle(color: Colors.black), // 黑色文字
              ),
            );
          },
        );
      }

      final map =
          List<List<String>>.from(mapData.map((row) => List<String>.from(row)));
      final mask =
          List<List<bool>>.from(maskData.map((row) => List<bool>.from(row)));
      final curPos = world.getCurrentPosition();

      // 确保地图数据有效
      if (map.isEmpty || map[0].isEmpty || mask.isEmpty || mask[0].isEmpty) {
        return Consumer<Localization>(
          builder: (context, localization, child) {
            return Center(
              child: Text(
                localization.translate('world.map_data_empty'),
                style: const TextStyle(color: Colors.black), // 黑色文字
              ),
            );
          },
        );
      }

      // 参考原游戏：显示完整的61x61地图 (0 <= i,j <= RADIUS * 2)
      // 原游戏代码：for(var j = 0; j <= World.RADIUS * 2; j++) { for(var i = 0; i <= World.RADIUS * 2; i++)
      const radius = 30; // 原游戏的World.RADIUS = 30
      final mapSize = radius * 2 + 1; // 61x61

      return Center(
        child: GestureDetector(
          onTapDown: (details) => _handleMapClick(details, world),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: const BoxDecoration(
              color: Colors.white, // 白色背景，与原游戏一致
              border: Border.fromBorderSide(
                BorderSide(color: Colors.black, width: 1), // 黑色边框
              ),
            ),
            // 参考原游戏CSS: overflow: hidden - 地图固定大小，不滚动
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(), // 使用更平滑的滚动物理
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const ClampingScrollPhysics(), // 使用更平滑的滚动物理
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(mapSize, (j) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(mapSize, (i) {
                        // 检查遮罩：只有mask[i][j]为true或者是玩家位置时才显示内容
                        final isPlayerPos = i == curPos[0] && j == curPos[1];
                        final isVisible = mask[i][j] || isPlayerPos;

                        return _buildMapTile(
                          map[i][j],
                          isVisible, // 使用遮罩系统控制可见性
                          isPlayerPos, // 检查是否是玩家位置
                          i, // X坐标
                          j, // Y坐标
                          world,
                          layoutParams,
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Consumer<Localization>(
        builder: (context, localization, child) {
          return Center(
            child: Text(
              '${localization.translate('world.map_render_error')}: $e',
              style: const TextStyle(color: Colors.red),
            ),
          );
        },
      );
    }
  }

  /// 构建地图瓦片 - 参考原游戏的drawMap函数逻辑
  Widget _buildMapTile(String tile, bool visible, bool isPlayer, int x, int y,
      World world, GameLayoutParams layoutParams) {
    // 如果不可见且不是玩家位置，显示空白（对应原游戏的'&nbsp;'）
    if (!visible && !isPlayer) {
      final tileSize = layoutParams.useVerticalLayout ? 8.0 : 12.0;
      final fontSize = layoutParams.useVerticalLayout ? 8.0 : 10.0;

      return Container(
        width: tileSize, // 移动端使用更小的瓦片
        height: tileSize,
        alignment: Alignment.center,
        child: Text(
          ' ', // 空白字符
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'Courier',
          ),
        ),
      );
    }

    String displayChar;
    Color color = Colors.grey;
    String? tooltip;
    bool isLandmarkStyle = false; // 是否使用地标样式（黑色粗体）

    if (isPlayer) {
      displayChar = '@';
      color = Colors.yellow;
      tooltip = Localization().translate('world.wanderer');
      isLandmarkStyle = true;
    } else {
      // 参考原游戏的地标显示逻辑
      // 原游戏逻辑：if(typeof World.LANDMARKS[c] != 'undefined' && (c != World.TILE.OUTPOST || !World.outpostUsed(i, j)))

      // 获取原始字符（去掉可能的'!'标记）
      final originalTile = tile.length > 1 ? tile[0] : tile;
      final isVisited = tile.length > 1 && tile.endsWith('!'); // 检查是否已访问
      final isLandmark =
          _isLandmarkTile(originalTile) || originalTile == 'A'; // 村庄也是地标
      // 修复：使用指定位置检查前哨站是否已使用，而不是当前位置
      final isUsedOutpost = (originalTile == 'P' && world.outpostUsed(x, y));

      if (isLandmark && !isUsedOutpost && !isVisited) {
        // 未访问的地标 - 显示为地标样式（黑色粗体）
        displayChar = originalTile;
        final styleResult = _getLandmarkStyle(originalTile);
        color = styleResult['color'];
        tooltip = styleResult['tooltip'];
        isLandmarkStyle = true;
      } else {
        // 已访问的地标、已使用的前哨站或普通地形 - 显示为普通样式
        displayChar = originalTile;

        if (isVisited && isLandmark) {
          // 已访问的地标显示为普通灰色，与原游戏一致（#999）
          color = const Color(0xFF999999); // 原游戏CSS中的#999颜色
          final styleResult = _getLandmarkStyle(originalTile);
          tooltip = styleResult['tooltip'];
        } else {
          // 普通地形
          color = _getTerrainColor(displayChar);
        }
        isLandmarkStyle = false;
      }
    }

    final tileSize = layoutParams.useVerticalLayout ? 8.0 : 12.0;
    final fontSize = layoutParams.useVerticalLayout ? 8.0 : 10.0;

    Widget tileWidget = Container(
      width: tileSize, // 移动端使用更小的瓦片
      height: tileSize,
      alignment: Alignment.center,
      child: Text(
        displayChar,
        style: TextStyle(
          color: color,
          fontSize: fontSize, // 移动端使用更小的字体
          fontFamily: 'Courier',
          fontWeight: isLandmarkStyle ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );

    if (tooltip != null) {
      tileWidget = Tooltip(
        message: tooltip,
        child: tileWidget,
      );
    }

    return tileWidget;
  }

  /// 检查是否是地标瓦片
  bool _isLandmarkTile(String tile) {
    const landmarks = [
      'H',
      'V',
      'O',
      'Y',
      'P',
      'W',
      'I',
      'C',
      'S',
      'B',
      'F',
      'M',
      'U',
      'X'
    ];
    return landmarks.contains(tile);
  }

  /// 获取地标样式 - 参考原游戏，所有未访问地标都使用黑色粗体
  Map<String, dynamic> _getLandmarkStyle(String tile) {
    final localization = Localization();
    switch (tile) {
      case 'A': // 村庄
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.village')
        };
      case 'H': // 房子
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.old_house')
        };
      case 'V': // 洞穴
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.damp_cave')
        };
      case 'O': // 小镇
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.abandoned_town')
        };
      case 'Y': // 城市
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.ruined_city')
        };
      case 'P': // 前哨站
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.outpost')
        };
      case 'W': // 飞船
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.crashed_starship')
        };
      case 'I': // 铁矿
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.iron_mine')
        };
      case 'C': // 煤矿
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.coal_mine')
        };
      case 'S': // 硫磺矿
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.sulphur_mine')
        };
      case 'B': // 钻孔
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.borehole')
        };
      case 'F': // 战场
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.battlefield')
        };
      case 'M': // 沼泽
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.dark_swamp')
        };
      case 'U': // 缓存
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.destroyed_village')
        };
      case 'X': // 执行者
        return {
          'color': Colors.black,
          'tooltip': localization.translate('world.terrain.destroyed_starship')
        };
      default:
        return {'color': Colors.black, 'tooltip': null};
    }
  }

  /// 获取地形颜色 - 参考原游戏，普通地形使用#999灰色
  Color _getTerrainColor(String tile) {
    // 所有普通地形都使用原游戏的#999灰色
    return const Color(0xFF999999); // 原游戏CSS中的#999颜色
  }

  /// 构建背包区域 - 参考原游戏的bagspace-world和updateSupplies函数
  Widget _buildBagspace(World world, GameLayoutParams layoutParams) {
    return Consumer<Path>(
      builder: (context, path, child) {
        final supplies = <Widget>[];

        // 参考原游戏逻辑：首先添加水
        if (world.water > 0) {
          final localization = Localization();
          supplies.add(_buildSupplyItem(
              localization.translate('world.bagspace.water'), world.water));
        }

        // 然后按照原游戏逻辑添加其他物品
        for (final entry in path.outfit.entries) {
          final itemName = entry.key;
          final num = entry.value;

          if (num > 0) {
            if (itemName == 'cured meat') {
              // 熏肉：如果有水则在水后面，否则在最前面
              final localization = Localization();
              final curedMeatText =
                  localization.translate('world.bagspace.cured_meat');
              if (world.water > 0) {
                // 在水后面插入（这里简化为直接添加）
                supplies.add(_buildSupplyItem(curedMeatText, num));
              } else {
                // 在最前面插入
                supplies.insert(0, _buildSupplyItem(curedMeatText, num));
              }
            } else {
              // 其他物品添加到末尾
              supplies
                  .add(_buildSupplyItem(_getItemDisplayName(itemName), num));
            }
          }
        }

        // 计算背包信息
        final total = path.outfit.entries.fold<double>(0.0, (sum, entry) {
          return sum + (entry.value * path.getWeight(entry.key));
        });
        final capacity = path.getCapacity();
        final freeSpace = capacity - total;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 让容器根据内容自适应高度
            children: [
              // 标题行 - 参考原游戏的布局，使用Stack来实现绝对定位
              SizedBox(
                height: 20, // 给Stack设置高度
                child: Stack(
                  children: [
                    // 背包标题 - 左侧
                    Positioned(
                      left: 10,
                      top: 0,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Consumer<Localization>(
                          builder: (context, localization, child) {
                            return Text(
                              (StateManager().get('stores["rucksack"]', true) ??
                                          0) >
                                      0
                                  ? localization
                                      .translate('world.bagspace.backpack')
                                  : localization
                                      .translate('world.bagspace.pocket'),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 生命值 - 左侧中间位置
                    Positioned(
                      left: 80,
                      top: 0,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Consumer<Localization>(
                          builder: (context, localization, child) {
                            return Text(
                              '${localization.translate('world.status.health')}: ${world.health}/${world.getMaxHealth()}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 距离信息 - 中间位置
                    Positioned(
                      left: 200,
                      top: 0,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Consumer<Localization>(
                          builder: (context, localization, child) {
                            return Text(
                              '${localization.translate('world.status.distance')}: ${world.getDistance()}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 背包空间信息 - 右侧
                    Positioned(
                      right: 10,
                      top: 0,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Consumer<Localization>(
                          builder: (context, localization, child) {
                            return Text(
                              '${localization.translate('world.bagspace.remaining')} ${freeSpace.floor()}/${capacity.floor()}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 物品列表 - 去掉局部滚动，显示全部物品
              Wrap(
                spacing: 5,
                runSpacing: 6,
                children: supplies,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 获取物品显示名称 - 参考原游戏的物品翻译
  String _getItemDisplayName(String itemName) {
    final localization = Localization();
    final translatedName = localization.translate('resources.$itemName');

    // 如果翻译存在且不等于原键名，返回翻译
    if (translatedName != 'resources.$itemName') {
      return translatedName;
    }

    // 否则返回原名称
    return itemName;
  }

  /// 构建补给品项目
  Widget _buildSupplyItem(String name, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$name: $count',
        style: const TextStyle(color: Colors.black, fontSize: 12), // 黑色文字
      ),
    );
  }

  /// 处理键盘按键
  void _handleKeyPress(KeyDownEvent event, World world) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        world.moveNorth();
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        world.moveSouth();
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        world.moveWest();
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        world.moveEast();
        break;
    }
  }

  /// 处理地图点击 - 参考原游戏的click函数，使用象限判断
  void _handleMapClick(TapDownDetails details, World world) {
    final localPosition = details.localPosition;
    final curPos = world.curPos;

    final tileSize = 12.0;
    final padding = 4.0;

    // 参考原游戏的click函数逻辑
    // 计算地图中心点（玩家位置）
    final mapWidth = (30 * 2 + 1) * tileSize; // 61 * 12
    final mapHeight = (30 * 2 + 1) * tileSize; // 61 * 12
    final centreX = padding + mapWidth * curPos[0] / (30 * 2);
    final centreY = padding + mapHeight * curPos[1] / (30 * 2);

    // 计算相对于中心的点击位置
    final clickX = localPosition.dx - centreX;
    final clickY = localPosition.dy - centreY;

    // APK版本适配：如果不是Web平台，使用简化的移动逻辑
    if (!kIsWeb) {
      _handleMobileMapClick(localPosition, curPos, world);
      return;
    }

    // Web版本：使用原游戏的象限判断逻辑
    if (clickX > clickY && clickX < -clickY) {
      world.moveNorth();
    } else if (clickX < clickY && clickX > -clickY) {
      world.moveSouth();
    } else if (clickX < clickY && clickX < -clickY) {
      world.moveWest();
    } else if (clickX > clickY && clickX > -clickY) {
      world.moveEast();
    }
    // 如果点击在玩家位置 (deltaX == 0 && deltaY == 0)，不移动
  }

  /// APK版本地图点击处理 - 修复坐标系映射问题
  void _handleMobileMapClick(
      Offset localPosition, List<int> curPos, World world) {
    // 获取地图容器的实际尺寸
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final mapSize = renderBox.size;

    // 计算地图中心点（屏幕中央）
    final centreX = mapSize.width / 2;
    final centreY = mapSize.height / 2;

    // 计算相对于中心的点击位置
    final clickX = localPosition.dx - centreX;
    final clickY = localPosition.dy - centreY;

    Logger.info(
        '📱 APK移动: 地图尺寸=${mapSize.width}x${mapSize.height}, 玩家位置=[${curPos[0]}, ${curPos[1]}]');
    Logger.info(
        '📱 APK移动: 中心点=($centreX, $centreY), 点击位置=(${localPosition.dx}, ${localPosition.dy})');
    Logger.info('📱 APK移动: 相对位置=($clickX, $clickY)');

    // APK版本坐标系修正：根据问题描述分析坐标映射
    // 当前问题现象：
    // - 点击下方 -> 实际向左移动 (错误，应该向南)
    // - 点击右方 -> 实际向上移动 (错误，应该向东)
    // - 点击上方 -> 实际向上移动 (可能正确，应该向北)
    // - 点击左方 -> 实际向左移动 (可能正确，应该向西)

    final absX = clickX.abs();
    final absY = clickY.abs();

    Logger.info(
        '📱 APK坐标分析: clickX=$clickX, clickY=$clickY, absX=$absX, absY=$absY');

    // 根据最新问题现象分析坐标映射
    // 当前问题现象（第三次更新）：
    // - 点击下方 -> 实际向左移动 (错误，应该向南)
    // - 点击右方 -> 实际向上移动 (错误，应该向东)
    // - 点击上方 -> 实际向上移动 (可能正确，应该向北)
    // - 点击左方 -> 实际向上移动 (错误，应该向西)

    // 分析：看起来大部分点击都导致向上移动，这很奇怪
    // 可能是坐标计算本身有问题，或者事件处理有问题

    const int mappingScheme = 10; // 10: 添加方向按钮方案

    switch (mappingScheme) {
      case 10: // 添加方向按钮方案 - 最直接的解决方案
        Logger.info('📱 APK方案10: 方向按钮方案');
        // 这个方案不使用点击移动，而是在界面上添加方向按钮
        // 点击地图时显示提示信息
        Logger.info('📱 请使用屏幕上的方向按钮进行移动');
        break;

      case 9: // 全新的按键式移动方案 - 完全不同的思路
        Logger.info('📱 APK方案9: 按键式移动方案');
        _handleKeyboardStyleMovement(localPosition, mapSize, world);
        break;

      case 7: // 全新的诊断和修复方案
        Logger.info('📱 APK方案7: 全新诊断方案');
        Logger.info(
            '📱 详细坐标: localPosition=(${localPosition.dx}, ${localPosition.dy})');
        Logger.info('📱 地图尺寸: ${mapSize.width} x ${mapSize.height}');
        Logger.info('📱 中心点: ($centreX, $centreY)');
        Logger.info('📱 相对坐标: ($clickX, $clickY)');
        Logger.info('📱 绝对值: absX=$absX, absY=$absY');

        // 使用更简单直接的方向判断
        if (clickY > 10) {
          // 明确点击下方
          Logger.info('📱 APK方案7: 南 (明确点击下方，clickY=$clickY > 10)');
          world.moveSouth();
        } else if (clickY < -10) {
          // 明确点击上方
          Logger.info('📱 APK方案7: 北 (明确点击上方，clickY=$clickY < -10)');
          world.moveNorth();
        } else if (clickX > 10) {
          // 明确点击右方
          Logger.info('📱 APK方案7: 东 (明确点击右方，clickX=$clickX > 10)');
          world.moveEast();
        } else if (clickX < -10) {
          // 明确点击左方
          Logger.info('📱 APK方案7: 西 (明确点击左方，clickX=$clickX < -10)');
          world.moveWest();
        } else {
          Logger.info(
              '📱 APK方案7: 点击太接近中心，不移动 (clickX=$clickX, clickY=$clickY)');
        }
        break;

      case 8: // 屏幕区域划分方案
        Logger.info('📱 APK方案8: 屏幕区域划分');
        // 将屏幕划分为4个区域，直接根据点击位置判断
        final screenCenterX = mapSize.width / 2;
        final screenCenterY = mapSize.height / 2;

        Logger.info('📱 屏幕中心: ($screenCenterX, $screenCenterY)');
        Logger.info('📱 点击位置: (${localPosition.dx}, ${localPosition.dy})');

        if (localPosition.dy > screenCenterY + 50) {
          // 点击屏幕下半部分
          Logger.info('📱 APK方案8: 南 (屏幕下半部分)');
          world.moveSouth();
        } else if (localPosition.dy < screenCenterY - 50) {
          // 点击屏幕上半部分
          Logger.info('📱 APK方案8: 北 (屏幕上半部分)');
          world.moveNorth();
        } else if (localPosition.dx > screenCenterX + 50) {
          // 点击屏幕右半部分
          Logger.info('📱 APK方案8: 东 (屏幕右半部分)');
          world.moveEast();
        } else if (localPosition.dx < screenCenterX - 50) {
          // 点击屏幕左半部分
          Logger.info('📱 APK方案8: 西 (屏幕左半部分)');
          world.moveWest();
        } else {
          Logger.info('📱 APK方案8: 点击中心区域，不移动');
        }
        break;

      case 5: // 完全重新映射方案
        Logger.info('📱 APK方案5: 完全重新映射');
        if (absY > absX) {
          if (clickY > 0) {
            // 点击下方 -> 强制向南
            Logger.info('📱 APK方案5: 南 (点击下方→强制南)');
            world.moveSouth();
          } else {
            // 点击上方 -> 强制向北
            Logger.info('📱 APK方案5: 北 (点击上方→强制北)');
            world.moveNorth();
          }
        } else if (absX > absY) {
          if (clickX > 0) {
            // 点击右方 -> 强制向东
            Logger.info('📱 APK方案5: 东 (点击右方→强制东)');
            world.moveEast();
          } else {
            // 点击左方 -> 强制向西
            Logger.info('📱 APK方案5: 西 (点击左方→强制西)');
            world.moveWest();
          }
        }
        break;

      case 6: // 使用原游戏象限逻辑但修正坐标
        Logger.info('📱 APK方案6: 使用原游戏象限逻辑');
        // 尝试使用原游戏的象限判断，但可能需要坐标修正
        if (clickX > clickY && clickX < -clickY) {
          Logger.info('📱 APK方案6: 北 (象限判断)');
          world.moveNorth();
        } else if (clickX < clickY && clickX > -clickY) {
          Logger.info('📱 APK方案6: 南 (象限判断)');
          world.moveSouth();
        } else if (clickX < clickY && clickX < -clickY) {
          Logger.info('📱 APK方案6: 西 (象限判断)');
          world.moveWest();
        } else if (clickX > clickY && clickX > -clickY) {
          Logger.info('📱 APK方案6: 东 (象限判断)');
          world.moveEast();
        }
        break;

      default: // 原始方案
        if (absX > absY) {
          if (clickX > 0) {
            Logger.info('📱 APK默认: 东');
            world.moveEast();
          } else {
            Logger.info('📱 APK默认: 西');
            world.moveWest();
          }
        } else if (absY > absX) {
          if (clickY > 0) {
            Logger.info('📱 APK默认: 南');
            world.moveSouth();
          } else {
            Logger.info('📱 APK默认: 北');
            world.moveNorth();
          }
        }
        break;
    }
    // 如果点击在中心附近 (absX ≈ absY)，不移动
  }

  /// 全新的按键式移动方案 - 完全不同的思路
  void _handleKeyboardStyleMovement(
      Offset localPosition, Size mapSize, World world) {
    Logger.info('📱 按键式移动: 开始处理');

    // 将屏幕划分为9个区域，像数字键盘一样
    final thirdWidth = mapSize.width / 3;
    final thirdHeight = mapSize.height / 3;

    final x = localPosition.dx;
    final y = localPosition.dy;

    Logger.info(
        '📱 按键式移动: 点击位置=($x, $y), 屏幕尺寸=${mapSize.width}x${mapSize.height}');
    Logger.info('📱 按键式移动: 区域尺寸=${thirdWidth}x$thirdHeight');

    // 确定点击在哪个区域
    int col = 0; // 0=左, 1=中, 2=右
    int row = 0; // 0=上, 1=中, 2=下

    if (x < thirdWidth) {
      col = 0; // 左
    } else if (x < thirdWidth * 2) {
      col = 1; // 中
    } else {
      col = 2; // 右
    }

    if (y < thirdHeight) {
      row = 0; // 上
    } else if (y < thirdHeight * 2) {
      row = 1; // 中
    } else {
      row = 2; // 下
    }

    Logger.info('📱 按键式移动: 区域位置=($col, $row)');

    // 根据区域位置决定移动方向（像数字键盘）
    // 7 8 9
    // 4 5 6
    // 1 2 3

    if (row == 0 && col == 1) {
      // 上中 (8) -> 北
      Logger.info('📱 按键式移动: 北 (上中区域)');
      world.moveNorth();
    } else if (row == 2 && col == 1) {
      // 下中 (2) -> 南
      Logger.info('📱 按键式移动: 南 (下中区域)');
      world.moveSouth();
    } else if (row == 1 && col == 0) {
      // 中左 (4) -> 西
      Logger.info('📱 按键式移动: 西 (中左区域)');
      world.moveWest();
    } else if (row == 1 && col == 2) {
      // 中右 (6) -> 东
      Logger.info('📱 按键式移动: 东 (中右区域)');
      world.moveEast();
    } else if (row == 1 && col == 1) {
      // 中心 (5) -> 不移动
      Logger.info('📱 按键式移动: 中心区域，不移动');
    } else {
      // 对角线区域，选择最近的主方向
      if (row == 0) {
        // 上排的对角线，优先向北
        Logger.info('📱 按键式移动: 北 (上排对角线)');
        world.moveNorth();
      } else if (row == 2) {
        // 下排的对角线，优先向南
        Logger.info('📱 按键式移动: 南 (下排对角线)');
        world.moveSouth();
      } else {
        // 不应该到这里
        Logger.info('📱 按键式移动: 未知区域，不移动');
      }
    }
  }

  /// 构建方向按钮（仅APK版本）
  Widget _buildDirectionButtons(World world, GameLayoutParams layoutParams) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 标题
          Text(
            '移动控制',
            style: TextStyle(
              fontSize: layoutParams.useVerticalLayout ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // 方向按钮布局
          Column(
            children: [
              // 上方按钮
              _buildDirectionButton('↑', '北', () {
                Logger.info('📱 方向按钮: 北');
                world.moveNorth();
              }, layoutParams),

              const SizedBox(height: 8),

              // 中间一行：左、中、右
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDirectionButton('←', '西', () {
                    Logger.info('📱 方向按钮: 西');
                    world.moveWest();
                  }, layoutParams),

                  const SizedBox(width: 16),

                  // 中间显示当前位置
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '[${world.curPos[0]}, ${world.curPos[1]}]',
                        style: TextStyle(
                          fontSize: layoutParams.useVerticalLayout ? 10 : 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  _buildDirectionButton('→', '东', () {
                    Logger.info('📱 方向按钮: 东');
                    world.moveEast();
                  }, layoutParams),
                ],
              ),

              const SizedBox(height: 8),

              // 下方按钮
              _buildDirectionButton('↓', '南', () {
                Logger.info('📱 方向按钮: 南');
                world.moveSouth();
              }, layoutParams),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个方向按钮
  Widget _buildDirectionButton(String arrow, String direction,
      VoidCallback onPressed, GameLayoutParams layoutParams) {
    return SizedBox(
      width: 60,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 1),
          padding: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              arrow,
              style: TextStyle(
                fontSize: layoutParams.useVerticalLayout ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              direction,
              style: TextStyle(
                fontSize: layoutParams.useVerticalLayout ? 8 : 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
