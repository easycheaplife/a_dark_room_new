import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/world.dart';
import '../modules/path.dart';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 主界面
          Consumer<World>(
            builder: (context, world, child) {
              return Column(
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      '荒芜世界',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 状态信息
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '生命值: ${world.health}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        Text(
                          '水: ${world.water}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        Text(
                          '距离: ${world.getDistance()}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 地图区域
                  Expanded(
                    child: _buildMap(world),
                  ),

                  // 补给品信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildSupplies(world),
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

  /// 构建地图
  Widget _buildMap(World world) {
    try {
      final mapData = world.state?['map'];
      final maskData = world.state?['mask'];

      if (mapData == null || maskData == null) {
        return const Center(
          child: Text(
            '地图未初始化',
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      final map =
          List<List<String>>.from(mapData.map((row) => List<String>.from(row)));
      final mask =
          List<List<bool>>.from(maskData.map((row) => List<bool>.from(row)));
      final curPos = world.getCurrentPosition();

      // 确保地图数据有效
      if (map.isEmpty || map[0].isEmpty || mask.isEmpty || mask[0].isEmpty) {
        return const Center(
          child: Text(
            '地图数据为空',
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      // 以玩家为中心显示地图的一小块区域
      const viewRadius = 10; // 显示玩家周围10格的区域
      final startX = (curPos[0] - viewRadius).clamp(0, map.length - 1);
      final endX = (curPos[0] + viewRadius).clamp(0, map.length - 1);
      final startY = (curPos[1] - viewRadius).clamp(0, map[0].length - 1);
      final endY = (curPos[1] + viewRadius).clamp(0, map[0].length - 1);

      return GestureDetector(
        onTapDown: (details) => _handleMapClick(details, world, startX, startY),
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: const BoxDecoration(
            color: Colors.white, // 白色背景，与原游戏一致
            border: Border.fromBorderSide(
              BorderSide(color: Colors.black, width: 1), // 黑色边框
            ),
          ),
          child: Column(
            children: List.generate(endY - startY + 1, (j) {
              final actualY = startY + j;
              return Row(
                children: List.generate(endX - startX + 1, (i) {
                  final actualX = startX + i;
                  // 检查遮罩：只有mask[actualX][actualY]为true或者是玩家位置时才显示内容
                  final isPlayerPos =
                      actualX == curPos[0] && actualY == curPos[1];
                  final isVisible = mask[actualX][actualY] || isPlayerPos;

                  return _buildMapTile(
                    map[actualX][actualY],
                    isVisible, // 使用遮罩系统控制可见性
                    isPlayerPos, // 检查是否是玩家位置
                    actualX, // X坐标
                    actualY, // Y坐标
                    world,
                  );
                }),
              );
            }),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text(
          '地图渲染错误: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  /// 构建地图瓦片 - 参考原游戏的drawMap函数逻辑
  Widget _buildMapTile(
      String tile, bool visible, bool isPlayer, int x, int y, World world) {
    // 如果不可见且不是玩家位置，显示空白（对应原游戏的'&nbsp;'）
    if (!visible && !isPlayer) {
      return Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        child: const Text(
          ' ', // 空白字符
          style: TextStyle(
            fontSize: 12,
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
      tooltip = '流浪者';
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

      // 调试信息：打印地标状态
      if (isLandmark) {
        print(
            '🗺️ 地标调试 [$x,$y]: tile="$tile", original="$originalTile", visited=$isVisited, usedOutpost=$isUsedOutpost');
      }

      if (isLandmark && !isUsedOutpost && !isVisited) {
        // 未访问的地标 - 显示为地标样式（黑色粗体）
        displayChar = originalTile;
        final styleResult = _getLandmarkStyle(originalTile);
        color = styleResult['color'];
        tooltip = styleResult['tooltip'];
        isLandmarkStyle = true;
        print('🗺️ 显示未访问地标: $originalTile (黑色粗体)');
      } else {
        // 已访问的地标、已使用的前哨站或普通地形 - 显示为普通样式
        displayChar = originalTile;

        if (isVisited && isLandmark) {
          // 已访问的地标显示为普通灰色，与原游戏一致（#999）
          color = const Color(0xFF999999); // 原游戏CSS中的#999颜色
          final styleResult = _getLandmarkStyle(originalTile);
          tooltip = styleResult['tooltip'];
          print('🗺️ 显示已访问地标: $originalTile (灰色)');
        } else {
          // 普通地形或已使用的前哨站
          color = _getTerrainColor(displayChar);
        }
        isLandmarkStyle = false;
      }
    }

    Widget tileWidget = Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      child: Text(
        displayChar,
        style: TextStyle(
          color: color,
          fontSize: 12,
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
    switch (tile) {
      case 'A': // 村庄
        return {'color': Colors.black, 'tooltip': '村庄'};
      case 'H': // 房子
        return {'color': Colors.black, 'tooltip': '旧房子'};
      case 'V': // 洞穴
        return {'color': Colors.black, 'tooltip': '潮湿洞穴'};
      case 'O': // 小镇
        return {'color': Colors.black, 'tooltip': '废弃小镇'};
      case 'Y': // 城市
        return {'color': Colors.black, 'tooltip': '废墟城市'};
      case 'P': // 前哨站
        return {'color': Colors.black, 'tooltip': '前哨站'};
      case 'W': // 飞船
        return {'color': Colors.black, 'tooltip': '坠毁星舰'};
      case 'I': // 铁矿
        return {'color': Colors.black, 'tooltip': '铁矿'};
      case 'C': // 煤矿
        return {'color': Colors.black, 'tooltip': '煤矿'};
      case 'S': // 硫磺矿
        return {'color': Colors.black, 'tooltip': '硫磺矿'};
      case 'B': // 钻孔
        return {'color': Colors.black, 'tooltip': '钻孔'};
      case 'F': // 战场
        return {'color': Colors.black, 'tooltip': '战场'};
      case 'M': // 沼泽
        return {'color': Colors.black, 'tooltip': '阴暗沼泽'};
      case 'U': // 缓存
        return {'color': Colors.black, 'tooltip': '被摧毁的村庄'};
      case 'X': // 执行者
        return {'color': Colors.black, 'tooltip': '被摧毁的战舰'};
      default:
        return {'color': Colors.black, 'tooltip': null};
    }
  }

  /// 获取地形颜色 - 参考原游戏，普通地形使用#999灰色
  Color _getTerrainColor(String tile) {
    // 所有普通地形都使用原游戏的#999灰色
    return const Color(0xFF999999); // 原游戏CSS中的#999颜色
  }

  /// 构建补给品信息
  Widget _buildSupplies(World world) {
    final path = Provider.of<Path>(context, listen: false);
    final supplies = <Widget>[];

    // 显示重要的补给品
    final meat = path.outfit['cured meat'] ?? 0;
    if (meat > 0) {
      supplies.add(_buildSupplyItem('熏肉', meat));
    }

    final bullets = path.outfit['bullets'] ?? 0;
    if (bullets > 0) {
      supplies.add(_buildSupplyItem('子弹', bullets));
    }

    final medicine = path.outfit['medicine'] ?? 0;
    if (medicine > 0) {
      supplies.add(_buildSupplyItem('药物', medicine));
    }

    return Wrap(
      spacing: 8,
      children: supplies,
    );
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
        style: const TextStyle(color: Colors.white, fontSize: 12),
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

  /// 处理地图点击 - 适应以玩家为中心的地图视图
  void _handleMapClick(
      TapDownDetails details, World world, int startX, int startY) {
    final localPosition = details.localPosition;
    final curPos = world.curPos;

    // 计算点击的瓦片坐标（相对于显示的地图区域）
    final tileSize = 16.0;
    final padding = 4.0;

    // 计算点击位置对应的瓦片索引（相对于显示区域）
    final relativeClickTileX =
        ((localPosition.dx - padding) / tileSize).floor();
    final relativeClickTileY =
        ((localPosition.dy - padding) / tileSize).floor();

    // 转换为绝对地图坐标
    final clickTileX = startX + relativeClickTileX;
    final clickTileY = startY + relativeClickTileY;

    // 计算相对于玩家的方向
    final deltaX = clickTileX - curPos[0];
    final deltaY = clickTileY - curPos[1];

    print('🗺️ 地图点击调试 (以玩家为中心):');
    print('  玩家位置: [${curPos[0]}, ${curPos[1]}]');
    print('  显示区域: [$startX-${startX + 20}, $startY-${startY + 20}]');
    print('  点击位置: (${localPosition.dx}, ${localPosition.dy})');
    print('  相对瓦片: [$relativeClickTileX, $relativeClickTileY]');
    print('  绝对瓦片: [$clickTileX, $clickTileY]');
    print('  方向偏移: ($deltaX, $deltaY)');

    // 计算玩家在当前显示区域中的相对位置
    final playerRelativeX = curPos[0] - startX;
    final playerRelativeY = curPos[1] - startY;
    final playerScreenX = playerRelativeX * tileSize + padding;
    final playerScreenY = playerRelativeY * tileSize + padding;
    print('  玩家在显示区域中的位置: [$playerRelativeX, $playerRelativeY]');
    print('  玩家屏幕位置: ($playerScreenX, $playerScreenY)');
    print(
        '  点击相对于玩家的像素偏移: (${localPosition.dx - playerScreenX}, ${localPosition.dy - playerScreenY})');

    // 简单的方向判断：只允许单步移动
    if (deltaX == 1 && deltaY == 0) {
      print('  ✅ 检测到向东移动 (deltaX=1, deltaY=0)');
      print('  🚀 调用 world.moveEast()');
      world.moveEast();
      print('  ✅ world.moveEast() 调用完成');
    } else if (deltaX == -1 && deltaY == 0) {
      print('  ✅ 检测到向西移动 (deltaX=-1, deltaY=0)');
      print('  🚀 调用 world.moveWest()');
      world.moveWest();
      print('  ✅ world.moveWest() 调用完成');
    } else if (deltaX == 0 && deltaY == 1) {
      print('  ✅ 检测到向南移动 (deltaX=0, deltaY=1)');
      print('  🚀 调用 world.moveSouth()');
      world.moveSouth();
      print('  ✅ world.moveSouth() 调用完成');
    } else if (deltaX == 0 && deltaY == -1) {
      print('  ✅ 检测到向北移动 (deltaX=0, deltaY=-1)');
      print('  🚀 调用 world.moveNorth()');
      world.moveNorth();
      print('  ✅ world.moveNorth() 调用完成');
    } else if (deltaX.abs() > 0 || deltaY.abs() > 0) {
      // 对于非相邻瓦片，选择主要方向
      if (deltaX.abs() > deltaY.abs()) {
        if (deltaX > 0) {
          print('  → 向东移动 (远距离)');
          world.moveEast();
        } else {
          print('  → 向西移动 (远距离)');
          world.moveWest();
        }
      } else {
        if (deltaY > 0) {
          print('  → 向南移动 (远距离)');
          world.moveSouth();
        } else {
          print('  → 向北移动 (远距离)');
          world.moveNorth();
        }
      }
    } else {
      print('  → 点击在玩家位置，不移动');
    }
  }
}
