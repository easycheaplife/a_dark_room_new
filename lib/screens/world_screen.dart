import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/world.dart';
import '../modules/path.dart';
import '../core/state_manager.dart';

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
            onPanUpdate: (details) => _handleSwipe(details, world),
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  // 状态栏
                  _buildStatusBar(world),
                  // 地图区域
                  Expanded(
                    child: _buildMapArea(world),
                  ),
                  // 背包区域
                  _buildBackpackArea(world),
                  // 控制按钮
                  _buildControlButtons(world),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar(World world) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            '生命值: ${world.health}/${world.getMaxHealth()}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '水: ${world.water}/${world.getMaxWater()}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '位置: ${world.getCurrentTerrainName()}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
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
    final map = world.state!['map'] as List<List<String>>;
    final mask = world.state!['mask'] as List<List<bool>>;
    final curPos = world.getCurrentPosition();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: List.generate(map.length, (j) {
              return Row(
                children: List.generate(map[j].length, (i) {
                  return _buildMapTile(
                    map[i][j],
                    mask[i][j],
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
    );
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
    } else if (!visible) {
      displayChar = ' ';
      color = Colors.black;
    } else {
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

    return GestureDetector(
      onTap: () => _handleMapTileClick(x, y, world),
      child: tileWidget,
    );
  }

  /// 构建背包区域
  Widget _buildBackpackArea(World world) {
    final path = Path();

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        color: Colors.grey[900],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '背包',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '空间: ${path.getCapacity() - path.getTotalWeight()}/${path.getCapacity()}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (world.water > 0) _buildSupplyItem('水', world.water),
              ...path.outfit.entries
                  .where((entry) => entry.value > 0)
                  .map((entry) => _buildSupplyItem(entry.key, entry.value)),
            ],
          ),
        ],
      ),
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

  /// 构建控制按钮
  Widget _buildControlButtons(World world) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDirectionButton('北', () => world.moveNorth()),
          Column(
            children: [
              _buildDirectionButton('西', () => world.moveWest()),
              const SizedBox(height: 8),
              _buildDirectionButton('东', () => world.moveEast()),
            ],
          ),
          _buildDirectionButton('南', () => world.moveSouth()),
        ],
      ),
    );
  }

  /// 构建方向按钮
  Widget _buildDirectionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        minimumSize: const Size(60, 40),
      ),
      child: Text(label),
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

  /// 处理滑动手势
  void _handleSwipe(DragUpdateDetails details, World world) {
    const double sensitivity = 20.0;

    if (details.delta.dx > sensitivity) {
      world.moveEast();
    } else if (details.delta.dx < -sensitivity) {
      world.moveWest();
    } else if (details.delta.dy > sensitivity) {
      world.moveSouth();
    } else if (details.delta.dy < -sensitivity) {
      world.moveNorth();
    }
  }

  /// 处理地图瓦片点击
  void _handleMapTileClick(int x, int y, World world) {
    final curPos = world.getCurrentPosition();
    final dx = x - curPos[0];
    final dy = y - curPos[1];

    // 只允许移动到相邻的瓦片
    if (dx.abs() + dy.abs() == 1) {
      if (dx > 0) {
        world.moveEast();
      } else if (dx < 0) {
        world.moveWest();
      } else if (dy > 0) {
        world.moveSouth();
      } else if (dy < 0) {
        world.moveNorth();
      }
    }
  }
}
