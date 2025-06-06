import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/world.dart';
import '../modules/path.dart';

/// 世界界面 - 显示地图探索和生存状态
class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // 确保焦点在组件上，以便接收键盘事件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<World>(
      builder: (context, world, child) {
        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              _handleKeyPress(event, world);
            }
          },
          child: GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  // 状态栏和背包区域
                  _buildTopArea(world),
                  // 地图区域 - 占据大部分空间
                  Expanded(
                    flex: 3,
                    child: _buildMapArea(world),
                  ),
                  // 重生按钮（仅在死亡时显示）
                  if (world.dead) _buildRespawnButton(world),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建顶部区域（状态栏和背包）
  Widget _buildTopArea(World world) {
    final path = Path();

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[900],
      child: Column(
        children: [
          // 状态栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '生命值: ${world.health}/${world.getMaxHealth()}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '水: ${world.water}/${world.getMaxWater()}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '位置: ${world.getCurrentTerrainName()}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 背包信息
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              color: Colors.black,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '背包',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    Text(
                      '空间: ${path.getCapacity() - path.getTotalWeight()}/${path.getCapacity()}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (world.water > 0) _buildSupplyItem('水', world.water),
                        ...path.outfit.entries
                            .where((entry) => entry.value > 0)
                            .map((entry) =>
                                _buildSupplyItem(entry.key, entry.value)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建重生按钮
  Widget _buildRespawnButton(World world) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => world.forceRespawn(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          minimumSize: const Size(100, 40),
        ),
        child: const Text('重生'),
      ),
    );
  }

  /// 构建地图区域
  Widget _buildMapArea(World world) {
    if (world.state == null) {
      return const Center(
        child: Text(
          '地图数据加载中...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        color: Colors.black,
      ),
      child: _buildMap(world),
    );
  }

  /// 构建地图
  Widget _buildMap(World world) {
    try {
      // 安全地转换地图数据
      final mapData = world.state!['map'];
      final maskData = world.state!['mask'];

      if (mapData == null || maskData == null) {
        return const Center(
          child: Text(
            '地图数据缺失',
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      // 转换为正确的类型
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
              child: Column(
                children: List.generate(map[0].length, (j) {
                  return Row(
                    children: List.generate(map.length, (i) {
                      return _buildMapTile(
                        map[i][j],
                        true, // 显示完整地图，不使用遮罩
                        i == curPos[0] && j == curPos[1],
                        i,
                        j,
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

  /// 构建地图瓦片
  Widget _buildMapTile(
      String tile, bool visible, bool isPlayer, int x, int y, World world) {
    String displayChar;
    Color color = Colors.grey;
    String? tooltip;

    if (isPlayer) {
      displayChar = '@';
      color = Colors.yellow;
      tooltip = '流浪者';
    } else {
      // 显示完整地图，不使用遮罩系统
      displayChar = tile;

      // 设置地形颜色和提示
      switch (tile) {
        case 'A': // 村庄
          color = Colors.green;
          tooltip = '村庄';
          break;
        case ';': // 森林
          color = Colors.green[300]!;
          break;
        case ',': // 田野
          color = Colors.yellow[700]!;
          break;
        case '.': // 荒地
          color = Colors.brown[300]!;
          break;
        case '#': // 道路
          color = Colors.grey[400]!;
          break;
        case 'H': // 房子
          color = Colors.blue;
          tooltip = '旧房子';
          break;
        case 'V': // 洞穴
          color = Colors.purple;
          tooltip = '潮湿洞穴';
          break;
        case 'O': // 小镇
          color = Colors.orange;
          tooltip = '废弃小镇';
          break;
        case 'Y': // 城市
          color = Colors.red;
          tooltip = '废墟城市';
          break;
        case 'P': // 前哨站
          color = Colors.cyan;
          tooltip = '前哨站';
          break;
        case 'W': // 飞船
          color = Colors.white;
          tooltip = '坠毁星舰';
          break;
        case 'I': // 铁矿
          color = Colors.grey[600]!;
          tooltip = '铁矿';
          break;
        case 'C': // 煤矿
          color = Colors.black;
          tooltip = '煤矿';
          break;
        case 'S': // 硫磺矿
          color = Colors.yellow;
          tooltip = '硫磺矿';
          break;
        case 'B': // 钻孔
          color = Colors.brown;
          tooltip = '钻孔';
          break;
        case 'F': // 战场
          color = Colors.red[800]!;
          tooltip = '战场';
          break;
        case 'M': // 沼泽
          color = Colors.green[800]!;
          tooltip = '阴暗沼泽';
          break;
        case 'U': // 缓存
          color = Colors.grey[700]!;
          tooltip = '被摧毁的村庄';
          break;
        case 'X': // 执行者
          color = Colors.red[900]!;
          tooltip = '被摧毁的战舰';
          break;
        default:
          color = Colors.grey;
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
          fontWeight: (tooltip != null || isPlayer)
              ? FontWeight.bold
              : FontWeight.normal,
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

  /// 处理地图点击 - 完全参考原游戏的点击移动逻辑
  void _handleMapClick(TapDownDetails details, World world) {
    // 获取地图容器的渲染框
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 计算点击位置相对于地图容器的本地坐标
    final localPosition = details.localPosition;

    // 获取地图的实际显示尺寸
    final mapDisplayWidth = renderBox.size.width;
    final mapDisplayHeight = renderBox.size.height;

    // 参考原游戏的逻辑：
    // centreX = map.offset().left + map.width() * World.curPos[0] / (World.RADIUS * 2),
    // centreY = map.offset().top + map.height() * World.curPos[1] / (World.RADIUS * 2),
    // clickX = event.pageX - centreX,
    // clickY = event.pageY - centreY;

    // 计算当前位置在地图中的中心点 - 完全参考原游戏逻辑
    final radius = World.radius;
    final curPos = world.curPos;

    // 原游戏的坐标计算：当前位置在地图显示中的像素坐标
    // 注意：原游戏的地图显示是整个地图，不是以当前位置为中心的视图
    final centreX = mapDisplayWidth * curPos[0] / (radius * 2);
    final centreY = mapDisplayHeight * curPos[1] / (radius * 2);

    // 计算点击位置相对于当前位置中心的偏移
    final clickX = localPosition.dx - centreX;
    final clickY = localPosition.dy - centreY;

    print('🗺️ 地图点击调试:');
    print('  地图尺寸: ${mapDisplayWidth}x${mapDisplayHeight}');
    print('  当前位置: ${curPos[0]}, ${curPos[1]}');
    print('  半径: $radius');
    print('  中心点: $centreX, $centreY');
    print('  点击位置: ${localPosition.dx}, ${localPosition.dy}');
    print('  偏移量: $clickX, $clickY');

    // 使用原游戏的完全相同的点击逻辑
    // 注意：原游戏使用的是 if 而不是 else if，这样可以处理边界情况
    if (clickX > clickY && clickX < -clickY) {
      // 上方
      print('  → 向北移动');
      world.moveNorth();
    }
    if (clickX < clickY && clickX > -clickY) {
      // 下方
      print('  → 向南移动');
      world.moveSouth();
    }
    if (clickX < clickY && clickX < -clickY) {
      // 左方
      print('  → 向西移动');
      world.moveWest();
    }
    if (clickX > clickY && clickX > -clickY) {
      // 右方
      print('  → 向东移动');
      world.moveEast();
    }
  }
}
