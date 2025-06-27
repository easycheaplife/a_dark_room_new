import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/world.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/responsive_layout.dart';
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
      final isUsedOutpost = (originalTile == 'P' && world.outpostUsed());

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

    // 使用原游戏的象限判断逻辑
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
}
