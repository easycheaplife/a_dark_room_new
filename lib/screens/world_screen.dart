import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/world.dart';
import '../modules/path.dart';

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
      body: Consumer<World>(
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
    );
  }

  /// 构建地图
  Widget _buildMap(World world) {
    try {
      final mapData = world.state?['map'];
      if (mapData == null) {
        return const Center(
          child: Text(
            '地图未初始化',
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      final map =
          List<List<String>>.from(mapData.map((row) => List<String>.from(row)));
      final curPos = world.getCurrentPosition();

      // 确保地图数据有效
      if (map.isEmpty || map[0].isEmpty) {
        return const Center(
          child: Text(
            '地图数据为空',
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      return GestureDetector(
        onTapDown: (details) => _handleMapClick(details, world),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: const BoxDecoration(
                color: Colors.white, // 白色背景，与原游戏一致
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 1), // 黑色边框
                ),
              ),
              child: Column(
                children: List.generate(map[0].length, (j) {
                  // j 是 Y轴（行，从上到下）
                  return Row(
                    children: List.generate(map.length, (i) {
                      // i 是 X轴（列，从左到右）
                      // 地图数据访问：map[i][j] 即 map[x][y]
                      return _buildMapTile(
                        map[i][j],
                        true, // 显示完整地图，不使用遮罩
                        i == curPos[0] && j == curPos[1], // 检查是否是玩家位置
                        i, // X坐标
                        j, // Y坐标
                        world,
                      );
                    }),
                  );
                }),
              ),
            ),
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
      final isLandmark = _isLandmarkTile(originalTile) || originalTile == 'A'; // 村庄也是地标
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

  /// 处理地图点击 - 简化版本，直接基于点击位置相对于玩家位置的方向
  void _handleMapClick(TapDownDetails details, World world) {
    final localPosition = details.localPosition;
    final curPos = world.curPos;

    // 计算玩家在地图中的实际像素位置（瓦片中心）
    final tileSize = 16.0;
    final padding = 4.0; // Container的padding
    final playerPixelX = curPos[0] * tileSize + tileSize / 2 + padding;
    final playerPixelY = curPos[1] * tileSize + tileSize / 2 + padding;

    // 计算点击位置相对于玩家位置的偏移
    final clickX = localPosition.dx - playerPixelX;
    final clickY = localPosition.dy - playerPixelY;

    print('🗺️ 地图点击调试 (简化版):');
    print('  当前位置: [${curPos[0]}, ${curPos[1]}]');
    print('  玩家像素位置: ($playerPixelX, $playerPixelY)');
    print('  点击位置: (${localPosition.dx}, ${localPosition.dy})');
    print('  偏移量: ($clickX, $clickY)');

    // 使用原游戏的点击逻辑
    // 这四个条件将以玩家为中心的区域分成四个三角形
    if (clickX > clickY && clickX < -clickY) {
      // 上方三角形 - 向北移动
      print('  → 向北移动');
      world.moveNorth();
    } else if (clickX < clickY && clickX > -clickY) {
      // 下方三角形 - 向南移动
      print('  → 向南移动');
      world.moveSouth();
    } else if (clickX < clickY && clickX < -clickY) {
      // 左方三角形 - 向西移动
      print('  → 向西移动');
      world.moveWest();
    } else if (clickX > clickY && clickX > -clickY) {
      // 右方三角形 - 向东移动
      print('  → 向东移动');
      world.moveEast();
    } else {
      // 点击在玩家位置附近，不移动
      print('  → 点击位置太接近玩家，不移动');
    }
  }
}
